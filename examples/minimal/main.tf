module "queue" {
  source = "../.."

  name = "message-queue-minimal"

  tags = {
    environment = "test"
    module      = "terraform-yandex-message-queue"
  }
}
