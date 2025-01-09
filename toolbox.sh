#!/bin/bash

# 设置颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 通用返回函数
back_to_menu() {
    echo
    read -p "按回车键返回..."
    $1
}

# 常用命令函数
common_commands() {
    clear
    echo -e "${GREEN}=== 常用命令 ===${NC}"
    echo "1. 系统信息查询"
    echo "2. 一键升级"
    echo "3. X-UI-F大"
    echo "4. X-UI-F大独立版"
    echo "5. F大warp添加IPV4"
    echo "6. 安装hy2"
    echo "7. 修改vps密码"
    echo "8. 更新系统"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-8): " choice
    
    case $choice in
        1)
            echo "查询系统信息..."
            uname -a
            lsb_release -a
            df -h
            free -m
            back_to_menu common_commands
            ;;
        2)
            echo "执行一键升级..."
            apt update -y && apt install curl wget -y && apt update && apt install curl wget
            back_to_menu common_commands 
            ;;
        3)
            echo "执行X-UI-F大安装..."
            bash <(curl -Ls https://raw.githubusercontent.com/wszx123/x-ui-FranzKafkaYu/master/install.sh)
            back_to_menu common_commands 
            ;;
        4)
            echo "执行X-UI-F大独立版安装..."
            bash <(curl -Ls https://raw.githubusercontent.com/wszx123/x-ui-FranzKafkaYu/master/install.sh) 0.3.4.4
            back_to_menu common_commands 
            ;;
        5)
            echo "执行F大warp添加IPV4..."
            wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
            back_to_menu common_commands 
            ;;
        6)
            echo "安装hy2..."
            wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
            back_to_menu common_commands 
            ;;
        7)
            echo "修改VPS密码..."
            passwd
            back_to_menu common_commands 
            ;;
        8)
            echo "更新系统..."
            apt update -y && apt upgrade -y && apt install -y curl wget sudo socat
            back_to_menu common_commands 
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; common_commands ;;
    esac
}

# VPS安装工具函数
vps_install() {
    clear
    echo -e "${GREEN}=== VPS 安装工具 ===${NC}"
    for i in {1..20}; do
        echo "$i. VPS 安装工具$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-20): " subchoice
    
    case $subchoice in
        [1-9]|1[0-9]|20) echo "执行VPS安装工具$subchoice" ; back_to_menu vps_install ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; vps_install ;;
    esac
}

# 抢鸡工具函数
vps_grab() {
    clear
    echo -e "${GREEN}=== 抢鸡工具 ===${NC}"
    for i in {1..10}; do
        echo "$i. 抢鸡工具$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        [1-9]|10) echo "执行抢鸡工具$subchoice" ; back_to_menu vps_grab ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; vps_grab ;;
    esac
}

# 重装系统函数
system_reinstall() {
    clear
    echo -e "${GREEN}=== 重装系统 ===${NC}"
    echo "1. 命令1-必须"
    echo "2. 命令2-安装Debian 12"
    echo "3. 命令3-安装Ubuntu 22.04"
    echo "4. 命令4-安装alpine"
    echo "5. 一键重装【慎用】"
    echo "6. 重启"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-6): " subchoice
    
    case $subchoice in
        1)
            echo "执行命令1-必须..."
            wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
            back_to_menu system_reinstall
            ;;
        2)
            echo "执行命令2-安装Debian 12..."
            bash InstallNET.sh -debian
            back_to_menu system_reinstall
            ;;
        3)
            echo "执行命令3-安装Ubuntu 22.04..."
            bash InstallNET.sh -ubuntu
            back_to_menu system_reinstall
            ;;
        4)
            echo "执行命令4-安装alpine..."
            bash InstallNET.sh -alpine
            back_to_menu system_reinstall
            ;;
        5)
            echo "执行一键重装【慎用】..."
            bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 11 -timezone "Asia/Shanghai"
            back_to_menu system_reinstall
            ;;
        6)
            echo "重启系统..."
            reboot
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; system_reinstall ;;
    esac
}

# 开小鸡工具函数
vps_create() {
    clear
    echo -e "${GREEN}=== 开小鸡工具 ===${NC}"
    echo "1. LXD开LXC小鸡"
    echo "2. Pve开LXC小鸡"
    echo "3. Pve开KVM或LXC小鸡"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-3): " subchoice
    
    case $subchoice in
        1) echo "执行LXD开LXC小鸡" ; back_to_menu vps_create ;;
        2) echo "执行Pve开LXC小鸡" ; back_to_menu vps_create ;;
        3) echo "执行Pve开KVM或LXC小鸡" ; back_to_menu vps_create ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; vps_create ;;
    esac
}

