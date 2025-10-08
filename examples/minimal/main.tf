module "storage_buckets" {
  source = "git::https://github.com/terraform-yacloud-modules/terraform-yandex-storage-bucket.git?ref=v1.0.0"

  bucket_name = "my-unique-bucket-name"
}

module "minimal-example" {
  source = "../.." // Укажите путь к директории с модулем

  name = "minimal-example"

  # ОБЯЗАТЕЛЬНО: Передайте статические ключи доступа
  # Рекомендуется хранить их в секретах (Vault, Yandex Lockbox) и передавать через переменные окружения TF_VAR_
  access_key = module.storage_buckets.storage_admin_access_key
  secret_key = module.storage_buckets.storage_admin_secret_key
}
