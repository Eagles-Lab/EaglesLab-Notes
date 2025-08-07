# Redis 集群

Redis 集群（Redis Cluster）是 Redis 官方提供的分布式解决方案，通过数据分片和自动故障转移实现水平扩展和高可用性。它是构建大规模 Redis 应用的核心技术。

## Redis 集群概述

### 集群模式的概念

Redis 集群是一个分布式、去中心化的 Redis 实现，具有以下特点：

**核心特性：**
- **数据分片（Sharding）**：自动将数据分布到多个节点
- **高可用性（High Availability）**：支持主从复制和自动故障转移
- **水平扩展（Horizontal Scaling）**：支持动态添加和删除节点
- **去中心化（Decentralized）**：没有单点故障，所有节点地位平等

**架构组件：**
- **主节点（Master）**：处理读写请求，负责数据分片
- **从节点（Slave）**：复制主节点数据，提供读服务和故障转移
- **哈希槽（Hash Slot）**：数据分片的基本单位，共16384个槽
- **集群总线（Cluster Bus）**：节点间通信的专用通道

### 集群模式的优势

**性能优势：**
- 数据分片提高并发处理能力
- 多节点并行处理请求
- 减少单节点内存压力
- 支持大数据量存储

**可用性优势：**
- 自动故障检测和转移
- 主从复制保证数据安全
- 部分节点故障不影响整体服务
- 支持在线扩容和缩容

**扩展性优势：**
- 线性扩展存储容量
- 动态调整集群规模
- 支持跨数据中心部署
- 灵活的数据迁移机制

**管理优势：**
- 自动数据分布和负载均衡
- 简化的集群管理工具
- 丰富的监控和诊断功能
- 标准化的客户端支持

### 集群模式的应用场景

```
典型应用场景：

1. 大规模缓存系统
   应用层 → 负载均衡 → Redis集群
   支持TB级别的缓存数据

2. 分布式会话存储
   Web应用 → 会话管理 → Redis集群
   支持大量并发用户会话

3. 实时数据分析
   数据采集 → 实时计算 → Redis集群
   支持高频数据写入和查询

4. 消息队列系统
   生产者 → Redis集群 → 消费者
   支持大规模消息处理

5. 游戏排行榜
   游戏服务器 → Redis集群 → 排行榜系统
   支持全球用户排行榜

6. 电商购物车
   电商平台 → Redis集群 → 购物车服务
   支持海量用户购物车数据
```

## Redis 集群原理

### 数据分片机制

#### 哈希槽（Hash Slot）

Redis 集群使用哈希槽来实现数据分片：

```
哈希槽机制：

1. 槽位总数：16384 个（0-16383）
2. 槽位分配：平均分配给各个主节点
3. 数据映射：key → CRC16(key) % 16384 → 槽位 → 节点
4. 槽位迁移：支持在线重新分配槽位

示例分配（3个主节点）：
节点A：槽位 0-5460    （5461个槽）
节点B：槽位 5461-10922 （5462个槽）
节点C：槽位 10923-16383（5461个槽）
```

#### 数据路由

```bash
# 数据路由过程

# 1. 客户端计算槽位
key = "user:1001"
slot = CRC16(key) % 16384
# 假设 slot = 8000

# 2. 查找负责的节点
# 槽位 8000 属于节点B（5461-10922）

# 3. 重定向机制
# 如果客户端连接到错误的节点：
redis-cli -c -p 7001 GET user:1001
# 节点A响应：(error) MOVED 8000 192.168.1.102:7002
# 客户端自动重定向到节点B

# 4. ASK重定向（槽位迁移中）
# 如果槽位正在迁移：
# 源节点响应：(error) ASK 8000 192.168.1.103:7003
# 客户端发送 ASKING 命令后重试
```

### 集群通信机制

#### 集群总线（Cluster Bus）

```
集群总线特性：

1. 端口：Redis端口 + 10000
   Redis端口：7001 → 集群总线端口：17001

2. 协议：二进制协议，效率更高

3. 通信内容：
   - 节点状态信息
   - 槽位分配信息
   - 故障检测信息
   - 配置更新信息

4. 通信频率：
   - 心跳：每秒1次
   - Gossip：随机选择节点交换信息
   - 故障检测：实时
```

#### Gossip 协议

```
Gossip 协议工作流程：

1. 节点选择：每次随机选择几个节点
2. 信息交换：发送自己已知的集群状态
3. 信息合并：接收并更新集群状态信息
4. 信息传播：将新信息传播给其他节点

消息类型：
- PING：心跳消息，包含发送者状态
- PONG：心跳响应，包含接收者状态
- MEET：新节点加入集群
- FAIL：节点故障通知
- PUBLISH：发布/订阅消息
```

### 故障检测和转移

#### 故障检测机制

```bash
# 故障检测配置
# redis.conf

# 集群节点超时时间（毫秒）
cluster-node-timeout 15000

# 故障转移投票有效时间
cluster-slave-validity-factor 10

# 从节点迁移屏障
cluster-migration-barrier 1

# 集群要求槽位完整覆盖
cluster-require-full-coverage yes
```

**故障检测流程：**

1. **主观下线（PFAIL）**
   - 节点在超时时间内无响应
   - 标记为主观下线状态
   - 开始收集其他节点意见

2. **客观下线（FAIL）**
   - 超过半数主节点认为故障
   - 标记为客观下线状态
   - 触发故障转移流程

3. **故障转移**
   - 从节点发起选举
   - 获得多数票的从节点成为新主节点
   - 更新槽位分配信息

#### 故障转移过程

```
故障转移详细流程：

1. 故障检测
   - 主节点A无响应超过cluster-node-timeout
   - 其他节点标记A为PFAIL
   - 收集到足够PFAIL报告后标记为FAIL

2. 从节点选举
   - A的从节点们开始选举
   - 计算选举延迟：rank * 1000 + random(0,1000)
   - 延迟最小的从节点首先发起选举

3. 投票过程
   - 候选从节点向所有主节点请求投票
   - 主节点在一个配置纪元内只能投一票
   - 获得多数票（N/2+1）的从节点胜出

4. 角色切换
   - 胜出的从节点执行CLUSTER FAILOVER
   - 接管原主节点的槽位
   - 更新集群配置并广播

5. 配置传播
   - 新主节点广播配置更新
   - 其他节点更新路由表
   - 客户端更新连接信息
```

## Redis 集群配置

### 基本配置

#### 节点配置文件

```bash
# 创建集群节点配置模板
cat > /tmp/redis_cluster_template.conf << 'EOF'
# Redis 集群节点配置模板

# 基本配置
port 7001
bind 127.0.0.1
dir ./
logfile "redis-7001.log"
pidfile "redis-7001.pid"
daemonize yes

# 集群配置
cluster-enabled yes
cluster-config-file nodes-7001.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-7001.aof"
appendfsync everysec

# 内存配置
maxmemory 256mb
maxmemory-policy allkeys-lru

# 网络配置
tcp-keepalive 300
timeout 0

# 安全配置
requirepass your_password
masterauth your_password

# 性能优化
tcp-backlog 511
databases 1  # 集群模式只支持数据库0
EOF
```

#### 多节点配置生成

```bash
# 生成6节点集群配置脚本
cat > /tmp/generate_cluster_configs.sh << 'EOF'
#!/bin/bash

# 集群配置参数
BASE_PORT=7001
NODE_COUNT=6
PASSWORD="cluster_$(openssl rand -hex 8)"

echo "生成Redis集群配置文件"
echo "节点数量: $NODE_COUNT"
echo "起始端口: $BASE_PORT"
echo "集群密码: $PASSWORD"
echo

# 创建工作目录
mkdir -p /tmp/redis_cluster
cd /tmp/redis_cluster

# 为每个节点生成配置
for i in $(seq 0 $((NODE_COUNT-1))); do
    PORT=$((BASE_PORT + i))
    NODE_DIR="node-$PORT"
    
    echo "生成节点 $PORT 配置..."
    mkdir -p $NODE_DIR
    
    cat > $NODE_DIR/redis.conf << EOF
# Redis 集群节点 $PORT 配置

# 基本配置
port $PORT
bind 127.0.0.1
dir ./
logfile "redis-$PORT.log"
pidfile "redis-$PORT.pid"
daemonize yes

# 集群配置
cluster-enabled yes
cluster-config-file nodes-$PORT.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-$PORT.aof"
appendfsync everysec

# 内存配置
maxmemory 256mb
maxmemory-policy allkeys-lru

# 网络配置
tcp-keepalive 300
timeout 0

# 安全配置
requirepass $PASSWORD
masterauth $PASSWORD

# 性能优化
tcp-backlog 511
databases 1
EOF

done

echo "配置文件生成完成！"
echo "集群密码: $PASSWORD"
echo "节点目录: /tmp/redis_cluster/node-*"
EOF

chmod +x /tmp/generate_cluster_configs.sh
```

