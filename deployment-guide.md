# 短途旅行项目云服务器部署方案

## 项目技术栈
- **后端**: Spring Boot 3.5.3 (Java 17)
- **前端**: Next.js 13 (React 18, TypeScript)
- **数据库**: PostgreSQL
- **缓存**: Redis
- **其他**: JWT认证、文件上传、地图服务、AI集成

---

## 方案一：经济型单服务器部署

### 服务器配置推荐
- **云服务商**: 阿里云ECS/腾讯云CVM/华为云ECS
- **配置**: 2核4GB内存，40GB系统盘
- **操作系统**: Ubuntu 20.04 LTS
- **预估成本**: 200-300元/月

### 部署步骤

#### 1. 服务器环境准备
```bash
# 更新系统
sudo apt update && sudo apt upgrade -y

# 安装Java 17
sudo apt install openjdk-17-jdk -y

# 安装Node.js 18
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 安装PostgreSQL
sudo apt install postgresql postgresql-contrib -y

# 安装Redis
sudo apt install redis-server -y

# 安装Nginx
sudo apt install nginx -y

# 安装Maven
sudo apt install maven -y
```

#### 2. 数据库配置
```bash
# 配置PostgreSQL
sudo -u postgres psql
CREATE DATABASE short_trip_db;
CREATE USER shorttrip WITH PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE short_trip_db TO shorttrip;
\q

# 配置Redis
sudo systemctl enable redis-server
sudo systemctl start redis-server
```

#### 3. 应用部署
```bash
# 创建应用目录
sudo mkdir -p /opt/short-trip
cd /opt/short-trip

# 上传项目文件（使用scp或git clone）
git clone your-repo-url .

# 后端部署
cd short-trip-background
mvn clean package -DskipTests
nohup java -jar target/short-trip-background-0.0.1-SNAPSHOT.jar > backend.log 2>&1 &

# 前端构建和部署
cd ../short-trip-front
npm install
npm run build
nohup npm start > frontend.log 2>&1 &
```

#### 4. Nginx配置
```nginx
# /etc/nginx/sites-available/short-trip
server {
    listen 80;
    server_name your-domain.com;

    # 前端
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # 后端API
    location /api/ {
        proxy_pass http://localhost:8080/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 优缺点
**优点**:
- 部署简单，成本最低
- 适合初期项目验证
- 维护简单

**缺点**:
- 单点故障风险
- 扩展性差
- 性能有限

---

## 方案二：Docker容器化部署

### 服务器配置推荐
- **配置**: 4核8GB内存，100GB系统盘
- **预估成本**: 500-800元/月

### 部署步骤

#### 1. 创建Dockerfile文件

**后端Dockerfile**:
```dockerfile
# short-trip-background/Dockerfile
FROM openjdk:17-jdk-slim

WORKDIR /app

COPY target/short-trip-background-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8080

ENV JAVA_OPTS="-Xmx1g -Xms512m"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
```

**前端Dockerfile**:
```dockerfile
# short-trip-front/Dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000

CMD ["npm", "start"]
```

#### 2. Docker Compose配置
```yaml
# docker-compose.yml
version: '3.8'

services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: short_trip_db
      POSTGRES_USER: shorttrip
      POSTGRES_PASSWORD: your_password
    volumes:
      - postgres_data:/var/lib/postgresql/data
      - ./short-trip-background/src/main/resources/db:/docker-entrypoint-initdb.d
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U shorttrip"]
      interval: 30s
      timeout: 10s
      retries: 3

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    ports:
      - "6379:6379"
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 30s
      timeout: 10s
      retries: 3

  backend:
    build: ./short-trip-background
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://postgres:5432/short_trip_db
      SPRING_DATASOURCE_USERNAME: shorttrip
      SPRING_DATASOURCE_PASSWORD: your_password
      SPRING_DATA_REDIS_HOST: redis
      SPRING_PROFILES_ACTIVE: production
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    ports:
      - "8080:8080"
    volumes:
      - ./uploads:/app/uploads
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build: ./short-trip-front
    environment:
      NEXT_PUBLIC_API_URL: http://your-domain.com/api
    depends_on:
      - backend
    ports:
      - "3000:3000"

  nginx:
    image: nginx:alpine
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    ports:
      - "80:80"
      - "443:443"
    depends_on:
      - frontend
      - backend

