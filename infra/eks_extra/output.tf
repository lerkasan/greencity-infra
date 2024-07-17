output "external_secrets_irsa_role_arn" {
  value       = module.external_secrets_irsa_role.iam_role_arn
  description = "External Secrets IRSA role ARN"
}

