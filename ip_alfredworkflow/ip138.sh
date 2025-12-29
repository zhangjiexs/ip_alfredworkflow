#!/bin/bash
# IP 归属地查询工具 - 使用 ip138 API
# 参考: https://github.com/hellosa/ip138-alfredworkflow

# 获取查询参数（Alfred 传入）
QUERY="$1"

# 图标路径
ICON_PATH="icon.png"

# 获取本地内网 IP 地址（IPv4）
get_local_ip() {
    # 方法1: 通过 UDP socket 获取默认路由对应的 IP（最可靠）
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null)
    if [ -z "$LOCAL_IP" ]; then
        # 方法2: 通过 ifconfig 获取
        LOCAL_IP=$(ifconfig | grep 'inet.*broadcast' | awk '{print $2}' | head -1)
    fi
    if [ -z "$LOCAL_IP" ]; then
        # 方法3: 通过 hostname 获取
        LOCAL_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
    fi
    # 过滤掉 127.0.0.1 和 169.254.x.x（链路本地地址）
    if [ -n "$LOCAL_IP" ] && [ "$LOCAL_IP" != "127.0.0.1" ] && [[ ! "$LOCAL_IP" =~ ^169\.254\. ]]; then
        echo "$LOCAL_IP"
    fi
}

# 获取外部 IP 的函数（优先 IPv4）
get_external_ip() {
    # 优先获取 IPv4 地址
    EXTERNAL_IP=$(curl -s --max-time 3 -4 "https://api.ipify.org" 2>/dev/null)
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(curl -s --max-time 3 -4 "https://icanhazip.com" 2>/dev/null)
    fi
    if [ -z "$EXTERNAL_IP" ]; then
        EXTERNAL_IP=$(curl -s --max-time 3 -4 "https://ifconfig.me/ip" 2>/dev/null)
    fi
    if [ -z "$EXTERNAL_IP" ]; then
        # 如果 IPv4 获取失败，尝试 IPv6
        EXTERNAL_IP=$(curl -s --max-time 3 -6 "https://api64.ipify.org" 2>/dev/null)
    fi
    echo "$EXTERNAL_IP"
}

# 获取外部 IPv6 地址的函数
get_external_ipv6() {
    EXTERNAL_IPV6=$(curl -s --max-time 3 -6 "https://api64.ipify.org" 2>/dev/null)
    if [ -z "$EXTERNAL_IPV6" ]; then
        EXTERNAL_IPV6=$(curl -s --max-time 3 -6 "https://icanhazip.com" 2>/dev/null)
    fi
    echo "$EXTERNAL_IPV6"
}

