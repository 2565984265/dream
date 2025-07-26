# 短途旅行项目 - 2GB内存Docker部署指南

## 🎯 适用场景

本部署方案专门针对 **2核2GB内存40GB硬盘** 的云服务器配置进行优化，适用于：

- 个人项目或小型团队
- 初期产品验证
- 预算有限的部署需求
- 学习和测试环境

## ⚠️ 重要提醒

**内存使用紧张**：2GB内存刚好满足运行需求，建议：
- 关闭不必要的系统服务
- 定期监控内存使用情况
- 考虑添加 swap 分区作为缓冲
- 生产环境建议升级到4GB内存

## 📋 系统要求

### 最低配置
- **CPU**: 2核
- **内存**: 2GB
- **硬盘**: 40GB
- **操作系统**: Ubuntu 20.04 LTS (推荐)

### 软件要求
- Docker 20.10+
- Docker Compose 2.0+
- Git
- Curl

## 🚀 快速部署

### 1. 环境准备

```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# 安装Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 重新登录以应用用户组变更
newgrp docker
```

### 2. 克隆项目

```bash
git clone <your-repo-url>
cd dream
```

### 3. 一键部署

```bash
# 赋予执行权限
chmod +x deploy-2g.sh

# 执行部署脚本
./deploy-2g.sh
```

## 📊 资源分配策略

### 内存分配 (总计 ~1.85GB)
```
PostgreSQL: 400MB (最大)
Redis:       100MB (最大)
后端服务:    900MB (最大)
前端服务:    400MB (最大)
Nginx:       50MB  (最大)
```

### 硬盘使用 (预估)
```
操作系统:     ~8GB
Docker镜像:   ~2GB
数据库数据:   ~5GB (增长)
日志文件:     ~1GB
文件上传:     ~5GB (增长)
系统缓存:     ~2GB
预留空间:     ~17GB
```

## 🔧 手动部署步骤

如果自动部署脚本失败，可按以下步骤手动部署：

### 1. 构建后端

```bash
cd short-trip-background
./mvnw clean package -DskipTests
cd ..
```

### 2. 启动服务

```bash
# 创建必要目录
mkdir -p uploads logs

# 启动所有服务
docker-compose -f docker-compose-2g.yml up -d
```

### 3. 验证服务

```bash
# 检查服务状态
docker-compose -f docker-compose-2g.yml ps

# 查看日志
docker-compose -f docker-compose-2g.yml logs -f
```

## 📈 监控和维护

### 监控脚本

```bash
# 查看实时监控
./monitor.sh

# 查看服务状态
docker-compose -f docker-compose-2g.yml ps

# 查看资源使用
docker stats
```

### 常用命令

```bash
# 重启服务
docker-compose -f docker-compose-2g.yml restart [service_name]

# 查看日志
docker-compose -f docker-compose-2g.yml logs -f [service_name]

# 停止服务
docker-compose -f docker-compose-2g.yml down

# 清理资源
docker system prune -af
```

## 🎛️ 配置调优

### 内存不足时的优化建议

1. **增加swap分区**
```bash
# 创建2GB swap文件
sudo fallocate -l 2G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# 永久启用
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
```

2. **关闭不必要服务**
```bash
# 停止不必要的系统服务
sudo systemctl disable snapd
sudo systemctl stop snapd
```

3. **调整JVM参数**
```bash
# 修改 .env 文件中的 JAVA_OPTS
JAVA_OPTS=-Xmx600m -Xms300m -XX:+UseG1GC
```

### 性能优化建议

1. **数据库优化**
   - 定期清理日志表
   - 优化查询索引
   - 限制连接池大小

2. **缓存策略**
   - 启用Redis缓存
   - 设置合理的过期时间
   - 定期清理过期数据

3. **前端优化**
   - 启用Gzip压缩
   - 使用CDN加速静态资源
   - 代码分割和懒加载

## 🚨 故障排除

### 常见问题

1. **内存不足导致容器重启**
```bash
# 检查内存使用
free -h
docker stats

# 解决方案：降低容器内存限制或添加swap
```

2. **磁盘空间不足**
```bash
# 清理Docker资源
docker system prune -af --volumes

# 检查磁盘使用
df -h
du -sh /var/lib/docker
```

3. **服务启动失败**
```bash
# 查看详细日志
docker-compose -f docker-compose-2g.yml logs [service_name]

# 重建服务
docker-compose -f docker-compose-2g.yml up --build -d
```

### 应急处理

1. **系统负载过高**
```bash
# 临时降低服务副本数
docker-compose -f docker-compose-2g.yml scale backend=1

# 重启服务
docker-compose -f docker-compose-2g.yml restart
```

2. **数据库连接问题**
```bash
# 检查数据库状态
docker-compose -f docker-compose-2g.yml exec postgres pg_isready

# 重启数据库
docker-compose -f docker-compose-2g.yml restart postgres
```

## 📝 注意事项

1. **内存监控**：定期检查内存使用，避免OOM
2. **日志管理**：定期清理日志文件，防止占满磁盘
3. **备份策略**：定期备份数据库和文件
4. **安全更新**：及时更新系统和Docker镜像
5. **监控告警**：建议配置监控告警系统

## 🔄 升级建议

当项目发展到一定规模时，建议升级配置：

- **4GB内存**：可以更稳定运行，减少OOM风险
- **80GB硬盘**：为数据增长和日志留足空间
- **负载均衡**：多实例部署提高可用性

## 📞 技术支持

如遇到部署问题，请检查：
1. 系统资源是否充足
2. Docker服务是否正常
3. 网络连接是否正常
4. 配置文件是否正确

通过监控脚本定期检查系统状态，确保服务稳定运行。 