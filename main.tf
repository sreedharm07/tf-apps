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

resource "aws_launch_template" "main" {
  name_prefix   = "${local.names}-template"
  image_id      = var.image_id
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  user_data = base64encode(templatefile("${path.module}/userdata.sh",
    {
      component= var.components
    }))
  tag_specifications {
    resource_type = "instance"
    tags = merge(local.tags,{Name= "${local.names}-ec2"})
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "${local.names}-autoscale"
  vpc_zone_identifier = [var.subnet_ids]
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = local.names
  }
}

