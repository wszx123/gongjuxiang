#!/bin/bash

set -e
green() { echo -e "\033[32m$1\033[0m"; }

green "▶ 更新系统..."
sudo apt update && sudo apt upgrade -y

green "▶ 安装 PHP 和常用扩展..."
sudo apt install -y php php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip unzip

green "▶ 安装 Caddy..."
sudo apt install -y debian-keyring debian-archive-keyring curl
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update
sudo apt install -y caddy

green "▶ 创建网站目录..."
sudo mkdir -p /var/www/html/mysite
sudo chown -R www-data:www-data /var/www/html/mysite

green "▶ 写入 PHP 测试页..."
cat <<EOF | sudo tee /var/www/html/mysite/index.php
<?php
phpinfo();
?>
EOF

green "▶ 配置 Caddy 支持 PHP..."
cat <<EOF | sudo tee /etc/caddy/Caddyfile
:80 {
    root * /var/www/html/mysite
    php_fastcgi unix//run/php/php-fpm.sock
    file_server
}
EOF

green "▶ 启动并启用 Caddy..."
sudo systemctl enable php*-fpm
sudo systemctl restart php*-fpm
sudo systemctl restart caddy

green "✅ 成功部署！请访问 http://你的-VPS-IP 查看 PHP 测试页。"
