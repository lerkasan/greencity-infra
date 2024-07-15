output "external_secrets_irsa_role_arn" {
  value       = module.external_secrets_irsa_role.iam_role_arn
  description = "External Secrets IRSA role ARN"
}

# output "grafana_admin_password" {
#   value       = random_password.grafana_admin_password.result
#   description = "grafana admin password"
#   sensitive = true
# }

