# Multi-Region EKS Architecture

## Overview
This Terraform implementation creates a highly available, multi-region Kubernetes infrastructure on AWS with automatic failover capabilities using AWS Global Accelerator.

## Architecture Diagram
```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   Internet                                      │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        Route53 DNS                                             │
│                  rajendra-acharya.com.np                                       │
│                    (A Record Alias)                                            │
└─────────────────────────┬───────────────────────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                    AWS Global Accelerator                                      │
│                 Static IPs: 52.223.29.64                                       │
│                            166.117.186.20                                      │
│                                                                                 │
│  ┌─────────────────────┐              ┌─────────────────────┐                  │
│  │   Primary Region    │              │  Secondary Region   │                  │
│  │   Traffic: 100%     │              │   Traffic: 0%       │                  │
│  │   (us-east-1)       │              │   (us-west-2)       │                  │
│  └─────────────────────┘              └─────────────────────┘                  │
└─────────────────────────┬───────────────────────────┬───────────────────────────┘
                          │                           │
                          ▼                           ▼
┌─────────────────────────────────────┐ ┌─────────────────────────────────────┐
│           PRIMARY REGION            │ │          SECONDARY REGION           │
│            (us-east-1)              │ │            (us-west-2)              │
│                                     │ │                                     │
│  ┌─────────────────────────────────┐ │ │  ┌─────────────────────────────────┐ │
│  │              VPC                │ │ │  │              VPC                │ │
│  │         10.0.0.0/16             │ │ │  │         10.1.0.0/16             │ │
│  │                                 │ │ │  │                                 │ │
│  │  ┌─────────────────────────────┐ │ │ │  │  ┌─────────────────────────────┐ │ │
│  │  │      Public Subnets         │ │ │ │  │  │      Public Subnets         │ │ │
│  │  │   10.0.1.0/24 (AZ-a)        │ │ │ │  │  │   10.1.1.0/24 (AZ-a)        │ │ │
│  │  │   10.0.2.0/24 (AZ-b)        │ │ │ │  │  │   10.1.2.0/24 (AZ-b)        │ │ │
│  │  │   10.0.3.0/24 (AZ-c)        │ │ │ │  │  │   10.1.3.0/24 (AZ-c)        │ │ │
│  │  │                             │ │ │ │  │  │                             │ │ │
│  │  │  ┌─────────────────────────┐ │ │ │ │  │  │  ┌─────────────────────────┐ │ │ │
│  │  │  │     Network LB          │ │ │ │  │  │  │     Network LB          │ │ │ │
│  │  │  │  (K8s Service)          │ │ │ │  │  │  │  (K8s Service)          │ │ │ │
│  │  │  └─────────────────────────┘ │ │ │ │  │  │  └─────────────────────────┘ │ │ │
│  │  │                             │ │ │ │  │  │                             │ │ │
│  │  │  ┌─────────────────────────┐ │ │ │ │  │  │  ┌─────────────────────────┐ │ │ │
│  │  │  │   Application LB        │ │ │ │  │  │  │   Application LB        │ │ │ │
│  │  │  │   (Terraform)           │ │ │ │  │  │  │   (Terraform)           │ │ │ │
│  │  │  └─────────────────────────┘ │ │ │ │  │  │  └─────────────────────────┘ │ │ │
│  │  └─────────────────────────────┘ │ │ │  │  └─────────────────────────────┘ │ │
│  │                                 │ │ │  │                                 │ │
│  │  ┌─────────────────────────────┐ │ │ │  │  ┌─────────────────────────────┐ │ │
│  │  │     Private Subnets         │ │ │ │  │  │     Private Subnets         │ │ │
│  │  │   10.0.4.0/24 (AZ-a)        │ │ │ │  │  │   10.1.4.0/24 (AZ-a)        │ │ │
│  │  │   10.0.5.0/24 (AZ-b)        │ │ │ │  │  │   10.1.5.0/24 (AZ-b)        │ │ │
│  │  │   10.0.6.0/24 (AZ-c)        │ │ │ │  │  │   10.1.6.0/24 (AZ-c)        │ │ │
│  │  │                             │ │ │ │  │  │                             │ │ │
│  │  │  ┌─────────────────────────┐ │ │ │  │  │  ┌─────────────────────────┐ │ │ │
│  │  │  │    EKS Cluster          │ │ │ │  │  │  │    EKS Cluster          │ │ │ │
│  │  │  │ primary-eks-cluster     │ │ │ │  │  │  │ secondary-eks-cluster   │ │ │ │
│  │  │  │                         │ │ │ │  │  │  │                         │ │ │ │
│  │  │  │  ┌─────────────────────┐ │ │ │ │  │  │  │  ┌─────────────────────┐ │ │ │ │
│  │  │  │  │   Worker Nodes      │ │ │ │ │  │  │  │  │   Worker Nodes      │ │ │ │ │
│  │  │  │  │   (t3.medium)       │ │ │ │ │  │  │  │  │   (t3.medium)       │ │ │ │ │
│  │  │  │  │   Min: 1, Max: 6    │ │ │ │ │  │  │  │  │   Min: 1, Max: 6    │ │ │ │ │
│  │  │  │  │   Desired: 3        │ │ │ │ │  │  │  │  │   Desired: 3        │ │ │ │ │
│  │  │  │  │                     │ │ │ │ │  │  │  │  │                     │ │ │ │ │
│  │  │  │  │  ┌─────────────────┐ │ │ │ │ │  │  │  │  │  ┌─────────────────┐ │ │ │ │ │
│  │  │  │  │  │  Sample App     │ │ │ │ │ │  │  │  │  │  │  Sample App     │ │ │ │ │ │
│  │  │  │  │  │  (Nginx Pods)   │ │ │ │ │ │  │  │  │  │  │  (Nginx Pods)   │ │ │ │ │ │
│  │  │  │  │  │  Replicas: 3    │ │ │ │ │ │  │  │  │  │  │  Replicas: 3    │ │ │ │ │ │
│  │  │  │  │  └─────────────────┘ │ │ │ │ │  │  │  │  │  └─────────────────┘ │ │ │ │ │
│  │  │  │  └─────────────────────┘ │ │ │ │  │  │  │  └─────────────────────┘ │ │ │ │
│  │  │  └─────────────────────────┘ │ │ │  │  │  └─────────────────────────┘ │ │ │
│  │  └─────────────────────────────┘ │ │ │  │  └─────────────────────────────┘ │ │
│  │                                 │ │ │  │                                 │ │
│  │  ┌─────────────────────────────┐ │ │ │  │  ┌─────────────────────────────┐ │ │
│  │  │    Transit Gateway          │ │ │ │  │  │    Transit Gateway          │ │ │
│  │  │    primary-tgw              │ │ │ │  │  │    secondary-tgw            │ │ │
│  │  └─────────────────────────────┘ │ │ │  │  └─────────────────────────────┘ │ │
│  └─────────────────────────────────┘ │ │  └─────────────────────────────────┘ │
└─────────────────────────────────────┘ └─────────────────────────────────────┘
                          │                           │
                          └─────────────┬─────────────┘
                                        │
                          ┌─────────────────────────────┐
                          │  Transit Gateway Peering   │
                          │     Cross-Region            │
                          └─────────────────────────────┘
```

