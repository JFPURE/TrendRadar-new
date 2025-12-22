# Docker 部署指南

本文档提供 TrendRadar 项目的 Docker 部署完整指南。

## 📋 目录

- [快速开始](#快速开始)
- [前置要求](#前置要求)
- [部署方式](#部署方式)
- [配置说明](#配置说明)
- [服务管理](#服务管理)
- [常见问题](#常见问题)

## 🚀 快速开始

### 方式一：使用快速启动脚本（最简单）

```bash
# 1. 克隆项目
git clone https://github.com/sansan0/TrendRadar.git
cd TrendRadar

# 2. 进入 docker 目录并运行快速启动脚本
cd docker
./quick-start.sh
```

脚本会自动完成所有配置和启动步骤。

### 方式二：使用预构建镜像（手动）

```bash
# 1. 克隆项目
git clone https://github.com/sansan0/TrendRadar.git
cd TrendRadar

# 2. 进入 docker 目录
cd docker

# 3. 复制环境变量模板并编辑
cp env.example .env
vim .env  # 根据需要修改配置

# 4. 启动服务
docker compose pull
docker compose up -d

# 5. 查看日志
docker logs -f trend-radar
```

### 方式二：本地构建镜像

```bash
# 1. 克隆项目
git clone https://github.com/sansan0/TrendRadar.git
cd TrendRadar

# 2. 进入 docker 目录
cd docker

# 3. 使用构建版本的 compose 文件
cp docker-compose-build.yml docker-compose.yml

# 4. 复制环境变量模板并编辑
cp env.example .env
vim .env  # 根据需要修改配置

# 5. 构建并启动
docker compose build
docker compose up -d
```

## 📦 前置要求

- Docker Engine 20.10+ 或 Docker Desktop
- Docker Compose 2.0+
- 至少 1GB 可用磁盘空间
- 网络连接（用于拉取镜像和爬取新闻）

## 🐳 部署方式

### 镜像说明

TrendRadar 提供两个独立的 Docker 镜像：

| 镜像名称                 | 用途         | 说明                              |
| ------------------------ | ------------ | --------------------------------- |
| `wantcat/trendradar`     | 新闻推送服务 | 定时抓取新闻、推送通知（必选）    |
| `wantcat/trendradar-mcp` | AI 分析服务  | MCP 协议支持、AI 对话分析（可选） |

### 启动选项

**选项 A：启动所有服务（推送 + AI 分析）**

```bash
docker compose up -d
```

**选项 B：仅启动新闻推送服务**

```bash
docker compose up -d trend-radar
```

**选项 C：仅启动 MCP AI 分析服务**

```bash
docker compose up -d trend-radar-mcp
```

> 💡 **提示**：
>
> - 大多数用户只需启动 `trend-radar` 即可实现新闻推送功能
> - 只有需要使用 Claude/ChatGPT 进行 AI 对话分析时，才需启动 `trend-radar-mcp`
> - 两个服务相互独立，可根据需求灵活组合

## ⚙️ 配置说明

### 目录结构

Docker 部署需要的关键目录结构：

```
项目根目录/
├── config/
│   ├── config.yaml          # 应用主配置
│   └── frequency_words.txt  # 关键词配置
└── docker/
    ├── .env                 # 环境变量配置
    ├── docker-compose.yml   # Docker Compose 配置
    └── DOCKER-DEPLOY.md     # 本文档
```

### 配置文件

1. **config/config.yaml** - 应用主配置

   - 报告模式（daily/incremental/current）
   - 推送设置
   - 通知渠道配置
   - 存储配置

2. **config/frequency_words.txt** - 关键词配置

   - 设置你关心的热点词汇
   - 每行一个关键词

3. **docker/.env** - 环境变量配置
   - Webhook URLs（飞书、钉钉、Telegram 等）
   - 定时任务配置（CRON_SCHEDULE）
   - 其他运行时配置

### 环境变量覆盖机制

如果修改 `config.yaml` 后配置不生效，可以通过环境变量直接覆盖：

| 环境变量                   | 对应配置                                    | 示例值                              | 说明                          |
| -------------------------- | ------------------------------------------- | ----------------------------------- | ----------------------------- |
| `ENABLE_CRAWLER`           | `crawler.enable_crawler`                    | `true` / `false`                    | 是否启用爬虫                  |
| `ENABLE_NOTIFICATION`      | `notification.enable_notification`          | `true` / `false`                    | 是否启用通知                  |
| `REPORT_MODE`              | `report.mode`                               | `daily` / `incremental` / `current` | 报告模式                      |
| `MAX_ACCOUNTS_PER_CHANNEL` | `notification.max_accounts_per_channel`     | `3`                                 | 每个渠道最大账号数            |
| `PUSH_WINDOW_ENABLED`      | `notification.push_window.enabled`          | `true` / `false`                    | 推送时间窗口开关              |
| `PUSH_WINDOW_START`        | `notification.push_window.time_range.start` | `08:00`                             | 推送开始时间                  |
| `PUSH_WINDOW_END`          | `notification.push_window.time_range.end`   | `22:00`                             | 推送结束时间                  |
| `ENABLE_WEBSERVER`         | -                                           | `true` / `false`                    | 是否自动启动 Web 服务器       |
| `WEBSERVER_PORT`           | -                                           | `8080`                              | Web 服务器端口                |
| `CRON_SCHEDULE`            | -                                           | `*/30 * * * *`                      | Cron 表达式（默认每 30 分钟） |
| `RUN_MODE`                 | -                                           | `cron` / `once`                     | 运行模式                      |
| `IMMEDIATE_RUN`            | -                                           | `true` / `false`                    | 启动时是否立即执行一次        |

**配置优先级**：环境变量 > config.yaml

### 通知渠道配置

在 `.env` 文件中配置通知渠道：

```bash
# 飞书 Webhook（多账号用 ; 分隔）
FEISHU_WEBHOOK_URL=https://open.feishu.cn/open-apis/bot/v2/hook/xxx

# 钉钉 Webhook（多账号用 ; 分隔）
DINGTALK_WEBHOOK_URL=https://oapi.dingtalk.com/robot/send?access_token=xxx

# Telegram Bot（多账号用 ; 分隔）
TELEGRAM_BOT_TOKEN=123456789:ABCdefGHIjklMNOpqrsTUVwxyz
TELEGRAM_CHAT_ID=123456789

# 企业微信 Webhook
WEWORK_WEBHOOK_URL=https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx
WEWORK_MSG_TYPE=markdown

# 邮件配置
EMAIL_FROM=your_email@example.com
EMAIL_PASSWORD=your_password_or_app_password
EMAIL_TO=recipient@example.com
EMAIL_SMTP_SERVER=smtp.example.com
EMAIL_SMTP_PORT=587

# 其他通知渠道...
```

## 🔧 服务管理

### 查看服务状态

```bash
# 查看所有容器状态
docker ps | grep trend-radar

# 查看新闻推送服务日志
docker logs -f trend-radar

# 查看 MCP AI 分析服务日志
docker logs -f trend-radar-mcp

# 查看容器内状态（进入容器）
docker exec -it trend-radar python manage.py status
```

### 容器管理命令

```bash
# 启动服务
docker compose up -d

# 停止服务
docker compose stop trend-radar
docker compose stop trend-radar-mcp

# 重启服务
docker compose restart trend-radar

# 停止并删除容器
docker compose down

# 停止并删除容器和卷（⚠️ 会删除数据）
docker compose down -v
```

### 容器内管理工具

进入容器后可以使用 `manage.py` 工具：

```bash
# 进入容器
docker exec -it trend-radar bash

# 手动执行一次爬虫
python manage.py run

# 查看容器状态
python manage.py status

# 查看当前配置
python manage.py config

# 查看输出文件
python manage.py files

# 启动 Web 服务器（如果未自动启动）
python manage.py start_webserver

# 停止 Web 服务器
python manage.py stop_webserver

# 查看 Web 服务器状态
python manage.py webserver_status

# 查看帮助
python manage.py help
```

### Web 服务器访问

如果启用了 Web 服务器（`ENABLE_WEBSERVER=true`），可以通过以下方式访问：

- 本地访问：`http://localhost:8080`
- 首页：`http://localhost:8080/index.html`
- 查看报告：`http://localhost:8080/2025年11月05日/html/`

> 💡 注意：默认端口映射为 `127.0.0.1:8080:8080`，仅允许本地访问。如需外部访问，请修改 `docker-compose.yml` 中的端口映射。

## 🔄 镜像更新

```bash
# 方式一：使用 docker compose 更新
docker compose pull
docker compose up -d

# 方式二：手动更新
docker pull wantcat/trendradar:latest
docker pull wantcat/trendradar-mcp:latest
docker compose down
docker compose up -d
```

## 📊 数据存储

### 本地存储

数据默认存储在 `output/` 目录，通过 Docker Volume 挂载：

```yaml
volumes:
  - ../output:/app/output
```

### 远程存储（可选）

支持 S3 兼容协议的云存储（Cloudflare R2、阿里云 OSS、腾讯云 COS 等）：

在 `.env` 文件中配置：

```bash
# 存储后端选择：local / remote / auto
STORAGE_BACKEND=auto

# S3 配置
S3_ENDPOINT_URL=https://xxx.r2.cloudflarestorage.com
S3_BUCKET_NAME=your-bucket-name
S3_ACCESS_KEY_ID=your-access-key-id
S3_SECRET_ACCESS_KEY=your-secret-access-key
S3_REGION=auto

# 数据保留天数（0 = 不清理）
LOCAL_RETENTION_DAYS=0
REMOTE_RETENTION_DAYS=0
```

## ❓ 常见问题

### 修改了 docker/.env 配置后不生效

**原因** docker compose restart 只重启容器，不会重新读取 .env 文件中的环境变量。

**解决方案**：
cd docker
docker compose down
docker compose up -d trend-radar

### or

cd docker
docker compose up -d --force-recreate trend-radar

### 1. 配置文件修改后不生效

**问题**：修改 `config.yaml` 后配置没有生效

**解决方案**：

- 使用环境变量覆盖配置（推荐）
- 确保配置文件路径正确：`config/config.yaml`
- 重启容器：`docker compose restart trend-radar`

### 2. 容器启动失败

**问题**：容器无法启动或立即退出

**排查步骤**：

```bash
# 查看容器日志
docker logs trend-radar

# 检查配置文件是否存在
docker exec -it trend-radar ls -la /app/config/

# 检查容器状态
docker exec -it trend-radar python manage.py status
```

### 3. 定时任务不执行

**问题**：配置了定时任务但没有执行

**排查步骤**：

```bash
# 检查 cron 配置
docker exec -it trend-radar python manage.py status

# 检查时区设置
docker exec -it trend-radar date

# 手动执行测试
docker exec -it trend-radar python manage.py run
```

### 4. Web 服务器无法访问

**问题**：启用了 Web 服务器但无法访问

**排查步骤**：

```bash
# 检查 Web 服务器状态
docker exec -it trend-radar python manage.py webserver_status

# 检查端口映射
docker ps | grep trend-radar

# 检查防火墙设置
# 确保端口 8080 已开放
```

### 5. 数据丢失

**问题**：重启容器后数据丢失

**原因**：数据存储在容器内，未挂载 Volume

**解决方案**：

- 确保 `docker-compose.yml` 中配置了 Volume 挂载
- 检查 `output/` 目录权限
- 使用远程存储备份数据

### 6. 网络连接问题

**问题**：无法拉取镜像或爬取新闻失败

**解决方案**：

- 检查网络连接
- 配置代理（在 `config.yaml` 中设置 `crawler.use_proxy`）
- 使用国内镜像源（如阿里云、腾讯云）

### 7. macOS 合盖后服务停止

**问题**：在 MacBook 上运行 Docker，合上笔记本后服务停止

**原因**：

- MacBook 合盖后，如果没有外接显示器/键盘/鼠标，系统会进入睡眠模式
- 睡眠模式下，所有进程（包括 Docker）都会暂停
- Docker 容器和定时任务都会停止运行

**解决方案**：

**方案 A：使用外接设备（合盖模式）** ⭐ 推荐

```bash
# 1. 连接外接显示器、键盘和鼠标
# 2. 合上 MacBook 盖子
# 3. MacBook 会进入"合盖模式"（Clamshell Mode），系统继续运行
# 4. Docker 服务会继续正常工作
```

**方案 B：防止系统睡眠**

使用 `caffeinate` 命令防止系统睡眠：

```bash
# 防止系统睡眠（直到手动停止）
caffeinate -d

# 或者防止系统睡眠，但允许显示器关闭
caffeinate -i

# 在后台运行，并记录 PID
caffeinate -d &
echo $! > /tmp/caffeinate.pid

# 停止防止睡眠
kill $(cat /tmp/caffeinate.pid)
```

**方案 C：使用远程服务器** ⭐ 最佳实践

对于需要 7x24 小时运行的服务，建议部署在：

- 云服务器（阿里云、腾讯云、AWS 等）
- 家庭 NAS（群晖、威联通等）
- 树莓派或其他小型服务器
- VPS（Vultr、DigitalOcean 等）

**方案 D：使用 macOS 系统设置**

1. 打开"系统设置" → "电池"
2. 设置"当显示器关闭时，防止电脑自动进入睡眠"
3. 或者使用第三方工具如 `Amphetamine`、`KeepingYouAwake` 等

**方案 E：使用 Docker Desktop 设置**

Docker Desktop 本身不支持在睡眠模式下运行，但可以：

1. 确保 Docker Desktop 设置为"开机启动"
2. 使用外接设备进入合盖模式
3. 或使用 `caffeinate` 防止睡眠

**方案 F：使用 macOS 辅助脚本** ⭐ 便捷工具

项目提供了 macOS 专用辅助脚本：

```bash
cd docker
./macos-helper.sh prevent-sleep  # 防止睡眠
./macos-helper.sh allow-sleep    # 允许睡眠
./macos-helper.sh status          # 查看状态
./macos-helper.sh check-setup     # 检查 Docker 设置
```

**注意事项**：

- ⚠️ 长期防止睡眠会消耗电池（如果使用电池供电）
- ⚠️ 建议连接电源适配器
- ⚠️ 合盖模式下注意散热，确保通风良好
- 💡 对于生产环境，强烈建议使用云服务器或专用服务器

## 📚 更多资源

- [项目 README](../README.md)
- [配置文件说明](../config/config.yaml)
- [GitHub Issues](https://github.com/sansan0/TrendRadar/issues)

## 🆘 获取帮助

如果遇到问题，可以通过以下方式获取帮助：

1. 查看容器日志：`docker logs trend-radar`
2. 查看项目 Issues：https://github.com/sansan0/TrendRadar/issues
3. 提交新 Issue 描述问题

---

**祝部署顺利！** 🎉
