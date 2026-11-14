# Minimal example

This example creates one standard message queue with the module's default
settings.

## Usage

```bash
export YC_TOKEN="$(yc iam create-token)"
export YC_MESSAGE_QUEUE_ACCESS_KEY="<key_id>"
export YC_MESSAGE_QUEUE_SECRET_KEY="<secret>"

terraform init
terraform plan
terraform apply
terraform destroy
```

The static access key must belong to a service account from the folder where
the queue should be created and the service account needs the `ymq.admin` role.

Note that this example may create resources which can cost money. Run
`terraform destroy` when you don't need these resources.
