#!/bin/bash

# 定义颜色
re="\033[0m"
red="\033[1;91m"
green="\e[1;32m"
yellow="\e[1;33m"
purple="\e[1;35m"
skyblue="\e[1;36m"
red() { echo -e "\e[1;91m$1\033[0m"; }
green() { echo -e "\e[1;32m$1\033[0m"; }
yellow() { echo -e "\e[1;33m$1\033[0m"; }
purple() { echo -e "\e[1;35m$1\033[0m"; }
skyblue() { echo -e "\e[1;36m$1\033[0m"; }
reading() { 
    if [ -n "$3" ]; then
        read -p "$(red "$1")" -i "$3" "$2"
    else
        read -p "$(red "$1")" "$2"
    fi
}

# 定义常量
server_name="xray"
work_dir="/etc/xray"
config_dir="${work_dir}/config.json"
client_dir="${work_dir}/url.txt"
# 定义环境变量
export UUID=${UUID:-$(cat /proc/sys/kernel/random/uuid)}
export PORT=${PORT:-$(shuf -i 1000-60000 -n 1)}
export ARGO_PORT=${ARGO_PORT:-'8080'}
export CFIP=${CFIP:-'cdns.doon.eu.org'} 
export CFPORT=${CFPORT:-'443'}   

# 检查是否为root下运行
[[ $EUID -ne 0 ]] && red "请在root用户下运行脚本" && exit 1

# 检查 xray 是否已安装
check_xray() {
if [ -f "${work_dir}/${server_name}" ]; then
    if [ -f /etc/alpine-release ]; then
        rc-service xray status | grep -q "started" && green "running" && return 0 || yellow "not running" && return 1
    else 
        [ "$(systemctl is-active xray)" = "active" ] && green "running" && return 0 || yellow "not running" && return 1
    fi
else
    red "not installed"
    return 2
fi
}

# 检查 argo 是否已安装
check_argo() {
if [ -f "${work_dir}/argo" ]; then
    if [ -f /etc/alpine-release ]; then
        rc-service tunnel status | grep -q "started" && green "running" && return 0 || yellow "not running" && return 1
    else 
        [ "$(systemctl is-active tunnel)" = "active" ] && green "running" && return 0 || yellow "not running" && return 1
    fi
else
    red "not installed"
    return 2
fi
}

# 检查 caddy 是否已安装
check_caddy() {
if command -v caddy &>/dev/null; then
    if [ -f /etc/alpine-release ]; then
        rc-service caddy status | grep -q "started" && green "running" && return 0 || yellow "not running" && return 1
    else 
        [ "$(systemctl is-active caddy)" = "active" ] && green "running" && return 0 || yellow "not running" && return 1
    fi
else
    red "not installed"
    return 2
fi
}

#根据系统类型安装、卸载依赖
manage_packages() {
    if [ $# -lt 2 ]; then
        red "Unspecified package name or action" 
        return 1
    fi

    action=$1
    shift

    for package in "$@"; do
        if [ "$action" == "install" ]; then
            if command -v "$package" &>/dev/null; then
                green "${package} already installed"
                continue
            fi
            yellow "正在安装 ${package}..."
            if command -v apt &>/dev/null; then
                DEBIAN_FRONTEND=noninteractive apt-get update -y && apt install -y "$package"
            elif command -v dnf &>/dev/null; then
                dnf update -y && dnf install -y "$package"
            elif command -v yum &>/dev/null; then
                yum update -y &7 yum install -y "$package"
            elif command -v apk &>/dev/null; then
                apk update && apk add "$package"
            else
                red "Unknown system!"
                return 1
            fi
        elif [ "$action" == "uninstall" ]; then
            if ! command -v "$package" &>/dev/null; then
                yellow "${package} is not installed"
                continue
            fi
            yellow "正在卸载 ${package}..."
            if command -v apt &>/dev/null; then
                apt remove -y "$package" && apt autoremove -y
            elif command -v dnf &>/dev/null; then
                dnf remove -y "$package" && dnf autoremove -y
            elif command -v yum &>/dev/null; then
                yum remove -y "$package" && yum autoremove -y
            elif command -v apk &>/dev/null; then
                apk del "$package"
            else
                red "Unknown system!"
                return 1
            fi
        else
            red "Unknown action: $action"
            return 1
        fi
    done

    return 0
}

# 获取ip
get_realip() {
  ip=$(curl -s --max-time 2 ipv4.ip.sb)
  if [ -z "$ip" ]; then
      ipv6=$(curl -s --max-time 2 ipv6.ip.sb)
      echo "[$ipv6]"
  else
      if echo "$(curl -s http://ipinfo.io/org)" | grep -qE 'Cloudflare|UnReal|AEZA|Andrei'; then
          ipv6=$(curl -s --max-time 2 ipv6.ip.sb)
          echo "[$ipv6]"
      else
          echo "$ip"
      fi
  fi
}

# 下载并安装 xray,cloudflared
install_xray() {
    clear
    purple "正在安装${1:-Xray-2go【默认四协议】}中，请稍等..."
    ARCH_RAW=$(uname -m)
    case "${ARCH_RAW}" in
        'x86_64') ARCH='amd64'; ARCH_ARG='64' ;;
        'x86' | 'i686' | 'i386') ARCH='386'; ARCH_ARG='32' ;;
        'aarch64' | 'arm64') ARCH='arm64'; ARCH_ARG='arm64-v8a' ;;
        'armv7l') ARCH='armv7'; ARCH_ARG='arm32-v7a' ;;
        's390x') ARCH='s390x' ;;
        *) red "不支持的架构: ${ARCH_RAW}"; exit 1 ;;
    esac

    # 下载xray,cloudflared
    [ ! -d "${work_dir}" ] && mkdir -p "${work_dir}" && chmod 777 "${work_dir}"
    curl -sLo "${work_dir}/${server_name}.zip" "https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-${ARCH_ARG}.zip"
    curl -sLo "${work_dir}/qrencode" "https://github.com/eooce/test/releases/download/${ARCH}/qrencode-linux-${ARCH}"
    curl -sLo "${work_dir}/argo" "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-${ARCH}"
    unzip "${work_dir}/${server_name}.zip" -d "${work_dir}/" > /dev/null 2>&1 && chmod +x ${work_dir}/${server_name} ${work_dir}/argo ${work_dir}/qrencode
    rm -rf "${work_dir}/${server_name}.zip" "${work_dir}/geosite.dat" "${work_dir}/geoip.dat" "${work_dir}/README.md" "${work_dir}/LICENSE" 

   # 生成随机UUID和密码
    password=$(< /dev/urandom tr -dc 'A-Za-z0-9' | head -c 24)
    GRPC_PORT=$(($PORT + 1))
    XHTTP_PORT=$(($PORT + 2))

    # 关闭防火墙
    iptables -F > /dev/null 2>&1 && iptables -P INPUT ACCEPT > /dev/null 2>&1 && iptables -P FORWARD ACCEPT > /dev/null 2>&1 && iptables -P OUTPUT ACCEPT > /dev/null 2>&1
    command -v ip6tables &> /dev/null && ip6tables -F > /dev/null 2>&1 && ip6tables -P INPUT ACCEPT > /dev/null 2>&1 && ip6tables -P FORWARD ACCEPT > /dev/null 2>&1 && ip6tables -P OUTPUT ACCEPT > /dev/null 2>&1

    output=$(/etc/xray/xray x25519)
    private_key=$(echo "${output}" | grep 'PrivateKey:' | awk '{print $2}')
    public_key=$(echo "${output}" | grep 'Password (PublicKey):' | awk '{print $3}')

   # 生成配置文件
