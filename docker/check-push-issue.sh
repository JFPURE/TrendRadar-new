#!/bin/bash
# TrendRadar 推送问题诊断脚本

echo "🔍 TrendRadar 推送问题诊断"
echo "=================================="
echo ""

# 检查容器是否运行
if ! docker ps | grep -q trend-radar; then
    echo "❌ 错误：trend-radar 容器未运行"
    echo "   请先启动容器：docker compose up -d"
    exit 1
fi

echo "✅ 容器运行状态："
docker ps | grep trend-radar
echo ""

# 检查最近的日志
echo "📋 最近的执行日志（最后50行）："
echo "-----------------------------------"
docker logs trend-radar --tail 50 2>&1 | grep -E "(增量模式|推送|通知|时间窗口|匹配频率词|ENABLE_NOTIFICATION|通知渠道)" || echo "未找到相关日志"
echo ""

# 检查配置
echo "⚙️  检查配置："
echo "-----------------------------------"

# 检查通知是否启用
NOTIFICATION_ENABLED=$(docker exec trend-radar printenv ENABLE_NOTIFICATION 2>/dev/null || echo "")
if [ -z "$NOTIFICATION_ENABLED" ]; then
    echo "⚠️  ENABLE_NOTIFICATION 环境变量未设置（将使用配置文件默认值）"
else
    echo "✅ ENABLE_NOTIFICATION=$NOTIFICATION_ENABLED"
fi

# 检查推送时间窗口
PUSH_WINDOW_ENABLED=$(docker exec trend-radar printenv PUSH_WINDOW_ENABLED 2>/dev/null || echo "")
if [ -z "$PUSH_WINDOW_ENABLED" ]; then
    echo "⚠️  PUSH_WINDOW_ENABLED 环境变量未设置（将使用配置文件默认值）"
else
    echo "✅ PUSH_WINDOW_ENABLED=$PUSH_WINDOW_ENABLED"
    if [ "$PUSH_WINDOW_ENABLED" = "true" ]; then
        PUSH_START=$(docker exec trend-radar printenv PUSH_WINDOW_START 2>/dev/null || echo "")
        PUSH_END=$(docker exec trend-radar printenv PUSH_WINDOW_END 2>/dev/null || echo "")
        echo "   时间窗口: ${PUSH_START:-未设置} - ${PUSH_END:-未设置}"
    fi
fi

# 检查通知渠道配置
echo ""
echo "📱 检查通知渠道配置："
echo "-----------------------------------"
CHANNELS=("FEISHU_WEBHOOK_URL" "DINGTALK_WEBHOOK_URL" "WEWORK_WEBHOOK_URL" "TELEGRAM_BOT_TOKEN" "BARK_URL" "SLACK_WEBHOOK_URL" "NTFY_TOPIC" "EMAIL_FROM")
HAS_CHANNEL=false

for channel in "${CHANNELS[@]}"; do
    value=$(docker exec trend-radar printenv "$channel" 2>/dev/null || echo "")
    if [ -n "$value" ]; then
        echo "✅ $channel 已配置"
        HAS_CHANNEL=true
    fi
done

if [ "$HAS_CHANNEL" = false ]; then
    echo "❌ 未配置任何通知渠道"
    echo "   请在 .env 文件中配置至少一个通知渠道（如 BARK_URL、FEISHU_WEBHOOK_URL 等）"
fi

# 检查报告模式
REPORT_MODE=$(docker exec trend-radar printenv REPORT_MODE 2>/dev/null || echo "")
if [ -z "$REPORT_MODE" ]; then
    echo ""
    echo "⚠️  REPORT_MODE 环境变量未设置（将使用配置文件默认值：incremental）"
else
    echo ""
    echo "✅ REPORT_MODE=$REPORT_MODE"
    if [ "$REPORT_MODE" = "incremental" ]; then
        echo "   ⚠️  增量模式：只有当新增新闻匹配频率词时才会推送"
        echo "   如果新增新闻不匹配频率词，将不会推送"
    fi
fi

# 检查当前时间
echo ""
echo "🕐 当前时间："
echo "-----------------------------------"
docker exec trend-radar date
echo ""

# 检查最近的执行结果
echo "📊 最近的执行结果分析："
echo "-----------------------------------"
RECENT_LOG=$(docker logs trend-radar --tail 100 2>&1)

# 检查是否有匹配的新闻
if echo "$RECENT_LOG" | grep -q "增量模式：.*条新增新闻中，有.*条匹配频率词"; then
    MATCHED=$(echo "$RECENT_LOG" | grep "增量模式：.*条新增新闻中，有.*条匹配频率词" | tail -1)
    echo "📰 $MATCHED"
    
    if echo "$MATCHED" | grep -q "有 0 条"; then
        echo ""
        echo "❌ 问题诊断：新增新闻未匹配任何频率词"
        echo "   解决方案："
        echo "   1. 检查 config/frequency_words.txt 中的关键词是否覆盖了你的关注领域"
        echo "   2. 或者切换到 daily 模式（会推送所有匹配的新闻，不限于新增）"
        echo "   3. 或者切换到 current 模式（会推送当前榜单中的匹配新闻）"
    fi
fi

# 检查时间窗口
if echo "$RECENT_LOG" | grep -q "不在推送时间窗口"; then
    echo ""
    echo "❌ 问题诊断：当前时间不在推送时间窗口内"
    WINDOW_INFO=$(echo "$RECENT_LOG" | grep "不在推送时间窗口" | tail -1)
    echo "   $WINDOW_INFO"
fi

# 检查是否已推送过
if echo "$RECENT_LOG" | grep -q "今天已推送过"; then
    echo ""
    echo "⚠️  今天已推送过（如果启用了 once_per_day）"
fi

echo ""
echo "=================================="
echo "💡 提示："
echo "   - 查看完整日志：docker logs -f trend-radar"
echo "   - 手动执行一次：docker exec trend-radar python -m trendradar"
echo "   - 检查配置文件：cat config/config.yaml"
echo ""
