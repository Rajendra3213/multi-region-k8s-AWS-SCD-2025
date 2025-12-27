#!/bin/bash

set -e

PRIMARY_REGION="ap-south-1"
SECONDARY_REGION="ap-northeast-1"
PRIMARY_CLUSTER="primary-cluster"
SECONDARY_CLUSTER="secondary-cluster"

echo "Getting NLB ARNs from Kubernetes services..."

# Get Primary NLB ARN
aws eks update-kubeconfig --name $PRIMARY_CLUSTER --region $PRIMARY_REGION --alias primary
PRIMARY_NLB=$(kubectl --context primary get svc nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
PRIMARY_NLB_ARN=$(aws elbv2 describe-load-balancers --region $PRIMARY_REGION --query "LoadBalancers[?DNSName=='$PRIMARY_NLB'].LoadBalancerArn" --output text)

# Get Secondary NLB ARN
aws eks update-kubeconfig --name $SECONDARY_CLUSTER --region $SECONDARY_REGION --alias secondary
SECONDARY_NLB=$(kubectl --context secondary get svc nginx-service -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
SECONDARY_NLB_ARN=$(aws elbv2 describe-load-balancers --region $SECONDARY_REGION --query "LoadBalancers[?DNSName=='$SECONDARY_NLB'].LoadBalancerArn" --output text)

echo "Primary NLB ARN: $PRIMARY_NLB_ARN"
echo "Secondary NLB ARN: $SECONDARY_NLB_ARN"
echo ""
echo "Update your main.tf Global Accelerator endpoint_configuration with these ARNs"
