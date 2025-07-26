# 数据库连接和使用指南

## 📊 数据库连接信息

### 基本信息
- **数据库类型**: PostgreSQL 14
- **主机地址**: localhost
- **端口**: 5432
- **数据库名**: short_trip_db
- **用户名**: shorttrip
- **密码**: shorttrip@2024

### 连接字符串
```bash
# JDBC URL
jdbc:postgresql://localhost:5432/short_trip_db

# psql 命令行连接
psql -h localhost -p 5432 -U shorttrip -d short_trip_db

# Docker 内部连接
docker-compose -f docker-compose-2g.yml exec postgres psql -U shorttrip -d short_trip_db
```

## 🔧 连接方式

### 1. 使用提供的脚本连接
```bash
# 显示连接信息
./connect-db.sh

# 直接连接到数据库
./connect-db.sh connect
```

### 2. 使用客户端工具连接

#### DBeaver 连接配置
- **驱动**: PostgreSQL
- **服务器主机**: localhost
- **端口**: 5432
- **数据库**: short_trip_db
- **用户名**: shorttrip
- **密码**: shorttrip@2024

#### Navicat 连接配置
- **连接类型**: PostgreSQL
- **主机**: localhost
- **端口**: 5432
- **数据库名**: short_trip_db
- **用户名**: shorttrip
- **密码**: shorttrip@2024

#### pgAdmin 连接配置
- **主机名/地址**: localhost
- **端口**: 5432
- **数据库**: short_trip_db
- **用户名**: shorttrip
- **密码**: shorttrip@2024

### 3. 编程语言连接示例

#### Java (Spring Boot)
```properties
spring.datasource.url=jdbc:postgresql://localhost:5432/short_trip_db
spring.datasource.username=shorttrip
spring.datasource.password=shorttrip@2024
spring.datasource.driver-class-name=org.postgresql.Driver
```

#### Python (psycopg2)
```python
import psycopg2

conn = psycopg2.connect(
    host="localhost",
    port="5432",
    database="short_trip_db",
    user="shorttrip",
    password="shorttrip@2024"
)
```

#### Node.js (pg)
```javascript
const { Client } = require('pg');

const client = new Client({
    host: 'localhost',
    port: 5432,
    database: 'short_trip_db',
    user: 'shorttrip',
    password: 'shorttrip@2024',
});
```

## 📋 数据库表结构

### 主要数据表

#### 1. users (用户表)
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password VARCHAR(255) NOT NULL,
    avatar_url VARCHAR(500),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 2. guides (攻略表)
