#!/bin/bash

set -e

echo "🧰 开始在 Debian 11/12 上安装 PHP 8.2 + Caddy..."

# 安装基础依赖
echo "📦 安装依赖..."
sudo apt update
sudo apt install -y lsb-release apt-transport-https ca-certificates curl gnupg2 unzip debian-keyring debian-archive-keyring

# 添加 PHP 8.2 Sury 源
echo "🔑 添加 PHP 8.2 官方源（Sury）..."
curl -fsSL https://packages.sury.org/php/apt.gpg | sudo gpg --dearmor -o /usr/share/keyrings/sury-php.gpg
echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list

# 更新源
echo "🔄 更新软件包列表..."
sudo apt update

# 安装 PHP 8.2 及常用扩展
echo "📦 安装 PHP 8.2 和常用扩展..."
sudo apt install -y php8.2 php8.2-fpm php8.2-mysql php8.2-cli php8.2-curl php8.2-gd php8.2-mbstring php8.2-xml php8.2-zip

# 启用 PHP-FPM 服务
sudo systemctl enable php8.2-fpm
sudo systemctl start php8.2-fpm

# 添加 Caddy 源
echo "🌐 添加 Caddy 官方源..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

# 安装 Caddy
echo "📦 安装 Caddy Web Server..."
sudo apt update
sudo apt install -y caddy

# 创建网站目录
echo "📁 创建网站目录 /home/html/web/web1..."
sudo mkdir -p /home/html/web/web1
sudo chown -R www-data:www-data /home/html/web/web1
sudo chmod -R 755 /home/html/web/web1

# 写入默认 Caddyfile
echo "📝 配置 Caddyfile..."
sudo tee /etc/caddy/Caddyfile > /dev/null <<EOF
example1.com {
    root * /home/html/web/web1
    php_fastcgi unix//run/php/php8.2-fpm.sock
    file_server
}
EOF

# 重启服务
echo "🚀 启动并启用 PHP 和 Caddy..."
sudo systemctl restart php8.2-fpm
sudo systemctl enable php8.2-fpm
sudo systemctl restart caddy
sudo systemctl enable caddy

echo "✅ 部署完成！"
echo "📂 网站目录：/home/html/web/web1"
echo "🌐 访问地址：http://example1.com （请解析域名）"
