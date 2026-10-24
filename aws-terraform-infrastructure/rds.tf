# ==============================================================================
# Amazon RDS PostgreSQL Database (Demo Tier)
# ==============================================================================

resource "aws_db_instance" "main" {
  identifier        = "${local.name_prefix}-rds"
  engine            = var.db_engine
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_class
  allocated_storage = var.db_allocated_storage

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  db_subnet_group_name   = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = true
  deletion_protection    = false
  storage_encrypted      = true

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-rds"
  })
}
