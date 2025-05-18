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
    echo "2. 系统优化"
    echo "3. 一键升级"
    echo "4. X-UI-F大"
    echo "5. X-UI-F大独立版"
    echo "6. F大warp添加IPV4"
    echo "7. 安装hy2"
    echo "8. 安装 3X-UI"
    echo "9. 安装F大argox隧道"
    echo "10. 删除argox脚本"
    echo "11. 梭哈脚本"
    echo "12. 查看梭哈"
    echo "13. 融合怪命令1【综合测试】"
    echo "14. 融合怪命令2【三网测试】"
    echo "15. 解锁测试"
    echo "16. 更新系统"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-16): " choice
    
    case $choice in
        1)
            echo "查询系统信息..."
            echo "----------------------------------------"
            echo "| 项目          | 信息                  |"
            echo "----------------------------------------"
            echo "| 主机名        | $(hostname)           |"
            echo "| Linux版本     | $(uname -r)           |"
            echo "| 系统版本      | $(lsb_release -d -s)  |"
            echo "| CPU架构       | $(uname -m)           |"
            echo "| CPU型号       | $(lscpu | grep 'Model name' | awk -F: '{print $2}' | xargs) |"
            echo "| CPU核心数     | $(nproc)              |"
            echo "| CPU频率       | $(lscpu | grep 'MHz' | awk -F: '{print $2}' | xargs) MHz |"
            echo "| CPU占用       | $(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1"%"}') |"
            echo "| 系统负载      | $(uptime | awk -F'load average:' '{ print $2 }' | xargs) |"
            echo "| 物理内存      | $(free -h | awk '/^Mem:/ {print $2}') |"
            echo "| 虚拟内存      | $(free -h | awk '/^Swap:/ {print $2}') |"
            echo "| 硬盘占用      | $(df -h --total | grep 'total' | awk '{print $3 "/" $2}') |"
            echo "| IPv4地址      | $(hostname -I | awk '{print $1}') |"
            echo "| IPv6地址      | $(hostname -I | awk '{print $2}') |"
            echo "| DNS地址       | $(cat /etc/resolv.conf | grep 'nameserver' | awk '{print $2}' | xargs) |"
            echo "| 地理位置      | $(curl -s ipinfo.io/country) |"
            echo "| 系统时间      | $(date) |"
            echo "| 运行时长      | $(uptime -p) |"
            echo "----------------------------------------"
            main_menu
            ;;
        2)
            while true; do
                clear
                echo -e "${GREEN}=== 系统优化 ===${NC}"
                echo "1. 校准时间"
                echo "2. 更新系统"
                echo "3. 清理系统"
                echo "4. 开启BBR"
                echo "5. ROOT登录"
                echo "0. 返回上级菜单"
                
                read -p "请选择 (0-5): " opt_choice
                
                case $opt_choice in
                    1)
                        echo "校准时间..."
                        sudo timedatectl set-timezone Asia/Shanghai
                        sudo timedatectl set-ntp true
                        echo -e "${GREEN}时间校准完成，当前时区为 Asia/Shanghai。${NC}"
                        back_to_menu common_commands
                        ;;
                    2)
                        echo "更新系统..."
                        if ! sudo apt update -y && ! sudo apt full-upgrade -y; then
                            echo -e "${RED}系统更新失败！请检查网络连接或源列表。${NC}"
                        else
                            sudo apt autoremove -y && sudo apt autoclean -y
                            echo -e "${GREEN}系统更新完成！${NC}"
                        fi
                        back_to_menu common_commands
                        ;;
                    3)
                        echo "清理系统..."
                        sudo apt autoremove --purge -y
                        sudo apt clean -y && sudo apt autoclean -y
                        sudo journalctl --rotate && sudo journalctl --vacuum-time=10m
                        sudo journalctl --vacuum-size=50M
                        echo -e "${GREEN}系统清理完成！${NC}"
                        back_to_menu common_commands
                        ;;
                    4)
                        echo "开启BBR..."
                        if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
                            echo -e "${GREEN}BBR已开启！${NC}"
                        else
                            echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
                            echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
                            if sudo sysctl -p; then
                                echo -e "${GREEN}BBR已开启！${NC}"
                            else
                                echo -e "${RED}BBR开启失败！${NC}"
                            fi
                        fi
                        back_to_menu common_commands
                        ;;
                    5)
                        while true; do
                            clear
                            echo -e "${GREEN}=== ROOT登录 ===${NC}"
                            echo "1. 设置密码"
                            echo "2. 修改配置"
                            echo "3. 重启服务"
                            echo "0. 返回上级菜单"
                            
                            read -p "请选择 (0-3): " root_choice
                            
                            case $root_choice in
                                1)
                                    sudo passwd root
                                    back_to_menu common_commands
                                    ;;
                                2)
                                    sudo sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
                                    sudo sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
                                    echo -e "${GREEN}配置修改成功！${NC}"
                                    back_to_menu common_commands
                                    ;;
                                3)
                                    if sudo systemctl restart sshd.service; then
                                        echo -e "${GREEN}ROOT登录已开启！${NC}"
                                    else
                                        echo -e "${RED}ROOT登录开启失败！${NC}"
                                    fi
                                    back_to_menu common_commands
                                    ;;
                                0) break ;;
                                *) echo -e "${RED}无效选择${NC}" ; sleep 2 ;;
                            esac
                        done
                        ;;
                    0) break ;;
                    *) echo -e "${RED}无效选择${NC}" ; sleep 2 ;;
                esac
            done
            ;;
        3)
            echo "执行一键升级..."
            apt update -y && apt install curl wget -y && apt update && apt install curl wget
            main_menu 
            ;;
        4)
            echo "执行X-UI-F大安装..."
            bash <(curl -Ls https://raw.githubusercontent.com/wszx123/x-ui-FranzKafkaYu/master/install.sh)
            main_menu 
            ;;
        5)
            echo "执行X-UI-F大独立版安装..."
            bash <(curl -Ls https://raw.githubusercontent.com/wszx123/x-ui-FranzKafkaYu/master/install.sh) 0.3.4.4
            main_menu 
            ;;
        6)
            echo "执行F大warp添加IPV4..."
            wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
            main_menu 
            ;;
        7)
            echo "安装hy2..."
            wget -N --no-check-certificate https://raw.githubusercontent.com/Misaka-blog/hysteria-install/main/hy2/hysteria.sh && bash hysteria.sh
            main_menu 
            ;;
        8)
            echo "安装3X-UI..."
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            main_menu 
            ;;
        9)
            echo "安装F大argox隧道..."
            bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh)
            main_menu 
            ;;
        10)
            echo "删除argox脚本..."
            argox -u
            main_menu 
            ;;
        11)
            echo "执行梭哈脚本..."
            curl https://raw.githubusercontent.com/wszx123/ArgoX/main/suoha.sh -o suoha.sh && bash suoha.sh
            main_menu 
            ;;
        12)
            echo "查看梭哈..."
            cat v2ray.txt
            main_menu 
            ;;
        13)
            echo "融合怪命令1【综合测试】..."
            bash <(wget -qO- bash.spiritlhl.net/ecs)
            main_menu 
            ;;
        14)
            echo "融合怪命令2【三网测试】..."
            bash <(curl -L -s https://bench.im/hyperspeed)
            main_menu 
            ;;
        15)
            echo "解锁测试..."
            bash <(curl -L -s media.ispvps.com)
            main_menu 
            ;;
        16)
            echo "更新系统..."
            read -p "确认更新系统？(y/n): " confirm