### 集群创建

#### 使用 redis-cli 创建集群

```bash
# 集群创建脚本
cat > /tmp/create_redis_cluster.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群创建脚本 ==="

# 配置参数
BASE_PORT=7001
NODE_COUNT=6
REPLICAS=1  # 每个主节点的从节点数量
CLUSTER_PASSWORD="cluster_password123"

# 1. 生成配置文件
echo "1. 生成配置文件..."
/tmp/generate_cluster_configs.sh

# 2. 启动所有节点
echo "2. 启动所有节点..."
cd /tmp/redis_cluster

for i in $(seq 0 $((NODE_COUNT-1))); do
    PORT=$((BASE_PORT + i))
    NODE_DIR="node-$PORT"
    
    echo "启动节点 $PORT..."
    cd $NODE_DIR
    redis-server redis.conf
    cd ..
    
    # 等待节点启动
    sleep 1
    
    # 验证节点启动
    if redis-cli -p $PORT -a "$CLUSTER_PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ 节点 $PORT 启动成功"
    else
        echo "❌ 节点 $PORT 启动失败"
        exit 1
    fi
done

echo
echo "3. 创建集群..."

# 构建节点列表
NODE_LIST=""
for i in $(seq 0 $((NODE_COUNT-1))); do
    PORT=$((BASE_PORT + i))
    NODE_LIST="$NODE_LIST 127.0.0.1:$PORT"
done

echo "节点列表: $NODE_LIST"
echo "副本数量: $REPLICAS"
echo

# 创建集群
echo "执行集群创建命令..."
redis-cli -a "$CLUSTER_PASSWORD" --cluster create $NODE_LIST --cluster-replicas $REPLICAS --cluster-yes

# 4. 验证集群状态
echo "4. 验证集群状态..."
sleep 3

echo "集群节点信息:"
redis-cli -p $BASE_PORT -a "$CLUSTER_PASSWORD" cluster nodes

echo
echo "集群状态信息:"
redis-cli -p $BASE_PORT -a "$CLUSTER_PASSWORD" cluster info

echo
echo "槽位分配信息:"
redis-cli -p $BASE_PORT -a "$CLUSTER_PASSWORD" cluster slots

echo
echo "=== 集群创建完成 ==="
echo "集群密码: $CLUSTER_PASSWORD"
echo "主节点端口: $BASE_PORT, $((BASE_PORT+1)), $((BASE_PORT+2))"
echo "从节点端口: $((BASE_PORT+3)), $((BASE_PORT+4)), $((BASE_PORT+5))"
echo "连接示例: redis-cli -c -p $BASE_PORT -a '$CLUSTER_PASSWORD'"
EOF

chmod +x /tmp/create_redis_cluster.sh
```

#### 手动创建集群

```bash
# 手动创建集群脚本
cat > /tmp/manual_cluster_setup.sh << 'EOF'
#!/bin/bash

echo "=== 手动创建 Redis 集群 ==="

# 配置参数
NODES=("127.0.0.1:7001" "127.0.0.1:7002" "127.0.0.1:7003" "127.0.0.1:7004" "127.0.0.1:7005" "127.0.0.1:7006")
PASSWORD="cluster_password123"

# 1. 让所有节点相互认识
echo "1. 建立节点间连接..."

for i in "${!NODES[@]}"; do
    current_node=${NODES[$i]}
    current_ip=${current_node%:*}
    current_port=${current_node#*:}
    
    echo "配置节点 $current_node..."
    
    for j in "${!NODES[@]}"; do
        if [ $i -ne $j ]; then
            target_node=${NODES[$j]}
            target_ip=${target_node%:*}
            target_port=${target_node#*:}
            
            echo "  连接到 $target_node"
            redis-cli -h $current_ip -p $current_port -a "$PASSWORD" CLUSTER MEET $target_ip $target_port
        fi
    done
done

echo "等待节点发现完成..."
sleep 5

# 2. 分配槽位
echo "2. 分配槽位..."

# 计算每个主节点的槽位范围
MASTER_COUNT=3
SLOTS_PER_MASTER=$((16384 / MASTER_COUNT))

for i in $(seq 0 $((MASTER_COUNT-1))); do
    node=${NODES[$i]}
    ip=${node%:*}
    port=${node#*:}
    
    start_slot=$((i * SLOTS_PER_MASTER))
    if [ $i -eq $((MASTER_COUNT-1)) ]; then
        # 最后一个主节点分配剩余的所有槽位
        end_slot=16383
    else
        end_slot=$(((i + 1) * SLOTS_PER_MASTER - 1))
    fi
    
    echo "为节点 $node 分配槽位 $start_slot-$end_slot"
    
    # 获取节点ID
    node_id=$(redis-cli -h $ip -p $port -a "$PASSWORD" CLUSTER MYID)
    
    # 分配槽位
    for slot in $(seq $start_slot $end_slot); do
        redis-cli -h $ip -p $port -a "$PASSWORD" CLUSTER ADDSLOTS $slot
    done
    
    echo "节点 $node (ID: $node_id) 分配槽位 $start_slot-$end_slot 完成"
done

echo "等待槽位分配完成..."
sleep 3

# 3. 配置主从关系
echo "3. 配置主从关系..."

# 获取主节点ID
master_ids=()
for i in $(seq 0 $((MASTER_COUNT-1))); do
    node=${NODES[$i]}
    ip=${node%:*}
    port=${node#*:}
    
    node_id=$(redis-cli -h $ip -p $port -a "$PASSWORD" CLUSTER MYID)
    master_ids+=($node_id)
    echo "主节点 $node ID: $node_id"
done

# 配置从节点
for i in $(seq $MASTER_COUNT $((${#NODES[@]}-1))); do
    slave_node=${NODES[$i]}
    slave_ip=${slave_node%:*}
    slave_port=${slave_node#*:}
    
    # 选择对应的主节点
    master_index=$((i - MASTER_COUNT))
    master_id=${master_ids[$master_index]}
    
    echo "配置从节点 $slave_node 复制主节点 ${NODES[$master_index]} (ID: $master_id)"
    redis-cli -h $slave_ip -p $slave_port -a "$PASSWORD" CLUSTER REPLICATE $master_id
done

echo "等待主从关系建立完成..."
sleep 5

# 4. 验证集群状态
echo "4. 验证集群状态..."

first_node=${NODES[0]}
first_ip=${first_node%:*}
first_port=${first_node#*:}

echo "集群信息:"
redis-cli -h $first_ip -p $first_port -a "$PASSWORD" CLUSTER INFO

echo
echo "集群节点:"
redis-cli -h $first_ip -p $first_port -a "$PASSWORD" CLUSTER NODES

echo
echo "=== 手动集群创建完成 ==="
EOF

chmod +x /tmp/manual_cluster_setup.sh
```

### 高级配置

#### 集群安全配置

```bash
# 安全增强的集群配置
cat > /tmp/secure_cluster_template.conf << 'EOF'
# 安全增强的 Redis 集群配置

# 基本配置
port 7001
bind 192.168.1.100 127.0.0.1  # 绑定特定网络接口
protected-mode yes
dir /var/lib/redis/cluster/
logfile "/var/log/redis/cluster-7001.log"
pidfile "/var/run/redis/cluster-7001.pid"
daemonize yes

# 集群配置
cluster-enabled yes
cluster-config-file nodes-7001.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes
cluster-allow-reads-when-down no

# 安全配置
requirepass "$(openssl rand -base64 32)"
masterauth "$(openssl rand -base64 32)"

# 重命名危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_$(openssl rand -hex 8)"
rename-command EVAL "EVAL_$(openssl rand -hex 8)"

# 连接限制
maxclients 10000
tcp-backlog 511

# 内存配置
maxmemory 2gb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes

appendonly yes
appendfilename "appendonly-7001.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# 网络优化
tcp-keepalive 300
timeout 0

# 日志配置
loglevel notice
syslog-enabled yes
syslog-ident redis-cluster-7001

# 性能优化
databases 1
lua-time-limit 5000
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端输出缓冲区限制
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
EOF
```

#### 性能优化配置

