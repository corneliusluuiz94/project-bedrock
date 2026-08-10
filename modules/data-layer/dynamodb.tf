# Schema confirmed against src/cart/src/main/java/.../repositories/dynamo/entities/DynamoItemEntity.java:
#   - partition key: id (String)
#   - GSI "idx_global_customerId" on customerId (String) — used by DynamoDBCartService
#     to fetch all items belonging to a customer's cart.

resource "aws_dynamodb_table" "carts" {
  name         = var.carts_table_name
  billing_mode = "PAY_PER_REQUEST" # on-demand — no capacity planning needed for an assessment workload
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  attribute {
    name = "customerId"
    type = "S"
  }

  global_secondary_index {
    name            = "idx_global_customerId"
    hash_key        = "customerId"
    projection_type = "ALL" # service needs full item attributes (itemId, quantity, unitPrice) back from this query
  }

  point_in_time_recovery {
    enabled = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = { Name = var.carts_table_name }
}
