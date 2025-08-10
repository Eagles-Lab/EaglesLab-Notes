#!/bin/bash

# 集群配置参数
BASE_PORT=7001
NODE_COUNT=6
BASE_DIR=/tmp/redis_cluster_cluster/

# 创建工作目录
mkdir -pv $BASE_DIR

# 为每个节点生成配置
for i in $(seq 0 $((NODE_COUNT-1))); do
    PORT=$((BASE_PORT + i))
    NODE_DIR="node-$PORT"
    
    echo "生成节点 $PORT 配置..."
    mkdir -p $BASE_DIR/$NODE_DIR
    
    cat > $BASE_DIR/$NODE_DIR/redis.conf << EOF
# Redis 集群节点 $PORT 配置

# 基本配置
port $PORT
bind 127.0.0.1
dir $BASE_DIR/$NODE_DIR
logfile "$BASE_DIR/$NODE_DIR/redis-$PORT.log"
pidfile "$BASE_DIR/$NODE_DIR/redis-$PORT.pid"
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

# 性能优化
tcp-backlog 511
databases 1
EOF

done

echo "配置文件生成完成！"
echo "节点目录: $BASE_DIR/node-*"