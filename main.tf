resource "yandex_storage_bucket" "example_bucket" {
  bucket     = "${var.project_name}-${var.environment}-bucket"
  access_key = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key = yandex_iam_service_account_static_access_key.sa_static_key.secret_key
  max_size   = var.bucket_max_size

  anonymous_access_flags {
    read = false
    list = false
  }

  depends_on = [yandex_resourcemanager_folder_iam_member.sa_roles]
}

resource "yandex_iam_service_account_static_access_key" "sa_static_key" {
  service_account_id = yandex_iam_service_account.example_sa.id
  description        = "Static access key for S3 bucket and Message Queue"

  depends_on = [yandex_resourcemanager_folder_iam_member.sa_roles]
}

resource "yandex_iam_service_account" "example_sa" {
  name        = "${var.project_name}-${var.environment}-sa"
  description = "Service account for S3 bucket and Message Queue"
  folder_id   = local.folder_id
}

resource "yandex_resourcemanager_folder_iam_member" "sa_roles" {
  for_each  = toset(["storage.admin", "ymq.admin"])
  folder_id = local.folder_id
  role      = each.value
  member    = "serviceAccount:${yandex_iam_service_account.example_sa.id}"
}

resource "yandex_message_queue" "example_queue" {
  name                        = var.queue_name
  visibility_timeout_seconds  = var.visibility_timeout
  message_retention_seconds   = var.message_retention
  receive_wait_time_seconds   = var.receive_wait_time
  max_message_size            = var.max_message_size
  delay_seconds               = var.delay_seconds
  access_key                  = yandex_iam_service_account_static_access_key.sa_static_key.access_key
  secret_key                  = yandex_iam_service_account_static_access_key.sa_static_key.secret_key

  depends_on = [yandex_resourcemanager_folder_iam_member.sa_roles]
}