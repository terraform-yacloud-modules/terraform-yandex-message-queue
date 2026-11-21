module "standard_queue" {
  source = "../.."

  name = "message-queue-complete"

  visibility_timeout_seconds = 600
  receive_wait_time_seconds  = 20
  message_retention_seconds  = 1209600
  max_message_size           = 262144
  delay_seconds              = 0

  create_dlq        = true
  max_receive_count = 3

  # The dead letter queue is configured independently from the source queue so
  # that failed messages can be kept longer and polled differently.
  dlq_visibility_timeout_seconds = 60
  dlq_receive_wait_time_seconds  = 10
  dlq_message_retention_seconds  = 1209600
  dlq_max_message_size           = 262144
  dlq_delay_seconds              = 0

  dlq_tags = {
    environment = "test"
    module      = "terraform-yandex-message-queue"
    role        = "dead-letter"
  }

  tags = {
    environment = "test"
    module      = "terraform-yandex-message-queue"
  }
}

module "fifo_queue" {
  source = "../.."

  name                        = "message-queue-complete.fifo"
  fifo_queue                  = true
  content_based_deduplication = true

  create_dlq        = true
  max_receive_count = 5

  dlq_visibility_timeout_seconds  = 120
  dlq_receive_wait_time_seconds   = 5
  dlq_message_retention_seconds   = 604800
  dlq_max_message_size            = 131072
  dlq_content_based_deduplication = true

  tags = {
    environment = "test"
    module      = "terraform-yandex-message-queue"
  }
}
