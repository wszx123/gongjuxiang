#!/bin/bash
set -e

# ================== 配置区 ==================
MYSQL_DB="wszx123"
MYSQL_USER="wszx123"
MYSQL_PASS="password@123@DDD"
# ===========================================


echo ">>> 更新软件包列表..."

if ! apt update; then
    echo ">>> APT 更新失败，检查是否为 Caddy 源返回 402..."

    if grep -Rqs 'dl.cloudsmith.io/public/caddy/stable' \
        /etc/apt/sources.list.d/; then

        echo ">>> 暂时禁用 Caddy 软件源..."

        for f in /etc/apt/sources.list.d/*; do
            [ -f "$f" ] || continue

            if grep -q 'dl.cloudsmith.io/public/caddy/stable' "$f"; then
                mv "$f" "${f}.disabled"
                echo "已禁用: $f"
            fi
        done

        echo ">>> 重新更新软件包列表..."
        apt update
    else
        echo "错误：APT 更新失败，未找到对应的 Caddy 软件源。"
        exit 1
    fi
fi


echo ">>> 安装 MariaDB（Debian 12 官方 default-mysql-server）..."
DEBIAN_FRONTEND=noninteractive apt install -y default-mysql-server

echo ">>> 启动并设置数据库开机自启..."
systemctl enable mariadb
systemctl start mariadb

echo ">>> 设置 root 密码并切换为密码登录..."
mysql <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_PASS}';
FLUSH PRIVILEGES;
EOF

echo ">>> 创建数据库和用户..."
mysql -uroot -p"${MYSQL_PASS}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`
  DEFAULT CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost'
  IDENTIFIED BY '${MYSQL_PASS}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ">>> 安装 PHP MySQL 扩展..."
apt install -y php8.2-mysql

echo ">>> 安装 SQLite3 和 PHP SQLite3 扩展..."
apt install -y sqlite3 php8.2-sqlite3

echo ">>> 重启 PHP-FPM..."
systemctl restart php8.2-fpm || true

echo "================================================="
echo " 数据库类型: MariaDB (MySQL 兼容)"
echo " 数据库名:   ${MYSQL_DB}"
echo " 用户名:     ${MYSQL_USER}"
echo " 密码:       ${MYSQL_PASS}"
echo "================================================="
echo " SQLite3 和 PHP SQLite3 扩展已安装"
