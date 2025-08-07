# Redis 主从复制

Redis 主从复制是 Redis 高可用性架构的基础，通过数据复制实现读写分离、故障转移和数据备份。理解主从复制的原理和配置是构建可靠 Redis 集群的关键。

## 主从复制概述

### 主从复制的概念

主从复制（Master-Slave Replication）是 Redis 提供的数据同步机制，其中一个 Redis 实例作为主节点（Master），其他实例作为从节点（Slave）。

**基本概念：**
- **主节点（Master）**：接受写操作，负责数据的修改
- **从节点（Slave）**：从主节点复制数据，通常只处理读操作
- **复制流（Replication Stream）**：主节点向从节点发送的数据同步流
- **复制偏移量（Replication Offset）**：用于标识复制进度的位置

### 主从复制的优势

**数据安全性：**
- 数据冗余备份
- 防止单点故障
- 支持数据恢复

**性能提升：**
- 读写分离
- 负载均衡
- 减轻主节点压力

**高可用性：**
- 故障转移基础
- 服务连续性
- 自动故障检测

**扩展性：**
- 水平扩展读能力
- 支持多级复制
- 灵活的架构设计

### 主从复制的应用场景


典型应用场景：

1. 读写分离架构
   应用 → 写操作 → Master
   应用 → 读操作 → Slave1, Slave2, Slave3

2. 数据备份
   Master → 实时数据
   Slave → 备份数据（可设置不同的持久化策略）

3. 故障转移
   Master 故障 → Slave 提升为新 Master

4. 数据分析
   Master → 生产数据
   Slave → 数据分析和报表生成

5. 跨地域部署
   Master → 主数据中心
   Slave → 异地数据中心


## 主从复制原理

### 复制过程

**全量复制（Full Resynchronization）**

全量复制发生在从节点首次连接主节点或复制中断后无法进行增量复制时。

全量复制流程：

1. 从节点发送 PSYNC 命令
   Slave → Master: PSYNC ? -1

2. 主节点响应 FULLRESYNC
   Master → Slave: FULLRESYNC <runid> <offset>

3. 主节点执行 BGSAVE
   Master: 生成 RDB 快照文件

4. 主节点发送 RDB 文件
   Master → Slave: RDB 文件数据

5. 主节点发送缓冲区命令
   Master → Slave: 复制期间的写命令

6. 从节点加载数据
   Slave: 清空数据库 → 加载 RDB → 执行缓冲命令


**增量复制（Partial Resynchronization）**

Redis 2.8+ 支持增量复制，用于处理短暂的网络中断。

增量复制流程：

1. 从节点重连并发送 PSYNC
   Slave → Master: PSYNC <runid> <offset>

2. 主节点检查复制积压缓冲区
   Master: 检查 offset 是否在缓冲区范围内

3. 主节点响应 CONTINUE
   Master → Slave: CONTINUE

4. 主节点发送缺失的命令
   Master → Slave: 缓冲区中 offset 之后的命令

5. 从节点执行命令
   Slave: 执行接收到的命令，恢复同步

### 复制相关的数据结构

**复制积压缓冲区（Replication Backlog）**

```shell
# 复制积压缓冲区配置
# redis.conf

# 缓冲区大小（默认 1MB）
repl-backlog-size 1mb

# 缓冲区超时时间（默认 3600 秒）
repl-backlog-ttl 3600

# 查看缓冲区状态
redis-cli INFO replication | grep backlog
```

**运行 ID（Run ID）**

```shell
# 查看运行 ID
redis-cli INFO server | grep run_id

# 运行 ID 的作用：
# 1. 标识 Redis 实例的唯一性
# 2. 用于增量复制的验证
# 3. 重启后会生成新的 Run ID
```

**复制偏移量（Replication Offset）**

```shell
# 查看复制偏移量
redis-cli INFO replication | grep offset

# 主节点偏移量：master_repl_offset
# 从节点偏移量：slave_repl_offset
# 偏移量差异表示复制延迟
```

## 主从复制配置

### 基本配置

**主节点配置**

```shell
# 主节点 redis.conf 配置

# 绑定地址（允许从节点连接）
bind 0.0.0.0

# 端口
port 6379

# 设置密码（可选）
requirepass master_password

# 主从复制相关配置
# 复制积压缓冲区大小
repl-backlog-size 1mb

# 复制积压缓冲区超时
repl-backlog-ttl 3600

# 复制超时时间
repl-timeout 60

# 禁用 TCP_NODELAY（可选，提高网络效率）
repl-disable-tcp-nodelay no

# 复制优先级（用于故障转移）
slave-priority 100

# 最小从节点数量（可选）
min-slaves-to-write 1
min-slaves-max-lag 10
```

