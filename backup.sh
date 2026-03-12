#!/bin/bash
# ========================================
# Banana Slides 数据备份脚本
# 建议添加到 crontab 定时执行
# ========================================

set -e

# 配置
DEPLOY_DIR="/opt/banana-slides"
BACKUP_DIR="/opt/backups/banana-slides"
RETENTION_DAYS=7

# 创建备份目录
mkdir -p $BACKUP_DIR

# 生成时间戳
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/banana-slides_$DATE.tar.gz"

echo "[$(date '+%Y-%m-%d %H:%M:%S')] 开始备份..."

# 备份数据库和上传文件
tar -czf $BACKUP_FILE \
    -C $DEPLOY_DIR \
    backend/instance \
    uploads \
    .env

# 检查备份是否成功
if [ $? -eq 0 ]; then
    SIZE=$(du -h $BACKUP_FILE | cut -f1)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备份成功: $BACKUP_FILE ($SIZE)"
else
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备份失败!"
    exit 1
fi

# 清理旧备份
echo "清理 $RETENTION_DAYS 天前的备份..."
find $BACKUP_DIR -name "banana-slides_*.tar.gz" -mtime +$RETENTION_DAYS -delete

# 列出当前备份
echo ""
echo "当前备份列表:"
ls -lh $BACKUP_DIR/

echo ""
echo "[$(date '+%Y-%m-%d %H:%M:%S')] 备份完成!"