volumes:
  postgres_data:
  redis_data:
```

#### 3. 部署脚本
```bash
#!/bin/bash
# deploy.sh

echo "开始部署短途旅行项目..."

# 构建后端
cd short-trip-background
mvn clean package -DskipTests
cd ..

# 启动所有服务
docker-compose up -d

# 等待服务启动
echo "等待服务启动..."
sleep 30

# 健康检查
docker-compose ps
curl -f http://localhost:8080/api/health

echo "部署完成！"
echo "前端地址: http://localhost"
echo "后端API: http://localhost/api"
```

### 优缺点
**优点**:
- 环境一致性好
- 易于迁移和扩展
- 便于版本管理
- 资源隔离

**缺点**:
- 需要学习Docker知识
- 资源开销略大

---

## 方案三：负载均衡高可用部署

### 架构设计
```
Internet
    |
[负载均衡器]
    |
[前端集群] -- [后端集群]
    |             |
[PostgreSQL主从] [Redis集群]
```

### 服务器配置
- **负载均衡器**: 2核4GB × 1台
- **前端服务器**: 2核4GB × 2台
- **后端服务器**: 4核8GB × 2台
- **数据库服务器**: 8核16GB × 2台 (主从)
- **Redis服务器**: 4核8GB × 3台 (集群)
- **预估成本**: 2000-3000元/月

### 部署步骤

#### 1. 负载均衡配置 (Nginx)
```nginx
# /etc/nginx/nginx.conf
upstream frontend {
    server 10.0.1.10:3000;
    server 10.0.1.11:3000;
}

upstream backend {
    server 10.0.1.20:8080;
    server 10.0.1.21:8080;
}

server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://frontend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    location /api/ {
        proxy_pass http://backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

#### 2. 数据库主从配置
```sql
-- 主库配置
# postgresql.conf
wal_level = replica
max_wal_senders = 3
wal_keep_segments = 32

-- 从库配置
# recovery.conf
standby_mode = 'on'
primary_conninfo = 'host=master_ip port=5432 user=replicator'
```

#### 3. Redis集群配置
```bash
# Redis集群部署脚本
redis-cli --cluster create \
  10.0.1.30:6379 10.0.1.31:6379 10.0.1.32:6379 \
  --cluster-replicas 0
```

### 优缺点
**优点**:
- 高可用性
- 负载分担
- 性能优秀
- 可扩展

**缺点**:
- 成本较高
- 配置复杂
- 运维难度大

---

## 方案四：云原生Kubernetes部署

### 服务器配置
- **Master节点**: 4核8GB × 3台
- **Worker节点**: 8核16GB × 3台
- **预估成本**: 3000-5000元/月

### Kubernetes配置文件

#### 1. PostgreSQL部署
```yaml
# postgres-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:14
        env:
        - name: POSTGRES_DB
          value: short_trip_db
        - name: POSTGRES_USER
          value: shorttrip
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        ports:
        - containerPort: 5432
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  ports:
  - port: 5432
  selector:
    app: postgres
```

#### 2. 后端部署
```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: backend
        image: your-registry/short-trip-backend:latest
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: jdbc:postgresql://postgres-service:5432/short_trip_db
        - name: SPRING_DATA_REDIS_HOST
          value: redis-service
        livenessProbe:
          httpGet:
            path: /api/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /api/health
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  ports:
  - port: 8080
  selector:
    app: backend
```

#### 3. 前端部署
```yaml
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: your-registry/short-trip-frontend:latest
        ports:
        - containerPort: 3000
        env:
        - name: NEXT_PUBLIC_API_URL
          value: https://your-domain.com/api
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  ports:
  - port: 3000
  selector:
    app: frontend
```

#### 4. Ingress配置
```yaml
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: short-trip-ingress
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - your-domain.com
    secretName: short-trip-tls
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 3000
```

### 优缺点
**优点**:
- 自动扩缩容
- 服务发现
- 滚动更新
- 资源管理完善
- 企业级解决方案

**缺点**:
- 学习成本高
- 配置复杂
- 成本较高
- 需要专业运维

---

## 方案五：Serverless混合部署