## Components

### 1. DNS Layer
- **Route53 Hosted Zone**: `rajendra-acharya.com.np`
- **A Record**: Alias pointing to Global Accelerator
- **DNS Resolution**: Resolves to Global Accelerator static IPs

### 2. Global Load Balancing
- **AWS Global Accelerator**
  - Static anycast IPs: `52.223.29.64`, `166.117.186.20`
  - DNS Name: `a0e74cd6e5c1f948e.awsglobalaccelerator.com`
  - Protocol: TCP Port 80
  - Client Affinity: SOURCE_IP

### 3. Regional Infrastructure

#### Primary Region (us-east-1)
- **VPC**: `10.0.0.0/16`
- **Public Subnets**: 3 AZs (10.0.1.0/24, 10.0.2.0/24, 10.0.3.0/24)
- **Private Subnets**: 3 AZs (10.0.4.0/24, 10.0.5.0/24, 10.0.6.0/24)
- **NAT Gateways**: 3 (one per AZ)
- **EKS Cluster**: `primary-eks-cluster` (v1.31)
- **Worker Nodes**: t3.medium (3 nodes, 1-6 range)
- **Transit Gateway**: Cross-region connectivity

#### Secondary Region (us-west-2)
- **VPC**: `10.1.0.0/16`
- **Public Subnets**: 3 AZs (10.1.1.0/24, 10.1.2.0/24, 10.1.3.0/24)
- **Private Subnets**: 3 AZs (10.1.4.0/24, 10.1.5.0/24, 10.1.6.0/24)
- **NAT Gateways**: 3 (one per AZ)
- **EKS Cluster**: `secondary-eks-cluster` (v1.31)
- **Worker Nodes**: t3.medium (3 nodes, 1-6 range)
- **Transit Gateway**: Cross-region connectivity

### 4. Kubernetes Layer
- **Sample Application**: Nginx deployment
- **Replicas**: 3 per region
- **Service Type**: LoadBalancer (creates NLB)
- **Resource Limits**: 128Mi memory, 500m CPU
- **Health Checks**: HTTP readiness/liveness probes

### 5. Load Balancers
- **Network Load Balancers**: Created by Kubernetes services
  - Primary: `a70b2a1f6b7614cf091734c9c519f3a5-c193f1fec5cf6585.elb.us-east-1.amazonaws.com`
  - Secondary: `a3637f1522b8845968342e61d5f0d8e2-5753de4cf3aa6aca.elb.us-west-2.amazonaws.com`
- **Application Load Balancers**: Created by Terraform (unused in current flow)

### 6. Cross-Region Connectivity
- **Transit Gateway Peering**: Connects primary and secondary regions
- **Route Tables**: Routes traffic between VPCs
- **Security Groups**: Allow cross-region communication

