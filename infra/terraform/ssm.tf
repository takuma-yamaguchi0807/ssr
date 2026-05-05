resource "aws_ssm_parameter" "database_url" {
  name  = "/${var.app_name}/DATABASE_URL"
  type  = "SecureString"
  value = "mysql://${local.db_username}:${var.db_password}@${aws_db_instance.main.address}:3306/${local.db_name}"

  tags = { Name = "${var.app_name}-database-url" }
}

resource "aws_ssm_parameter" "redis_host" {
  name  = "/${var.app_name}/REDIS_HOST"
  type  = "String"
  value = aws_elasticache_cluster.main.cache_nodes[0].address

  tags = { Name = "${var.app_name}-redis-host" }
}
