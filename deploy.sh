#!/bin/bash
# ========================================
# Banana Slides 服务器部署脚本
# 适用于 Ubuntu/Debian 系统
# ========================================

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Banana Slides 服务器部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}请使用 sudo 运行此脚本${NC}"
    exit 1
fi

# 1. 检查并安装 Docker
echo -e "${YELLOW}[1/6] 检查 Docker...${NC}"
if ! command -v docker &> /dev/null; then
    echo "安装 Docker..."
    curl -fsSL https://get.docker.com | sh
    systemctl enable docker
    systemctl start docker
else
    echo -e "${GREEN}Docker 已安装${NC}"
fi

# 2. 检查并安装 Docker Compose
echo -e "${YELLOW}[2/6] 检查 Docker Compose...${NC}"
if ! command -v docker-compose &> /dev/null; then
    echo "安装 Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
else
    echo -e "${GREEN}Docker Compose 已安装${NC}"
fi

# 3. 创建部署目录
echo -e "${YELLOW}[3/6] 创建部署目录...${NC}"
DEPLOY_DIR="/opt/banana-slides"
mkdir -p $DEPLOY_DIR
cd $DEPLOY_DIR

# 4. 下载或更新代码
echo -e "${YELLOW}[4/6] 获取代码...${NC}"
if [ -d ".git" ]; then
    echo "更新代码..."
    git pull
else
    echo "克隆代码..."
    read -p "请输入仓库地址 (默认: https://github.com/Anionex/banana-slides): " REPO_URL
    REPO_URL=${REPO_URL:-https://github.com/Anionex/banana-slides}
    git clone $REPO_URL .
fi

# 5. 配置环境变量
echo -e "${YELLOW}[5/6] 配置环境变量...${NC}"
if [ ! -f ".env" ]; then
    cp .env.production .env
    echo ""
    echo -e "${RED}请编辑 .env 文件，配置以下关键参数：${NC}"
    echo "  - OPENAI_API_KEY: 你的 API Key"
    echo "  - CORS_ORIGINS: 修改为服务器地址，如 http://$(hostname -I | awk '{print $1}'):3333"
    echo "  - SECRET_KEY: 修改为随机字符串"
    echo ""
    read -p "配置完成后按回车继续..."
else
    echo -e "${GREEN}.env 文件已存在，跳过${NC}"
fi

# 6. 启动服务
echo -e "${YELLOW}[6/6] 启动服务...${NC}"
docker-compose down 2>/dev/null || true
docker-compose up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 10

# 7. 验证部署
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 获取服务器IP
SERVER_IP=$(hostname -I | awk '{print $1}')

echo "服务状态："
docker-compose ps
echo ""

echo -e "${GREEN}访问地址：${NC}"
echo "  前端: http://$SERVER_IP:3333"
echo "  后端: http://$SERVER_IP:5000"
echo ""

echo -e "${YELLOW}常用命令：${NC}"
echo "  查看日志: docker-compose logs -f"
echo "  重启服务: docker-compose restart"
echo "  停止服务: docker-compose down"
echo "  更新代码: git pull && docker-compose up -d --build"
echo ""

echo -e "${YELLOW}下一步操作：${NC}"
echo "1. 如果需要外部访问，请配置防火墙和 Nginx 反向代理"
echo "2. 建议配置 HTTPS 证书"
echo "3. 设置定期备份数据库"
echo ""

# 显示日志提示
echo -e "${YELLOW}查看实时日志? (y/n)${NC}"
read -p "> " VIEW_LOGS
if [ "$VIEW_LOGS" = "y" ]; then
    docker-compose logs -f
fi