## Traffic Flow

### Normal Operation
1. **Client Request** → `rajendra-acharya.com.np`
2. **DNS Resolution** → Route53 returns Global Accelerator IPs
3. **Global Accelerator** → Routes to primary region (100% traffic)
4. **Network Load Balancer** → Distributes to EKS service
5. **Kubernetes Service** → Routes to healthy pods
6. **Nginx Pods** → Serve application content

### Failover Scenario
1. **Health Check Failure** → Global Accelerator detects primary region issues
2. **Automatic Failover** → Traffic shifts to secondary region
3. **Secondary NLB** → Takes over traffic handling
4. **Secondary EKS** → Serves requests from us-west-2

## Security

### Network Security
- **Security Groups**: Restrict traffic to necessary ports
- **Private Subnets**: Worker nodes isolated from internet
- **NAT Gateways**: Outbound internet access for private resources

### EKS Security
- **IAM Roles**: Separate roles for cluster and node groups
- **RBAC**: Kubernetes role-based access control
- **Private Endpoints**: EKS API server access control

### Load Balancer Security
- **NLB**: Layer 4 load balancing with health checks
- **ALB**: Layer 7 with security groups (if used)

## High Availability Features

### Multi-AZ Deployment
- **3 Availability Zones** per region
- **Distributed Workloads** across AZs
- **Multiple NAT Gateways** for redundancy

### Auto Scaling
- **EKS Node Groups**: 1-6 nodes with desired state of 3
- **Pod Replicas**: 3 replicas per region
- **Horizontal Pod Autoscaler**: Can be added for dynamic scaling

### Disaster Recovery
- **Cross-Region Replication**: Applications deployed in both regions
- **Global Accelerator**: Automatic failover between regions
- **Transit Gateway**: Cross-region connectivity for data replication

## Monitoring and Observability

### EKS Add-ons
- **VPC CNI**: Network plugin for pod networking
- **CoreDNS**: DNS resolution within cluster
- **kube-proxy**: Network proxy for services

### Health Checks
- **Global Accelerator**: Monitors NLB health
- **Kubernetes**: Pod readiness and liveness probes
- **Load Balancer**: Target group health checks

## Cost Optimization

### Resource Sizing
- **t3.medium instances**: Cost-effective for development/testing
- **Spot instances**: Can be configured for additional savings
- **Right-sizing**: Adjustable based on workload requirements

### Regional Strategy
- **Primary-Secondary**: Reduces costs compared to active-active
- **Traffic Dial**: Gradual traffic shifting for testing

## Terraform Modules

### Core Modules
- **VPC Module**: Network infrastructure
- **EKS Module**: Kubernetes clusters
- **ALB Module**: Application load balancers
- **Transit Gateway Module**: Cross-region connectivity
- **Route53 Module**: DNS management
- **Global Accelerator Module**: Global load balancing

### Configuration Files
- **main.tf**: Primary infrastructure definition
- **variables.tf**: Input parameters
- **outputs.tf**: Resource outputs
- **terraform.tfvars**: Environment-specific values

## Deployment Process

### Infrastructure Deployment
```bash
terraform init
terraform plan
terraform apply
```

### Application Deployment
```bash
aws eks update-kubeconfig --region us-east-1 --name primary-eks-cluster
aws eks update-kubeconfig --region us-west-2 --name secondary-eks-cluster
kubectl apply -f k8s-manifests/sample-app.yaml --context=primary
kubectl apply -f k8s-manifests/sample-app.yaml --context=secondary
```

### Verification
```bash
curl http://rajendra-acharya.com.np
kubectl get pods,svc --context=primary
kubectl get pods,svc --context=secondary
```

## Failover Testing

### Manual Failover
1. Update traffic dial percentage in Terraform
2. Apply changes: `terraform apply`
3. Verify traffic shift: `curl http://rajendra-acharya.com.np`

### Automatic Failover
1. Simulate primary region failure
2. Global Accelerator detects unhealthy endpoints
3. Traffic automatically routes to secondary region
4. Monitor failover time and application availability

## Best Practices Implemented

### Infrastructure as Code
- **Version Control**: All infrastructure defined in Terraform
- **Modular Design**: Reusable modules for different components
- **Environment Separation**: Different tfvars for environments

### Security
- **Least Privilege**: IAM roles with minimal required permissions
- **Network Isolation**: Private subnets for worker nodes
- **Encryption**: EBS volumes encrypted by default

### Reliability
- **Multi-AZ**: Resources distributed across availability zones
- **Health Checks**: Multiple layers of health monitoring
- **Graceful Degradation**: Automatic failover capabilities

### Scalability
- **Auto Scaling Groups**: Dynamic node scaling
- **Load Balancing**: Traffic distribution across multiple targets
- **Resource Limits**: Proper resource allocation for pods

This architecture provides a robust, scalable, and highly available multi-region Kubernetes platform suitable for production workloads with automatic failover capabilities.