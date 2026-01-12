# 推送问题解决方案

## 问题分析

**当前状态：**
- ✅ 服务已启动
- ✅ 通知功能已启用  
- ✅ Bark 通知渠道已配置
- ✅ 关键词已正确加载（包括新增的黄金、白银、铜、铝等）
- ❌ **增量模式下，新增的新闻不包含关键词，所以没有推送**

## 解决方案

### 方案 1：切换到 daily 模式（推荐）

**daily 模式特点：**
- 推送所有匹配关键词的新闻（不限于新增）
- 按时推送（默认每小时一次）
- 适合想要全面了解当日热点的场景

**修改方法：**

1. **方法 A：通过环境变量（推荐）**
   
   编辑 `docker/.env` 文件，添加或修改：
   ```bash
   REPORT_MODE=daily
   ```
   
   然后重启容器：
   ```bash
   docker compose restart trend-radar
   ```

2. **方法 B：修改配置文件**
   
   编辑 `config/config.yaml`，修改：
   ```yaml
   report:
     mode: "daily"  # 从 "incremental" 改为 "daily"
   ```
   
   然后重启容器：
   ```bash
   docker compose restart trend-radar
   ```

### 方案 2：切换到 current 模式

**current 模式特点：**
- 推送当前榜单中匹配关键词的新闻
- 按时推送（默认每小时一次）
- 适合想要实时了解当前热点的场景

**修改方法：**
```bash
# 在 docker/.env 中设置
REPORT_MODE=current
```

### 方案 3：继续使用 incremental 模式

**incremental 模式特点：**
- 只推送新增且匹配关键词的新闻
- 有新增才推送
- 适合避免重复信息干扰的场景

**注意事项：**
- 如果新增的新闻不包含关键词，就不会推送
- 需要等待有包含关键词的新增新闻出现

## 验证修改

修改后，查看日志确认：
```bash
docker logs -f trend-radar
```

应该能看到：
- `报告模式: daily` 或 `报告模式: current`
- 匹配关键词的新闻会被推送

## 快速诊断命令

```bash
# 检查当前模式
docker exec trend-radar printenv REPORT_MODE

# 查看最近日志
docker logs trend-radar --tail 50

# 手动执行一次测试
docker exec trend-radar python -m trendradar
```