**从节点配置**

```shell
# 从节点 redis.conf 配置

# 绑定地址
bind 0.0.0.0

# 端口（通常使用不同端口）
port 6380

# 指定主节点
slaveof 192.168.1.100 6379
# 或者使用新的配置项
replicaof 192.168.1.100 6379

# 主节点密码
masterauth master_password

# 从节点密码（可选）
requirepass slave_password

# 从节点只读（推荐）
slave-read-only yes

# 复制相关配置
slave-serve-stale-data yes
slave-priority 100

# 从节点持久化配置（可选）
# 通常从节点可以禁用持久化以提高性能
save ""
appendonly no
```

### 动态配置

**运行时配置主从关系**

```shell
# 将当前实例设置为从节点
redis-cli SLAVEOF 192.168.1.100 6379
# 或使用新命令
redis-cli REPLICAOF 192.168.1.100 6379

# 取消主从关系（将从节点提升为主节点）
redis-cli SLAVEOF NO ONE
# 或
redis-cli REPLICAOF NO ONE

# 设置主节点密码
redis-cli CONFIG SET masterauth master_password

# 查看复制状态
redis-cli INFO replication
```

**配置验证**

```shell
# 在主节点上查看从节点信息
redis-cli -h 192.168.1.100 -p 6379 INFO replication

# 在从节点上查看复制状态
redis-cli -h 192.168.1.101 -p 6380 INFO replication

# 测试数据同步
# 在主节点写入数据
redis-cli -h 192.168.1.100 -p 6379 SET test_key "test_value"

# 在从节点读取数据
redis-cli -h 192.168.1.101 -p 6380 GET test_key
```

### 高级配置

**复制安全配置**

```shell
# redis.conf 安全配置

# 保护模式
protected-mode yes

# 绑定特定网络接口
bind 192.168.1.100 127.0.0.1

# 设置强密码
requirepass "$(openssl rand -base64 32)"

# 重命名危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_$(openssl rand -hex 8)"

# 限制客户端连接数
maxclients 1000

# 设置内存限制
maxmemory 2gb
maxmemory-policy allkeys-lru
```

**网络优化配置**

```shell
# 网络相关优化配置

# TCP keepalive
tcp-keepalive 300

# 复制超时
repl-timeout 60

# 禁用 Nagle 算法（降低延迟）
repl-disable-tcp-nodelay no

# 复制积压缓冲区大小（根据网络情况调整）
repl-backlog-size 10mb

# 客户端输出缓冲区限制
client-output-buffer-limit slave 256mb 64mb 60
```

## 主从复制管理

### 监控主从状态

**复制状态监控**

```shell
# 主节点重点指标
INFO server：
    redis_version:6.2.19
    uptime_in_seconds:14339
INFO replication：
    role:master
    connected_slaves:1
    master_repl_offset:1000000
    repl_backlog_size:10485760
    repl_backlog_ttl:3600
INFO stats：
    total_commands_processed:1000000
    instantaneous_ops_per_sec:1000
INFO memory：
    used_memory_human:100.00M

# 从节点重点指标
INFO server：
    redis_version:6.2.19
    uptime_in_seconds:14339
INFO replication：
    role:slave
    master_host:192.168.1.100
    master_port:6379
    master_link_status:up
    master_last_io_seconds_ago:0
    master_sync_in_progress:0
    # lag = master_repl_offset - slave_repl_offset
    slave_repl_offset:1000000
    slave_priority:100
```

### 性能优化

**复制性能调优**

```shell
# 复制性能优化配置
# 禁用 TCP_NODELAY 以提高网络效率
repl-disable-tcp-nodelay no

# TCP keepalive
tcp-keepalive 300

# 增大复制积压缓冲区
repl-backlog-size 100mb

# 增大客户端输出缓冲区
client-output-buffer-limit slave 512mb 128mb 60

# 复制超时
repl-timeout 60

# 复制积压缓冲区超时
repl-backlog-ttl 7200

# 主节点：启用 AOF，禁用 RDB 自动保存
appendonly yes
appendfsync everysec
save ""

# 从节点：禁用持久化以提高性能
# save ""
# appendonly no

# 设置合适的内存策略
maxmemory-policy allkeys-lru

# 增加最大客户端连接数
maxclients 10000

```

