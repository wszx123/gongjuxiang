#!/bin/bash
set -e

# 修复主机名解析警告（可选）
export HOSTNAME=$(hostname)

# === 配置变量（根据需要修改，MYSQL_PASS密码务必要修改） ===
MYSQL_VERSION="8.0"
MYSQL_DB="wszx123_db"
MYSQL_USER="wszx123_user"
MYSQL_PASS="password@123@DDD"

echo ">>> 添加 MySQL 官方 GPG 密钥..."
# 下载并导入 MySQL GPG 密钥
wget -qO - https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | gpg --dearmor -o /etc/apt/trusted.gpg.d/mysql.gpg

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
echo "#############################################################"
echo "数据库名: ${MYSQL_DB}"
echo "用 户 名: ${MYSQL_USER}"
echo "密    码: ${MYSQL_PASS}"

echo "SQLite3 和 PHP SQLite3 扩展已安装!"
echo "#############################################################"
