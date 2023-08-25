resource "aws_security_group" "main" {
  name        =  "${local.names}-sg"
  description = "${local.names}-sg"
  vpc_id      = var.vpc_id
  tags = merge(local.tags,{Name= "${local.names}-sg"})

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.sg-ssh-ingress-cidr]
  }
  ingress {
    description = "app"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.sg-ingress-cidr
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