```bash
# 性能优化的集群配置
cat > /tmp/performance_cluster_template.conf << 'EOF'
# 性能优化的 Redis 集群配置

# 基本配置
port 7001
bind 0.0.0.0
dir ./
logfile "redis-7001.log"
pidfile "redis-7001.pid"
daemonize yes

# 集群配置
cluster-enabled yes
cluster-config-file nodes-7001.conf
cluster-node-timeout 5000     # 减少超时时间
cluster-slave-validity-factor 0  # 禁用从节点有效性检查
cluster-migration-barrier 1
cluster-require-full-coverage no  # 允许部分槽位不可用时继续服务

# 内存优化
maxmemory 8gb
maxmemory-policy allkeys-lru
maxmemory-samples 10

# 持久化优化
# 禁用 RDB 以提高性能
save ""
stop-writes-on-bgsave-error no

# AOF 优化
appendonly yes
appendfilename "appendonly-7001.aof"
appendfsync no  # 由操作系统决定何时同步
no-appendfsync-on-rewrite yes
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 1gb

# 网络优化
tcp-keepalive 60
tcp-backlog 2048
timeout 0

# 连接优化
maxclients 50000

# 客户端输出缓冲区优化
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 1gb 256mb 60
client-output-buffer-limit pubsub 128mb 32mb 60

# 性能调优
databases 1
lua-time-limit 5000
slowlog-log-slower-than 1000
slowlog-max-len 1000

# 哈希表优化
hash-max-ziplist-entries 512
hash-max-ziplist-value 64
list-max-ziplist-size -2
list-compress-depth 0
set-max-intset-entries 512
zset-max-ziplist-entries 128
zset-max-ziplist-value 64

# HyperLogLog 优化
hll-sparse-max-bytes 3000

# 流优化
stream-node-max-bytes 4096
stream-node-max-entries 100
EOF
```

## Redis 集群管理

### 集群操作命令

#### 基本管理命令

```bash
# 集群管理命令大全
cat > /tmp/cluster_commands.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群管理命令 ==="

# 连接参数
HOST="127.0.0.1"
PORT="7001"
PASSWORD="cluster_password123"

# 基本连接
echo "1. 基本连接"
echo "redis-cli -c -h $HOST -p $PORT -a '$PASSWORD'"
echo

# 集群信息查看
echo "2. 集群信息查看"
echo "# 查看集群基本信息"
echo "CLUSTER INFO"
echo
echo "# 查看集群节点信息"
echo "CLUSTER NODES"
echo
echo "# 查看槽位分配"
echo "CLUSTER SLOTS"
echo
echo "# 查看特定节点信息"
echo "CLUSTER NODES | grep master"
echo "CLUSTER NODES | grep slave"
echo

# 槽位管理
echo "3. 槽位管理"
echo "# 查看键所在的槽位"
echo "CLUSTER KEYSLOT key_name"
echo
echo "# 查看槽位中的键数量"
echo "CLUSTER COUNTKEYSINSLOT 1000"
echo
echo "# 获取槽位中的键"
echo "CLUSTER GETKEYSINSLOT 1000 10"
echo
echo "# 手动分配槽位"
echo "CLUSTER ADDSLOTS 1000 1001 1002"
echo
echo "# 删除槽位分配"
echo "CLUSTER DELSLOTS 1000 1001 1002"
echo

# 节点管理
echo "4. 节点管理"
echo "# 添加节点"
echo "CLUSTER MEET 192.168.1.100 7007"
echo
echo "# 忘记节点"
echo "CLUSTER FORGET node_id"
echo
echo "# 设置从节点"
echo "CLUSTER REPLICATE master_node_id"
echo
echo "# 故障转移"
echo "CLUSTER FAILOVER"
echo "CLUSTER FAILOVER FORCE"
echo "CLUSTER FAILOVER TAKEOVER"
echo

# 槽位迁移
echo "5. 槽位迁移"
echo "# 设置槽位为迁移状态"
echo "CLUSTER SETSLOT 1000 MIGRATING target_node_id"
echo "CLUSTER SETSLOT 1000 IMPORTING source_node_id"
echo
echo "# 迁移键"
echo "MIGRATE 192.168.1.101 7002 key_name 0 5000"
echo
echo "# 完成槽位迁移"
echo "CLUSTER SETSLOT 1000 NODE target_node_id"
echo

# 集群重置
echo "6. 集群重置"
echo "# 软重置（保留数据）"
echo "CLUSTER RESET SOFT"
echo
echo "# 硬重置（清除数据）"
echo "CLUSTER RESET HARD"
echo

# 调试命令
echo "7. 调试命令"
echo "# 保存集群配置"
echo "CLUSTER SAVECONFIG"
echo
echo "# 设置配置纪元"
echo "CLUSTER SET-CONFIG-EPOCH 1"
echo
echo "# 获取节点ID"
echo "CLUSTER MYID"
EOF

chmod +x /tmp/cluster_commands.sh
```

#### 集群状态监控

```bash
# 集群状态监控脚本
cat > /tmp/cluster_monitor.sh << 'EOF'
#!/bin/bash

# 配置参数
CLUSTER_NODES=("127.0.0.1:7001" "127.0.0.1:7002" "127.0.0.1:7003" "127.0.0.1:7004" "127.0.0.1:7005" "127.0.0.1:7006")
PASSWORD="cluster_password123"

echo "=== Redis 集群状态监控 ==="
echo "时间: $(date)"
echo

# 1. 检查节点连通性
echo "=== 节点连通性检查 ==="
online_nodes=0
offline_nodes=()

for node in "${CLUSTER_NODES[@]}"; do
    ip=${node%:*}
    port=${node#*:}
    
    if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ $node 在线"
        online_nodes=$((online_nodes + 1))
    else
        echo "❌ $node 离线"
        offline_nodes+=("$node")
    fi
done

echo "在线节点: $online_nodes/${#CLUSTER_NODES[@]}"
echo

# 2. 集群整体状态
if [ $online_nodes -gt 0 ]; then
    # 选择第一个在线节点
    for node in "${CLUSTER_NODES[@]}"; do
        ip=${node%:*}
        port=${node#*:}
        
        if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
            ACTIVE_NODE="$ip:$port"
            break
        fi
    done
    
    echo "=== 集群整体状态 ==="
    echo "活跃节点: $ACTIVE_NODE"
    echo
    
    # 集群基本信息
    cluster_info=$(redis-cli -h ${ACTIVE_NODE%:*} -p ${ACTIVE_NODE#*:} -a "$PASSWORD" CLUSTER INFO)
    echo "集群状态:"
    echo "$cluster_info" | grep -E "cluster_state|cluster_slots_assigned|cluster_slots_ok|cluster_slots_pfail|cluster_slots_fail|cluster_known_nodes|cluster_size"
    echo
    
    # 3. 节点角色分布
    echo "=== 节点角色分布 ==="
    nodes_info=$(redis-cli -h ${ACTIVE_NODE%:*} -p ${ACTIVE_NODE#*:} -a "$PASSWORD" CLUSTER NODES)
    
    master_count=$(echo "$nodes_info" | grep -c "master")
    slave_count=$(echo "$nodes_info" | grep -c "slave")
    
    echo "主节点数量: $master_count"
    echo "从节点数量: $slave_count"
    echo
    
    echo "主节点详情:"
    echo "$nodes_info" | grep "master" | while read line; do
        node_id=$(echo $line | awk '{print $1}')
        node_addr=$(echo $line | awk '{print $2}')
        node_flags=$(echo $line | awk '{print $3}')
        slots=$(echo $line | awk '{print $9}' | head -c 50)
        echo "  $node_addr ($node_flags) - 槽位: $slots..."
    done
    echo
    
    echo "从节点详情:"
    echo "$nodes_info" | grep "slave" | while read line; do
        node_id=$(echo $line | awk '{print $1}')
        node_addr=$(echo $line | awk '{print $2}')
        node_flags=$(echo $line | awk '{print $3}')
        master_id=$(echo $line | awk '{print $4}')
        echo "  $node_addr ($node_flags) - 主节点: $master_id"
    done
    echo
    
    # 4. 槽位分配状态
    echo "=== 槽位分配状态 ==="
    slots_info=$(redis-cli -h ${ACTIVE_NODE%:*} -p ${ACTIVE_NODE#*:} -a "$PASSWORD" CLUSTER SLOTS)
    
    total_slots=0
    echo "$slots_info" | while read line; do
        if [[ $line =~ ^[0-9]+$ ]]; then
            start_slot=$line
            read end_slot
            read master_info
            slot_count=$((end_slot - start_slot + 1))
            total_slots=$((total_slots + slot_count))
            echo "  槽位 $start_slot-$end_slot ($slot_count 个) -> $master_info"
        fi
    done
    
    assigned_slots=$(echo "$cluster_info" | grep "cluster_slots_assigned" | cut -d: -f2 | tr -d '\r')
    echo "已分配槽位: $assigned_slots/16384"
    echo
    
    # 5. 内存使用情况
    echo "=== 内存使用情况 ==="
    for node in "${CLUSTER_NODES[@]}"; do
        ip=${node%:*}
        port=${node#*:}
        
        if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
            memory_info=$(redis-cli -h $ip -p $port -a "$PASSWORD" INFO memory | grep "used_memory_human")
            role=$(redis-cli -h $ip -p $port -a "$PASSWORD" INFO replication | grep "role:" | cut -d: -f2 | tr -d '\r')
            echo "  $node ($role): $memory_info"
        fi
    done
    echo
    
    # 6. 性能指标
    echo "=== 性能指标 ==="
    for node in "${CLUSTER_NODES[@]}"; do
        ip=${node%:*}
        port=${node#*:}
        
        if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
            ops_per_sec=$(redis-cli -h $ip -p $port -a "$PASSWORD" INFO stats | grep "instantaneous_ops_per_sec" | cut -d: -f2 | tr -d '\r')
            connected_clients=$(redis-cli -h $ip -p $port -a "$PASSWORD" INFO clients | grep "connected_clients" | cut -d: -f2 | tr -d '\r')
            echo "  $node: ${ops_per_sec} ops/sec, ${connected_clients} 客户端"
        fi
    done
    echo
    
    # 7. 故障检测
    echo "=== 故障检测 ==="
    failed_nodes=$(echo "$nodes_info" | grep -E "fail|pfail")
    if [ -n "$failed_nodes" ]; then
        echo "⚠️  发现故障节点:"
        echo "$failed_nodes"
    else
        echo "✅ 未发现故障节点"
    fi
    echo
    
else
    echo "❌ 所有节点都不可用，无法获取集群状态"
fi

# 8. 生成监控报告
echo "=== 监控总结 ==="
echo "监控时间: $(date)"
echo "总节点数: ${#CLUSTER_NODES[@]}"
echo "在线节点数: $online_nodes"
echo "离线节点数: ${#offline_nodes[@]}"

if [ ${#offline_nodes[@]} -gt 0 ]; then
    echo "离线节点列表: ${offline_nodes[*]}"
fi

if [ $online_nodes -lt ${#CLUSTER_NODES[@]} ]; then
    echo "⚠️  集群存在节点故障，建议立即检查"
elif [ $online_nodes -eq ${#CLUSTER_NODES[@]} ]; then
    echo "✅ 集群状态正常"
fi
EOF

chmod +x /tmp/cluster_monitor.sh
```

