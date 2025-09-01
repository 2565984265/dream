#!/bin/bash

# 短途旅行项目 - 多仓库自动部署脚本
set -e

echo "🚀 短途旅行项目 - 多仓库自动部署 (2GB内存优化版)"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 多仓库配置
MAIN_REPO="${MAIN_REPO:-https://github.com/2565984265/dream.git}"
BACKEND_REPO="${BACKEND_REPO:-https://github.com/2565984265/short-trip-background.git}"
FRONTEND_REPO="${FRONTEND_REPO:-https://github.com/2565984265/short-trip-front.git}"

# 项目配置
PROJECT_NAME="short-trip"
DEPLOY_DIR="/opt/${PROJECT_NAME}"
DB_NAME="short_trip_db"
DB_USER="shorttrip"
DB_PASSWORD="shorttrip@2024"
DB_PORT="5432"

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

log_step() {
    echo -e "${PURPLE}[STEP]${NC} $1"
}

log_repo() {
    echo -e "${CYAN}[REPO]${NC} $1"
}

# 打印配置信息
print_config() {
    echo "================================================================"
    echo "                   多仓库部署配置信息"
    echo "================================================================"
    echo "主仓库: ${MAIN_REPO}"
    echo "后端仓库: ${BACKEND_REPO}"
    echo "前端仓库: ${FRONTEND_REPO}"
    echo "部署目录: ${DEPLOY_DIR}"
    echo "数据库名: ${DB_NAME}"
    echo "数据库用户: ${DB_USER}"
    echo "数据库密码: ${DB_PASSWORD}"
    echo "================================================================"
    echo
}

# 检查系统资源
check_system_resources() {
    log_step "1. 检查系统资源"
    
    TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
    AVAILABLE_MEM=$(free -m | awk 'NR==2{printf "%.0f", $7}')
    
    log_info "总内存: ${TOTAL_MEM}MB, 可用内存: ${AVAILABLE_MEM}MB"
    
    if [ $TOTAL_MEM -lt 1800 ]; then
        log_error "系统内存不足2GB，无法部署"
        exit 1
    fi
    
    if [ $AVAILABLE_MEM -lt 800 ]; then
        log_warning "可用内存较少，建议释放更多内存"
    fi
    
    AVAILABLE_DISK=$(df -m . | awk 'NR==2{print $4}')
    log_info "可用磁盘空间: ${AVAILABLE_DISK}MB"
    
    if [ $AVAILABLE_DISK -lt 15360 ]; then
        log_error "磁盘空间不足15GB，无法部署"
        exit 1
    fi
    
    log_success "系统资源检查通过"
}

# 检查依赖环境
check_dependencies() {
    log_step "2. 检查依赖环境"
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker未安装，正在安装..."
        install_docker
    else
        log_success "Docker已安装: $(docker --version)"
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose未安装，正在安装..."
        install_docker_compose
    else
        log_success "Docker Compose已安装: $(docker-compose --version)"
    fi
    
    if ! command -v git &> /dev/null; then
        log_error "Git未安装，正在安装..."
        sudo apt update && sudo apt install -y git
    else
        log_success "Git已安装: $(git --version)"
    fi
    
    for cmd in curl wget; do
        if ! command -v $cmd &> /dev/null; then
            sudo apt update && sudo apt install -y $cmd
        fi
    done
    
    log_success "所有依赖检查完成"
}

# 安装Docker
install_docker() {
    log_info "开始安装Docker..."
    
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io
    
    sudo systemctl start docker
    sudo systemctl enable docker
    sudo usermod -aG docker $USER
    
    log_success "Docker安装完成"
}

# 安装Docker Compose
install_docker_compose() {
    log_info "开始安装Docker Compose..."
    
    COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep 'tag_name' | cut -d\" -f4)
    sudo curl -L "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    
    sudo chmod +x /usr/local/bin/docker-compose
    
    log_success "Docker Compose安装完成"
}

# 系统优化
optimize_system() {
    log_step "3. 系统优化"
    
    if [ -f /proc/sys/vm/swappiness ]; then
        echo 10 | sudo tee /proc/sys/vm/swappiness > /dev/null
        log_info "设置swappiness=10"
    fi
    
    sync && echo 1 | sudo tee /proc/sys/vm/drop_caches > /dev/null
    log_info "清理系统缓存"
    
    services_to_stop=("snapd" "unattended-upgrades")
    for service in "${services_to_stop[@]}"; do
        if systemctl is-active --quiet $service; then
            sudo systemctl stop $service 2>/dev/null || true
            sudo systemctl disable $service 2>/dev/null || true
            log_info "已停止服务: $service"
        fi
    done
    
    log_success "系统优化完成"
}

