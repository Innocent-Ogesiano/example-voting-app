output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}

output "hcp_terraform_role_arn" {
  description = "Set as TFC_AWS_RUN_ROLE_ARN on the HCP Terraform workspace"
  value       = aws_iam_role.hcp_terraform.arn
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.github_actions.arn
}
