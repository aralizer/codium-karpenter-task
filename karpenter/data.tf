data "terraform_remote_state" "eks_remote_state" {
  backend = "local"

  config = {
    path = "${path.module}/../eks/terraform.tfstate"
  }
}

data "aws_eks_cluster" "eks_cluster" {
  name = local.eks_cluster_name
}

data "aws_eks_cluster_auth" "eks_cluster" {
  name = local.eks_cluster_name
}
