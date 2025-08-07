# Redis 哨兵模式

Redis 哨兵（Sentinel）是 Redis 官方提供的高可用性解决方案，通过监控、通知、自动故障转移和配置提供者等功能，确保 Redis 服务的持续可用性。

## 哨兵模式概述

### 哨兵模式的概念

Redis 哨兵是一个分布式系统，用于管理多个 Redis 实例，提供以下核心功能：

**核心组件：**
- **哨兵节点（Sentinel）**：监控和管理 Redis 实例的独立进程
- **主节点（Master）**：处理写操作的 Redis 实例
- **从节点（Slave/Replica）**：从主节点复制数据的 Redis 实例
- **客户端（Client）**：连接到哨兵系统的应用程序

**核心功能：**
1. **监控（Monitoring）**：持续监控主从节点的健康状态
2. **通知（Notification）**：当实例出现问题时发送通知
3. **自动故障转移（Automatic Failover）**：主节点故障时自动选举新主节点
4. **配置提供者（Configuration Provider）**：为客户端提供当前主节点信息

### 哨兵模式的优势

**高可用性：**
- 自动故障检测和转移
- 无需人工干预
- 最小化服务中断时间
- 支持多数据中心部署

**可靠性：**
- 分布式决策机制
- 避免脑裂问题
- 多哨兵节点冗余
- 客观下线判断

**易用性：**
- 客户端自动发现主节点
- 透明的故障转移
- 简化的运维管理
- 丰富的监控信息

**扩展性：**
- 支持动态添加哨兵节点
- 支持多主从架构
- 灵活的配置管理
- 可编程的通知机制

### 哨兵模式的应用场景

```
典型应用场景：

1. 生产环境高可用
   应用 → 哨兵集群 → Redis 主从集群
   自动故障转移，保证服务连续性

2. 多数据中心部署
   数据中心A: 主节点 + 哨兵
   数据中心B: 从节点 + 哨兵
   数据中心C: 从节点 + 哨兵

3. 读写分离架构
   写操作 → 哨兵发现的主节点
   读操作 → 哨兵管理的从节点

4. 缓存层高可用
   Web应用 → 哨兵 → Redis缓存集群
   缓存故障时自动切换

5. 会话存储
   负载均衡器 → 应用服务器 → 哨兵 → Redis会话存储
   保证会话数据的高可用性
```

## 哨兵模式原理

### 哨兵工作机制

#### 监控机制

哨兵通过定期发送命令来监控 Redis 实例的状态：

```
监控流程：

1. 发送 PING 命令
   哨兵 → Redis实例: PING
   Redis实例 → 哨兵: PONG

2. 获取实例信息
   哨兵 → 主节点: INFO replication
   主节点 → 哨兵: 从节点列表和状态

3. 发现新实例
   哨兵根据主节点信息自动发现从节点
   哨兵之间通过发布/订阅发现彼此

4. 状态判断
   主观下线（SDOWN）：单个哨兵认为实例不可用
   客观下线（ODOWN）：多数哨兵认为实例不可用
```

#### 故障检测

```bash
# 故障检测参数
# sentinel.conf

# 主观下线时间（毫秒）
sentinel down-after-milliseconds mymaster 30000

# 客观下线需要的哨兵数量
sentinel quorum mymaster 2

# 故障转移超时时间
sentinel failover-timeout mymaster 180000

# 并行同步的从节点数量
sentinel parallel-syncs mymaster 1
```

**故障检测流程：**

1. **主观下线（Subjectively Down, SDOWN）**
   - 单个哨兵在指定时间内无法与实例通信
   - 哨兵将实例标记为主观下线
   - 开始询问其他哨兵的意见

2. **客观下线（Objectively Down, ODOWN）**
   - 足够数量的哨兵认为实例主观下线
   - 达到 quorum 配置的数量要求
   - 实例被标记为客观下线

3. **故障转移触发**
   - 只有主节点的客观下线会触发故障转移
   - 从节点的客观下线只会影响监控状态

#### 故障转移过程

```
故障转移详细流程：

1. 选举领导者哨兵
   - 检测到主节点客观下线
   - 哨兵之间进行领导者选举
   - 使用 Raft 算法确保只有一个领导者

2. 选择新主节点
   领导者哨兵根据以下优先级选择：
   a. 排除主观下线的从节点
   b. 排除断线时间超过阈值的从节点
   c. 选择 slave-priority 最小的从节点
   d. 选择复制偏移量最大的从节点
   e. 选择 run_id 最小的从节点

3. 提升新主节点
   - 向选中的从节点发送 SLAVEOF NO ONE
   - 等待从节点变为主节点
   - 验证新主节点状态

4. 更新其他从节点
   - 向其他从节点发送 SLAVEOF 新主节点
   - 控制并行同步数量（parallel-syncs）
   - 监控同步进度

5. 更新配置
   - 更新哨兵配置文件
   - 通知客户端新主节点信息
   - 发布配置变更事件
```

### 哨兵通信机制

#### 发布/订阅通信

哨兵使用 Redis 的发布/订阅功能进行通信：

```bash
# 哨兵通信频道
__sentinel__:hello          # 哨兵发现和信息交换
+switch-master             # 主节点切换通知
+slave                     # 从节点发现通知
+sentinel                  # 哨兵发现通知
+sdown                     # 主观下线通知
+odown                     # 客观下线通知
+failover-triggered        # 故障转移触发通知
+failover-state-*          # 故障转移状态变更
```

#### 哨兵发现机制

