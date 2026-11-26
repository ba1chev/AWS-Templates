# Run with: terraform init && terraform test
# Uses a mocked AWS provider - no credentials needed, nothing is created.
mock_provider "aws" {
  mock_resource "aws_iam_instance_profile" {
    defaults = {
      arn = "arn:aws:iam::123456789012:instance-profile/test"
    }
  }

  mock_resource "aws_launch_template" {
    defaults = {
      id = "lt-0123456789abcdef0"
    }
  }

  override_data {
    target = data.aws_ssm_parameter.ami
    values = {
      insecure_value = "ami-0aaaaaaaaaaaaaaaa"
    }
  }

  override_data {
    target = data.aws_ami.this
    values = {
      root_device_name = "/dev/xvda"
    }
  }

  override_data {
    target = data.aws_partition.current
    values = {
      partition = "aws"
    }
  }
}

variables {
  name               = "test"
  subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
  security_group_ids = ["sg-0123456789abcdef0"]
}

run "defaults" {
  command = apply

  assert {
    condition     = aws_launch_template.this.image_id == "ami-0aaaaaaaaaaaaaaaa"
    error_message = "Should use the AMI from the SSM parameter by default."
  }

  assert {
    condition     = aws_launch_template.this.metadata_options[0].http_tokens == "required"
    error_message = "IMDSv2 should be required."
  }

  assert {
    condition     = aws_launch_template.this.block_device_mappings[0].ebs[0].encrypted == "true" && aws_launch_template.this.block_device_mappings[0].device_name == "/dev/xvda"
    error_message = "Root volume should be encrypted and use the AMI's root device name."
  }

  assert {
    condition     = aws_iam_role_policy_attachment.ssm.policy_arn == "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
    error_message = "SSM managed instance policy should be attached."
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "EC2"
    error_message = "Without target groups the ASG should use EC2 health checks."
  }

  assert {
    condition     = length(aws_autoscaling_policy.cpu) == 1 && aws_autoscaling_policy.cpu[0].target_tracking_configuration[0].target_value == 50
    error_message = "A CPU target tracking policy at 50% should exist by default."
  }
}

run "behind_load_balancer" {
  command = apply

  variables {
    ami_id            = "ami-0bbbbbbbbbbbbbbbb"
    target_group_arns = ["arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/test-tg/abc"]
    user_data         = "#!/bin/bash\necho hello"
  }

  assert {
    condition     = length(data.aws_ssm_parameter.ami) == 0 && aws_launch_template.this.image_id == "ami-0bbbbbbbbbbbbbbbb"
    error_message = "An explicit ami_id should skip the SSM lookup."
  }

  assert {
    condition     = aws_autoscaling_group.this.health_check_type == "ELB"
    error_message = "With target groups the ASG should use ELB health checks."
  }

  assert {
    condition     = aws_launch_template.this.user_data == base64encode("#!/bin/bash\necho hello")
    error_message = "User data should be base64-encoded."
  }
}

run "no_auto_scaling" {
  command = apply

  variables {
    cpu_target_value = null
  }

  assert {
    condition     = length(aws_autoscaling_policy.cpu) == 0
    error_message = "No scaling policy when cpu_target_value is null."
  }
}

run "rejects_min_above_max" {
  command = plan

  variables {
    min_size = 3
    max_size = 1
  }

  expect_failures = [aws_autoscaling_group.this]
}
