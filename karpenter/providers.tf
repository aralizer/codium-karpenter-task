provider "aws" {
  region     = local.aws_region

  default_tags {
    tags = local.common_tags
  }
}

provider "kubernetes" {
    host = data.aws_eks_cluster.eks_cluster.endpoint
    token = data.aws_eks_cluster_auth.eks_cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
}

provider "helm" {
  kubernetes {
    host = data.aws_eks_cluster.eks_cluster.endpoint
    token = data.aws_eks_cluster_auth.eks_cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  }
}

provider "kubectl" {
  host = data.aws_eks_cluster.eks_cluster.endpoint
  token = data.aws_eks_cluster_auth.eks_cluster.token
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority.0.data)
  load_config_file       = false
}
