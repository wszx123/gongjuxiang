#!/bin/bash
set -e

# 修复主机名解析警告（可选）
export HOSTNAME=$(hostname)

# === 配置变量（根据需要修改，MYSQL_PASS密码务必要修改） ===
MYSQL_VERSION="8.0"
MYSQL_DB="wszx123_db"
MYSQL_USER="wszx123_user"
MYSQL_PASS="password@123@DDD"

echo ">>> 清理旧的 MySQL 配置..."
# 移除旧的mysql-apt-config包（如果存在）
dpkg -r mysql-apt-config 2>/dev/null || true
dpkg --purge mysql-apt-config 2>/dev/null || true

# 清理旧的MySQL仓库配置
rm -f /etc/apt/sources.list.d/mysql.list
rm -f /etc/apt/sources.list.d/mysql-*.list
rm -f /etc/apt/trusted.gpg.d/mysql-archive-keyring.gpg
rm -f /etc/apt/trusted.gpg.d/mysql.gpg
rm -f /etc/apt/sources.list.d/mysql-apt-config.list
apt clean

echo ">>> 添加 MySQL 官方 GPG 密钥..."
# 下载并导入最新的MySQL GPG密钥（使用2023年密钥）
wget -qO /tmp/mysql_pubkey.asc https://repo.mysql.com/RPM-GPG-KEY-mysql-2023
gpg --dearmor /tmp/mysql_pubkey.asc > /etc/apt/trusted.gpg.d/mysql.gpg 2>/dev/null || \
wget -qO- https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 | gpg --dearmor -o /etc/apt/trusted.gpg.d/mysql.gpg
rm -f /tmp/mysql_pubkey.asc

echo ">>> 手动配置 MySQL 官方仓库..."
# 手动创建MySQL仓库配置文件
cat > /etc/apt/sources.list.d/mysql.list <<EOF
deb [signed-by=/etc/apt/trusted.gpg.d/mysql.gpg] http://repo.mysql.com/apt/debian/ bookworm mysql-${MYSQL_VERSION}
EOF

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
