## これは何？

Laravel 環境を作成するためのDocker ファイル群です。
(下記はいずれシェルスクリプトになります)

## 使い方

```
git clone XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
cd laravel-docker
```

## 設定

### ローカルの設定

Laravel 環境の作成

```bash
# laravel pj 作成
composer create-project --prefer-dist laravel/laravel src


```

php とつなぎこみの設定
docker nginx で実行してください。
```bash
## php fpm docker にログイン
docker exec -it <nginx docker 名称> bash

## php-fpm 所有者変更
chown -R www-data:www-data /run/php-fpm/www.sock

## storage 権限変更
chmod 777 -R storage/

```



env の変更

app key の生成
```bash
# app key を生成
php artisan key:generate
```

データベース関連のenv 設定
config/database.php 内でmysql を指定していることを確認してください！

```bash
DB_CONNECTION=mysql
DB_HOST=laravel-docker-env-mysql-1
DB_PORT=3306
DB_DATABASE=database
DB_USERNAME=user
DB_PASSWORD=password

```

migration の実行
```bash
#php fpm docker 内で実行
php artisan migrate
```


ここまでこればLaravel の初期画面が見えているはずです。