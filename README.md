# Yandex Cloud Message Queue Terraform module

Terraform module which creates Yandex Cloud Message Queue (YMQ) resources.

The module creates one queue and, optionally, a dead letter queue with a
redrive policy. Both standard and FIFO queues are supported.

## Usage

Standard queue with a dead letter queue:

```hcl
module "queue" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue.git?ref=v1.0.0"

  name = "my-queue"

  visibility_timeout_seconds = 600
  receive_wait_time_seconds  = 20

  create_dlq        = true
  max_receive_count = 3

  tags = {
    environment = "production"
  }
}
```

FIFO queue with content-based deduplication:

```hcl
module "fifo_queue" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue.git?ref=v1.0.0"

  name                        = "my-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}
```

A dead letter queue must be the same type as the source queue. When
`create_dlq = true`, the module creates a FIFO dead letter queue for a FIFO
queue and a standard dead letter queue for a standard queue.

An existing queue can be used as a dead letter queue instead of creating a new
one:

```hcl
module "queue" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue.git?ref=v1.0.0"

  name = "my-queue"

  redrive_policy = jsonencode({
    deadLetterTargetArn = "yrn:yc:ymq:ru-central1:<folder_id>:my-dlq"
    maxReceiveCount     = 3
  })
}
```

`create_dlq` and `redrive_policy` are mutually exclusive.

## Authentication and folder

The `yandex_message_queue` resource has no `folder_id` argument. Yandex Cloud
creates the queue in the folder that owns the static access key used for the
YMQ API, so the key must belong to a service account from the target folder.

The provider still needs IAM authentication for its own initialization, and the
YMQ API needs a static access key. In practice the following variables are used:

```bash
export YC_TOKEN="$(yc iam create-token)"          # or YC_SERVICE_ACCOUNT_KEY_FILE
export YC_MESSAGE_QUEUE_ACCESS_KEY="<key_id>"     # static access key of the service account
export YC_MESSAGE_QUEUE_SECRET_KEY="<secret>"     # its secret
```

The service account needs the `ymq.admin` role on the folder to create and
manage queues. `YC_FOLDER_ID` is not used by this module, but can be set for
other resources in the same configuration.

## Examples

Examples codified under
the [`examples`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples)
are intended to give users references for how to use the module(s) as well as
testing/validating changes to the source code of the module. If contributing to
the project, please be sure to make any appropriate updates to the relevant
examples to allow maintainers to test your changes and to keep the examples up
to date for users. Thank you!

- [`examples/minimal`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples/minimal) — one standard queue.
- [`examples/complete`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples/complete) — a standard queue with a dead letter queue and a FIFO queue.

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3 |
| <a name="requirement_yandex"></a> [yandex](#requirement\_yandex) | >= 0.140.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_yandex"></a> [yandex](#provider\_yandex) | >= 0.140.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [yandex_message_queue.dlq](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/message_queue) | resource |
| [yandex_message_queue.this](https://registry.terraform.io/providers/yandex-cloud/yandex/latest/docs/resources/message_queue) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_content_based_deduplication"></a> [content\_based\_deduplication](#input\_content\_based\_deduplication) | Enable content-based deduplication. Can be used only for FIFO queues. | `bool` | `false` | no |
| <a name="input_create_dlq"></a> [create\_dlq](#input\_create\_dlq) | Create a dead letter queue for this queue and configure a redrive policy. | `bool` | `false` | no |
| <a name="input_delay_seconds"></a> [delay\_seconds](#input\_delay\_seconds) | Time in seconds to delay new messages. Valid values: 0-900. | `number` | `0` | no |
| <a name="input_dlq_name"></a> [dlq\_name](#input\_dlq\_name) | Name of the dead letter queue created by the module. Defaults to <name>-dlq or <name>-dlq.fifo for FIFO queues. | `string` | `null` | no |
| <a name="input_fifo_queue"></a> [fifo\_queue](#input\_fifo\_queue) | Whether the queue is a FIFO queue. The value cannot be changed after creation. | `bool` | `false` | no |
| <a name="input_max_message_size"></a> [max\_message\_size](#input\_max\_message\_size) | Maximum message size in bytes. Valid values: 1024-262144. | `number` | `262144` | no |
| <a name="input_max_receive_count"></a> [max\_receive\_count](#input\_max\_receive\_count) | Number of receives before a message is moved to the dead letter queue. Valid values: 1-1000. | `number` | `3` | no |
| <a name="input_message_retention_seconds"></a> [message\_retention\_seconds](#input\_message\_retention\_seconds) | Message retention period in seconds. Valid values: 60-1209600. | `number` | `345600` | no |
| <a name="input_name"></a> [name](#input\_name) | Message queue name. FIFO queue names must end with the .fifo suffix. | `string` | n/a | yes |
| <a name="input_receive_wait_time_seconds"></a> [receive\_wait\_time\_seconds](#input\_receive\_wait\_time\_seconds) | Long polling wait time in seconds. Valid values: 0-20. | `number` | `0` | no |
| <a name="input_redrive_policy"></a> [redrive\_policy](#input\_redrive\_policy) | Explicit redrive policy in JSON format for an existing dead letter queue. Cannot be used with create\_dlq. | `string` | `null` | no |
| <a name="input_region_id"></a> [region\_id](#input\_region\_id) | Region where the message queue is located. Defaults to the provider region (ru-central1). | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A set of tags for the queue. | `map(string)` | `{}` | no |
| <a name="input_visibility_timeout_seconds"></a> [visibility\_timeout\_seconds](#input\_visibility\_timeout\_seconds) | Visibility timeout for received messages in seconds. Valid values: 0-43200. | `number` | `30` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_arn"></a> [arn](#output\_arn) | Message queue ARN. |
| <a name="output_dlq_arn"></a> [dlq\_arn](#output\_dlq\_arn) | Dead letter queue ARN, or null when the module does not create a DLQ. |
| <a name="output_dlq_id"></a> [dlq\_id](#output\_dlq\_id) | Dead letter queue URL, or null when the module does not create a DLQ. |
| <a name="output_id"></a> [id](#output\_id) | Message queue URL. |
| <a name="output_name"></a> [name](#output\_name) | Message queue name. |
<!-- END_TF_DOCS -->
