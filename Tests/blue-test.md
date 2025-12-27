# 1. Configure kubectl for the blue cluster
export KUBECONFIG="/tmp/eks-blue-green-blue"
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-blue

# 2. Verify cluster access
kubectl cluster-info
kubectl get nodes

# 3. Check namespaces and pods
kubectl get namespaces
kubectl get pods -A

# 4. Access ArgoCD
echo "ArgoCD URL: https://$(kubectl get svc -n argocd argo-cd-argocd-server -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')"
echo "ArgoCD Username: admin"
echo "ArgoCD Password: $(aws secretsmanager get-secret-value --secret-id argocd-admin-secret.eks-blue-green --query SecretString --output text --region ap-south-1)"

# 5. Test team access (optional)
# Platform team
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-blue --role-arn arn:aws:iam::488309743291:role/team-platform-20251226211158226900000020

# Dev teams
aws eks --region ap-south-1 update-kubeconfig --name eks-blue-green-blue --role-arn arn:aws:iam::488309743291:role/team-burnham-20251226211158227200000021
