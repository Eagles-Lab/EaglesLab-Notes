# Redis 集群架构

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


## Redis 集群原理

### 数据分片机制

**哈希槽（Hash Slot）**

Redis 集群使用哈希槽来实现数据分片：

哈希槽机制：

1. 槽位总数：16384 个（0-16383）
2. 槽位分配：平均分配给各个主节点
3. 数据映射：key → CRC16(key) % 16384 → 槽位 → 节点
4. 槽位迁移：支持在线重新分配槽位

示例分配（3个主节点）：
节点A：槽位 0-5460    （5461个槽）
节点B：槽位 5461-10922 （5462个槽）
节点C：槽位 10923-16383（5461个槽）

**数据路由**

```shell
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

**集群总线（Cluster Bus）**

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


### Gossip 协议

Gossip 协议（流言协议）是一种分布式系统中的信息传播协议，类似于现实生活中流言的传播方式。在Redis集群中，Gossip协议用于维护集群状态的一致性。

**Gossip 协议原理：**

1. **去中心化设计**
   - 没有中央协调节点
   - 每个节点都是平等的
   - 信息通过节点间的随机通信传播

2. **最终一致性**
   - 不保证强一致性
   - 通过多轮传播达到最终一致
   - 容忍网络分区和节点故障

3. **概率性传播**
   - 随机选择通信节点
   - 降低网络负载
   - 提高系统可扩展性

**Gossip 协议特点：**

1. **高可用性**
   - 单点故障不影响整体运行
   - 网络分区时仍能部分工作
   - 自动故障恢复能力

2. **可扩展性**
   - 通信复杂度为 O(log N)
   - 支持大规模集群
   - 动态添加/删除节点

3. **容错性**
   - 容忍节点故障
   - 容忍消息丢失
   - 容忍网络延迟

**Redis 中的 Gossip 实现：**

**Gossip 协议工作流程**：

1. **节点选择**：每次随机选择几个节点进行通信
2. **信息交换**：发送自己已知的集群状态信息
3. **信息合并**：接收并更新集群状态信息
4. **信息传播**：将新信息传播给其他节点

**消息类型：**

- **PING**：心跳消息，包含发送者状态和已知的其他节点信息
- **PONG**：心跳响应，包含接收者状态和集群视图
- **MEET**：新节点加入集群时的握手消息
- **FAIL**：节点故障通知，标记节点为失效状态
- **PUBLISH**：发布/订阅消息在集群间的传播

**Gossip 消息结构：**

Gossip 消息头：
- 消息类型 (PING/PONG/MEET/FAIL)
- 发送者节点ID
- 消息序列号
- 集群配置版本

Gossip 消息体：
- 节点状态信息
- 槽位分配信息
- 其他节点的状态摘要
- 故障检测信息


**传播机制：**

1. **主动传播**
   - 每个节点定期发送PING消息
   - 频率：每秒选择随机节点发送
   - 目标：维持集群连通性

2. **被动传播**
   - 接收到消息后回复PONG
   - 携带本地集群状态信息
   - 实现双向信息交换

3. **故障传播**
   - 检测到节点故障时发送FAIL消息
   - 快速传播故障信息
   - 触发故障转移流程

**Gossip 协议优势：**

1. **网络效率**
   - 避免广播风暴
   - 减少网络带宽消耗
   - 适合大规模集群

2. **故障隔离**
   - 局部故障不影响全局
   - 自动绕过故障节点
   - 提高系统稳定性

3. **动态适应**
   - 自动发现新节点
   - 自动移除故障节点
   - 支持集群拓扑变化


### 故障检测和转移

**故障检测机制**

```shell
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

**故障转移过程**

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


## Redis 集群配置

### 基本配置

**节点配置文件**

```shell
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

# 性能优化
tcp-backlog 511
databases 1  # 集群模式只支持数据库0
```

**多节点配置生成**

1. 复制节点配置模板
2. 修改端口号和配置文件名
3. 生成节点配置文件

### 集群创建

**使用 redis-cli 创建集群**

1. 启动所有节点
2. 连接其中一个节点（如 7001）
3. 执行集群创建命令
```shell
redis-cli --cluster create 127.0.0.1:7001 127.0.0.1:7002 127.0.0.1:7003 127.0.0.1:7004 127.0.0.1:7005 127.0.0.1:7006 --cluster-replicas 1
```

### 高级配置

**集群安全配置**

```shell
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

# 客户端输出缓冲区限制
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit slave 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60
```

