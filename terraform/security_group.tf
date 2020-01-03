resource "aws_security_group" "rails-app-sg" {
  description = "ssh, http"
  egress = [
    {
      description      = ""
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  ingress = [
    {
      description      = "for HTTP"
      protocol         = "tcp"
      from_port        = 80
      to_port          = 80
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "for rails app"
      protocol         = "tcp"
      from_port        = 3000
      to_port          = 3000
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "for SSH"
      protocol         = "tcp"
      from_port        = 22
      to_port          = 22
      cidr_blocks      = [
        "0.0.0.0/0",
      ]
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]
  name   = "sg for eks"
  vpc_id = aws_vpc.rails-app-vpc.id
  tags   = {}
  timeouts {}
}