### 集群扩容和缩容

#### 添加节点

```bash
# 集群扩容脚本
cat > /tmp/cluster_scale_out.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群扩容操作 ==="

# 配置参数
EXISTING_NODE="127.0.0.1:7001"
NEW_MASTER="127.0.0.1:7007"
NEW_SLAVE="127.0.0.1:7008"
PASSWORD="cluster_password123"

# 1. 准备新节点
echo "1. 准备新节点配置..."

# 创建新节点目录
mkdir -p /tmp/redis_cluster/node-7007
mkdir -p /tmp/redis_cluster/node-7008

# 生成新主节点配置
cat > /tmp/redis_cluster/node-7007/redis.conf << EOF
port 7007
bind 127.0.0.1
dir ./
logfile "redis-7007.log"
pidfile "redis-7007.pid"
daemonize yes

cluster-enabled yes
cluster-config-file nodes-7007.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

requirepass $PASSWORD
masterauth $PASSWORD

save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-7007.aof"
appendfsync everysec

maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
databases 1
EOF

# 生成新从节点配置
cat > /tmp/redis_cluster/node-7008/redis.conf << EOF
port 7008
bind 127.0.0.1
dir ./
logfile "redis-7008.log"
pidfile "redis-7008.pid"
daemonize yes

cluster-enabled yes
cluster-config-file nodes-7008.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

requirepass $PASSWORD
masterauth $PASSWORD

save ""
appendonly no

maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
databases 1
EOF

# 2. 启动新节点
echo "2. 启动新节点..."

cd /tmp/redis_cluster/node-7007
redis-server redis.conf
cd ../node-7008
redis-server redis.conf
cd ..

sleep 3

# 验证新节点启动
for port in 7007 7008; do
    if redis-cli -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ 新节点 $port 启动成功"
    else
        echo "❌ 新节点 $port 启动失败"
        exit 1
    fi
done

# 3. 添加新主节点到集群
echo "3. 添加新主节点到集群..."

echo "使用 redis-cli 添加新主节点:"
redis-cli -a "$PASSWORD" --cluster add-node ${NEW_MASTER} ${EXISTING_NODE}

# 等待节点加入
sleep 5

# 验证节点加入
echo "验证新主节点加入:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES | grep ${NEW_MASTER%:*}:${NEW_MASTER#*:}

# 4. 重新分配槽位
echo "4. 重新分配槽位..."

# 获取新主节点ID
NEW_MASTER_ID=$(redis-cli -h ${NEW_MASTER%:*} -p ${NEW_MASTER#*:} -a "$PASSWORD" CLUSTER MYID)
echo "新主节点ID: $NEW_MASTER_ID"

# 计算要迁移的槽位数量（假设平均分配）
CURRENT_MASTERS=3
NEW_MASTERS=4
SLOTS_PER_MASTER=$((16384 / NEW_MASTERS))
SLOTS_TO_MIGRATE=$((16384 / NEW_MASTERS))

echo "每个主节点应分配槽位数: $SLOTS_PER_MASTER"
echo "需要迁移的槽位数: $SLOTS_TO_MIGRATE"

# 使用 redis-cli 重新分片
echo "执行重新分片..."
redis-cli -a "$PASSWORD" --cluster reshard ${EXISTING_NODE} \
    --cluster-from all \
    --cluster-to $NEW_MASTER_ID \
    --cluster-slots $SLOTS_TO_MIGRATE \
    --cluster-yes

# 5. 添加新从节点
echo "5. 添加新从节点..."

echo "添加新从节点到集群:"
redis-cli -a "$PASSWORD" --cluster add-node ${NEW_SLAVE} ${EXISTING_NODE} --cluster-slave --cluster-master-id $NEW_MASTER_ID

# 等待从节点加入
sleep 5

# 6. 验证扩容结果
echo "6. 验证扩容结果..."

echo "集群节点信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES

echo
echo "集群状态信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER INFO

echo
echo "槽位分配验证:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER SLOTS | grep -A 2 -B 2 ${NEW_MASTER%:*}

# 7. 测试新节点
echo "7. 测试新节点..."

# 写入测试数据到新节点负责的槽位
echo "写入测试数据..."
for i in {1..100}; do
    key="scale_test:$i"
    slot=$(redis-cli -h ${NEW_MASTER%:*} -p ${NEW_MASTER#*:} -a "$PASSWORD" CLUSTER KEYSLOT $key)
    
    # 检查槽位是否属于新主节点
    slot_owner=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER SLOTS | \
                 awk -v slot=$slot '$1 <= slot && $2 >= slot {print $3; exit}')
    
    if [ "$slot_owner" = "${NEW_MASTER%:*}" ]; then
        redis-cli -c -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" SET $key "value_$i"
        echo "写入键 $key 到槽位 $slot (新主节点)"
        break
    fi
done

# 验证数据读取
echo "验证数据读取..."
redis-cli -c -h ${NEW_MASTER%:*} -p ${NEW_MASTER#*:} -a "$PASSWORD" GET $key
redis-cli -c -h ${NEW_SLAVE%:*} -p ${NEW_SLAVE#*:} -a "$PASSWORD" GET $key

echo
echo "=== 集群扩容完成 ==="
echo "新主节点: $NEW_MASTER (ID: $NEW_MASTER_ID)"
echo "新从节点: $NEW_SLAVE"
echo "集群现有节点数: 8 (4主4从)"
EOF

chmod +x /tmp/cluster_scale_out.sh
```

#### 删除节点