cat > "${config_dir}" << EOF
{
  "log": { "access": "/dev/null", "error": "/dev/null", "loglevel": "none" },
  "inbounds": [
    {
      "port": $ARGO_PORT,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "$UUID", "flow": "xtls-rprx-vision" }],
        "decryption": "none",
        "fallbacks": [
          { "dest": 3001 }, { "path": "/vless-argo", "dest": 3002 },
          { "path": "/vmess-argo", "dest": 3003 }
        ]
      },
      "streamSettings": { "network": "tcp" }
    },
    {
      "port": 3001, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [{ "id": "$UUID" }], "decryption": "none" },
      "streamSettings": { "network": "tcp", "security": "none" }
    },
    {
      "port": 3002, "listen": "127.0.0.1", "protocol": "vless",
      "settings": { "clients": [{ "id": "$UUID", "level": 0 }], "decryption": "none" },
      "streamSettings": { "network": "ws", "security": "none", "wsSettings": { "path": "/vless-argo" } },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false }
    },
    {
      "port": 3003, "listen": "127.0.0.1", "protocol": "vmess",
      "settings": { "clients": [{ "id": "$UUID", "alterId": 0 }] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/vmess-argo" } },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls", "quic"], "metadataOnly": false }
    },
    {
      "listen":"::","port": $XHTTP_PORT, "protocol": "vless","settings": {"clients": [{"id": "$UUID"}],"decryption": "none"},
      "streamSettings": {"network": "xhttp","security": "reality","realitySettings": {"target": "www.nazhumi.com:443","xver": 0,"serverNames": 
      ["www.nazhumi.com"],"privateKey": "$private_key","shortIds": [""]}},"sniffing": {"enabled": true,"destOverride": ["http","tls","quic"]}
    },
    {
      "listen":"::","port":$GRPC_PORT,"protocol":"vless","settings":{"clients":[{"id":"$UUID"}],"decryption":"none"},
      "streamSettings":{"network":"grpc","security":"reality","realitySettings":{"dest":"www.iij.ad.jp:443","serverNames":["www.iij.ad.jp"],
      "privateKey":"$private_key","shortIds":[""]},"grpcSettings":{"serviceName":"grpc"}},"sniffing":{"enabled":true,"destOverride":["http","tls","quic"]}
    }
  ],
  "dns": { "servers": ["https+local://8.8.8.8/dns-query"] },
   "outbounds": [
        {
            "protocol": "freedom",
            "tag": "direct"
        },
        {
            "protocol": "blackhole",
            "tag": "block"
        }
    ]
}
EOF
}

write_xray_systemd_service() {
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
NoNewPrivileges=yes
ExecStart=$work_dir/xray -c $config_dir
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray
}

write_xray_openrc_service() {
    cat > /etc/init.d/xray << 'EOF'
#!/sbin/openrc-run

description="Xray service"
command="/etc/xray/xray"
command_args="-c /etc/xray/config.json"
command_background=true
pidfile="/var/run/xray.pid"
EOF

    chmod +x /etc/init.d/xray
    rc-update add xray default
    rc-service xray restart
}

start_single_xray_service() {
    if [ -x "$(command -v systemctl)" ]; then
        write_xray_systemd_service
    elif [ -x "$(command -v rc-update)" ]; then
        write_xray_openrc_service
    else
        red "Unsupported init system"
        return 1
    fi
}

filter_single_node_config() {
    local node_mode=$1

    case "${node_mode}" in
        grpc-reality)
            jq '.inbounds = [.inbounds[] | select(.streamSettings.network == "grpc" and .streamSettings.security == "reality")]' "$config_dir" > "${config_dir}.tmp"
            ;;
        xhttp-reality)
            jq '.inbounds = [.inbounds[] | select(.streamSettings.network == "xhttp" and .streamSettings.security == "reality")]' "$config_dir" > "${config_dir}.tmp"
            ;;
        reality)
            jq '.inbounds = [.inbounds[] | select(.streamSettings.network == "grpc" and .streamSettings.security == "reality") | .streamSettings.network = "tcp" | .settings.clients[0].flow = "xtls-rprx-vision" | .streamSettings.realitySettings.target = .streamSettings.realitySettings.dest | del(.streamSettings.grpcSettings)]' "$config_dir" > "${config_dir}.tmp"
            ;;
        *)
            red "未知节点类型：${node_mode}"
            return 1
            ;;
    esac

    if [ $? -eq 0 ]; then
        mv "${config_dir}.tmp" "$config_dir"
        echo "${node_mode}" > "${work_dir}/install-mode"
    else
        rm -f "${config_dir}.tmp"
        red "节点配置生成失败"
        return 1
    fi
}

get_isp_name() {
    curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://api.ip.sb/geoip" | tr -d '\n' | awk -F\" '{c="";i="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="isp")i=$(x+2)};if(c&&i)print c"-"i}' | sed 's/ /_/g' || curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://ipapi.co/json" | tr -d '\n' | awk -F\" '{c="";o="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="org")o=$(x+2)};if(c&&o)print c"-"o}' | sed 's/ /_/g' || echo "vps"
}

show_single_node_info() {
    local node_mode=$1
    local node_link
    IP=$(get_realip)
    isp=$(get_isp_name)

    case "${node_mode}" in
        grpc-reality)
            node_link="vless://${UUID}@${IP}:${GRPC_PORT}?encryption=none&security=reality&sni=www.iij.ad.jp&fp=chrome&pbk=${public_key}&allowInsecure=0&type=grpc&authority=www.iij.ad.jp&serviceName=grpc&mode=gun#${isp}"
            ;;
        xhttp-reality)
            node_link="vless://${UUID}@${IP}:${XHTTP_PORT}?encryption=none&security=reality&sni=www.nazhumi.com&fp=chrome&pbk=${public_key}&allowInsecure=0&type=xhttp&mode=auto#${isp}"
            ;;
        reality)
            node_link="vless://${UUID}@${IP}:${GRPC_PORT}?encryption=none&security=reality&sni=www.iij.ad.jp&fp=chrome&pbk=${public_key}&allowInsecure=0&type=tcp&flow=xtls-rprx-vision#${isp}"
            ;;
    esac

    printf '%s\n' "$node_link" > "$client_dir"
    base64 -w0 "$client_dir" > "${work_dir}/sub.txt"
    green "\n${node_mode}节点安装完成\n"
    purple "$node_link\n"
    yellow "该安装模式未启用订阅服务，请直接复制以上节点链接\n"
}

install_single_xray_node() {
    local node_mode=$1
    clear
    manage_packages install jq unzip iptables openssl coreutils lsof
    install_xray "${node_mode}节点"
    filter_single_node_config "$node_mode" || return 1
    start_single_xray_service || return 1
    sleep 2
    show_single_node_info "$node_mode"
    create_shortcut
}

filter_argo_node_config() {
    jq '.inbounds = .inbounds[:4]' "$config_dir" > "${config_dir}.tmp" && mv "${config_dir}.tmp" "$config_dir"
    if [ $? -ne 0 ]; then
        rm -f "${config_dir}.tmp"
        red "Argo节点配置生成失败"
        return 1
    fi
    echo "argo" > "${work_dir}/install-mode"
}

get_argo_domain_only() {
    local argo_domain
    for i in {1..10}; do
        if [ -f "${work_dir}/argo.log" ]; then
            argo_domain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' "${work_dir}/argo.log")
        fi
        [ -n "$argo_domain" ] && break
        sleep 2
    done
    echo "$argo_domain"
}

