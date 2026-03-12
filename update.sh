#!/bin/bash
# ========================================
# Banana Slides 更新部署脚本
# 从你的仓库拉取最新代码并重新构建
# ========================================

set -e

# 配置 - 修改为你的仓库地址
REPO_URL="https://github.com/你的用户名/banana-slides.git"
BRANCH="main"
DEPLOY_DIR="/opt/banana-slides"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}  Banana Slides 更新部署${NC}"
echo -e "${YELLOW}========================================${NC}"
echo ""

# 检查是否为 root
if [ "$EUID" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本"
    exit 1
fi

# 进入部署目录
cd $DEPLOY_DIR

# 备份当前配置
echo -e "${YELLOW}[1/4] 备份配置...${NC}"
cp .env .env.backup.$(date +%Y%m%d_%H%M%S)

# 拉取最新代码
echo -e "${YELLOW}[2/4] 拉取最新代码...${NC}"
git fetch origin
git reset --hard origin/$BRANCH

# 恢复配置
echo -e "${YELLOW}[3/4] 恢复配置...${NC}"
if [ -f ".env.backup.$(date +%Y%m%d_%H%M%S)" ]; then
    # 如果之前没有 .env，使用备份
    [ ! -f ".env" ] && cp .env.backup.* .env
fi

# 重新构建并启动
echo -e "${YELLOW}[4/4] 重新构建并启动...${NC}"
docker-compose down
docker-compose up -d --build

# 等待服务启动
echo "等待服务启动..."
sleep 15

# 验证部署
echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  更新完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo "服务状态："
docker-compose ps
echo ""

echo -e "${GREEN}访问地址：${NC}"
SERVER_IP=$(hostname -I | awk '{print $1}')
echo "  前端: http://$SERVER_IP:3333"
echo ""

echo -e "${YELLOW}查看日志? (y/n)${NC}"
read -p "> " VIEW_LOGS
if [ "$VIEW_LOGS" = "y" ]; then
    docker-compose logs -f --tail=50
fi
