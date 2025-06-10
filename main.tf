# Локальные переменные для вычислений
locals {
  # Определяем имя для DLQ: используем переданное или генерируем на основе имени основной очереди
  dlq_name = var.dlq_name != null ? var.dlq_name : "${var.name}-dlq"

  # Определяем, нужно ли использовать политику перенаправления в DLQ
  is_dlq_enabled = var.create_dlq || var.dlq_target_arn != null

  # Определяем ARN для DLQ: либо из создаваемой очереди, либо из переданной переменной
  final_dlq_arn = var.create_dlq ? yandex_message_queue.dlq[0].arn : var.dlq_target_arn

  # Формируем политику перенаправления сообщений (redrive policy) в формате JSON
  redrive_policy = local.is_dlq_enabled ? jsonencode({
    deadLetterTargetArn = local.final_dlq_arn
    maxReceiveCount     = var.max_receive_count
  }) : null
}

# --- Основная очередь сообщений ---
resource "yandex_message_queue" "main" {
  # Имя очереди, передаваемое извне модуля
  name = var.is_fifo ? (strcontains(var.name, ".fifo") ? var.name : "${var.name}.fifo") : var.name

  # Ключи доступа для Yandex Message Queue.
  # Эти значения передаются напрямую в ресурс, как вы и просили.
  # Теперь они используют правильные имена переменных из variables.tf.
  access_key = var.access_key
  secret_key = var.secret_key

  # Параметры очереди, управляемые через переменные
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds

  # Параметры, специфичные для FIFO-очередей
  content_based_deduplication = var.is_fifo ? var.content_based_deduplication : null
  fifo_queue                    = var.is_fifo

  # Применяем политику перенаправления в DLQ, если она включена
  redrive_policy = local.redrive_policy

  # Добавляем теги для лучшей идентификации ресурса
  tags = merge(
    var.tags,
    {
      created_by = "terraform-module"
    }
  )
}

# --- Очередь недоставленных сообщений (Dead Letter Queue) ---
# Создается только если var.create_dlq установлено в true
resource "yandex_message_queue" "dlq" {
  # Используем count для условного создания ресурса
  count = var.create_dlq ? 1 : 0

  name       = local.dlq_name
  access_key = var.access_key
  secret_key = var.secret_key

  # DLQ обычно имеет такие же или более длительные сроки хранения
  message_retention_seconds = var.message_retention_seconds

  # FIFO-статус для DLQ должен соответствовать основной очереди
  fifo_queue = var.is_fifo

  tags = merge(
    var.tags,
    {
      created_by = "terraform-module",
      dlq_for    = var.name
    }
  )
}
