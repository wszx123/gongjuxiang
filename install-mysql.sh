#!/bin/bash
set -e

# === 配置变量（根据需要修改，MYSQL_PASS密码务必要修改） ===
MYSQL_VERSION="8.0"
MYSQL_DB="wszx123_db"
MYSQL_USER="wszx123_user"
MYSQL_PASS="password123"

# === 检查 root 权限 ===
if [ "$EUID" -ne 0 ]; then
  echo "请使用 root 用户运行此脚本"
  exit 1
fi

# 询问用户是否要修改默认密码
echo "默认 MySQL 密码是: ${MYSQL_PASS}"
read -p "是否要修改默认密码? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    read -s -p "请输入新的 MySQL 密码: " NEW_MYSQL_PASS
    echo
    MYSQL_PASS=$NEW_MYSQL_PASS
fi

echo ">>> 添加 MySQL 官方 APT 源..."
wget -q https://dev.mysql.com/get/mysql-apt-config_0.8.32-1_all.deb
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.32-1_all.deb
rm -f mysql-apt-config_0.8.32-1_all.deb

echo ">>> 更新包列表..."
apt update

echo ">>> 安装 MySQL Server ${MYSQL_VERSION}..."
DEBIAN_FRONTEND=noninteractive apt install -y mysql-server

echo ">>> 启动并启用 MySQL..."
systemctl enable mysql
systemctl start mysql

echo ">>> 设置 root 账号密码和权限..."
mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
FLUSH PRIVILEGES;
EOF

echo ">>> 创建数据库 ${MYSQL_DB} 和用户 ${MYSQL_USER}..."
mysql -u root -p${MYSQL_PASS} <<EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DB} DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
GRANT ALL PRIVILEGES ON ${MYSQL_DB}.* TO '${MYSQL_USER}'@'localhost';
FLUSH PRIVILEGES;
EOF

echo ">>> 安装 PHP MySQL 扩展..."
apt install -y php8.2-mysql

echo ">>> 安装 SQLite3 数据库和 PHP SQLite3 扩展..."
apt install -y sqlite3 php8.2-sqlite3

echo ">>> 重启 PHP-FPM 服务..."
systemctl restart php8.2-fpm || true

echo ">>> MySQL 安装完成!"
echo "数据库名: ${MYSQL_DB}"
echo "用户名:   ${MYSQL_USER}"
echo "密码:     ${MYSQL_PASS}"
echo "SQLite3 和 PHP SQLite3 扩展已安装!"
