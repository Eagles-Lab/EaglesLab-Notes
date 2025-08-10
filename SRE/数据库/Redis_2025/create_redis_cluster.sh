#!/bin/bash

# 配置参数
BASE_PORT=7001
NODE_COUNT=6
REPLICAS=1
BASE_DIR=/tmp/redis_cluster_cluster/

# 1. 生成配置文件
echo "1. 生成配置文件... generate_cluster_configs.sh"

# 2. 启动所有节点
echo "2. 启动所有节点..."

for i in $(seq 0 $((NODE_COUNT-1))); do
    PORT=$((BASE_PORT + i))
    NODE_DIR="node-$PORT"
    
    echo "启动节点 $PORT..."
    redis-server $BASE_DIR/$NODE_DIR/redis.conf
    
    # 等待节点启动
    sleep 1
    
    # 验证节点启动
    if redis-cli -p $PORT ping > /dev/null 2>&1; then
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
redis-cli --cluster create $NODE_LIST --cluster-replicas $REPLICAS --cluster-yes

# 4. 验证集群状态
echo "4. 验证集群状态..."
sleep 3

echo "集群节点信息:"
redis-cli -p $BASE_PORT cluster nodes

echo
echo "集群状态信息:"
redis-cli -p $BASE_PORT cluster info

echo
echo "槽位分配信息:"
redis-cli -p $BASE_PORT cluster slots

echo
echo "=== 集群创建完成 ==="
echo "主节点端口: $BASE_PORT, $((BASE_PORT+1)), $((BASE_PORT+2))"
echo "从节点端口: $((BASE_PORT+3)), $((BASE_PORT+4)), $((BASE_PORT+5))"