```bash
# 集群缩容脚本
cat > /tmp/cluster_scale_in.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群缩容操作 ==="

# 配置参数
EXISTING_NODE="127.0.0.1:7001"
REMOVE_MASTER="127.0.0.1:7007"
REMOVE_SLAVE="127.0.0.1:7008"
PASSWORD="cluster_password123"

# 1. 检查要删除的节点
echo "1. 检查要删除的节点..."

# 获取要删除的主节点ID
REMOVE_MASTER_ID=$(redis-cli -h ${REMOVE_MASTER%:*} -p ${REMOVE_MASTER#*:} -a "$PASSWORD" CLUSTER MYID 2>/dev/null)
REMOVE_SLAVE_ID=$(redis-cli -h ${REMOVE_SLAVE%:*} -p ${REMOVE_SLAVE#*:} -a "$PASSWORD" CLUSTER MYID 2>/dev/null)

echo "要删除的主节点: $REMOVE_MASTER (ID: $REMOVE_MASTER_ID)"
echo "要删除的从节点: $REMOVE_SLAVE (ID: $REMOVE_SLAVE_ID)"

# 检查节点状态
if [ -z "$REMOVE_MASTER_ID" ]; then
    echo "❌ 无法连接到要删除的主节点"
    exit 1
fi

# 2. 迁移槽位
echo "2. 迁移槽位..."

# 获取要删除节点的槽位
slots_info=$(redis-cli -h ${REMOVE_MASTER%:*} -p ${REMOVE_MASTER#*:} -a "$PASSWORD" CLUSTER NODES | grep $REMOVE_MASTER_ID)
slots_range=$(echo "$slots_info" | awk '{print $9}')

echo "要迁移的槽位: $slots_range"

if [ -n "$slots_range" ] && [ "$slots_range" != "-" ]; then
    # 计算槽位数量
    if [[ $slots_range =~ ^([0-9]+)-([0-9]+)$ ]]; then
        start_slot=${BASH_REMATCH[1]}
        end_slot=${BASH_REMATCH[2]}
        slot_count=$((end_slot - start_slot + 1))
    else
        slot_count=1
    fi
    
    echo "需要迁移 $slot_count 个槽位"
    
    # 获取目标节点（选择第一个其他主节点）
    target_nodes=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES | \
                   grep "master" | grep -v $REMOVE_MASTER_ID | head -3)
    
    echo "目标节点:"
    echo "$target_nodes"
    
    # 平均分配槽位到其他主节点
    target_count=$(echo "$target_nodes" | wc -l)
    slots_per_target=$((slot_count / target_count))
    
    echo "每个目标节点分配 $slots_per_target 个槽位"
    
    # 执行槽位迁移
    echo "开始槽位迁移..."
    
    target_index=0
    echo "$target_nodes" | while read target_line; do
        target_id=$(echo $target_line | awk '{print $1}')
        target_addr=$(echo $target_line | awk '{print $2}')
        
        start_migrate_slot=$((start_slot + target_index * slots_per_target))
        if [ $target_index -eq $((target_count - 1)) ]; then
            # 最后一个目标节点分配剩余的所有槽位
            end_migrate_slot=$end_slot
        else
            end_migrate_slot=$((start_migrate_slot + slots_per_target - 1))
        fi
        
        migrate_count=$((end_migrate_slot - start_migrate_slot + 1))
        
        echo "迁移槽位 $start_migrate_slot-$end_migrate_slot ($migrate_count 个) 到 $target_addr"
        
        # 使用 redis-cli 迁移槽位
        redis-cli -a "$PASSWORD" --cluster reshard ${EXISTING_NODE} \
            --cluster-from $REMOVE_MASTER_ID \
            --cluster-to $target_id \
            --cluster-slots $migrate_count \
            --cluster-yes
        
        target_index=$((target_index + 1))
    done
    
    echo "槽位迁移完成"
else
    echo "该节点没有分配槽位，跳过迁移"
fi

# 3. 删除从节点
echo "3. 删除从节点..."

if [ -n "$REMOVE_SLAVE_ID" ]; then
    echo "删除从节点 $REMOVE_SLAVE..."
    redis-cli -a "$PASSWORD" --cluster del-node ${EXISTING_NODE} $REMOVE_SLAVE_ID
    
    # 验证从节点删除
    sleep 2
    remaining_slave=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES | grep $REMOVE_SLAVE_ID)
    if [ -z "$remaining_slave" ]; then
        echo "✅ 从节点删除成功"
    else
        echo "❌ 从节点删除失败"
    fi
else
    echo "从节点不可用，跳过删除"
fi

# 4. 删除主节点
echo "4. 删除主节点..."

# 再次检查主节点是否还有槽位
remaining_slots=$(redis-cli -h ${REMOVE_MASTER%:*} -p ${REMOVE_MASTER#*:} -a "$PASSWORD" CLUSTER NODES | \
                  grep $REMOVE_MASTER_ID | awk '{print $9}')

if [ "$remaining_slots" = "-" ] || [ -z "$remaining_slots" ]; then
    echo "删除主节点 $REMOVE_MASTER..."
    redis-cli -a "$PASSWORD" --cluster del-node ${EXISTING_NODE} $REMOVE_MASTER_ID
    
    # 验证主节点删除
    sleep 2
    remaining_master=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES | grep $REMOVE_MASTER_ID)
    if [ -z "$remaining_master" ]; then
        echo "✅ 主节点删除成功"
    else
        echo "❌ 主节点删除失败"
    fi
else
    echo "❌ 主节点仍有槽位分配，无法删除: $remaining_slots"
    echo "请先完成槽位迁移"
    exit 1
fi

# 5. 停止已删除的节点
echo "5. 停止已删除的节点..."

for port in ${REMOVE_MASTER#*:} ${REMOVE_SLAVE#*:}; do
    echo "停止节点 $port..."
    redis-cli -p $port -a "$PASSWORD" SHUTDOWN NOSAVE 2>/dev/null || echo "节点 $port 已停止或不可用"
done

# 6. 验证缩容结果
echo "6. 验证缩容结果..."

echo "剩余集群节点:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER NODES

echo
echo "集群状态信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER INFO

echo
echo "槽位分配验证:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} -a "$PASSWORD" CLUSTER SLOTS

# 7. 清理节点文件
echo "7. 清理节点文件..."

read -p "是否删除已移除节点的数据文件? (y/n): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo "清理节点数据文件..."
    rm -rf /tmp/redis_cluster/node-${REMOVE_MASTER#*:}
    rm -rf /tmp/redis_cluster/node-${REMOVE_SLAVE#*:}
    echo "✅ 数据文件清理完成"
else
    echo "保留节点数据文件"
fi

echo
echo "=== 集群缩容完成 ==="
echo "已删除主节点: $REMOVE_MASTER"
echo "已删除从节点: $REMOVE_SLAVE"
echo "集群现有节点数: 6 (3主3从)"
EOF

chmod +x /tmp/cluster_scale_in.sh
```

### 故障处理

#### 节点故障恢复