show_argo_node_info() {
    local argo_domain=$1
    IP=$(get_realip)
    isp=$(get_isp_name)

    cat > "$client_dir" <<EOF
vless://${UUID}@${CFIP}:${CFPORT}?encryption=none&security=tls&sni=${argo_domain}&fp=chrome&type=ws&host=${argo_domain}&path=%2Fvless-argo%3Fed%3D2560&allowInsecure=0#${isp}

vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${isp}\", \"add\": \"${CFIP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argo_domain}\", \"path\": \"/vless-argo?ed=2560\", \"tls\": \"tls\", \"sni\": \"${argo_domain}\", \"alpn\": \"\", \"fp\": \"chrome\", \"allowInsecure\": false }" | base64 -w0)
EOF

    base64 -w0 "$client_dir" > "${work_dir}/sub.txt"
    green "\nArgoDomain：${purple}${argo_domain}${re}\n"
    green "Argo隧道节点安装完成\n"
    while IFS= read -r line; do echo -e "${purple}$line"; done < "$client_dir"
    yellow "\n该安装模式未启用订阅服务，请直接复制以上节点链接\n"
}

install_argo_node() {
    clear
    manage_packages install jq unzip iptables openssl coreutils lsof
    install_xray "Argo隧道节点"
    filter_argo_node_config || return 1
    rm -f "${work_dir}/argo.log"

    if [ -x "$(command -v systemctl)" ]; then
        main_systemd_services
    elif [ -x "$(command -v rc-update)" ]; then
        alpine_openrc_services
        change_hosts
        rc-service xray restart
        rc-service tunnel restart
    else
        red "Unsupported init system"
        return 1
    fi

    sleep 3
    argodomain=$(get_argo_domain_only)
    if [ -z "$argodomain" ]; then
        red "未获取到Argo临时域名，可稍后通过Argo隧道管理重新获取\n"
        return 1
    fi
    show_argo_node_info "$argodomain"
    create_shortcut
}
# debian/ubuntu/centos 守护进程
main_systemd_services() {
    cat > /etc/systemd/system/xray.service << EOF
[Unit]
Description=Xray Service
Documentation=https://github.com/XTLS/Xray-core
After=network.target nss-lookup.target
Wants=network-online.target

[Service]
Type=simple
NoNewPrivileges=yes
ExecStart=$work_dir/xray -c $config_dir
Restart=on-failure
RestartPreventExitStatus=23

[Install]
WantedBy=multi-user.target
EOF

    cat > /etc/systemd/system/tunnel.service << EOF
[Unit]
Description=Cloudflare Tunnel
After=network.target

[Service]
Type=simple
NoNewPrivileges=yes
TimeoutStartSec=0
ExecStart=/etc/xray/argo tunnel --url http://localhost:$ARGO_PORT --no-autoupdate --edge-ip-version auto --protocol http2
StandardOutput=append:/etc/xray/argo.log
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target

EOF
    if [ -f /etc/centos-release ]; then
        yum install -y chrony
        systemctl start chronyd
        systemctl enable chronyd
        chronyc -a makestep
        yum update -y ca-certificates
        bash -c 'echo "0 0" > /proc/sys/net/ipv4/ping_group_range'
    fi
    bash -c 'echo "0 0" > /proc/sys/net/ipv4/ping_group_range'
    systemctl daemon-reload
    systemctl enable xray
    systemctl is-active --quiet xray || systemctl start xray
    systemctl enable tunnel
    systemctl start tunnel
    systemctl is-active --quiet tunnel || systemctl start xray
}
# 适配alpine 守护进程
alpine_openrc_services() {
    cat > /etc/init.d/xray << 'EOF'
#!/sbin/openrc-run

description="Xray service"
command="/etc/xray/xray"
command_args="-c /etc/xray/config.json"
command_background=true
pidfile="/var/run/xray.pid"
EOF

    cat > /etc/init.d/tunnel << 'EOF'
#!/sbin/openrc-run

description="Cloudflare Tunnel"
command="/bin/sh"
command_args="-c '/etc/xray/argo tunnel --url http://localhost:8080 --no-autoupdate --edge-ip-version auto --protocol http2 > /etc/xray/argo.log 2>&1'"
command_background=true
pidfile="/var/run/tunnel.pid"
EOF

    chmod +x /etc/init.d/xray
    chmod +x /etc/init.d/tunnel

    rc-update add xray default
    rc-update add tunnel default

}


