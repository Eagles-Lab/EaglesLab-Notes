# Redis 环境搭建

## Redis 安装

Redis 在 Rocky Linux release 9.4 (Blue Onyx) 通过 YUM 安装 redis-6.2.19-1.el9_6.x86_64

```shell
[root@localhost ~]# cat /etc/redhat-release
Rocky Linux release 9.4 (Blue Onyx)
[root@localhost ~]# yum provides redis
Last metadata expiration check: 0:06:10 ago on Sat Aug  2 12:50:25 2025.
redis-6.2.19-1.el9_6.x86_64 : A persistent key-value database
Repo        : appstream
Matched from:
Provide    : redis = 6.2.19-1.el9_6
[root@localhost ~]# yum install redis-6.2.19-1.el9_6 -y

```

## Redis 启动和连接

### Redis 服务启动

**使用 systemd 管理**

```shell
# 服务文件
[root@localhost ~]# ls -l /usr/lib/systemd/system/redis.service
# 重新加载 systemd
systemctl daemon-reload
# 启动 Redis 服务
systemctl start redis
# 设置开机自启
systemctl enable redis
# 查看服务状态
systemctl status redis
```

**手动启动**

```shell
# 前台启动（用于调试）
redis-server /etc/redis/redis.conf
# 后台启动
redis-server /etc/redis/redis.conf --daemonize yes
# 指定端口启动
redis-server --port 6380
# 指定配置参数启动
redis-server --maxmemory 1gb --maxmemory-policy allkeys-lru
```

### Redis 客户端连接

**本地连接**

```shell
# 默认连接
redis-cli
# 指定主机和端口
redis-cli -h 127.0.0.1 -p 6379
# 使用密码连接
redis-cli -h 127.0.0.1 -p 6379 -a your_password
# 连接后认证
redis-cli
127.0.0.1:6379> AUTH your_password
OK
# 选择数据库
127.0.0.1:6379> SELECT 1
OK
127.0.0.1:6379[1]>
```

**远程连接配置**

```shell
# 服务器端配置
# 修改配置文件
vim /etc/redis/redis.conf
# 修改绑定地址
bind 0.0.0.0
# 设置密码
requirepass your_strong_password
# 重启服务
systemctl restart redis

# 客户端连接
# 远程连接
redis-cli -h 192.168.1.100 -p 6379 -a your_password

```

## Redis 配置

### 配置文件详解

Redis 的主配置文件通常位于 `/etc/redis/redis.conf`，包含了所有的配置选项。

**配置文件结构：**

```shell
# Redis 配置文件主要部分
1. 网络配置 (NETWORK)
2. 通用配置 (GENERAL)
3. 快照配置 (SNAPSHOTTING)
4. 复制配置 (REPLICATION)
5. 安全配置 (SECURITY)
6. 客户端配置 (CLIENTS)
7. 内存管理 (MEMORY MANAGEMENT)
8. 惰性释放 (LAZY FREEING)
9. 线程 I/O (THREADED I/O)
10. 内核透明大页 (KERNEL TRANSPARENT HUGEPAGE)
11. 追加模式 (APPEND ONLY MODE)
12. LUA 脚本 (LUA SCRIPTING)
13. Redis 集群 (REDIS CLUSTER)
14. 慢日志 (SLOW LOG)
15. 延迟监控 (LATENCY MONITOR)
16. 事件通知 (EVENT NOTIFICATION)
17. 高级配置 (ADVANCED CONFIG)
```

### 常用配置参数

**网络配置**

```shell
# 绑定地址
bind 127.0.0.1 ::1
# 允许所有地址访问（生产环境需谨慎）
# bind 0.0.0.0

# 端口号
port 6379

# TCP 监听队列长度
tcp-backlog 511

# 客户端空闲超时时间（秒）
timeout 0

# TCP keepalive
tcp-keepalive 300
```

**通用配置**

```shell
# 以守护进程方式运行
daemonize yes

# 进程文件
pidfile /var/run/redis_6379.pid

# 日志级别：debug, verbose, notice, warning
loglevel notice

# 日志文件
logfile /var/log/redis/redis-server.log

# 数据库数量
databases 16

# 显示 Redis logo
always-show-logo no
```

**内存管理**

