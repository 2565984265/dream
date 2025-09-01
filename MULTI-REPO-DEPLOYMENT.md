# 短途旅行项目 - 多仓库部署指南

## 🎯 项目架构

您的项目采用多仓库架构，包含三个独立的Git仓库：

### 📂 仓库结构
```
短途旅行项目
├── 主仓库 (dream)
│   ├── 部署脚本
│   ├── 配置文件
│   ├── 文档
│   └── Docker配置
├── 后端仓库 (short-trip-background)
│   ├── Spring Boot应用
│   ├── Java源码
│   ├── Maven配置
│   └── 数据库脚本
└── 前端仓库 (short-trip-front)
    ├── Next.js应用
    ├── React组件
    ├── TypeScript源码
    └── 样式文件
```

### 🔗 仓库地址
- **主仓库**: https://github.com/2565984265/dream.git
- **后端仓库**: https://github.com/2565984265/short-trip-background.git  
- **前端仓库**: https://github.com/2565984265/short-trip-front.git

## 🚀 一键部署

### 使用多仓库部署脚本
```bash
# 使用默认仓库地址部署
./multi-repo-deploy.sh

# 查看帮助信息
./multi-repo-deploy.sh --help
```

### 自定义仓库地址（如果需要）
```bash
# 自定义仓库地址
MAIN_REPO="https://github.com/yourusername/dream.git" \
BACKEND_REPO="https://github.com/yourusername/backend.git" \
FRONTEND_REPO="https://github.com/yourusername/frontend.git" \
./multi-repo-deploy.sh
```

## 🎛️ 部署过程

部署脚本会自动执行以下步骤：

### 1. 环境检查
- ✅ 检查系统资源（内存、磁盘）
- ✅ 检查依赖软件（Docker、Git）
- ✅ 自动安装缺失依赖

### 2. 系统优化
- ✅ 创建Swap分区（2GB）
- ✅ 优化内存设置
- ✅ 停止不必要服务

### 3. 代码获取
- ✅ 克隆主仓库（包含部署配置）
- ✅ 克隆后端仓库到 `short-trip-background/`
- ✅ 克隆前端仓库到 `short-trip-front/`

### 4. 应用构建
- ✅ 构建后端Java应用
- ✅ 构建前端Next.js应用
- ✅ 创建Docker镜像

### 5. 服务启动
- ✅ 启动PostgreSQL数据库
- ✅ 启动Redis缓存
- ✅ 启动后端API服务
- ✅ 启动前端Web服务
- ✅ 启动Nginx反向代理

## 🗄️ 数据库信息

部署完成后的数据库连接信息：

### 📊 连接参数
- **主机**: localhost
- **端口**: 5432
- **数据库**: short_trip_db
- **用户**: shorttrip
- **密码**: shorttrip@2024

### 🔗 连接方式
```bash
# 1. 使用管理脚本连接（推荐）
cd /opt/short-trip
./connect-db.sh connect

# 2. 直接psql连接
psql -h localhost -p 5432 -U shorttrip -d short_trip_db

# 3. Docker内部连接
docker-compose -f docker-compose-2g.yml exec postgres psql -U shorttrip -d short_trip_db

# 4. JDBC连接字符串
jdbc:postgresql://localhost:5432/short_trip_db
```

## 🛠️ 多仓库管理

部署完成后会创建以下管理脚本：

### 📋 核心管理脚本

| 脚本名称 | 功能描述 | 使用方法 |
|---------|---------|---------|
| `update-repos.sh` | 更新所有仓库代码并重新部署 | `./update-repos.sh` |
| `check-repos.sh` | 检查仓库状态和分支信息 | `./check-repos.sh` |
| `connect-db.sh` | 数据库连接管理 | `./connect-db.sh connect` |
| `insert-sample-data.sh` | 插入示例数据 | `./insert-sample-data.sh` |
| `backup-database.sh` | 数据库备份 | `./backup-database.sh` |

### 🔄 日常维护命令

```bash
# 进入部署目录
cd /opt/short-trip

# 检查所有仓库状态
./check-repos.sh

# 更新所有仓库并重新部署
./update-repos.sh

# 查看Docker服务状态
docker-compose -f docker-compose-2g.yml ps

# 查看服务日志
docker-compose -f docker-compose-2g.yml logs -f [service_name]

# 重启特定服务
docker-compose -f docker-compose-2g.yml restart [service_name]

# 停止所有服务
docker-compose -f docker-compose-2g.yml down

# 清理Docker资源
docker system prune -af
```

## 📱 访问地址

部署成功后的访问地址：

- **前端网站**: http://localhost
- **后端API**: http://localhost/api  
- **API文档**: http://localhost/api/swagger-ui.html
- **健康检查**: http://localhost/api/health

## 🔧 多仓库开发工作流