get_info() {  
  clear
  IP=$(get_realip)

  isp=$(curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://api.ip.sb/geoip" | tr -d '\n' | awk -F\" '{c="";i="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="isp")i=$(x+2)};if(c&&i)print c"-"i}' | sed 's/ /_/g' || curl -sm 3 -H "User-Agent: Mozilla/5.0" "https://ipapi.co/json" | tr -d '\n' | awk -F\" '{c="";o="";for(x=1;x<=NF;x++){if($x=="country_code")c=$(x+2);if($x=="org")o=$(x+2)};if(c&&o)print c"-"o}' | sed 's/ /_/g' || echo "vps")

  if [ -f "${work_dir}/argo.log" ]; then
      for i in {1..5}; do
          green "第 $i 次尝试获取ArgoDoamin中..."
          argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' "${work_dir}/argo.log")
          [ -n "$argodomain" ] && break
          sleep 2
      done
  else
      restart_argo
      sleep 6
      argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' "${work_dir}/argo.log")
  fi

  green "\nArgoDomain：${red}$argodomain${green}\n"

  cat > ${work_dir}/url.txt <<EOF
vless://${UUID}@${IP}:${GRPC_PORT}??encryption=none&security=reality&sni=www.iij.ad.jp&fp=chrome&pbk=${public_key}&allowInsecure=0&type=grpc&authority=www.iij.ad.jp&serviceName=grpc&mode=gun#${isp}

vless://${UUID}@${IP}:${XHTTP_PORT}?encryption=none&security=reality&sni=www.nazhumi.com&fp=chrome&pbk=${public_key}&allowInsecure=0&type=xhttp&mode=auto#${isp}

vless://${UUID}@${CFIP}:${CFPORT}?encryption=none&security=tls&sni=${argodomain}&fp=chrome&type=ws&host=${argodomain}&path=%2Fvless-argo%3Fed%3D2560&allowInsecure=0#${isp}

vmess://$(echo "{ \"v\": \"2\", \"ps\": \"${isp}\", \"add\": \"${CFIP}\", \"port\": \"${CFPORT}\", \"id\": \"${UUID}\", \"aid\": \"0\", \"scy\": \"none\", \"net\": \"ws\", \"type\": \"none\", \"host\": \"${argodomain}\", \"path\": \"/vmess-argo?ed=2560\", \"tls\": \"tls\", \"sni\": \"${argodomain}\", \"alpn\": \"\", \"fp\": \"chrome\", \"allowInsecure\": false }" | base64 -w0)

EOF
echo ""
while IFS= read -r line; do echo -e "${purple}$line"; done < ${work_dir}/url.txt
base64 -w0 ${work_dir}/url.txt > ${work_dir}/sub.txt
yellow "\n温馨提醒：如果是NAT机,reality端口和订阅端口需使用可用端口范围内的端口,否则reality协议不通,无法订阅\n"
green "节点订阅链接：http://$IP:$PORT/$password\n\n订阅链接适用于V2rayN,Nekbox,karing,Sterisand,Loon,小火箭,圈X等\n"
green "订阅二维码"
$work_dir/qrencode "http://$IP:$PORT/$password"
echo ""
}

# 处理ubuntu系统中没有caddy源的问题
install_caddy () {
if [ -f /etc/os-release ] && (grep -q "Ubuntu" /etc/os-release || grep -q "Debian GNU/Linux 11" /etc/os-release); then
    purple "安装依赖中...\n"
    apt install -y debian-keyring debian-archive-keyring apt-transport-https
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | tee /etc/apt/trusted.gpg.d/caddy-stable.asc
    curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | tee /etc/apt/sources.list.d/caddy-stable.list
    rm /etc/apt/trusted.gpg.d/caddy-stable.asc /usr/share/keyrings/caddy-archive-keyring.gpg 2>/dev/null
    curl -fsSL https://dl.cloudsmith.io/public/caddy/stable/gpg.key | gpg --dearmor -o /usr/share/keyrings/caddy-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/caddy-archive-keyring.gpg] https://dl.cloudsmith.io/public/caddy/stable/deb/debian any-version main" | tee /etc/apt/sources.list.d/caddy-stable.list
    DEBIAN_FRONTEND=noninteractive apt update -y && manage_packages install caddy
else
    manage_packages install caddy 
fi
}

# caddy订阅配置
add_caddy_conf() {
[ -f /etc/caddy/Caddyfile ] && cp /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak > /dev/null 2>&1
rm -rf /etc/caddy/Caddyfile
    cat > /etc/caddy/Caddyfile << EOF
{
    auto_https off
    log {
        output file /var/log/caddy/caddy.log {
            roll_size 10MB
            roll_keep 10
            roll_keep_for 720h
        }
    }
}

:$PORT {
    handle /$password {
        root * /etc/xray
        try_files /sub.txt
        file_server browse
        header Content-Type "text/plain; charset=utf-8"
    }

    handle {
        respond "404 Not Found" 404
    }
}
EOF

/usr/bin/caddy validate --config /etc/caddy/Caddyfile > /dev/null 2>&1
chown caddy:caddy /var/log/caddy/caddy.log > /dev/null 2>&1
chmod 644 /var/log/caddy/caddy.log > /dev/null 2>&1

if [ $? -eq 0 ]; then
    if [ -f /etc/alpine-release ]; then
        rc-service caddy restart
    else
        systemctl daemon-reload
        systemctl restart caddy
    fi
else
    [ -f /etc/alpine-release ] && rc-service caddy restart > /dev/null 2>&1 || red "Caddy 配置文件验证失败，订阅功能可能无法使用，但不影响节点使用\nissues 反馈：https://github.com/eooce/xray-argo/issues\n"
fi
}


# 启动 xray
start_xray() {
if [ ${check_xray} -eq 1 ]; then
    yellow "\n正在启动 ${server_name} 服务\n" 
    if [ -f /etc/alpine-release ]; then
        rc-service xray start
    else
        systemctl daemon-reload
        systemctl start "${server_name}"
    fi
   if [ $? -eq 0 ]; then
       green "${server_name} 服务已成功启动\n"
   else
       red "${server_name} 服务启动失败\n"
   fi
elif [ ${check_xray} -eq 0 ]; then
    yellow "xray 正在运行\n"
    sleep 1
    menu
else
    yellow "xray 尚未安装!\n"
    sleep 1
    menu
fi
}

# 停止 xray
stop_xray() {
if [ ${check_xray} -eq 0 ]; then
   yellow "\n正在停止 ${server_name} 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service xray stop
    else
        systemctl stop "${server_name}"
    fi
   if [ $? -eq 0 ]; then
       green "${server_name} 服务已成功停止\n"
   else
       red "${server_name} 服务停止失败\n"
   fi

elif [ ${check_xray} -eq 1 ]; then
    yellow "xray 未运行\n"
    sleep 1
    menu
else
    yellow "xray 尚未安装！\n"
    sleep 1
    menu
fi
}

# 重启 xray
restart_xray() {
if [ ${check_xray} -eq 0 ]; then
   yellow "\n正在重启 ${server_name} 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service ${server_name} restart
    else
        systemctl daemon-reload
        systemctl restart "${server_name}"
    fi
    if [ $? -eq 0 ]; then
        green "${server_name} 服务已成功重启\n"
    else
        red "${server_name} 服务重启失败\n"
    fi
elif [ ${check_xray} -eq 1 ]; then
    yellow "xray 未运行\n"
    sleep 1
    menu
else
    yellow "xray 尚未安装！\n"
    sleep 1
    menu
fi
}

# 启动 argo
start_argo() {
if [ ${check_argo} -eq 1 ]; then
    yellow "\n正在启动 Argo 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service tunnel start
    else
        systemctl daemon-reload
        systemctl start tunnel
    fi
    if [ $? -eq 0 ]; then
        green "Argo 服务已成功重启\n"
    else
        red "Argo 服务重启失败\n"
    fi
elif [ ${check_argo} -eq 0 ]; then
    green "Argo 服务正在运行\n"
    sleep 1
    menu
else
    yellow "Argo 尚未安装！\n"
    sleep 1
    menu
fi
}

# 停止 argo
stop_argo() {
if [ ${check_argo} -eq 0 ]; then
    yellow "\n正在停止 Argo 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service stop start
    else
        systemctl daemon-reload
        systemctl stop tunnel
    fi
    if [ $? -eq 0 ]; then
        green "Argo 服务已成功停止\n"
    else
        red "Argo 服务停止失败\n"
    fi
elif [ ${check_argo} -eq 1 ]; then
    yellow "Argo 服务未运行\n"
    sleep 1
    menu
else
    yellow "Argo 尚未安装！\n"
    sleep 1
    menu
fi
}

# 重启 argo
restart_argo() {
if [ ${check_argo} -eq 0 ]; then
    yellow "\n正在重启 Argo 服务\n"
    rm /etc/xray/argo.log 2>/dev/null
    if [ -f /etc/alpine-release ]; then
        rc-service tunnel restart
    else
        systemctl daemon-reload
        systemctl restart tunnel
    fi
    if [ $? -eq 0 ]; then
        green "Argo 服务已成功重启\n"
    else
        red "Argo 服务重启失败\n"
    fi
elif [ ${check_argo} -eq 1 ]; then
    yellow "Argo 服务未运行\n"
    sleep 1
    menu
else
    yellow "Argo 尚未安装！\n"
    sleep 1
    menu
fi
}

# 启动 caddy
start_caddy() {
if command -v caddy &>/dev/null; then
    yellow "\n正在启动 caddy 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service caddy start
    else
        systemctl daemon-reload
        systemctl start caddy
    fi
    if [ $? -eq 0 ]; then
        green "caddy 服务已成功启动\n"
    else
        red "caddy 启动失败\n"
    fi
else
    yellow "caddy 尚未安装！\n"
    sleep 1
    menu
fi
}

# 重启 caddy
restart_caddy() {
if command -v caddy &>/dev/null; then
    yellow "\n正在重启 caddy 服务\n"
    if [ -f /etc/alpine-release ]; then
        rc-service caddy restart
    else
        systemctl restart caddy
    fi
    if [ $? -eq 0 ]; then
        green "caddy 服务已成功重启\n"
    else
        red "caddy 重启失败\n"
    fi
else
    yellow "caddy 尚未安装！\n"
    sleep 1
    menu
fi
}

# 卸载 xray
uninstall_xray() {
   reading "确定要卸载 xray-2go 吗? (y/n): " choice
   case "${choice}" in
       y|Y)
           yellow "正在卸载 xray"
           if [ -f /etc/alpine-release ]; then
                rc-service xray stop
                rc-service tunnel stop
                rm /etc/init.d/xray /etc/init.d/tunnel
                rc-update del xray default
                rc-update del tunnel default
           else
                # 停止 xray和 argo 服务
                systemctl stop "${server_name}"
                systemctl stop tunnel
                # 禁用 xray 服务
                systemctl disable "${server_name}"
                systemctl disable tunnel

                # 重新加载 systemd
                systemctl daemon-reload || true
            fi
           # 删除配置文件和日志
           rm -rf "${work_dir}" || true
	       rm -rf /etc/systemd/system/xray.service /etc/systemd/system/tunnel.service 2>/dev/null	
           
           # 卸载caddy
           reading "\n是否卸载 caddy？${green}(卸载请输入 ${yellow}y${re} ${green}回车将跳过卸载caddy) (y/n): ${re}" choice
            case "${choice}" in
                y|Y)
                    manage_packages uninstall caddy
                    ;;
                 *)
                    yellow "取消卸载caddy\n"
                    ;;
            esac

            green "\nXray_2go 卸载成功\n"
           ;;
       *)
           purple "已取消卸载操作\n"
           ;;
   esac
}

