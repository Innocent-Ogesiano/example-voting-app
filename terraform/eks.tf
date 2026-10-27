resource "aws_eks_cluster" "voting_app_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids = data.aws_subnets.default_vpc_subnets.ids
  }

  access_config {
    authentication_mode                         = "API"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy_attachment,
  ]
}

resource "aws_eks_access_entry" "github_actions" {
  cluster_name  = aws_eks_cluster.voting_app_cluster.name
  principal_arn = data.aws_iam_role.github_actions.arn
}

resource "aws_eks_access_policy_association" "github_actions_admin" {
  cluster_name  = aws_eks_cluster.voting_app_cluster.name
  principal_arn = data.aws_iam_role.github_actions.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.github_actions,
  ]
}

resource "aws_eks_access_entry" "account_root" {
  cluster_name  = aws_eks_cluster.voting_app_cluster.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
}

resource "aws_eks_access_policy_association" "account_root_admin" {
  cluster_name  = aws_eks_cluster.voting_app_cluster.name
  principal_arn = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.account_root,
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

  # Auto-discovery tags for the Cluster Autoscaler (propagated to the node group's ASG).
  tags = {
    "k8s.io/cluster-autoscaler/enabled"             = "true"
    "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
  }

  # The Cluster Autoscaler changes the desired size at runtime.
  lifecycle {
    ignore_changes = [scaling_config[0].desired_size]
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_node_worker_policy_attachment,
    aws_iam_role_policy_attachment.eks_node_cni_policy_attachment,
    aws_iam_role_policy_attachment.eks_node_ecr_readonly_policy_attachment,
  ]
}
