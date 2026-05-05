variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "env" {
  description = "環境名（タグ・リソース名に使用）"
  type        = string
  default     = "prod"
}

variable "app_name" {
  description = "アプリケーション名（リソース名のプレフィックス）"
  type        = string
  default     = "ssr"
}

variable "db_password" {
  description = "RDS の管理パスワード（terraform.tfvars または環境変数で渡す）"
  type        = string
  sensitive   = true
}
