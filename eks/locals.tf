data "aws_caller_identity" "current" {}

locals {

  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region

  eks_cluster_name = var.cluster_name
  eks_cluster_iam_role = "eks_cluster_role"
  eks_node_group_name = "my-node-group"
  eks_node_group_iam_role_name = "eks-node-group-role"


  common_tags = {
    Application = "Codium-Karpenter-Task"
    Owner       = "Alex"
  }
}