```bash
# 节点故障恢复脚本
cat > /tmp/cluster_recovery.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群故障恢复 ==="

# 配置参数
CLUSTER_NODES=("127.0.0.1:7001" "127.0.0.1:7002" "127.0.0.1:7003" "127.0.0.1:7004" "127.0.0.1:7005" "127.0.0.1:7006")
PASSWORD="cluster_password123"

# 1. 故障检测
echo "1. 执行故障检测..."

failed_nodes=()
online_nodes=()

for node in "${CLUSTER_NODES[@]}"; do
    ip=${node%:*}
    port=${node#*:}
    
    if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        online_nodes+=("$node")
        echo "✅ $node 正常"
    else
        failed_nodes+=("$node")
        echo "❌ $node 故障"
    fi
done

echo "在线节点: ${#online_nodes[@]}"
echo "故障节点: ${#failed_nodes[@]}"

if [ ${#failed_nodes[@]} -eq 0 ]; then
    echo "✅ 所有节点正常，无需恢复"
    exit 0
fi

if [ ${#online_nodes[@]} -eq 0 ]; then
    echo "❌ 所有节点都故障，需要手动恢复"
    exit 1
fi

# 2. 分析故障类型
echo "2. 分析故障类型..."

# 选择一个在线节点查看集群状态
active_node=${online_nodes[0]}
active_ip=${active_node%:*}
active_port=${active_node#*:}

echo "使用活跃节点: $active_node"

# 获取集群状态
cluster_info=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER INFO)
cluster_state=$(echo "$cluster_info" | grep "cluster_state" | cut -d: -f2 | tr -d '\r')

echo "集群状态: $cluster_state"

if [ "$cluster_state" = "ok" ]; then
    echo "✅ 集群状态正常，可能是从节点故障"
    failure_type="slave"
elif [ "$cluster_state" = "fail" ]; then
    echo "⚠️  集群状态异常，可能是主节点故障"
    failure_type="master"
else
    echo "❓ 集群状态未知: $cluster_state"
    failure_type="unknown"
fi

# 获取故障节点详情
echo "故障节点详情:"
for failed_node in "${failed_nodes[@]}"; do
    failed_ip=${failed_node%:*}
    failed_port=${failed_node#*:}
    
    # 从集群信息中查找该节点
    node_info=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER NODES | grep "$failed_ip:$failed_port")
    
    if [ -n "$node_info" ]; then
        node_id=$(echo "$node_info" | awk '{print $1}')
        node_role=$(echo "$node_info" | awk '{print $3}' | grep -o "master\|slave")
        node_status=$(echo "$node_info" | awk '{print $3}')
        
        echo "  $failed_node: $node_role, 状态: $node_status, ID: $node_id"
        
        if [[ $node_status == *"fail"* ]]; then
            echo "    ⚠️  节点被标记为故障"
        fi
        
        if [ "$node_role" = "master" ]; then
            slots=$(echo "$node_info" | awk '{print $9}')
            echo "    槽位: $slots"
        fi
    else
        echo "  $failed_node: 未在集群中找到"
    fi
done

# 3. 尝试自动恢复
echo "3. 尝试自动恢复..."

for failed_node in "${failed_nodes[@]}"; do
    failed_ip=${failed_node%:*}
    failed_port=${failed_node#*:}
    
    echo "尝试恢复节点 $failed_node..."
    
    # 检查进程是否存在
    if pgrep -f "redis-server.*$failed_port" > /dev/null; then
        echo "  Redis进程存在，尝试重启..."
        pkill -f "redis-server.*$failed_port"
        sleep 2
    fi
    
    # 尝试启动节点
    node_dir="/tmp/redis_cluster/node-$failed_port"
    if [ -d "$node_dir" ] && [ -f "$node_dir/redis.conf" ]; then
        echo "  启动Redis节点..."
        cd "$node_dir"
        redis-server redis.conf
        cd - > /dev/null
        
        # 等待启动
        sleep 5
        
        # 验证启动
        if redis-cli -h $failed_ip -p $failed_port -a "$PASSWORD" ping > /dev/null 2>&1; then
            echo "  ✅ 节点 $failed_node 恢复成功"
            
            # 检查是否需要重新加入集群
            node_cluster_info=$(redis-cli -h $failed_ip -p $failed_port -a "$PASSWORD" CLUSTER INFO)
            node_cluster_state=$(echo "$node_cluster_info" | grep "cluster_state" | cut -d: -f2 | tr -d '\r')
            
            if [ "$node_cluster_state" != "ok" ]; then
                echo "  节点需要重新加入集群..."
                
                # 重置节点集群状态
                redis-cli -h $failed_ip -p $failed_port -a "$PASSWORD" CLUSTER RESET SOFT
                
                # 重新加入集群
                redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER MEET $failed_ip $failed_port
                
                echo "  节点已重新加入集群"
            fi
        else
            echo "  ❌ 节点 $failed_node 恢复失败"
        fi
    else
        echo "  ❌ 找不到节点配置文件: $node_dir/redis.conf"
    fi
done

# 4. 验证恢复结果
echo "4. 验证恢复结果..."

sleep 10  # 等待集群状态稳定

# 重新检查节点状态
echo "重新检查节点状态:"
recovered_count=0
still_failed=()

for node in "${failed_nodes[@]}"; do
    ip=${node%:*}
    port=${node#*:}
    
    if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        echo "✅ $node 已恢复"
        recovered_count=$((recovered_count + 1))
    else
        echo "❌ $node 仍然故障"
        still_failed+=("$node")
    fi
done

# 检查集群整体状态
echo "检查集群整体状态:"
final_cluster_info=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER INFO)
final_cluster_state=$(echo "$final_cluster_info" | grep "cluster_state" | cut -d: -f2 | tr -d '\r')

echo "最终集群状态: $final_cluster_state"

if [ "$final_cluster_state" = "ok" ]; then
    echo "✅ 集群状态正常"
elif [ "$final_cluster_state" = "fail" ]; then
    echo "⚠️  集群状态仍然异常"
    
    # 检查是否需要手动故障转移
    echo "检查是否需要手动故障转移..."
    
    failed_masters=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER NODES | \
                     grep "master" | grep -E "fail|pfail")
    
    if [ -n "$failed_masters" ]; then
        echo "发现故障的主节点:"
        echo "$failed_masters"
        
        echo "尝试手动故障转移..."
        
        # 对每个故障主节点的从节点执行故障转移
        echo "$failed_masters" | while read master_line; do
            master_id=$(echo $master_line | awk '{print $1}')
            
            # 查找该主节点的从节点
            slaves=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER NODES | \
                     grep "slave $master_id")
            
            if [ -n "$slaves" ]; then
                slave_line=$(echo "$slaves" | head -1)
                slave_addr=$(echo $slave_line | awk '{print $2}')
                slave_ip=${slave_addr%:*}
                slave_port=${slave_addr#*:}
                
                echo "对从节点 $slave_addr 执行故障转移..."
                redis-cli -h $slave_ip -p $slave_port -a "$PASSWORD" CLUSTER FAILOVER FORCE
            fi
        done
        
        echo "等待故障转移完成..."
        sleep 10
        
        # 再次检查集群状态
        final_check=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER INFO | \
                      grep "cluster_state" | cut -d: -f2 | tr -d '\r')
        echo "故障转移后集群状态: $final_check"
    fi
fi

# 5. 生成恢复报告
echo "5. 生成恢复报告..."

echo
echo "=== 故障恢复报告 ==="
echo "恢复时间: $(date)"
echo "原故障节点数: ${#failed_nodes[@]}"
echo "成功恢复节点数: $recovered_count"
echo "仍然故障节点数: ${#still_failed[@]}"

if [ ${#still_failed[@]} -gt 0 ]; then
    echo "仍然故障的节点: ${still_failed[*]}"
    echo "建议手动检查这些节点的日志和配置"
fi

echo "最终集群状态: $final_cluster_state"

if [ "$final_cluster_state" = "ok" ] && [ ${#still_failed[@]} -eq 0 ]; then
    echo "✅ 故障恢复完全成功"
elif [ "$final_cluster_state" = "ok" ] && [ ${#still_failed[@]} -gt 0 ]; then
    echo "⚠️  集群功能正常，但部分节点仍需手动处理"
else
    echo "❌ 故障恢复不完整，需要进一步处理"
fi
EOF

chmod +x /tmp/cluster_recovery.sh
```

#### 数据一致性检查

