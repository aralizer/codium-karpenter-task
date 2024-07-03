data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {}

locals {

  account_id = data.aws_caller_identity.current.account_id
  aws_region = var.aws_region

  eks_cluster_name = data.terraform_remote_state.eks_remote_state.outputs.eks_cluster_name
  eks_node_group_iam_role_name = data.terraform_remote_state.eks_remote_state.outputs.eks_node_group_iam_role_name

  common_tags = {
    Application = "Codium-Karpenter-Task"
    Owner       = "Alex"
  }
}
