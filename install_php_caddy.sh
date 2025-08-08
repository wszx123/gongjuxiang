#!/bin/bash
set -e

# ===== 1. 更新系统 =====
echo "更新系统..."
sudo apt update && sudo apt upgrade -y

# ===== 2. 安装 PHP 及扩展 =====
echo "安装 PHP 及扩展..."
sudo apt install -y php php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip unzip curl gpg

# 检测 PHP 主版本号
PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;")
echo "检测到 PHP 版本: $PHP_VER"

# ===== 3. 安装必要工具 =====
echo "安装必要工具..."
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https

# ===== 4. 导入 Caddy GPG 密钥 =====
echo "导入 Caddy GPG 密钥..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
| sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

# ===== 5. 添加 Caddy 源 =====
echo "添加 Caddy 软件源..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
| sudo tee /etc/apt/sources.list.d/caddy-stable.list

# ===== 6. 更新并安装 Caddy =====
echo "安装 Caddy..."
sudo apt update
sudo apt install -y caddy

# ===== 7. 创建站点目录 =====
SITE_DIR="/home/html/web/web1"
echo "创建站点目录 $SITE_DIR ..."
sudo mkdir -p $SITE_DIR
sudo chown -R www-data:www-data $SITE_DIR
sudo chmod -R 755 $SITE_DIR

# ===== 8. 添加测试 PHP 文件 =====
echo "<?php phpinfo(); ?>" | sudo tee $SITE_DIR/index.php > /dev/null

# ===== 9. 配置 Caddy =====
echo "配置 Caddy..."
CADDYFILE="/etc/caddy/Caddyfile"
sudo tee $CADDYFILE > /dev/null <<EOF
:80 {
    root * $SITE_DIR
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
}
EOF

# ===== 10. 启用并启动服务 =====
echo "启用并启动 PHP-FPM 和 Caddy..."
sudo systemctl enable php${PHP_VER}-fpm
sudo systemctl restart php${PHP_VER}-fpm
sudo systemctl enable caddy
sudo systemctl restart caddy

echo "=================================="
echo " PHP + Caddy 安装完成！"
echo " 站点目录: $SITE_DIR"
echo " 配置文件: $CADDYFILE"
echo " 访问地址: http://<服务器IP>"
echo "=================================="