```bash
# 数据一致性检查脚本
cat > /tmp/cluster_consistency_check.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群数据一致性检查 ==="

# 配置参数
CLUSTER_NODES=("127.0.0.1:7001" "127.0.0.1:7002" "127.0.0.1:7003" "127.0.0.1:7004" "127.0.0.1:7005" "127.0.0.1:7006")
PASSWORD="cluster_password123"
TEST_KEY_PREFIX="consistency_test"
TEST_COUNT=1000

# 1. 检查集群状态
echo "1. 检查集群状态..."

# 找到一个可用的节点
active_node=""
for node in "${CLUSTER_NODES[@]}"; do
    ip=${node%:*}
    port=${node#*:}
    
    if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        active_node="$node"
        break
    fi
done

if [ -z "$active_node" ]; then
    echo "❌ 无法找到可用的集群节点"
    exit 1
fi

active_ip=${active_node%:*}
active_port=${active_node#*:}

echo "使用活跃节点: $active_node"

# 检查集群状态
cluster_state=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER INFO | \
                grep "cluster_state" | cut -d: -f2 | tr -d '\r')

if [ "$cluster_state" != "ok" ]; then
    echo "❌ 集群状态异常: $cluster_state"
    echo "请先修复集群状态再进行一致性检查"
    exit 1
fi

echo "✅ 集群状态正常"

# 2. 获取集群拓扑
echo "2. 获取集群拓扑..."

# 获取所有节点信息
nodes_info=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER NODES)

# 解析主从关系
declare -A master_slaves
declare -A node_roles
declare -A node_addresses

while read line; do
    if [ -n "$line" ]; then
        node_id=$(echo $line | awk '{print $1}')
        node_addr=$(echo $line | awk '{print $2}')
        node_flags=$(echo $line | awk '{print $3}')
        master_id=$(echo $line | awk '{print $4}')
        
        node_addresses[$node_id]=$node_addr
        
        if [[ $node_flags == *"master"* ]]; then
            node_roles[$node_id]="master"
            master_slaves[$node_id]=""
        elif [[ $node_flags == *"slave"* ]]; then
            node_roles[$node_id]="slave"
            if [ -n "${master_slaves[$master_id]}" ]; then
                master_slaves[$master_id]="${master_slaves[$master_id]} $node_id"
            else
                master_slaves[$master_id]="$node_id"
            fi
        fi
    fi
done <<< "$nodes_info"

echo "集群拓扑:"
for master_id in "${!master_slaves[@]}"; do
    master_addr=${node_addresses[$master_id]}
    slaves=${master_slaves[$master_id]}
    
    echo "  主节点: $master_addr (ID: $master_id)"
    
    if [ -n "$slaves" ]; then
        for slave_id in $slaves; do
            slave_addr=${node_addresses[$slave_id]}
            echo "    从节点: $slave_addr (ID: $slave_id)"
        done
    else
        echo "    ⚠️  无从节点"
    fi
done

# 3. 写入测试数据
echo "3. 写入测试数据..."

echo "写入 $TEST_COUNT 个测试键..."
for i in $(seq 1 $TEST_COUNT); do
    key="${TEST_KEY_PREFIX}:$i"
    value="test_value_$i:$(date +%s)"
    
    # 使用集群模式写入
    redis-cli -c -h $active_ip -p $active_port -a "$PASSWORD" SET $key "$value" > /dev/null
    
    if [ $((i % 100)) -eq 0 ]; then
        echo "  已写入 $i 个键"
    fi
done

echo "✅ 测试数据写入完成"

# 4. 检查主从数据一致性
echo "4. 检查主从数据一致性..."

inconsistent_count=0
total_checks=0

for master_id in "${!master_slaves[@]}"; do
    master_addr=${node_addresses[$master_id]}
    master_ip=${master_addr%:*}
    master_port=${master_addr#*:}
    slaves=${master_slaves[$master_id]}
    
    echo "检查主节点 $master_addr 的数据一致性..."
    
    if [ -n "$slaves" ]; then
        for slave_id in $slaves; do
            slave_addr=${node_addresses[$slave_id]}
            slave_ip=${slave_addr%:*}
            slave_port=${slave_addr#*:}
            
            echo "  对比主节点 $master_addr 和从节点 $slave_addr..."
            
            # 随机选择一些键进行对比
            sample_size=50
            sample_keys=()
            
            for i in $(seq 1 $sample_size); do
                random_num=$((RANDOM % TEST_COUNT + 1))
                sample_keys+=("${TEST_KEY_PREFIX}:$random_num")
            done
            
            inconsistent_keys=()
            
            for key in "${sample_keys[@]}"; do
                # 检查键是否属于这个主节点
                key_slot=$(redis-cli -h $master_ip -p $master_port -a "$PASSWORD" CLUSTER KEYSLOT $key)
                key_node=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER SLOTS | \
                           awk -v slot=$key_slot '$1 <= slot && $2 >= slot {print $3; exit}')
                
                if [ "$key_node" = "$master_ip" ]; then
                    # 获取主节点的值
                    master_value=$(redis-cli -h $master_ip -p $master_port -a "$PASSWORD" GET $key 2>/dev/null)
                    
                    # 获取从节点的值
                    slave_value=$(redis-cli -h $slave_ip -p $slave_port -a "$PASSWORD" GET $key 2>/dev/null)
                    
                    total_checks=$((total_checks + 1))
                    
                    if [ "$master_value" != "$slave_value" ]; then
                        inconsistent_keys+=("$key")
                        inconsistent_count=$((inconsistent_count + 1))
                        echo "    ❌ 键 $key 不一致"
                        echo "       主节点值: $master_value"
                        echo "       从节点值: $slave_value"
                    fi
                fi
            done
            
            if [ ${#inconsistent_keys[@]} -eq 0 ]; then
                echo "    ✅ 数据一致"
            else
                echo "    ⚠️  发现 ${#inconsistent_keys[@]} 个不一致的键"
            fi
        done
    else
        echo "  ⚠️  该主节点没有从节点，跳过一致性检查"
    fi
done

# 5. 检查槽位覆盖
echo "5. 检查槽位覆盖..."

slots_coverage=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER INFO | \
                 grep "cluster_slots_assigned" | cut -d: -f2 | tr -d '\r')

echo "已分配槽位: $slots_coverage/16384"

if [ "$slots_coverage" -eq 16384 ]; then
    echo "✅ 槽位覆盖完整"
else
    echo "❌ 槽位覆盖不完整，缺少 $((16384 - slots_coverage)) 个槽位"
    
    # 查找未分配的槽位
    echo "查找未分配的槽位..."
    
    slots_info=$(redis-cli -h $active_ip -p $active_port -a "$PASSWORD" CLUSTER SLOTS)
    assigned_slots=()
    
    # 解析已分配的槽位范围
    while read line; do
        if [[ $line =~ ^[0-9]+$ ]]; then
            start_slot=$line
            read end_slot
            
            for slot in $(seq $start_slot $end_slot); do
                assigned_slots[$slot]=1
            done
        fi
    done <<< "$slots_info"
    
    # 查找未分配的槽位
    unassigned_slots=()
    for slot in $(seq 0 16383); do
        if [ -z "${assigned_slots[$slot]}" ]; then
            unassigned_slots+=($slot)
        fi
    done
    
    echo "未分配的槽位: ${unassigned_slots[*]:0:20}..."  # 只显示前20个
fi

# 6. 性能一致性检查
echo "6. 性能一致性检查..."

echo "检查各节点响应时间..."

for node in "${CLUSTER_NODES[@]}"; do
    ip=${node%:*}
    port=${node#*:}
    
    if redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null 2>&1; then
        # 测试响应时间
        start_time=$(date +%s%N)
        redis-cli -h $ip -p $port -a "$PASSWORD" ping > /dev/null
        end_time=$(date +%s%N)
        
        response_time=$(((end_time - start_time) / 1000000))  # 转换为毫秒
        
        echo "  $node: ${response_time}ms"
        
        if [ $response_time -gt 100 ]; then
            echo "    ⚠️  响应时间较慢"
        fi
    else
        echo "  $node: 不可用"
    fi
done

# 7. 清理测试数据
echo "7. 清理测试数据..."

read -p "是否删除测试数据? (y/n): " confirm
if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo "删除测试数据..."
    
    for i in $(seq 1 $TEST_COUNT); do
        key="${TEST_KEY_PREFIX}:$i"
        redis-cli -c -h $active_ip -p $active_port -a "$PASSWORD" DEL $key > /dev/null
        
        if [ $((i % 100)) -eq 0 ]; then
            echo "  已删除 $i 个键"
        fi
    done
    
    echo "✅ 测试数据清理完成"
else
    echo "保留测试数据"
fi

# 8. 生成一致性报告
echo "8. 生成一致性报告..."

echo
echo "=== 数据一致性检查报告 ==="
echo "检查时间: $(date)"
echo "集群状态: $cluster_state"
echo "槽位覆盖: $slots_coverage/16384"
echo "总检查次数: $total_checks"
echo "不一致次数: $inconsistent_count"

if [ $total_checks -gt 0 ]; then
    consistency_rate=$(((total_checks - inconsistent_count) * 100 / total_checks))
    echo "一致性率: $consistency_rate%"
else
    echo "一致性率: N/A (无有效检查)"
fi

if [ $inconsistent_count -eq 0 ] && [ "$slots_coverage" -eq 16384 ]; then
    echo "✅ 集群数据完全一致"
elif [ $inconsistent_count -eq 0 ]; then
    echo "⚠️  数据一致但槽位覆盖不完整"
else
    echo "❌ 发现数据不一致，建议进一步调查"
    echo "建议操作:"
    echo "  1. 检查网络连接"
    echo "  2. 检查复制延迟"
    echo "  3. 检查节点负载"
    echo "  4. 考虑手动同步数据"
fi
EOF

chmod +x /tmp/cluster_consistency_check.sh
```

## 实践操作

### 搭建 Redis 集群环境

本实践将指导您完成一个完整的 Redis 集群搭建、测试和管理过程。

#### 环境准备