```shell
# 最大内存限制
maxmemory 2gb

# 内存淘汰策略
# noeviction: 不淘汰，内存满时报错
# allkeys-lru: 所有键 LRU 淘汰
# volatile-lru: 有过期时间的键 LRU 淘汰
# allkeys-random: 所有键随机淘汰
# volatile-random: 有过期时间的键随机淘汰
# volatile-ttl: 有过期时间的键按 TTL 淘汰
# allkeys-lfu: 所有键 LFU 淘汰
# volatile-lfu: 有过期时间的键 LFU 淘汰
maxmemory-policy allkeys-lru

# LRU 和 LFU 算法样本数量
maxmemory-samples 5
```

### 安全配置

**密码认证**

```shell
# 设置密码
requirepass your_strong_password_here

# 重命名危险命令
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG "CONFIG_9a8b7c6d5e4f"
```

**ACL 用户管理**

```shell
# 启用 ACL 日志
acllog-max-len 128

# ACL 配置文件
# aclfile /etc/redis/users.acl

# 示例 ACL 配置
# user default on nopass ~* &* -@all +@read +@write
# user app_user on >app_password ~app:* +@read +@write -@dangerous
# user readonly_user on >readonly_password ~* +@read -@write -@dangerous
```

**网络安全**

```shell
# 保护模式（默认开启）
protected-mode yes

# 绑定到特定接口
bind 127.0.0.1 192.168.1.100

# 禁用某些命令
rename-command DEBUG ""
rename-command EVAL ""
rename-command SCRIPT ""
```

### 性能调优配置

**持久化优化**

```shell
# RDB 配置
save 900 1      # 900秒内至少1个键变化
save 300 10     # 300秒内至少10个键变化
save 60 10000   # 60秒内至少10000个键变化

# RDB 文件压缩
rdbcompression yes

# RDB 文件校验
rdbchecksum yes

# RDB 文件名
dbfilename dump.rdb

# 工作目录
dir /var/lib/redis

# AOF 配置
appendonly yes
appendfilename "appendonly.aof"

# AOF 同步策略
# always: 每个写操作都同步
# everysec: 每秒同步一次
# no: 由操作系统决定
appendfsync everysec

# AOF 重写配置
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
```

**客户端连接优化**

```shell
# 最大客户端连接数
maxclients 10000

# 客户端输出缓冲区限制
# client-output-buffer-limit <class> <hard limit> <soft limit> <soft seconds>
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# 客户端查询缓冲区限制
client-query-buffer-limit 1gb
```

**慢查询配置**

```shell
# 慢查询阈值（微秒）
slowlog-log-slower-than 10000

# 慢查询日志长度
slowlog-max-len 128
```


## 实践操作

### 需求描述

在生产环境中，我们经常需要在同一台服务器上运行多个Redis实例，用于不同的业务场景或实现数据隔离。本实践将演示如何通过自定义配置文件部署多个Redis实例，包括主实例、缓存实例和会话实例。

### 实践细节和结果验证

