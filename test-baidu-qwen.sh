#!/bin/bash

# 百度千问API测试脚本
# 使用方法: ./test-baidu-qwen.sh

echo "=== 百度千问API集成测试 ==="
echo

# 检查后端服务是否运行
echo "1. 检查后端服务状态..."
if curl -s http://localhost:8080/api/health > /dev/null; then
    echo "✅ 后端服务运行正常"
else
    echo "❌ 后端服务未运行，请先启动后端服务"
    echo "   cd short-trip-background && mvn spring-boot:run"
    exit 1
fi

echo

# 测试AI服务状态
echo "2. 检查AI服务状态..."
STATUS_RESPONSE=$(curl -s "http://localhost:8080/api/ai/service-status")
if echo "$STATUS_RESPONSE" | grep -q "configured"; then
    echo "✅ AI服务配置正常"
    echo "$STATUS_RESPONSE" | jq '.' 2>/dev/null || echo "$STATUS_RESPONSE"
else
    echo "❌ AI服务配置异常"
    echo "$STATUS_RESPONSE"
fi

echo

# 测试百度千问API
echo "3. 测试百度千问API..."
TEST_RESPONSE=$(curl -s "http://localhost:8080/api/ai/test-baidu?message=你好，请回复'测试成功'")
if echo "$TEST_RESPONSE" | grep -q "测试成功\|你好\|成功"; then
    echo "✅ 百度千问API测试成功"
    echo "$TEST_RESPONSE" | jq '.' 2>/dev/null || echo "$TEST_RESPONSE"
else
    echo "❌ 百度千问API测试失败"
    echo "$TEST_RESPONSE"
fi

echo

# 测试AI对话
echo "4. 测试AI智能对话..."
CHAT_RESPONSE=$(curl -s -X POST "http://localhost:8080/api/ai/chat" \
    -H "Content-Type: application/json" \
    -d '{"message": "请推荐一个适合周末短途旅行的地方"}')
if echo "$CHAT_RESPONSE" | grep -q "content\|推荐\|旅行"; then
    echo "✅ AI智能对话测试成功"
    echo "$CHAT_RESPONSE" | jq '.' 2>/dev/null || echo "$CHAT_RESPONSE"
else
    echo "❌ AI智能对话测试失败"
    echo "$CHAT_RESPONSE"
fi

echo

echo "=== 测试完成 ==="
echo
echo "如果所有测试都通过，说明百度千问API集成成功！"
echo "如果遇到问题，请检查："
echo "1. 百度千问API配置是否正确"
echo "2. 网络连接是否正常"
echo "3. API密钥是否有效"
echo "4. 查看应用日志获取详细错误信息" 