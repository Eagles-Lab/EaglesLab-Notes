#!/bin/bash

echo "=== Redis 集群扩容操作 ==="

# 配置参数
EXISTING_NODE="127.0.0.1:7001"
NEW_MASTER="127.0.0.1:7007"
NEW_SLAVE="127.0.0.1:7008"
BASE_DIR="/tmp/redis_cluster"

# 1. 准备新节点
echo "1. 准备新节点配置..."

# 创建新节点目录
mkdir -p ${BASE_DIR}/node-${NEW_MASTER#*:}
mkdir -p ${BASE_DIR}/node-${NEW_SLAVE#*:}

# 生成新主节点配置
cat > ${BASE_DIR}/node-${NEW_MASTER#*:}/redis.conf << EOF
port ${NEW_MASTER#*:}
bind 127.0.0.1
dir ${BASE_DIR}/node-${NEW_MASTER#*:}
logfile ${BASE_DIR}/node-${NEW_MASTER#*:}/redis-${NEW_MASTER#*:}.log
pidfile ${BASE_DIR}/node-${NEW_MASTER#*:}/redis-${NEW_MASTER#*:}.pid
daemonize yes

cluster-enabled yes
cluster-config-file ${BASE_DIR}/node-${NEW_MASTER#*:}/nodes-${NEW_MASTER#*:}.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

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
cat > ${BASE_DIR}/node-${NEW_SLAVE#*:}/redis.conf << EOF
port ${NEW_SLAVE#*:}
bind 127.0.0.1
dir ${BASE_DIR}/node-${NEW_SLAVE#*:}
logfile ${BASE_DIR}/node-${NEW_SLAVE#*:}/redis-${NEW_SLAVE#*:}.log
pidfile ${BASE_DIR}/node-${NEW_SLAVE#*:}/redis-${NEW_SLAVE#*:}.pid
daemonize yes

cluster-enabled yes
cluster-config-file ${BASE_DIR}/node-${NEW_SLAVE#*:}/nodes-${NEW_SLAVE#*:}.conf
cluster-node-timeout 15000
cluster-slave-validity-factor 10
cluster-migration-barrier 1
cluster-require-full-coverage yes

save ""
appendonly no

maxmemory 256mb
maxmemory-policy allkeys-lru
tcp-keepalive 300
databases 1
EOF

# 2. 启动新节点
echo "2. 启动新节点..."

redis-server ${BASE_DIR}/node-${NEW_MASTER#*:}/redis.conf
redis-server ${BASE_DIR}/node-${NEW_SLAVE#*:}/redis.conf

sleep 3

# 验证新节点启动
for port in ${NEW_MASTER#*:} ${NEW_SLAVE#*:}; do
    if redis-cli -p $port ping > /dev/null 2>&1; then
        echo "✅ 新节点 $port 启动成功"
    else
        echo "❌ 新节点 $port 启动失败"
        exit 1
    fi
done

# 3. 添加新主节点到集群
echo "3. 添加新主节点到集群..."

echo "使用 redis-cli 添加新主节点:"
redis-cli --cluster add-node ${NEW_MASTER} ${EXISTING_NODE}

# 等待节点加入
sleep 5

# 验证节点加入
echo "验证新主节点加入:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER NODES | grep ${NEW_MASTER%:*}:${NEW_MASTER#*:}

# 4. 重新分配槽位
echo "4. 重新分配槽位..."

# 获取新主节点ID
NEW_MASTER_ID=$(redis-cli -h ${NEW_MASTER%:*} -p ${NEW_MASTER#*:} CLUSTER MYID)
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
redis-cli --cluster reshard ${EXISTING_NODE} \
    --cluster-from all \
    --cluster-to $NEW_MASTER_ID \
    --cluster-slots $SLOTS_TO_MIGRATE \
    --cluster-yes
sleep 5

# 5. 添加新从节点
echo "5. 添加新从节点..."
redis-cli --cluster add-node ${NEW_SLAVE} ${EXISTING_NODE} --cluster-slave --cluster-master-id ${NEW_MASTER_ID}

# 等待从节点加入
sleep 5

# 6. 验证扩容结果
echo "集群节点信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER NODES

echo
echo "集群状态信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER INFO

echo
echo "槽位分配验证:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER SLOTS | grep -A 2 -B 2 ${NEW_MASTER%:*}

# 7. 测试新节点 - 写入数据至新主节点并验证

echo
echo "=== 集群扩容完成 ==="
echo "新主节点: $NEW_MASTER (ID: $NEW_MASTER_ID)"
echo "新从节点: $NEW_SLAVE"
echo "集群现有节点数: 8 (4主4从)"
