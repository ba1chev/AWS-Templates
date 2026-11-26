data "aws_partition" "current" {}

# Latest Amazon Linux 2023 AMI, unless an explicit AMI is given
data "aws_ssm_parameter" "ami" {
  count = var.ami_id == null ? 1 : 0

  name = var.ami_ssm_parameter
}

locals {
  ami_id = var.ami_id != null ? var.ami_id : data.aws_ssm_parameter.ami[0].insecure_value
}

# Looked up to get the AMI's root device name, which differs between distros
data "aws_ami" "this" {
  filter {
    name   = "image-id"
    values = [local.ami_id]
  }
}

# Instance role: SSM Session Manager access instead of SSH
resource "aws_iam_role" "this" {
  name_prefix = "${var.name}-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "extra" {
  count = length(var.iam_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.iam_policy_arns[count.index]
}

resource "aws_iam_instance_profile" "this" {
  name_prefix = "${var.name}-"
  role        = aws_iam_role.this.name

  tags = var.tags
}

# Launch template: IMDSv2 only, encrypted root volume
resource "aws_launch_template" "this" {
  name_prefix            = "${var.name}-"
  image_id               = local.ami_id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = var.security_group_ids
  user_data              = var.user_data != null ? base64encode(var.user_data) : null
  update_default_version = true

  iam_instance_profile {
    arn = aws_iam_instance_profile.this.arn
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.enable_detailed_monitoring
  }

  block_device_mappings {
    device_name = data.aws_ami.this.root_device_name

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(var.tags, { Name = var.name })
  }

  tags = merge(var.tags, { Name = var.name })
}

# Auto Scaling group; a new launch template version triggers a rolling instance refresh
resource "aws_autoscaling_group" "this" {
  name_prefix         = "${var.name}-"
  vpc_zone_identifier = var.subnet_ids
  min_size            = var.min_size
  max_size            = var.max_size
  desired_capacity    = var.desired_capacity

  target_group_arns         = var.target_group_arns
  health_check_type         = length(var.target_group_arns) > 0 ? "ELB" : "EC2"
  health_check_grace_period = var.health_check_grace_period

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.instance_refresh_min_healthy_percentage
    }
  }

  dynamic "tag" {
    for_each = merge(var.tags, { Name = var.name })
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true

    precondition {
      condition     = var.min_size <= var.max_size
      error_message = "min_size must be less than or equal to max_size."
    }
  }
}

# Target tracking on average CPU
resource "aws_autoscaling_policy" "cpu" {
  count = var.cpu_target_value != null ? 1 : 0

  name                   = "${var.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = var.cpu_target_value
  }
}
