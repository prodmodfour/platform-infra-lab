output "environment_name" {
  description = "Environment represented by this Terraform root."
  value       = local.environment
}

output "aws_region" {
  description = "AWS region configured for this environment root."
  value       = var.aws_region
}

output "name_prefix" {
  description = "Public-safe naming prefix for future resources."
  value       = local.name_prefix
}

output "common_tags" {
  description = "Common public-safe tags passed to future modules."
  value       = local.common_tags
}

output "network_defaults" {
  description = "Network defaults that will be passed to the network module in a later ticket."
  value       = local.network_defaults
}

output "platform_defaults" {
  description = "Cost and availability defaults that future modules will consume."
  value       = local.platform_defaults
}

output "planned_module_contract" {
  description = "Planned module set shared by dev and prod; module calls are added ticket-by-ticket."
  value       = local.planned_module_contract
}