# Docker工具函数
docker_tools() {
    clear
    echo -e "${GREEN}=== Docker 工具 ===${NC}"
    echo "1. 安装docker"
    echo "2. 启动docker"
    echo "3. 查看docker"
    echo "4. 安装docker2"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-4): " subchoice
    
    case $subchoice in
        1)
            echo "安装docker..."
            curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
            back_to_menu docker_tools
            ;;
        2)
            echo "启动docker..."
            docker-compose up -d
            back_to_menu docker_tools
            ;;
        3)
            echo "查看docker..."
            docker ps
            back_to_menu docker_tools
            ;;
        4)
            echo "安装docker2..."
            wget -O install_docker.sh "https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/install_docker.sh" && chmod +x install_docker.sh && ./install_docker.sh
            back_to_menu docker_tools
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; docker_tools ;;
    esac
}

# 哪吒面板函数
nezha_panel() {
    clear
    echo -e "${GREEN}=== 哪吒面板 ===${NC}"
    echo "1. v1哪吒"
    echo "2. 执行命令"
    echo "3. 清除v1 agent"
    echo "4. 安装unzip"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-4): " subchoice
    
    case $subchoice in
        1)
            echo "安装v1哪吒..."
            curl -L https://raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && sudo ./nezha.sh
            back_to_menu nezha_panel
            ;;
        2)
            echo "执行命令..."
            ./nezha.sh
            back_to_menu nezha_panel
            ;;
        3)
            echo "清除v1 agent..."
            wget https://raw.githubusercontent.com/miaojior/cleanup_nezha/main/cleanup_nezha.sh && chmod +x cleanup_nezha.sh && ./cleanup_nezha.sh
            back_to_menu nezha_panel
            ;;
        4)
            echo "安装unzip..."
            apt -y install unzip
            back_to_menu nezha_panel
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; nezha_panel ;;
    esac
}

# Caddy2工具函数
caddy_tools() {
    clear
    echo -e "${GREEN}=== Caddy2 工具 ===${NC}"
    echo "1. 关闭防火墙"
    echo "2. 安装必要的软件包"
    echo "3. 添加Caddy的安全密钥"
    echo "4. 下载Caddy密钥文件"
    echo "5. 更新软件包列表"
    echo "6. 安装Caddy2"
    echo "7. 启动Caddy2"
    echo "8. 重启Caddy2"
    echo "9. 开机自启"
    echo "10. 停止Caddy2"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        1)
            echo "关闭防火墙..."
            sudo ufw disable
            back_to_menu caddy_tools
            ;;
        2)
            echo "安装必要的软件包..."
            sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
            back_to_menu caddy_tools
            ;;
        3)
            echo "添加Caddy的安全密钥..."
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
            back_to_menu caddy_tools
            ;;
        4)
            echo "下载Caddy密钥文件..."
            curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
            back_to_menu caddy_tools
            ;;
        5)
            echo "更新软件包列表..."
            sudo apt update
            back_to_menu caddy_tools
            ;;
        6)
            echo "安装Caddy2..."
            sudo apt install caddy
            back_to_menu caddy_tools
            ;;
        7)
            echo "启动Caddy2..."
            systemctl start caddy
            back_to_menu caddy_tools
            ;;
        8)
            echo "重启Caddy2..."
            systemctl restart caddy
            back_to_menu caddy_tools
            ;;
        9)
            echo "设置Caddy2开机自启..."
            systemctl enable caddy
            back_to_menu caddy_tools
            ;;
        10)
            echo "停止Caddy2..."
            systemctl stop caddy
            back_to_menu caddy_tools
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; caddy_tools ;;
    esac
}

