# 一、安装Docker 和 Docker Compose
- 一键脚本：
```
wget -O install_docker.sh "https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/install_docker.sh" && chmod +x install_docker.sh && ./install_docker.sh
```
&#x26A1;1、安装Docker 和 Docker Compose；2、卸载 Docker 和 Docker Compose；3、查询安装情况和运行状态；4退出脚本。&#x26A1;

# 二、开设虚拟内存 addswap
为openvz、kvm虚拟化的linux服务器增加swap分区(虚拟内存)，单位换算：输入 1024 产生 1G SWAP内存。
- 致谢 [@spiritLHLS](https://github.com/spiritLHLS) 提供。
- 一键脚本：
```
curl -L https://raw.githubusercontent.com/wszx123/gongjuxiang/refs/heads/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
```
