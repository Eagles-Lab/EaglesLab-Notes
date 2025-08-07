# Redis 持久化

Redis 是一个内存数据库，为了保证数据的持久性和可靠性，Redis 提供了多种持久化机制。理解和正确配置持久化是 Redis 生产环境部署的关键。

## RDB 持久化

### RDB 概述

RDB（Redis Database）是 Redis 的一种持久化方式，它将某个时间点的数据集快照保存到磁盘上。

**RDB 特点：**
- **快照方式**：保存某个时间点的完整数据集
- **紧凑格式**：二进制格式，文件体积小
- **恢复快速**：启动时直接加载，恢复速度快
- **性能影响小**：通过 fork 子进程执行，对主进程影响小
- **数据丢失风险**：两次快照间的数据可能丢失

**适用场景：**
- 对数据完整性要求不高的场景
- 需要定期备份的场景
- 主从复制的从节点
- 数据恢复速度要求高的场景

### RDB 配置

**自动触发配置**

```shell
# redis.conf 配置文件中的 RDB 相关配置

# 自动保存条件（save <seconds> <changes>）
# 在指定时间内，如果至少有指定数量的键发生变化，则执行 BGSAVE
save 900 1      # 900秒内至少1个键发生变化
save 300 10     # 300秒内至少10个键发生变化
save 60 10000   # 60秒内至少10000个键发生变化

# 禁用自动保存（注释掉所有 save 行或使用空字符串）
# save ""

# RDB 文件名：dump.rdb

# RDB 文件保存目录：/var/lib/redis

# 当 RDB 持久化出现错误时，是否停止接受写命令
stop-writes-on-bgsave-error yes

# 是否压缩 RDB 文件
rdbcompression yes

# 是否对 RDB 文件进行校验和检查
rdbchecksum yes
```

**手动触发配置**

```shell
# 查看当前 RDB 配置
redis-cli CONFIG GET save
redis-cli CONFIG GET dbfilename
redis-cli CONFIG GET dir

# 动态修改 RDB 配置
redis-cli CONFIG SET save "900 1 300 10 60 10000"
redis-cli CONFIG SET dbfilename "backup.rdb"
redis-cli CONFIG SET rdbcompression yes

# 保存配置到文件
redis-cli CONFIG REWRITE
```

### RDB 操作命令

**手动生成 RDB 文件**

```shell
# SAVE 命令（阻塞方式）
# 在主进程中执行，会阻塞所有客户端请求
redis-cli SAVE

# BGSAVE 命令（非阻塞方式，推荐）
# 在后台子进程中执行，不阻塞主进程
redis-cli BGSAVE

# 检查 BGSAVE 是否正在执行
redis-cli LASTSAVE  # 返回最后一次成功执行 SAVE/BGSAVE 的时间戳

# 获取 RDB 相关信息
redis-cli INFO persistence
```

**RDB 文件管理**

```shell
# 查看 RDB 文件信息
ls -la /var/lib/redis/dump.rdb

# 备份 RDB 文件
cp /var/lib/redis/dump.rdb /backup/redis/dump_$(date +%Y%m%d_%H%M%S).rdb

# 验证 RDB 文件完整性
redis-check-rdb /var/lib/redis/dump.rdb

# 从 RDB 文件恢复数据
# 1. 停止 Redis 服务
systemctl stop redis

# 2. 替换 RDB 文件
cp /backup/redis/dump_xxx.rdb /var/lib/redis/dump.rdb
chown redis:redis /var/lib/redis/dump.rdb

# 3. 启动 Redis 服务
systemctl start redis

# 4. 验证数据恢复
redis-cli DBSIZE
```

### RDB 文件格式

**RDB 文件结构**

```shell
RDB 文件结构：
+-------+-------------+-----------+-----------------+-----+-----------+
| REDIS | RDB-VERSION | SELECT-DB | KEY-VALUE-PAIRS | EOF | CHECK-SUM |
+-------+-------------+-----------+-----------------+-----+-----------+

详细说明：
- REDIS: 文件标识符（5字节）
- RDB-VERSION: RDB 版本号（4字节）
- SELECT-DB: 数据库选择器
- KEY-VALUE-PAIRS: 键值对数据
- EOF: 文件结束标识（1字节）
- CHECK-SUM: 校验和（8字节）
```

