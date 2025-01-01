#!/bin/bash

# 设置颜色变量
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 主菜单函数
main_menu() {
    clear
    echo -e "${GREEN}=== Linux 命令工具箱 ===${NC}"
    echo "1. 常用命令"
    echo "2. VPS 安装工具"
    echo "3. 抢鸡工具"
    echo "4. 重装系统"
    echo "5. 开小鸡工具"
    echo "6. Docker 工具"
    echo "7. 哪吒面板"
    echo "8. Caddy2 工具"
    echo "0. 退出"
    
    read -p "请选择功能 (0-8): " choice
    
    case $choice in
        1) common_commands ;;
        2) vps_install ;;
        3) vps_grab ;;
        4) system_reinstall ;;
        5) vps_create ;;
        6) docker_tools ;;
        7) nezha_panel ;;
        8) caddy_tools ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; main_menu ;;
    esac
}

# 常用命令函数
common_commands() {
    clear
    echo -e "${GREEN}=== 常用命令 ===${NC}"
    echo "1. 系统信息查看"
    echo "2. 网络测试工具"
    echo "3. 性能监控"
    echo "4. 返回主菜单"
    
    read -p "请选择 (1-4): " subchoice
    
    case $subchoice in
        1) system_info ;;
        2) network_tools ;;
        3) performance_monitor ;;
        4) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; common_commands ;;
    esac
}

# 系统信息查看函数
system_info() {
    clear
    echo -e "${YELLOW}系统信息：${NC}"
    echo "1. 查看系统版本"
    echo "2. 查看内存使用"
    echo "3. 查看磁盘使用"
    echo "4. 返回上级菜单"
    
    read -p "请选择 (1-4): " choice
    
    case $choice in
        1) cat /etc/os-release ;;
        2) free -h ;;
        3) df -h ;;
        4) common_commands ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; system_info ;;
    esac
    
    read -p "按回车键继续..."
    system_info
}

# 其他功能函数可以按照类似的方式实现
# ...

# 启动主菜单
main_menu 