**读写分离优化**

```shell
# 读写分离连接池配置示例（Python）- redis_pool_example.py
```

## 实践操作

**需求描述：**
在本地环境搭建一主两从的 Redis 复制架构，学习配置方法和管理技巧。

**实践细节和结果验证：**

```shell
# 创建工作目录
mkdir -p /data/redis_cluster/{master,slave1,slave2}

# 生成配置文件
cat > /data/redis_cluster/master/redis.conf << EOF
# 主节点配置
port 6679
bind 0.0.0.0
dir /data/redis_cluster/master
logfile "redis-master.log"
pidfile "redis-master.pid"

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-master.aof"

# 复制配置
repl-backlog-size 10mb
repl-backlog-ttl 3600
min-slaves-to-write 1
min-slaves-max-lag 10
EOF

# 从节点1配置
cat > /data/redis_cluster/slave1/redis.conf << EOF
# 从节点1配置
port 6680
bind 0.0.0.0
dir /data/redis_cluster/slave1
logfile "redis-slave1.log"
pidfile "redis-slave1.pid"

# 主从配置
replicaof 127.0.0.1 6679
slave-read-only yes
slave-serve-stale-data yes
slave-priority 100

# 持久化配置（从节点可以禁用以提高性能）
save ""
appendonly no
EOF

# 从节点2配置
cat > /data/redis_cluster/slave2/redis.conf << EOF
# 从节点2配置
port 6681
bind 0.0.0.0
dir /data/redis_cluster/slave2
logfile "redis-slave2.log"
pidfile "redis-slave2.pid"

# 主从配置
replicaof 127.0.0.1 6679
slave-read-only yes
slave-serve-stale-data yes
slave-priority 90

# 持久化配置
save ""
appendonly no
EOF

# 启动主节点
redis-server /data/redis_cluster/master/redis.conf --daemonize yes
# 验证主节点启动
redis-cli -p 6679 ping

# 启动从节点
redis-server /data/redis_cluster/slave1/redis.conf --daemonize yes
redis-server /data/redis_cluster/slave2/redis.conf --daemonize yes
# 验证从节点启动
redis-cli -p 6680 ping
redis-cli -p 6681 ping

# 验证主从复制
# 查看主节点状态
redis-cli -p 6679 INFO replication

# 查看从节点1状态
redis-cli -p 6680 INFO replication | grep -E "role|master_host|master_port|master_link_status"
# 查看从节点2状态
redis-cli -p 6681 INFO replication | grep -E "role|master_host|master_port|master_link_status"

# 测试数据同步
# 在主节点写入数据
redis-cli -p 6679 << EOF
SET test:string "Hello Redis Replication"
LPUSH test:list "item1" "item2" "item3"
SADD test:set "member1" "member2" "member3"
HMSET test:hash field1 "value1" field2 "value2"
ZADD test:zset 1 "first" 2 "second" 3 "third"
SETEX test:expire 3600 "will expire in 1 hour"
EOF

# 在从节点验证数据
redis-cli -p 6680 << EOF
GET test:string
LRANGE test:list 0 -1
SMEMBERS test:set
HGETALL test:hash
ZRANGE test:zset 0 -1 WITHSCORES
TTL test:expire
EOF

# 测试读写分离
# 测试从节点只读
redis-cli -p 6680 SET readonly_test "should_fail"


# 监控复制延迟
# 获取复制偏移量
master_offset=$(redis-cli -p 6679 INFO replication | grep master_repl_offset | cut -d: -f2 | tr -d '\r')
slave1_offset=$(redis-cli -p 6680 INFO replication | grep slave_repl_offset | cut -d: -f2 | tr -d '\r')
slave2_offset=$(redis-cli -p 6681 INFO replication | grep slave_repl_offset | cut -d: -f2 | tr -d '\r')
echo "主节点偏移量: $master_offset"
echo "从节点1偏移量: $slave1_offset (延迟: $((master_offset - slave1_offset)) 字节)"
echo "从节点2偏移量: $slave2_offset (延迟: $((master_offset - slave2_offset)) 字节)"

# 故障模拟
# 模拟从节点故障
redis-cli -p 6680 SHUTDOWN NOSAVE
# 检查主节点状态
redis-cli -p 6679 INFO replication | grep connected_slaves

# 恢复从节点1
redis-server /data/redis_cluster/slave1/redis.conf --daemonize yes

# 验证恢复
redis-cli -p 6680 ping
redis-cli -p 6679 INFO replication | grep connected_slaves

```