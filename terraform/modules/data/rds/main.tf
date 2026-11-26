locals {
  default_ports = {
    postgres = 5432
    mysql    = 3306
  }

  default_log_exports = {
    postgres = ["postgresql", "upgrade"]
    mysql    = ["error"]
  }

  port        = coalesce(var.port, local.default_ports[var.engine])
  log_exports = var.enabled_cloudwatch_logs_exports != null ? var.enabled_cloudwatch_logs_exports : local.default_log_exports[var.engine]
}

resource "aws_db_subnet_group" "this" {
  name       = var.name
  subnet_ids = var.subnet_ids

  tags = merge(var.tags, { Name = var.name })
}

# RDS instance: private, encrypted, master password managed in Secrets Manager
resource "aws_db_instance" "this" {
  identifier     = var.name
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_type          = var.storage_type
  storage_encrypted     = true
  kms_key_id            = var.kms_key_id

  db_name                     = var.db_name
  username                    = var.username
  manage_master_user_password = true
  port                        = local.port

  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.security_group_ids
  publicly_accessible    = false
  multi_az               = var.multi_az

  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  maintenance_window        = var.maintenance_window
  copy_tags_to_snapshot     = true
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.name}-final-snapshot"

  auto_minor_version_upgrade      = true
  apply_immediately               = var.apply_immediately
  performance_insights_enabled    = var.performance_insights_enabled
  enabled_cloudwatch_logs_exports = local.log_exports

  tags = merge(var.tags, { Name = var.name })
}