```
哨兵发现流程：

1. 主节点发现
   - 通过配置文件指定初始主节点
   - 哨兵连接并监控主节点

2. 从节点发现
   - 通过 INFO replication 命令获取从节点列表
   - 自动连接和监控发现的从节点

3. 哨兵发现
   - 通过 __sentinel__:hello 频道发布自己的信息
   - 订阅该频道发现其他哨兵
   - 建立哨兵之间的连接

4. 信息同步
   - 定期交换监控信息
   - 同步实例状态和配置
   - 协调故障检测和转移
```

## 哨兵模式配置

### 基本配置

#### 哨兵配置文件

```bash
# 创建哨兵配置文件 sentinel.conf
cat > /tmp/sentinel.conf << 'EOF'
# Redis 哨兵配置文件

# 哨兵端口
port 26379

# 哨兵工作目录
dir /tmp

# 监控的主节点配置
# sentinel monitor <master-name> <ip> <port> <quorum>
sentinel monitor mymaster 127.0.0.1 6379 2

# 主节点认证密码
sentinel auth-pass mymaster your_password

# 主观下线时间（毫秒）
sentinel down-after-milliseconds mymaster 30000

# 故障转移超时时间（毫秒）
sentinel failover-timeout mymaster 180000

# 并行同步的从节点数量
sentinel parallel-syncs mymaster 1

# 哨兵认证（可选）
requirepass sentinel_password

# 日志配置
logfile "/var/log/redis/sentinel.log"
loglevel notice

# 通知脚本（可选）
# sentinel notification-script mymaster /path/to/notify.sh

# 客户端重配置脚本（可选）
# sentinel client-reconfig-script mymaster /path/to/reconfig.sh

# 拒绝危险命令
sentinel deny-scripts-reconfig yes
EOF
```

#### 多哨兵配置

```bash
# 哨兵1配置
cat > /tmp/sentinel-1.conf << 'EOF'
port 26379
dir /tmp/sentinel-1
logfile "sentinel-1.log"
pidfile "sentinel-1.pid"

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster master_password
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
EOF

# 哨兵2配置
cat > /tmp/sentinel-2.conf << 'EOF'
port 26380
dir /tmp/sentinel-2
logfile "sentinel-2.log"
pidfile "sentinel-2.pid"

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster master_password
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
EOF

# 哨兵3配置
cat > /tmp/sentinel-3.conf << 'EOF'
port 26381
dir /tmp/sentinel-3
logfile "sentinel-3.log"
pidfile "sentinel-3.pid"

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster master_password
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1
EOF
```

### 高级配置

#### 通知脚本配置

```bash
# 创建通知脚本
cat > /tmp/sentinel_notify.sh << 'EOF'
#!/bin/bash

# 哨兵通知脚本
# 参数：事件类型 实例类型 实例名称 IP 端口 其他信息

EVENT_TYPE=$1
INSTANCE_TYPE=$2
INSTANCE_NAME=$3
IP=$4
PORT=$5
OTHER_INFO=$6

# 日志文件
LOG_FILE="/var/log/redis/sentinel_events.log"

# 记录事件
echo "$(date): $EVENT_TYPE $INSTANCE_TYPE $INSTANCE_NAME $IP:$PORT $OTHER_INFO" >> $LOG_FILE

# 根据事件类型执行不同操作
case $EVENT_TYPE in
    "+switch-master")
        echo "主节点切换: $INSTANCE_NAME 从 $OTHER_INFO 切换到 $IP:$PORT" >> $LOG_FILE
        # 发送邮件通知
        # echo "Redis主节点已切换到 $IP:$PORT" | mail -s "Redis故障转移通知" admin@example.com
        # 更新负载均衡器配置
        # /path/to/update_lb_config.sh $IP $PORT
        ;;
    "+slave")
        echo "发现新从节点: $IP:$PORT" >> $LOG_FILE
        ;;
    "+sentinel")
        echo "发现新哨兵: $IP:$PORT" >> $LOG_FILE
        ;;
    "+sdown")
        echo "主观下线: $INSTANCE_TYPE $INSTANCE_NAME $IP:$PORT" >> $LOG_FILE
        ;;
    "+odown")
        echo "客观下线: $INSTANCE_TYPE $INSTANCE_NAME $IP:$PORT" >> $LOG_FILE
        # 发送告警
        # curl -X POST "https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK" \
        #      -H 'Content-type: application/json' \
        #      --data "{\"text\":\"Redis实例客观下线: $IP:$PORT\"}"
        ;;
    "+failover-triggered")
        echo "故障转移触发: $INSTANCE_NAME" >> $LOG_FILE
        ;;
esac

exit 0
EOF

chmod +x /tmp/sentinel_notify.sh
```

#### 客户端重配置脚本