### 1. 代码开发
```bash
# 后端开发
cd /opt/short-trip/short-trip-background
git checkout -b feature/new-feature
# 进行开发...
git add .
git commit -m "feat: add new feature"
git push origin feature/new-feature

# 前端开发  
cd /opt/short-trip/short-trip-front
git checkout -b feature/ui-update
# 进行开发...
git add .
git commit -m "feat: update UI"
git push origin feature/ui-update
```

### 2. 代码更新部署
```bash
# 更新特定仓库
cd /opt/short-trip/short-trip-background
git pull origin main

# 或者更新所有仓库并重新部署
cd /opt/short-trip
./update-repos.sh
```

### 3. 配置文件更新
```bash
# 更新主仓库中的部署配置
cd /opt/short-trip
git pull origin main

# 重新应用配置
docker-compose -f docker-compose-2g.yml down
docker-compose -f docker-compose-2g.yml up -d
```

## 📊 资源监控

### 系统资源监控
```bash
# 查看内存使用
free -h

# 查看磁盘使用
df -h

# 查看Docker容器资源使用
docker stats

# 查看具体服务资源使用
docker stats --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

### 应用监控
```bash
# 查看应用日志
cd /opt/short-trip

# 后端日志
docker-compose -f docker-compose-2g.yml logs -f backend

# 前端日志  
docker-compose -f docker-compose-2g.yml logs -f frontend

# 数据库日志
docker-compose -f docker-compose-2g.yml logs -f postgres

# 所有服务日志
docker-compose -f docker-compose-2g.yml logs -f
```

## 🚨 故障排除

### 常见问题及解决方案

#### 1. 内存不足
```bash
# 检查内存使用
free -h

# 清理系统缓存
sudo sync && echo 1 | sudo tee /proc/sys/vm/drop_caches

# 重启服务释放内存
cd /opt/short-trip
docker-compose -f docker-compose-2g.yml restart
```

#### 2. 磁盘空间不足
```bash
# 检查磁盘使用
df -h

# 清理Docker资源
docker system prune -af --volumes

# 清理旧的备份文件
cd /opt/short-trip
rm -rf backups/*.sql

# 清理日志文件
docker-compose -f docker-compose-2g.yml down
rm -rf logs/*
docker-compose -f docker-compose-2g.yml up -d
```

#### 3. 服务启动失败
```bash
# 查看服务状态
cd /opt/short-trip
docker-compose -f docker-compose-2g.yml ps

# 查看错误日志
docker-compose -f docker-compose-2g.yml logs [service_name]

# 重建服务
docker-compose -f docker-compose-2g.yml down
docker-compose -f docker-compose-2g.yml up -d --build
```

#### 4. 代码更新失败
```bash
# 检查Git状态
cd /opt/short-trip
./check-repos.sh

# 手动更新仓库
cd short-trip-background
git stash  # 保存本地改动
git pull origin main
git stash pop  # 恢复本地改动

# 重新构建
./update-repos.sh
```

## 🔐 安全配置

### 1. 数据库安全
```bash
# 修改数据库密码
cd /opt/short-trip
# 编辑 .env 文件修改 DB_PASSWORD
# 然后重启服务
docker-compose -f docker-compose-2g.yml down
docker-compose -f docker-compose-2g.yml up -d
```

### 2. 防火墙配置
```bash
# 只允许必要端口
sudo ufw enable
sudo ufw allow 80/tcp    # HTTP
sudo ufw allow 443/tcp   # HTTPS
sudo ufw allow 22/tcp    # SSH
```

### 3. SSL证书配置
```bash
# 使用Let's Encrypt获取SSL证书
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d your-domain.com
```

## 📋 备份策略

### 1. 数据库备份
```bash
# 手动备份
cd /opt/short-trip
./backup-database.sh

# 设置定时备份
crontab -e
# 添加以下行（每天凌晨2点备份）
0 2 * * * cd /opt/short-trip && ./backup-database.sh
```

### 2. 代码备份
```bash
# 各仓库都已托管在GitHub，代码安全有保障
# 可以定期创建release版本

# 备份部署配置
cd /opt/short-trip
tar -czf config-backup-$(date +%Y%m%d).tar.gz .env *.yml *.sh
```

## 🎯 最佳实践

### 1. 开发流程
- ✅ 使用Git Flow工作流
- ✅ 各仓库独立开发和测试
- ✅ 定期合并主分支更新
- ✅ 生产部署前充分测试

### 2. 部署管理
- ✅ 定期备份数据库和配置
- ✅ 监控系统资源使用
- ✅ 及时更新依赖和安全补丁
- ✅ 保持代码仓库同步

### 3. 扩展建议
- 🔄 设置CI/CD流水线
- 📊 添加应用性能监控
- 🔔 配置告警通知系统
- 📈 考虑负载均衡部署

---

## 📞 技术支持

如遇到问题：
1. 首先运行 `./check-repos.sh` 检查状态
2. 查看相关服务日志
3. 参考故障排除章节
4. 检查GitHub仓库是否正常

多仓库架构为您的项目提供了更好的可维护性和扩展性！🎉 