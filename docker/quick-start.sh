#!/bin/bash
# TrendRadar Docker 快速启动脚本

set -e

echo "🚀 TrendRadar Docker 快速启动脚本"
echo "=================================="
echo ""

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    echo "❌ 错误：未检测到 Docker，请先安装 Docker"
    echo "   访问 https://docs.docker.com/get-docker/ 获取安装指南"
    exit 1
fi

# 检查 Docker Compose 是否安装
if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ 错误：未检测到 Docker Compose，请先安装 Docker Compose"
    echo "   访问 https://docs.docker.com/compose/install/ 获取安装指南"
    exit 1
fi

# 获取脚本所在目录
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# 检查配置文件是否存在
if [ ! -f "../config/config.yaml" ]; then
    echo "❌ 错误：未找到配置文件 config/config.yaml"
    echo "   请确保已正确克隆项目或创建配置文件"
    exit 1
fi

if [ ! -f "../config/frequency_words.txt" ]; then
    echo "❌ 错误：未找到关键词文件 config/frequency_words.txt"
    echo "   请确保已正确克隆项目或创建关键词文件"
    exit 1
fi

# 检查 .env 文件
if [ ! -f ".env" ]; then
    echo "📝 未找到 .env 文件，正在从模板创建..."
    if [ -f "env.example" ]; then
        cp env.example .env
        echo "✅ 已创建 .env 文件（从 env.example 模板）"
        echo "⚠️  请编辑 .env 文件配置你的通知渠道和运行参数"
        echo ""
        read -p "是否现在编辑 .env 文件？(y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            ${EDITOR:-vim} .env
        fi
    else
        echo "⚠️  警告：未找到 env.example 模板文件"
        echo "   将使用默认配置启动（可能无法正常推送通知）"
    fi
fi

# 选择部署方式
echo ""
echo "请选择部署方式："
echo "1) 使用预构建镜像（推荐，快速）"
echo "2) 本地构建镜像（需要编译，较慢）"
read -p "请输入选项 (1/2，默认1): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[2]$ ]]; then
    echo "🔨 使用本地构建模式..."
    if [ -f "docker-compose-build.yml" ]; then
        cp docker-compose-build.yml docker-compose.yml
        echo "✅ 已切换到构建模式"
    else
        echo "❌ 错误：未找到 docker-compose-build.yml 文件"
        exit 1
    fi
else
    echo "📦 使用预构建镜像模式..."
    if [ ! -f "docker-compose.yml" ] || grep -q "build:" docker-compose.yml; then
        echo "⚠️  检测到构建模式的 compose 文件，正在切换到预构建模式..."
        # 这里可以添加逻辑来恢复预构建版本的 compose 文件
        # 或者提示用户手动处理
        echo "   请确保 docker-compose.yml 使用的是预构建镜像"
    fi
fi

# 选择启动的服务
echo ""
echo "请选择要启动的服务："
echo "1) 仅启动新闻推送服务（trend-radar）"
echo "2) 仅启动 MCP AI 分析服务（trend-radar-mcp）"
echo "3) 启动所有服务（trend-radar + trend-radar-mcp）"
read -p "请输入选项 (1/2/3，默认1): " -n 1 -r
echo ""

SERVICE=""
case $REPLY in
    2)
        SERVICE="trend-radar-mcp"
        echo "🤖 将启动 MCP AI 分析服务"
        ;;
    3)
        SERVICE=""
        echo "🚀 将启动所有服务"
        ;;
    *)
        SERVICE="trend-radar"
        echo "📰 将启动新闻推送服务"
        ;;
esac

# 拉取镜像（如果使用预构建模式）
if [[ ! $REPLY =~ ^[2]$ ]] && [ -z "$SERVICE" ] || [ "$SERVICE" = "trend-radar" ]; then
    echo ""
    echo "📥 正在拉取最新镜像..."
    if [ -n "$SERVICE" ]; then
        docker compose pull $SERVICE
    else
        docker compose pull
    fi
fi

# 启动服务
echo ""
echo "🚀 正在启动服务..."
if [ -n "$SERVICE" ]; then
    docker compose up -d $SERVICE
else
    docker compose up -d
fi

# 等待服务启动
echo ""
echo "⏳ 等待服务启动..."
sleep 3

# 检查服务状态
echo ""
echo "📊 服务状态："
docker compose ps

echo ""
echo "✅ 部署完成！"
echo ""
echo "📋 常用命令："
echo "  查看日志:     docker logs -f $([ -n "$SERVICE" ] && echo "$SERVICE" || echo "trend-radar")"
echo "  查看状态:     docker compose ps"
echo "  停止服务:     docker compose stop $([ -n "$SERVICE" ] && echo "$SERVICE" || echo "")"
echo "  重启服务:     docker compose restart $([ -n "$SERVICE" ] && echo "$SERVICE" || echo "")"
echo "  进入容器:     docker exec -it $([ -n "$SERVICE" ] && echo "$SERVICE" || echo "trend-radar") bash"
echo ""
if [ "$SERVICE" = "trend-radar" ] || [ -z "$SERVICE" ]; then
    echo "🌐 Web 服务器（如果已启用）："
    echo "  访问地址:     http://localhost:8080"
    echo "  首页:         http://localhost:8080/index.html"
    echo ""
fi
echo "📖 更多信息请查看: docker/DOCKER-DEPLOY.md"

