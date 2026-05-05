resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.app_name}-redis-subnet-group"
  subnet_ids = aws_subnet.data[*].id

  tags = { Name = "${var.app_name}-redis-subnet-group" }
}

resource "aws_elasticache_cluster" "main" {
  cluster_id        = "${var.app_name}-redis"
  engine            = "redis"
  node_type         = "cache.t3.micro"
  num_cache_nodes   = 1
  engine_version    = "7.1"
  port              = 6379

  subnet_group_name  = aws_elasticache_subnet_group.main.name
  security_group_ids = [aws_security_group.redis.id]

  tags = { Name = "${var.app_name}-redis" }
}
