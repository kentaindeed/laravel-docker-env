#!/bin/bash

# GitHub連携でCloud Buildトリガーを設定するスクリプト

# 設定変数（これらを実際の値に変更してください）
REPO_NAME="YOUR_REPO_NAME"           # リポジトリ名（例: laravel-docker-env）
REPO_OWNER="YOUR_GITHUB_USERNAME"    # GitHubユーザー名
PROJECT_ID="YOUR_PROJECT_ID"         # Google CloudプロジェクトID
TRIGGER_NAME="laravel-app-deploy"    # トリガー名

echo "GitHub連携のCloud Buildトリガーを設定します..."
echo "リポジトリ: ${REPO_OWNER}/${REPO_NAME}"
echo "プロジェクト: ${PROJECT_ID}"

# 必要なAPIを有効化
echo "必要なAPIを有効化しています..."
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable sourcerepo.googleapis.com

# GitHubリポジトリとの連携を設定
echo "GitHubリポジトリとの連携を設定しています..."
gcloud builds triggers create github \
  --repo-name="${REPO_NAME}" \
  --repo-owner="${REPO_OWNER}" \
  --branch-pattern="^main$" \
  --build-config="docker/cloudrun/cloudbuild.yaml" \
  --name="${TRIGGER_NAME}" \
  --description="Laravel app deployment to Cloud Run"

echo "トリガーが作成されました！"
echo ""
echo "次の手順:"
echo "1. GitHubでWebhookが自動設定されているか確認"
echo "2. mainブランチにpushしてデプロイをテスト"
echo "3. Cloud Consoleでビルド状況を確認: https://console.cloud.google.com/cloud-build/triggers"
echo ""
echo "トリガーの詳細を確認:"
gcloud builds triggers describe "${TRIGGER_NAME}"