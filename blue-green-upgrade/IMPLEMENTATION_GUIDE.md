# Blue-Green EKS Cluster Migration - Complete Implementation Guide

## Overview
This guide provides step-by-step instructions to implement a blue-green deployment strategy for EKS clusters using Terraform, ArgoCD, and AWS Route 53 weighted routing.

## Architecture
- **Blue Cluster**: Production cluster serving 100% traffic initially
- **Green Cluster**: New cluster for testing and gradual traffic migration
- **Route 53**: Weighted routing for traffic distribution
- **ArgoCD**: GitOps deployment automation
- **External DNS**: Automatic DNS record management

## Prerequisites

### Required Tools
```bash
# Install required CLI tools
brew install terraform
brew install awscli
brew install kubectl
brew install git
```

### AWS Requirements
- AWS CLI configured with admin permissions
- Existing Route 53 hosted zone (e.g., `example.com`)
- GitHub SSH key stored in AWS Secrets Manager

### GitHub SSH Key Setup
```bash
# Create SSH key for GitHub access
ssh-keygen -t rsa -b 4096 -C "your-email@example.com" -f ~/.ssh/github_key

# Add public key to GitHub account
cat ~/.ssh/github_key.pub

# Store private key in AWS Secrets Manager
aws secretsmanager create-secret \
  --name "github-blueprint-ssh-key" \
  --description "GitHub SSH private key for EKS blueprints" \
  --secret-string file://~/.ssh/github_key
```

## Step 1: Environment Setup

### Clone Repository
```bash
git clone https://github.com/aws-ia/terraform-aws-eks-blueprints.git
cd terraform-aws-eks-blueprints/patterns/blue-green-upgrade/
```

### Configure Variables
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Create symlinks for shared configuration
ln -s ../terraform.tfvars environment/terraform.tfvars
ln -s ../terraform.tfvars eks-blue/terraform.tfvars
ln -s ../terraform.tfvars eks-green/terraform.tfvars
```

### Edit Configuration
```bash
# Edit terraform.tfvars with your values
cat > terraform.tfvars << EOF
aws_region          = "us-west-2"
environment_name    = "eks-blueprint"
hosted_zone_name    = "example.com"  # Your existing hosted zone
eks_admin_role_name = "Admin"        # Your AWS admin role

gitops_workloads_org      = "git@github.com:aws-samples"
gitops_workloads_repo     = "eks-blueprints-workloads"
gitops_workloads_revision = "main"
gitops_workloads_path     = "envs/dev"

aws_secret_manager_git_private_ssh_key_name = "github-blueprint-ssh-key"
EOF
```

## Step 2: Deploy Common Infrastructure

### Create Environment Stack
```bash
cd environment/
terraform init
terraform plan
terraform apply -auto-approve
```

**Resources Created:**
- VPC with public/private subnets
- Route 53 hosted zone: `eks-blueprint.example.com`
- ACM certificate for `*.eks-blueprint.example.com`
- Secrets Manager password for ArgoCD

### Verify Environment
```bash
terraform output
# Expected outputs:
# aws_acm_certificate_status = "ISSUED"
# aws_route53_zone = "eks-blueprint.example.com"
# vpc_id = "vpc-xxxxxxxxx"
```

## Step 3: Deploy Blue Cluster

### Create Blue Cluster
```bash
cd ../eks-blue/
terraform init
terraform plan
terraform apply -auto-approve
```

**Deployment Time:** ~15-20 minutes

### Configure kubectl Access
```bash
# Get cluster access command from terraform output
terraform output eks_blueprints_admin_team_configure_kubectl

# Example command:
aws eks --region us-west-2 update-kubeconfig \
  --name eks-blueprint-blue \
  --role-arn arn:aws:iam::123456789012:role/admin-team-xxx
```

### Verify Blue Cluster
```bash
# Check cluster status
kubectl get nodes

# Check ArgoCD applications
kubectl get applications -n argocd

# Check workload deployment
kubectl get deployment -n team-burnham -l app=burnham

# Test application endpoint
URL=$(echo -n "https://" ; kubectl get ing -n team-burnham burnham-ingress -o json | jq ".spec.rules[0].host" -r)
curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'
# Should return: eks-blueprint-blue
```

## Step 4: Deploy Green Cluster

### Create Green Cluster
```bash
cd ../eks-green/
terraform init
terraform plan
terraform apply -auto-approve
```

### Configure kubectl for Green Cluster
```bash
# Switch to green cluster context
aws eks --region us-west-2 update-kubeconfig \
  --name eks-blueprint-green \
  --role-arn arn:aws:iam::123456789012:role/admin-team-xxx
```

### Verify Green Cluster
```bash
# Check green cluster deployment
kubectl get deployment -n team-burnham -l app=burnham

# Verify Route 53 records (should show both clusters)
export ROOT_DOMAIN="example.com"
ZONE_ID=$(aws route53 list-hosted-zones-by-name \
  --output json \
  --dns-name "eks-blueprint.${ROOT_DOMAIN}." \
  --query "HostedZones[0].Id" --out text)

aws route53 list-resource-record-sets \
  --output json \
  --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name == 'burnham.eks-blueprint.$ROOT_DOMAIN.']|[?Type == 'A']"
```

## Step 5: Traffic Migration Process

### Phase 1: Blue Only (100% Blue, 0% Green)
**Current State:** All traffic goes to blue cluster

```bash
# Verify current traffic distribution
for i in {1..10}; do
  curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'
  sleep 2
