output "region" {
  value = var.region
}

output "cluster-name" {
  value = var.cluster-name
}

output "subnet1" {
  value = aws_subnet.rails-app-subnet1a.id
}

output "subnet2" {
  value = aws_subnet.rails-app-subnet1c.id
}

output "node-role" {
  value = aws_iam_role.eks-node.arn
}