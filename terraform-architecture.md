# Terraform Architecture

Two independent Terraform stacks keep state in HCP Terraform (your HCP org). `bootstrap/` is
applied once, manually, with real AWS credentials (its workspace uses local execution). `terraform/` (main) is
what CI creates and destroys on every push to `main` — it references the
bootstrap role by name, never owns it, so destroying the cluster never
breaks CI's own ability to authenticate.

```mermaid
flowchart TB
    subgraph CI["GitHub Actions (push to main)"]
        direction TB
        T1[test]
        T2[scan-build-push]
        T3[deploy]
        T1 --> T2 --> T3
    end

    subgraph S3["HCP Terraform org"]
        direction LR
        S1["workspace: example-voting-app-bootstrap\n(local execution)"]
        S2["workspace: example-voting-app-eks\n(remote execution)"]
    end

    subgraph Bootstrap["terraform/bootstrap/ (applied manually, once)"]
        direction TB
        OIDC["aws_iam_openid_connect_provider\ntoken.actions.githubusercontent.com"]
        Role["aws_iam_role\nexample-voting-app-github-actions-role\n(trust: job_workflow_ref + sts:TagSession)"]
        Policy["aws_iam_role_policy\n(eks:DescribeCluster)"]
        HcpOIDC["aws_iam_openid_connect_provider\napp.terraform.io"]
        HcpRole["aws_iam_role\nexample-voting-app-hcp-terraform-role\n(eks:*, iam:*Role, ec2:Describe*)"]
        HcpOIDC --> HcpRole
        OIDC --> Role
        Policy --> Role
    end

    subgraph Main["terraform/ (main stack — CI creates/destroys this)"]
        direction TB
        DataRole["data.aws_iam_role\ngithub_actions\n(looks up bootstrap role by name)"]
        ClusterRole["aws_iam_role\neks_cluster_role"]
        NodeRole["aws_iam_role\neks_node_role"]
        Cluster["aws_eks_cluster\nexample-voting-app"]
        NodeGroup["aws_eks_node_group\nexample-voting-app-nodes"]
        AccessEntry["aws_eks_access_entry +\naws_eks_access_policy_association\n(grants DataRole cluster-admin)"]

        ClusterRole --> Cluster
        NodeRole --> NodeGroup
        Cluster --> NodeGroup
        Cluster --> AccessEntry
        DataRole --> AccessEntry
    end

    EKS["Amazon EKS cluster\n(default VPC)"]
    Helm["helm upgrade --install voting-app\n(vote, result, worker, redis, db)"]

    T3 -- "assumes via OIDC" --> Role
    T3 -- "terraform apply\n(remote HCP run)" --> Main
    Main -- "assumes via HCP OIDC" --> HcpRole
    Main -- "state" --> S2
    Bootstrap -- "state" --> S1
    NodeGroup --> EKS
    T3 -- "aws eks update-kubeconfig\n+ helm upgrade --install" --> Helm
    Helm --> EKS
```

## Why two stacks

AWS OIDC authentication requires the trust relationship (provider + role) to
already exist before a workflow can use it — CI cannot create its own
permission to talk to AWS. Splitting the state means:

- `terraform/bootstrap/` (OIDC provider, IAM role, inline policy) is rarely
  touched and never destroyed by CI.
- `terraform/` (cluster, node group, cluster/node IAM roles, access entries)
  is safe to create and destroy repeatedly — a full `terraform destroy` here
  never removes CI's ability to re-authenticate and rebuild.

## Trust policy notes

The role's trust policy anchors on `token.actions.githubusercontent.com:job_workflow_ref`
rather than the classic `sub` claim (`repo:owner/repo:ref:refs/heads/main`),
because repositories created after GitHub's immutable-ID rollout emit a
`sub` claim that doesn't match that string format at all. `job_workflow_ref`
(the calling workflow's file path + ref) is unaffected by that change and is
explicitly supported by AWS as an alternative anchor condition. The policy
also grants `sts:TagSession`, required because `aws-actions/configure-aws-credentials@v4`
passes GitHub context as session tags by default.