```bash
# 创建客户端重配置脚本
cat > /tmp/client_reconfig.sh << 'EOF'
#!/bin/bash

# 客户端重配置脚本
# 在主节点切换时更新应用程序配置

MASTER_NAME=$1
ROLE=$2
STATE=$3
FROM_IP=$4
FROM_PORT=$5
TO_IP=$6
TO_PORT=$7

# 配置文件路径
APP_CONFIG="/etc/myapp/redis.conf"
NGINX_CONFIG="/etc/nginx/conf.d/redis_upstream.conf"

# 日志文件
LOG_FILE="/var/log/redis/client_reconfig.log"

echo "$(date): 客户端重配置 - $MASTER_NAME $ROLE $STATE $FROM_IP:$FROM_PORT -> $TO_IP:$TO_PORT" >> $LOG_FILE

if [ "$ROLE" = "master" ] && [ "$STATE" = "start" ]; then
    echo "更新应用程序配置..." >> $LOG_FILE
    
    # 更新应用程序配置文件
    if [ -f "$APP_CONFIG" ]; then
        sed -i "s/redis_host=.*/redis_host=$TO_IP/" $APP_CONFIG
        sed -i "s/redis_port=.*/redis_port=$TO_PORT/" $APP_CONFIG
        echo "应用程序配置已更新" >> $LOG_FILE
    fi
    
    # 更新 Nginx 上游配置
    if [ -f "$NGINX_CONFIG" ]; then
        cat > $NGINX_CONFIG << EOF_NGINX
upstream redis_backend {
    server $TO_IP:$TO_PORT max_fails=3 fail_timeout=30s;
}
EOF_NGINX
        nginx -s reload
        echo "Nginx配置已更新并重载" >> $LOG_FILE
    fi
    
    # 重启应用程序（可选）
    # systemctl restart myapp
    # echo "应用程序已重启" >> $LOG_FILE
    
    # 发送通知
    echo "Redis主节点已切换，应用程序配置已更新" | \
        mail -s "Redis配置更新通知" admin@example.com
fi

exit 0
EOF

chmod +x /tmp/client_reconfig.sh
```

#### 安全配置

```bash
# 安全增强的哨兵配置
cat > /tmp/sentinel_secure.conf << 'EOF'
# 安全增强的哨兵配置

# 基本配置
port 26379
dir /var/lib/redis/sentinel
logfile "/var/log/redis/sentinel.log"
pidfile "/var/run/redis/sentinel.pid"

# 绑定特定接口
bind 192.168.1.100 127.0.0.1

# 保护模式
protected-mode yes

# 哨兵认证
requirepass "$(openssl rand -base64 32)"

# 监控配置
sentinel monitor mymaster 192.168.1.100 6379 2
sentinel auth-pass mymaster "$(openssl rand -base64 32)"

# 超时配置
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

# 拒绝脚本重配置
sentinel deny-scripts-reconfig yes

# 通知脚本（使用绝对路径）
sentinel notification-script mymaster /usr/local/bin/sentinel_notify.sh
sentinel client-reconfig-script mymaster /usr/local/bin/client_reconfig.sh

# 日志级别
loglevel notice

# 限制连接数
# maxclients 100
EOF
```

### 动态配置管理

#### 运行时配置修改

```bash
# 连接到哨兵
redis-cli -p 26379

# 查看监控的主节点
SENTINEL masters

# 查看特定主节点的从节点
SENTINEL slaves mymaster

# 查看哨兵节点
SENTINEL sentinels mymaster

# 获取主节点地址
SENTINEL get-master-addr-by-name mymaster

# 动态修改配置
SENTINEL set mymaster down-after-milliseconds 60000
SENTINEL set mymaster failover-timeout 300000
SENTINEL set mymaster parallel-syncs 2

# 重置主节点（清除故障状态）
SENTINEL reset mymaster

# 强制故障转移
SENTINEL failover mymaster

# 移除主节点监控
SENTINEL remove mymaster

# 添加新的主节点监控
SENTINEL monitor newmaster 192.168.1.200 6379 2
```

#### 配置持久化

```bash
# 哨兵配置自动更新机制
echo "哨兵配置文件会自动更新以下内容："
echo "1. 发现的从节点信息"
echo "2. 发现的其他哨兵信息"
echo "3. 故障转移后的新主节点信息"
echo "4. 实例状态变更记录"

# 查看自动更新的配置
cat /tmp/sentinel.conf | grep -E "^# Generated by CONFIG REWRITE|^sentinel known-"

# 手动保存配置
redis-cli -p 26379 CONFIG REWRITE
```

## 哨兵模式管理

### 启动和停止

#### 启动哨兵

```bash
# 方法1：使用 redis-sentinel 命令
redis-sentinel /path/to/sentinel.conf

# 方法2：使用 redis-server 命令
redis-server /path/to/sentinel.conf --sentinel

# 后台启动
redis-sentinel /path/to/sentinel.conf --daemonize yes

# 使用 systemd 管理
sudo systemctl start redis-sentinel
sudo systemctl enable redis-sentinel

# 检查启动状态
ps aux | grep sentinel
netstat -tlnp | grep 26379
```

#### 停止哨兵

```bash
# 优雅停止
redis-cli -p 26379 SHUTDOWN

# 使用 systemd 停止
sudo systemctl stop redis-sentinel

# 强制停止
kill -TERM $(cat /var/run/redis/sentinel.pid)

# 检查停止状态
ps aux | grep sentinel
```

### 监控和诊断

#### 状态监控

