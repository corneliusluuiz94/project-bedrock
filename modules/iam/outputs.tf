# These are intentionally NOT wired into the root outputs.tf — the assessment
# requires the five root outputs stay non-sensitive (terraform output -json
# reveals sensitive values in full). Pull these individually with -raw instead:
#
#   terraform output -raw dev_user_access_key_id
#   terraform output -raw dev_user_secret_access_key
#   terraform output -raw dev_user_console_password
#
# Copy them into your grading deliverable doc directly — never into a committed file.

output "dev_user_arn" {
  value = aws_iam_user.dev_view.arn
}

output "dev_user_access_key_id" {
  value     = aws_iam_access_key.dev_view.id
  sensitive = true
}

output "dev_user_secret_access_key" {
  value     = aws_iam_access_key.dev_view.secret
  sensitive = true
}

output "dev_user_console_password" {
  value     = aws_iam_user_login_profile.dev_view.password
  sensitive = true
}