# 创建快捷指令
create_shortcut() {
  cat > "$work_dir/2go.sh" << EOF
#!/usr/bin/env bash

bash <(curl -Ls https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/ArgoSB/xray_2go.sh) \$1
EOF
  chmod +x "$work_dir/2go.sh"
  ln -sf "$work_dir/2go.sh" /usr/bin/2go
  if [ -s /usr/bin/2go ]; then
    green "\n快捷指令 2go 创建成功\n"
  else
    red "\n快捷指令创建失败\n"
  fi
}

# 适配alpine运行argo报错用户组和dns的问题
change_hosts() {
    sh -c 'echo "0 0" > /proc/sys/net/ipv4/ping_group_range'
    sed -i '1s/.*/127.0.0.1   localhost/' /etc/hosts
    sed -i '2s/.*/::1         localhost/' /etc/hosts
}

restart_installed_xray() {
    if [ -x "$(command -v systemctl)" ]; then
        systemctl daemon-reload
        systemctl restart xray
    elif [ -x "$(command -v rc-update)" ]; then
        rc-service xray restart
    fi
}

refresh_standalone_subscription() {
    base64 -w0 "$client_dir" > "${work_dir}/sub.txt"
    while IFS= read -r line; do yellow "$line"; done < "$client_dir"
}

update_standalone_uuid_links() {
    local new_uuid=$1
    local content vmess_urls vmess_url encoded_vmess decoded_vmess updated_vmess encoded_updated_vmess new_vmess_url

    sed -i -E "s#^(vless://)[^@]+@#\1${new_uuid}@#" "$client_dir"
    if grep -q '^vmess://' "$client_dir"; then
        content=$(cat "$client_dir")
        vmess_urls=$(grep -o 'vmess://[^[:space:]]*' "$client_dir")
        for vmess_url in $vmess_urls; do
            encoded_vmess="${vmess_url#vmess://}"
            decoded_vmess=$(echo "$encoded_vmess" | base64 -d 2>/dev/null)
            updated_vmess=$(echo "$decoded_vmess" | jq --arg new_uuid "$new_uuid" '.id = $new_uuid')
            encoded_updated_vmess=$(echo "$updated_vmess" | base64 | tr -d '\n')
            new_vmess_url="vmess://${encoded_updated_vmess}"
            content=$(echo "$content" | sed "s|$vmess_url|$new_vmess_url|")
        done
        echo "$content" > "$client_dir"
    fi
}

update_standalone_port_links() {
    local new_port=$1

    awk -v port="$new_port" '
        /^vless:\/\// {
            query_pos = index($0, "?")
            if (query_pos > 0) {
                address = substr($0, 1, query_pos - 1)
                query = substr($0, query_pos)
                sub(/:[0-9]+$/, ":" port, address)
                print address query
            } else {
                print
            }
            next
        }
        { print }
    ' "$client_dir" > "${client_dir}.tmp" && mv "${client_dir}.tmp" "$client_dir"
}

change_single_node_config() {
    local node_mode new_uuid new_port new_sni
    node_mode=$(cat "${work_dir}/install-mode" 2>/dev/null)

    clear
    echo ""
    green "1. 修改UUID"
    skyblue "------------"
    if [ "$node_mode" != "argo" ]; then
        green "2. 修改节点端口"
        skyblue "------------"
        green "3. 修改Reality伪装域名"
        skyblue "------------"
    fi
    purple "${red}0. 返回主菜单"
    skyblue "------------"
    reading "请输入选择: " choice

    case "${choice}" in
        1)
            reading "\n请输入新的UUID: " new_uuid
            [ -z "$new_uuid" ] && new_uuid=$(cat /proc/sys/kernel/random/uuid)
            until [[ "$new_uuid" =~ ^[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}$ ]]; do
                red "UUID格式不正确"
                reading "请重新输入UUID: " new_uuid
            done
            jq --arg new_uuid "$new_uuid" '.inbounds[].settings.clients[].id = $new_uuid' "$config_dir" > "${config_dir}.tmp" && mv "${config_dir}.tmp" "$config_dir" || return 1
            update_standalone_uuid_links "$new_uuid"
            restart_installed_xray
            refresh_standalone_subscription
            green "\nUUID已修改为：${purple}${new_uuid}${re}\n"
            ;;
        2)
            if [ "$node_mode" == "argo" ]; then
                yellow "\nArgo安装模式使用Cloudflare端口，请在Argo隧道管理中处理域名\n"
            else
                reading "\n请输入新的节点端口 (回车使用随机端口): " new_port
                [ -z "$new_port" ] && new_port=$(shuf -i 2000-65000 -n 1)
                while true; do
                    if [[ ! "$new_port" =~ ^[0-9]+$ ]] || [ "$new_port" -lt 1 ] || [ "$new_port" -gt 65535 ]; then
                        red "端口必须是1-65535"
                        reading "请重新输入节点端口: " new_port
                    elif [ -n "$(lsof -iTCP:"$new_port" -sTCP:LISTEN 2>/dev/null)" ]; then
                        red "${new_port}端口已被占用，请更换端口"
                        reading "请重新输入节点端口: " new_port
                    else
                        break
                    fi
                done
                jq --argjson new_port "$new_port" '.inbounds[0].port = $new_port' "$config_dir" > "${config_dir}.tmp" && mv "${config_dir}.tmp" "$config_dir" || return 1
                update_standalone_port_links "$new_port"
                restart_installed_xray
                refresh_standalone_subscription
                green "\n节点端口已修改为：${purple}$new_port${re}\n"
            fi
            ;;
        3)
            if [ "$node_mode" == "argo" ]; then
                yellow "\nArgo安装模式请使用Argo隧道管理修改域名\n"
            else
                green "\n1. bgk.jp\n\n2. www.joom.com\n\n3. www.stengg.com\n\n4. www.nazhumi.com\n"
                reading "\n请输入新的Reality伪装域名(可自定义输入,回车使用默认1): " new_sni
                case "$new_sni" in
                    ""|1) new_sni="bgk.jp" ;;
                    2) new_sni="www.joom.com" ;;
                    3) new_sni="www.stengg.com" ;;
                    4) new_sni="www.nazhumi.com" ;;
                esac
                jq --arg new_sni "$new_sni" '.inbounds[0].streamSettings.realitySettings.dest = ($new_sni + ":443") | .inbounds[0].streamSettings.realitySettings.target = ($new_sni + ":443") | .inbounds[0].streamSettings.realitySettings.serverNames = [$new_sni]' "$config_dir" > "${config_dir}.tmp" && mv "${config_dir}.tmp" "$config_dir" || return 1
                sed -i -E "s#([?&])sni=[^&]*#\1sni=$new_sni#" "$client_dir"
                grep -q 'authority=' "$client_dir" && sed -i -E "s#([?&])authority=[^&]*#\1authority=$new_sni#" "$client_dir"
                restart_installed_xray
                refresh_standalone_subscription
                green "\nReality SNI已修改为：${purple}$new_sni${re}\n"
            fi
            ;;
        0) return 0 ;;
        *) red "无效的选项！" ;;
    esac
}

