# Project Bedrock — InnovateMart EKS Deployment

Production-grade EKS deployment for the retail-store-sample-app, built as a
graded capstone. Infrastructure is provisioned with Terraform, deployed to
Kubernetes via Helm, and automated via GitHub Actions.

![Architecture Diagram](./architecture.png)

## Tech Stack

| Layer | Technology |
|---|---|
| IaC | Terraform 1.11+ (S3 backend, native state locking) |
| Container Orchestration | Amazon EKS 1.34, managed node group |
| Application Deployment | Helm 3 (umbrella chart wrapping 5 upstream service charts) |
| Data Layer | RDS MySQL, RDS PostgreSQL, DynamoDB, Secrets Manager |
| Networking | VPC (2 AZs), single NAT Gateway, AWS Load Balancer Controller (ALB) |
| Observability | CloudWatch (control plane logs + Container Insights) |
| Serverless | S3 + Lambda (event-driven image processing) |
| CI/CD | GitHub Actions, OIDC-authenticated (no static AWS keys) |
| Security | IAM least-privilege roles, IRSA, EKS Access Entries, NetworkPolicy |

## Prerequisites

Install and confirm each of these before starting:

```powershell
terraform -version    # >= 1.11.0
aws --version
kubectl version --client
helm version           # >= 3.8 (dependency/alias support)
git --version
aws sts get-caller-identity   # confirms AWS credentials are configured
```

## Repository Structure
```
project-bedrock/
├── main.tf, variables.tf, outputs.tf, providers.tf, versions.tf, backend.tf
├── locals.tf
├── terraform.tfvars.example
├── modules/
│ ├── networking/ # VPC, subnets, NAT Gateway
│ ├── eks/ # EKS cluster, node group, IAM, LB Controller, autoscaler
│ ├── data-layer/ # RDS MySQL/Postgres, DynamoDB, Secrets Manager
│ ├── iam/ # bedrock-dev-view user, carts IRSA role
│ ├── k8s/ # namespace, Terraform-managed K8s Secrets
│ ├── observability/ # CloudWatch Observability EKS add-on
│ ├── serverless/ # S3 bucket, Lambda, event trigger
│ ├── cicd/ # GitHub OIDC provider + role
│ ├── cost-guardrails/ # AWS Budget alert
│ ├── tls/ # self-signed cert imported to ACM (bonus 5.2)
│ └── network-policies/ # NetworkPolicy resources (bonus 5.4)
├── helm/retail-store/ # umbrella Helm chart (bonus 5.1)
├── k8s/values/ # per-service Helm values overrides (reference/debug)
├── lambda/ # bedrock-asset-processor source
└── .github/workflows/ # terraform-plan.yml, terraform-apply.yml
```


## Branching Strategy
```
main → protected; only accepts PRs from review; merge triggers terraform apply
review → integration branch; all feature branches merge here first
feature/* → one branch per capability, one PR per branch
```


Roadmap (each row = one feature branch → PR into `review`):

| Branch | Covers |
|---|---|
| feature/project-structure | scaffold, backend, providers, variables |
| feature/networking | VPC, subnets, single NAT Gateway |
| feature/eks-cluster | EKS cluster (v1.34), managed node group, IAM roles, control plane logging |
| feature/data-layer | RDS MySQL (catalog), RDS PostgreSQL (orders), DynamoDB (carts), Secrets Manager |
| feature/security-access | bedrock-dev-view IAM user, EKS Access Entries |
| feature/app-deployment | Helm deploy of all 5 services, AWS LB Controller, ALB ingress |
| feature/observability | CloudWatch Observability EKS add-on (container logs) |
| feature/serverless | S3 assets bucket, bedrock-asset-processor Lambda, event trigger |
| feature/cicd | GitHub Actions — plan on PR, apply on merge to main |
| feature/cost-guardrails | AWS Budget alert, this teardown guide |

## Bootstrap (one-time, before `terraform init` works)

