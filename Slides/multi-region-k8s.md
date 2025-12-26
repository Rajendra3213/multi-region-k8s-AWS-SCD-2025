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
  }
  h1, h2, h3 {
    background: rgba(255,255,255,0.9);
    padding: 10px;
    border-radius: 5px;
    color: #ff9900;
  }
  li {
    color: #232f3e;
  }
header: Multi-Region K8S with EKS
footer: AWS SCD 2025, Rajendra Acharya and Aaditya Pageni

---
# Introduction
- Why Multi-Region Kubernetes?
- Why Hub and Spoke ?
- Service Mesh: Istio
- Disaster Recovery
- Blue Green Deployment ( Argo Rollouts )

---
# Why Multi-Region Kubernetes?
- High Availability and Fault Tolerance
- Disaster Recovery
- Reduced latency for global users by serving traffic from nearby regions
- Regulatory compliance and data residency (store/process data where required)
- Capacity and load distribution across regions for better autoscaling
- Fault isolation and faster recovery from region-specific failures
- Maintenance flexibility (can upgrade/patch one region at a time)
- Traffic steering and geo-aware routing for better UX
- Improved resiliency for large-scale incidents and blackouts

---


# Multi-Region Implementation
![alt text](assets/image.png)






---
#### Why Service Mesh?

- mTLS between services

- Traffic mirroring

- Canary releases

- Cross-cluster communication

---
#### Why this Architecture Wins:

- Resilience: Survives pod failures, availability zone failures, and full region failures
- Safety: Deployments are automated and can be aborted instantly without downtime
- Security: End-to-end encryption (mTLS) and private networking
- Scalability: Add new regions (Spokes) simply by attaching them to the Transit Gateway.


---
