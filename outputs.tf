output "id" {
  description = "Message queue URL."
  value       = yandex_message_queue.this.id
}

output "arn" {
  description = "Message queue ARN."
  value       = yandex_message_queue.this.arn
}

output "name" {
  description = "Message queue name."
  value       = yandex_message_queue.this.name
}

output "dlq_id" {
  description = "Dead letter queue URL, or null when the module does not create a DLQ."
  value       = var.create_dlq ? yandex_message_queue.dlq[0].id : null
}

output "dlq_arn" {
  description = "Dead letter queue ARN, or null when the module does not create a DLQ."
  value       = var.create_dlq ? yandex_message_queue.dlq[0].arn : null
}