# 经典应用函数
classic_apps() {
    clear
    echo -e "${GREEN}=== 经典应用 ===${NC}"
    echo "1. Cloudreve网盘"
    echo "2. 简单图床图片管理程序"
    echo "3. webssh网页版SSH连接工具"
    echo "4. Speedtest测速面板"
    echo "5. UptimeKuma监控工具"
    echo "6. Memos网页备忘录"
    echo "7. searxng聚合搜索站"
    echo "8. PhotoPrism私有相册系统"
    echo "9. Sun-Panel导航面板"
    echo "10. MyIP工具箱"
    echo "11. Pingvin-Share文件分享平台"
    echo "0. 返回主菜单"
    
    read -p "请选择功能 (0-11): " choice
    
    case $choice in
        1)
            echo "安装Cloudreve网盘..."

			send_stats "搭建网盘"


			local docker_name=cloudreve
			local docker_port=5212
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "网盘服务 $check_docker $update_status"
				echo "cloudreve是一个支持多家云存储的网盘系统"
				echo "视频介绍: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 卸载"
				echo "------------------------"
				echo "5. 域名访问"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install jq
						install_docker
						cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
						curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
						cd /home/docker/cloud/ && docker compose up -d

						clear
						echo "cloudreve已经安装完成"
						check_docker_app_ip
						sleep 3
						docker logs cloudreve
						echo ""


						;;

					2)
						docker rm -f cloudreve
						docker rmi -f cloudreve/cloudreve:latest
						docker rm -f aria2
						docker rmi -f p3terx/aria2-pro
						cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
						curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
						cd /home/docker/cloud/ && docker compose up -d
						clear
						echo "cloudreve已经安装完成"
						check_docker_app_ip
						sleep 3
						docker logs cloudreve
						echo ""
						;;
					3)

						docker rm -f cloudreve
						docker rmi -f cloudreve/cloudreve:latest
						docker rm -f aria2
						docker rmi -f p3terx/aria2-pro
						rm -rf /home/docker/cloud
						echo "应用已卸载"

						;;
					5)
						echo "${docker_name}域名访问设置"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;

        2)
            echo "安装简单图床图片管理程序..."
            # 从kejilion.sh中提取简单图床图片管理程序的安装命令
            back_to_menu classic_apps
            ;;
        3)
            echo "安装webssh网页版SSH连接工具..."
            # 从kejilion.sh中提取webssh网页版SSH连接工具的安装命令
            back_to_menu classic_apps
            ;;
        4)
            echo "安装Speedtest测速面板..."
            # 从kejilion.sh中提取Speedtest测速面板的安装命令
            back_to_menu classic_apps
            ;;
        5)
            echo "安装UptimeKuma监控工具..."
            # 从kejilion.sh中提取UptimeKuma监控工具的安装命令
            back_to_menu classic_apps
            ;;
        6)
            echo "安装Memos网页备忘录..."
            # 从kejilion.sh中提取Memos网页备忘录的安装命令
            back_to_menu classic_apps
            ;;
        7)
            echo "安装searxng聚合搜索站..."
            # 从kejilion.sh中提取searxng聚合搜索站的安装命令
            back_to_menu classic_apps
            ;;
        8)
            echo "安装PhotoPrism私有相册系统..."
            # 从kejilion.sh中提取PhotoPrism私有相册系统的安装命令
            back_to_menu classic_apps
            ;;
        9)
            echo "安装Sun-Panel导航面板..."
            # 从kejilion.sh中提取Sun-Panel导航面板的安装命令
            back_to_menu classic_apps
            ;;
        10)
            echo "安装MyIP工具箱..."
            # 从kejilion.sh中提取MyIP工具箱的安装命令
            back_to_menu classic_apps
            ;;
        11)
            echo "安装Pingvin-Share文件分享平台..."
            # 从kejilion.sh中提取Pingvin-Share文件分享平台的安装命令
            back_to_menu classic_apps
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; classic_apps ;;
    esac
}

# 主菜单函数
main_menu() {
    clear
    echo -e "${GREEN}=== Linux 命令工具箱 ===${NC}"
    echo "1. 常用命令"
    echo "2. VPS 安装工具"
    echo "3. 经典应用"
    echo "4. 抢鸡工具"
    echo "5. 重装系统"
    echo "6. 开小鸡工具"
    echo "7. Docker 工具"
    echo "8. 哪吒面板"
    echo "9. Caddy2 工具"
    echo "0. 退出"
    
    read -p "请选择功能 (0-9): " choice
    
    case $choice in
        1) common_commands ;;
        2) vps_install ;;
        3) classic_apps ;;
        4) vps_grab ;;
        5) system_reinstall ;;
        6) vps_create ;;
        7) docker_tools ;;
        8) nezha_panel ;;
        9) caddy_tools ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; main_menu ;;
    esac
}

# 启动主菜单
main_menu 
