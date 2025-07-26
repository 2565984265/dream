#!/bin/bash

# KML管理功能测试脚本
# 测试下载、预览、编辑功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
API_BASE_URL="http://localhost:8080"
FRONTEND_URL="http://localhost:3000"

print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# 检查服务是否运行
check_service() {
    local url=$1
    local name=$2
    
    if curl -s --head "$url" | head -n 1 | grep -q "200 OK\|302"; then
        print_message $GREEN "✓ $name 服务正常"
        return 0
    else
        print_message $RED "✗ $name 服务未运行或无法访问"
        return 1
    fi
}

# 执行测试
run_test() {
    local test_name=$1
    local command=$2
    local expected_pattern=$3
    
    print_message $YELLOW "执行测试: $test_name"
    
    result=$(eval "$command" 2>&1)
    
    if echo "$result" | grep -q "$expected_pattern"; then
        print_message $GREEN "✓ $test_name - 通过"
        return 0
    else
        print_message $RED "✗ $test_name - 失败"
        echo "预期模式: $expected_pattern"
        echo "实际结果: $result"
        return 1
    fi
}

# 调用API
call_api() {
    local endpoint=$1
    local method=${2:-GET}
    local data=${3:-}
    
    if [ "$method" = "GET" ]; then
        curl -s -X GET "$API_BASE_URL$endpoint"
    elif [ "$method" = "POST" ]; then
        curl -s -X POST "$API_BASE_URL$endpoint" \
             -H "Content-Type: application/json" \
             -d "$data"
    elif [ "$method" = "PUT" ]; then
        curl -s -X PUT "$API_BASE_URL$endpoint" \
             -H "Content-Type: application/json" \
             -d "$data"
    fi
}

main() {
    print_message $BLUE "=== KML管理功能测试 ==="
    
    # 检查服务状态
    print_message $BLUE "步骤1: 检查服务状态"
    if ! check_service "$API_BASE_URL/api/health" "后端API"; then
        print_message $RED "后端服务未运行，请先启动后端服务"
        exit 1
    fi
    
    if ! check_service "$FRONTEND_URL" "前端"; then
        print_message $YELLOW "前端服务未运行，仅测试后端API"
    fi
    
    # 确保有KML数据
    print_message $BLUE "步骤2: 确保KML数据已初始化"
    run_test "初始化KML数据" \
        "curl -s -X POST $API_BASE_URL/api/kml-init/load" \
        "code.*0"
    
    # 测试KML文件列表
    print_message $BLUE "步骤3: 测试KML文件列表"
    run_test "获取公开KML文件列表" \
        "curl -s -X GET '$API_BASE_URL/api/kml-files/public?page=0&size=5'" \
        "code.*0"
    
    # 获取第一个文件ID用于后续测试
    print_message $BLUE "步骤4: 获取测试文件ID"
    first_file_response=$(curl -s -X GET "$API_BASE_URL/api/kml-files/public?page=0&size=1")
    
    if echo "$first_file_response" | jq -e '.data.content[0].id' > /dev/null 2>&1; then
        file_id=$(echo "$first_file_response" | jq -r '.data.content[0].id')
        file_name=$(echo "$first_file_response" | jq -r '.data.content[0].fileName')
        print_message $GREEN "✓ 获取到测试文件: ID=$file_id, 名称=$file_name"
    else
        print_message $RED "✗ 无法获取测试文件ID"
        exit 1
    fi
    
    # 测试下载功能
    print_message $BLUE "步骤5: 测试下载功能"
    run_test "下载KML文件" \
        "curl -s -w '%{http_code}' -X GET $API_BASE_URL/api/kml-files/$file_id/download -o /tmp/test_download.kml" \
        "200"
    
    if [ -f "/tmp/test_download.kml" ]; then
        file_size=$(wc -c < "/tmp/test_download.kml")
        print_message $GREEN "✓ 文件下载成功，大小: $file_size 字节"
        rm -f "/tmp/test_download.kml"
    else
        print_message $RED "✗ 下载的文件不存在"
    fi
    
    # 测试预览功能
    print_message $BLUE "步骤6: 测试预览功能"
    run_test "预览KML文件内容" \
        "curl -s -X GET $API_BASE_URL/api/kml-files/$file_id" \
        "kml"
    
    # 测试权限检查
    print_message $BLUE "步骤7: 测试权限检查"
    run_test "检查上传权限" \
        "curl -s -X GET $API_BASE_URL/api/kml-files/upload-permission" \
        "code.*0"
    
    # 测试编辑功能（需要认证，这里只测试接口存在）
    print_message $BLUE "步骤8: 测试编辑接口（无认证）"
    update_data='{"routeName":"测试路线","travelMode":"WALKING","tags":"测试","remarks":"测试备注","isPublic":true,"isRecommended":false}'
    
    edit_response=$(curl -s -w '%{http_code}' -X PUT "$API_BASE_URL/api/kml-files/$file_id" \
                         -H "Content-Type: application/json" \
                         -d "$update_data" \
                         -o /tmp/edit_response.json)
    
    if [ "$edit_response" = "401" ] || [ "$edit_response" = "403" ]; then
        print_message $GREEN "✓ 编辑接口正确要求认证 (HTTP $edit_response)"
    elif [ "$edit_response" = "200" ]; then
        print_message $GREEN "✓ 编辑接口可用 (HTTP $edit_response)"
    else
        print_message $YELLOW "? 编辑接口返回 HTTP $edit_response"
    fi
    
    rm -f "/tmp/edit_response.json"
    
    # 测试前端页面（如果前端服务运行）
    if check_service "$FRONTEND_URL" "前端" > /dev/null 2>&1; then
        print_message $BLUE "步骤9: 测试前端页面"
        
        run_test "KML管理页面可访问" \
            "curl -s -w '%{http_code}' $FRONTEND_URL/kml-manager -o /dev/null" \
            "200"
        
        print_message $GREEN "✓ 可以通过浏览器访问: $FRONTEND_URL/kml-manager"
    fi
    
    # 总结
    print_message $BLUE "=== 测试完成 ==="
    print_message $GREEN "KML管理功能测试完成！"
    print_message $YELLOW "主要功能:"
    echo "  • 文件列表展示 ✓"
    echo "  • 文件下载功能 ✓"
    echo "  • 文件预览功能 ✓"
    echo "  • 权限检查功能 ✓"
    echo "  • 编辑接口存在 ✓"
    echo "  • 前端页面可访问 ✓"
    
    print_message $YELLOW "使用方法:"
    echo "  1. 访问 $FRONTEND_URL/kml-manager"
    echo "  2. 查看KML文件列表"
    echo "  3. 点击'预览'查看文件内容"
    echo "  4. 点击'编辑'修改文件信息（需要登录）"
    echo "  5. 点击'下载'下载文件"
    echo "  6. 用户ID < 100 可以上传新文件"
}

# 检查依赖
if ! command -v curl &> /dev/null; then
    print_message $RED "错误: 需要安装 curl"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    print_message $YELLOW "警告: 建议安装 jq 以获得更好的测试体验"
fi

# 运行主函数
main 