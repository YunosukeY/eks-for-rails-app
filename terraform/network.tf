resource "aws_vpc" "rails-app-vpc" {
  cidr_block = "10.1.0.0/16"
  tags       = {
    "Name" = "vpc-for-eks"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_subnet" "rails-app-subnet1a" {
  availability_zone = var.az1a
  cidr_block        = "10.1.0.0/24"
  vpc_id            = aws_vpc.rails-app-vpc.id
  tags              = {
    "Name" = "subnet1-for-eks"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_subnet" "rails-app-subnet1c" {
  availability_zone = var.az1c
  cidr_block        = "10.1.1.0/24"
  vpc_id            = aws_vpc.rails-app-vpc.id
  tags              = {
    "Name" = "subnet2-for-eks"
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
  }
}

resource "aws_internet_gateway" "rails-app-gw" {
  vpc_id = aws_vpc.rails-app-vpc.id
  tags   = {
    "Name" = "gw-for-eks"
  }
}

resource "aws_route_table" "rails-app-rt" {
  vpc_id = aws_vpc.rails-app-vpc.id
  route = [
    {
      cidr_block                = "0.0.0.0/0"
      egress_only_gateway_id    = ""
      gateway_id                = aws_internet_gateway.rails-app-gw.id
      instance_id               = ""
      ipv6_cidr_block           = ""
      nat_gateway_id            = ""
      network_interface_id      = ""
      transit_gateway_id        = ""
      vpc_peering_connection_id = ""
    },
  ]
  tags = {
    Name = "rt-for-eks"
  }
}

resource "aws_route_table_association" "rails-app-subnet1a-assoc-rt" {
  subnet_id      = aws_subnet.rails-app-subnet1a.id
  route_table_id = aws_route_table.rails-app-rt.id
}

resource "aws_route_table_association" "rails-app-subnet1c-assoc-rt" {
  subnet_id      = aws_subnet.rails-app-subnet1c.id
  route_table_id = aws_route_table.rails-app-rt.id
}