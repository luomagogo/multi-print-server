#!/bin/bash

# 颜色定义
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}=========================================="
echo -e "   多打印服务器 (HP T630) 一键部署脚本"
echo -e "==========================================${NC}"

# 1. 检查并安装 Docker
if ! command -v docker &> /dev/null; then
    echo -e "${GREEN}[+] 未检测到 Docker，正在自动安装...${NC}"
    curl -fsSL https://get.docker.com | sh
    systemctl start docker
    systemctl enable docker
fi

# 2. 创建所需持久化目录
echo -e "${GREEN}[+] 正在创建本地数据挂载目录...${NC}"
mkdir -p /opt/portainer_data
mkdir -p /opt/virtualhere

# 3. 写入 docker-compose.yml 配置文件
echo -e "${GREEN}[+] 正在生成 /opt/docker-compose.yml...${NC}"
cat << 'EOF' > /opt/docker-compose.yml
version: '3.8'

services:
  # Portainer 可视化 Docker 管理面板
  portainer:
    image: 6053537/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /opt/portainer_data:/data

  # VirtualHere USB Over IP 共享服务
  virtualhere:
    image: moritzf/virtualhere:latest
    container_name: virtualhere
    restart: unless-stopped
    network_mode: host
    privileged: true
    volumes:
      - /opt/virtualhere:/data

  # CUPS Web 网页直印服务
  cups-web-print:
    image: ghcr.io/wishday/cups-web-print:latest
    container_name: cups-web-print
    hostname: cups-web-print
    restart: unless-stopped
    ports:
      - "2980:5000"
    volumes:
      - /var/run/cups/cups.sock:/var/run/cups/cups.sock
      - /etc/cups:/etc/cups
      - cups-uploads:/app/uploads
      - cups-previews:/app/previews

volumes:
  cups-uploads:
  cups-previews:
EOF

# 4. 启动容器堆栈
echo -e "${GREEN}[+] 正在拉取镜像并启动服务堆栈...${NC}"
docker compose -f /opt/docker-compose.yml up -d

# 5. 输出提示信息
IP_ADDR=$(hostname -I | awk '{print $1}')
echo -e "${GREEN}=========================================="
echo -e "         🎉 所有服务已成功启动！"
echo -e "------------------------------------------"
echo -e " 1. Web 打印服务后台:    http://${IP_ADDR}:2980"
echo -e " 2. Portainer 管理面板:  http://${IP_ADDR}:9000"
echo -e " 3. VirtualHere 服务:    已挂载宿主机网络运行"
echo -e "==========================================${NC}"
