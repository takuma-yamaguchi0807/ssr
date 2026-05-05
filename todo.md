# Todo

## アプリケーション

- [x] Next.jsプロジェクトの初期化（依存パッケージのインストール）
- [x] next.config.ts を standalone モードに設定
- [x] prisma/schema.prisma を作成（MySQLモデル定義）
- [x] src/lib/db.ts を実装（Prisma clientのシングルトン）
- [x] src/lib/redis.ts を実装（ioredis clientのシングルトン）
- [x] src/lib/session.ts を実装（Cookie↔Redisのセッション読み書き）
- [x] src/app/page.tsx を実装（アイテム一覧 Server Component）
- [x] src/app/items/[id]/page.tsx を実装（Redisキャッシュ経由のアイテム詳細）
- [x] src/app/api/auth/route.ts を実装（ログイン・ログアウト）
- [x] src/app/api/health/route.ts を実装（ALBヘルスチェック用）
- [x] src/components/TaskBadge.tsx を実装（ECSタスクID表示）

## インフラ・デプロイ

- [x] Dockerfile を作成（マルチステージビルド、ポート8080）
- [x] infra/terraform/main.tf / variables.tf / outputs.tf を作成
- [x] infra/terraform/vpc.tf を作成（VPC・サブネット×6・IGW・NAT）
- [x] infra/terraform/sg.tf を作成（セキュリティグループ×4）
- [x] infra/terraform/alb.tf を作成（ALB・ターゲットグループ・リスナー）
- [x] infra/terraform/ecr.tf を作成（ECRリポジトリ）
- [x] infra/terraform/ecs.tf を作成（クラスター・タスク定義・サービス）
- [x] infra/terraform/rds.tf を作成（RDS MySQL）
- [x] infra/terraform/elasticache.tf を作成（Redisクラスター）
- [x] infra/terraform/cloudwatch.tf を作成（ロググループ・アラーム）
- [x] infra/terraform/ssm.tf を作成（Parameter Store）
- [x] .github/workflows/deploy.yml を作成（docker build → ECR push → ECS deploy）

## 動作確認

- [x] GitHub シークレットを登録（AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY）
- [x] terraform apply でAWSインフラを構築
- [ ] git push → GitHub Actionsの実行・デプロイ確認
- [ ] DBマイグレーション手動実行（README.md参照）
- [ ] http://\<alb_dns_name\>/ でアクセス確認（ALBラウンドロビン・セッション共有）
- [ ] terraform destroy でAWSリソースを削除
