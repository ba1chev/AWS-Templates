# Run with: terraform init && terraform test
# Uses a mocked AWS provider - no credentials needed, nothing is created.
mock_provider "aws" {
  mock_resource "aws_lb" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:loadbalancer/app/test/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    defaults = {
      arn = "arn:aws:elasticloadbalancing:eu-central-1:123456789012:targetgroup/test-tg/0123456789abcdef"
    }
  }
}

variables {
  name               = "test"
  vpc_id             = "vpc-12345678"
  subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
  security_group_ids = ["sg-0123456789abcdef0"]
}

run "http_only" {
  command = apply

  assert {
    condition     = aws_lb.this.load_balancer_type == "application" && !aws_lb.this.internal
    error_message = "Should create an internet-facing ALB by default."
  }

  assert {
    condition     = aws_lb.this.drop_invalid_header_fields
    error_message = "Invalid HTTP headers should be dropped (Security Hub ELB.4)."
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "forward" && aws_lb_listener.http.default_action[0].target_group_arn == aws_lb_target_group.this.arn
    error_message = "Without a certificate, HTTP should forward to the target group."
  }

  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "No HTTPS listener without a certificate."
  }

  assert {
    condition     = aws_lb_target_group.this.name == "test-tg" && aws_lb_target_group.this.health_check[0].path == "/"
    error_message = "Target group should be named <name>-tg with a default health check on /."
  }
}

run "https" {
  command = apply

  variables {
    certificate_arn = "arn:aws:acm:eu-central-1:123456789012:certificate/abc"
    health_check    = { path = "/health" }
  }

  assert {
    condition     = aws_lb_listener.http.default_action[0].type == "redirect" && aws_lb_listener.http.default_action[0].redirect[0].protocol == "HTTPS"
    error_message = "With a certificate, HTTP should redirect to HTTPS."
  }

  assert {
    condition     = aws_lb_listener.https[0].port == 443 && aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS listener should use port 443 and a TLS 1.3 policy."
  }

  assert {
    condition     = aws_lb_target_group.this.health_check[0].path == "/health" && aws_lb_target_group.this.health_check[0].matcher == "200"
    error_message = "Partial health_check overrides should keep the other defaults."
  }
}

run "rejects_long_name" {
  command = plan

  variables {
    name = "this-name-is-way-too-long-for-an-alb"
  }

  expect_failures = [var.name]
}

run "rejects_single_subnet" {
  command = plan

  variables {
    subnet_ids = ["subnet-aaaa1111"]
  }

  expect_failures = [var.subnet_ids]
}