# 变更配置
change_config() {
clear
echo ""
green "1. 修改UUID"
skyblue "------------"
green "2. 修改grpc-reality端口"
skyblue "------------"
green "3. 修改xhttp-reality端口"
skyblue "------------"
green "4. 修改reality节点伪装域名"
skyblue "------------"
purple "${red}0. 返回主菜单"
skyblue "------------"
reading "请输入选择: " choice
case "${choice}" in
    1)
        reading "\n请输入新的UUID: " new_uuid
        [ -z "$new_uuid" ] && new_uuid=$(cat /proc/sys/kernel/random/uuid) && green "\n生成的UUID为：$new_uuid"
        sed -i "s/[a-fA-F0-9]\{8\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{12\}/$new_uuid/g" $config_dir
        restart_xray
        sed -i "s/[a-fA-F0-9]\{8\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{4\}-[a-fA-F0-9]\{12\}/$new_uuid/g" $client_dir
        content=$(cat "$client_dir")
        vmess_urls=$(grep -o 'vmess://[^ ]*' "$client_dir")
        vmess_prefix="vmess://"
        for vmess_url in $vmess_urls; do
            encoded_vmess="${vmess_url#"$vmess_prefix"}"
            decoded_vmess=$(echo "$encoded_vmess" | base64 --decode)
            updated_vmess=$(echo "$decoded_vmess" | jq --arg new_uuid "$new_uuid" '.id = $new_uuid | .allowInsecure = false')
            encoded_updated_vmess=$(echo "$updated_vmess" | base64 | tr -d '\n')
            new_vmess_url="$vmess_prefix$encoded_updated_vmess"
            content=$(echo "$content" | sed "s|$vmess_url|$new_vmess_url|")
        done
        echo "$content" > "$client_dir"
        base64 -w0 $client_dir > /etc/xray/sub.txt
        while IFS= read -r line; do yellow "$line"; done < $client_dir
        green "\nUUID已修改为：${purple}${new_uuid}${re} ${green}请更新订阅或手动更改所有节点的UUID${re}\n"
        ;;
    2)
        reading "\n请输入grpc-reality端口 (回车跳过将使用随机端口): " new_port
        [ -z "$new_port" ] && new_port=$(shuf -i 2000-65000 -n 1)
        until [[ -z $(lsof -iTCP:$new_port -sTCP:LISTEN 2>/dev/null) ]]; do
            if [[ -n $(lsof -iTCP:$new_port -sTCP:LISTEN 2>/dev/null) ]]; then
                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                reading "请输入新的订阅端口(1-65535):" new_port
                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
            fi
        done
        sed -i "41s/\"port\":\s*[0-9]\+/\"port\": $new_port/" /etc/xray/config.json
        restart_xray
        sed -i '1s/\(vless:\/\/[^@]*@[^:]*:\)[0-9]\{1,\}/\1'"$new_port"'/' $client_dir
        base64 -w0 $client_dir > /etc/xray/sub.txt
        while IFS= read -r line; do yellow "$line"; done < ${work_dir}/url.txt
        green "\nGRPC-reality端口已修改成：${purple}$new_port${re} ${green}请更新订阅或手动更改grpc-reality节点端口${re}\n"
        ;;
    3)
        reading "\n请输入xhttp-reality端口 (回车跳过将使用随机端口): " new_port
        [ -z "$new_port" ] && new_port=$(shuf -i 2000-65000 -n 1)
        until [[ -z $(lsof -iTCP:$new_port -sTCP:LISTEN 2>/dev/null) ]]; do
            if [[ -n $(lsof -iTCP:$new_port -sTCP:LISTEN 2>/dev/null) ]]; then
                echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                reading "请输入新的订阅端口(1-65535):" new_port
                [[ -z $new_port ]] && new_port=$(shuf -i 2000-65000 -n 1)
            fi
        done
        sed -i "35s/\"port\":\s*[0-9]\+/\"port\": $new_port/" /etc/xray/config.json
        restart_xray
        sed -i '3s/\(vless:\/\/[^@]*@[^:]*:\)[0-9]\{1,\}/\1'"$new_port"'/' $client_dir
        base64 -w0 $client_dir > /etc/xray/sub.txt
        while IFS= read -r line; do yellow "$line"; done < ${work_dir}/url.txt
        green "\nxhttp-reality端口已修改成：${purple}$new_port${re} ${green}请更新订阅或手动更改xhttp-reality节点端口${re}\n"
        ;;
    4)  
        clear
        green "\n1. bgk.jp\n\n2. www.joom.com\n\n3. www.stengg.com\n\n4. www.nazhumi.com\n"  
        reading "\n请输入新的Reality伪装域名(可自定义输入,回车留空将使用默认1): " new_sni
            if [ -z "$new_sni" ]; then    
                new_sni="bgk.jp"
            elif [[ "$new_sni" == "1" ]]; then
                new_sni="bgk.jp"
            elif [[ "$new_sni" == "2" ]]; then
                new_sni="www.joom.com"
            elif [[ "$new_sni" == "3" ]]; then
                new_sni="www.stengg.com"
            elif [[ "$new_sni" == "4" ]]; then
                new_sni="www.nazhumi.com"
            else
                new_sni="$new_sni"
            fi
            jq --arg new_sni "$new_sni" '.inbounds[5].streamSettings.realitySettings.dest = ($new_sni + ":443") | .inbounds[5].streamSettings.realitySettings.serverNames = [$new_sni]' /etc/xray/config.json > /etc/xray/config.json.tmp && mv /etc/xray/config.json.tmp /etc/xray/config.json
            restart_xray 
            sed -i "1s/\(vless:\/\/[^\?]*\?\([^\&]*\&\)*sni=\)[^&]*/\1$new_sni/" $client_dir
            sed -i "1s/\(vless:\/\/[^\?]*\?\([^\&]*\&\)*authority=\)[^&]*/\1$new_sni/" $client_dir
            base64 -w0 $client_dir > /etc/xray/sub.txt
            while IFS= read -r line; do yellow "$line"; done < ${work_dir}/url.txt
            echo ""
            green "\nReality sni已修改为：${purple}${new_sni}${re} ${green}请更新订阅或手动更改reality节点的sni域名${re}\n"
        ;; 
    0)  menu ;;
    *)  read "无效的选项！" ;; 
esac
}

