cat > /tmp/install.sh <<'EOF'
#!/bin/sh

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
PLAIN='\033[0m'

clear

printf "${GREEN}${BOLD}
     🚀 NAT 小鸡 VLESS-REALITY 一键部署脚本
${PLAIN}\n\n"


# 输入 SSH 端口
printf "${YELLOW}请输入 SSH 端口 (内网/公网，例如 22/43694): ${PLAIN}"
read ssh_input

ssh_internal=$(echo "$ssh_input" | cut -d'/' -f1)
ssh_external=$(echo "$ssh_input" | cut -d'/' -f2)


# 输入节点端口
printf "${YELLOW}请输入节点端口 (内网/公网，例如 20000/32090): ${PLAIN}"
read node_input

node_internal=$(echo "$node_input" | cut -d'/' -f1)
node_external=$(echo "$node_input" | cut -d'/' -f2)


# 选择 SNI
echo ""
printf "${YELLOW}请选择 SNI 伪装域名:${PLAIN}\n"
echo "1) www.yahoo.com"
echo "2) www.icloud.com"
echo "3) 自定义"

printf "选择 [1-3] (默认1): "
read sni_choice


case "$sni_choice" in
2)
SNI="www.icloud.com"
;;
3)
printf "请输入SNI:"
read custom_sni

if [ -n "$custom_sni" ]; then
SNI="$custom_sni"
else
SNI="www.yahoo.com"
fi
;;
*)
SNI="www.yahoo.com"
;;
esac


echo ""

printf "${BLUE}[1/6] 清理旧环境...${PLAIN}\n"

pkill xray 2>/dev/null

rm -rf \
/usr/local/bin/xray \
/etc/xray \
/usr/local/bin/vless \
/tmp/xray.zip


printf "${BLUE}[2/6] 安装依赖和Xray...${PLAIN}\n"

apk update

apk add --no-cache \
curl \
wget \
unzip \
openssl


mkdir -p /usr/local/bin/xray
mkdir -p /etc/xray


wget -q \
-O /tmp/xray.zip \
https://github.com/XTLS/Xray-core/releases/latest/download/Xray-linux-64.zip


unzip -o /tmp/xray.zip \
-d /usr/local/bin/xray >/dev/null


rm -f /tmp/xray.zip


printf "${BLUE}[3/6] 获取公网IP...${PLAIN}\n"

IP=$(curl -s4 icanhazip.com)

if [ -z "$IP" ]; then
IP=$(curl -s4 ip.sb)
fi


printf "${BLUE}[4/6] 生成UUID和REALITY密钥...${PLAIN}\n"


UUID=$(/usr/local/bin/xray/xray uuid)

KEYPAIR=$(/usr/local/bin/xray/xray x25519)


PRIVATE_KEY=$(echo "$KEYPAIR" | grep Private | awk '{print $NF}')

PUBLIC_KEY=$(echo "$KEYPAIR" | grep Public | awk '{print $NF}')

SHORT_ID=$(openssl rand -hex 4)


printf "${BLUE}[5/6] 写入Xray配置...${PLAIN}\n"


cat > /etc/xray/config.json <<EOF2
{
"log":{
"loglevel":"warning"
},

"inbounds":[
{
"listen":"0.0.0.0",
"port":$node_internal,

"protocol":"vless",

"settings":{
"clients":[
{
"id":"$UUID",
"flow":"xtls-rprx-vision"
}
],
"decryption":"none"
},

"streamSettings":{
"network":"tcp",

"security":"reality",

"realitySettings":{
"show":false,

"dest":"$SNI:443",

"xver":0,

"serverNames":[
"$SNI"
],

"privateKey":"$PRIVATE_KEY",

"shortIds":[
"$SHORT_ID"
]
}
}
}
],

"outbounds":[
{
"protocol":"freedom"
}
]
}
EOF2


printf "${BLUE}[6/6] 启动Xray并生成快捷命令...${PLAIN}\n"


/usr/local/bin/xray/xray run \
-config /etc/xray/config.json \
> /dev/null 2>&1 &


mkdir -p /etc/local.d


cat > /etc/local.d/xray.start <<EOF3
#!/bin/sh

pkill xray

nohup /usr/local/bin/xray/xray run \
-config /etc/xray/config.json \
>/dev/null 2>&1 &

EOF3


chmod +x /etc/local.d/xray.start


rc-update add local default 2>/dev/null


cat > /usr/local/bin/vless <<EOF4
#!/bin/sh


echo ""
echo "========== VLESS REALITY 信息 =========="
echo "IP:" "$IP"

echo "端口:" "$node_external"

echo "UUID:" "$UUID"

echo "Public Key:" "$PUBLIC_KEY"

echo "Short ID:" "$SHORT_ID"

echo "SNI:" "$SNI"

echo "VLESS链接:"

echo "vless://$UUID@$IP:$node_external?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#ws01%20vless"

echo ""
EOF4


chmod +x /usr/local/bin/vless


cat > /usr/local/bin/vless-uninstall <<EOF5
#!/bin/sh

printf "\033[0;33m即将卸载 VLESS-REALITY 节点，是否继续？[y/N]: \033[0m"
read confirm

case "\$confirm" in
y|Y|yes|YES)
;;
*)
echo "已取消卸载"
exit 0
;;
esac

echo ""
echo "[1/3] 停止 Xray 服务..."
pkill xray 2>/dev/null

echo "[2/3] 删除开机自启配置..."
rm -f /etc/local.d/xray.start

echo "[3/3] 删除程序文件和配置..."
rm -rf \
/usr/local/bin/xray \
/etc/xray \
/usr/local/bin/vless \
/usr/local/bin/vless-uninstall

echo ""
echo "\033[0;32m================================\033[0m"
echo "卸载完成，所有相关文件已清除"
echo "\033[0;32m================================\033[0m"
EOF5


chmod +x /usr/local/bin/vless-uninstall


echo ""
echo "========== VLESS REALITY 信息 =========="
echo "IP:" "$IP"

echo "端口:" "$node_external"

echo "UUID:" "$UUID"

echo "Public Key:" "$PUBLIC_KEY"

echo "Short ID:" "$SHORT_ID"

echo "SNI:" "$SNI"

echo ""



echo ""
echo "${GREEN}================================${PLAIN}"
echo "安装完成！"

echo "VLESS链接:"
echo "vless://$UUID@$IP:$node_external?encryption=none&flow=xtls-rprx-vision&security=reality&sni=$SNI&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp#ws01%20vless"

echo ""

echo "以后可随时输入 vless 命令重新查看以上信息"
echo "如需卸载，请输入 vless-uninstall"
echo "${GREEN}================================${PLAIN}"

EOF


chmod +x /tmp/install.sh

/tmp/install.sh