done
# Should show only: eks-blueprint-blue
```

### Phase 2: Canary Testing (50% Blue, 50% Green)

#### Update Green Cluster Weight
```bash
cd eks-green/

# Edit main.tf to set route53_weight = "100"
sed -i 's/route53_weight = "0"/route53_weight = "100"/' main.tf

# Apply changes
terraform apply -auto-approve
```

#### Verify Canary Distribution
```bash
# Test traffic distribution (wait for DNS TTL)
for i in {1..20}; do
  curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'
  sleep 3
done
# Should show mix of: eks-blueprint-blue and eks-blueprint-green
```

### Phase 3: Full Migration (0% Blue, 100% Green)

#### Update Blue Cluster Weight
```bash
cd ../eks-blue/

# Set blue cluster weight to 0
sed -i 's/route53_weight = "100"/route53_weight = "0"/' main.tf

# Apply changes
terraform apply -auto-approve
```

#### Verify Full Migration
```bash
# Wait for DNS propagation (TTL = 60 seconds)
sleep 120

# Test traffic (should be 100% green)
for i in {1..10}; do
  curl -s $URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'
  sleep 2
done
# Should show only: eks-blueprint-green
```

## Step 6: Monitoring and Validation

### ArgoCD Dashboard Access
```bash
# Get ArgoCD URL
kubectl get svc -n argocd argo-cd-argocd-server -o json | \
  jq '.status.loadBalancer.ingress[0].hostname' -r

# Get ArgoCD password
aws secretsmanager get-secret-value \
  --secret-id argocd-admin-secret.eks-blueprint \
  --query SecretString \
  --output text --region $AWS_REGION
```

### DNS Resolution Monitoring
```bash
# Check DNS resolution and TTL
dig +noauthority +noquestion +noadditional +nostats +ttlunits +ttlid \
  A burnham.eks-blueprint.$ROOT_DOMAIN
```

### Application Health Checks
```bash
# Check application pods in both clusters
kubectl get pods -n team-burnham -l app=burnham

# Check ingress status
kubectl get ingress -n team-burnham

# Monitor External DNS logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f
```

## Step 7: Cleanup Process

### Automated Cleanup
```bash
# Use provided cleanup script
cd eks-blue/  # or eks-green/
../tear-down.sh
```

### Manual Cleanup Steps
```bash
# 1. Remove ArgoCD applications
kubectl delete applications -n argocd --all

# 2. Remove ingress resources
kubectl delete ingress -A --all

# 3. Destroy Terraform resources
terraform destroy -auto-approve

# 4. Clean environment stack
cd ../environment/
terraform destroy -auto-approve
```

## Troubleshooting

### Common Issues

#### External DNS Ownership Conflicts
```bash
# Check External DNS logs
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns

# Verify Route 53 TXT records
aws route53 list-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Type == 'TXT']"
```

#### ArgoCD Application Sync Issues
```bash
# Check ArgoCD application status
kubectl get applications -n argocd

# Force sync application
kubectl patch application -n argocd <app-name> \
  -p '{"operation":{"sync":{"syncStrategy":{"hook":{}}}}}' --type merge
```

#### DNS Propagation Delays
```bash
# Check current DNS resolution
nslookup burnham.eks-blueprint.$ROOT_DOMAIN

# Verify Route 53 records
aws route53 list-resource-record-sets \
  --hosted-zone-id $ZONE_ID \
  --query "ResourceRecordSets[?Name == 'burnham.eks-blueprint.$ROOT_DOMAIN.']"
```

## Advanced Configuration

### Custom Application Weights
Modify individual application weights by editing the Helm values:

```yaml
# In workload repository
spec:
  ingress:
    route53_weight: "100"  # Per-application weight
```

### Multi-Region Setup
Extend the pattern for cross-region deployments:

```hcl
# Add region-specific configurations
variable "secondary_region" {
  description = "Secondary AWS region for DR"
  type        = string
  default     = "us-east-1"
}
```

### Automated Migration Pipeline
Create CI/CD pipeline for automated blue-green deployments:

```yaml
# .github/workflows/blue-green-deploy.yml
name: Blue-Green Deployment
on:
  workflow_dispatch:
    inputs:
      target_cluster:
        description: 'Target cluster (blue/green)'
        required: true
        default: 'green'
      traffic_weight:
        description: 'Traffic weight (0-100)'
        required: true
        default: '0'
```

## Security Considerations

### IAM Permissions
- Use least-privilege IAM roles
- Separate roles for platform and application teams
- Enable CloudTrail for audit logging

### Network Security
- Private subnets for worker nodes
- Security groups with minimal required access
- VPC endpoints for AWS services

### Secrets Management
- Use AWS Secrets Manager for sensitive data
- Rotate SSH keys regularly
- Enable encryption at rest and in transit

## Cost Optimization

### Resource Management
- Use Karpenter for efficient node scaling
- Implement resource quotas per namespace
- Monitor costs with Kubecost addon

### Cleanup Automation
- Implement automated cleanup for unused resources
- Use Terraform state management
- Regular cost reviews and optimization

## Conclusion

This blue-green deployment pattern provides:
- Zero-downtime deployments
- Easy rollback capabilities
- Gradual traffic migration
- Infrastructure as Code management
- GitOps-based automation

The solution enables platform teams to manage cluster migrations independently while application teams maintain deployment autonomy through ArgoCD.