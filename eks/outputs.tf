output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_node_group_iam_role_name" {
  value = aws_iam_role.eks_node_group_role.name
}
