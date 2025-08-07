# Redis 性能优化

## 性能监控

### 性能指标分析

Redis 性能监控需要关注以下关键指标：

**内存指标**：
- `used_memory`：Redis 使用的内存总量
- `used_memory_rss`：Redis 进程占用的物理内存
- `used_memory_peak`：Redis 使用内存的峰值
- `mem_fragmentation_ratio`：内存碎片率

**性能指标**：
- `instantaneous_ops_per_sec`：每秒操作数
- `keyspace_hits`：键空间命中次数
- `keyspace_misses`：键空间未命中次数
- `hit_rate`：缓存命中率

**连接指标**：
- `connected_clients`：当前连接的客户端数量
- `blocked_clients`：被阻塞的客户端数量
- `rejected_connections`：被拒绝的连接数

### 监控工具使用

**Redis 内置监控命令**：

```shell
# 查看服务器信息
redis-cli info

# 查看特定分类信息
redis-cli info memory
redis-cli info stats
redis-cli info clients

# 实时监控命令执行
redis-cli monitor

# 查看慢查询日志
redis-cli slowlog get 10
```

**性能测试工具**：

```shell
# Redis 基准测试
redis-benchmark -h 127.0.0.1 -p 6379 -c 100 -n 10000

# 测试特定命令性能
redis-benchmark -h 127.0.0.1 -p 6379 -t set,get -n 100000 -q

# 测试管道性能
redis-benchmark -h 127.0.0.1 -p 6379 -n 100000 -P 16
```

### 慢查询日志

**配置慢查询**：

```shell
# 设置慢查询阈值（微秒）
CONFIG SET slowlog-log-slower-than 10000

# 设置慢查询日志长度
CONFIG SET slowlog-max-len 128

# 查看慢查询配置
CONFIG GET slowlog*
```

**分析慢查询**：

```shell
# 获取慢查询日志
SLOWLOG GET 10

# 获取慢查询日志长度
SLOWLOG LEN

# 清空慢查询日志
SLOWLOG RESET
```

### 内存使用分析

**内存分析命令**：

```shell
# 分析内存使用情况
MEMORY USAGE key_name

# 获取内存统计信息
MEMORY STATS

# 分析键空间
MEMORY DOCTOR

# 查看大键
redis-cli --bigkeys
```

## 内存优化

### 内存使用策略

**过期策略配置**：

```shell
# 设置最大内存限制
maxmemory 2gb

# 设置内存淘汰策略
maxmemory-policy allkeys-lru

# 可选的淘汰策略：
# noeviction：不淘汰，返回错误
# allkeys-lru：所有键中淘汰最近最少使用
# allkeys-lfu：所有键中淘汰最少使用频率
# volatile-lru：过期键中淘汰最近最少使用
# volatile-lfu：过期键中淘汰最少使用频率
# allkeys-random：所有键中随机淘汰
# volatile-random：过期键中随机淘汰
# volatile-ttl：过期键中淘汰即将过期的
```

### 数据结构优化

**字符串优化**：

```shell
# 使用整数编码
SET counter 100  # 使用 int 编码
SET counter "100"  # 使用 raw 编码

# 小字符串使用 embstr 编码（<=44字节）
SET small_string "hello world"

# 大字符串使用 raw 编码（>44字节）
SET large_string "very long string content..."
```

**哈希优化**：

```shell
# 配置哈希压缩列表阈值
hash-max-ziplist-entries 512
hash-max-ziplist-value 64

# 小哈希使用压缩列表
HSET user:1 name "john" age 25

# 大哈希使用哈希表
for i in {1..1000}; do
    redis-cli HSET large_hash field$i value$i
done
```

**列表优化**：

```shell
# 配置列表压缩参数
list-max-ziplist-size -2
list-compress-depth 0

# 使用压缩列表的小列表
LPUSH small_list item1 item2 item3

# 使用快速列表的大列表
for i in {1..10000}; do
    redis-cli LPUSH large_list item$i
done
```

### 过期策略配置

**过期策略参数**：

```shell
# 设置过期扫描频率
hz 10

# 设置过期删除的CPU时间比例
maxmemory-samples 5

# 配置惰性删除
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
```

### 内存碎片处理

**内存碎片分析**：

```shell
# 查看内存碎片率
INFO memory | grep mem_fragmentation_ratio

# 内存碎片率计算
# mem_fragmentation_ratio = used_memory_rss / used_memory
# 正常范围：1.0 - 1.5
# > 1.5：内存碎片较多
# < 1.0：可能发生了内存交换
```

**内存整理**：

```shell
# 主动内存整理（Redis 4.0+）
MEMORY PURGE

# 配置自动内存整理
activedefrag yes
active-defrag-ignore-bytes 100mb
active-defrag-threshold-lower 10
active-defrag-threshold-upper 100
```

