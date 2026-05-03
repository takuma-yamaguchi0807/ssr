# SSR学習プロジェクト（Next.js on AWS ECS）

Next.js（App Router）+ TypeScript によるSSRをAWS ECS Fargate上で運用する学習用プロジェクト。
Terraform での一般的なインフラ構成の理解がメイン。

アーキテクチャ・構成図の詳細は [STRUCTURE.md](./STRUCTURE.md) を参照。

---

## 技術スタック

| レイヤー | 技術 |
|---|---|
| アプリ | Next.js 15 + TypeScript |
| SSR | React Server Components（App Router） |
| ORM | Prisma + MySQL driver |
| セッション | ioredis（セッションIDをCookieに、データをRedisに） |
| キャッシュ | ioredis（手動 get/set） |
| DB | RDS MySQL 8.0 |
| キャッシュ基盤 | ElastiCache Redis 7.x |
| ロードバランサ | ALB |
| コンテナ実行 | ECS Fargate（desired count=2） |
| コンテナレジストリ | ECR |
| インフラ構築 | Terraform |
| CI/CD | GitHub Actions |
| 監視 | CloudWatch（ECSログ自動収集） |

---

## ディレクトリ構成

```
ssr/
├── .github/
│   └── workflows/
│       └── deploy.yml               # docker build → ECR push → ECS deploy
│
├── src/
│   ├── app/
│   │   ├── layout.tsx
│   │   ├── page.tsx                 # / アイテム一覧（Server Component）
│   │   ├── items/[id]/page.tsx      # /items/:id
│   │   ├── api/auth/route.ts        # ログイン・ログアウト
│   │   └── api/health/route.ts      # ALBヘルスチェック用
│   ├── lib/
│   │   ├── db.ts                    # Prisma client
│   │   ├── redis.ts                 # ioredis client
│   │   └── session.ts               # セッション管理
│   └── components/
│       └── TaskBadge.tsx            # ECSタスクID表示（ALBラウンドロビン確認用）
│
├── prisma/
│   └── schema.prisma
│
├── infra/
│   └── terraform/
│       ├── main.tf
│       ├── variables.tf
│       ├── outputs.tf
│       ├── vpc.tf
│       ├── sg.tf
│       ├── alb.tf
│       ├── ecr.tf
│       ├── ecs.tf
│       ├── rds.tf
│       ├── elasticache.tf
│       ├── cloudwatch.tf
│       └── ssm.tf
│
├── Dockerfile
├── next.config.ts
├── package.json
└── tsconfig.json
```

---

## セットアップ手順

### 前提条件
- AWS CLI 設定済み（`aws configure`）
- Terraform・Node.js 20・Docker インストール済み

### 1. インフラ構築（Terraform）

```bash
cd infra/terraform
terraform init
terraform apply
# 出力: alb_dns_name / ecr_repository_url / rds_endpoint / redis_endpoint
```

### 2. 以降のデプロイ（GitHub Actions）

```bash
git push origin main
# → docker build → ECR push → ECS update-service（自動ローリングデプロイ）
# → http://<alb_dns_name>/ でアクセス確認
```

### 3. 動作確認後は必ず削除

```bash
terraform destroy
```

---

## GitHub Actions シークレット設定

| シークレット名 | 値 |
|---|---|
| `AWS_ACCESS_KEY_ID` | デプロイ用IAMユーザーキー |
| `AWS_SECRET_ACCESS_KEY` | 同上 |
| `AWS_REGION` | `ap-northeast-1` |

---

## 環境変数（SSM Parameter Store → ECSタスク定義で参照）

| パラメータ名 | 説明 |
|---|---|
| `/ssr/db_url` | `mysql://user:pass@rds-endpoint/ssrdb` |
| `/ssr/redis_host` | ElastiCacheエンドポイント |
| `/ssr/session_secret` | セッション暗号化キー |
