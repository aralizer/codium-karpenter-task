data "tls_certificate" "eks" {
  url = data.aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  url             = data.aws_eks_cluster.eks_cluster.identity.0.oidc.0.issuer
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates.0.sha1_fingerprint]
}

data "aws_iam_policy_document" "karpenter_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:karpenter:karpenter"]
    }
  }
}


resource "aws_iam_role" "karpenter_role" {
  name = "KarpenterRole"
  assume_role_policy = data.aws_iam_policy_document.karpenter_assume_role.json
}

resource "aws_iam_role_policy" "karpenter_policy" {
  name   = "KarpenterPolicy"
  role   = aws_iam_role.karpenter_role.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action   = [
          "ssm:GetParameter",
          "iam:GetRole",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
          
        ],
        Effect   = "Allow",
        Resource = "*",
        Sid      = "Karpenter"
      },
      {
        Action   = "ec2:terminateInstances"
        Condition = {
          StringLike = {
            "ec2:ResourceTag/karpenter.sh/nodepool" = "*"
          }
        },

        Effect = "Allow",
        Resource = "*",
        Sid = "ConditionalEC2Termination"
      },
      {
        Action = "eks:DescribeCluster",
        Effect = "Allow",
        Resource = "arn:aws:eks:${local.aws_region}:${local.account_id}:cluster/${local.eks_cluster_name}",
        Sid = "EKSClusterEndpointLookup"
      },
      {
        Action = "iam:PassRole",
        Effect = "Allow",
        Resource = "arn:aws:iam::${local.account_id}:role/${local.eks_node_group_iam_role_name}",
        Sid = "PassNodeIAMRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "karpenter" {
  name = "KarpenterInstanceProfile"
  role = local.eks_node_group_iam_role_name
}
