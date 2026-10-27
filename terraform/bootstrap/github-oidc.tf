data "aws_caller_identity" "current" {}

resource "aws_iam_openid_connect_provider" "github_actions" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}

data "aws_iam_policy_document" "github_actions_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity", "sts:TagSession"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:job_workflow_ref"
      values   = ["${var.github_repository}/.github/workflows/ci.yaml@refs/heads/main"]
    }
  }
}

resource "aws_iam_role" "github_actions" {
  name               = "${var.cluster_name}-github-actions-role"
  assume_role_policy = data.aws_iam_policy_document.github_actions_assume_role.json
}

data "aws_iam_policy_document" "github_actions_permissions" {
  statement {
    sid       = "EksKubeconfig"
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "${var.cluster_name}-github-actions-policy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_permissions.json
}

# HCP Terraform runs the main stack remotely and authenticates to AWS through
# its own OIDC identity (dynamic credentials).
resource "aws_iam_openid_connect_provider" "hcp_terraform" {
  url            = "https://app.terraform.io"
  client_id_list = ["aws.workload.identity"]
}

data "aws_iam_policy_document" "hcp_terraform_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.hcp_terraform.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "app.terraform.io:aud"
      values   = ["aws.workload.identity"]
    }

    condition {
      test     = "StringLike"
      variable = "app.terraform.io:sub"
      values   = ["organization:${var.hcp_organization}:project:*:workspace:${var.hcp_workspace}:run_phase:*"]
    }
  }
}

resource "aws_iam_role" "hcp_terraform" {
  name               = "${var.cluster_name}-hcp-terraform-role"
  assume_role_policy = data.aws_iam_policy_document.hcp_terraform_assume_role.json
}

data "aws_iam_policy_document" "hcp_terraform_permissions" {
  statement {
    sid       = "EksManagement"
    actions   = ["eks:*"]
    resources = ["*"]
  }

  statement {
    sid = "IamRoleManagement"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:PassRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "iam:ListRolePolicies",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.cluster_name}-*",
    ]
  }

  statement {
    sid = "EksServiceLinkedRole"
    actions = [
      "iam:GetRole",
      "iam:CreateServiceLinkedRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks-nodegroup.amazonaws.com/AWSServiceRoleForAmazonEKSNodegroup",
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/eks.amazonaws.com/AWSServiceRoleForAmazonEKS",
    ]
  }

  statement {
    sid = "IamPolicyManagement"
    actions = [
      "iam:CreatePolicy",
      "iam:DeletePolicy",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListPolicyVersions",
      "iam:CreatePolicyVersion",
      "iam:DeletePolicyVersion",
      "iam:TagPolicy",
      "iam:UntagPolicy",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/${var.cluster_name}-*",
    ]
  }

  statement {
    sid       = "SubnetTagging"
    actions   = ["ec2:CreateTags", "ec2:DeleteTags"]
    resources = ["arn:aws:ec2:*:*:subnet/*"]
  }

  statement {
    sid       = "IamOidcReadOnly"
    actions   = ["iam:GetOpenIDConnectProvider"]
    resources = [aws_iam_openid_connect_provider.github_actions.arn]
  }

  statement {
    sid = "Ec2ReadOnly"
    actions = [
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeAvailabilityZones",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "hcp_terraform" {
  name   = "${var.cluster_name}-hcp-terraform-policy"
  role   = aws_iam_role.hcp_terraform.id
  policy = data.aws_iam_policy_document.hcp_terraform_permissions.json
}
