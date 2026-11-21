output "queue_id" {
  description = "Message queue URL."
  value       = module.standard_queue.id
}

output "queue_arn" {
  description = "Message queue ARN."
  value       = module.standard_queue.arn
}

output "dlq_id" {
  description = "Dead letter queue URL."
  value       = module.standard_queue.dlq_id
}

output "dlq_name" {
  description = "Dead letter queue name."
  value       = module.standard_queue.dlq_name
}

output "dlq_arn" {
  description = "Dead letter queue ARN."
  value       = module.standard_queue.dlq_arn
}

output "fifo_queue_id" {
  description = "FIFO message queue URL."
  value       = module.fifo_queue.id
}

output "fifo_queue_arn" {
  description = "FIFO message queue ARN."
  value       = module.fifo_queue.arn
}

output "fifo_dlq_id" {
  description = "FIFO dead letter queue URL."
  value       = module.fifo_queue.dlq_id
}

output "fifo_dlq_name" {
  description = "FIFO dead letter queue name."
  value       = module.fifo_queue.dlq_name
}