**性能优化配置**

```shell
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
```

## Redis 集群管理

### 集群操作命令

**基本管理命令**

```shell
# 集群管理命令大全
# 基本连接
redis-cli -c -h 127.0.0.1 -p 7001

# 查看集群基本信息
127.0.0.1:7001> CLUSTER INFO
# 查看集群节点信息
127.0.0.1:7001> CLUSTER NODES
# 查看槽位分配
127.0.0.1:7001> CLUSTER SLOTS

# 槽位管理
# 查看键所在的槽位
127.0.0.1:7001> CLUSTER KEYSLOT key_name    
# 查看槽位中的键数量
127.0.0.1:7001> CLUSTER COUNTKEYSINSLOT 1000
# 获取槽位中的键，最多返回10个
127.0.0.1:7001> CLUSTER GETKEYSINSLOT 1000 10
# 删除槽位分配
127.0.0.1:7001> CLUSTER DELSLOTS 7000 7001 7002
# 手动分配槽位
127.0.0.1:7001> CLUSTER ADDSLOTS 7000 7001 7002

# 节点管理
# 添加节点
127.0.0.1:7001> CLUSTER MEET 127.0.0.1 7007
# 忘记节点
127.0.0.1:7001> CLUSTER FORGET node_id
# 设置从节点
127.0.0.1:7001> CLUSTER REPLICATE 127.0.0.1 7007
# 故障转移
127.0.0.1:7001> CLUSTER FAILOVER
127.0.0.1:7001> CLUSTER FAILOVER FORCE
127.0.0.1:7001> CLUSTER FAILOVER TAKEOVER

# 槽位迁移
# 设置槽位为迁移状态
127.0.0.1:7001> CLUSTER SETSLOT 1000 MIGRATING target_node_id
127.0.0.1:7001> CLUSTER SETSLOT 1000 IMPORTING source_node_id
# 迁移键
127.0.0.1:7001> MIGRATE 127.0.0.1 7002 key_name 0 5000
# 完成槽位迁移
127.0.0.1:7001> CLUSTER SETSLOT 1000 NODE target_node_id
# 检查槽位迁移状态
127.0.0.1:7001> CLUSTER SLOTS
# 检查键是否迁移完成
127.0.0.1:7001> EXISTS key_name

# 调试命令
# 保存集群配置
127.0.0.1:7001> CLUSTER SAVECONFIG
# 设置配置纪元
127.0.0.1:7001> CLUSTER SET-CONFIG-EPOCH 1
# 获取节点ID
127.0.0.1:7001> CLUSTER MYID

```

### 集群扩容和缩容

**添加节点流程**
1. 复制节点配置模板
2. 修改端口号和配置文件名
3. 生成节点配置文件
4. 启动新节点
5. 连接其中一个节点（如 7001）
6. 执行集群添加节点命令
```shell
redis-cli --cluster add-node 127.0.0.1:7007 127.0.0.1:7001
```
7. 重新分配槽位
```shell
# NEW_MASTER_ID
redis-cli -h 127.0.0.1 -p 7007 CLUSTER MYID
# SLOTS_TO_MIGRATE
16384 / 4 = 4096

redis-cli --cluster reshard 127.0.0.1:7001 \
    --cluster-from all \
    --cluster-to  <NEW_MASTER_ID> \
    --cluster-slots  <SLOTS_TO_MIGRATE> \
    --cluster-yes
```
8. 添加新从节点
```shell
redis-cli --cluster add-node 127.0.0.1:7008 127.0.0.1:7001 --cluster-slave --cluster-master-id <NEW_MASTER_ID>
```
9. 验证扩容结果
10. 测试新节点 & 验证数据读写


**删除节点流程**
1. 确认要删除的主节点
2. 迁移该主节点上的所有槽位：注意整个集群槽位分配是否平均
```shell
# REMOVE_MASTER_ID：删除节点
# TARGET_ID：选择一个节点作为目标节点
# RANGE_COUNT：槽位迁移数量
redis-cli --cluster reshard 127.0.0.1:7001 \
    --cluster-from <REMOVE_MASTER_ID> \
    --cluster-to <TARGET_ID> \
    --cluster-slots <RANGE_COUNT> \
    --cluster-yes > /dev/null 2>&1
```
3. 删除从节点 & 主节点
```shell
redis-cli --cluster del-node 127.0.0.1:7001 <REMOVE_SLAVE_ID>
redis-cli --cluster del-node 127.0.0.1:7001 <REMOVE_MASTER_ID>
```
4. 停掉相关进程

