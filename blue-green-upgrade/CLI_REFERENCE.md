# Blue-Green EKS - CLI Quick Reference

## Prerequisites Check
```bash
# Verify required tools
terraform --version
aws --version
kubectl version --client
git --version

# Check AWS credentials
aws sts get-caller-identity

# Verify Route 53 hosted zone
aws route53 list-hosted-zones --query "HostedZones[?Name=='example.com.']"
```

## Initial Setup Commands
```bash
# 1. Clone and navigate
git clone https://github.com/aws-ia/terraform-aws-eks-blueprints.git
cd terraform-aws-eks-blueprints/patterns/blue-green-upgrade/

# 2. Setup configuration
cp terraform.tfvars.example terraform.tfvars
ln -s ../terraform.tfvars environment/terraform.tfvars
ln -s ../terraform.tfvars eks-blue/terraform.tfvars  
ln -s ../terraform.tfvars eks-green/terraform.tfvars

# 3. Create GitHub SSH secret
aws secretsmanager create-secret \
  --name "github-blueprint-ssh-key" \
  --secret-string file://~/.ssh/id_rsa
```

## Deployment Commands
```bash
# Deploy environment (5-10 min)
cd environment/
terraform init && terraform apply -auto-approve

# Deploy blue cluster (15-20 min)
cd ../eks-blue/
terraform init && terraform apply -auto-approve

# Deploy green cluster (15-20 min)  
cd ../eks-green/
terraform init && terraform apply -auto-approve
```

## Cluster Access Commands
```bash
# Connect to blue cluster
aws eks --region us-west-2 update-kubeconfig --name eks-blueprint-blue

# Connect to green cluster  
aws eks --region us-west-2 update-kubeconfig --name eks-blueprint-green

# List contexts
kubectl config get-contexts

# Switch context
kubectl config use-context arn:aws:eks:us-west-2:123456789012:cluster/eks-blueprint-blue
```

## Traffic Migration Commands
```bash
# Check current traffic distribution
URL=$(kubectl get ing -n team-burnham burnham-ingress -o json | jq -r ".spec.rules[0].host")
for i in {1..10}; do curl -s https://$URL | grep CLUSTER_NAME | awk -F "<span>|</span>" '{print $4}'; done

# Update green cluster to 50% traffic
cd eks-green/
sed -i 's/route53_weight = "0"/route53_weight = "100"/' main.tf
terraform apply -auto-approve

# Update blue cluster to 0% traffic (full migration)
cd ../eks-blue/
sed -i 's/route53_weight = "100"/route53_weight = "0"/' main.tf
terraform apply -auto-approve
```

## Monitoring Commands
```bash
# Check cluster status
kubectl get nodes
kubectl get pods -A

# Check ArgoCD applications
kubectl get applications -n argocd

# Check ingress resources
kubectl get ingress -A

# Monitor External DNS
kubectl logs -n external-dns -l app.kubernetes.io/name=external-dns -f

# Check Route 53 records
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "eks-blueprint.example.com." --query "HostedZones[0].Id" --out text)
aws route53 list-resource-record-sets --hosted-zone-id $ZONE_ID --query "ResourceRecordSets[?Type=='A']"
```

## ArgoCD Access Commands
```bash
# Get ArgoCD URL
kubectl get svc -n argocd argo-cd-argocd-server -o json | jq -r '.status.loadBalancer.ingress[0].hostname'

# Get ArgoCD password
aws secretsmanager get-secret-value --secret-id argocd-admin-secret.eks-blueprint --query SecretString --output text

# Port forward ArgoCD (alternative access)
kubectl port-forward svc/argo-cd-argocd-server -n argocd 8080:443
```

## Troubleshooting Commands
```bash
# Check DNS resolution
dig burnham.eks-blueprint.example.com
nslookup burnham.eks-blueprint.example.com

# Check certificate status
aws acm list-certificates --region us-west-2

# Check External DNS ownership
kubectl get ingress -A -o yaml | grep external-dns

# Force ArgoCD sync
kubectl patch application -n argocd <app-name> -p '{"operation":{"sync":{}}}' --type merge

# Check load balancer status
kubectl get svc -A | grep LoadBalancer
```

## Cleanup Commands
```bash
# Automated cleanup (recommended)
cd eks-blue/  # or eks-green/
../tear-down.sh

# Manual cleanup
kubectl delete applications -n argocd --all
kubectl delete ingress -A --all
terraform destroy -auto-approve

# Clean environment
cd ../environment/
terraform destroy -auto-approve
```

## Useful One-Liners
```bash
# Quick health check
kubectl get pods -A | grep -v Running | grep -v Completed

# Get all ingress hosts
kubectl get ingress -A -o json | jq -r '.items[].spec.rules[].host'

# Check ArgoCD app sync status
kubectl get applications -n argocd -o json | jq -r '.items[] | "\(.metadata.name): \(.status.sync.status)"'

# Monitor traffic distribution
watch 'curl -s https://burnham.eks-blueprint.example.com | grep CLUSTER_NAME | awk -F "<span>|</span>" "{print \$4}"'

# Get cluster endpoints
kubectl cluster-info

# Check node capacity
kubectl describe nodes | grep -A 5 "Capacity:"
```

## Environment Variables
```bash
# Set common variables
export AWS_REGION="us-west-2"
export CLUSTER_NAME_BLUE="eks-blueprint-blue"
export CLUSTER_NAME_GREEN="eks-blueprint-green"
export HOSTED_ZONE="eks-blueprint.example.com"
export ROOT_DOMAIN="example.com"

# Use in commands
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME_BLUE
```

## Terraform State Management
```bash
# Check Terraform state
terraform state list

# Import existing resources
terraform import aws_route53_zone.example Z123456789

# Refresh state
terraform refresh

# Show current state
terraform show
```