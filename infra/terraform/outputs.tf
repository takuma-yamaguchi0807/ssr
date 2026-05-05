output "alb_dns_name" {
  description = "ALB の DNS 名（ブラウザアクセス確認用）"
  value       = aws_lb.main.dns_name
}

output "ecr_repository_url" {
  description = "ECR リポジトリ URL（GitHub Actions の docker push 先）"
  value       = aws_ecr_repository.app.repository_url
}

output "ecs_cluster_name" {
  description = "ECS クラスター名（GitHub Actions の update-service 用）"
  value       = aws_ecs_cluster.main.name
}

output "ecs_service_name" {
  description = "ECS サービス名（GitHub Actions の update-service 用）"
  value       = aws_ecs_service.app.name
}