```sql
CREATE TABLE guides (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    author_id BIGINT REFERENCES users(id),
    destination VARCHAR(100),
    tags VARCHAR(500),
    view_count INTEGER DEFAULT 0,
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. community_posts (社区帖子表)
```sql
CREATE TABLE community_posts (
    id BIGSERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content TEXT,
    author_id BIGINT REFERENCES users(id),
    image_urls TEXT[],
    like_count INTEGER DEFAULT 0,
    comment_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 4. comments (评论表)
```sql
CREATE TABLE comments (
    id BIGSERIAL PRIMARY KEY,
    content TEXT NOT NULL,
    author_id BIGINT REFERENCES users(id),
    post_id BIGINT,
    post_type VARCHAR(20),
    parent_id BIGINT REFERENCES comments(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### 5. routes (路线表)
```sql
CREATE TABLE routes (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    description TEXT,
    start_point VARCHAR(200),
    end_point VARCHAR(200),
    waypoints JSONB,
    distance DECIMAL(10,2),
    duration INTEGER,
    difficulty VARCHAR(20),
    creator_id BIGINT REFERENCES users(id),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

## 🔨 数据操作示例

### 1. 用户管理
```sql
-- 创建新用户
INSERT INTO users (username, email, password) 
VALUES ('newuser', 'user@example.com', '$2a$10$...');

-- 查询用户
SELECT * FROM users WHERE username = 'admin';

-- 更新用户信息
UPDATE users SET avatar_url = '/avatars/user1.jpg' WHERE id = 1;

-- 删除用户
DELETE FROM users WHERE id = 1;
```

### 2. 攻略管理
```sql
-- 创建攻略
INSERT INTO guides (title, content, author_id, destination) 
VALUES ('杭州西湖攻略', '详细内容...', 1, '杭州');

-- 查询热门攻略
SELECT * FROM guides ORDER BY view_count DESC LIMIT 10;

-- 搜索攻略
SELECT * FROM guides WHERE title ILIKE '%西湖%' OR content ILIKE '%西湖%';

-- 更新攻略浏览量
UPDATE guides SET view_count = view_count + 1 WHERE id = 1;
```

### 3. 社区帖子管理
```sql
-- 创建帖子
INSERT INTO community_posts (title, content, author_id) 
VALUES ('分享我的旅行照片', '内容...', 1);

-- 查询最新帖子
SELECT cp.*, u.username, u.avatar_url 
FROM community_posts cp 
JOIN users u ON cp.author_id = u.id 
ORDER BY cp.created_at DESC;

-- 点赞帖子
UPDATE community_posts SET like_count = like_count + 1 WHERE id = 1;
```

### 4. 评论管理
```sql
-- 添加评论
INSERT INTO comments (content, author_id, post_id, post_type) 
VALUES ('很棒的攻略！', 1, 1, 'guide');

-- 查询评论
SELECT c.*, u.username 
FROM comments c 
JOIN users u ON c.author_id = u.id 
WHERE c.post_id = 1 AND c.post_type = 'guide';

-- 回复评论
INSERT INTO comments (content, author_id, post_id, post_type, parent_id) 
VALUES ('谢谢！', 2, 1, 'guide', 1);
```

## 🛠️ 管理脚本

### 插入示例数据
```bash
./insert-sample-data.sh
```

### 备份数据库
```bash
./backup-database.sh
```

### 恢复数据库
```bash
# 从备份文件恢复
docker-compose -f docker-compose-2g.yml exec -T postgres psql -U shorttrip short_trip_db < backups/backup_file.sql
```

### 清空数据表
```sql
-- 谨慎操作！清空所有数据
TRUNCATE users, guides, community_posts, comments, routes CASCADE;
```

## 📈 性能优化

### 索引优化
```sql
-- 用户表索引
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);

-- 攻略表索引
CREATE INDEX idx_guides_author ON guides(author_id);
CREATE INDEX idx_guides_destination ON guides(destination);
CREATE INDEX idx_guides_created_at ON guides(created_at);

-- 评论表索引
CREATE INDEX idx_comments_post ON comments(post_id, post_type);
CREATE INDEX idx_comments_author ON comments(author_id);
```

### 查询优化
```sql
-- 使用 EXPLAIN ANALYZE 分析查询性能
EXPLAIN ANALYZE SELECT * FROM guides WHERE destination = '杭州';

-- 分页查询优化
SELECT * FROM guides 
ORDER BY created_at DESC 
LIMIT 20 OFFSET 0;
```

## 🔐 安全配置

### 用户权限
```sql
-- 创建只读用户
CREATE USER readonly WITH PASSWORD 'readonly_password';
GRANT CONNECT ON DATABASE short_trip_db TO readonly;
GRANT USAGE ON SCHEMA public TO readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO readonly;

-- 撤销权限
REVOKE ALL ON DATABASE short_trip_db FROM readonly;
```

### 密码策略
- 数据库密码建议使用强密码
- 定期更换密码
- 限制数据库连接IP

## 📊 监控和维护

### 查看数据库状态
```sql
-- 查看连接数
SELECT count(*) FROM pg_stat_activity;

-- 查看表大小
SELECT 
    schemaname,
    tablename,
    pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public';

-- 查看索引使用情况
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes;
```

### 日志查看
```bash
# 查看PostgreSQL日志
docker-compose -f docker-compose-2g.yml logs postgres

# 实时监控
docker-compose -f docker-compose-2g.yml logs -f postgres
```

需要更多数据库操作说明或遇到连接问题，请参考这个文档或联系技术支持。 