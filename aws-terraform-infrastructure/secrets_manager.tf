# ==============================================================================
# AWS Secrets Manager & Database Credentials
# ==============================================================================

resource "random_password" "db_password" {
  length           = 20
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name_prefix             = "${local.name_prefix}-db-creds-"
  description             = "Master database credentials for ${local.name_prefix}-rds"
  recovery_window_in_days = 0

  tags = local.common_tags
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    engine   = var.db_engine
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    username = var.db_username
    password = random_password.db_password.result
    database = var.db_name
  })
}
