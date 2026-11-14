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

  tags = {
    environment = "test"
    module      = "terraform-yandex-message-queue"
  }
}
