variable "queue_name" {
  description = "Название очереди сообщений"
  type        = string
  default     = "example-terraform-queue"
}

variable "visibility_timeout" {
  description = "Время в секундах, в течение которого сообщение будет невидимо после получения"
  type        = number
  default     = 30
}

variable "message_retention" {
  description = "Время в секундах, в течение которого сообщения будут храниться в очереди"
  type        = number
  default     = 345600 # 4 дня
}

variable "receive_wait_time" {
  description = "Время в секундах ожидания при получении сообщений (long polling)"
  type        = number
  default     = 0
}

variable "max_message_size" {
  description = "Максимальный размер сообщения в байтах"
  type        = number
  default     = 262144 # 256 KB
}

variable "delay_seconds" {
  description = "Задержка в секундах перед тем как сообщение станет доступным для получения"
  type        = number
  default     = 0
}

variable "environment" {
  description = "Окружение (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Название проекта"
  type        = string
  default     = "terraform-example"
}


variable "folder_id" {
  description = "ID каталога Yandex Cloud"
  type        = string
  default     = null
}



variable "bucket_max_size" {
  description = "Максимальный размер бакета в байтах"
  type        = number
  default     = 5368709120 # 5 GB
}