# Redis 哨兵架构

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

**监控机制**

哨兵通过定期发送命令来监控 Redis 实例的状态：

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

**故障检测**

```shell
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

**故障转移过程**

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

### 哨兵通信机制

**发布/订阅通信**

哨兵使用 Redis 的发布/订阅功能进行通信：

```shell
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

**哨兵发现机制**

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


## 哨兵模式配置

### 基本配置

**哨兵配置文件**

```shell
# 创建哨兵配置文件 sentinel.conf
cat > /tmp/sentinel.conf << EOF
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

**多哨兵配置**

```shell
# 哨兵1配置
cat > /tmp/sentinel-1.conf << EOF
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
cat > /tmp/sentinel-2.conf << EOF
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
cat > /tmp/sentinel-3.conf << EOF
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

**安全配置**

```shell
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

**运行时配置修改**

```shell
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

**配置持久化**

```shell
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

**启动哨兵**

```shell
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

**停止哨兵**

```shell
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

**状态监控**

```shell
# 检查哨兵连接
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT ping

# 获取主节点信息
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL get-master-addr-by-name $MASTER_NAME

# 获取从节点信息
redis-cli -h $SENTINEL_HOST -p $SENTINEL_PORT SENTINEL slaves $MASTER_NAME

```

## 实践操作

### 需求描述

搭建一个完整的 Redis 哨兵集群，包括1个主节点、2个从节点和3个哨兵节点，学习哨兵的配置、管理和故障转移机制。

### 实践细节和结果验证

```shell
# 1. 环境准备
# 创建工作目录
mkdir -p /tmp/redis_sentinel_cluster/{redis-master,redis-slave1,redis-slave2,sentinel1,sentinel2,sentinel3}
cd /tmp/redis_sentinel_cluster

# 2. 配置 Redis 实例
# 主节点配置
cat > redis-master/redis.conf << EOF
port 6779
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/redis-master
logfile "redis-master.log"
pidfile "redis-master.pid"
daemonize yes

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
port 6780
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/redis-slave1
logfile "redis-slave1.log"
pidfile "redis-slave1.pid"
daemonize yes


# 主从配置
replicaof 127.0.0.1 6779
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
port 6781
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/redis-slave2
logfile "redis-slave2.log"
pidfile "redis-slave2.pid"
daemonize yes

# 主从配置
replicaof 127.0.0.1 6779
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
# 哨兵1配置
cat > sentinel1/sentinel.conf << EOF
port 26779
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/sentinel1
logfile "sentinel1.log"
pidfile "sentinel1.pid"
daemonize yes

# 监控主节点
sentinel monitor mymaster 127.0.0.1 6779 2

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
port 26780
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/sentinel2
logfile "sentinel2.log"
pidfile "sentinel2.pid"
daemonize yes

sentinel monitor mymaster 127.0.0.1 6779 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel notification-script mymaster /tmp/redis_sentinel_cluster/notify.sh
sentinel client-reconfig-script mymaster /tmp/redis_sentinel_cluster/reconfig.sh
sentinel deny-scripts-reconfig yes
EOF

# 哨兵3配置
cat > sentinel3/sentinel.conf << EOF
port 26781
bind 127.0.0.1
dir /tmp/redis_sentinel_cluster/sentinel3
logfile "sentinel3.log"
pidfile "sentinel3.pid"
daemonize yes

sentinel monitor mymaster 127.0.0.1 6779 2
sentinel down-after-milliseconds mymaster 30000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel notification-script mymaster /tmp/redis_sentinel_cluster/notify.sh
sentinel client-reconfig-script mymaster /tmp/redis_sentinel_cluster/reconfig.sh
sentinel deny-scripts-reconfig yes
EOF

# 4. 创建通知脚本
cd /tmp/redis_sentinel_cluster
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
cd /tmp/redis_sentinel_cluster
redis-server redis-master/redis.conf
redis-server redis-slave1/redis.conf
redis-server redis-slave2/redis.conf


# 6. 启动哨兵节点
cd /tmp/redis_sentinel_cluster
redis-sentinel sentinel1/sentinel.conf
redis-sentinel sentinel2/sentinel.conf
redis-sentinel sentinel3/sentinel.conf

# 7. 验证集群状态
# 检查主从复制
redis-cli -p 6779 INFO replication | grep -E "role|connected_slaves"
redis-cli -p 6780 INFO replication | grep -E "role|master_host|master_link_status"
redis-cli -p 6781 INFO replication | grep -E "role|master_host|master_link_status"
# 检查哨兵状态
for port in 26779 26780 26781; do redis-cli -p $port SENTINEL masters | grep -E "name|ip|port|num-slaves|num-other-sentinels" | head -5;done

# 8. [可选]测试数据同步

# 9. 测试故障转移
# 停止主节点
redis-cli -p 6779 SHUTDOWN NOSAVE
# 获取新主节点
redis-cli -p 26779 SENTINEL get-master-addr-by-name mymaster
# 验证新主节点
redis-cli -p 6781 INFO replication | grep -E "role|connected_slaves"
# 测试写入新主节点
redis-cli -p 6781 SET failover:test "success"
# 查看哨兵事件日志
tail -10 sentinel_events.log

```
