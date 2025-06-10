variable "name" {
  description = "Уникальное имя создаваемой очереди сообщений. Должно соответствовать требованиям Yandex Cloud."
  type        = string
}

variable "is_fifo" {
  description = "Установить в 'true' для создания FIFO-очереди. Для стандартной очереди оставьте 'false'. При создании FIFO-очереди имя должно заканчиваться на '.fifo'."
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Таймаут видимости сообщения в секундах. После того как компонент получил сообщение, оно становится невидимым для других компонентов на это время."
  type        = number
  default     = 600
}

variable "receive_wait_time_seconds" {
  description = "Время ожидания поступления сообщений в очередь при использовании Long Polling (в секундах). Возможные значения: от 0 до 20."
  type        = number
  default     = 20
}

variable "message_retention_seconds" {
  description = "Срок хранения сообщений в очереди в секундах. Минимальное значение: 60 (1 минута), максимальное: 1209600 (14 дней)."
  type        = number
  default     = 1209600
}

variable "content_based_deduplication" {
  description = "Включение дедупликации по содержимому. Актуально только для FIFO-очередей. Если 'true', сообщения с одинаковым телом, отправленные в течение 5-минутного интервала, будут считаться дубликатами."
  type        = bool
  default     = false
}

variable "create_dlq" {
  description = "Установить в 'true', чтобы автоматически создать Dead Letter Queue (DLQ) для этой очереди. Если 'true', необходимо также указать 'max_receive_count'."
  type        = bool
  default     = false
}

variable "dlq_name" {
  description = "Имя для автоматически создаваемой DLQ. Если не указано, будет сгенерировано на основе имени основной очереди (например, 'my-queue-dlq')."
  type        = string
  default     = null
}

variable "dlq_target_arn" {
  description = "ARN существующей очереди, которую нужно использовать в качестве DLQ. Если указано, 'create_dlq' будет проигнорировано."
  type        = string
  default     = null
}

variable "max_receive_count" {
  description = "Количество попыток чтения сообщения из основной очереди перед его отправкой в DLQ. Обязательно, если используется политика перенаправления (create_dlq=true или указан dlq_target_arn)."
  type        = number
  default     = 3
}

variable "access_key" {
  description = "Идентификатор статического ключа доступа сервисного аккаунта для очереди. Если не задан, будет использоваться ключ из конфигурации провайдера."
  type        = string
  default     = null
  sensitive   = true
}

variable "secret_key" {
  description = "Секретная часть статического ключа доступа. Если не задан, будет использоваться ключ из конфигурации провайдера."
  type        = string
  default     = null
  sensitive   = true
}

variable "tags" {
  description = "Карта тегов для основной очереди."
  type        = map(string)
  default     = {}
}

variable "dlq_max_receive_count" {
  description = "Максимальное количество раз, которое сообщение будет получено перед отправкой в DLQ."
  type        = number
  default     = 3
}
