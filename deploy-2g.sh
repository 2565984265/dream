#!/bin/bash

# 2GB内存环境Docker部署脚本
set -e

echo "🚀 开始部署短途旅行项目 (2GB内存优化版)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查系统资源
check_system_resources() {
    log_info "检查系统资源..."
    
    # 检查内存
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    log_info "总内存: ${TOTAL_MEM}MB, 可用内存: ${AVAILABLE_MEM}MB"
    
    if [ $TOTAL_MEM -lt 1800 ]; then
        log_error "系统内存不足2GB，建议升级配置"
        exit 1
    fi
    
    if [ $AVAILABLE_MEM -lt 1200 ]; then
        log_warning "可用内存较少，建议关闭不必要的服务"
    fi
    
    # 检查磁盘空间
    AVAILABLE_DISK=$(df -m . | awk 'NR==2{print $4}')
    log_info "可用磁盘空间: ${AVAILABLE_DISK}MB"
    
    if [ $AVAILABLE_DISK -lt 10240 ]; then  # 10GB
        log_warning "磁盘空间较少，建议清理不必要的文件"
    fi
}

# 检查Docker环境
check_docker() {
    log_info "检查Docker环境..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，请先安装Docker"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，请先安装Docker Compose"
        exit 1
    fi
    
    # 检查Docker守护进程
    if ! docker info &> /dev/null; then
        log_error "Docker守护进程未运行，请启动Docker服务"
        exit 1
    fi
    
    log_success "Docker环境检查通过"
}

# 系统优化
optimize_system() {
    log_info "优化系统配置..."
    
    # 设置swap使用策略（降低swap使用，优先使用内存）
    if [ -f /proc/sys/vm/swappiness ]; then
        echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null
        log_info "设置swappiness=10"
    fi
    
    # 清理系统缓存
    sync && echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    log_info "清理系统缓存"
}

# 创建必要目录
create_directories() {
    log_info "创建必要目录..."
    
    mkdir -p uploads logs
    chmod 755 uploads logs
    
    log_success "目录创建完成"
}

# 设置环境变量
setup_env() {
    log_info "设置环境变量..."
    
    if [ ! -f .env ]; then
        cat > .env << EOF
# 数据库配置
DB_PASSWORD=shorttrip123

# 应用配置
NODE_ENV=production
SPRING_PROFILES_ACTIVE=production,docker

# JVM配置（2GB内存优化）
JAVA_OPTS=-Xmx800m -Xms400m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Node.js配置
NODE_OPTIONS=--max-old-space-size=300
EOF
        log_success "环境变量文件创建完成"
    else
        log_info "环境变量文件已存在"
    fi
}

# 构建应用
build_app() {
    log_info "构建后端应用..."
    
    cd short-trip-background
    if [ -f mvnw ]; then
        ./mvnw clean package -DskipTests -q
    else
        mvn clean package -DskipTests -q
    fi
    cd ..
    
    log_success "后端构建完成"
}

# 启动服务
start_services() {
    log_info "启动Docker服务..."
    
    # 停止现有服务
    docker-compose -f docker-compose-2g.yml down --remove-orphans
    
    # 清理未使用的Docker资源
    docker system prune -af --volumes
    
    # 启动服务
    docker-compose -f docker-compose-2g.yml up -d
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_info "等待服务启动..."
    
    # 等待数据库
    log_info "等待PostgreSQL启动..."
    timeout=60
    counter=0
    while ! docker-compose -f docker-compose-2g.yml exec -T postgres pg_isready -U shorttrip &> /dev/null; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            log_error "PostgreSQL启动超时"
            exit 1
        fi
    done
    log_success "PostgreSQL已启动"
    
    # 等待Redis
    log_info "等待Redis启动..."
    timeout=30
    counter=0
    while ! docker-compose -f docker-compose-2g.yml exec -T redis redis-cli ping &> /dev/null; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            log_error "Redis启动超时"
            exit 1
        fi
    done
    log_success "Redis已启动"
    
    # 等待后端
    log_info "等待后端服务启动..."
    timeout=120
    counter=0
    while ! curl -f http://localhost:8080/api/health &> /dev/null; do
        sleep 3
        counter=$((counter + 3))
        if [ $counter -ge $timeout ]; then
            log_error "后端服务启动超时"
            exit 1
        fi
        echo -n "."
    done
    echo
    log_success "后端服务已启动"
    
    # 等待前端
    log_info "等待前端服务启动..."
    timeout=60
    counter=0
    while ! curl -f http://localhost:3000 &> /dev/null; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            log_error "前端服务启动超时"
            exit 1
        fi
        echo -n "."
    done
    echo
    log_success "前端服务已启动"
    
    # 等待Nginx
    log_info "等待Nginx启动..."
    timeout=30
    counter=0
    while ! curl -f http://localhost/nginx-health &> /dev/null; do
        sleep 2
        counter=$((counter + 2))
        if [ $counter -ge $timeout ]; then
            log_error "Nginx启动超时"
            exit 1
        fi
    done
    log_success "Nginx已启动"
}

# 显示服务状态
show_status() {
    log_info "服务状态:"
    docker-compose -f docker-compose-2g.yml ps
    
    echo
    log_info "内存使用情况:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    
    echo
    log_success "🎉 部署完成！"
    echo
    echo "访问地址:"
    echo "  前端: http://localhost"
    echo "  后端API: http://localhost/api"
    echo "  API文档: http://localhost/api/swagger-ui.html"
    echo
    echo "管理命令:"
    echo "  查看日志: docker-compose -f docker-compose-2g.yml logs -f [service]"
    echo "  重启服务: docker-compose -f docker-compose-2g.yml restart [service]"
    echo "  停止服务: docker-compose -f docker-compose-2g.yml down"
    echo "  查看状态: docker-compose -f docker-compose-2g.yml ps"
}

# 监控脚本
create_monitor_script() {
    log_info "创建监控脚本..."
    
    cat > monitor.sh << 'EOF'
#!/bin/bash

echo "=== 短途旅行项目监控 ==="
echo "时间: $(date)"
echo

echo "=== 系统资源 ==="
echo "内存使用:"
free -h
echo
echo "磁盘使用:"
df -h /
echo

echo "=== Docker服务状态 ==="
docker-compose -f docker-compose-2g.yml ps
echo

echo "=== 容器资源使用 ==="
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
echo

echo "=== 服务健康检查 ==="
services=("http://localhost/nginx-health" "http://localhost:8080/api/health" "http://localhost:3000")
for url in "${services[@]}"; do
    if curl -f -s "$url" > /dev/null; then
        echo "✅ $url - 正常"
    else
        echo "❌ $url - 异常"
    fi
done
EOF
    
    chmod +x monitor.sh
    log_success "监控脚本创建完成: ./monitor.sh"
}

# 主执行流程
main() {
    echo "================================================================"
    echo "        短途旅行项目 - 2GB内存优化版Docker部署脚本"
    echo "================================================================"
    echo
    
    check_system_resources
    check_docker
    optimize_system
    create_directories
    setup_env
    build_app
    start_services
    wait_for_services
    show_status
    create_monitor_script
    
    echo
    log_success "🎊 部署成功完成！"
    log_info "建议定期运行 ./monitor.sh 监控系统状态"
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查日志"; exit 1' ERR

# 运行主函数
main "$@" 