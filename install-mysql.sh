
#!/bin/bash
set -Eeuo pipefail

# ================== 配置区 ==================

# 第一个数据库
MYSQL_DB="wszx123"
MYSQL_USER="wszx123"
MYSQL_PASS="99JQpRF2fZQUsrKnjb7DgSUSfpVl@123@DDD99"

# 第二个数据库
MYSQL_DB2="wszx456"
MYSQL_USER2="wszx456"
MYSQL_PASS2="99JQpRF2fZQUsrKnjb7DgSUSfpVl@456@DDD99"

# root 密码自动使用第一个数据库密码
MYSQL_ROOT_PASS="$MYSQL_PASS"

# ============================================

# 必须使用 root 运行
if [ "$EUID" -ne 0 ]; then
    echo "错误：请使用 root 用户运行此脚本！"
    exit 1
fi

# 检查数据库名和用户名
for name in "$MYSQL_DB" "$MYSQL_USER" "$MYSQL_DB2" "$MYSQL_USER2"; do
    if [[ ! "$name" =~ ^[A-Za-z0-9_]+$ ]]; then
        echo "错误：数据库名和用户名只能使用字母、数字和下划线！"
        exit 1
    fi
done

# 检查两个数据库及用户名不能重复
if [[ "$MYSQL_DB" == "$MYSQL_DB2" || "$MYSQL_USER" == "$MYSQL_USER2" ]]; then
    echo "错误：两个数据库名和用户名不能重复！"
    exit 1
fi

# 检查密码
for pass in "$MYSQL_PASS" "$MYSQL_PASS2"; do
    case "$pass" in
        ""|*"'"*|*\\*|*$'\n'*)
            echo "错误：密码不能为空，且不能包含单引号、反斜杠或换行！"
            exit 1
            ;;
    esac
done

if [[ "$MYSQL_PASS" == "99JQpRF2fZQUsrKnjb7DgSUSfpVl@123@DDD99" ||
      "$MYSQL_PASS2" == "99JQpRF2fZQUsrKnjb7DgSUSfpVl@456@DDD99" ]]; then
    echo "错误：请先修改配置区的两个数据库密码！"
    exit 1
fi

# ================== 更新软件源 ==================

echo
echo ">>> 更新软件包列表..."

APT_LOG="$(mktemp)"
trap 'rm -f "$APT_LOG"' EXIT

if ! apt-get update 2>&1 | tee "$APT_LOG"; then

    # 只有确认 Caddy 源返回 402 才执行禁用操作
    if grep -q 'dl.cloudsmith.io/public/caddy/stable' "$APT_LOG" &&
       grep -q '402 Payment Required' "$APT_LOG"; then

        echo
        echo ">>> 检测到 Caddy 软件源返回 402..."
        echo ">>> 暂时禁用 Caddy 软件源..."

        FOUND_CADDY=0

        for f in /etc/apt/sources.list /etc/apt/sources.list.d/*; do
            [ -f "$f" ] || continue
            [[ "$f" == *.disabled ]] && continue

            if grep -q 'dl.cloudsmith.io/public/caddy/stable' "$f"; then
                mv "$f" "${f}.disabled"
                echo "已禁用：$f"
                FOUND_CADDY=1
            fi
        done

        if [ "$FOUND_CADDY" -eq 0 ]; then
            echo "错误：没有找到可禁用的 Caddy 源文件！"
            exit 1
        fi

        echo
        echo ">>> 重新更新软件包列表..."

        if ! apt-get update; then
            echo "错误：APT 更新仍然失败，请检查软件源！"
            exit 1
        fi

    else
        echo
        echo "错误：APT 更新失败，请检查软件源！"
        exit 1
    fi
fi

# ================== 安装 MariaDB ==================

echo
echo ">>> 正在安装 MariaDB..."

export DEBIAN_FRONTEND=noninteractive

apt-get install -y default-mysql-server

echo
echo ">>> 启动 MariaDB 并设置开机自启..."

systemctl enable mariadb
systemctl start mariadb

# ================== 设置 root 密码 ==================

echo
echo ">>> 正在设置 MariaDB root 密码..."

# 全新 Debian/MariaDB 安装通常支持本地 socket 登录
if mysql -uroot -e "SELECT 1" >/dev/null 2>&1; then

    mysql -uroot <<EOF
ALTER USER 'root'@'localhost'
IDENTIFIED BY '${MYSQL_ROOT_PASS}';
FLUSH PRIVILEGES;
EOF

else
    echo "错误：MariaDB root 无法通过本地 socket 登录。"
    echo "此脚本主要用于全新安装，请检查是否已有 MariaDB 配置。"
    exit 1
fi

# 验证 root 密码
if ! mysql -uroot -p"${MYSQL_ROOT_PASS}" -e "SELECT 1" >/dev/null 2>&1; then
    echo "错误：MariaDB root 密码验证失败！"
    exit 1
fi

# ================== 创建两个数据库 ==================

echo
echo ">>> 正在创建两个数据库和独立账号..."

mysql -uroot -p"${MYSQL_ROOT_PASS}" <<EOF

CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB}\`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost'
IDENTIFIED BY '${MYSQL_PASS}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DB}\`.*
TO '${MYSQL_USER}'@'localhost';


CREATE DATABASE IF NOT EXISTS \`${MYSQL_DB2}\`
DEFAULT CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER2}'@'localhost'
IDENTIFIED BY '${MYSQL_PASS2}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DB2}\`.*
TO '${MYSQL_USER2}'@'localhost';

FLUSH PRIVILEGES;

EOF

echo ">>> 第一个数据库创建完成：${MYSQL_DB}"
echo ">>> 第二个数据库创建完成：${MYSQL_DB2}"

# ================== 安装 PHP 数据库扩展 ==================

echo
echo ">>> 正在安装 PHP 8.2 MySQL 扩展..."

apt-get install -y php8.2-mysql

echo
echo ">>> 正在安装 SQLite3 扩展..."

apt-get install -y sqlite3 php8.2-sqlite3

# ================== 重启 PHP-FPM ==================

echo
echo ">>> 正在重启 PHP-FPM..."

if systemctl list-unit-files --type=service | grep -q '^php8.2-fpm.service'; then
    systemctl restart php8.2-fpm
else
    echo "提示：未检测到 PHP 8.2 FPM 服务，跳过重启。"
fi

# ================== 安装完成 ==================

echo
echo "================================================="
echo "          MariaDB 双数据库安装完成 2026-11-17"
echo "================================================="
echo
echo "数据库类型：MariaDB（MySQL 兼容）"
echo "数据库端口：3306"
echo "字符集：utf8mb4"
echo
echo "第一个数据库："
echo "数据库名：${MYSQL_DB}"
echo "用户名：${MYSQL_USER}"
echo "密码：已设置"
echo
echo "第二个数据库："
echo "数据库名：${MYSQL_DB2}"
echo "用户名：${MYSQL_USER2}"
echo "密码：已设置"
echo
echo "MariaDB root 密码：与第一个数据库密码相同"
echo
echo "PHP 扩展："
echo "php8.2-mysql"
echo "php8.2-sqlite3"
echo "sqlite3"
echo
echo "================================================="
echo "              安装全部完成！"
echo "================================================="
