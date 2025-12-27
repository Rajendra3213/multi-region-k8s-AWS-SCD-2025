# EKS Blue-Green Deployment - Green Cluster

## Cluster Information

**Cluster ID:** `eks-blue-green-green`  
**Region:** `ap-south-1`

---

## Access ArgoCD

```bash
export KUBECONFIG="/tmp/eks-blue-green-green"
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green
echo "ArgoCD URL: https://$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id argocd-admin-secret.eks-blue-green --query SecretString --output text --region ap-south-1)"
```

---

## Configure kubectl

```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green
```

---

## Team Access Configuration

### Dev Teams

**Team Burnham:**
```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-burnham-2025122622035300640000001c
```

**Team Riker:**
```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-riker-2025122622035148780000001b
```

### ECS Demo Teams

**Team ECS Demo Crystal:**
```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-ecsdemo-crystal-20251226220351460100000017
```

**Team ECS Demo Frontend:**
```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-ecsdemo-frontend-20251226220351474900000018
```

**Team ECS Demo NodeJS:**
```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-ecsdemo-nodejs-2025122622035148520000001a
```

### Platform Team

```bash
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-green --role-arn arn:aws:iam::488309743291:role/team-platform-20251226220350963800000015
```

---

## GitOps Metadata

`<sensitive>`