```bash
# 哨兵状态监控脚本
cat > /tmp/sentinel_monitor.sh << 'EOF'
#!/bin/bash

SENTINEL_HOST="127.0.0.1"
SENTINEL_PORT="26379"
MASTER_NAME="mymaster"

echo "=== Redis 哨兵监控报告 ==="
echo "时间: $(date)"
echo "哨兵地址: $SENTINEL_HOST:$SENTINEL_PORT"
echo "主节点名称: $MASTER_NAME"
echo

# 检查哨兵连接
echo "=== 哨兵连接状态 ==="
if redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT ping > /dev/null 2>&1; then
    echo "✅ 哨兵连接正常"
else
    echo "❌ 哨兵连接失败"
    exit 1
fi
echo

# 获取主节点信息
echo "=== 主节点信息 ==="
master_info=$(redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL get-master-addr-by-name $MASTER_NAME)
if [ -n "$master_info" ]; then
    master_ip=$(echo $master_info | awk '{print $1}')
    master_port=$(echo $master_info | awk '{print $2}')
    echo "主节点地址: $master_ip:$master_port"
    
    # 检查主节点状态
    if redis-cli -h $master_ip -p $master_port ping > /dev/null 2>&1; then
        echo "主节点状态: ✅ 在线"
    else
        echo "主节点状态: ❌ 离线"
    fi
else
    echo "❌ 无法获取主节点信息"
fi
echo

# 获取从节点信息
echo "=== 从节点信息 ==="
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL slaves $MASTER_NAME | \
while read line; do
    if [[ $line =~ ^[0-9]+\) ]]; then
        echo "从节点 ${line%)*}:"
    elif [[ $line =~ ^ip ]]; then
        ip=$(echo $line | cut -d, -f1 | cut -d= -f2)
        port=$(echo $line | cut -d, -f2 | cut -d= -f2)
        echo "  地址: $ip:$port"
    elif [[ $line =~ ^flags ]]; then
        flags=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "  状态: $flags"
    fi
done
echo

# 获取哨兵节点信息
echo "=== 哨兵节点信息 ==="
sentinel_count=$(redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL sentinels $MASTER_NAME | grep -c "^ip")
echo "哨兵节点数量: $((sentinel_count + 1))"  # +1 包括当前连接的哨兵

redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL sentinels $MASTER_NAME | \
while read line; do
    if [[ $line =~ ^[0-9]+\) ]]; then
        echo "哨兵 ${line%)*}:"
    elif [[ $line =~ ^ip ]]; then
        ip=$(echo $line | cut -d, -f1 | cut -d= -f2)
        port=$(echo $line | cut -d, -f2 | cut -d= -f2)
        echo "  地址: $ip:$port"
    elif [[ $line =~ ^flags ]]; then
        flags=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "  状态: $flags"
    fi
done
echo

# 获取主节点详细状态
echo "=== 主节点详细状态 ==="
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL masters | \
while read line; do
    if [[ $line =~ ^name ]]; then
        name=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "主节点名称: $name"
    elif [[ $line =~ ^flags ]]; then
        flags=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "状态标志: $flags"
    elif [[ $line =~ ^num-slaves ]]; then
        slaves=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "从节点数量: $slaves"
    elif [[ $line =~ ^num-other-sentinels ]]; then
        sentinels=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "其他哨兵数量: $sentinels"
    elif [[ $line =~ ^quorum ]]; then
        quorum=$(echo $line | cut -d= -f2 | cut -d, -f1)
        echo "仲裁数量: $quorum"
    fi
done
EOF

chmod +x /tmp/sentinel_monitor.sh
```

#### 性能监控

```bash
# 哨兵性能监控脚本
cat > /tmp/sentinel_performance.sh << 'EOF'
#!/bin/bash

SENTINEL_PORTS=(26379 26380 26381)

echo "=== 哨兵性能监控 ==="
echo "时间: $(date)"
echo

for port in "${SENTINEL_PORTS[@]}"; do
    echo "=== 哨兵 $port 性能指标 ==="
    
    # 检查连接
    if ! redis-cli -p $port ping > /dev/null 2>&1; then
        echo "❌ 哨兵 $port 不可用"
        continue
    fi
    
    # 获取基本信息
    echo "基本信息:"
    redis-cli -p $port INFO server | grep -E "redis_version|uptime_in_seconds|process_id"
    
    # 获取内存使用
    echo "内存使用:"
    redis-cli -p $port INFO memory | grep -E "used_memory_human|used_memory_peak_human"
    
    # 获取网络统计
    echo "网络统计:"
    redis-cli -p $port INFO stats | grep -E "total_connections_received|total_commands_processed"
    
    # 获取哨兵特定信息
    echo "哨兵信息:"
    redis-cli -p $port INFO sentinel | grep -E "sentinel_masters|sentinel_running_scripts"
    
    echo
done

# 系统资源使用
echo "=== 系统资源使用 ==="
echo "CPU使用率:"
top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1

echo "内存使用:"
free -h | grep Mem

echo "磁盘使用:"
df -h | grep -E "/$|/var"

echo "网络连接:"
netstat -an | grep -E ":2637[0-9]" | wc -l
EOF

chmod +x /tmp/sentinel_performance.sh
```

### 故障处理

#### 常见问题诊断

