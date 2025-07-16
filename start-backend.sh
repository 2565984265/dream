#!/bin/bash

echo "启动短途旅行后端服务..."

# 检查Java是否安装
if ! command -v java &> /dev/null; then
    echo "错误: 未找到Java，请先安装Java 17或更高版本"
    exit 1
fi

# 检查Maven是否安装
if ! command -v mvn &> /dev/null; then
    echo "错误: 未找到Maven，请先安装Maven"
    exit 1
fi

# 进入后端目录
cd short-trip-background

# 检查PostgreSQL是否运行
echo "检查PostgreSQL连接..."
if ! pg_isready -h localhost -p 5432 &> /dev/null; then
    echo "警告: PostgreSQL未运行，请确保PostgreSQL服务已启动"
    echo "可以使用以下命令启动PostgreSQL:"
    echo "  brew services start postgresql@14  # macOS"
    echo "  sudo systemctl start postgresql    # Linux"
    echo "  net start postgresql               # Windows"
fi

# 检查Redis是否运行
echo "检查Redis连接..."
if ! redis-cli ping &> /dev/null; then
    echo "警告: Redis未运行，请确保Redis服务已启动"
    echo "可以使用以下命令启动Redis:"
    echo "  brew services start redis          # macOS"
    echo "  sudo systemctl start redis         # Linux"
    echo "  net start redis                    # Windows"
fi

# 编译项目
echo "编译项目..."
mvn clean compile

# 启动应用
echo "启动Spring Boot应用..."
mvn spring-boot:run

echo "后端服务启动完成！"
echo "API文档地址: http://localhost:8080/swagger-ui.html"
echo "健康检查: http://localhost:8080/api/health" 