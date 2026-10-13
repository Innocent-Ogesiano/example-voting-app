resource "aws_eks_cluster" "voting_app_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = data.aws_subnets.default_vpc_subnets.ids
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}

resource "aws_eks_node_group" "voting_app_nodes" {
  cluster_name    = aws_eks_cluster.voting_app_cluster.name
  node_group_name = "${var.cluster_name}-nodes"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = data.aws_subnets.default_vpc_subnets.ids
  instance_types  = [var.node_instance_type]

  scaling_config {
    desired_size = var.node_desired_size
    min_size     = var.node_min_size
    max_size     = var.node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy_attachment,
    aws_iam_role_policy_attachment.eks_node_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_node_ecr_readonly_policy_attachment,
  ]
}
