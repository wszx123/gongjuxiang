#!/bin/bash
# PHP + Caddy 自动部署脚本
# 适用于 Debian/Ubuntu 系统

set -e

# 配置变量
CADDYFILE="/etc/caddy/Caddyfile"
WEB_ROOT="/home/html/web"

# 检测系统是否支持
check_system() {
    if ! command -v apt &> /dev/null; then
        echo "错误: 此脚本仅支持基于 Debian/Ubuntu 的系统"
        exit 1
    fi
    
    if [ "$(id -u)" -eq 0 ]; then
        echo "错误: 请勿以 root 用户执行此脚本"
        exit 1
    fi
}

# 检测 PHP 版本
get_php_version() {
    if command -v php &> /dev/null; then
        PHP_VER=$(php -r "echo PHP_MAJOR_VERSION.'.'.PHP_MINOR_VERSION;" 2>/dev/null || true)
        echo "检测到 PHP 版本: $PHP_VER"
    else
        echo "未检测到 PHP"
        PHP_VER=""
    fi
}

# 安装环境函数
install_env() {
    echo "===== 更新系统 ====="
    sudo apt update && sudo apt upgrade -y

    echo "===== 安装 PHP 及扩展 ====="
    sudo apt install -y php php-fpm php-mysql php-cli php-curl php-gd php-mbstring php-xml php-zip unzip curl gpg

    get_php_version

    echo "===== 安装必要工具 ====="
    sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https

    echo "===== 添加 Caddy GPG 密钥 ====="
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' \
        | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg

    echo "===== 添加 Caddy 软件源 ====="
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' \
        | sudo tee /etc/apt/sources.list.d/caddy-stable.list

    echo "===== 安装 Caddy ====="
    sudo apt update
    sudo apt install -y caddy

    echo "===== 启用 PHP-FPM 和 Caddy ====="
    if [ -n "$PHP_VER" ] && systemctl list-unit-files | grep -q "php${PHP_VER}-fpm.service"; then
        sudo systemctl enable php${PHP_VER}-fpm
        sudo systemctl restart php${PHP_VER}-fpm
    else
        sudo systemctl enable --now php*-fpm || true
    fi

    sudo systemctl enable caddy
    sudo systemctl restart caddy

    echo "===== 创建网站根目录 ====="
    sudo mkdir -p $WEB_ROOT
    sudo chown -R www-data:www-data $WEB_ROOT
    sudo chmod -R 755 $WEB_ROOT

    echo "===== 初始化 Caddyfile ====="
    if [ ! -f "$CADDYFILE" ]; then
        echo "" | sudo tee $CADDYFILE
    fi

    echo "环境安装完成！"
}

# 添加站点函数
add_site() {
    read -p "请输入站点域名（HTTP 用 IP 或域名，HTTPS 用域名）: " DOMAIN
    if [ -z "$DOMAIN" ]; then
        echo "错误: 域名不能为空"
        return 1
    fi

    read -p "请输入站点目录名（只输入文件夹名，例如 web1）: " FOLDER
    if [ -z "$FOLDER" ]; then
        echo "错误: 目录名不能为空"
        return 1
    fi

    SITE_DIR="$WEB_ROOT/$FOLDER"

    echo "===== 创建站点目录 $SITE_DIR ====="
    sudo mkdir -p "$SITE_DIR"
    sudo chown -R www-data:www-data "$SITE_DIR"
    sudo chmod -R 755 "$SITE_DIR"

    # 添加 PHP 测试文件
    echo "<?php phpinfo(); ?>" | sudo tee "$SITE_DIR/index.php" > /dev/null

    # 写入 Caddyfile 配置
    echo "===== 写入 Caddyfile 配置 ====="
    sudo tee -a "$CADDYFILE" > /dev/null <<EOF

$DOMAIN {
    root * $SITE_DIR
    php_fastcgi unix//run/php/php${PHP_VER}-fpm.sock
    file_server
}
EOF

    echo "===== 重新加载 Caddy ====="
    sudo systemctl reload caddy

    echo "站点 $DOMAIN 部署完成！目录：$SITE_DIR"
    echo "HTTP 访问: http://$DOMAIN"
}

# 显示菜单
show_menu() {
    echo "============================"
    echo "  PHP + Caddy 多站点部署脚本"
    echo "============================"
    echo "1) 安装环境（PHP + Caddy）"
    echo "2) 添加新站点"
    echo "0) 退出"
    echo "============================"
}

# 主程序循环
main() {
    check_system
    get_php_version
    
    # 如果提供了命令行参数，则直接执行对应功能
    if [ "$#" -gt 0 ]; then
        case "$1" in
            install)
                install_env
                ;;
            add-site)
                add_site
                ;;
            *)
                echo "用法: $0 {install|add-site}"
                echo "  install   - 安装 PHP 和 Caddy 环境"
                echo "  add-site  - 添加新站点"
                exit 1
                ;;
        esac
    else
        # 否则显示交互式菜单
        while true; do
            show_menu
            read -p "请输入选项: " choice

            case $choice in
                1) install_env ;;
                2) add_site ;;
                0) exit 0 ;;
                *) echo "无效选项" ;;
            esac
            
            echo ""
            read -p "按回车键继续..."
        done
    fi
}

# 执行主程序
main "$@"
