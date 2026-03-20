output "cluster_name" {
  description = "GKE cluster name"
  value       = google_container_cluster.primary.name
}

output "cluster_endpoint" {
  description = "GKE cluster endpoint"
  value       = google_container_cluster.primary.endpoint
  sensitive   = true
}

output "cluster_ca_certificate" {
  description = "Base64-encoded public certificate of the cluster CA"
  value       = google_container_cluster.primary.master_auth[0].cluster_ca_certificate
  sensitive   = true
}

output "cluster_location" {
  description = "Cluster location (region)"
  value       = google_container_cluster.primary.location
}

output "node_pool_name" {
  description = "Name of the general-purpose node pool"
  value       = google_container_node_pool.general.name
}