**分析 RDB 文件**

```bash
# 使用 redis-rdb-tools 分析 RDB 文件
pip install rdbtools python-lzf

# 将 RDB 转换为 JSON 格式
rdb --command json /var/lib/redis/dump.rdb > dump.json

# 生成内存使用报告
rdb --command memory /var/lib/redis/dump.rdb > memory_report.csv

# 按键类型统计
rdb --command memory /var/lib/redis/dump.rdb --bytes 128 --largest 10

# 查看特定键的信息
rdb --command memory /var/lib/redis/dump.rdb | grep "user:"
```

## AOF 持久化

### AOF 概述

AOF（Append Only File）是 Redis 的另一种持久化方式，它记录服务器接收到的每个写操作命令。

**AOF 特点：**
- **命令记录**：记录每个写操作命令
- **数据安全性高**：可配置每秒或每个命令同步
- **文件可读**：文本格式，可以直接查看和编辑
- **自动重写**：定期压缩 AOF 文件
- **恢复较慢**：需要重放所有命令

**适用场景：**
- 对数据完整性要求高的场景
- 需要最小数据丢失的场景
- 主节点持久化
- 需要审计写操作的场景

### AOF 配置

**基本配置**

```shell
# redis.conf 配置文件中的 AOF 相关配置

# 启用 AOF 持久化
appendonly yes

# AOF 文件名
appendfilename "appendonly.aof"

# AOF 同步策略
# always: 每个写命令都同步到磁盘（最安全，性能最低）
# everysec: 每秒同步一次（推荐，平衡安全性和性能）
# no: 由操作系统决定何时同步（性能最高，安全性最低）
appendfsync everysec

# 在 AOF 重写期间是否同步
no-appendfsync-on-rewrite no

# AOF 自动重写配置
# 当 AOF 文件大小超过上次重写后大小的指定百分比时触发重写
auto-aof-rewrite-percentage 100
# AOF 文件最小重写大小
auto-aof-rewrite-min-size 64mb

# AOF 加载时是否忽略最后一个不完整的命令
aof-load-truncated yes

# 是否使用 RDB-AOF 混合持久化
aof-use-rdb-preamble yes
```

**动态配置**

```shell
# 查看当前 AOF 配置
redis-cli CONFIG GET appendonly
redis-cli CONFIG GET appendfsync
redis-cli CONFIG GET auto-aof-rewrite-percentage

# 动态启用 AOF
redis-cli CONFIG SET appendonly yes

# 修改同步策略
redis-cli CONFIG SET appendfsync everysec

# 修改自动重写配置
redis-cli CONFIG SET auto-aof-rewrite-percentage 100
redis-cli CONFIG SET auto-aof-rewrite-min-size 64mb

# 保存配置
redis-cli CONFIG REWRITE
```

### AOF 操作命令

**手动重写 AOF**

```shell
# 手动触发 AOF 重写
redis-cli BGREWRITEAOF

# 检查 AOF 重写状态
redis-cli INFO persistence | grep aof

# 查看 AOF 相关统计信息
redis-cli INFO persistence
```

**AOF 文件管理**

```shell
# 查看 AOF 文件
ls -la /var/lib/redis/appendonly.aof
tail -f /var/lib/redis/appendonly.aof

# 检查 AOF 文件完整性
redis-check-aof /var/lib/redis/appendonly.aof

# 修复损坏的 AOF 文件
redis-check-aof --fix /var/lib/redis/appendonly.aof

# 备份 AOF 文件
cp /var/lib/redis/appendonly.aof /backup/redis/appendonly_$(date +%Y%m%d_%H%M%S).aof
```

### AOF 文件格式

**AOF 命令格式**

AOF 文件使用 RESP（Redis Serialization Protocol）格式记录命令：

```shell
# AOF 文件内容示例
*3          # 数组长度（3个元素）
$3          # 字符串长度（3字节）
SET         # 命令
$4          # 字符串长度（4字节）
name        # 键名
$5          # 字符串长度（5字节）
Alice       # 键值

*3
$3
SET
$3
age
$2
25

*2
$4
INCR
$7
counter
```

**分析 AOF 文件**

