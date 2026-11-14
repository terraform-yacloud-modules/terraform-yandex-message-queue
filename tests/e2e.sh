#!/usr/bin/env bash
#
# End-to-end test for the message queue module.
#
# Creates real queues in Yandex Cloud, checks send/receive for standard and FIFO
# queues, checks content-based deduplication and dead letter queue redrive, then
# always destroys the created resources.
#
# Required environment variables:
#   YC_MESSAGE_QUEUE_ACCESS_KEY  static access key ID of a service account with ymq.admin
#   YC_MESSAGE_QUEUE_SECRET_KEY  static access key secret
#   YC_TOKEN or YC_SERVICE_ACCOUNT_KEY_FILE  authentication for the yandex provider
#
# Optional:
#   YMQ_ENDPOINT  default https://message-queue.api.cloud.yandex.net
#   YC_REGION     default ru-central1
#
# Requirements: terraform, python3 with boto3.

set -Eeuo pipefail
export TF_IN_AUTOMATION=1

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
module_dir="$(cd "${script_dir}/.." && pwd)"

for cmd in terraform python3; do
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "ERROR: $cmd is required" >&2
    exit 1
  fi
done

if ! python3 -c 'import boto3' >/dev/null 2>&1; then
  echo "ERROR: python3 boto3 is required (pip install boto3)" >&2
  exit 1
fi

: "${YC_MESSAGE_QUEUE_ACCESS_KEY:?set YC_MESSAGE_QUEUE_ACCESS_KEY}"
: "${YC_MESSAGE_QUEUE_SECRET_KEY:?set YC_MESSAGE_QUEUE_SECRET_KEY}"

suffix="$(date +%s)-${RANDOM}"
workdir="$(mktemp -d "${TMPDIR:-/tmp}/ymq-e2e.XXXXXX")"
module_source="$(python3 -c 'import os, sys; print(os.path.relpath(sys.argv[1], sys.argv[2]))' "$module_dir" "$workdir")"

cleanup() {
  local status=$?
  if [[ -f "${workdir}/terraform.tfstate" ]]; then
    echo "==> Destroying test queues"
    if ! (cd "$workdir" && terraform destroy -auto-approve -input=false -no-color >/dev/null); then
      echo "WARNING: failed to destroy test queues, check the cloud manually" >&2
    fi
  fi
  rm -rf "$workdir"
  exit "$status"
}
trap cleanup EXIT

cat >"${workdir}/main.tf" <<EOF
terraform {
  required_version = ">= 1.3"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = ">= 0.140.0"
    }
  }
}

module "standard" {
  source = "${module_source}"

  name                       = "mq-e2e-${suffix}"
  visibility_timeout_seconds = 1

  create_dlq        = true
  max_receive_count = 2

  tags = {
    test = "e2e"
  }
}

module "fifo" {
  source = "${module_source}"

  name                        = "mq-e2e-${suffix}.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

output "queue_url" {
  value = module.standard.id
}

output "dlq_url" {
  value = module.standard.dlq_id
}

output "fifo_url" {
  value = module.fifo.id
}
EOF

echo "==> Creating test queues"
(
  cd "$workdir"
  terraform init -backend=false -input=false -no-color >/dev/null
  terraform apply -auto-approve -input=false -no-color >/dev/null
)

queue_url="$(cd "$workdir" && terraform output -raw queue_url)"
dlq_url="$(cd "$workdir" && terraform output -raw dlq_url)"
fifo_url="$(cd "$workdir" && terraform output -raw fifo_url)"

echo "==> Running send/receive checks"
YMQ_QUEUE_URL="$queue_url" \
  YMQ_DLQ_URL="$dlq_url" \
  YMQ_FIFO_URL="$fifo_url" \
  YC_MESSAGE_QUEUE_ACCESS_KEY="$YC_MESSAGE_QUEUE_ACCESS_KEY" \
  YC_MESSAGE_QUEUE_SECRET_KEY="$YC_MESSAGE_QUEUE_SECRET_KEY" \
  python3 - <<'PY'
import os
import sys
import time
import uuid

import boto3
from botocore.config import Config


def require(name):
    value = os.environ.get(name)
    if not value:
        sys.exit(f"ERROR: {name} is not set")
    return value


client = boto3.client(
    "sqs",
    endpoint_url=os.environ.get("YMQ_ENDPOINT", "https://message-queue.api.cloud.yandex.net"),
    region_name=os.environ.get("YC_REGION", "ru-central1"),
    aws_access_key_id=require("YC_MESSAGE_QUEUE_ACCESS_KEY"),
    aws_secret_access_key=require("YC_MESSAGE_QUEUE_SECRET_KEY"),
    config=Config(
        retries={"max_attempts": 10, "mode": "standard"},
        connect_timeout=10,
        read_timeout=30,
    ),
)

queue_url = require("YMQ_QUEUE_URL")
dlq_url = require("YMQ_DLQ_URL")
fifo_url = require("YMQ_FIFO_URL")


def fail(message):
    print(f"FAIL: {message}", file=sys.stderr)
    sys.exit(1)


def receive(url, wait=5, visibility=None, limit=1):
    kwargs = {"QueueUrl": url, "MaxNumberOfMessages": limit, "WaitTimeSeconds": wait}
    if visibility is not None:
        kwargs["VisibilityTimeout"] = visibility
    return client.receive_message(**kwargs).get("Messages", [])


def collect(url, count, timeout):
    messages = []
    deadline = time.time() + timeout
    while len(messages) < count and time.time() < deadline:
        messages.extend(receive(url, wait=2, limit=10))
    return messages


def delete(url, messages):
    for message in messages:
        client.delete_message(QueueUrl=url, ReceiptHandle=message["ReceiptHandle"])


body = f"standard-{uuid.uuid4()}"
client.send_message(QueueUrl=queue_url, MessageBody=body)
messages = collect(queue_url, 1, timeout=15)
if not messages or messages[0]["Body"] != body:
    fail("standard queue did not return the sent message")
delete(queue_url, messages)
print("PASS standard send/receive/delete")

group = f"group-{uuid.uuid4()}"
bodies = [f"fifo-1-{uuid.uuid4()}", f"fifo-2-{uuid.uuid4()}"]
for body in bodies:
    client.send_message(QueueUrl=fifo_url, MessageBody=body, MessageGroupId=group)
for expected in bodies:
    messages = collect(fifo_url, 1, timeout=15)
    if not messages or messages[0]["Body"] != expected:
        fail(f"FIFO queue order mismatch: expected {expected}, got {messages}")
    delete(fifo_url, messages)
print("PASS FIFO send/receive/order")

body = f"dedup-{uuid.uuid4()}"
for _ in range(2):
    client.send_message(QueueUrl=fifo_url, MessageBody=body, MessageGroupId=group)
messages = collect(fifo_url, 1, timeout=15)
duplicates = sum(message["Body"] == body for message in messages)
if duplicates != 1:
    fail(f"content-based deduplication returned {duplicates} copies, expected 1")
delete(fifo_url, messages)
print("PASS FIFO content-based deduplication")

body = f"poison-{uuid.uuid4()}"
client.send_message(QueueUrl=queue_url, MessageBody=body)
for _ in range(6):
    receive(queue_url, wait=2, visibility=0)
    time.sleep(0.2)

deadline = time.time() + 30
while time.time() < deadline:
    messages = receive(dlq_url, wait=5)
    if any(message["Body"] == body for message in messages):
        delete(dlq_url, messages)
        print("PASS DLQ redrive")
        break
    time.sleep(1)
else:
    fail("message was not moved to the dead letter queue")
PY

echo "==> All checks passed"
