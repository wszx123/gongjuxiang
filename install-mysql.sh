#!/bin/bash
set -e

# 修复主机名解析警告（可选）
export HOSTNAME=$(hostname)

# === 配置变量（根据需要修改，MYSQL_PASS密码务必要修改） ===
MYSQL_VERSION="8.0"
MYSQL_DB="wszx123_db"
MYSQL_USER="wszx123_user"
MYSQL_PASS="password@123@DDD"

echo ">>> 检查是否已安装 MySQL..."
if command -v mysql &> /dev/null; then
    echo ">>> MySQL 已安装，跳过安装步骤，直接配置..."
    INSTALL_MYSQL=false
else
    echo ">>> 准备安装 MySQL..."
    INSTALL_MYSQL=true
    
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
    # 方法1: 尝试导入密钥到trusted.gpg.d
    wget -qO- https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | gpg --dearmor | tee /etc/apt/trusted.gpg.d/mysql-archive-keyring.gpg > /dev/null
    
    # 方法2: 如果方法1失败，尝试使用apt-key
    if ! apt-key list | grep -q B7B3B788A8D3785C; then
        wget -qO- https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | apt-key add -
    fi
    
    # 方法3: 确保密钥文件存在且有效
    if [ ! -f /etc/apt/trusted.gpg.d/mysql-archive-keyring.gpg ] || [ ! -s /etc/apt/trusted.gpg.d/mysql-archive-keyring.gpg ]; then
        wget -qO- https://repo.mysql.com/RPM-GPG-KEY-mysql-2022 | gpg --no-default-keyring --keyring /etc/apt/trusted.gpg.d/mysql.gpg --import -
    fi
    
    echo ">>> 添加 MySQL 官方仓库..."
    # 手动创建MySQL仓库配置文件
    cat > /etc/apt/sources.list.d/mysql.list <<EOF
deb [signed-by=/etc/apt/trusted.gpg.d/mysql.gpg] http://repo.mysql.com/apt/debian bookworm mysql-${MYSQL_VERSION}
EOF

    echo ">>> 更新包列表..."
    apt update
    
    echo ">>> 安装 MySQL Server ${MYSQL_VERSION}..."
    DEBIAN_FRONTEND=noninteractive apt install -y mysql-server
fi

echo ">>> 启动并启用 MySQL..."
systemctl enable mysql || true
systemctl restart mysql || systemctl start mysql

echo ">>> 等待 MySQL 服务启动..."
sleep 3

echo ">>> 设置 root 账号密码和权限..."
# 尝试使用空密码连接，如果失败则使用已设置的密码
if mysql -u root -e "SELECT 1;" &>/dev/null; then
    mysql -u root <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_PASS}';
FLUSH PRIVILEGES;
EOF
elif mysql -u root -p${MYSQL_PASS} -e "SELECT 1;" &>/dev/null; then
    echo ">>> Root密码已设置，跳过密码设置..."
else
    echo ">>> 警告：无法连接到MySQL，可能需要手动设置密码"
fi

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
