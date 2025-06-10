# Локальные переменные для вычислений
locals {
  # Прямое и безопасное определение ARN для DLQ.
  # Эта логика покрывает все три случая:
  # 1. Если var.dlq_target_arn передан, используем его.
  # 2. Если не передан, но var.create_dlq = true, используем ARN создаваемого ресурса.
  # 3. Если ни одно из условий не выполнено, значение будет null, что не вызовет ошибок.
  final_dlq_arn = var.dlq_target_arn != null ? var.dlq_target_arn : (var.create_dlq ? yandex_message_queue.dlq[0].arn : null)
}

# Основной ресурс - очередь сообщений
resource "yandex_message_queue" "main" {
  name                        = var.name
  fifo_queue                  = var.is_fifo
  content_based_deduplication = var.is_fifo ? var.content_based_deduplication : null
  tags                        = var.tags

  # Добавлены недостающие параметры из variables.tf для полноты модуля
  visibility_timeout_seconds = var.visibility_timeout_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  message_retention_seconds  = var.message_retention_seconds
  access_key                 = var.access_key
  secret_key                 = var.secret_key

  # Условное создание redrive_policy.
  # Атрибут будет добавлен к ресурсу, только если local.final_dlq_arn не является null.
  # В противном случае Terraform просто проигнорирует этот блок, что нам и нужно.
  redrive_policy = local.final_dlq_arn != null ? jsonencode({
    deadLetterTargetArn = local.final_dlq_arn
    maxReceiveCount     = var.dlq_max_receive_count
  }) : null

  # Зависимость гарантирует, что DLQ будет создана до того, как основная очередь
  # попытается на нее сослаться (если DLQ создается этим модулем).
  depends_on = [
    yandex_message_queue.dlq
  ]
}

# Ресурс очереди для недоставленных сообщений (DLQ)
resource "yandex_message_queue" "dlq" {
  # Создаем этот ресурс, только если create_dlq = true И не передан внешний ARN.
  count = var.create_dlq && var.dlq_target_arn == null ? 1 : 0

  # Имя для DLQ генерируется на основе имени основной очереди.
  # Если var.dlq_name не задано, формируем его автоматически.
  name       = coalesce(var.dlq_name, "${var.name}-dlq${var.is_fifo ? ".fifo" : ""}")
  fifo_queue = var.is_fifo
  tags       = var.tags

  # Параметры для DLQ, можно вынести в отдельные переменные при необходимости
  message_retention_seconds = 1209600 # Для DLQ часто ставят максимальный срок хранения
}