```powershell
$StudentId = "alt-soe-tin-025-0310"
$StateBucket = "bedrock-tfstate-$StudentId"

aws s3api create-bucket --bucket $StateBucket --region us-east-1
aws s3api put-bucket-versioning --bucket $StateBucket --versioning-configuration Status=Enabled
aws s3api put-bucket-encryption --bucket $StateBucket --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
```

Update `backend.tf` with that bucket name, copy `terraform.tfvars.example` to
`terraform.tfvars`, fill in `student_id`, `budget_alert_email`, and
`github_repo`, then:

```powershell
terraform init
terraform apply
```

## Deployment Guide

1. `terraform apply` provisions VPC, EKS, RDS, DynamoDB, IAM, the CloudWatch
   add-on, the S3/Lambda pair, and the AWS Load Balancer Controller.
2. Fill in `<MYSQL_ENDPOINT>`, `<POSTGRES_ENDPOINT>`, and `<CARTS_IRSA_ROLE_ARN>`
   placeholders in `helm/retail-store/values.yaml` using the real values from
   `terraform apply` output / `terraform state show`.
3. `aws eks update-kubeconfig --region us-east-1 --name project-bedrock-cluster`
4. Deploy all 5 services with one real Helm command, via the umbrella chart
   in `helm/retail-store/` (bonus 5.1 — see that folder's `Chart.yaml` for how
   it wraps the 5 upstream service charts as dependencies):
```powershell
   helm dependency update .\helm\retail-store
   helm upgrade --install retail-store .\helm\retail-store `
     --namespace retail-app --create-namespace `
     -f .\helm\retail-store\values.yaml
```
   (`k8s/values/*.yaml` — the five individual per-service values files — are
   kept in the repo too, useful if you ever need to debug/redeploy one service
   on its own, but the umbrella chart above is the primary, single-command
   deploy path.)
5. `kubectl get ingress -n retail-app` — the ALB's DNS name appears in the
   `ADDRESS` column once the LB Controller finishes provisioning it (a couple
   of minutes). That URL is how to access the running store.

## Teardown Guide

Order matters — Kubernetes-managed AWS resources (the ALB, in particular)
need to be removed before Terraform destroys the VPC/subnets they live in,
or `terraform destroy` will hang waiting on a dependency it doesn't know
about.

```powershell
# 1. Remove the Helm release first — this deletes the ALB itself
helm uninstall retail-store --namespace retail-app

# 2. Destroy all Terraform-managed infrastructure
terraform destroy

# 3. Manual cleanup — these are NOT in Terraform state and won't be removed
#    by `destroy`:

# 3a. Empty and delete the assets S3 bucket
aws s3 rm s3://bedrock-assets-alt-soe-tin-025-0310 --recursive
aws s3api delete-bucket --bucket bedrock-assets-alt-soe-tin-025-0310 --region us-east-1

# 3b. CloudWatch log groups created automatically by EKS control plane logging
#     and the Observability add-on are NOT managed by Terraform and persist
#     after destroy:
aws logs delete-log-group --log-group-name /aws/eks/project-bedrock-cluster/cluster
aws logs describe-log-groups --log-group-name-prefix "/aws/containerinsights/project-bedrock-cluster" --query "logGroups[*].logGroupName" --output text
aws logs delete-log-group --log-group-name /aws/lambda/bedrock-asset-processor

# 3c. Deactivate/delete the bedrock-dev-view access key used for grading
aws iam list-access-keys --user-name bedrock-dev-view
aws iam update-access-key --user-name bedrock-dev-view --access-key-id <key-id> --status Inactive

# 3d. Remove the state bucket manually once fully done:
aws s3 rm s3://bedrock-tfstate-alt-soe-tin-025-0310 --recursive
aws s3api delete-bucket --bucket bedrock-tfstate-alt-soe-tin-025-0310 --region us-east-1
```

**Cost reminder:** EKS clusters, NAT Gateways, RDS instances, and ALBs incur
ongoing charges. If you're pausing work rather than finishing, at minimum
scale the EKS node group to 0 and stop the RDS instances rather than leaving
everything running.