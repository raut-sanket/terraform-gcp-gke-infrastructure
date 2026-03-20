# Terraform GCP GKE Infrastructure

Production-grade Google Kubernetes Engine (GKE) cluster provisioning with Terraform. Includes VPC networking, IAM service accounts, node pool configuration with cluster autoscaling, and security hardening — based on real production infrastructure running a DeFi platform with 50+ pods.

---

## Problem Statement

Provisioning GKE clusters manually through the Console leads to undocumented infrastructure, configuration drift between environments, and inability to reproduce or audit changes. Need repeatable, version-controlled infrastructure that enforces networking isolation, least-privilege IAM, and cost-optimized node pools.

## Solution

Terraform modules that provision a production-ready GKE cluster with:
- Private VPC with custom subnets and secondary ranges for pods/services
- Right-sized node pools (`e2-custom-2-8192`) with cluster autoscaler (0–3 nodes)
- Workload Identity for pod-level GCP IAM bindings
- Network policies and private cluster configuration

---

## Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                        GCP Project                           │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Custom VPC                          │  │
│  │                                                        │  │
│  │  ┌─────────────────────┐  ┌─────────────────────────┐ │  │
│  │  │  Subnet: gke-nodes  │  │  Subnet: gke-services   │ │  │
│  │  │  10.0.0.0/24        │  │  10.0.1.0/24            │ │  │
│  │  └─────────┬───────────┘  └─────────────────────────┘ │  │
│  │            │                                           │  │
│  │  ┌─────────▼───────────────────────────────────────┐  │  │
│  │  │              GKE Cluster (Private)              │  │  │
│  │  │                                                 │  │  │
│  │  │  ┌─────────────────────────────────────────┐   │  │  │
│  │  │  │     Node Pool: general-purpose          │   │  │  │
│  │  │  │     Machine: e2-custom-2-8192           │   │  │  │
│  │  │  │     Autoscaling: 0–3 nodes              │   │  │  │
│  │  │  │     Zones: us-east4-a, b, c             │   │  │  │
│  │  │  │     Preemptible: configurable           │   │  │  │
│  │  │  └─────────────────────────────────────────┘   │  │  │
│  │  │                                                 │  │  │
│  │  │  ┌───────────┐ ┌────────────┐ ┌────────────┐  │  │  │
│  │  │  │ Workload  │ │ Network    │ │ Binary     │  │  │  │
│  │  │  │ Identity  │ │ Policy     │ │ AuthZ      │  │  │  │
│  │  │  └───────────┘ └────────────┘ └────────────┘  │  │  │
│  │  └─────────────────────────────────────────────────┘  │  │
│  └────────────────────────────────────────────────────────┘  │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ Cloud NAT    │  │ Cloud Router │  │ Artifact Registry│   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└──────────────────────────────────────────────────────────────┘
```

---

## Repository Structure

```
terraform-gcp-gke-infrastructure/
├── environments/
│   ├── production/
│   │   ├── main.tf              # Production cluster config
│   │   ├── variables.tf
│   │   ├── terraform.tfvars     # Production values
│   │   ├── outputs.tf
│   │   └── backend.tf           # GCS remote state
│   └── staging/
│       ├── main.tf
│       ├── variables.tf
│       ├── terraform.tfvars
│       ├── outputs.tf
│       └── backend.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf              # VPC, subnets, firewall rules
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── gke/
│   │   ├── main.tf              # GKE cluster + node pools
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/
│   │   ├── main.tf              # Service accounts, Workload Identity
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── artifact-registry/
│       ├── main.tf              # Container image repositories
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   ├── init-cluster.sh          # Post-provision bootstrap
│   └── cleanup.sh               # Resource teardown
├── .github/
│   └── workflows/
│       └── terraform.yml        # Plan on PR, Apply on merge
├── .gitignore
├── Makefile
└── README.md
```

---

## Tech Stack

| Component | Technology |
|---|---|
| **IaC** | Terraform >= 1.5 |
| **Cloud** | Google Cloud Platform |
| **Kubernetes** | GKE (Regular channel) |
| **Networking** | Custom VPC, Cloud NAT, Cloud Router |
| **IAM** | Workload Identity, Least-privilege SAs |
| **State** | GCS Backend with state locking |
| **CI/CD** | GitHub Actions (plan/apply pipeline) |

---

## Key Features

- **Private Cluster** — Control plane and nodes on private IPs, Cloud NAT for outbound
- **Cluster Autoscaler** — 0 to 3 nodes based on pending pod demand
- **Right-Sized Nodes** — `e2-custom-2-8192` (2 vCPU, 8GB RAM) optimized for mixed workloads
- **Multi-Zone HA** — Nodes spread across 3 availability zones
- **Workload Identity** — No static service account keys; pods bind to GCP IAM natively
- **Firewall Hardening** — No default VPC; explicit ingress/egress rules only
- **Remote State** — GCS backend with locking to prevent concurrent applies
- **Environment Isolation** — Separate tfvars per environment, shared modules

---

## Quick Start

```bash
# Initialize
cd environments/production
terraform init

# Preview changes
terraform plan -var-file=terraform.tfvars

# Apply infrastructure
terraform apply -var-file=terraform.tfvars

# Get cluster credentials
gcloud container clusters get-credentials <cluster-name> \
  --region us-east4 --project <project-id>
```

---

## Production Metrics

| Metric | Value |
|---|---|
| Monthly compute cost | $106 (optimized from $250) |
| Node pool scaling | 0–3 nodes |
| Availability zones | 3 |
| Pod capacity | 50+ pods |
| Cost reduction achieved | 58% |

---

## Screenshots (Suggested)

- GCP Console: GKE cluster overview showing node pool and autoscaler config
- Terraform plan output showing resource changes
- GitHub Actions workflow run showing plan/apply stages
- Cost comparison chart (before/after optimization)

---

## Author

**Sanket Raut** — DevOps Engineer  
[LinkedIn](https://linkedin.com/in/sanket-raut) · [Email](mailto:sanketraut.cloud@gmail.com)