### 故障处理

**节点故障恢复流程**
1. 检测故障节点：ping 不通
2. 分析故障类型：通过 `cluster info` 查看集群状态 `cluster_state` 字段 && `cluster nodes` 查看节点状态
    - `cluster_state: ok`：可能是从节点故障
    - `cluster_state: fail`：可能是主节点故障
    - `cluster_state: unknown`：未知故障
3. 执行故障恢复：
    - 尝试重启相关 Redis 进程：如果需要可以重置节点集群状态  `CLUSTER RESET SOFT` 后重新加入集群 `CLUSTER MEET $failed_ip $failed_port`
    - 手动故障转移：如果节点故障持续存在，可能需要手动触发故障转移，从节点上执行 `CLUSTER FAILOVER FORCE`
4. 检查恢复结果：通过 `cluster nodes` 查看节点状态，确认故障节点已恢复

**数据一致性检查**

数据一致性检查是确保Redis集群数据完整性和可靠性的重要环节。

**1. 槽位分配一致性检查**
```shell
# 检查所有槽位是否完整分配
redis-cli --cluster check 127.0.0.1:7001

# 查看槽位分配详情
redis-cli -h 127.0.0.1 -p 7001 CLUSTER SLOTS

# 检查特定槽位的分配情况
redis-cli -h 127.0.0.1 -p 7001 CLUSTER KEYSLOT mykey
redis-cli -h 127.0.0.1 -p 7001 CLUSTER NODES | grep "0-5460"
```

**2. 主从复制一致性检查**
```shell
# 检查主从节点数据同步状态
redis-cli -h 127.0.0.1 -p 7001 INFO replication
redis-cli -h 127.0.0.1 -p 7004 INFO replication

# 比较主从节点的数据量
redis-cli -h 127.0.0.1 -p 7001 DBSIZE
redis-cli -h 127.0.0.1 -p 7004 DBSIZE

# 检查复制延迟
redis-cli -h 127.0.0.1 -p 7004 LASTSAVE
```

**3. 数据完整性验证**
- 写入足够分散的测试数据 
- 随机从集群中的节点读取数据进行验证


## 实践操作

### 需求描述

完成一个完整的 Redis Cluster 集群搭建、测试和管理过程：
1. 搭建3主3从节点的Redis Cluster 集群
2. 尝试扩容集群节点，添加一个主节点和一个从节点
3. 尝试缩容集群节点，删除一个主节点和一个从节点
4. 整个过程中，集群状态符合预期

### 实践细节和结果验证

```shell
# 1. 搭建3主3从节点的Redis Cluster 集群
# 准备目录
[root@localhost ~]# mkdir -pv /data/redis_cluster_cluster/{7101,7102,7103,7104,7105,7106}
# 为每个节点生成配置：参考 genrate_cluster_configs.sh 脚本
# 修改 BASE_DIR 为 /data/redis_cluster_cluster/ 
# 修改 BASE_PORT 为 7101
# 查看生成的目录文件结构
[root@localhost ~]# tree  /data/redis_cluster_cluster/
/data/redis_cluster_cluster/
├── node-7101
│   └── redis.conf
├── node-7102
│   └── redis.conf
├── node-7103
│   └── redis.conf
├── node-7104
│   └── redis.conf
├── node-7105
│   └── redis.conf
└── node-7106
    └── redis.conf
# 启动所有节点并创建集群： 参考 create_redis_cluster.sh 脚本
# 修改 BASE_DIR 为 /data/redis_cluster_cluster/ 
# 修改 BASE_PORT 为 7101
# 手动执行集群管理命令：集群状态符合预期

# 2. 尝试扩容集群节点，添加一个主节点和一个从节点
# 参考 cluster_scale_out.sh 脚本
# 修改 EXISTING_NODE 为 127.0.0.1:7101
# 修改 NEW_MASTER 为 127.0.0.1:7107
# 修改 NEW_SLAVE 为 127.0.0.1:7108
# 修改 BASE_DIR 为 /data/redis_cluster_cluster/

# 3. 尝试缩容集群节点，删除一个主节点和一个从节点
# 参考 cluster_scale_in.sh 脚本
# 修改 EXISTING_NODE 为 127.0.0.1:7101
# 修改 REMOVE_MASTER_ID 为 7107
# 修改 REMOVE_SLAVE_ID 为 7108
# 修改 BASE_DIR 为 /data/redis_cluster_cluster/

```