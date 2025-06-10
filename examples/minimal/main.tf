module "minimal-example" {
  source = "../.." // Укажите путь к директории с модулем

  name = "minimal-example"

  # ОБЯЗАТЕЛЬНО: Передайте статические ключи доступа
  # Рекомендуется хранить их в секретах (Vault, Yandex Lockbox) и передавать через переменные окружения TF_VAR_
  access_key = "YC_access_key"
  secret_key = "YC_secret_key"

}