if [[ "$confirm" == "y" ]]; then
    apt update && apt full-upgrade -y
else
    echo "取消更新"
fi

            main_menu
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; common_commands ;;
    esac
}

# VPS安装工具函数
vps_install() {
    clear
    echo -e "${GREEN}=== VPS 安装工具 ===${NC}"
    echo "1. 安装unzip"
    echo "2. 安装zip"
    echo "3. 安装curl"
    echo "4. 安装git"
    echo "5. 安装nano"
    for i in {6..10}; do
        echo "$i. VPS 安装工具$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        1)
            echo "安装unzip..."
            apt -y install unzip
            back_to_menu vps_install
            ;;
        2)
            echo "安装zip..."
            apt -y install zip
            back_to_menu vps_install
            ;;
        3)
            echo "安装curl..."
            apt -y install curl
            back_to_menu vps_install
            ;;
        4)
            echo "安装git..."
            apt -y install git
            back_to_menu vps_install
            ;;
        5)
            echo "安装nano..."
            apt -y install nano
            back_to_menu vps_install
            ;;
        [6-9]|1[0-9]|10) echo "执行VPS安装工具$subchoice" ; back_to_menu vps_install ;;
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
    echo "1. 命令1-必须，密码为LeitboGi0ro，重装后必须修改"
    echo "2. 命令2-安装Debian 12，密码为LeitboGi0ro，重装后必须修改"
    echo "3. 命令3-安装Ubuntu 22.04，密码为LeitboGi0ro，重装后必须修改"
    echo "4. 命令4-安装alpine，密码为LeitboGi0ro，重装后必须修改"
    echo "5. 一键重装debian11【不修改密码】"
    echo "6. 一键重装debian11【密码为KKK12356ws01，虚拟内存1G】"
    echo "7. 一键重装debian12【不修改密码】"
    echo "8. 一键重装debian12【密码为KKK12356ws01，虚拟内存1G】"
    echo "9. 一键重装OpenVz/LXC【小内存LXC专用，其它慎用】"
    echo "10. 重启"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
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
            echo "执行一键重装debian11【不修改密码】..."
            bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 11 -timezone "Asia/Shanghai"
            back_to_menu system_reinstall
            ;;
        6)
            echo "执行一键重装debian11【密码为KKK12356ws01，重装后要修改，虚拟内存1G】..."
            bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 11 -timezone "Asia/Shanghai" -pwd 'KKK12356ws01' -swap "1024" --bbr
            back_to_menu system_reinstall
            ;;
        7)
            echo "执行一键重装debian12【不修改密码】..."
            bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 12 -timezone "Asia/Shanghai"
            back_to_menu system_reinstall
            ;;
        8)
            echo "执行一键重装debian12【密码为KKK12356ws01，重装后要修改，虚拟内存1G】..."
            bash <(curl -sSL https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh) -debian 12 -timezone "Asia/Shanghai" -pwd 'KKK12356ws01' -swap "1024" --bbr
            back_to_menu system_reinstall
            ;;
        9)
            echo "一键重装OpenVz/LXC【小内存LXC专用，其它慎用】..."
            curl -so OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && bash OsMutation.sh
            back_to_menu system_reinstall
            ;;
        10)
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
    echo "2. 启动docker【进入目录后启动】"
    echo "3. 查看docker"
    echo "4. 安装docker2"
    echo "5. 停止指定docker容器"
    echo "6. 启动指定docker容器"
    echo "7. 删除指定docker容器"
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-7): " subchoice
    
    case $subchoice in
        1)
            echo "安装docker..."
            curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
            back_to_menu docker_tools
            ;;
        2)
            echo "启动docker【进入目录后启动】..."
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
        5)
            echo "当前运行的Docker容器："
            docker ps
            read -p "请输入要停止的容器名称或ID: " container_name
            if [ ! -z "$container_name" ]; then
                echo "正在停止容器 $container_name..."
                docker stop $container_name
                echo -e "${GREEN}容器 $container_name 已停止${NC}"
            else
                echo -e "${RED}未输入容器名称或ID${NC}"
            fi
            back_to_menu docker_tools
            ;;
        6)
            echo "当前未运行的Docker容器："
            docker ps -a --filter "status=exited"
            read -p "请输入要启动的容器名称或ID: " container_name
            if [ ! -z "$container_name" ]; then
                echo "正在启动容器 $container_name..."
                docker start $container_name
                echo -e "${GREEN}容器 $container_name 已启动${NC}"
            else
                echo -e "${RED}未输入容器名称或ID${NC}"
            fi
            back_to_menu docker_tools
            ;;
        7)
            echo "当前运行的Docker容器："
            docker ps -a
            read -p "请输入要删除的容器名称或ID: " container_name
            if [ ! -z "$container_name" ]; then
                echo "正在删除容器 $container_name..."
                docker rm -f $container_name
                echo -e "${GREEN}容器 $container_name 已删除${NC}"
            else
                echo -e "${RED}未输入容器名称或ID${NC}"
            fi
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
    echo -e "${GREEN}=== 经典应用【未完成】 ===${NC}"
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
            # 从kejilion.sh中提取Cloudreve网盘的安装命令
            # 例如：docker run -d --name cloudreve -p 5212:5212 -v /path/to/data:/cloudreve cloudreve/cloudreve
            back_to_menu classic_apps
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

