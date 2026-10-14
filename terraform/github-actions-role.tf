data "aws_iam_role" "github_actions" {
  name = "${var.cluster_name}-github-actions-role"
}

data "aws_caller_identity" "current" {}
