#!/bin/bash
# 调试新增新闻脚本

echo "🔍 检查新增新闻和关键词匹配情况"
echo "=================================="
echo ""

# 获取最新的日志，找出新增新闻
echo "📋 最近一次执行的新增新闻检测："
echo "-----------------------------------"
docker logs trend-radar --tail 100 2>&1 | grep -A 3 "从存储后端检测到.*条新增标题" | tail -5
echo ""

# 检查关键词配置
echo "📝 当前关键词配置（最后10个关键词组）："
echo "-----------------------------------"
docker exec trend-radar cat /app/config/frequency_words.txt | tail -20
echo ""

# 手动执行一次并查看详细输出
echo "🚀 手动执行一次测试（查看详细输出）："
echo "-----------------------------------"
echo "正在执行..."
docker exec trend-radar python -m trendradar 2>&1 | grep -E "(增量模式|新增新闻|匹配频率词|推送|通知)" | tail -20
echo ""

echo "💡 提示："
echo "   - 如果新增新闻不匹配关键词，说明新闻标题中确实不包含你配置的关键词"
echo "   - 可以尝试切换到 daily 模式查看所有匹配的新闻"
echo "   - 或者等待有包含关键词的新增新闻出现"
echo ""
