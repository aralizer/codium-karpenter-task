resource "kubernetes_namespace" "karpenter" {
  metadata {
    annotations = {
      name = "karpenter"
    }
    name = "karpenter"
  }
}

resource "helm_release" "karpenter" {
  namespace  = kubernetes_namespace.karpenter.id
  name       = "karpenter"
  repository = "oci://public.ecr.aws/karpenter"
  chart      = "karpenter"
  version    = "0.37.0"

  set {
    name  = "settings.clusterName"
    value = local.eks_cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = data.aws_eks_cluster.eks_cluster.endpoint
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.karpenter_role.arn
  }

  set {
    name  = "replicas"
    value = "1"
  }
}

resource "kubectl_manifest" "node_pool_amd64" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: karpenter-amd64
  namespace: ${kubernetes_namespace.karpenter.id}
spec:
  template:
    spec:
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
      requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values:
        - t2.micro
        - t2.small
        - t2.medium
      - key: kubernetes.io/arch
        operator: In
        values:
        - amd64
      limits:
        cpu: 5
YAML
}

resource "kubectl_manifest" "node_pool_arm64" {
  yaml_body = <<YAML
apiVersion: karpenter.sh/v1beta1
kind: NodePool
metadata:
  name: karpenter-arm64
  namespace: ${kubernetes_namespace.karpenter.id}
spec:
  template:
    spec:
      nodeClassRef:
        apiVersion: karpenter.k8s.aws/v1beta1
        kind: EC2NodeClass
        name: default
      requirements:
      - key: node.kubernetes.io/instance-type
        operator: In
        values:
        - t4g.micro
        - t4g.small
      - key: kubernetes.io/arch
        operator: In
        values:
        - arm64
      limits:
        cpu: 5
YAML
}

resource "kubectl_manifest" "node_class" {
  yaml_body = <<YAML
apiVersion: karpenter.k8s.aws/v1beta1
kind: EC2NodeClass
metadata:
  name: default
  namespace: ${kubernetes_namespace.karpenter.id}
spec:
  amiFamily: AL2023
  subnetSelectorTerms:
    - tags:
        kubernetes.io/cluster/${local.eks_cluster_name}: "owned"
  securityGroupSelectorTerms:
    - tags:
        kubernetes.io/cluster/${local.eks_cluster_name}: "owned"
  instanceProfile: ${aws_iam_instance_profile.karpenter.name}
YAML
}
