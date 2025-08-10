#!/bin/bash

echo "=== Redis 集群缩容操作 ==="

# 配置参数
EXISTING_NODE="127.0.0.1:7001"
REMOVE_MASTER="127.0.0.1:7007"
REMOVE_SLAVE="127.0.0.1:7008"

# 1. 检查要删除的节点
echo "1. 检查要删除的节点..."

# 获取要删除的主节点ID
REMOVE_MASTER_ID=$(redis-cli -h ${REMOVE_MASTER%:*} -p ${REMOVE_MASTER#*:} CLUSTER MYID 2>/dev/null)
REMOVE_SLAVE_ID=$(redis-cli -h ${REMOVE_SLAVE%:*} -p ${REMOVE_SLAVE#*:} CLUSTER MYID 2>/dev/null)

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
slots_info=$(redis-cli -h ${REMOVE_MASTER%:*} -p ${REMOVE_MASTER#*:} CLUSTER NODES | grep $REMOVE_MASTER_ID)
slots_range=$(echo "$slots_info" | awk '{for(i=9;i<=NF;i++) printf "%s%s", $i, (i==NF?"":" ")}')

echo "要迁移的槽位: $slots_range"

if [ -n "$slots_range" ] && [ "$slots_range" != "-" ]; then
    # 解析多个槽位范围（用空格分隔）
    # 例如: 179-1364 5461-6826 10923-12287
    slot_ranges_array=()
    total_slot_count=0
    
    # 将槽位范围字符串分割成数组
    IFS=' ' read -ra SLOT_RANGES <<< "$slots_range"
    
    echo "解析到的槽位范围:"
    for range in "${SLOT_RANGES[@]}"; do
        if [[ $range =~ ^([0-9]+)-([0-9]+)$ ]]; then
            start_slot=${BASH_REMATCH[1]}
            end_slot=${BASH_REMATCH[2]}
            range_count=$((end_slot - start_slot + 1))
            slot_ranges_array+=("$start_slot:$end_slot:$range_count")
            total_slot_count=$((total_slot_count + range_count))
            echo "  范围 $start_slot-$end_slot: $range_count 个槽位"
        elif [[ $range =~ ^[0-9]+$ ]]; then
            # 单个槽位
            slot_ranges_array+=("$range:$range:1")
            total_slot_count=$((total_slot_count + 1))
            echo "  单个槽位 $range: 1 个槽位"
        fi
    done
    
    echo "总共需要迁移 $total_slot_count 个槽位"
    
    # 获取目标节点（选择第一个其他主节点）
    target_nodes=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER NODES | \
                   grep "master" | grep -v $REMOVE_MASTER_ID | head -3)
    
    echo "目标节点:"
    echo "$target_nodes"
    
    # 将目标节点信息存储到数组中
    target_nodes_array=()
    while IFS= read -r target_line; do
        if [ -n "$target_line" ]; then
            target_nodes_array+=("$target_line")
        fi
    done <<< "$target_nodes"
    
    target_count=${#target_nodes_array[@]}
    echo "找到 $target_count 个目标节点"
    
    # 执行槽位迁移 - 处理每个槽位范围
    echo "开始槽位迁移..."
    
    range_index=0
    target_index=0
    
    # 遍历每个槽位范围
    for slot_range_info in "${slot_ranges_array[@]}"; do
        # 解析槽位范围信息 (格式: start:end:count)
        IFS=':' read -ra RANGE_INFO <<< "$slot_range_info"
        range_start=${RANGE_INFO[0]}
        range_end=${RANGE_INFO[1]}
        range_count=${RANGE_INFO[2]}
        
        # 选择目标节点（轮询分配）
        target_line="${target_nodes_array[$target_index]}"
        target_id=$(echo $target_line | awk '{print $1}')
        target_addr=$(echo $target_line | awk '{print $2}')
        
        echo "迁移槽位范围 $range_start-$range_end ($range_count 个槽位) 到 $target_addr"
        
        # 使用 redis-cli 迁移整个槽位范围
        redis-cli --cluster reshard ${EXISTING_NODE} \
            --cluster-from $REMOVE_MASTER_ID \
            --cluster-to $target_id \
            --cluster-slots $range_count \
            --cluster-yes > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo "✅ 槽位范围 $range_start-$range_end 迁移成功"
        else
            echo "❌ 槽位范围 $range_start-$range_end 迁移失败"
        fi

        # 验证槽位迁移结果
        echo "验证槽位范围 $range_start-$range_end 的迁移状态..."
        sleep 5
        
        # 检查槽位是否已成功迁移
        migrated_slots=$(redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER NODES | \
                        grep $target_id | awk '{print $9}')
        echo "目标节点 $target_addr 当前槽位: $migrated_slots"
        
        # 轮询到下一个目标节点
        target_index=$(((target_index + 1) % target_count))
        range_index=$((range_index + 1))
    done
    echo "所有槽位范围迁移操作完成"

else
    echo "该节点没有分配槽位，跳过迁移"
fi

# 3. 删除从节点
echo "3. 删除从节点..."

echo "删除从节点 $REMOVE_SLAVE..."
redis-cli --cluster del-node ${EXISTING_NODE} $REMOVE_SLAVE_ID
    
# 4. 删除主节点
echo "4. 删除主节点..."

echo "删除主节点 $REMOVE_MASTER..."
redis-cli --cluster del-node ${EXISTING_NODE} $REMOVE_MASTER_ID


# 5. 停止已删除的节点
echo "5. 停止已删除的节点..."

for port in ${REMOVE_MASTER#*:} ${REMOVE_SLAVE#*:}; do
    echo "停止节点 $port..."
    redis-cli -p $port SHUTDOWN NOSAVE 2>/dev/null || echo "节点 $port 已停止或不可用"
done

# 6. 验证缩容结果
echo "6. 验证缩容结果..."

echo "剩余集群节点:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER NODES

echo
echo "集群状态信息:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER INFO

echo
echo "槽位分配验证:"
redis-cli -h ${EXISTING_NODE%:*} -p ${EXISTING_NODE#*:} CLUSTER SLOTS

echo
echo "=== 集群缩容完成 ==="
echo "已删除主节点: $REMOVE_MASTER"
echo "已删除从节点: $REMOVE_SLAVE"
echo "集群现有节点数: 6 (3主3从)"