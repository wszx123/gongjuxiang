#!/bin/bash

set -e

# 颜色输出函数
green() { echo -e "\e[32m$1\e[0m"; }

green "▶ 更新系统软件包..."
sudo apt update && sudo apt upgrade -y

green "▶ 安装必要工具..."
sudo apt install -y curl wget unzip git ufw

green "▶ 安装 Nginx..."
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx

green "▶ 安装 PHP 和常用扩展..."
sudo apt install -y php php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip

green "▶ 安装 MySQL Server..."
sudo apt install -y mysql-server
sudo systemctl enable mysql
sudo systemctl start mysql

green "▶ 初始化 MySQL（安全设置）..."
sudo mysql <<EOF
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'rootpass123';
FLUSH PRIVILEGES;
EOF

green "▶ 创建 PHP 网站目录..."
sudo mkdir -p /var/www/html/mysite
sudo chown -R $USER:$USER /var/www/html/mysite

green "▶ 写入测试 PHP 文件..."
cat <<EOF > /var/www/html/mysite/index.php
<?php
phpinfo();
?>
EOF

green "▶ 配置 Nginx 支持 PHP..."
NGINX_CONF="/etc/nginx/sites-available/default"
sudo cp \$NGINX_CONF \$NGINX_CONF.bak

sudo sed -i "s|root .*|root /var/www/html/mysite;|g" \$NGINX_CONF
sudo sed -i "s/index nginx-debian.html;/index index.php index.html index.htm;/" \$NGINX_CONF

# 确保 PHP FastCGI 配置存在
sudo sed -i '/location ~ \\\.php$ {/,+5d' \$NGINX_CONF

sudo tee -a \$NGINX_CONF >/dev/null <<'EOF'
location ~ \.php$ {
    include snippets/fastcgi-php.conf;
    fastcgi_pass unix:/run/php/php-fpm.sock;
}
EOF

green "▶ 启用防火墙并允许 HTTP/HTTPS..."
sudo ufw allow 'OpenSSH'
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

green "▶ 重启 Nginx 和 PHP 服务..."
sudo systemctl restart php*-fpm
sudo systemctl restart nginx

green "✅ 部署完成，请访问： http://你的VPS-IP/ 查看 PHP 页面！"