disable_open_sub() {
if [ ${check_xray} -eq 0 ]; then
    clear
    echo ""
    green "1. 关闭节点订阅"
    skyblue "------------"
    green "2. 开启节点订阅"
    skyblue "------------"
    green "3. 更换订阅端口"
    skyblue "------------"
    purple "4. 返回主菜单"
    skyblue "------------"
    reading "请输入选择: " choice
    case "${choice}" in
        1)
            if command -v caddy &>/dev/null; then
                if [ -f /etc/alpine-release ]; then
                    rc-service caddy status | grep -q "started" && rc-service caddy stop || red "caddy not running"
                else 
                    [ "$(systemctl is-active caddy)" = "active" ] && systemctl stop caddy || red "ngixn not running"
                fi
            else
                yellow "caddy is not installed"
            fi

            green "\n已关闭节点订阅\n"     
            ;; 
        2)
            green "\n已开启节点订阅\n"
            server_ip=$(get_realip)
            password=$(tr -dc A-Za-z < /dev/urandom | head -c 32) 
            sed -i "s/\/[a-zA-Z0-9]\+/\/$password/g" /etc/caddy/Caddyfile
	        sub_port=$(port=$(grep -oP ':\K[0-9]+' /etc/caddy/Caddyfile); if [ "$port" -eq 80 ]; then echo ""; else echo "$port"; fi)
            start_caddy
            (port=$(grep -oP ':\K[0-9]+' /etc/caddy/Caddyfile); if [ "$port" -eq 80 ]; then echo ""; else green "订阅端口：$port"; fi); link=$(if [ -z "$sub_port" ]; then echo "http://$server_ip/$password"; else echo "http://$server_ip:$sub_port/$password"; fi); green "\n新的节点订阅链接：$link\n"
            ;; 

        3)
            reading "请输入新的订阅端口(1-65535):" sub_port
            [ -z "$sub_port" ] && sub_port=$(shuf -i 2000-65000 -n 1)
            until [[ -z $(lsof -iTCP:$sub_port -sTCP:LISTEN 2>/dev/null) ]]; do
                if [[ -n $(lsof -iTCP:$sub_port -sTCP:LISTEN 2>/dev/null) ]]; then
                    echo -e "${red}${new_port}端口已经被其他程序占用，请更换端口重试${re}"
                    reading "请输入新的订阅端口(1-65535):" sub_port
                    [[ -z $sub_port ]] && sub_port=$(shuf -i 2000-65000 -n 1)
                fi
            done
            sed -i "s/:[0-9]\+/:$sub_port/g" /etc/caddy/Caddyfile
            path=$(sed -n 's/.*handle \/\([^ ]*\).*/\1/p' /etc/caddy/Caddyfile)
            server_ip=$(get_realip)
            restart_caddy
            green "\n订阅端口更换成功\n"
            green "新的订阅链接为：http://$server_ip:$sub_port/$path\n"
            ;; 
        4)  menu ;; 
        *)  red "无效的选项！" ;;
    esac
else
    yellow "xray—2go 尚未安装！"
    sleep 1
    menu
fi
}

# xray 管理
manage_xray() {
    green "1. 启动xray服务"
    skyblue "-------------------"
    green "2. 停止xray服务"
    skyblue "-------------------"
    green "3. 重启xray服务"
    skyblue "-------------------"
    purple "4. 返回主菜单"
    skyblue "------------"
    reading "\n请输入选择: " choice
    case "${choice}" in
        1) start_xray ;;  
        2) stop_xray ;;
        3) restart_xray ;;
        4) menu ;;
        *) red "无效的选项！" ;;
    esac
}

# Argo 管理
manage_argo() {
if [ ${check_argo} -eq 2 ]; then
    yellow "Argo 尚未安装！"
    sleep 1
    menu
else
    clear
    echo ""
    green "1. 启动Argo服务"
    skyblue "------------"
    green "2. 停止Argo服务"
    skyblue "------------"
    green "3. 添加Argo固定隧道"
    skyblue "----------------"
    green "4. 切换回Argo临时隧道"
    skyblue "------------------"
    green "5. 重新获取Argo临时域名"
    skyblue "-------------------"
    purple "6. 返回主菜单"
    skyblue "-----------"
    reading "\n请输入选择: " choice
    case "${choice}" in
        1)  start_argo ;;
        2)  stop_argo ;; 
        3)
            clear
            yellow "\n固定隧道可为json或token，固定隧道端口为8080，自行在cf后台设置\n\njson在f佬维护的站点里获取，获取地址：${purple}https://fscarmen.cloudflare.now.cc${re}\n"
            reading "\n请输入你的argo域名: " argo_domain
            green "你的Argo域名为：$argo_domain"
            ArgoDomain=$argo_domain
            reading "\n请输入你的argo密钥(token或json): " argo_auth
            if [[ $argo_auth =~ TunnelSecret ]]; then
                echo $argo_auth > ${work_dir}/tunnel.json
                cat > ${work_dir}/tunnel.yml << EOF
tunnel: $(cut -d\" -f12 <<< "$argo_auth")
credentials-file: ${work_dir}/tunnel.json
protocol: http2
                                           
ingress:
  - hostname: $ArgoDomain
    service: http://localhost:8080
    originRequest:
      noTLSVerify: true
  - service: http_status:404
EOF
                if [ -f /etc/alpine-release ]; then
                    sed -i '/^command_args=/c\command_args="-c '\''/etc/xray/argo tunnel --edge-ip-version auto --config /etc/xray/tunnel.yml run 2>&1'\''"' /etc/init.d/tunnel
                else
                    sed -i '/^ExecStart=/c ExecStart=/bin/sh -c "/etc/xray/argo tunnel --edge-ip-version auto --config /etc/xray/tunnel.yml run 2>&1"' /etc/systemd/system/tunnel.service
                fi
                restart_argo
                change_argo_domain
            elif [[ $argo_auth =~ ^[A-Z0-9a-z=]{120,250}$ ]]; then
                if [ -f /etc/alpine-release ]; then
                    sed -i "/^command_args=/c\command_args=\"-c '/etc/xray/argo tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token $argo_auth 2>&1'\"" /etc/init.d/tunnel
                else

                    sed -i '/^ExecStart=/c ExecStart=/bin/sh -c "/etc/xray/argo tunnel --edge-ip-version auto --no-autoupdate --protocol http2 run --token '$argo_auth' 2>&1"' /etc/systemd/system/tunnel.service
                fi
                restart_argo
                change_argo_domain
            else
                yellow "你输入的argo域名或token不匹配，请重新输入"
                manage_argo            
            fi
            ;; 
        4)
            clear
            if [ -f /etc/alpine-release ]; then
                alpine_openrc_services
            else
                main_systemd_services
            fi
            get_quick_tunnel
            change_argo_domain 
            ;; 

        5)  
            if [ -f /etc/alpine-release ]; then
                if grep -Fq -- '--url http://localhost:8080' /etc/init.d/tunnel; then
                    get_quick_tunnel
                    change_argo_domain 
                else
                    yellow "当前使用固定隧道，无法获取临时隧道"
                    sleep 2
                    menu
                fi
            else
                if grep -q 'ExecStart=.*--url http://localhost:8080' /etc/systemd/system/tunnel.service; then
                    get_quick_tunnel
                    change_argo_domain 
                else
                    yellow "当前使用固定隧道，无法获取临时隧道"
                    sleep 2
                    menu
                fi
            fi 
            ;; 
        6)  menu ;; 
        *)  red "无效的选项！" ;;
    esac
fi
}

