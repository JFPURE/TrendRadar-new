# Docker 部署

本目录包含 TrendRadar 项目的 Docker 部署相关文件。

## 📁 文件说明

- `Dockerfile` - Docker 镜像构建文件（新闻推送服务）
- `Dockerfile.mcp` - Docker 镜像构建文件（MCP AI 分析服务）
- `docker-compose.yml` - Docker Compose 配置（使用预构建镜像）
- `docker-compose-build.yml` - Docker Compose 配置（本地构建镜像）
- `entrypoint.sh` - 容器启动脚本
- `manage.py` - 容器内管理工具
- `env.example` - 环境变量配置模板
- `quick-start.sh` - 快速启动脚本
- `DOCKER-DEPLOY.md` - 完整部署指南

## 🚀 快速开始

### 方式一：使用快速启动脚本（推荐）

```bash
cd docker
./quick-start.sh
```

脚本会自动：

- 检查 Docker 环境
- 创建 `.env` 配置文件
- 拉取最新镜像
- 启动服务

### 方式二：手动部署

```bash
# 1. 进入 docker 目录
cd docker

# 2. 复制环境变量模板
cp env.example .env

# 3. 编辑配置文件
vim .env  # 配置你的通知渠道等

# 4. 启动服务
docker compose pull
docker compose up -d

# 5. 查看日志
docker logs -f trend-radar
```

## 📖 详细文档

完整的部署指南请查看：[DOCKER-DEPLOY.md](./DOCKER-DEPLOY.md)

## 🔧 常用命令

```bash
# 查看服务状态
docker compose ps

# 查看日志
docker logs -f trend-radar

# 停止服务
docker compose stop

# 重启服务
docker compose restart trend-radar

# 进入容器
docker exec -it trend-radar bash

# 容器内管理工具
docker exec -it trend-radar python manage.py status
docker exec -it trend-radar python manage.py run
docker exec -it trend-radar python manage.py help
```

## 📝 配置说明

### 必需配置文件

1. `../config/config.yaml` - 应用主配置
2. `../config/frequency_words.txt` - 关键词配置
3. `.env` - 环境变量配置（从 `env.example` 复制）

### 目录结构

```
项目根目录/
├── config/
│   ├── config.yaml
│   └── frequency_words.txt
└── docker/
    ├── .env              # 环境变量（需创建）
    └── docker-compose.yml
```

## 🍎 macOS 用户特别说明

**MacBook 合盖后服务会停止？**

MacBook 合盖后，如果没有外接设备，系统会进入睡眠模式，Docker 服务会暂停。

**解决方案：**

1. **使用辅助脚本**（推荐）：

   ```bash
   ./macos-helper.sh prevent-sleep  # 防止睡眠
   ./macos-helper.sh status          # 查看状态
   ```

2. **使用合盖模式**：

   - 连接外接显示器、键盘和鼠标
   - 合上 MacBook 盖子
   - 系统会继续运行

3. **部署到云服务器**（最佳实践）：
   - 7x24 小时稳定运行
   - 不受本地电脑状态影响

详细说明请查看：[DOCKER-DEPLOY.md](./DOCKER-DEPLOY.md#7-macos-合盖后服务停止)

## 🆘 获取帮助

- 查看完整部署指南：`DOCKER-DEPLOY.md`
- 查看项目主文档：`../README.md`
- 提交 Issue：https://github.com/sansan0/TrendRadar/issues