# 创建Swap分区
create_swap() {
    log_step "4. 创建Swap分区"
    
    if swapon --show | grep -q /swapfile; then
        log_info "Swap分区已存在"
        return
    fi
    
    log_info "创建2GB Swap文件..."
    sudo fallocate -l 2G /swapfile
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    
    if ! grep -q '/swapfile' /etc/fstab; then
        echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    fi
    
    log_success "Swap分区创建完成"
}

# 克隆多个仓库
clone_repositories() {
    log_step "5. 克隆项目仓库"
    
    # 创建部署目录
    sudo mkdir -p $DEPLOY_DIR
    sudo chown $USER:$USER $DEPLOY_DIR
    
    # 删除现有目录
    if [ -d "$DEPLOY_DIR" ] && [ "$(ls -A $DEPLOY_DIR)" ]; then
        log_warning "删除现有代码目录"
        sudo rm -rf $DEPLOY_DIR/*
    fi
    
    cd $DEPLOY_DIR
    
    # 克隆主仓库（包含部署配置）
    log_repo "克隆主仓库: $MAIN_REPO"
    git clone $MAIN_REPO ./main-repo
    
    # 复制部署配置文件到根目录
    if [ -d "./main-repo" ]; then
        cp -r ./main-repo/* ./
        cp -r ./main-repo/.[^.]* ./ 2>/dev/null || true
        rm -rf ./main-repo
        log_success "主仓库克隆完成，配置文件已复制"
    fi
    
    # 克隆后端仓库
    log_repo "克隆后端仓库: $BACKEND_REPO"
    git clone $BACKEND_REPO ./short-trip-background
    log_success "后端仓库克隆完成"
    
    # 克隆前端仓库
    log_repo "克隆前端仓库: $FRONTEND_REPO"
    git clone $FRONTEND_REPO ./short-trip-front
    log_success "前端仓库克隆完成"
    
    log_success "所有仓库克隆完成"
}

# 创建配置文件
create_config_files() {
    log_step "6. 创建配置文件"
    
    cd $DEPLOY_DIR
    
    # 创建环境变量文件
    cat > .env << EOF
# 数据库配置
DB_PASSWORD=${DB_PASSWORD}
DB_USER=${DB_USER}
DB_NAME=${DB_NAME}

# 应用配置
NODE_ENV=production
SPRING_PROFILES_ACTIVE=production,docker

# JVM配置（2GB内存优化）
JAVA_OPTS=-Xmx800m -Xms400m -XX:+UseG1GC -XX:MaxGCPauseMillis=200 -XX:+UseContainerSupport -XX:MaxRAMPercentage=75.0

# Node.js配置
NODE_OPTIONS=--max-old-space-size=300

# JWT配置
JWT_SECRET=shorttrip-super-secret-jwt-key-$(date +%s)

# 数据库连接信息
SPRING_DATASOURCE_URL=jdbc:postgresql://postgres:5432/${DB_NAME}
SPRING_DATASOURCE_USERNAME=${DB_USER}
SPRING_DATASOURCE_PASSWORD=${DB_PASSWORD}
SPRING_DATA_REDIS_HOST=redis

# 仓库信息
MAIN_REPO=${MAIN_REPO}
BACKEND_REPO=${BACKEND_REPO}
FRONTEND_REPO=${FRONTEND_REPO}
EOF
    
    # 创建更新脚本
    cat > update-repos.sh << 'EOF'
#!/bin/bash
# 多仓库更新脚本

source .env

echo "🔄 更新所有仓库..."

# 更新后端
echo "更新后端仓库..."
cd short-trip-background
git pull origin main
cd ..

# 更新前端
echo "更新前端仓库..."
cd short-trip-front
git pull origin main
cd ..

# 重新构建和部署
echo "重新构建应用..."
cd short-trip-background
if [ -f mvnw ]; then
    ./mvnw clean package -DskipTests -q
else
    mvn clean package -DskipTests -q
fi
cd ..

# 重启服务
echo "重启Docker服务..."
docker-compose -f docker-compose-2g.yml down
docker-compose -f docker-compose-2g.yml up -d --build

echo "✅ 更新完成！"
EOF
    
    chmod +x update-repos.sh
    
    # 创建数据库连接脚本
    cat > connect-db.sh << 'EOF'
#!/bin/bash
# 数据库连接脚本

source .env

echo "=== 数据库连接信息 ==="
echo "主机: localhost"
echo "端口: 5432"
echo "数据库: ${DB_NAME}"
echo "用户: ${DB_USER}"
echo "密码: ${DB_PASSWORD}"
echo "========================"

echo "连接命令:"
echo "docker-compose -f docker-compose-2g.yml exec postgres psql -U ${DB_USER} -d ${DB_NAME}"
echo
echo "外部连接命令:"
echo "psql -h localhost -p 5432 -U ${DB_USER} -d ${DB_NAME}"
echo
echo "JDBC URL:"
echo "jdbc:postgresql://localhost:5432/${DB_NAME}"

if [ "$1" = "connect" ]; then
    docker-compose -f docker-compose-2g.yml exec postgres psql -U ${DB_USER} -d ${DB_NAME}
fi
EOF
    
    chmod +x connect-db.sh
    
    # 创建示例数据插入脚本
    cat > insert-sample-data.sh << 'EOF'
#!/bin/bash
# 示例数据插入脚本

source .env

echo "插入示例数据到数据库..."

# 等待数据库启动
echo "等待数据库启动..."
until docker-compose -f docker-compose-2g.yml exec -T postgres pg_isready -U ${DB_USER} &> /dev/null; do
    sleep 2
done

# 插入示例数据
docker-compose -f docker-compose-2g.yml exec -T postgres psql -U ${DB_USER} -d ${DB_NAME} << 'SQL'
-- 插入示例用户
INSERT INTO users (username, email, password, created_at) VALUES 
('admin', 'admin@shorttrip.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM5AQNaJCMBrr.drLiqy', NOW()),
('testuser', 'test@shorttrip.com', '$2a$10$N.zmdr9k7uOCQb376NoUnuTJ8iAt6Z5EHsM5AQNaJCMBrr.drLiqy', NOW())
ON CONFLICT (email) DO NOTHING;

-- 插入示例攻略
INSERT INTO guides (title, content, author_id, created_at) VALUES 
('杭州西湖一日游', '详细的西湖游玩攻略...', 1, NOW()),
('上海外滩夜景指南', '上海外滩最佳观景点...', 1, NOW())
ON CONFLICT DO NOTHING;

-- 查看插入结果
SELECT 'Users count: ' || COUNT(*) FROM users;
SELECT 'Guides count: ' || COUNT(*) FROM guides;
SQL

echo "示例数据插入完成！"
echo "默认用户账号:"
echo "  管理员 - 邮箱: admin@shorttrip.com, 密码: password"
echo "  测试用户 - 邮箱: test@shorttrip.com, 密码: password"
EOF
    
    chmod +x insert-sample-data.sh
    
    # 创建备份脚本
    cat > backup-database.sh << 'EOF'
#!/bin/bash
# 数据库备份脚本

source .env

BACKUP_DIR="./backups"
BACKUP_FILE="short_trip_backup_$(date +%Y%m%d_%H%M%S).sql"

mkdir -p $BACKUP_DIR

echo "开始备份数据库..."
docker-compose -f docker-compose-2g.yml exec -T postgres pg_dump -U ${DB_USER} ${DB_NAME} > $BACKUP_DIR/$BACKUP_FILE

if [ $? -eq 0 ]; then
    echo "数据库备份成功: $BACKUP_DIR/$BACKUP_FILE"
    echo "文件大小: $(du -h $BACKUP_DIR/$BACKUP_FILE | cut -f1)"
else
    echo "数据库备份失败"
    exit 1
fi
EOF
    
    chmod +x backup-database.sh
    
    # 创建仓库状态检查脚本
    cat > check-repos.sh << 'EOF'
#!/bin/bash
# 检查仓库状态脚本

echo "📊 检查仓库状态..."
echo

echo "=== 后端仓库状态 ==="
cd short-trip-background
echo "分支: $(git branch --show-current)"
echo "最后提交: $(git log --oneline -1)"
echo "状态: $(git status --porcelain | wc -l) 个未提交文件"
cd ..

echo
echo "=== 前端仓库状态 ==="
cd short-trip-front
echo "分支: $(git branch --show-current)"
echo "最后提交: $(git log --oneline -1)"
echo "状态: $(git status --porcelain | wc -l) 个未提交文件"
cd ..

echo
echo "=== 主仓库信息 ==="
echo "部署时间: $(date)"
if [ -f .env ]; then
    echo "配置文件: 存在"
else
    echo "配置文件: 缺失"
fi

echo
echo "=== Docker服务状态 ==="
if command -v docker-compose &> /dev/null; then
    docker-compose -f docker-compose-2g.yml ps
else
    echo "Docker Compose 未安装"
fi
EOF
    
    chmod +x check-repos.sh
    
    log_success "所有配置文件创建完成"
}

# 构建和启动服务
build_and_start() {
    log_step "7. 构建和启动服务"
    
    cd $DEPLOY_DIR
    
    mkdir -p uploads logs backups
    
    # 构建后端
    log_info "构建后端应用..."
    cd short-trip-background
    if [ -f mvnw ]; then
        ./mvnw clean package -DskipTests -q
    else
        mvn clean package -DskipTests -q
    fi
    cd ..
    
    # 清理Docker资源
    log_info "清理Docker资源..."
    docker system prune -af --volumes || true
    
    # 启动服务
    log_info "启动Docker服务..."
    docker-compose -f docker-compose-2g.yml down --remove-orphans || true
    docker-compose -f docker-compose-2g.yml up -d --build
    
    log_success "服务启动完成"
}

# 等待服务就绪
wait_for_services() {
    log_step "8. 等待服务就绪"
    
    cd $DEPLOY_DIR
    
    services=("postgres" "redis" "backend" "frontend" "nginx")
    
    for service in "${services[@]}"; do
        case $service in
            "postgres")
                log_info "等待PostgreSQL启动..."
                timeout=60
                counter=0
                while ! docker-compose -f docker-compose-2g.yml exec -T postgres pg_isready -U $DB_USER &> /dev/null; do
                    sleep 2
                    counter=$((counter + 2))
                    if [ $counter -ge $timeout ]; then
                        log_error "PostgreSQL启动超时"
                        show_debug_info
                        exit 1
                    fi
                    echo -n "."
                done
                echo
                log_success "PostgreSQL已启动"
                ;;
            "redis")
                log_info "等待Redis启动..."
                timeout=30
                counter=0
                while ! docker-compose -f docker-compose-2g.yml exec -T redis redis-cli ping &> /dev/null; do
                    sleep 2
                    counter=$((counter + 2))
                    if [ $counter -ge $timeout ]; then
                        log_error "Redis启动超时"
                        show_debug_info
                        exit 1
                    fi
                    echo -n "."
                done
                echo
                log_success "Redis已启动"
                ;;
            "backend")
                log_info "等待后端服务启动..."
                timeout=120
                counter=0
                while ! curl -f http://localhost:8080/api/health &> /dev/null; do
                    sleep 3
                    counter=$((counter + 3))
                    if [ $counter -ge $timeout ]; then
                        log_error "后端服务启动超时"
                        show_debug_info
                        exit 1
                    fi
                    echo -n "."
                done
                echo
                log_success "后端服务已启动"
                ;;
            "frontend")
                log_info "等待前端服务启动..."
                timeout=60
                counter=0
                while ! curl -f http://localhost:3000 &> /dev/null; do
                    sleep 2
                    counter=$((counter + 2))
                    if [ $counter -ge $timeout ]; then
                        log_error "前端服务启动超时"
                        show_debug_info
                        exit 1
                    fi
                    echo -n "."
                done
                echo
                log_success "前端服务已启动"
                ;;
            "nginx")
                log_info "等待Nginx启动..."
                timeout=30
                counter=0
                while ! curl -f http://localhost/nginx-health &> /dev/null; do
                    sleep 2
                    counter=$((counter + 2))
                    if [ $counter -ge $timeout ]; then
                        log_error "Nginx启动超时"
                        show_debug_info
                        exit 1
                    fi
                    echo -n "."
                done
                echo
                log_success "Nginx已启动"
                ;;
        esac
    done
}

# 显示调试信息
show_debug_info() {
    echo
    log_error "服务启动失败，显示调试信息："
    echo "=================================="
    
    cd $DEPLOY_DIR
    
    echo "服务状态:"
    docker-compose -f docker-compose-2g.yml ps
    
    echo
    echo "最近的日志:"
    docker-compose -f docker-compose-2g.yml logs --tail=20
    
    echo
    echo "系统资源:"
    free -h
    df -h
    
    echo
    echo "仓库状态:"
    ./check-repos.sh
}

# 插入示例数据
insert_sample_data() {
    log_step "9. 插入示例数据"
    
    cd $DEPLOY_DIR
    
    read -p "是否插入示例数据？(y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./insert-sample-data.sh
        log_success "示例数据插入完成"
    else
        log_info "跳过示例数据插入"
    fi
}

# 显示部署结果
show_deployment_result() {
    log_step "10. 部署完成"
    
    cd $DEPLOY_DIR
    
    echo
    echo "================================================================"
    echo "                🎉 多仓库部署成功完成！"
    echo "================================================================"
    echo
    echo "📂 仓库信息:"
    echo "  主仓库: ${MAIN_REPO}"
    echo "  后端仓库: ${BACKEND_REPO}"
    echo "  前端仓库: ${FRONTEND_REPO}"
    echo
    echo "📱 访问地址:"
    echo "  前端网站: http://localhost"
    echo "  后端API:  http://localhost/api"
    echo "  API文档:  http://localhost/api/swagger-ui.html"
    echo
    echo "🗄️ 数据库连接信息:"
    echo "  主机: localhost"
    echo "  端口: 5432"
    echo "  数据库: ${DB_NAME}"
    echo "  用户: ${DB_USER}"
    echo "  密码: ${DB_PASSWORD}"
    echo
    echo "🛠️ 管理命令:"
    echo "  连接数据库: ./connect-db.sh connect"
    echo "  查看仓库状态: ./check-repos.sh"
    echo "  更新所有仓库: ./update-repos.sh"
    echo "  插入示例数据: ./insert-sample-data.sh"
    echo "  备份数据库: ./backup-database.sh"
    echo "  查看服务状态: docker-compose -f docker-compose-2g.yml ps"
    echo "  查看日志: docker-compose -f docker-compose-2g.yml logs -f [service]"
    echo "  重启服务: docker-compose -f docker-compose-2g.yml restart [service]"
    echo "  停止服务: docker-compose -f docker-compose-2g.yml down"
    echo
    echo "📊 当前资源使用:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
    echo
    echo "💡 多仓库管理提示:"
    echo "  - 使用 ./update-repos.sh 更新所有仓库代码"
    echo "  - 使用 ./check-repos.sh 检查仓库状态"
    echo "  - 各仓库独立开发，部署时自动拉取最新代码"
    echo "  - 建议为每个仓库设置独立的CI/CD流程"
    echo
    echo "================================================================"
}

# 主执行流程
main() {
    echo
    print_config
    
    if [ "$EUID" -eq 0 ]; then
        log_error "请不要使用root用户运行此脚本"
        exit 1
    fi
    
    check_system_resources
    check_dependencies
    optimize_system
    create_swap
    clone_repositories
    create_config_files
    build_and_start
    wait_for_services
    insert_sample_data
    show_deployment_result
    
    log_success "🎊 多仓库部署流程执行完毕！"
}

# 错误处理
trap 'log_error "部署过程中发生错误，请检查上面的日志信息"; exit 1' ERR

# 检查参数
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "多仓库部署脚本使用说明"
    echo "========================"
    echo "用法: $0"
    echo
    echo "环境变量 (可选):"
    echo "  MAIN_REPO=https://github.com/user/dream.git          主仓库地址"
    echo "  BACKEND_REPO=https://github.com/user/backend.git     后端仓库地址"
    echo "  FRONTEND_REPO=https://github.com/user/frontend.git   前端仓库地址"
    echo
    echo "默认配置:"
    echo "  主仓库: https://github.com/2565984265/dream.git"
    echo "  后端仓库: https://github.com/2565984265/short-trip-background.git"
    echo "  前端仓库: https://github.com/2565984265/short-trip-front.git"
    echo
    echo "示例:"
    echo "  # 使用默认仓库地址"
    echo "  $0"
    echo
    echo "  # 自定义仓库地址"
    echo "  MAIN_REPO=https://github.com/myuser/main.git $0"
    exit 0
fi

# 运行主函数
main "$@" 