## 网络优化

### 连接池配置

**连接池参数优化**：

```shell
# 设置最大客户端连接数
maxclients 10000

# 设置客户端超时时间
timeout 300

# 设置TCP keepalive
tcp-keepalive 300

# 设置TCP backlog
tcp-backlog 511
```

**连接池最佳实践**：

```python
# Python 连接池配置示例
import redis
from redis.connection import ConnectionPool

# 创建连接池
pool = ConnectionPool(
    host='localhost',
    port=6379,
    max_connections=20,  # 最大连接数
    retry_on_timeout=True,
    socket_keepalive=True,
    socket_keepalive_options={},
    health_check_interval=30  # 健康检查间隔
)

# 使用连接池
r = redis.Redis(connection_pool=pool)
```

### 管道技术

**管道批量操作**：

```python
# Python 管道示例
import redis

r = redis.Redis(host='localhost', port=6379)

# 使用管道批量执行命令
pipe = r.pipeline()
for i in range(1000):
    pipe.set(f'key:{i}', f'value:{i}')
results = pipe.execute()

# 对比单个命令执行
# 不使用管道：1000次网络往返
# 使用管道：1次网络往返
```

```shell
# Redis CLI 管道
echo -e "SET key1 value1\nSET key2 value2\nSET key3 value3" | redis-cli --pipe

# 批量导入数据
cat data.txt | redis-cli --pipe
```

### 批量操作

**批量命令优化**：

```shell
# 使用 MSET 代替多个 SET
MSET key1 value1 key2 value2 key3 value3

# 使用 MGET 代替多个 GET
MGET key1 key2 key3

# 使用 HMSET 批量设置哈希字段
HMSET user:1 name john age 25 email john@example.com

# 使用 HMGET 批量获取哈希字段
HMGET user:1 name age email
```

### 网络延迟优化

**网络参数调优**：

```shell
# 禁用 Nagle 算法
tcp-nodelay yes

# 设置发送缓冲区大小
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
```

## 配置优化

### 核心参数调优

**基础性能参数**：

```shell
# Redis 配置文件优化
# /etc/redis/redis.conf

# 绑定网络接口
bind 127.0.0.1 192.168.1.100

# 设置端口
port 6379

# 设置工作目录
dir /var/lib/redis

# 设置日志级别
loglevel notice

# 设置日志文件
logfile /var/log/redis/redis-server.log

# 设置数据库数量
databases 16

# 设置密码
requirepass your_password
```

**内存管理参数**：

```shell
# 最大内存设置
maxmemory 4gb

# 内存淘汰策略
maxmemory-policy allkeys-lru

# 内存采样数量
maxmemory-samples 5

# 惰性删除
lazyfree-lazy-eviction yes
lazyfree-lazy-expire yes
lazyfree-lazy-server-del yes
```

### 持久化优化

**RDB 优化配置**：

```shell
# RDB 保存策略
save 900 1
save 300 10
save 60 10000

# RDB 文件压缩
rdbcompression yes

# RDB 文件校验
rdbchecksum yes

# RDB 文件名
dbfilename dump.rdb

# 后台保存出错时停止写入
stop-writes-on-bgsave-error yes
```

**AOF 优化配置**：

```shell
# 启用 AOF
appendonly yes

# AOF 文件名
appendfilename "appendonly.aof"

# AOF 同步策略
appendfsync everysec

# AOF 重写优化
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# AOF 重写时不同步
no-appendfsync-on-rewrite no

# AOF 加载时忽略错误
aof-load-truncated yes

# 混合持久化
aof-use-rdb-preamble yes
```

### 复制优化

**主从复制优化**：

```shell
# 复制积压缓冲区大小
repl-backlog-size 1mb

# 复制积压缓冲区超时
repl-backlog-ttl 3600

# 复制超时时间
repl-timeout 60

# 禁用TCP_NODELAY
repl-disable-tcp-nodelay no

# 复制ping周期
repl-ping-replica-period 10
```

### 系统级优化

**操作系统参数调优**：

```shell
# 内存过量分配
echo 1 > /proc/sys/vm/overcommit_memory

# 禁用透明大页
echo never > /sys/kernel/mm/transparent_hugepage/enabled

# 设置文件描述符限制
ulimit -n 65535

# 设置内存映射限制
echo 262144 > /proc/sys/vm/max_map_count

# TCP 参数优化
echo 'net.core.somaxconn = 65535' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_max_syn_backlog = 65535' >> /etc/sysctl.conf
sysctl -p
```

**文件系统优化**：

