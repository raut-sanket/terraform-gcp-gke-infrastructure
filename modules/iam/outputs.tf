output "gke_node_sa_email" {
  description = "Email of the GKE node service account"
  value       = google_service_account.gke_nodes.email
}

output "workload_sa_emails" {
  description = "Map of workload service account emails"
  value       = { for k, v in google_service_account.workload : k => v.email }
}

output "cicd_sa_email" {
  description = "Email of the CI/CD service account"
  value       = var.create_cicd_sa ? google_service_account.cicd[0].email : ""
}

output "wif_provider_name" {
  description = "Workload Identity Federation provider resource name"
  value       = var.create_cicd_sa && var.github_repo != "" ? google_iam_workload_identity_pool_provider.github[0].name : ""
}
