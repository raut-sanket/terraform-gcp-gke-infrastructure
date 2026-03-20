output "network_id" {
  description = "VPC network ID"
  value       = google_compute_network.main.id
}

output "network_name" {
  description = "VPC network name"
  value       = google_compute_network.main.name
}

output "subnet_id" {
  description = "GKE nodes subnet ID"
  value       = google_compute_subnetwork.gke_nodes.id
}

output "subnet_name" {
  description = "GKE nodes subnet name"
  value       = google_compute_subnetwork.gke_nodes.name
}

output "pods_range_name" {
  description = "Name of the secondary range for pods"
  value       = "pods"
}

output "services_range_name" {
  description = "Name of the secondary range for services"
  value       = "services"
}
