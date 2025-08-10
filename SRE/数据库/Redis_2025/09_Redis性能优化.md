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
redis-benchmark -h 127.0.0.1 -p 6379 -t set,get -n 10000 -q

# 测试管道性能：Pepeline模式
redis-benchmark -h 127.0.0.1 -p 6379 -n 10000 -P 16

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

### 管道技术

**技术原理**
1. 客户端批量发送命令 → 服务器批量处理 → 批量返回结果
2. 管道技术可以减少网络往返次数，提高批量操作的效率


**管道批量操作**：

```shell
# 传统模式 - 逐个执行命令（每个命令都需要等待响应）
redis-cli SET key1 value1
redis-cli SET key2 value2
redis-cli SET key3 value3
redis-cli GET key1
redis-cli GET key2
redis-cli GET key3

# Pipeline模式 - 批量发送命令（减少网络往返）
# 方法1：使用管道符
echo -e "SET key1 value1\nSET key2 value2\nSET key3 value3\nGET key1\nGET key2\nGET key3" | redis-cli --pipe

# 方法2：使用文件批量执行
cat > commands.txt << EOF
SET key1 value1
SET key2 value2
SET key3 value3
GET key1
GET key2
GET key3
EOF
redis-cli --pipe < commands.txt


# 性能对比测试
# 传统模式：100个SET命令
time for i in {1..100}; do redis-cli SET test_key_$i value_$i > /dev/null; done

# Pipeline模式：100个SET命令
time (for i in {1..100}; do echo "SET test_key_$i value_$i"; done | redis-cli --pipe > /dev/null)
```

### 批量操作

**批量命令优化**：

```shell
# 传统方式 - 多个单独命令
SET key1 value1
SET key2 value2
SET key3 value3
GET key1
GET key2
GET key3

# 优化方式 - 使用批量命令
# 使用 MSET 代替多个 SET
MSET key1 value1 key2 value2 key3 value3

# 使用 MGET 代替多个 GET
MGET key1 key2 key3

# 使用 HMSET 批量设置哈希字段
HMSET user:1 name john age 25 email john@example.com

# 使用 HMGET 批量获取哈希字段
HMGET user:1 name age email

# 使用 redis-benchmark 对比批量操作和单个操作的性能
# 对比 SET vs MSET 性能
redis-benchmark -t set -n 100000 -q
# 结果示例: SET: 28352.71 requests per second, p50=0.871 msec
redis-benchmark -t mset -n 100000 -q
# 结果示例: MSET (10 keys): 26860.06 requests per second, p50=0.927 msec

# 性能分析:
# - SET 单个操作: 28,352 ops/sec，平均延迟 0.871ms
# - MSET 批量操作: 26,860 ops/sec，平均延迟 0.927ms
# - 注意：MSET 测试的是每次设置10个键值对，实际吞吐量为 26,860 * 10 = 268,600 键/秒
# - 批量操作的真实性能提升约为: 268,600 / 28,352 ≈ 9.5倍

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

## [扩展] 实践操作

### 需求描述

通过实际操作来监控 Redis 性能、优化内存使用，并测试性能提升效果。

### 实践细节和结果验证