# 查询 IP 归属地
query_ip_location() {
    local ip="$1"
    
    if [ -z "$ip" ]; then
        return 1
    fi
    
    # 优先使用 ip-api.com（免费，返回 JSON，易于解析）
    RESULT=$(curl -s --max-time 5 "http://ip-api.com/json/${ip}?lang=zh-CN&fields=status,country,regionName,city,isp" 2>/dev/null)
    
    if [ -n "$RESULT" ]; then
        # 检查是否成功
        STATUS=$(echo "$RESULT" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        if [ "$STATUS" = "success" ]; then
            COUNTRY=$(echo "$RESULT" | grep -o '"country":"[^"]*"' | cut -d'"' -f4)
            REGION=$(echo "$RESULT" | grep -o '"regionName":"[^"]*"' | cut -d'"' -f4)
            CITY=$(echo "$RESULT" | grep -o '"city":"[^"]*"' | cut -d'"' -f4)
            ISP=$(echo "$RESULT" | grep -o '"isp":"[^"]*"' | cut -d'"' -f4)
            
            # 组合归属地信息
            LOCATION_PARTS=()
            [ -n "$COUNTRY" ] && LOCATION_PARTS+=("$COUNTRY")
            [ -n "$REGION" ] && LOCATION_PARTS+=("$REGION")
            [ -n "$CITY" ] && LOCATION_PARTS+=("$CITY")
            
            LOCATION_INFO=$(IFS=' '; echo "${LOCATION_PARTS[*]}")
            [ -n "$ISP" ] && LOCATION_INFO="${LOCATION_INFO} | ${ISP}"
            
            echo "$LOCATION_INFO"
            return 0
        fi
    fi
    
    # 备用方案：尝试使用 ip138（需要解析 HTML）
    # 注意：ip138 返回 HTML，解析较复杂，这里作为备用
    return 1
}

# 验证 IP 地址格式
is_valid_ip() {
    local ip="$1"
    # IPv4 验证
    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        return 0
    fi
    # IPv6 验证（简单验证）
    if [[ $ip =~ : ]]; then
        return 0
    fi
    return 1
}

# 判断是否为 IPv6
is_ipv6() {
    local ip="$1"
    if [[ $ip =~ : ]]; then
        return 0
    fi
    return 1
}

# 主逻辑
main() {
    # 如果没有输入，获取内网和外网 IP
    if [ -z "$QUERY" ] || [ "$QUERY" = "" ]; then
        ITEMS=""
        
        # 获取内网 IP
        LOCAL_IP=$(get_local_ip)
        if [ -n "$LOCAL_IP" ]; then
            LOCAL_LOCATION=$(query_ip_location "$LOCAL_IP")
            ITEMS="${ITEMS}{
        \"title\": \"内网 IPv4: $LOCAL_IP\",
        \"subtitle\": \"${LOCAL_LOCATION:-本地网络}\",
        \"arg\": \"$LOCAL_IP\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
        fi
        
        # 获取外网 IP
        EXTERNAL_IP=$(get_external_ip)
        if [ -n "$EXTERNAL_IP" ]; then
            EXTERNAL_LOCATION=$(query_ip_location "$EXTERNAL_IP")
            
            # 判断 IP 类型
            if is_ipv6 "$EXTERNAL_IP"; then
                # IPv6 地址
                if [ -n "$ITEMS" ]; then
                    ITEMS="${ITEMS},
    {
        \"title\": \"外网 IPv6: $EXTERNAL_IP\",
        \"subtitle\": \"${EXTERNAL_LOCATION:-查询中...}\",
        \"arg\": \"$EXTERNAL_IP\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
                else
                    ITEMS="{
        \"title\": \"外网 IPv6: $EXTERNAL_IP\",
        \"subtitle\": \"${EXTERNAL_LOCATION:-查询中...}\",
        \"arg\": \"$EXTERNAL_IP\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
                fi
                
                # 尝试获取 IPv4
                EXTERNAL_IPV4=$(curl -s --max-time 3 -4 "https://api.ipify.org" 2>/dev/null)
                if [ -n "$EXTERNAL_IPV4" ]; then
                    EXTERNAL_LOCATION_V4=$(query_ip_location "$EXTERNAL_IPV4")
                    ITEMS="${ITEMS},
    {
        \"title\": \"外网 IPv4: $EXTERNAL_IPV4\",
        \"subtitle\": \"${EXTERNAL_LOCATION_V4:-查询中...}\",
        \"arg\": \"$EXTERNAL_IPV4\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
                fi
            else
                # IPv4 地址
                if [ -n "$ITEMS" ]; then
                    ITEMS="${ITEMS},
    {
        \"title\": \"外网 IPv4: $EXTERNAL_IP\",
        \"subtitle\": \"${EXTERNAL_LOCATION:-查询中...}\",
        \"arg\": \"$EXTERNAL_IP\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
                else
                    ITEMS="{
        \"title\": \"外网 IPv4: $EXTERNAL_IP\",
        \"subtitle\": \"${EXTERNAL_LOCATION:-查询中...}\",
        \"arg\": \"$EXTERNAL_IP\",
        \"icon\": {\"path\": \"$ICON_PATH\"},
        \"valid\": true
    }"
                fi
            fi
        fi
        
        # 如果都没有获取到
        if [ -z "$ITEMS" ]; then
            cat <<EOF
{
    "items": [{
        "title": "无法获取 IP 地址",
        "subtitle": "请检查网络连接",
        "icon": {"path": "$ICON_PATH"},
        "valid": false
    }]
}
EOF
            exit 0
        fi
        
        # 输出结果
        cat <<EOF
{
    "items": [$ITEMS]
}
EOF
    else
        # 验证输入的 IP
        if ! is_valid_ip "$QUERY"; then
            cat <<EOF
{
    "items": [{
        "title": "无效的 IP 地址",
        "subtitle": "请输入有效的 IPv4 地址，例如: 8.8.8.8",
        "icon": {"path": "$ICON_PATH"},
        "valid": false
    }]
}
EOF
            exit 0
        fi
        
        # 查询指定 IP 归属地
        LOCATION=$(query_ip_location "$QUERY")
        
        if [ -z "$LOCATION" ] || [ "$LOCATION" = "查询失败" ] || [ "$LOCATION" = "解析失败" ]; then
            cat <<EOF
{
    "items": [{
        "title": "IP: $QUERY",
        "subtitle": "查询失败，请稍后重试",
        "arg": "$QUERY",
        "icon": {"path": "$ICON_PATH"},
        "valid": true
    }]
}
EOF
        else
            cat <<EOF
{
    "items": [{
        "title": "IP: $QUERY",
        "subtitle": "$LOCATION",
        "arg": "$QUERY",
        "icon": {"path": "$ICON_PATH"},
        "valid": true
    }]
}
EOF
        fi
    fi
}

# 执行主函数
main

