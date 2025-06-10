output "queue_arn" {
  description = "ARN (Amazon Resource Name) созданной основной очереди."
  value       = yandex_message_queue.main.arn
}

output "queue_id" {
  description = "ID (URL) созданной основной очереди."
  value       = yandex_message_queue.main.id
}

output "queue_name" {
  description = "Имя созданной основной очереди."
  value       = yandex_message_queue.main.name
}

output "dlq_arn" {
  description = "ARN очереди недоставленных сообщений (если создана или передана)."
  value       = local.final_dlq_arn
}

output "dlq_id" {
  description = "ID (URL) созданной Dead Letter Queue. Будет 'null', если DLQ не создавалась."
  value       = var.create_dlq ? yandex_message_queue.dlq[0].id : null
}

output "dlq_name" {
  description = "Имя созданной Dead Letter Queue. Будет 'null', если DLQ не создавалась."
  value       = var.create_dlq ? yandex_message_queue.dlq[0].name : null
}

output "main_queue_arn" {
  description = "ARN созданной основной очереди."
  value       = yandex_message_queue.main.arn
}

output "main_queue_url" {
  description = "URL созданной основной очереди."
  value       = yandex_message_queue.main.id
}
