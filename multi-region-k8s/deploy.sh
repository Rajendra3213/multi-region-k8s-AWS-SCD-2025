#!/bin/bash

set -e

PRIMARY_CLUSTER="primary-cluster"
SECONDARY_CLUSTER="secondary-cluster"
PRIMARY_REGION="ap-south-1"
SECONDARY_REGION="ap-northeast-1"

echo "Deploying to Primary Region ($PRIMARY_REGION)..."
aws eks update-kubeconfig --name $PRIMARY_CLUSTER --region $PRIMARY_REGION
kubectl apply -f k8s-manifests/deployment.yaml
echo "Primary deployment complete!"

echo ""
echo "Deploying to Secondary Region ($SECONDARY_REGION)..."
aws eks update-kubeconfig --name $SECONDARY_CLUSTER --region $SECONDARY_REGION
kubectl apply -f k8s-manifests/deployment-secondary.yaml
echo "Secondary deployment complete!"

echo ""
echo "Getting LoadBalancer endpoints..."
echo "Primary Region:"
aws eks update-kubeconfig --name $PRIMARY_CLUSTER --region $PRIMARY_REGION
kubectl get svc nginx-service

echo ""
echo "Secondary Region:"
aws eks update-kubeconfig --name $SECONDARY_CLUSTER --region $SECONDARY_REGION
kubectl get svc nginx-service
