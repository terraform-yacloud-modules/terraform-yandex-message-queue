locals {
  # FIFO queues must have the .fifo suffix, so the generated DLQ name keeps it.
  dlq_name = coalesce(
    var.dlq_name,
    var.fifo_queue ? "${trimsuffix(var.name, ".fifo")}-dlq.fifo" : "${var.name}-dlq"
  )

  # An existing queue can be used as a DLQ through an explicit redrive policy.
  # Otherwise the module creates its own DLQ and builds the policy from it.
  redrive_policy = var.create_dlq ? jsonencode({
    deadLetterTargetArn = yandex_message_queue.dlq[0].arn
    maxReceiveCount     = var.max_receive_count
  }) : var.redrive_policy
}

resource "yandex_message_queue" "this" {
  name = var.name

  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  message_retention_seconds  = var.message_retention_seconds
  max_message_size           = var.max_message_size
  delay_seconds              = var.delay_seconds

  fifo_queue                  = var.fifo_queue
  content_based_deduplication = var.fifo_queue ? var.content_based_deduplication : null

  redrive_policy = local.redrive_policy
  tags           = var.tags
  region_id      = var.region_id

  lifecycle {
    precondition {
      condition = (
        var.fifo_queue
        ? can(regex("^[a-zA-Z0-9_-]+\\.fifo$", var.name))
        : can(regex("^[a-zA-Z0-9_-]+$", var.name))
      )
      error_message = "FIFO queue names must end with .fifo and contain only letters, numbers, hyphens, and underscores. Standard queue names cannot contain dots."
    }

    precondition {
      condition     = !var.content_based_deduplication || var.fifo_queue
      error_message = "content_based_deduplication can be enabled only when fifo_queue is true."
    }

    precondition {
      condition     = !(var.create_dlq && var.redrive_policy != null)
      error_message = "create_dlq and redrive_policy cannot be used together. Use one of them: either let the module create a DLQ or point redrive_policy to an existing queue."
    }

    precondition {
      condition = var.dlq_name == null ? true : (
        var.dlq_name != var.name &&
        (
          var.fifo_queue
          ? can(regex("^[a-zA-Z0-9_-]+\\.fifo$", var.dlq_name))
          : can(regex("^[a-zA-Z0-9_-]+$", var.dlq_name))
        )
      )
      error_message = "dlq_name must differ from name and follow the same naming rules as name."
    }
  }
}

resource "yandex_message_queue" "dlq" {
  count = var.create_dlq ? 1 : 0

  name       = local.dlq_name
  fifo_queue = var.fifo_queue
  tags       = var.tags
  region_id  = var.region_id

  lifecycle {
    precondition {
      condition     = length(local.dlq_name) <= 80
      error_message = "The generated DLQ name is longer than 80 characters. Set dlq_name explicitly."
    }
  }
}