```shell
# 查看 AOF 文件内容
cat /var/lib/redis/appendonly.aof

# 统计 AOF 文件中的命令
grep -c "^\*" /var/lib/redis/appendonly.aof

# 查看最近的命令
tail -20 /var/lib/redis/appendonly.aof

# 提取特定命令
grep -A 10 "SET" /var/lib/redis/appendonly.aof

# 使用工具分析 AOF 文件：python 脚本工具
```

### AOF 重写机制

**重写原理**

AOF 重写是为了解决 AOF 文件不断增长的问题：

```shell
# 重写前的 AOF 文件可能包含：
SET counter 1
INCR counter
INCR counter
INCR counter
DEL temp_key
SET temp_key value
DEL temp_key

# 重写后的 AOF 文件只包含：
SET counter 4
# temp_key 相关的命令被完全移除，因为最终结果是键不存在
```

**重写配置和监控**

```shell
# 查看重写相关配置
redis-cli CONFIG GET auto-aof-rewrite-*

# 查看重写统计信息
redis-cli INFO persistence | grep -E "aof_rewrite|aof_current_size|aof_base_size"

# 手动触发重写
redis-cli BGREWRITEAOF

# 监控重写进度
watch -n 1 'redis-cli INFO persistence | grep aof_rewrite_in_progress'

```

**重写性能优化**

```shell
# 优化重写性能的配置
# redis.conf

# 重写期间不进行 fsync，提高性能
no-appendfsync-on-rewrite yes

# 调整重写触发条件
auto-aof-rewrite-percentage 100  # 文件大小翻倍时重写
auto-aof-rewrite-min-size 64mb   # 最小64MB才考虑重写

# 使用混合持久化减少重写后的文件大小
aof-use-rdb-preamble yes
```

## 混合持久化

### 混合持久化概述

Redis 4.0 引入了混合持久化，结合了 RDB 和 AOF 的优点。

**混合持久化特点：**
- **快速恢复**：RDB 部分快速加载
- **数据安全**：AOF 部分保证最新数据
- **文件较小**：比纯 AOF 文件小
- **兼容性好**：向后兼容

**文件结构：**
```
混合 AOF 文件结构：
+---------------------+------------------------+
| RDB 格式的数据快照   | AOF 格式的增量命令      |
+---------------------+------------------------+
```

### 混合持久化配置

```shell
# 启用混合持久化
# redis.conf
appendonly yes
aof-use-rdb-preamble yes

# 动态启用
redis-cli CONFIG SET aof-use-rdb-preamble yes
redis-cli CONFIG REWRITE

# 验证配置
redis-cli CONFIG GET aof-use-rdb-preamble
```

### 混合持久化操作

```shell
# 触发混合持久化重写
redis-cli BGREWRITEAOF

# 检查文件格式
file /var/lib/redis/appendonly.aof
head -c 20 /var/lib/redis/appendonly.aof | xxd

# 如果是混合格式，开头应该是 "REDIS" 而不是 "*"
```

## 持久化策略选择

### 不同场景的持久化策略

**高性能场景**

```shell
# 配置：仅使用 RDB，较长的保存间隔
save 900 1
save 300 10
save 60 10000
appendonly no

# 适用场景：
# - 缓存系统
# - 数据丢失容忍度高
# - 性能要求极高
```

**高可靠性场景**

```shell
# 配置：AOF + 每秒同步
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes

# 可选：同时启用 RDB 作为备份
save 900 1

# 适用场景：
# - 金融系统
# - 重要业务数据
# - 数据丢失容忍度低
```

**平衡场景**

```shell
# 配置：混合持久化
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes
save 900 1
save 300 10

# 适用场景：
# - 大多数生产环境
# - 平衡性能和可靠性
# - 中等数据量
```

### 持久化最佳实践

**生产环境配置建议**

```shell
# 推荐的生产环境配置
# redis.conf

# 启用混合持久化
appendonly yes
appendfsync everysec
aof-use-rdb-preamble yes

# RDB 配置（作为备份）
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes

# AOF 重写配置
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb
no-appendfsync-on-rewrite no
aof-load-truncated yes

# 文件路径配置
dir /var/lib/redis
dbfilename dump.rdb
appendfilename "appendonly.aof"
```

## 实践操作