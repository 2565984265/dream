#!/bin/bash

echo "启动短途旅行前端服务..."

# 检查Node.js是否安装
if ! command -v node &> /dev/null; then
    echo "错误: 未找到Node.js，请先安装Node.js 16或更高版本"
    exit 1
fi

# 检查npm是否安装
if ! command -v npm &> /dev/null; then
    echo "错误: 未找到npm，请先安装npm"
    exit 1
fi

# 进入前端目录
cd short-trip-front

# 检查依赖是否已安装
if [ ! -d "node_modules" ]; then
    echo "安装依赖..."
    npm install
fi

# 启动开发服务器
echo "启动Next.js开发服务器..."
npm run dev

echo "前端服务启动完成！"
echo "访问地址: http://localhost:3000"
echo "地图页面: http://localhost:3000/map"