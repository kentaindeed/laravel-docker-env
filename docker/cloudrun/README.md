# Cloud Run デプロイメント

このディレクトリには、LaravelアプリケーションをGoogle Cloud Runにデプロイするための設定ファイルが含まれています。

## ファイル構成

- `Dockerfile` - Cloud Run用のDockerfile（nginx + PHP-FPM統合）
- `cloudbuild.yaml` - 基本的なCloud Build設定
- `cloudbuild-prod.yaml` - 本番環境用のCloud Build設定
- `nginx.conf` - nginx設定ファイル
- `default.conf` - nginxサイト設定
- `php-fpm-www.conf` - PHP-FPM設定
- `supervisord.conf` - プロセス管理設定

## デプロイ手順

### 1. 事前準備

```bash
# Google Cloud CLIの認証
gcloud auth login

# プロジェクトを設定
gcloud config set project YOUR_PROJECT_ID

# Cloud Build APIを有効化
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
```

### 2. 手動ビルド・デプロイ

```bash
# 基本デプロイ
gcloud builds submit --config=docker/cloudrun/cloudbuild.yaml .

# 本番環境デプロイ
gcloud builds submit --config=docker/cloudrun/cloudbuild-prod.yaml .
```

### 3. GitHub連携での自動デプロイ

Cloud Build トリガーを設定して、GitHubのpushで自動デプロイ：

```bash
# トリガー作成
gcloud builds triggers create github \
  --repo-name=YOUR_REPO_NAME \
  --repo-owner=YOUR_GITHUB_USERNAME \
  --branch-pattern="^main$" \
  --build-config=docker/cloudrun/cloudbuild.yaml
```

## 環境変数の設定

本番環境では、以下の環境変数を設定してください：

### Secret Managerを使用する場合

```bash
# アプリケーションキーを作成
echo -n "your-app-key" | gcloud secrets create app-key --data-file=-

# データベースパスワードを作成
echo -n "your-db-password" | gcloud secrets create db-password --data-file=-
```

### 直接環境変数を設定する場合

`cloudbuild-prod.yaml`の`substitutions`セクションを編集してください。

## カスタマイズ

### リソース設定

`cloudbuild.yaml`の以下の部分を調整：

- `--memory`: メモリ使用量（512Mi, 1Gi, 2Gi等）
- `--cpu`: CPU数（1, 2, 4等）
- `--max-instances`: 最大インスタンス数
- `--min-instances`: 最小インスタンス数（本番環境推奨）

### リージョン設定

デフォルトは`asia-northeast1`（東京）です。他のリージョンを使用する場合は変更してください。

## トラブルシューティング

### ビルドエラーの確認

```bash
# ビルドログを確認
gcloud builds log BUILD_ID
```

### Cloud Runサービスの確認

```bash
# サービス一覧
gcloud run services list

# サービス詳細
gcloud run services describe laravel-app --region=asia-northeast1
```

### ログの確認

```bash
# Cloud Runのログを確認
gcloud logs read "resource.type=cloud_run_revision AND resource.labels.service_name=laravel-app" --limit=50
```