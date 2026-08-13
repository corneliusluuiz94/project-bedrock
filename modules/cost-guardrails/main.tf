variable "budget_amount_usd" {
  type    = number
  default = 20
}

variable "budget_alert_email" {
  description = "Email address to receive the budget alert"
  type        = string
}

variable "project_tag" {
  type = string
}

resource "aws_budgets_budget" "project" {
  name         = "project-bedrock-monthly-budget"
  budget_type  = "COST"
  limit_amount = tostring(var.budget_amount_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  # Scoped to only resources carrying our mandatory Project tag — this budget
  # won't fire because of unrelated spend elsewhere in the account.
  # AWS Budgets tag filter format is "user:TagKey$TagValue" — format() avoids
  # HCL's own "$${" escaping ambiguity when building that string.
  cost_filter {
    name   = "TagKeyValue"
    values = [format("user:Project$%s", var.project_tag)]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80 # alert at 80% of budget, before you actually hit the limit
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alert_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED" # also warn if the current trend is projected to exceed budget
    subscriber_email_addresses = [var.budget_alert_email]
  }
}