```shell
# 使用高性能文件系统
# 推荐：ext4, xfs

# 挂载选项优化
# /etc/fstab
/dev/sdb1 /var/lib/redis ext4 defaults,noatime,nodiratime 0 2

# SSD 优化
echo deadline > /sys/block/sdb/queue/scheduler
echo 1 > /sys/block/sdb/queue/iosched/fifo_batch
```

## 实践操作

### 需求描述

通过实际操作来监控 Redis 性能、优化内存使用，并测试性能提升效果。

### 实践细节和结果验证

```shell
#!/bin/bash
# Redis 性能优化实践脚本

echo "=== Redis 性能优化实践 ==="

# 1. 性能监控脚本
echo "1. 创建性能监控脚本"
cat > redis_monitor.sh << 'EOF'
#!/bin/bash
# Redis 性能监控脚本

REDIS_CLI="redis-cli"
LOG_FILE="/tmp/redis_monitor.log"

echo "$(date): Redis 性能监控开始" >> $LOG_FILE

# 获取基本信息
echo "=== 基本信息 ===" >> $LOG_FILE
$REDIS_CLI info server | grep -E "redis_version|uptime_in_seconds" >> $LOG_FILE

# 内存使用情况
echo "=== 内存使用 ===" >> $LOG_FILE
$REDIS_CLI info memory | grep -E "used_memory_human|used_memory_rss_human|mem_fragmentation_ratio" >> $LOG_FILE

# 性能统计
echo "=== 性能统计 ===" >> $LOG_FILE
$REDIS_CLI info stats | grep -E "instantaneous_ops_per_sec|keyspace_hits|keyspace_misses" >> $LOG_FILE

# 计算命中率
HITS=$($REDIS_CLI info stats | grep keyspace_hits | cut -d: -f2 | tr -d '\r')
MISSES=$($REDIS_CLI info stats | grep keyspace_misses | cut -d: -f2 | tr -d '\r')
if [ $((HITS + MISSES)) -gt 0 ]; then
    HIT_RATE=$(echo "scale=2; $HITS * 100 / ($HITS + $MISSES)" | bc)
    echo "hit_rate:$HIT_RATE%" >> $LOG_FILE
fi

# 连接信息
echo "=== 连接信息 ===" >> $LOG_FILE
$REDIS_CLI info clients | grep -E "connected_clients|blocked_clients" >> $LOG_FILE

# 慢查询
echo "=== 慢查询 ===" >> $LOG_FILE
SLOW_COUNT=$($REDIS_CLI slowlog len)
echo "slow_queries_count:$SLOW_COUNT" >> $LOG_FILE

echo "$(date): 监控完成" >> $LOG_FILE
echo "---" >> $LOG_FILE
EOF

chmod +x redis_monitor.sh
echo "性能监控脚本创建完成"

# 2. 内存优化配置
echo "2. 应用内存优化配置"

# 设置内存限制和淘汰策略
redis-cli CONFIG SET maxmemory 1gb
redis-cli CONFIG SET maxmemory-policy allkeys-lru
redis-cli CONFIG SET maxmemory-samples 5

# 启用惰性删除
redis-cli CONFIG SET lazyfree-lazy-eviction yes
redis-cli CONFIG SET lazyfree-lazy-expire yes
redis-cli CONFIG SET lazyfree-lazy-server-del yes

# 配置慢查询
redis-cli CONFIG SET slowlog-log-slower-than 10000
redis-cli CONFIG SET slowlog-max-len 128

echo "内存优化配置完成"

# 3. 性能基准测试
echo "3. 执行性能基准测试"

# 基础性能测试
echo "执行基础性能测试..."
redis-benchmark -h 127.0.0.1 -p 6379 -c 50 -n 10000 -q > /tmp/benchmark_basic.log
echo "基础测试完成，结果保存到 /tmp/benchmark_basic.log"

# 管道性能测试
echo "执行管道性能测试..."
redis-benchmark -h 127.0.0.1 -p 6379 -c 50 -n 10000 -P 16 -q > /tmp/benchmark_pipeline.log
echo "管道测试完成，结果保存到 /tmp/benchmark_pipeline.log"

# 4. 数据结构优化测试
echo "4. 测试数据结构优化"

# 创建测试数据
echo "创建测试数据..."

# 字符串测试
for i in {1..1000}; do
    redis-cli SET string:$i "value_$i" EX 3600 > /dev/null
done

# 哈希测试（小哈希）
for i in {1..100}; do
    redis-cli HSET small_hash:$i field1 value1 field2 value2 field3 value3 > /dev/null
done

# 列表测试
for i in {1..100}; do
    redis-cli LPUSH list:$i item1 item2 item3 item4 item5 > /dev/null
done

echo "测试数据创建完成"

# 5. 内存使用分析
echo "5. 分析内存使用情况"

# 分析大键
echo "分析大键..."
redis-cli --bigkeys > /tmp/bigkeys_analysis.log 2>&1
echo "大键分析完成，结果保存到 /tmp/bigkeys_analysis.log"

# 内存使用统计
echo "内存使用统计："
redis-cli info memory | grep -E "used_memory_human|used_memory_rss_human|mem_fragmentation_ratio"

# 6. 连接池测试
echo "6. 创建连接池测试脚本"
cat > connection_pool_test.py << 'EOF'
#!/usr/bin/env python3
# 连接池性能测试

import redis
import time
import threading
from redis.connection import ConnectionPool

def test_without_pool():
    """不使用连接池的测试"""
    start_time = time.time()
    for i in range(100):
        r = redis.Redis(host='localhost', port=6379)
        r.set(f'test_no_pool:{i}', f'value_{i}')
        r.get(f'test_no_pool:{i}')
    end_time = time.time()
    return end_time - start_time

def test_with_pool():
    """使用连接池的测试"""
    pool = ConnectionPool(host='localhost', port=6379, max_connections=10)
    r = redis.Redis(connection_pool=pool)
    
    start_time = time.time()
    for i in range(100):
        r.set(f'test_with_pool:{i}', f'value_{i}')
        r.get(f'test_with_pool:{i}')
    end_time = time.time()
    return end_time - start_time

def test_pipeline():
    """管道测试"""
    r = redis.Redis(host='localhost', port=6379)
    
    start_time = time.time()
    pipe = r.pipeline()
    for i in range(100):
        pipe.set(f'test_pipeline:{i}', f'value_{i}')
        pipe.get(f'test_pipeline:{i}')
    pipe.execute()
    end_time = time.time()
    return end_time - start_time

if __name__ == '__main__':
    print("连接池性能测试")
    
    # 测试不使用连接池
    time_no_pool = test_without_pool()
    print(f"不使用连接池耗时: {time_no_pool:.4f} 秒")
    
    # 测试使用连接池
    time_with_pool = test_with_pool()
    print(f"使用连接池耗时: {time_with_pool:.4f} 秒")
    
    # 测试管道
    time_pipeline = test_pipeline()
    print(f"使用管道耗时: {time_pipeline:.4f} 秒")
    
    print(f"连接池性能提升: {((time_no_pool - time_with_pool) / time_no_pool * 100):.2f}%")
    print(f"管道性能提升: {((time_no_pool - time_pipeline) / time_no_pool * 100):.2f}%")
EOF

echo "连接池测试脚本创建完成"

# 7. 运行监控
echo "7. 运行性能监控"
./redis_monitor.sh
echo "监控结果："
cat /tmp/redis_monitor.log | tail -20

# 8. 性能对比报告
echo "8. 生成性能报告"
cat > /tmp/performance_report.md << 'EOF'
# Redis 性能优化报告

## 优化前后对比

### 内存使用优化
- 配置了内存限制和LRU淘汰策略
- 启用了惰性删除机制
- 优化了数据结构使用

### 网络性能优化
- 使用连接池减少连接开销
- 使用管道技术批量执行命令
- 优化了TCP参数

### 监控和分析
- 实施了性能监控脚本
- 分析了慢查询和大键
- 监控了内存碎片率

## 性能测试结果

详细的基准测试结果请查看：
- 基础性能测试：/tmp/benchmark_basic.log
- 管道性能测试：/tmp/benchmark_pipeline.log
- 大键分析：/tmp/bigkeys_analysis.log

## 建议

1. 定期监控内存使用情况
2. 合理设置过期时间
3. 使用合适的数据结构
4. 避免大键和热键问题
5. 定期清理无用数据
EOF

echo "性能报告生成完成：/tmp/performance_report.md"

# 9. 清理测试数据
echo "9. 清理测试数据"
read -p "是否清理测试数据？(y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    redis-cli FLUSHDB
    echo "测试数据已清理"
else
    echo "保留测试数据"
fi

echo "=== Redis 性能优化实践完成 ==="
echo "相关文件："
echo "- 监控脚本：redis_monitor.sh"
echo "- 连接池测试：connection_pool_test.py"
echo "- 性能报告：/tmp/performance_report.md"
echo "- 监控日志：/tmp/redis_monitor.log"
```

通过本章的学习，你将掌握：

1. **性能监控**：学会使用各种工具监控 Redis 性能指标
2. **内存优化**：掌握内存使用策略和数据结构优化技巧
3. **网络优化**：了解连接池、管道等网络优化技术
4. **配置调优**：掌握核心参数的调优方法
5. **系统优化**：了解操作系统级别的优化措施
6. **实践应用**：通过实际操作验证优化效果

Redis 性能优化是一个持续的过程，需要根据具体的应用场景和负载特点进行针对性的调优。定期监控和分析是保持 Redis 高性能运行的关键。