# Run with: terraform init && terraform test
# Uses a mocked AWS provider - no credentials needed, nothing is created.
mock_provider "aws" {}

variables {
  name               = "test-db"
  subnet_ids         = ["subnet-aaaa1111", "subnet-bbbb2222"]
  security_group_ids = ["sg-0123456789abcdef0"]
}

run "postgres_defaults" {
  command = apply

  assert {
    condition     = aws_db_instance.this.engine == "postgres" && aws_db_instance.this.port == 5432
    error_message = "Should default to PostgreSQL on port 5432."
  }

  assert {
    condition     = aws_db_instance.this.storage_encrypted && !aws_db_instance.this.publicly_accessible
    error_message = "Storage should be encrypted and the instance not publicly accessible."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password
    error_message = "Master password should be managed in Secrets Manager."
  }

  assert {
    condition     = aws_db_instance.this.deletion_protection && aws_db_instance.this.final_snapshot_identifier == "test-db-final-snapshot"
    error_message = "Deletion protection and a final snapshot should be on by default."
  }

  assert {
    condition     = toset(aws_db_instance.this.enabled_cloudwatch_logs_exports) == toset(["postgresql", "upgrade"])
    error_message = "PostgreSQL logs should be exported to CloudWatch."
  }

  assert {
    condition     = aws_db_instance.this.db_subnet_group_name == aws_db_subnet_group.this.name
    error_message = "Instance should use the module's DB subnet group."
  }
}

run "mysql" {
  command = apply

  variables {
    engine = "mysql"
  }

  assert {
    condition     = aws_db_instance.this.port == 3306
    error_message = "MySQL should default to port 3306."
  }

  assert {
    condition     = toset(aws_db_instance.this.enabled_cloudwatch_logs_exports) == toset(["error"])
    error_message = "MySQL error log should be exported by default."
  }
}

run "dev_settings" {
  command = apply

  variables {
    deletion_protection = false
    skip_final_snapshot = true
  }

  assert {
    condition     = !aws_db_instance.this.deletion_protection && aws_db_instance.this.final_snapshot_identifier == null
    error_message = "Dev settings should allow destroy without a final snapshot."
  }
}

run "rejects_unknown_engine" {
  command = plan

  variables {
    engine = "oracle-ee"
  }

  expect_failures = [var.engine]
}

run "rejects_invalid_name" {
  command = plan

  variables {
    name = "Test_DB"
  }

  expect_failures = [var.name]
}
