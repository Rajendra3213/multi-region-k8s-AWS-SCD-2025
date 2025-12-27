---
marp: true
theme: default
paginate: true
style: |
  section {
    background-image: 
      linear-gradient(rgba(0,0,0,.1) 1px, transparent 1px),
      linear-gradient(90deg, rgba(0,0,0,.1) 1px, transparent 1px);
    background-size: 20px 20px;
    background-color: #f8f8f8;
    color: #232f3e;
    font-size: 28px;
  }
  h1 {
    background: rgba(255,255,255,0.9);
    padding: 10px;
    border-radius: 5px;
    color: #ff9900;
    font-size: 50px;
  }
  h2 {
    background: rgba(255,255,255,0.9);
    padding: 8px;
    border-radius: 5px;
    color: #ff9900;
    font-size: 34px;
  }
  h3 {
    background: rgba(255,255,255,0.9);
    padding: 6px;
    border-radius: 5px;
    color: #ff9900;
    font-size: 28px;
  }
  li {
    color: #232f3e;
    font-size: 24px;
    margin: 12px 0;
  }
  code {
    font-size: 18px;
  }
  pre {
    font-size: 16px;
  }
header: Multi-Region K8S with EKS
footer: AWS SCD 2025, Rajendra Acharya and Aaditya Pageni
---

# Multi-Region EKS with Global Accelerator
## High Availability Kubernetes on AWS

![bg right:40% 80%]()

---
# Why Multi-Region ?
#### AWS US‑EAST‑1 Outage (October 20–21, 2025)
<img src="image-1.png" alt="alt text" width="40%">

---

# Who survives or is less affected?

---
# Architecture Overview

**Multi-region stateless applications using Amazon EKS**

## Key Components:
- **EKS Clusters**: Primary (us-east-1) and Secondary (us-west-2)
- **Global Accelerator**: Static anycast IPs with automatic failover
- **Route53**: DNS management with alias records
- **Network Load Balancers**: Regional endpoints
- **Transit Gateway**: Cross-region connectivity

![bg right:40% 80%]()

---
# Deployment Architecture
![alt text](image-4.png)

---
# Network Architecture & Traffic Flow

## Regional Setup:
- **Primary (us-east-1)**: VPC `10.0.0.0/16`, 3 AZs, EKS v1.31
- **Secondary (us-west-2)**: VPC `10.1.0.0/16`, 3 AZs, EKS v1.31
- **Worker Nodes**: t3.medium (Min: 1, Max: 6, Desired: 3)
- **Application**: Nginx (3 replicas/region)

![bg right:40% 80%]()

---
# Traffic Flow:
1. Client → Global Accelerator (anycast IPs)
2. Global Accelerator → Regional NLB (primary: 100%)
3. NLB → EKS Service LoadBalancer
4. Service → Application Pods

---

# Global Accelerator & Failover

## Static IPs:
- `52.223.29.64` / `166.117.186.20`

## Configuration:
- **Protocol**: TCP Port 80
- **Affinity**: SOURCE_IP
- **Primary**: 100% (active)
- **Secondary**: 0% (standby)

--- 
## Failover Mechanism:
- **Health Checks**: Global Accelerator monitors NLB health
- **Automatic Failover**: Traffic shifts to secondary region on failure
- **Traffic Dial**: Gradual traffic shifting (0-100%)

![bg right:40% 80%]()

---

# Transit Gateway: Cross-Region Connectivity

## Purpose:
- **Private VPC peering** between regions (10.0.0.0/16 <--> 10.1.0.0/16)
- **Pod-to-pod communication** across EKS clusters
- **Shared services** access (databases, caching, monitoring)

## Use Cases:
- Stateful applications requiring cross-region sync
- Centralized logging/monitoring infrastructure
- Multi-region microservices communication

---

# Demo

---

![alt text](image-8.png)
![alt text](image-9.png)

---

<img src="image-10.png" alt="alt text" height="550">


---

# Blue Green Deployment ?

---

### Why Blue-Green 
- Minimize downtime during upgrades
- Easy rollback to previous version
- Safer testing in production: Green can be fully tested before live traffic hits it.

---

### EKS-Blue-Green deployment setup

![alt text](image-2.png)

---

### Argo Rollout setup
![alt text](image-3.png)

---

![alt text](image-6.png)

---

# Tips
- Build and Deploy GREEN
- Run Health Checks + alarms
- Shift 10% traffic to GREEN
- Monitor logs + metrices
- Gradually increases traffic ( 50 % --> 100%)



---
# Demo

---

![alt text](image-5.png)

---
![alt text](image-7.png)

---
# Thanks

## Questions?

---
# Let's talk infrastructures
<img src="image-11.png" alt="alt text" height="400">
