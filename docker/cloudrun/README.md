# Cloud Run デプロイメント

このディレクトリには、LaravelアプリケーションをGoogle Cloud Runにデプロイするための設定ファイルが含まれています。

## ファイル構成

- `Dockerfile` - Cloud Run用のDockerfile（nginx + PHP-FPM統合）
- `cloudbuild.yaml` - Cloud Build設定（GitHubからのソース取得、マイグレーション実行、デプロイ）
- `nginx.conf` - nginx設定ファイル
- `default.conf` - nginxサイト設定
- `php-fpm-www.conf` - PHP-FPM設定
- `supervisord.conf` - プロセス管理設定

## 主な機能

- **GitHubからの自動ソース取得**: `https://github.com/kentaindeed/laravel-kensho-env.git`からソースコードを自動クローン
- **自動マイグレーション実行**: デプロイ前にCloud SQL経由でマイグレーションを実行
- **Cloud SQL統合**: `cloudsql_instances`を使用した安全なデータベース接続
- **本番環境設定**: 2Gi メモリ、2 CPU、最大100インスタンスの本番環境向け設定

## デプロイ手順

### 1. 事前準備

```bash
# Google Cloud CLIの認証
gcloud auth login

# プロジェクトを設定
gcloud config set project YOUR_PROJECT_ID

# 必要なAPIを有効化
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sqladmin.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### 2. Cloud SQL設定

```bash
# Cloud SQLインスタンスを作成（既存の場合はスキップ）
gcloud sql instances create YOUR_INSTANCE_NAME \
  --database-version=MYSQL_8_0 \
  --region=asia-northeast1 \
  --tier=db-f1-micro

# データベースを作成
gcloud sql databases create YOUR_DATABASE_NAME --instance=YOUR_INSTANCE_NAME

# ユーザーを作成
gcloud sql users create YOUR_DB_USER --instance=YOUR_INSTANCE_NAME --password=YOUR_PASSWORD
```

### 3. 権限設定

```bash
# Cloud Build サービスアカウントに必要な権限を付与
PROJECT_NUMBER=$(gcloud projects describe $PROJECT_ID --format="value(projectNumber)")

# Cloud SQL Client権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/cloudsql.client"

# Cloud Run Admin権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/run.admin"

# Service Account User権限
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"
```

### 4. Cloud Buildトリガーの作成

```bash
# GitHubトリガーを作成
gcloud builds triggers create github \
  --repo-name=laravel-kensho-env \
  --repo-owner=kentaindeed \
  --branch-pattern="^main$" \
  --build-config=docker/cloudrun/cloudbuild.yaml \
  --substitutions=_APP_KEY="YOUR_APP_KEY",_DB_HOST="YOUR_DB_HOST",_DB_DATABASE="YOUR_DATABASE_NAME",_DB_USERNAME="YOUR_DB_USER",_DB_PASSWORD="YOUR_DB_PASSWORD",_DB_CONNECTION_NAME="YOUR_PROJECT_ID:asia-northeast1:YOUR_INSTANCE_NAME"
```

### 5. 手動ビルド・デプロイ

```bash
# 置換変数を指定してビルド実行
gcloud builds submit --config=docker/cloudrun/cloudbuild.yaml \
  --substitutions=_APP_KEY="YOUR_APP_KEY",_DB_HOST="YOUR_DB_HOST",_DB_DATABASE="YOUR_DATABASE_NAME",_DB_USERNAME="YOUR_DB_USER",_DB_PASSWORD="YOUR_DB_PASSWORD",_DB_CONNECTION_NAME="YOUR_PROJECT_ID:asia-northeast1:YOUR_INSTANCE_NAME" .
```

## 環境変数の設定

Cloud Buildトリガーの「置換変数」で以下の変数を設定してください：

| 変数名 | 説明 | 例 |
|--------|------|-----|
| `_APP_KEY` | Laravelアプリケーションキー | `base64:xxxxx` |
| `_DB_HOST` | Cloud SQL Private IP | `10.x.x.x` |
| `_DB_DATABASE` | データベース名 | `laravel_prod` |
| `_DB_USERNAME` | データベースユーザー名 | `laravel_user` |
| `_DB_PASSWORD` | データベースパスワード | `secure_password` |
| `_DB_CONNECTION_NAME` | Cloud SQL接続名 | `project-id:asia-northeast1:instance-name` |

### Cloud SQL接続名の確認方法

```bash
gcloud sql instances describe YOUR_INSTANCE_NAME --format="value(connectionName)"
```

## デプロイフロー

1. **ソース取得**: GitHubリポジトリからソースコードをクローン
2. **イメージビルド**: Dockerイメージをビルド（Laravel依存関係インストール含む）
3. **レジストリプッシュ**: Container Registryにイメージをプッシュ
4. **マイグレーション実行**: Cloud SQL経由でデータベースマイグレーションを実行
5. **Cloud Runデプロイ**: 本番環境設定でCloud Runにデプロイ

## リソース設定

現在の本番環境設定：

- **メモリ**: 2Gi
- **CPU**: 2
- **最大インスタンス数**: 100
- **最小インスタンス数**: 1
- **同時実行数**: 80
- **タイムアウト**: 300秒
- **リージョン**: asia-northeast1（東京）

## トラブルシューティング

### ビルドエラーの確認

```bash
# ビルドログを確認
gcloud builds log BUILD_ID

# 最新のビルドを確認
gcloud builds list --limit=5
```

### Cloud Runサービスの確認

```bash
# サービス一覧
gcloud run services list --region=asia-northeast1

# サービス詳細
gcloud run services describe laravel-app-prod --region=asia-northeast1
```

### Cloud SQLの接続確認

```bash
# Cloud SQLインスタンスの状態確認
gcloud sql instances describe YOUR_INSTANCE_NAME

# 接続テスト
gcloud sql connect YOUR_INSTANCE_NAME --user=YOUR_DB_USER
```

### ログの確認

```bash
# Cloud Runのログを確認
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=laravel-app-prod" --limit=50

# Cloud Buildのログを確認
gcloud logs read "resource.type=build" --limit=20
```

### よくある問題

1. **マイグレーションエラー**: Cloud SQL接続名が正しいか確認
2. **権限エラー**: Cloud Build サービスアカウントの権限を確認
3. **イメージプルエラー**: Container Registry の権限を確認
4. **メモリ不足**: リソース設定を調整

## セキュリティ考慮事項

- 機密情報はCloud Buildトリガーの置換変数で管理
- Cloud SQL Private IPを使用してセキュアな接続
- 最小権限の原則でサービスアカウント権限を設定