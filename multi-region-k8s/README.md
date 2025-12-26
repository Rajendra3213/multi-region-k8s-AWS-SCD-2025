# Multi-Region EKS with Global Accelerator

This implementation follows the AWS blog post architecture for operating multi-regional stateless applications using Amazon EKS.

## Architecture Components

- **EKS Clusters**: Primary (us-east-1) and Secondary (us-west-2)
- **Global Accelerator**: Static anycast IPs with automatic failover
- **Route53**: DNS management with alias records
- **Network Load Balancers**: Regional endpoints for Global Accelerator
- **Transit Gateway**: Cross-region connectivity

## Key Features

✅ **Global Performance**: AWS Global Accelerator for optimized routing
✅ **Automatic Failover**: Traffic shifts to healthy regions
✅ **Static IPs**: Consistent endpoints for clients
✅ **Cross-Region Connectivity**: Transit Gateway peering

## Deployment

1. **Deploy Infrastructure**:
   ```bash
   terraform init
   terraform apply
   ```

2. **Configure kubectl**:
   ```bash
   aws eks update-kubeconfig --region us-east-1 --name primary-eks-cluster
   aws eks update-kubeconfig --region us-west-2 --name secondary-eks-cluster
   ```

3. **Deploy Application**:
   ```bash
   kubectl apply -f k8s-manifests/sample-app.yaml --context=primary
   kubectl apply -f k8s-manifests/sample-app.yaml --context=secondary
   ```

## Traffic Flow

1. **Client** → Global Accelerator (anycast IPs)
2. **Global Accelerator** → Regional NLB (primary: 100%, secondary: 0%)
3. **NLB** → EKS Service LoadBalancer
4. **Service** → Application Pods

## Failover Mechanism

- **Health Checks**: Global Accelerator monitors NLB health
- **Automatic Failover**: Traffic shifts to secondary region on failure
- **Traffic Dial**: Gradual traffic shifting (0-100%)

## Configuration

Update `terraform.tfvars`:
```hcl
domain_name = "myapp.example.com"
primary_region = "us-east-1"
secondary_region = "us-west-2"
```