```bash
# 哨兵故障诊断脚本
cat > /tmp/sentinel_diagnosis.sh << 'EOF'
#!/bin/bash

echo "=== Redis 哨兵故障诊断 ==="
echo "时间: $(date)"
echo

# 1. 检查哨兵进程
echo "=== 检查哨兵进程 ==="
sentinel_processes=$(ps aux | grep -E "redis-sentinel|redis-server.*sentinel" | grep -v grep)
if [ -n "$sentinel_processes" ]; then
    echo "✅ 发现哨兵进程:"
    echo "$sentinel_processes"
else
    echo "❌ 未发现哨兵进程"
fi
echo

# 2. 检查端口监听
echo "=== 检查端口监听 ==="
sentinel_ports=$(netstat -tlnp | grep -E ":2637[0-9]")
if [ -n "$sentinel_ports" ]; then
    echo "✅ 哨兵端口监听正常:"
    echo "$sentinel_ports"
else
    echo "❌ 未发现哨兵端口监听"
fi
echo

# 3. 检查配置文件
echo "=== 检查配置文件 ==="
config_files=("/etc/redis/sentinel.conf" "/tmp/sentinel.conf" "/usr/local/etc/redis/sentinel.conf")
for config in "${config_files[@]}"; do
    if [ -f "$config" ]; then
        echo "✅ 发现配置文件: $config"
        echo "监控的主节点:"
        grep "^sentinel monitor" "$config" || echo "  未配置监控主节点"
    fi
done
echo

# 4. 检查日志文件
echo "=== 检查日志文件 ==="
log_files=("/var/log/redis/sentinel.log" "/tmp/sentinel.log")
for log in "${log_files[@]}"; do
    if [ -f "$log" ]; then
        echo "✅ 发现日志文件: $log"
        echo "最近的错误信息:"
        tail -20 "$log" | grep -i error || echo "  未发现错误信息"
        echo "最近的警告信息:"
        tail -20 "$log" | grep -i warning || echo "  未发现警告信息"
    fi
done
echo

# 5. 检查网络连通性
echo "=== 检查网络连通性 ==="
redis_hosts=("127.0.0.1" "192.168.1.100" "192.168.1.101")
redis_ports=(6379 6380 6381)

for host in "${redis_hosts[@]}"; do
    for port in "${redis_ports[@]}"; do
        if timeout 3 bash -c "</dev/tcp/$host/$port" 2>/dev/null; then
            echo "✅ $host:$port 连接正常"
        else
            echo "❌ $host:$port 连接失败"
        fi
    done
done
echo

# 6. 检查防火墙
echo "=== 检查防火墙 ==="
if command -v iptables > /dev/null; then
    echo "iptables 规则:"
    sudo iptables -L | grep -E "6379|6380|6381|26379|26380|26381" || echo "  未发现相关规则"
fi

if command -v firewall-cmd > /dev/null; then
    echo "firewalld 端口:"
    sudo firewall-cmd --list-ports | grep -E "6379|6380|6381|26379|26380|26381" || echo "  未开放相关端口"
fi
echo

# 7. 检查系统资源
echo "=== 检查系统资源 ==="
echo "内存使用:"
free -h
echo "磁盘空间:"
df -h | grep -E "/$|/var|/tmp"
echo "文件描述符限制:"
ulimit -n
echo

# 8. 生成诊断建议
echo "=== 诊断建议 ==="
echo "1. 确保所有哨兵节点都在运行"
echo "2. 检查网络连通性和防火墙设置"
echo "3. 验证配置文件中的主节点信息"
echo "4. 查看日志文件中的详细错误信息"
echo "5. 确保有足够的系统资源"
echo "6. 验证 Redis 实例的认证配置"
EOF

chmod +x /tmp/sentinel_diagnosis.sh
```

#### 故障恢复

```bash
# 哨兵故障恢复脚本
cat > /tmp/sentinel_recovery.sh << 'EOF'
#!/bin/bash

echo "=== Redis 哨兵故障恢复 ==="
echo "时间: $(date)"
echo

# 配置参数
MASTER_NAME="mymaster"
SENTINEL_PORTS=(26379 26380 26381)
REDIS_MASTER="127.0.0.1:6379"
REDIS_SLAVES=("127.0.0.1:6380" "127.0.0.1:6381")

# 1. 检查当前状态
echo "=== 检查当前状态 ==="
working_sentinels=0
for port in "${SENTINEL_PORTS[@]}"; do
    if redis-cli -p $port ping > /dev/null 2>&1; then
        echo "✅ 哨兵 $port 正常运行"
        working_sentinels=$((working_sentinels + 1))
    else
        echo "❌ 哨兵 $port 不可用"
    fi
done

echo "可用哨兵数量: $working_sentinels/${#SENTINEL_PORTS[@]}"
echo

# 2. 检查主节点状态
echo "=== 检查主节点状态 ==="
master_ip=${REDIS_MASTER%:*}
master_port=${REDIS_MASTER#*:}

if redis-cli -h $master_ip -p $master_port ping > /dev/null 2>&1; then
    echo "✅ 主节点 $REDIS_MASTER 正常运行"
    master_available=true
else
    echo "❌ 主节点 $REDIS_MASTER 不可用"
    master_available=false
fi
echo

# 3. 检查从节点状态
echo "=== 检查从节点状态 ==="
available_slaves=()
for slave in "${REDIS_SLAVES[@]}"; do
    slave_ip=${slave%:*}
    slave_port=${slave#*:}
    if redis-cli -h $slave_ip -p $slave_port ping > /dev/null 2>&1; then
        echo "✅ 从节点 $slave 正常运行"
        available_slaves+=("$slave")
    else
        echo "❌ 从节点 $slave 不可用"
    fi
done

echo "可用从节点数量: ${#available_slaves[@]}/${#REDIS_SLAVES[@]}"
echo

# 4. 恢复策略
echo "=== 恢复策略 ==="

if [ $working_sentinels -eq 0 ]; then
    echo "❌ 所有哨兵都不可用，需要手动重启哨兵服务"
    echo "建议操作:"
    echo "1. 检查哨兵配置文件"
    echo "2. 重启哨兵服务: systemctl restart redis-sentinel"
    echo "3. 检查日志文件: tail -f /var/log/redis/sentinel.log"
    exit 1
elif [ $working_sentinels -lt 2 ]; then
    echo "⚠️  可用哨兵数量不足，建议尽快恢复其他哨兵"
else
    echo "✅ 哨兵数量充足，系统可以正常工作"
fi

if [ "$master_available" = false ]; then
    if [ ${#available_slaves[@]} -gt 0 ]; then
        echo "主节点不可用但有可用从节点，哨兵应该会自动进行故障转移"
        echo "等待故障转移完成..."
        
        # 等待故障转移
        for i in {1..30}; do
            sleep 2
            for port in "${SENTINEL_PORTS[@]}"; do
                if redis-cli -p $port ping > /dev/null 2>&1; then
                    new_master=$(redis-cli -p $port SENTINEL get-master-addr-by-name $MASTER_NAME 2>/dev/null)
                    if [ -n "$new_master" ] && [ "$new_master" != "$REDIS_MASTER" ]; then
                        echo "✅ 故障转移完成，新主节点: $new_master"
                        break 2
                    fi
                fi
            done
            echo "等待故障转移... ($i/30)"
        done
    else
        echo "❌ 主节点和所有从节点都不可用，需要手动恢复"
        echo "建议操作:"
        echo "1. 检查 Redis 实例状态"
        echo "2. 重启 Redis 服务"
        echo "3. 检查网络连通性"
        exit 1
    fi
fi

# 5. 重置哨兵状态（如果需要）
echo "=== 重置哨兵状态 ==="
read -p "是否需要重置哨兵状态？(y/n): " reset_sentinel
if [ "$reset_sentinel" = "y" ]; then
    for port in "${SENTINEL_PORTS[@]}"; do
        if redis-cli -p $port ping > /dev/null 2>&1; then
            echo "重置哨兵 $port 的状态..."
            redis-cli -p $port SENTINEL reset $MASTER_NAME
        fi
    done
    echo "哨兵状态重置完成"
fi

# 6. 验证恢复结果
echo "=== 验证恢复结果 ==="
sleep 5

for port in "${SENTINEL_PORTS[@]}"; do
    if redis-cli -p $port ping > /dev/null 2>&1; then
        echo "哨兵 $port 状态:"
        redis-cli -p $port SENTINEL masters | grep -E "name|ip|port|flags" | head -4
        echo
    fi
done

echo "=== 恢复完成 ==="
echo "请继续监控系统状态，确保所有组件正常工作"
EOF

chmod +x /tmp/sentinel_recovery.sh
```

