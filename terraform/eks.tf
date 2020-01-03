resource "aws_eks_cluster" "cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.eks-master.arn
  vpc_config {
    security_group_ids = [aws_security_group.rails-app-sg.id]
    subnet_ids = [aws_subnet.rails-app-subnet1a.id, aws_subnet.rails-app-subnet1c.id]
  }
}