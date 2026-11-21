#
# naming
#
variable "name" {
  description = "Message queue name. FIFO queue names must end with the .fifo suffix."
  type        = string

  validation {
    condition = (
      length(var.name) >= 1 && length(var.name) <= 80 &&
      can(regex("^[a-zA-Z0-9_.-]+$", var.name))
    )
    error_message = "The name must be 1-80 characters long and contain only letters, numbers, hyphens, underscores, and dots."
  }
}

#
# queue configuration
#
variable "fifo_queue" {
  description = "Whether the queue is a FIFO queue. The value cannot be changed after creation."
  type        = bool
  default     = false
}

variable "content_based_deduplication" {
  description = "Enable content-based deduplication. Can be used only for FIFO queues."
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Time in seconds to delay new messages. Valid values: 0-900."
  type        = number
  default     = 0

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900
    error_message = "delay_seconds must be between 0 and 900."
  }
}

variable "max_message_size" {
  description = "Maximum message size in bytes. Valid values: 1024-262144."
  type        = number
  default     = 262144

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 262144
    error_message = "max_message_size must be between 1024 and 262144."
  }
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds. Valid values: 60-1209600."
  type        = number
  default     = 345600

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600
    error_message = "message_retention_seconds must be between 60 and 1209600."
  }
}

variable "receive_wait_time_seconds" {
  description = "Long polling wait time in seconds. Valid values: 0-20."
  type        = number
  default     = 0

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20
    error_message = "receive_wait_time_seconds must be between 0 and 20."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for received messages in seconds. Valid values: 0-43200."
  type        = number
  default     = 30

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200
    error_message = "visibility_timeout_seconds must be between 0 and 43200."
  }
}

variable "region_id" {
  description = "Region where the message queue is located. Defaults to the provider region (ru-central1)."
  type        = string
  default     = null
}

variable "tags" {
  description = "A set of tags for the queue."
  type        = map(string)
  default     = {}
}

#
# dead letter queue
#
variable "create_dlq" {
  description = "Create a dead letter queue for this queue and configure a redrive policy."
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Name of the dead letter queue created by the module. Defaults to <name>-dlq or <name>-dlq.fifo for FIFO queues."
  type        = string
  default     = null

  validation {
    condition = var.dlq_name == null ? true : (
      length(var.dlq_name) >= 1 && length(var.dlq_name) <= 80 &&
      can(regex("^[a-zA-Z0-9_.-]+$", var.dlq_name))
    )
    error_message = "dlq_name must be 1-80 characters long and contain only letters, numbers, hyphens, underscores, and dots."
  }
}

variable "max_receive_count" {
  description = "Number of receives before a message is moved to the dead letter queue. Valid values: 1-1000."
  type        = number
  default     = 3

  validation {
    condition     = var.max_receive_count >= 1 && var.max_receive_count <= 1000
    error_message = "max_receive_count must be between 1 and 1000."
  }
}

variable "redrive_policy" {
  description = "Explicit redrive policy in JSON format for an existing dead letter queue. Cannot be used with create_dlq."
  type        = string
  default     = null

  validation {
    condition = var.redrive_policy == null || try(
      jsondecode(var.redrive_policy).deadLetterTargetArn != null &&
      jsondecode(var.redrive_policy).maxReceiveCount != null,
      false
    )
    error_message = "redrive_policy must be a valid JSON object with deadLetterTargetArn and maxReceiveCount, or null."
  }
}

#
# dead letter queue settings
#
variable "dlq_visibility_timeout_seconds" {
  description = "Visibility timeout for messages in the dead letter queue, in seconds. Valid values: 0-43200."
  type        = number
  default     = 30

  validation {
    condition     = var.dlq_visibility_timeout_seconds >= 0 && var.dlq_visibility_timeout_seconds <= 43200
    error_message = "dlq_visibility_timeout_seconds must be between 0 and 43200."
  }
}

variable "dlq_receive_wait_time_seconds" {
  description = "Long polling wait time for the dead letter queue, in seconds. Valid values: 0-20."
  type        = number
  default     = 0

  validation {
    condition     = var.dlq_receive_wait_time_seconds >= 0 && var.dlq_receive_wait_time_seconds <= 20
    error_message = "dlq_receive_wait_time_seconds must be between 0 and 20."
  }
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for the dead letter queue, in seconds. Valid values: 60-1209600."
  type        = number
  default     = 345600

  validation {
    condition     = var.dlq_message_retention_seconds >= 60 && var.dlq_message_retention_seconds <= 1209600
    error_message = "dlq_message_retention_seconds must be between 60 and 1209600."
  }
}

variable "dlq_max_message_size" {
  description = "Maximum message size for the dead letter queue, in bytes. Valid values: 1024-262144."
  type        = number
  default     = 262144

  validation {
    condition     = var.dlq_max_message_size >= 1024 && var.dlq_max_message_size <= 262144
    error_message = "dlq_max_message_size must be between 1024 and 262144."
  }
}

variable "dlq_delay_seconds" {
  description = "Time in seconds to delay new messages in the dead letter queue. Valid values: 0-900."
  type        = number
  default     = 0

  validation {
    condition     = var.dlq_delay_seconds >= 0 && var.dlq_delay_seconds <= 900
    error_message = "dlq_delay_seconds must be between 0 and 900."
  }
}

variable "dlq_content_based_deduplication" {
  description = "Enable content-based deduplication for the dead letter queue. Can be used only for FIFO queues created by the module."
  type        = bool
  default     = false
}

variable "dlq_tags" {
  description = "A set of tags for the dead letter queue. Defaults to the tags of the source queue."
  type        = map(string)
  default     = null
}
