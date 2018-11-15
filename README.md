# Docker container of PHP 5.2 with Apache

CentOS 7 & PHP 5.2 & Apache 2 & PostgreSQL 環境の Docker コンテナ生成用の Dockerfile です。

* CentOS 7
* Apache 2
* PHP 5.2
  * PHP GD
  * PHP PDO
      * MySQL (`mysql-devel`)
      * PostgreSQL (`postgresql-devel`)
      * SQLite (`sqlite-devel`)
* PostgreSQL Latest
* pgadmin

.env の編集
------------
各パラメータは各自の環境にあわせて設定して下さい。

コンテナ作成 & 実行
------------

次の Docker コマンドでコンテナを作成できます:

```
docker-compose up -d
```