### 架构设计
- **前端**: Vercel / Netlify
- **后端**: 阿里云函数计算 / 腾讯云云函数
- **数据库**: 云数据库 PostgreSQL
- **缓存**: 云 Redis
- **文件存储**: 对象存储 OSS

### 部署步骤

#### 1. 前端部署到Vercel
```json
// vercel.json
{
  "builds": [
    {
      "src": "package.json",
      "use": "@vercel/next"
    }
  ],
  "env": {
    "NEXT_PUBLIC_API_URL": "https://your-api-gateway.com"
  },
  "regions": ["sin1"]
}
```

#### 2. 后端改造为云函数
```java
// 云函数入口类
@Component
public class FunctionHandler implements StreamRequestHandler {
    
    @Autowired
    private ApplicationContext applicationContext;
    
    @Override
    public void handleRequest(InputStream input, OutputStream output, Context context) {
        // 处理HTTP请求
        try {
            // 解析请求
            String requestBody = IOUtils.toString(input, StandardCharsets.UTF_8);
            Map<String, Object> request = JSON.parseObject(requestBody, Map.class);
            
            // 路由到对应的Controller
            String path = (String) request.get("path");
            String method = (String) request.get("httpMethod");
            
            // 处理业务逻辑
            Object result = routeRequest(path, method, request);
            
            // 返回响应
            Map<String, Object> response = new HashMap<>();
            response.put("statusCode", 200);
            response.put("body", JSON.toJSONString(result));
            
            output.write(JSON.toJSONString(response).getBytes());
        } catch (Exception e) {
            // 错误处理
            logger.error("Function execution error", e);
        }
    }
}
```

#### 3. 数据库配置
```yaml
# serverless.yml
service: short-trip-backend

provider:
  name: aliyun
  runtime: java8
  region: cn-hangzhou

functions:
  api:
    handler: org.example.shorttrip.FunctionHandler
    events:
      - http:
          path: /{proxy+}
          method: ANY
    environment:
      SPRING_DATASOURCE_URL: jdbc:postgresql://your-rds-endpoint:5432/short_trip_db
      SPRING_DATA_REDIS_HOST: your-redis-endpoint

resources:
  Resources:
    Database:
      Type: ALIYUN::RDS::DBInstance
      Properties:
        Engine: PostgreSQL
        EngineVersion: '14.0'
        DBInstanceClass: rds.pg.s2.large
        
    Redis:
      Type: ALIYUN::REDIS::Instance  
      Properties:
        InstanceType: redis.master.small.default
```

### 优缺点
**优点**:
- 按需付费
- 自动扩缩容
- 运维成本低
- 全球CDN加速

**缺点**:
- 冷启动延迟
- 调试困难
- 厂商锁定
- 复杂查询性能限制

---

## 🎯 方案选择建议

### 初期项目 (< 1000用户)
**推荐**: 方案一 (经济型单服务器)
- 成本低，快速上线
- 验证产品可行性

### 成长期项目 (1000-10000用户)  
**推荐**: 方案二 (Docker容器化)
- 便于扩展和维护
- 成本可控

### 成熟期项目 (10000-100000用户)
**推荐**: 方案三 (负载均衡高可用)
- 高可用性保障
- 良好的性能表现

### 大型项目 (> 100000用户)
**推荐**: 方案四 (Kubernetes) 或方案五 (Serverless)
- 根据团队技术栈选择
- 考虑运维成本和复杂度

---

## 📋 部署前检查清单

### 安全配置
- [ ] SSL证书配置
- [ ] 防火墙规则设置  
- [ ] 数据库访问控制
- [ ] API限流配置
- [ ] 日志记录和监控

### 性能优化
- [ ] 数据库索引优化
- [ ] Redis缓存策略
- [ ] CDN加速配置
- [ ] 图片压缩优化
- [ ] 代码分割和懒加载

### 备份策略
- [ ] 数据库定期备份
- [ ] 文件存储备份
- [ ] 配置文件备份
- [ ] 恢复流程测试

### 监控告警
- [ ] 服务器资源监控
- [ ] 应用性能监控
- [ ] 错误日志告警
- [ ] 业务指标监控

需要我为您详细展开某个方案的具体实施步骤吗？或者您有特定的需求和约束条件需要考虑？ 