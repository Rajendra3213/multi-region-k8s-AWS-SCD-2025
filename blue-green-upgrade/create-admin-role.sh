#!/bin/bash

# Create IAM role for EKS admin access
aws iam create-role \
  --role-name EKS-Admin-Role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "AWS": "arn:aws:iam::'$(aws sts get-caller-identity --query Account --output text)':root"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  }'

# Attach admin policy
aws iam attach-role-policy \
  --role-name EKS-Admin-Role \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

echo "IAM role EKS-Admin-Role created successfully"