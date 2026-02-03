#!/bin/bash
set -e

# ================== 配置区 ==================
MYSQL_DB="wszx123"
MYSQL_USER="wszx123"
MYSQL_PASS="password@123@DDD"
# ===========================================

echo ">>> 更新系统..."
apt update

echo ">>> 安装 MySQL Server（Debian 官方源）..."
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo ">>> 启动并设置 MySQL 开机自启..."
systemctl enable mysql
systemctl start mysql

echo ">>> 配置 MySQL root 账号（切换为密码登录）..."
mysql <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED WITH mysql_native_password
BY '${MYSQL_PASS}';
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
echo " MySQL 安装完成"
echo " 数据库名: ${MYSQL_DB}"
echo " 用户名:   ${MYSQL_USER}"
echo " 密码:     ${MYSQL_PASS}"
echo "================================================="
echo " SQLite3 和 PHP SQLite3 扩展已安装"
