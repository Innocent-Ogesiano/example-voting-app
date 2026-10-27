# IAM + cluster plumbing for the AWS Load Balancer Controller. The controller
# itself is installed by CI with Helm (see .github/workflows/ci.yaml).

resource "aws_eks_addon" "pod_identity_agent" {
  cluster_name = aws_eks_cluster.voting_app_cluster.name
  addon_name   = "eks-pod-identity-agent"

  depends_on = [
    aws_eks_node_group.voting_app_nodes,
  ]
}

data "aws_iam_policy_document" "lb_controller_assume_role" {
  statement {
    actions = ["sts:AssumeRole", "sts:TagSession"]
    principals {
      type        = "Service"
      identifiers = ["pods.eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lb_controller" {
  name               = "${var.cluster_name}-lb-controller-role"
  assume_role_policy = data.aws_iam_policy_document.lb_controller_assume_role.json
}

# Policy pinned to AWS Load Balancer Controller v3.5.0 (docs/install/iam_policy.json).
resource "aws_iam_policy" "lb_controller" {
  name   = "${var.cluster_name}-lb-controller-policy"
  policy = file("${path.module}/lb-controller-iam-policy.json")
}

resource "aws_iam_role_policy_attachment" "lb_controller" {
  role       = aws_iam_role.lb_controller.name
  policy_arn = aws_iam_policy.lb_controller.arn
}

resource "aws_eks_pod_identity_association" "lb_controller" {
  cluster_name    = aws_eks_cluster.voting_app_cluster.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.lb_controller.arn

  depends_on = [
    aws_eks_addon.pod_identity_agent,
  ]
}

# The controller discovers public subnets for internet-facing ALBs by this tag.
# The default VPC's subnets are untagged.
resource "aws_ec2_tag" "public_subnet_elb" {
  for_each = toset(data.aws_subnets.default_vpc_subnets.ids)

  resource_id = each.value
  key         = "kubernetes.io/role/elb"
  value       = "1"
}