## 实践操作

### 搭建哨兵集群

**需求描述：**
搭建一个完整的 Redis 哨兵集群，包括1个主节点、2个从节点和3个哨兵节点，学习哨兵的配置、管理和故障转移机制。

**实践细节和结果验证：**

```bash
echo "=== Redis 哨兵集群搭建实践 ==="

# 1. 环境准备
echo "=== 环境准备 ==="

# 创建工作目录
mkdir -p /tmp/redis_sentinel_cluster/{redis-master,redis-slave1,redis-slave2,sentinel1,sentinel2,sentinel3}
cd /tmp/redis_sentinel_cluster

# 生成密码
MASTER_PASSWORD="master_$(openssl rand -hex 8)"
SLAVE_PASSWORD="slave_$(openssl rand -hex 8)"
SENTINEL_PASSWORD="sentinel_$(openssl rand -hex 8)"

echo "生成的密码:"
echo "主节点密码: $MASTER_PASSWORD"
echo "从节点密码: $SLAVE_PASSWORD"
echo "哨兵密码: $SENTINEL_PASSWORD"
echo

# 2. 配置 Redis 实例
echo "=== 配置 Redis 实例 ==="

# 主节点配置
cat > redis-master/redis.conf << EOF
port 6379
bind 127.0.0.1
dir ./
logfile "redis-master.log"
pidfile "redis-master.pid"
daemonize yes

# 认证
requirepass $MASTER_PASSWORD

# 持久化
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-master.aof"
appendfsync everysec

# 复制配置
repl-backlog-size 10mb
repl-backlog-ttl 3600
min-slaves-to-write 1
min-slaves-max-lag 10

# 性能优化
maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
EOF

# 从节点1配置
cat > redis-slave1/redis.conf << EOF
port 6380
bind 127.0.0.1
dir ./
logfile "redis-slave1.log"
pidfile "redis-slave1.pid"
daemonize yes

# 认证
requirepass $SLAVE_PASSWORD

# 主从配置
replicaof 127.0.0.1 6379
masterauth $MASTER_PASSWORD
slave-read-only yes
slave-serve-stale-data yes
slave-priority 100

# 禁用持久化以提高性能
save ""
appendonly no

# 性能优化
maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
EOF

# 从节点2配置
cat > redis-slave2/redis.conf << EOF
port 6381
bind 127.0.0.1
dir ./
logfile "redis-slave2.log"
pidfile "redis-slave2.pid"
daemonize yes

# 认证
requirepass $SLAVE_PASSWORD

# 主从配置
replicaof 127.0.0.1 6379
masterauth $MASTER_PASSWORD
slave-read-only yes
slave-serve-stale-data yes
slave-priority 90

# 禁用持久化
save ""
appendonly no

# 性能优化
maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
EOF

# 3. 配置哨兵节点
echo "=== 配置哨兵节点 ==="

# 哨兵1配置
cat > sentinel1/sentinel.conf << EOF
port 26379
bind 127.0.0.1
dir ./
logfile "sentinel1.log"
pidfile "sentinel1.pid"
daemonize yes

# 哨兵认证
requirepass $SENTINEL_PASSWORD

# 监控主节点
sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster $MASTER_PASSWORD

# 故障检测配置
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

# 通知脚本
sentinel notification-script mymaster /tmp/redis_sentinel_cluster/notify.sh
sentinel client-reconfig-script mymaster /tmp/redis_sentinel_cluster/reconfig.sh

# 安全配置
sentinel deny-scripts-reconfig yes
EOF

# 哨兵2配置
cat > sentinel2/sentinel.conf << EOF
port 26380
bind 127.0.0.1
dir ./
logfile "sentinel2.log"
pidfile "sentinel2.pid"
daemonize yes

requirepass $SENTINEL_PASSWORD

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster $MASTER_PASSWORD
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel notification-script mymaster /tmp/redis_sentinel_cluster/notify.sh
sentinel client-reconfig-script mymaster /tmp/redis_sentinel_cluster/reconfig.sh
sentinel deny-scripts-reconfig yes
EOF

# 哨兵3配置
cat > sentinel3/sentinel.conf << EOF
port 26381
bind 127.0.0.1
dir ./
logfile "sentinel3.log"
pidfile "sentinel3.pid"
daemonize yes

requirepass $SENTINEL_PASSWORD

sentinel monitor mymaster 127.0.0.1 6379 2
sentinel auth-pass mymaster $MASTER_PASSWORD
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel notification-script mymaster /tmp/redis_sentinel_cluster/notify.sh
sentinel client-reconfig-script mymaster /tmp/redis_sentinel_cluster/reconfig.sh
sentinel deny-scripts-reconfig yes
EOF

# 4. 创建通知脚本
echo "=== 创建通知脚本 ==="

cat > notify.sh << 'EOF'
#!/bin/bash
echo "$(date): 哨兵事件 - $*" >> /tmp/redis_sentinel_cluster/sentinel_events.log
EOF

cat > reconfig.sh << 'EOF'
#!/bin/bash
echo "$(date): 客户端重配置 - $*" >> /tmp/redis_sentinel_cluster/reconfig_events.log
EOF

chmod +x notify.sh reconfig.sh

# 5. 启动 Redis 实例
echo "=== 启动 Redis 实例 ==="

# 启动主节点
echo "启动主节点..."
cd redis-master
redis-server redis.conf
cd ..
sleep 2

# 验证主节点
if redis-cli -p 6379 -a "$MASTER_PASSWORD" ping > /dev/null 2>&1; then
    echo "✅ 主节点启动成功"
else
    echo "❌ 主节点启动失败"
    exit 1
fi

# 启动从节点
echo "启动从节点1..."
cd redis-slave1
redis-server redis.conf
cd ..

echo "启动从节点2..."
cd redis-slave2
redis-server redis.conf
cd ..

sleep 3

# 验证从节点
for port in 6380 6381; do
    if redis-cli -p $port -a "$SLAVE_PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ 从节点 $port 启动成功"
    else
        echo "❌ 从节点 $port 启动失败"
    fi
done

# 6. 启动哨兵节点
echo "=== 启动哨兵节点 ==="

for i in {1..3}; do
    echo "启动哨兵$i..."
    cd sentinel$i
    redis-sentinel sentinel.conf
    cd ..
    sleep 2
done

# 验证哨兵
for port in 26379 26380 26381; do
    if redis-cli -p $port -a "$SENTINEL_PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ 哨兵 $port 启动成功"
    else
        echo "❌ 哨兵 $port 启动失败"
    fi
done

# 等待哨兵发现所有实例
echo "等待哨兵发现所有实例..."
sleep 10

# 7. 验证集群状态
echo "=== 验证集群状态 ==="

# 检查主从复制
echo "主节点复制状态:"
redis-cli -p 6379 -a "$MASTER_PASSWORD" INFO replication | grep -E "role|connected_slaves"

echo "从节点1复制状态:"
redis-cli -p 6380 -a "$SLAVE_PASSWORD" INFO replication | grep -E "role|master_host|master_link_status"

echo "从节点2复制状态:"
redis-cli -p 6381 -a "$SLAVE_PASSWORD" INFO replication | grep -E "role|master_host|master_link_status"

# 检查哨兵状态
echo "哨兵监控状态:"
for port in 26379 26380 26381; do
    echo "哨兵 $port:"
    redis-cli -p $port -a "$SENTINEL_PASSWORD" SENTINEL masters | grep -E "name|ip|port|num-slaves|num-other-sentinels" | head -5
    echo
done

# 8. 测试数据同步
echo "=== 测试数据同步 ==="

# 在主节点写入测试数据
echo "在主节点写入测试数据..."
redis-cli -p 6379 -a "$MASTER_PASSWORD" << 'EOF'
SET sentinel:test "Hello Sentinel"
LPUSH sentinel:list "item1" "item2" "item3"
SADD sentinel:set "member1" "member2" "member3"
HMSET sentinel:hash field1 "value1" field2 "value2"
ZADD sentinel:zset 1 "first" 2 "second" 3 "third"
EOF

# 等待同步
sleep 2

# 验证从节点数据
echo "验证从节点数据同步:"
for port in 6380 6381; do
    echo "从节点 $port 数据:"
    redis-cli -p $port -a "$SLAVE_PASSWORD" << 'EOF'
GET sentinel:test
LLEN sentinel:list
SCARD sentinel:set
HLEN sentinel:hash
ZCARD sentinel:zset
EOF
    echo
done

# 9. 测试故障转移
echo "=== 测试故障转移 ==="

read -p "是否测试故障转移？(y/n): " test_failover
if [ "$test_failover" = "y" ]; then
    echo "模拟主节点故障..."
    
    # 记录当前主节点
    current_master=$(redis-cli -p 26379 -a "$SENTINEL_PASSWORD" SENTINEL get-master-addr-by-name mymaster)
    echo "当前主节点: $current_master"
    
    # 停止主节点
    redis-cli -p 6379 -a "$MASTER_PASSWORD" SHUTDOWN NOSAVE
    echo "主节点已停止"
    
    # 等待故障转移
    echo "等待故障转移..."
    for i in {1..30}; do
        sleep 2
        new_master=$(redis-cli -p 26379 -a "$SENTINEL_PASSWORD" SENTINEL get-master-addr-by-name mymaster 2>/dev/null)
        if [ -n "$new_master" ] && [ "$new_master" != "$current_master" ]; then
            echo "✅ 故障转移完成！"
            echo "新主节点: $new_master"
            break
        fi
        echo "等待故障转移... ($i/30)"
    done
    
    # 验证新主节点
    new_master_ip=$(echo $new_master | awk '{print $1}')
    new_master_port=$(echo $new_master | awk '{print $2}')
    
    if [ -n "$new_master_ip" ] && [ -n "$new_master_port" ]; then
        echo "验证新主节点状态:"
        redis-cli -h $new_master_ip -p $new_master_port -a "$SLAVE_PASSWORD" INFO replication | grep role
        
        # 测试写入新主节点
        echo "测试写入新主节点:"
        redis-cli -h $new_master_ip -p $new_master_port -a "$SLAVE_PASSWORD" SET failover:test "success"
        redis-cli -h $new_master_ip -p $new_master_port -a "$SLAVE_PASSWORD" GET failover:test
    fi
    
    # 查看哨兵事件日志
    echo "哨兵事件日志:"
    if [ -f "sentinel_events.log" ]; then
        tail -10 sentinel_events.log
    fi
fi

# 10. 性能测试
echo "=== 性能测试 ==="

# 获取当前主节点
current_master=$(redis-cli -p 26379 -a "$SENTINEL_PASSWORD" SENTINEL get-master-addr-by-name mymaster 2>/dev/null)
if [ -n "$current_master" ]; then
    master_ip=$(echo $current_master | awk '{print $1}')
    master_port=$(echo $current_master | awk '{print $2}')
    
    echo "当前主节点: $master_ip:$master_port"
    
    # 写性能测试
    echo "写性能测试 (1000 次操作):"
    time {
        for i in {1..1000}; do
            redis-cli -h $master_ip -p $master_port -a "$SLAVE_PASSWORD" SET "perf:$i" "value$i" > /dev/null
        done
    }
    
    # 读性能测试（从节点）
    echo "读性能测试 (1000 次操作):"
    time {
        for i in {1..1000}; do
            redis-cli -p 6380 -a "$SLAVE_PASSWORD" GET "perf:$i" > /dev/null
        done
    }
fi

# 11. 监控和管理
echo "=== 监控和管理 ==="

# 创建监控脚本
cat > monitor_cluster.sh << 'EOF'
#!/bin/bash

echo "=== Redis 哨兵集群监控 ==="
echo "时间: $(date)"
echo

# 检查 Redis 实例
echo "Redis 实例状态:"
for port in 6379 6380 6381; do
    if redis-cli -p $port ping > /dev/null 2>&1; then
        role=$(redis-cli -p $port INFO replication | grep "role:" | cut -d: -f2 | tr -d '\r')
        echo "  $port: ✅ $role"
    else
        echo "  $port: ❌ 离线"
    fi
done

echo
echo "哨兵实例状态:"
for port in 26379 26380 26381; do
    if redis-cli -p $port ping > /dev/null 2>&1; then
        echo "  $port: ✅ 在线"
    else
        echo "  $port: ❌ 离线"
    fi
done

echo
echo "当前主节点:"
redis-cli -p 26379 SENTINEL get-master-addr-by-name mymaster 2>/dev/null || echo "  无法获取主节点信息"
EOF

chmod +x monitor_cluster.sh

# 12. 清理环境
echo "=== 清理环境 ==="

read -p "是否清理测试环境？(y/n): " cleanup
if [ "$cleanup" = "y" ]; then
    echo "停止所有实例..."
    
    # 停止 Redis 实例
    for port in 6379 6380 6381; do
        redis-cli -p $port SHUTDOWN NOSAVE 2>/dev/null
    done
    
    # 停止哨兵实例
    for port in 26379 26380 26381; do
        redis-cli -p $port SHUTDOWN 2>/dev/null
    done
    
    echo "删除临时文件..."
    cd /tmp
    rm -rf redis_sentinel_cluster
    
    echo "✅ 环境清理完成"
else
    echo "保留测试环境，可继续进行其他测试"
    echo "监控脚本: /tmp/redis_sentinel_cluster/monitor_cluster.sh"
    echo "哨兵连接: redis-cli -p 26379 -a '$SENTINEL_PASSWORD'"
    echo "主节点连接: redis-cli -p 6379 -a '$MASTER_PASSWORD'"
    echo "从节点连接: redis-cli -p 6380 -a '$SLAVE_PASSWORD'"
fi

echo "=== 哨兵集群搭建实践完成 ==="
```

通过以上实践操作，我们全面学习了：

1. **哨兵模式原理**：监控机制、故障检测、故障转移流程的深入理解
2. **集群配置**：Redis实例配置、哨兵配置、安全认证设置
3. **环境搭建**：从零开始搭建完整的哨兵集群架构
4. **故障转移**：模拟主节点故障，观察自动故障转移过程
5. **状态监控**：实时监控集群状态、复制延迟、哨兵健康度
6. **性能测试**：读写分离性能验证、故障转移时间测量
7. **运维管理**：日常监控脚本、故障诊断、恢复策略
8. **最佳实践**：生产环境配置建议、安全设置、性能优化

这些实践为我们在生产环境中部署和管理 Redis 哨兵集群提供了完整的知识基础和实操经验，确保能够构建高可用、可靠的 Redis 服务架构。