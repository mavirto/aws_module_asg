
# Security Group para comunicacion con la instancias dentro del VPC

resource  "aws_security_group" "lt_sg" {
  name = "sg_${lookup(var.asg_config, "asg_name")}"
  description = "SG para Instancias en Private Subnets"
  vpc_id = var.asg_vpc

  dynamic "ingress" {
    for_each = var.sg_ingress_ports
    content {
      from_port   = ingress.key
      to_port     = ingress.key
      protocol    = ingress.value
      cidr_blocks = ["${var.vpc_cidr}"]
    }
  }

  # En principio vamos a aceptar que las instancias tengan abierto el tráfico de salida
  egress {
    from_port = 0
    to_port = 0
    protocol =  "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Launch Template

resource "aws_launch_template" "lt" {
  name = "lt-${lookup(var.asg_config, "asg_name")}"
  image_id = lookup(var.lt_config, "ami")
  instance_type = lookup(var.lt_config, "instance_type")

  instance_initiated_shutdown_behavior = "terminate"

  vpc_security_group_ids = [aws_security_group.lt_sg.id]

  # network_interfaces {
  #   associate_public_ip_address = "false"
  #   security_groups = [aws_security_group.lt_sg.id]
  # }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "${lookup(var.asg_config, "asg_name")}-instances"
    }
  }
}


# Auto Scaling Group

resource "aws_autoscaling_group" "asg" {
  name = lookup(var.asg_config, "asg_name")

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }

  vpc_zone_identifier = [for st in var.asg_subnets : "${st}"]

  force_delete = true

  desired_capacity   = lookup(var.asg_config, "asg_desiredcap")
  max_size           = lookup(var.asg_config, "asg_max")
  min_size           = lookup(var.asg_config, "asg_min")

  health_check_grace_period = lookup(var.asg_config, "asg_grace")
  health_check_type = lookup(var.asg_config, "asg_hct")

  lifecycle {
    create_before_destroy = true
  }
  
  # ARN del Target Group al que attachar el ASG
  target_group_arns = [for arns in var.asg_tg_arn : "${arns}"]
}
