# Terraform-модуль Message Queue для Yandex Cloud

Модуль создаёт очередь Yandex Cloud Message Queue (YMQ) и, при необходимости,
очередь недоставленных сообщений (DLQ) с redrive-политикой. Поддерживаются
стандартные и FIFO-очереди.

## Возможности

- создание стандартной или FIFO-очереди с настройкой времени видимости,
  long polling, срока хранения, максимального размера сообщения и задержки;
- включение content-based дедупликации для FIFO-очередей;
- создание DLQ модулем либо использование существующей очереди через явную
  redrive-политику;
- независимая настройка DLQ: собственные время видимости, long polling, срок
  хранения, максимальный размер сообщения, задержка, дедупликация и теги;
- теги и регион для очередей.

## Использование

Стандартная очередь с очередью недоставленных сообщений:

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

FIFO-очередь с content-based дедупликацией:

```hcl
module "fifo_queue" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue.git?ref=v1.0.0"

  name                        = "my-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}
```

DLQ должна быть того же типа, что и исходная очередь. При `create_dlq = true`
модуль создаёт FIFO-DLQ для FIFO-очереди и стандартную DLQ для стандартной
очереди.

Вместо создания новой DLQ можно указать существующую очередь:

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

`create_dlq` и `redrive_policy` взаимоисключающие.

## Настройка очереди недоставленных сообщений

По умолчанию DLQ создаётся с настройками YMQ. Параметры `dlq_*` позволяют
настроить её отдельно от исходной очереди — например, хранить недоставленные
сообщения дольше, чем в рабочей очереди, и опрашивать её с другим long polling:

```hcl
module "queue" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue.git?ref=v1.0.0"

  name = "my-queue"

  message_retention_seconds = 345600

  create_dlq        = true
  max_receive_count = 5

  dlq_visibility_timeout_seconds = 60
  dlq_receive_wait_time_seconds  = 10
  dlq_message_retention_seconds  = 1209600
  dlq_max_message_size           = 131072
  dlq_delay_seconds              = 0

  dlq_tags = {
    role = "dead-letter"
  }
}
```

Если `dlq_tags` не задан, DLQ получает теги исходной очереди. Для FIFO-очереди
можно включить `dlq_content_based_deduplication` — по умолчанию дедупликация в
DLQ выключена.

## Аутентификация и каталог

У ресурса `yandex_message_queue` нет аргумента `folder_id`. Yandex Cloud
создаёт очередь в каталоге, которому принадлежит статический ключ доступа,
используемый для YMQ API. Поэтому ключ должен принадлежать сервисному
аккаунту из нужного каталога.

Провайдеру также нужна IAM-аутентификация для инициализации, а YMQ API —
статический ключ доступа. На практике используются переменные:

```bash
export YC_TOKEN="$(yc iam create-token)"          # или YC_SERVICE_ACCOUNT_KEY_FILE
export YC_MESSAGE_QUEUE_ACCESS_KEY="<key_id>"     # статический ключ сервисного аккаунта
export YC_MESSAGE_QUEUE_SECRET_KEY="<secret>"     # его секрет
```

Сервисному аккаунту нужна роль `ymq.admin` на каталог, чтобы создавать
очереди и управлять ими. `YC_FOLDER_ID` этому модулю не нужен, но может
пригодиться другим ресурсам в той же конфигурации.

## Тестирование

CI на pull request выполняет только статические проверки: `terraform fmt`,
`terraform validate` для модуля и примеров, TFLint и Checkov. Сквозные тесты в
облаке автоматически не запускаются, потому что секреты репозитория недоступны
для pull request из форков.

Сквозной тест можно запустить вручную. Он создаёт реальные очереди с
уникальными именами, проверяет отправку и получение для стандартной и
FIFO-очередей, порядок FIFO, content-based дедупликацию и перевод сообщения в
DLQ, после чего всегда удаляет созданные ресурсы:

```bash
export YC_TOKEN="$(yc iam create-token)"
export YC_MESSAGE_QUEUE_ACCESS_KEY="<key_id>"
export YC_MESSAGE_QUEUE_SECRET_KEY="<secret>"

./tests/e2e.sh
```

Скрипту нужны Terraform и Python 3 с boto3. Статический ключ должен
принадлежать сервисному аккаунту с ролью `ymq.admin` в каталоге, где создаются
очереди.

## Примеры

Примеры в каталоге
[`examples`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples)
служат справочником по использованию модуля и одновременно проверкой изменений
в его коде. Если вы вносите вклад в проект, обновляйте примеры, чтобы
мейнтейнеры могли проверить изменения, а примеры оставались актуальными.

- [`examples/minimal`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples/minimal) — одна стандартная очередь.
- [`examples/complete`](https://github.com/terraform-yacloud-modules/terraform-yandex-message-queue/tree/main/examples/complete) — стандартная очередь с настроенной DLQ и FIFO-очередь с собственной FIFO-DLQ.

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
| <a name="input_dlq_content_based_deduplication"></a> [dlq\_content\_based\_deduplication](#input\_dlq\_content\_based\_deduplication) | Enable content-based deduplication for the dead letter queue. Can be used only for FIFO queues created by the module. | `bool` | `false` | no |
| <a name="input_dlq_delay_seconds"></a> [dlq\_delay\_seconds](#input\_dlq\_delay\_seconds) | Time in seconds to delay new messages in the dead letter queue. Valid values: 0-900. | `number` | `0` | no |
| <a name="input_dlq_max_message_size"></a> [dlq\_max\_message\_size](#input\_dlq\_max\_message\_size) | Maximum message size for the dead letter queue, in bytes. Valid values: 1024-262144. | `number` | `262144` | no |
| <a name="input_dlq_message_retention_seconds"></a> [dlq\_message\_retention\_seconds](#input\_dlq\_message\_retention\_seconds) | Message retention period for the dead letter queue, in seconds. Valid values: 60-1209600. | `number` | `345600` | no |
| <a name="input_dlq_name"></a> [dlq\_name](#input\_dlq\_name) | Name of the dead letter queue created by the module. Defaults to <name>-dlq or <name>-dlq.fifo for FIFO queues. | `string` | `null` | no |
| <a name="input_dlq_receive_wait_time_seconds"></a> [dlq\_receive\_wait\_time\_seconds](#input\_dlq\_receive\_wait\_time\_seconds) | Long polling wait time for the dead letter queue, in seconds. Valid values: 0-20. | `number` | `0` | no |
| <a name="input_dlq_tags"></a> [dlq\_tags](#input\_dlq\_tags) | A set of tags for the dead letter queue. Defaults to the tags of the source queue. | `map(string)` | `null` | no |
| <a name="input_dlq_visibility_timeout_seconds"></a> [dlq\_visibility\_timeout\_seconds](#input\_dlq\_visibility\_timeout\_seconds) | Visibility timeout for messages in the dead letter queue, in seconds. Valid values: 0-43200. | `number` | `30` | no |
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
| <a name="output_dlq_name"></a> [dlq\_name](#output\_dlq\_name) | Dead letter queue name, or null when the module does not create a DLQ. |
| <a name="output_id"></a> [id](#output\_id) | Message queue URL. |
| <a name="output_name"></a> [name](#output\_name) | Message queue name. |
<!-- END_TF_DOCS -->