```shell
# 1. 创建多实例目录结构
mkdir -p /etc/redis/instances/{main,cache,session}
mkdir -p /var/lib/redis/{main,cache,session}
mkdir -p /var/log/redis

# 2. 创建主实例配置文件 (端口6380)
tee /etc/redis/instances/main/redis.conf > /dev/null << 'EOF'
# Redis 主实例配置 - 用于核心业务数据
port 6380
bind 127.0.0.1
daemonize yes
pidfile /var/run/redis/redis-main.pid
logfile /var/log/redis/redis-main.log
dir /var/lib/redis/main
dbfilename dump-main.rdb

# 内存配置
maxmemory 1gb
maxmemory-policy allkeys-lru

# 持久化配置
save 900 1
save 300 10
save 60 10000
appendonly yes
appendfilename "appendonly-main.aof"

# 安全配置
requirepass main_redis_2025
rename-command FLUSHDB ""
rename-command FLUSHALL ""

# 客户端配置
maxclients 1000
timeout 300
EOF

# 3. 创建缓存实例配置文件 (端口6381)
sudo tee /etc/redis/instances/cache/redis.conf > /dev/null << 'EOF'
# Redis 缓存实例配置 - 用于应用缓存
port 6381
bind 127.0.0.1
daemonize yes
pidfile /var/run/redis/redis-cache.pid
logfile /var/log/redis/redis-cache.log
dir /var/lib/redis/cache
dbfilename dump-cache.rdb

# 内存配置 - 缓存实例分配更多内存
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 10

# 持久化配置 - 缓存数据可以不持久化
save ""
appendonly no

# 安全配置
requirepass cache_redis_2025

# 客户端配置
maxclients 2000
timeout 0

# 过期键删除配置
hz 10
EOF

# 4. 创建会话实例配置文件 (端口6382)
sudo tee /etc/redis/instances/session/redis.conf > /dev/null << 'EOF'
# Redis 会话实例配置 - 用于用户会话存储
port 6382
bind 127.0.0.1
daemonize yes
pidfile /var/run/redis/redis-session.pid
logfile /var/log/redis/redis-session.log
dir /var/lib/redis/session
dbfilename dump-session.rdb

# 内存配置
maxmemory 512mb
maxmemory-policy volatile-lru

# 持久化配置 - 会话数据需要持久化但频率可以低一些
save 1800 1
save 300 100
appendonly yes
appendfilename "appendonly-session.aof"
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# 安全配置
requirepass session_redis_2025

# 客户端配置
maxclients 500
timeout 1800

# 键空间通知 - 用于会话过期监控
notify-keyspace-events Ex
EOF

# 5. 创建运行时目录
mkdir -p /var/run/redis
chown redis:redis /var/run/redis
chown -R redis:redis /var/lib/redis
chown -R redis:redis /var/log/redis
chown -R redis:redis /etc/redis/instances

# 6. 创建systemd服务文件
# 主实例服务
tee /etc/systemd/system/redis-main.service > /dev/null << 'EOF'
[Unit]
Description=Redis Main Instance
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/instances/main/redis.conf --supervised systemd
ExecStop=/usr/bin/redis-cli -p 6380 -a main_redis_2025 shutdown
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

# 缓存实例服务
sudo tee /etc/systemd/system/redis-cache.service > /dev/null << 'EOF'
[Unit]
Description=Redis Cache Instance
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/instances/cache/redis.conf --supervised systemd
ExecStop=/usr/bin/redis-cli -p 6381 -a cache_redis_2025 shutdown
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

# 会话实例服务
sudo tee /etc/systemd/system/redis-session.service > /dev/null << 'EOF'
[Unit]
Description=Redis Session Instance
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/instances/session/redis.conf --supervised systemd
ExecStop=/usr/bin/redis-cli -p 6382 -a session_redis_2025 shutdown
TimeoutStopSec=0
Restart=always
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF

# 7. 重新加载systemd并启动服务
sudo systemctl daemon-reload
sudo systemctl enable redis-main redis-cache redis-session
sudo systemctl start redis-main redis-cache redis-session

# 检查服务状态
sudo systemctl status redis-main redis-cache redis-session --no-pager

# 检查端口监听
sudo netstat -tlnp | grep redis-server

# 检查进程
ps aux | grep redis-server | grep -v grep

# 测试主实例
redis-cli -p 6380 -a main_redis_2025 ping
redis-cli -p 6380 -a main_redis_2025 set main:test "Main Instance Data"
redis-cli -p 6380 -a main_redis_2025 get main:test

# 测试缓存实例
redis-cli -p 6381 -a cache_redis_2025 ping
redis-cli -p 6381 -a cache_redis_2025 set cache:user:1001 "User Cache Data" EX 3600
redis-cli -p 6381 -a cache_redis_2025 get cache:user:1001
redis-cli -p 6381 -a cache_redis_2025 ttl cache:user:1001

# 测试会话实例
redis-cli -p 6382 -a session_redis_2025 ping
redis-cli -p 6382 -a session_redis_2025 set session:user:1001 "User Session Data" EX 1800
redis-cli -p 6382 -a session_redis_2025 get session:user:1001
redis-cli -p 6382 -a session_redis_2025 ttl session:user:1001

# 检查内存使用情况 - used_memory_human
redis-cli -p 6380 -a main_redis_2025 info memory | grep used_memory_human
redis-cli -p 6381 -a cache_redis_2025 info memory | grep used_memory_human
redis-cli -p 6382 -a session_redis_2025 info memory | grep used_memory_human

# 检查配置信息 - maxmemory
redis-cli -p 6380 -a main_redis_2025 config get maxmemory
redis-cli -p 6381 -a cache_redis_2025 config get maxmemory
redis-cli -p 6382 -a session_redis_2025 config get maxmemory

```