# VPS安全工具函数
vps_security_tools() {
    clear
    echo -e "${GREEN}=== VPS安全工具 ===${NC}"
    echo "1. 修改VPS密码"
    echo "2. 修改VPS 22端口为50100"
    echo "3. 修改VPS端口为任意端口"
    echo "4. 一键修改为密钥登录"
    echo "5. 恢复密码登录【已安装3才可用】"
    echo "6. 一键开启防火墙(UFW)"
    echo -e "${RED}7. 一键关闭防火墙(UFW)${NC}"
    echo -e "${RED}8. 一键关闭root远程登录${NC}"
    echo "9. 查看登录次数"
    echo "10. 备份指定文件夹"
    echo "0. 返回主菜单"
    read -p "请选择 (0-10): " subchoice
    case $subchoice in
        1)
            echo "修改VPS密码..."
            passwd
            back_to_menu vps_security_tools
            ;;
        2)
            echo "修改VPS 22端口为50100..."
            sed -i 's/^#\?Port 22/Port 50100/' /etc/ssh/sshd_config && systemctl restart ssh
            back_to_menu vps_security_tools
            ;;
        3)
            read -p "请输入新的SSH端口号(1-65535): " new_port
            if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -ge 1 ] && [ $new_port -le 65535 ]; then
                echo "正在修改SSH端口为 $new_port..."
                sed -i "s/^#\?Port 22/Port $new_port/" /etc/ssh/sshd_config
                systemctl restart ssh
                echo -e "${GREEN}SSH端口已成功修改为 $new_port${NC}"
                echo -e "${YELLOW}请确保新端口 $new_port 已在防火墙中开放${NC}"
            else
                echo -e "${RED}无效的端口号，请输入1-65535之间的数字${NC}"
            fi
            back_to_menu vps_security_tools
            ;;
        4)
            echo "一键修改为密钥登录..."
            bash -c "$(curl -L https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/authorized_keys.sh)"
            back_to_menu vps_security_tools
            ;;
        5)
            echo "恢复密码登录【已安装3才可用】..."
            bash /root/restore_ssh_password_auth.sh
            back_to_menu vps_security_tools
            ;;
        6)
            echo "开启UFW防火墙..."
            ufw enable
            back_to_menu vps_security_tools
            ;;
        7)
            echo "关闭UFW防火墙..."
            ufw disable
            back_to_menu vps_security_tools
            ;;
        8)
            echo "关闭root远程登录..."
            sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && systemctl restart ssh
            back_to_menu vps_security_tools
            ;;
        9)
            echo "查看登录次数..."
            echo -e "${GREEN}登录失败次数: $(lastb | wc -l)${NC}"
            back_to_menu vps_security_tools
            ;;
        10)
            echo "备份指定文件夹..."
            read -p "请输入要备份的文件夹路径: " folder_path
            if [ -d "$folder_path" ]; then
                mkdir -p /home/backup
                backup_file="/home/backup/backup_$(date +%Y%m%d%H%M%S).zip"
                zip -r $backup_file $folder_path
                echo -e "${GREEN}备份完成，备份文件保存在: $backup_file${NC}"
            else
                echo -e "${RED}指定的文件夹路径不存在，请检查后重试${NC}"
            fi
            back_to_menu vps_security_tools
            ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; vps_security_tools ;;
    esac
}

# 主菜单函数
main_menu() {
    clear
    echo -e "${GREEN}=== Linux 命令工具箱 ===${NC}"
    echo "1. 常用命令"
    echo "2. VPS 安装工具"
    echo "3. 经典应用【未完成】"
    echo "4. 抢鸡工具"
    echo "5. 重装系统"
    echo "6. 开小鸡工具"
    echo "7. Docker 工具"
    echo "8. 哪吒面板"
    echo "9. Caddy2 工具"
    echo "10. VPS安全工具"
    echo "0. 退出"
    
    read -p "请选择功能 (0-10): " choice
    
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
        10) vps_security_tools ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; main_menu ;;
    esac
}

# 启动主菜单
main_menu 