```bash
# 创建实践环境脚本
cat > /tmp/cluster_practice_setup.sh << 'EOF'
#!/bin/bash

echo "=== Redis 集群实践环境搭建 ==="

# 1. 环境检查
echo "1. 检查环境依赖..."

# 检查 Redis 是否安装
if ! command -v redis-server &> /dev/null; then
    echo "❌ Redis 未安装，请先安装 Redis"
    echo "安装命令示例:"
    echo "  Ubuntu/Debian: sudo apt-get install redis-server"
    echo "  CentOS/RHEL: sudo yum install redis"
    echo "  macOS: brew install redis"
    exit 1
fi

echo "✅ Redis 已安装: $(redis-server --version)"

# 检查端口可用性
echo "检查端口可用性..."
for port in {7001..7006}; do
    if netstat -ln 2>/dev/null | grep ":$port " > /dev/null; then
        echo "❌ 端口 $port 已被占用"
        echo "请停止占用该端口的进程或选择其他端口"
        exit 1
    fi
done

echo "✅ 端口 7001-7006 可用"

# 2. 创建工作目录
echo "2. 创建工作目录..."

WORK_DIR="/tmp/redis_cluster_practice"
rm -rf $WORK_DIR
mkdir -p $WORK_DIR
cd $WORK_DIR

echo "工作目录: $WORK_DIR"

# 3. 生成集群配置
echo "3. 生成集群配置..."

CLUSTER_PASSWORD="practice_$(openssl rand -hex 8)"
echo "集群密码: $CLUSTER_PASSWORD"

# 为每个节点创建配置
for port in {7001..7006}; do
    node_dir="node-$port"
    mkdir -p $node_dir
    
    cat > $node_dir/redis.conf << EOF
# Redis 集群节点 $port 配置

# 基本配置
port $port
bind 127.0.0.1
dir ./
logfile "redis-$port.log"
pidfile "redis-$port.pid"
daemonize yes

# 集群配置
cluster-enabled yes
cluster-config-file nodes-$port.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

# 安全配置
requirepass $CLUSTER_PASSWORD
masterauth $CLUSTER_PASSWORD

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-$port.aof"
appendfsync everysec

# 内存配置
maxmemory 128mb
maxmemory-policy allkeys-lru

# 网络配置
tcp-keepalive 300
timeout 0

# 性能优化
tcp-backlog 511
databases 1
EOF

    echo "生成节点 $port 配置完成"
done

# 4. 创建管理脚本
echo "4. 创建管理脚本..."

# 启动脚本
cat > start_cluster.sh << 'SCRIPT'
#!/bin/bash
echo "启动 Redis 集群节点..."
for port in {7001..7006}; do
    cd node-$port
    redis-server redis.conf
    cd ..
    echo "节点 $port 已启动"
    sleep 1
done
echo "所有节点启动完成"
SCRIPT

# 停止脚本
cat > stop_cluster.sh << 'SCRIPT'
#!/bin/bash
echo "停止 Redis 集群节点..."
for port in {7001..7006}; do
    redis-cli -p $port -a "CLUSTER_PASSWORD_PLACEHOLDER" SHUTDOWN NOSAVE 2>/dev/null || echo "节点 $port 已停止"
    echo "节点 $port 已停止"
done
echo "所有节点停止完成"
SCRIPT

# 替换密码占位符
sed -i "s/CLUSTER_PASSWORD_PLACEHOLDER/$CLUSTER_PASSWORD/g" stop_cluster.sh

# 状态检查脚本
cat > check_cluster.sh << 'SCRIPT'
#!/bin/bash
echo "检查 Redis 集群状态..."
echo "节点连通性:"
for port in {7001..7006}; do
    if redis-cli -p $port -a "CLUSTER_PASSWORD_PLACEHOLDER" ping > /dev/null 2>&1; then
        echo "  ✅ 节点 $port 在线"
    else
        echo "  ❌ 节点 $port 离线"
    fi
done

echo
echo "集群信息:"
redis-cli -p 7001 -a "CLUSTER_PASSWORD_PLACEHOLDER" CLUSTER INFO 2>/dev/null || echo "无法获取集群信息"

echo
echo "集群节点:"
redis-cli -p 7001 -a "CLUSTER_PASSWORD_PLACEHOLDER" CLUSTER NODES 2>/dev/null || echo "无法获取节点信息"
SCRIPT

# 替换密码占位符
sed -i "s/CLUSTER_PASSWORD_PLACEHOLDER/$CLUSTER_PASSWORD/g" check_cluster.sh

# 设置脚本权限
chmod +x start_cluster.sh stop_cluster.sh check_cluster.sh

# 5. 创建测试脚本
echo "5. 创建测试脚本..."

cat > test_cluster.sh << 'SCRIPT'
#!/bin/bash
echo "=== Redis 集群功能测试 ==="

PASSWORD="CLUSTER_PASSWORD_PLACEHOLDER"

# 1. 基本读写测试
echo "1. 基本读写测试..."
for i in {1..10}; do
    key="test:key:$i"
    value="test_value_$i"
    
    # 写入数据
    redis-cli -c -p 7001 -a "$PASSWORD" SET $key "$value" > /dev/null
    
    # 读取数据
    result=$(redis-cli -c -p 7001 -a "$PASSWORD" GET $key)
    
    if [ "$result" = "$value" ]; then
        echo "  ✅ 键 $key 读写正常"
    else
        echo "  ❌ 键 $key 读写异常: 期望 $value, 实际 $result"
    fi
done

# 2. 数据分布测试
echo "2. 数据分布测试..."
echo "写入100个键，检查分布情况..."

declare -A node_counts
for port in {7001..7003}; do
    node_counts[$port]=0
done

for i in {1..100}; do
    key="dist_test:$i"
    value="value_$i"
    
    # 写入数据并获取重定向信息
    output=$(redis-cli -p 7001 -a "$PASSWORD" SET $key "$value" 2>&1)
    
    # 计算键的槽位
    slot=$(redis-cli -p 7001 -a "$PASSWORD" CLUSTER KEYSLOT $key)
    
    # 查找槽位对应的节点
    node_port=$(redis-cli -p 7001 -a "$PASSWORD" CLUSTER SLOTS | \
                awk -v slot=$slot '$1 <= slot && $2 >= slot {print $4; exit}')
    
    if [ -n "$node_port" ]; then
        node_counts[$node_port]=$((node_counts[$node_port] + 1))
    fi
done

echo "数据分布统计:"
for port in {7001..7003}; do
    count=${node_counts[$port]}
    echo "  节点 $port: $count 个键"
done

# 3. 故障转移测试
echo "3. 故障转移测试..."
echo "模拟从节点故障..."

# 停止一个从节点
redis-cli -p 7004 -a "$PASSWORD" DEBUG SEGFAULT 2>/dev/null || echo "从节点 7004 已停止"
sleep 5

# 检查集群状态
cluster_state=$(redis-cli -p 7001 -a "$PASSWORD" CLUSTER INFO | grep cluster_state | cut -d: -f2 | tr -d '\r')
echo "从节点故障后集群状态: $cluster_state"

# 重启从节点
cd node-7004
redis-server redis.conf
cd ..
echo "从节点 7004 已重启"

sleep 5

# 再次检查集群状态
cluster_state=$(redis-cli -p 7001 -a "$PASSWORD" CLUSTER INFO | grep cluster_state | cut -d: -f2 | tr -d '\r')
echo "从节点恢复后集群状态: $cluster_state"

# 4. 性能测试
echo "4. 性能测试..."
echo "执行性能基准测试..."

# 使用 redis-benchmark 测试
if command -v redis-benchmark &> /dev/null; then
    echo "SET 操作性能测试:"
    redis-benchmark -h 127.0.0.1 -p 7001 -a "$PASSWORD" -t set -n 1000 -q
    
    echo "GET 操作性能测试:"
    redis-benchmark -h 127.0.0.1 -p 7001 -a "$PASSWORD" -t get -n 1000 -q
else
    echo "redis-benchmark 不可用，跳过性能测试"
fi

echo "=== 集群功能测试完成 ==="
SCRIPT

# 替换密码占位符
sed -i "s/CLUSTER_PASSWORD_PLACEHOLDER/$CLUSTER_PASSWORD/g" test_cluster.sh
chmod +x test_cluster.sh

# 6. 创建说明文档
echo "6. 创建说明文档..."

cat > README.md << 'DOC'
# Redis 集群实践环境

## 环境说明

本环境包含6个Redis节点，构成一个3主3从的集群：
- 主节点：7001, 7002, 7003
- 从节点：7004, 7005, 7006

## 使用方法

### 1. 启动集群
```bash
./start_cluster.sh
```

### 2. 创建集群
```bash
redis-cli -a "CLUSTER_PASSWORD_PLACEHOLDER" --cluster create \
  127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 \
  127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 \
  --cluster-replicas 1 --cluster-yes
```

### 3. 检查集群状态
```bash
./check_cluster.sh
```

### 4. 测试集群功能
```bash
./test_cluster.sh
```

### 5. 连接集群
```bash
redis-cli -c -p 7001 -a "CLUSTER_PASSWORD_PLACEHOLDER"
```

### 6. 停止集群
```bash
./stop_cluster.sh
```

## 常用命令

- 查看集群信息：`CLUSTER INFO`
- 查看节点信息：`CLUSTER NODES`
- 查看槽位分配：`CLUSTER SLOTS`
- 计算键的槽位：`CLUSTER KEYSLOT key_name`

## 注意事项

1. 集群密码已设置，连接时需要提供密码
2. 数据持久化已启用，重启后数据不会丢失
3. 建议在测试完成后清理环境

DOC

# 替换密码占位符
sed -i "s/CLUSTER_PASSWORD_PLACEHOLDER/$CLUSTER_PASSWORD/g" README.md

echo
echo "=== 环境搭建完成 ==="
echo "工作目录: $WORK_DIR"
echo "集群密码: $CLUSTER_PASSWORD"
echo
echo "下一步操作:"
echo "1. cd $WORK_DIR"
echo "2. ./start_cluster.sh"
echo "3. 创建集群（参考 README.md）"
echo "4. ./test_cluster.sh"
EOF

chmod +x /tmp/cluster_practice_setup.sh
```

## 总结

Redis 集群是构建大规模、高可用 Redis 应用的核心技术。通过本章学习，您应该掌握：

### 核心概念
- **数据分片机制**：哈希槽实现数据自动分布
- **高可用架构**：主从复制和自动故障转移
- **去中心化设计**：无单点故障的分布式架构
- **动态扩展能力**：支持在线添加和删除节点

### 实际应用
- **集群规划**：根据业务需求设计集群拓扑
- **配置管理**：掌握集群配置的最佳实践
- **运维操作**：熟练使用集群管理命令
- **故障处理**：具备集群故障诊断和恢复能力

### 最佳实践
- **容量规划**：合理分配内存和槽位
- **监控告警**：建立完善的集群监控体系
- **备份策略**：制定数据备份和恢复方案
- **性能优化**：根据业务特点调优集群性能

Redis 集群为现代应用提供了强大的分布式缓存和存储能力，是构建高性能、高可用系统的重要基础设施。