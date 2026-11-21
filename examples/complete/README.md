# Complete example

This example creates:

- a standard queue with a dead letter queue and a redrive policy;
- a FIFO queue with content-based deduplication and its own FIFO dead letter
  queue.

Both dead letter queues are configured explicitly with their own visibility
timeout, long polling, retention period, maximum message size and tags, so the
example also covers the `dlq_*` module inputs. The FIFO dead letter queue also
enables content-based deduplication.

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
the queues should be created and the service account needs the `ymq.admin`
role.

Note that this example may create resources which can cost money. Run
`terraform destroy` when you don't need these resources.
