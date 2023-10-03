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
    from_port   = var.port
    to_port     = var.port
    protocol    = "tcp"
    cidr_blocks = var.sg-ingress-cidr
  }
  ingress {
    description = "prometheus"
    from_port   = 9100
    to_port     = 9100
    protocol    = "tcp"
    cidr_blocks = [ var.sg-prometheus-cidr ]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group_rule" "nginx-exporter" {
  count             = var.components == "frontend" ? 1 : 0
  type              = "ingress"
  from_port         = 9113
  to_port           = 9113
  protocol          = "tcp"
  cidr_blocks       = [var.sg-prometheus-cidr]
  security_group_id = aws_security_group.main.id
  description       = "prometheus-ngnx-exporter"
}

resource "aws_launch_template" "main" {
  name_prefix            = "${local.names}-template"
  image_id               = var.image_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile {name="${local.names}-role"}

  user_data              = base64encode(templatefile("${path.module}/userdata.sh",
    {
      component = var.components
      env       = var.env
    }))
  tag_specifications {
    resource_type = "instance"
    tags          = merge(local.tags, { Name = "${local.names}-ec2" })
  }
}

resource "aws_autoscaling_group" "main" {
  name                = "${local.names}-autoscale"
  vpc_zone_identifier = var.subnet_ids
  desired_capacity    = var.desired_capacity
  max_size            = var.max_size
  min_size            = var.min_size
  target_group_arns = [aws_lb_target_group.main.arn]

  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    propagate_at_launch = true
    value               = local.names
  }
  tag {
    key                 = "monitor"
    propagate_at_launch = true
    value               = "yes"
  }
}

resource "aws_autoscaling_policy" "cpu" {
  name                      = "auto_scale for cpu util"
  policy_type               = "TargetTrackingScaling"
  autoscaling_group_name    = aws_autoscaling_group.main.name
  estimated_instance_warmup = 120
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 30.0
  }
}

resource "aws_route53_record" "main" {
  zone_id = "Z09444252M01QG3Q8GZAK"
  name    = var.components == "frontend" ? var.env == "prod" ? "www" : var.env : "${var.components}-${var.env}"
  type    = "CNAME"
  ttl     = 30
  records = [var.components == "frontend" ? var.dns_public_name : var.dns_name]
}

resource "aws_lb_target_group" "main" {
  name     = "${local.names}-private-tg"
  port     = var.port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 5
    matcher             = "200"
    path                = "/health"
#    port                = var.port
    unhealthy_threshold = 3
    timeout = 2
  }
}

resource "aws_lb_listener_rule" "main" {
  listener_arn = var.listner
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
  condition {
    host_header {
      values =[var.components == "frontend" ? "${var.env == "prod" ? "www" : var.env}.cloudev7.online": "${var.components}-${var.env}.cloudev7.online" ]
    }
  }
}

resource "aws_lb_target_group" "public" {
  count       = var.components == "frontend" ? 1 : 0
  name        = "${local.names}-public"
  target_type = "ip"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.default_vpc
  tags        = merge(local.tags, { Name = "${local.names}-tg" })
  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 5
    matcher             = "404"
    path                = "/"
#    port                = var.port
    unhealthy_threshold = 3
    timeout = 2
  }
}

resource "aws_lb_target_group_attachment" "public" {
  count             = var.components == "frontend" ? length(var.subnet_ids) : 0
#  count             = var.components == "frontend" ? length(var.subnet_ids) : 0
  target_group_arn  = aws_lb_target_group.public[0].arn
  target_id         = element(tolist(data.dns_a_record_set.public.addrs), count.index)
  port              = 80
  availability_zone = "all"
}

resource "aws_lb_listener_rule" "public" {
  count = var.components== "frontend" ? 1:0
  listener_arn = var.public_listner
  priority     = var.priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public[0].arn
  }

  condition {
    host_header{
      values =["${var.env == "prod" ? "www" : var.env}.cloudev7.online"]
    }
  }
}

resource "aws_iam_role" "main" {
  name = "${local.names}-role"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Sid       = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = merge(local.tags, { Name = "${local.names}-policy" })
}


resource "aws_iam_policy" "main" {
  name        = "${local.names}-policy"
  path        = "/"
  description = "${local.names}-policy"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "kms:Decrypt",
          "ssm:GetParameterHistory",
          "ssm:GetParametersByPath",
          "ssm:GetParameters",
          "ssm:GetParameter"
        ],
        "Resource": local.parameters_eff
      },
      {
        "Sid": "VisualEditor1",
        "Effect": "Allow",
        "Action": "ssm:DescribeParameters",
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "test-attach" {
  role       = aws_iam_role.main.name
  policy_arn = aws_iam_policy.main.arn
}

resource "aws_iam_instance_profile" "main" {
  name = "${local.names}-role"
  role = aws_iam_role.main.name
}