# 获取argo临时隧道
get_quick_tunnel() {
restart_argo
yellow "获取临时argo域名中，请稍等...\n"
sleep 3
if [ -f /etc/xray/argo.log ]; then
  for i in {1..5}; do
      get_argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' /etc/xray/argo.log)
      [ -n "$get_argodomain" ] && break
      sleep 2
  done
else
  restart_argo
  sleep 6
  get_argodomain=$(sed -n 's|.*https://\([^/]*trycloudflare\.com\).*|\1|p' /etc/xray/argo.log)
fi
green "ArgoDomain：${purple}$get_argodomain${re}\n"
ArgoDomain=$get_argodomain
}

# 更新Argo域名到订阅
change_argo_domain() {
    awk -v domain="$ArgoDomain" '
        /^vless:\/\// && /type=ws/ {
            gsub(/sni=[^&]+/, "sni=" domain)
            gsub(/host=[^&]+/, "host=" domain)
            print
            next
        }
        { print }
    ' "$client_dir" > "${client_dir}.tmp" && mv "${client_dir}.tmp" "$client_dir"
    content=$(cat "$client_dir")
    vmess_urls=$(grep -o 'vmess://[^ ]*' "$client_dir")
    vmess_prefix="vmess://"
    for vmess_url in $vmess_urls; do
        encoded_vmess="${vmess_url#"$vmess_prefix"}"
        decoded_vmess=$(echo "$encoded_vmess" | base64 --decode)
        updated_vmess=$(echo "$decoded_vmess" | jq --arg new_domain "$ArgoDomain" '.host = $new_domain | .sni = $new_domain | .allowInsecure = false')
        encoded_updated_vmess=$(echo "$updated_vmess" | base64 | tr -d '\n')
        new_vmess_url="$vmess_prefix$encoded_updated_vmess"
        content=$(echo "$content" | sed "s|$vmess_url|$new_vmess_url|")
    done
    echo "$content" > "$client_dir"
    base64 -w0 ${work_dir}/url.txt > ${work_dir}/sub.txt

    while IFS= read -r line; do echo -e "${purple}$line"; done < "$client_dir"
    
    green "\n节点已更新,更新订阅或手动复制以上节点\n"
}

# 查看节点信息和订阅链接
check_nodes() {
if [ ${check_xray} -eq 0 ]; then
    while IFS= read -r line; do purple "${purple}$line"; done < ${work_dir}/url.txt
    server_ip=$(get_realip)
    if [ -f /etc/caddy/Caddyfile ]; then
        sub_port=$(sed -n 's/.*:\([0-9]\+\).*/\1/p' /etc/caddy/Caddyfile)
        lujing=$(sed -n 's/.*handle \/\([a-zA-Z0-9]\+\).*/\1/p' /etc/caddy/Caddyfile)
        green "\n\n节点订阅链接：http://$server_ip:$sub_port/$lujing\n"
    else
        green "\n\n当前安装模式未启用节点订阅\n"
    fi
else 
    yellow "Xray-2go 尚未安装或未运行,请先安装或启动Xray-2go"
    sleep 1
    menu
fi
}

# 捕获 Ctrl+C 信号
trap 'red "已取消操作"; exit' INT

# 主菜单
menu() {
while true; do
   check_xray &>/dev/null; check_xray=$?
   check_caddy &>/dev/null; check_caddy=$?
   check_argo &>/dev/null; check_argo=$?
   check_xray_status=$(check_xray) > /dev/null 2>&1
   check_caddy_status=$(check_caddy) > /dev/null 2>&1
   check_argo_status=$(check_argo) > /dev/null 2>&1
   clear
   echo ""
   green "===== Xray-2go一键安装脚本 ====="
   purple "-------- ws01 v20261101 --------\n"
   red " Xray 状态: ${check_xray_status}"
   red " Argo 状态: ${check_argo_status}"   
   red "Caddy 状态: ${check_caddy_status}"
   echo "=============================="
   green "1. 安装Xray-2go【默认四协议】"
   green "2. 安装grpc-reality节点"
   green "3. 安装xhttp-reality节点"
   green "4. 安装Argo隧道两节点"
   yellow "5. 安装reality节点【与默认四协议暂不兼容】"
   purple "6. 卸载Xray-2go"
   green "7. Xray-2go管理"
   green "8. Argo隧道管理"
   green "9. 查看节点信息"
   green "10. 修改节点配置"
   green "11. 管理节点订阅"
   red "12. ws01综合工具箱"
   red "13. ssh综合工具箱-eooce"
   red "14. 安装singbox四合一-eooce"
   echo  "=============================="
   purple "0. 退出脚本"
   reading "请输入选择(0-13) [默认1]: " choice
   choice=${choice:-1}
   echo ""
   case "${choice}" in
        1)  
            if [ ${check_xray} -eq 0 ]; then
                yellow "Xray-2go 已经安装！"
            else
                install_caddy
                manage_packages install jq unzip iptables openssl coreutils lsof
                install_xray
                echo "default" > "${work_dir}/install-mode"

                if [ -x "$(command -v systemctl)" ]; then
                    main_systemd_services
                elif [ -x "$(command -v rc-update)" ]; then
                    alpine_openrc_services
                    change_hosts
                    rc-service xray restart
                    rc-service tunnel restart
                else
                    echo "Unsupported init system"
                    exit 1 
                fi

                sleep 3
                get_info
                add_caddy_conf
                create_shortcut
            fi
           ;;
        2)
            if [ -f "$config_dir" ]; then
                yellow "Xray-2go 已经安装，请先卸载后再安装独立节点"
            else
                install_single_xray_node "grpc-reality"
            fi
            ;;
        3)
            if [ -f "$config_dir" ]; then
                yellow "Xray-2go 已经安装，请先卸载后再安装独立节点"
            else
                install_single_xray_node "xhttp-reality"
            fi
            ;;
        4)
            if [ -f "$config_dir" ]; then
                yellow "Xray-2go 已经安装，请先卸载后再安装Argo隧道两节点"
            else
                install_argo_node
            fi
            ;;
        5)
            if [ -f "$config_dir" ]; then
                yellow "Xray-2go 已经安装，请先卸载后再安装独立节点"
            else
                install_single_xray_node "reality"
            fi
            ;;
        6) uninstall_xray ;;
        7) manage_xray ;;
        8)
            if [ -f "${work_dir}/install-mode" ] && grep -qE '^(grpc-reality|xhttp-reality|reality)$' "${work_dir}/install-mode"; then
                yellow "当前安装模式未包含Argo隧道"
            else
                manage_argo
            fi
            ;;
        9) check_nodes ;;
        10)
            if [ -f "${work_dir}/install-mode" ] && [ "$(cat "${work_dir}/install-mode" 2>/dev/null)" != "default" ]; then
                change_single_node_config
            else
                change_config
            fi
            ;;
        11)
            if [ -f "${work_dir}/install-mode" ] && [ "$(cat "${work_dir}/install-mode" 2>/dev/null)" != "default" ]; then
                yellow "当前安装模式未启用节点订阅"
            else
                disable_open_sub
            fi
            ;;
        12) clear && curl -fsSL wget https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/toolbox.sh -O toolbox.sh && chmod +x toolbox.sh && ./toolbox.sh ;; 
        13) clear && curl -fsSL https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh -o ssh_tool.sh && chmod +x ssh_tool.sh && ./ssh_tool.sh ;; 
        14) clear && bash <(curl -Ls https://raw.githubusercontent.com/eooce/sing-box/main/sing-box.sh) ;;
        0) exit 0 ;;
        *) red "无效的选项，请输入 0 到 13" ;; 
   esac
   read -n 1 -s -r -p $'\033[1;91m按任意键继续...\033[0m'
done
}
menu
