#!/bin/bash
# macOS Docker 服务管理辅助脚本
# 用于解决 MacBook 合盖后 Docker 服务停止的问题

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PID_FILE="/tmp/trendradar-caffeinate.pid"

show_help() {
    cat << EOF
🍎 TrendRadar macOS 辅助工具

MacBook 合盖后 Docker 服务会停止，本工具提供解决方案。

使用方法：
  $0 [命令]

可用命令：
  prevent-sleep    防止系统睡眠（推荐：合盖模式）
  allow-sleep      允许系统睡眠（停止防止睡眠）
  status           查看当前状态
  check-setup      检查 Docker 服务状态
  help             显示此帮助信息

解决方案说明：

1. 合盖模式（推荐）⭐
   - 连接外接显示器、键盘和鼠标
   - 合上 MacBook 盖子
   - 系统会继续运行，Docker 服务正常工作

2. 防止睡眠模式
   - 使用本脚本的 prevent-sleep 命令
   - 系统不会进入睡眠，但会消耗更多电量
   - 建议连接电源适配器

3. 远程服务器（最佳实践）⭐
   - 部署到云服务器或 NAS
   - 7x24 小时稳定运行
   - 不受本地电脑状态影响

EOF
}

prevent_sleep() {
    echo "🔒 正在防止系统睡眠..."
    
    # 检查是否已经运行
    if [ -f "$PID_FILE" ]; then
        OLD_PID=$(cat "$PID_FILE")
        if ps -p "$OLD_PID" > /dev/null 2>&1; then
            echo "⚠️  防止睡眠功能已在运行 (PID: $OLD_PID)"
            echo "   如需重新启动，请先运行: $0 allow-sleep"
            return
        else
            rm "$PID_FILE"
        fi
    fi
    
    # 启动 caffeinate（防止系统睡眠，但允许显示器关闭）
    caffeinate -i &
    CAFFEINATE_PID=$!
    echo $CAFFEINATE_PID > "$PID_FILE"
    
    echo "✅ 防止睡眠功能已启动 (PID: $CAFFEINATE_PID)"
    echo ""
    echo "💡 提示："
    echo "   - 系统不会进入睡眠，Docker 服务会继续运行"
    echo "   - 显示器可能会关闭以节省电量"
    echo "   - 建议连接电源适配器"
    echo "   - 停止防止睡眠: $0 allow-sleep"
}

allow_sleep() {
    echo "🔓 正在允许系统睡眠..."
    
    if [ ! -f "$PID_FILE" ]; then
        echo "ℹ️  防止睡眠功能未运行"
        return
    fi
    
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        kill "$PID"
        echo "✅ 已停止防止睡眠功能 (PID: $PID)"
    else
        echo "⚠️  PID 文件存在但进程不存在，清理中..."
    fi
    
    rm -f "$PID_FILE"
    echo "✅ 系统现在可以正常进入睡眠"
}

check_status() {
    echo "📊 当前状态："
    echo ""
    
    # 检查防止睡眠状态
    if [ -f "$PID_FILE" ]; then
        PID=$(cat "$PID_FILE")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "🔒 防止睡眠: ✅ 运行中 (PID: $PID)"
        else
            echo "🔒 防止睡眠: ❌ 未运行（PID 文件存在但进程不存在）"
            rm "$PID_FILE"
        fi
    else
        echo "🔒 防止睡眠: ⭕ 未启用"
    fi
    
    echo ""
    
    # 检查 Docker 状态
    if command -v docker &> /dev/null; then
        echo "🐳 Docker 状态："
        if docker info &> /dev/null; then
            echo "   ✅ Docker 正在运行"
            
            # 检查 TrendRadar 容器
            cd "$SCRIPT_DIR"
            if docker compose ps 2>/dev/null | grep -q "trend-radar"; then
                echo "   ✅ TrendRadar 容器状态："
                docker compose ps | grep trend-radar || true
            else
                echo "   ⚠️  TrendRadar 容器未运行"
                echo "      启动命令: cd $SCRIPT_DIR && docker compose up -d"
            fi
        else
            echo "   ❌ Docker 未运行或无法访问"
        fi
    else
        echo "🐳 Docker: ❌ 未安装"
    fi
    
    echo ""
    
    # 检查外接设备（合盖模式）
    echo "🖥️  合盖模式检查："
    if system_profiler SPDisplaysDataType 2>/dev/null | grep -q "Display Type: External"; then
        echo "   ✅ 检测到外接显示器"
        echo "   💡 如果已连接键盘和鼠标，可以合盖使用"
    else
        echo "   ⚠️  未检测到外接显示器"
        echo "   💡 连接外接显示器、键盘和鼠标后，合盖也能继续运行"
    fi
    
    echo ""
    echo "💡 建议："
    echo "   - 如果使用 MacBook 作为服务器，建议部署到云服务器或 NAS"
    echo "   - 临时使用可以启用防止睡眠功能"
    echo "   - 长期运行建议使用合盖模式（外接设备）"
}

check_docker_setup() {
    echo "🔍 检查 Docker 服务设置..."
    echo ""
    
    cd "$SCRIPT_DIR"
    
    # 检查配置文件
    echo "📁 配置文件检查："
    if [ -f "../config/config.yaml" ]; then
        echo "   ✅ config.yaml 存在"
    else
        echo "   ❌ config.yaml 不存在"
    fi
    
    if [ -f "../config/frequency_words.txt" ]; then
        echo "   ✅ frequency_words.txt 存在"
    else
        echo "   ❌ frequency_words.txt 不存在"
    fi
    
    if [ -f ".env" ]; then
        echo "   ✅ .env 存在"
    else
        echo "   ⚠️  .env 不存在（将从 env.example 创建）"
    fi
    
    echo ""
    
    # 检查 Docker Compose
    echo "🐳 Docker Compose 检查："
    if [ -f "docker-compose.yml" ]; then
        echo "   ✅ docker-compose.yml 存在"
        
        # 检查服务状态
        if docker compose ps 2>/dev/null | grep -q "trend-radar"; then
            echo ""
            echo "📊 容器状态："
            docker compose ps
        else
            echo "   ⚠️  容器未运行"
            echo ""
            echo "💡 启动命令："
            echo "   cd $SCRIPT_DIR"
            echo "   docker compose up -d"
        fi
    else
        echo "   ❌ docker-compose.yml 不存在"
    fi
}

# 主逻辑
case "${1:-help}" in
    prevent-sleep)
        prevent_sleep
        ;;
    allow-sleep)
        allow_sleep
        ;;
    status)
        check_status
        ;;
    check-setup)
        check_docker_setup
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ 未知命令: $1"
        echo ""
        show_help
        exit 1
        ;;
esac

