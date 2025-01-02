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
    for i in {1..10}; do
        echo "$i. 常用命令$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        [1-9]|10) echo "执行常用命令$subchoice" ; back_to_menu common_commands ;;
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
    for i in {1..10}; do
        echo "$i. 重装系统$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        [1-9]|10) echo "执行重装系统$subchoice" ; back_to_menu system_reinstall ;;
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
    for i in {1..10}; do
        echo "$i. Docker工具$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        [1-9]|10) echo "执行Docker工具$subchoice" ; back_to_menu docker_tools ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; docker_tools ;;
    esac
}

# 哪吒面板函数
nezha_panel() {
    clear
    echo -e "${GREEN}=== 哪吒面板 ===${NC}"
    for i in {1..20}; do
        echo "$i. 哪吒面板$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-20): " subchoice
    
    case $subchoice in
        [1-9]|1[0-9]|20) echo "执行哪吒面板$subchoice" ; back_to_menu nezha_panel ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; nezha_panel ;;
    esac
}

# Caddy2工具函数
caddy_tools() {
    clear
    echo -e "${GREEN}=== Caddy2 工具 ===${NC}"
    for i in {1..10}; do
        echo "$i. Caddy2工具$i"
    done
    echo "0. 返回主菜单"
    
    read -p "请选择 (0-10): " subchoice
    
    case $subchoice in
        [1-9]|10) echo "执行Caddy2工具$subchoice" ; back_to_menu caddy_tools ;;
        0) main_menu ;;
        *) echo -e "${RED}无效选择${NC}" ; sleep 2 ; caddy_tools ;;
    esac
}

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

# 启动主菜单
main_menu 
