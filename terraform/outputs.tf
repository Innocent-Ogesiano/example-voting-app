output "cluster_name" {
  value = aws_eks_cluster.voting_app_cluster.name
}

output "cluster_endpoint" {
  value = aws_eks_cluster.voting_app_cluster.endpoint
}

output "cluster_certificate_authority_data" {
  value = aws_eks_cluster.voting_app_cluster.certificate_authority[0].data
}

output "configure_kubectl" {
  value = "aws eks update-kubeconfig --region ${var.aws_region} --name ${aws_eks_cluster.voting_app_cluster.name}"
}
