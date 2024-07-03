# Codium Karpenter Task

This repository contains Terraform code designed to provision an EKS cluster integrated with Karpenter.

## Overview

The code is split into two separate TF deployments - one for deploying the EKS cluster and the other for deploying Karpenter on that cluster.

## Prerequisites

Before you begin, ensure you have the following installed:
- Terraform (version 1.9.0 or later)
- AWS CLI (configured with administrator access)

Make sure you're logged in into your AWS account to allow Terraform to perform the deployment

## How to use

As specified in the task description, it is assumed that we're using an exising VPC. This means that values for vpc id and subnet ids need to be passed down as variables to the EKS deployment.

**NOTE**

Since Karpenter needs to know to which subnets to allocate nodes into, the following tag needs to be added to the private subnets of the provided VPC

```
kubernetes.io/cluster/<CLUSTER_NAME> = owned
```

### Deploying EKS

Fill in the values for the EKS related variables in `eks/config/terraform.tfvars` and run the following Terraform commands to deploy the EKS cluster

```bash
cd eks
terraform init
terraform plan -out eks.tfplan
terraform apply eks.tfplan
```
### Deploying Karpenter

Fill in the values for the Karpenter related variables in `karpenter/config/terraform.tfvars` and run the following Terraform commands to deploy Karpenter into the EKS cluster

```bash
cd karpenter
terraform init
terraform plan -out karpenter.tfplan
terraform apply karpenter.tfplan
```


## Caveats

- No remote states are used for both deployments, to simplify the development. Local state files are assumed and is used by the Karpenter deployment to pull data about the EKS deployment
- vpc id and subnet ids are passed in as variables to the EKS deployment as the VPC deployment is not part of the task. The proper way to get such values would be to set them as outputs of the VPC deployment and reading them as outputs of a remote state
- To reduce costs during development, the replica count of the karpenter chart was overriden to 1


## How to use - As a developer

In order to deploy your application on the EKS cluser created by this task and use either `amd64` or `arm64` node you'll need to specify the desired architecture in the `nodeSelector` section of you Deployment of Pod object, like so:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: karpenter-demo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: karpenter-demo
  template:
    metadata:
      labels:
        app: karpenter-demo
    spec:
      nodeSelector:
        kubernetes.io/arch: "amd64"  # Or "arm64" 
      containers:
        - name: karpenter-demo
          image: nginx:latest
          resources:
            limits:
              cpu: 1
```
