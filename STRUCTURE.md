# アーキテクチャ・構成詳細

## アーキテクチャ全体図

```mermaid
graph TB
    Browser["ブラウザ"]

    subgraph CICD["CI/CD"]
        GA["GitHub Actions\nnpm ci + docker build"]
        ECR["ECR\nDockerイメージ"]
    end

    subgraph AWS["AWS"]
        ALB["ALB\nHTTP:80 / ラウンドロビン"]

        subgraph Private["プライベートサブネット"]
            T1["ECS Task-1\nNext.js :8080"]
            T2["ECS Task-2\nNext.js :8080"]
        end

        subgraph Data["データサブネット"]
            RDS["RDS MySQL"]
            Redis["ElastiCache Redis\nセッション / キャッシュ"]
        end

        CW["CloudWatch\nログ自動収集・アラーム"]
        SSM["SSM Parameter Store\n接続情報管理"]
    end

    Browser -->|HTTP| ALB
    ALB --> T1 & T2
    T1 & T2 --> RDS & Redis
    T1 & T2 -->|ログ自動収集| CW
    T1 & T2 -->|起動時に接続情報取得| SSM
    GA -->|docker push| ECR
    GA -->|ecs update-service| AWS
    T1 & T2 -->|イメージpull| ECR
```

---

## VPC構成図

```mermaid
graph TB
    Internet(("Internet"))
    IGW["Internet Gateway"]

    subgraph VPC["VPC  10.0.0.0/16  ap-northeast-1"]

        subgraph pub["パブリックサブネット  10.0.1.0/24（AZ-a）/ 10.0.2.0/24（AZ-c）"]
            ALB["ALB\n0.0.0.0/0 → :80"]
            NAT["NAT Gateway"]
        end

        subgraph priv["プライベートサブネット  10.0.11.0/24（AZ-a）/ 10.0.12.0/24（AZ-c）"]
            T1["ECS Task-1\nAZ-a"]
            T2["ECS Task-2\nAZ-c"]
        end

        subgraph data["データサブネット  10.0.21.0/24（AZ-a）/ 10.0.22.0/24（AZ-c）"]
            RDS["RDS MySQL :3306"]
            Redis["ElastiCache Redis :6379"]
        end

    end

    Internet --> IGW --> ALB
    ALB --> T1 & T2
    T1 & T2 --> RDS & Redis
    T1 & T2 -->|ECRイメージpull・SSM取得| NAT --> IGW
```

### セキュリティグループ経路

| 送信元 | 宛先 | ポート | 理由 |
|---|---|---|---|
| `0.0.0.0/0` | ALB SG | 80 | ユーザーからのHTTPアクセス |
| ALB SG | ECS Task SG | 8080 | ALBからコンテナへの転送 |
| ECS Task SG | RDS SG | 3306 | アプリからDBアクセス |
| ECS Task SG | Redis SG | 6379 | アプリからRedisアクセス |

---

## セッション共有の仕組み

### Redis によるセッション共有

```mermaid
sequenceDiagram
    participant U as ブラウザ
    participant ALB as ALB
    participant T1 as ECS Task-1
    participant T2 as ECS Task-2
    participant R as Redis

    U->>ALB: POST /api/auth
    ALB->>T1: 転送
    T1->>R: SET session:xxx {userId: 1}
    T1-->>U: Set-Cookie: session_id=xxx

    U->>ALB: GET /
    ALB->>T2: 転送（Task-2へ）
    T2->>R: GET session:xxx
    R-->>T2: {userId: 1}
    T2-->>U: ログイン状態維持
```

---

## CI/CDデプロイフロー

```mermaid
sequenceDiagram
    participant Dev as 開発者
    participant GA as GitHub Actions
    participant ECR as ECR
    participant ECS as ECS Service

    Dev->>GA: git push main
    GA->>GA: docker build -t app:$SHA .
    GA->>ECR: docker push app:$SHA
    GA->>ECS: aws ecs update-service --force-new-deployment
    ECS->>ECR: 新イメージpull
    ECS->>ECS: ローリングデプロイ
    note over ECS: 旧Task停止 → 新Task起動<br/>ALBヘルスチェック確認しながら順次切り替え
```

EC2と違い、**ECSがローリングデプロイを自動で管理**します。

---

## 各ファイルの役割

### アプリ

| ファイル | 役割 |
|---|---|
| `src/app/page.tsx` | Server Component。DBからアイテム取得してHTMLを返す |
| `src/app/items/[id]/page.tsx` | アイテム詳細。Redisキャッシュ経由でDB取得 |
| `src/app/api/auth/route.ts` | ログイン・ログアウト。セッションをRedisに保存 |
| `src/app/api/health/route.ts` | `{ status: "ok" }` を返すだけ。ALBヘルスチェック用 |
| `src/lib/db.ts` | Prisma clientのシングルトン |
| `src/lib/redis.ts` | ioredis clientのシングルトン |
| `src/lib/session.ts` | Cookie↔Redisのセッション読み書きユーティリティ |
| `src/components/TaskBadge.tsx` | `HOSTNAME` 環境変数（ECSタスクID）を表示。ALBラウンドロビンの目視確認用 |

### Dockerfile（マルチステージビルド）

```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=8080
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
COPY --from=builder /app/public ./public
EXPOSE 8080
CMD ["node", "server.js"]
```

standaloneモードで最小構成のイメージを作る。

### インフラ（Terraform）

| ファイル | 役割 |
|---|---|
| `vpc.tf` | VPC・サブネット×6・IGW・NATゲートウェイ・ルートテーブル |
| `sg.tf` | セキュリティグループ×4（ALB・ECS Task・RDS・Redis） |
| `alb.tf` | ALB・ターゲットグループ（IPタイプ）・リスナー・ヘルスチェック |
| `ecr.tf` | ECRリポジトリ（イメージの置き場） |
| `ecs.tf` | ECSクラスター・タスク定義・サービス（desired count=2）・IAMロール |
| `rds.tf` | RDS MySQL・サブネットグループ |
| `elasticache.tf` | ElastiCache Redisクラスター（1ノード） |
| `cloudwatch.tf` | ロググループ・アラーム（CPU・5xx） |
| `ssm.tf` | Parameter Store（DB接続文字列・Redisホスト・セッションシークレット） |

### EC2との主な違い

| | EC2 | ECS Fargate |
|---|---|---|
| サーバー管理 | userdata.sh・pm2 | 不要（Dockerコンテナ） |
| デプロイ | S3→SSM→差し替え→再起動 | ECR push → update-service |
| ローリングデプロイ | deploy.shで手動制御 | ECSが自動管理 |
| ログ収集 | CW Agentインストール必要 | タスク定義で自動収集 |
| ALBターゲット登録 | インスタンスID | IPアドレス（タスクのENI） |
