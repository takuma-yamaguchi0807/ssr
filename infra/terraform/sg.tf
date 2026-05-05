# ALB セキュリティグループ
resource "aws_security_group" "alb" {
  name   = "${var.app_name}-sg-alb"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg-alb" }
}

# ECS Task セキュリティグループ
resource "aws_security_group" "ecs_task" {
  name   = "${var.app_name}-sg-ecs-task"
  vpc_id = aws_vpc.main.id

  egress {
    description = "to internet (ECR pull / SSM / CloudWatch)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.app_name}-sg-ecs-task" }
}

# ALB → ECS（循環依存を避けるため別リソースで定義）
resource "aws_security_group_rule" "alb_to_ecs" {
  type                     = "egress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.alb.id
  source_security_group_id = aws_security_group.ecs_task.id
}

resource "aws_security_group_rule" "ecs_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.ecs_task.id
  source_security_group_id = aws_security_group.alb.id
}

# RDS セキュリティグループ
resource "aws_security_group" "rds" {
  name   = "${var.app_name}-sg-rds"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "MySQL from ECS tasks"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
  }

  tags = { Name = "${var.app_name}-sg-rds" }
}

# ElastiCache (Redis) セキュリティグループ
resource "aws_security_group" "redis" {
  name   = "${var.app_name}-sg-redis"
  vpc_id = aws_vpc.main.id

  ingress {
    description     = "Redis from ECS tasks"
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
  }

  tags = { Name = "${var.app_name}-sg-redis" }
}
