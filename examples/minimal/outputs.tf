output "id" {
  description = "Message queue URL."
  value       = module.queue.id
}

output "arn" {
  description = "Message queue ARN."
  value       = module.queue.arn
}

output "name" {
  description = "Message queue name."
  value       = module.queue.name
}
