# Redis 基本命令

Redis 提供了丰富的命令来管理键、数据库、事务和脚本。掌握这些基本命令是高效使用 Redis 的基础。

## 键操作命令

### 键的命名规范

良好的键命名规范是 Redis 应用的重要基础，有助于提高可维护性和性能。

**推荐的命名规范：**

1. **使用冒号分隔层级**
   ```shell
   user:1001:profile
   product:category:electronics
   cache:query:user_list
   session:web:abc123
   ```

2. **使用有意义的前缀**
   ```shell
   # 按功能分类
   cache:*     # 缓存数据
   session:*   # 会话数据
   config:*    # 配置信息
   temp:*      # 临时数据
   
   # 按业务分类
   user:*      # 用户相关
   order:*     # 订单相关
   product:*   # 商品相关
   ```

3. **避免特殊字符**
   ```shell
   # 推荐
   user:1001:name
   article:2023:01:15
   
   # 不推荐
   user 1001 name
   article@2023#01#15
   ```

4. **保持一致性**
   ```shell
   # 统一使用小写
   user:profile:name
   user:profile:email
   
   # 统一日期格式
   log:2024:01:15
   report:2024:01:15
   ```

### 键的查询和遍历

**基本查询命令**

```shell
# 检查键是否存在
# 用法：EXISTS key [key ...]
EXISTS user:1001
EXISTS user:1001 user:1002 user:1003  # 返回存在的键数量

# 获取键的类型
# 用法：TYPE key
TYPE user:1001          # 返回 hash
TYPE user:tags          # 返回 set
TYPE message_queue      # 返回 list

# 获取键的编码方式
# 用法：OBJECT ENCODING key
OBJECT ENCODING user:1001
OBJECT ENCODING counter

# 获取键的空闲时间（秒）
# 用法：OBJECT IDLETIME key
# 注意：返回值为键的空闲时间，单位为秒。
OBJECT IDLETIME user:1001

# 获取键的引用计数
# 用法：OBJECT REFCOUNT key
# 注意：返回值为键的引用计数，单位为秒。
OBJECT REFCOUNT user:1001
```

**模式匹配查询**

```shell
# 查找匹配模式的键（谨慎使用）
# 用法：KEYS pattern
KEYS user:*             # 查找所有用户相关的键
KEYS cache:*            # 查找所有缓存键
KEYS *:1001:*           # 查找包含1001的键
KEYS user:100?          # ?匹配单个字符
KEYS user:[12]*         # []匹配字符集合

# 更安全的遍历方式（推荐）
# 用法：SCAN cursor [MATCH pattern] [COUNT count] [TYPE type]
SCAN 0 MATCH user:* COUNT 10
SCAN 0 MATCH cache:* COUNT 20
SCAN 0 TYPE string COUNT 10

# 示例：安全遍历所有用户键
redis-cli --scan --pattern "user:*"
```

**随机获取键**

```shell
# 随机返回一个键
# 用法：RANDOMKEY

# 示例：随机获取键进行采样
RANDOMKEY
RANDOMKEY
RANDOMKEY
```

### 键的过期设置

Redis 支持为键设置过期时间，这是内存管理和缓存实现的重要功能。

**设置过期时间**

```shell
# 设置键的过期时间（秒）
# 用法：EXPIRE key seconds
EXPIRE user:1001 3600   # 1小时后过期
EXPIRE temp_data 300    # 5分钟后过期

# 设置键的过期时间（毫秒）
# 用法：PEXPIRE key milliseconds
PEXPIRE temp_data 30000  # 30秒后过期

# 设置键的过期时间戳（秒）
# 用法：EXPIREAT key timestamp
EXPIREAT temp_data 1705123200  # 指定时间戳过期

# 设置键的过期时间戳（毫秒）
# 用法：PEXPIREAT key milliseconds-timestamp    
PEXPIREAT temp_data 1705123200000

# 创建键时同时设置过期时间
# 用法：SETEX key seconds value
SETEX key seconds value
SETEX session:abc123 3600 "user_data"

# 创建键时同时设置过期时间（毫秒）
# 用法：PSETEX key milliseconds value
PSETEX session:def456 3600000 "user_data"
```

**查询过期时间**

```shell
# 获取键的剩余生存时间（秒）
# 用法：TTL key
TTL session:abc123      # 返回剩余秒数，-1表示永不过期，-2表示不存在

# 获取键的剩余生存时间（毫秒）
# 用法：PTTL key
PTTL session:abc123     # 返回剩余毫秒数

# 示例：检查多个键的过期时间
SETEX key1 100 "value1"
SETEX key2 200 "value2"
SET key3 "value3"       # 永不过期
TTL key1
TTL key2
TTL key3
```

**移除过期时间**    

```shell
# 移除键的过期时间，使其永久存在
# 用法：PERSIST key
PERSIST session:abc123
SETEX temp_key 300 "临时数据"
TTL temp_key            # 查看过期时间
PERSIST temp_key        # 移除过期时间
TTL temp_key            # 返回-1，表示永不过期
```

### 键的删除和重命名

**删除键**

```shell
# 删除一个或多个键
# 用法：DEL key [key ...]
DEL user:1001
DEL cache:query1 cache:query2 cache:query3

# 异步删除键（适用于大键）
# 用法：UNLINK key [key ...]
UNLINK large_list large_set large_hash

# 删除所有键（危险操作）
FLUSHDB             # 删除当前数据库所有键
FLUSHALL            # 删除所有数据库所有键
```

**重命名键**

```shell
# 重命名键
# 用法：RENAME key newkey
RENAME user:1001 user:1002
SET old_name "value"
RENAME old_name new_name
GET new_name

# 仅当新键不存在时重命名
# 用法：RENAMENX key newkey
RENAMENX source_key target_key  # 成功返回1
RENAMENX source_key target_key  # 失败返回0（target_key已存在）
```

## 数据库操作

### 多数据库概念

Redis 支持多个数据库，默认有16个数据库（编号0-15），可以通过配置文件修改数量。

**数据库特点：**
- 每个数据库都是独立的键空间
- 不同数据库间的键名可以相同
- 默认连接到数据库0
- 数据库间不支持关联查询

**使用场景：**
- 区分不同环境（开发、测试、生产）
- 分离不同类型的数据
- 临时数据隔离

### 数据库切换

```shell
# 切换到指定数据库
# 用法：SELECT index
SELECT 0    # 切换到数据库0
SELECT 1    # 切换到数据库1
SELECT 15   # 切换到数据库15

# 示例：在不同数据库中存储数据
SELECT 0
SET app:env "production"
SET app:version "1.0.0"

SELECT 1
SET app:env "development"
SET app:version "1.1.0-dev"

SELECT 2
SET temp:data "临时测试数据"

# 验证数据隔离
SELECT 0
GET app:env     # 返回 "production"

SELECT 1
GET app:env     # 返回 "development"
```

### 数据库清空

```shell
# 清空当前数据库
FLUSHDB

# 异步清空当前数据库
FLUSHDB ASYNC

# 清空所有数据库
FLUSHALL

# 异步清空所有数据库
FLUSHALL ASYNC

# 示例：安全的数据库清理
SELECT 15       # 切换到测试数据库
SET test:key "test_value"
DBSIZE          # 查看键数量
FLUSHDB         # 清空测试数据库
DBSIZE          # 确认清空结果
```

### 数据库信息查看

```shell
# 获取当前数据库键的数量
DBSIZE

# 获取服务器信息
INFO [section]
INFO            # 获取所有信息
INFO server     # 服务器信息
INFO clients    # 客户端信息
INFO memory     # 内存信息
INFO keyspace   # 键空间信息

# 获取配置信息
CONFIG GET parameter
CONFIG GET databases    # 查看数据库数量配置
CONFIG GET maxmemory    # 查看最大内存配置

# 示例：查看各数据库使用情况
INFO keyspace
# 输出示例：
# db0:keys=100,expires=10,avg_ttl=3600000
# db1:keys=50,expires=5,avg_ttl=1800000
```

## 事务操作

### 事务的概念

Redis 事务是一组命令的集合，这些命令会被顺序执行，具有以下特点：

**事务特性：**
- **原子性**：事务中的命令要么全部执行，要么全部不执行
- **一致性**：事务执行前后，数据保持一致状态
- **隔离性**：事务执行过程中不会被其他命令干扰
- **持久性**：事务执行结果会被持久化（如果启用了持久化）

**Redis 事务限制：**
- 不支持回滚
- 命令错误不会影响其他命令执行
- 不支持嵌套事务

### MULTI/EXEC 命令

**基本事务操作**

```shell
# 开始事务
MULTI

# 添加命令到事务队列
SET account:1001:balance 1000
SET account:1002:balance 500
DECRBY account:1001:balance 100
INCRBY account:1002:balance 100

# 执行事务
EXEC

# 取消事务
# DISCARD
```

**完整事务示例**

```shell
# 银行转账事务示例
MULTI
GET account:1001:balance    # 检查余额
DECRBY account:1001:balance 100
INCRBY account:1002:balance 100
SET transfer:log "1001->1002:100"
EXEC

# 批量用户创建事务
MULTI
HMSET user:2001 name "用户A" email "usera@example.com" status "active"
HMSET user:2002 name "用户B" email "userb@example.com" status "active"
SADD active_users "user:2001" "user:2002"
INCR total_users
EXEC
```

**事务错误处理**

```shell
# 语法错误示例（事务不会执行）
MULTI
SET key1 value1
INVALID_COMMAND     # 语法错误
SET key2 value2
EXEC                # 返回错误，事务不执行

# 运行时错误示例（其他命令仍会执行）
MULTI
SET string_key "hello"
LPUSH string_key "world"  # 类型错误，但不影响其他命令
SET another_key "value"
EXEC                # 部分命令执行成功
```

### WATCH 命令

WATCH 命令用于实现乐观锁，监视键的变化。

**基本用法**

```shell
# 监视键
WATCH key [key ...]
WATCH account:1001:balance account:1002:balance

# 开始事务
MULTI
DECRBY account:1001:balance 100
INCRBY account:1002:balance 100
EXEC    # 如果被监视的键发生变化，事务不会执行

# 取消监视
UNWATCH
```

**乐观锁实现**

```shell
# 实现安全的计数器增加
WATCH counter
val=$(redis-cli GET counter)
if [ "$val" -lt 100 ]; then
    redis-cli MULTI
    redis-cli INCR counter
    redis-cli EXEC
else
    redis-cli UNWATCH
    echo "计数器已达到上限"
fi
```

**复杂事务示例**

```shell
# 库存扣减事务（防止超卖）
WATCH product:1001:stock
stock=$(redis-cli GET product:1001:stock)
if [ "$stock" -ge 1 ]; then
    redis-cli MULTI
    redis-cli DECR product:1001:stock
    redis-cli LPUSH order:queue "order:$(date +%s)"
    redis-cli INCR sales:total
    result=$(redis-cli EXEC)
    if [ "$result" != "" ]; then
        echo "购买成功"
    else
        echo "购买失败，请重试"
    fi
else
    redis-cli UNWATCH
    echo "库存不足"
fi
```

### 事务的特性和限制

**事务特性验证**

```shell
# 原子性验证
SET test:atomic "initial"
MULTI
SET test:atomic "step1"
SET test:atomic "step2"
SET test:atomic "final"
EXEC
GET test:atomic     # 返回 "final"

# 隔离性验证（在事务执行期间，其他客户端的命令不会干扰）
# 客户端1：
MULTI
SET test:isolation "value1"
# 暂停，不执行EXEC

# 客户端2：
SET test:isolation "value2"  # 这个命令会立即执行

# 客户端1继续：
EXEC
GET test:isolation  # 返回 "value1"（事务中的值覆盖了客户端2的修改）
```

**事务限制示例**

```shell
# 无回滚特性
SET balance 1000
MULTI
DECRBY balance 100      # 成功
LPUSH balance "error"   # 类型错误，但不影响前面的命令
DECRBY balance 50       # 成功
EXEC
GET balance             # 返回 "850"（前面和后面的命令都执行了）

# 条件执行限制（Redis事务不支持if-else逻辑）
# 需要在应用层实现条件判断
balance=$(redis-cli GET account:balance)
if [ "$balance" -gt 100 ]; then
    redis-cli MULTI
    redis-cli DECRBY account:balance 100
    redis-cli SET last:transaction "withdraw:100"
    redis-cli EXEC
else
    echo "余额不足"
fi
```

## 脚本操作

### Lua 脚本简介

Redis 内嵌了 Lua 解释器，支持执行 Lua 脚本。Lua 脚本的优势：

**主要优势：**
- **原子性**：脚本执行过程中不会被其他命令干扰
- **减少网络开销**：多个命令在服务器端执行
- **复杂逻辑**：支持条件判断、循环等复杂逻辑
- **性能优化**：避免多次网络往返

**使用场景：**
- 复杂的原子操作
- 条件判断和循环
- 批量数据处理
- 限流算法实现
- 分布式锁

### EVAL 和 EVALSHA 命令

**EVAL 命令基本用法**

```shell
# EVAL script numkeys key [key ...] arg [arg ...]
# script: Lua脚本
# numkeys: 键的数量
# key: 键名
# arg: 参数

# 简单示例：设置键值并返回
EVAL "return redis.call('SET', KEYS[1], ARGV[1])" 1 mykey myvalue

# 获取并增加计数器
EVAL "local val = redis.call('GET', KEYS[1]) or 0; return redis.call('INCR', KEYS[1])" 1 counter

# 条件设置（仅当键不存在时设置）
EVAL "if redis.call('EXISTS', KEYS[1]) == 0 then return redis.call('SET', KEYS[1], ARGV[1]) else return nil end" 1 newkey newvalue
```


**EVALSHA 命令**

```shell
# 加载脚本并获取SHA1值
SCRIPT LOAD "return redis.call('GET', KEYS[1])"
# 返回："6b1bf486c81ceb7edf3c093f4c48582e38c0e791"

# 使用SHA1值执行脚本
EVALSHA 6b1bf486c81ceb7edf3c093f4c48582e38c0e791 1 mykey

# 检查脚本是否存在
SCRIPT EXISTS sha1 [sha1 ...]
SCRIPT EXISTS 6b1bf486c81ceb7edf3c093f4c48582e38c0e791

# 清除脚本缓存
SCRIPT FLUSH

# 杀死正在执行的脚本
SCRIPT KILL
```

### 脚本缓存

Redis 会缓存已执行的脚本，提高重复执行的性能。

```shell
# 预加载常用脚本
incr_script_sha=$(redis-cli SCRIPT LOAD "return redis.call('INCR', KEYS[1])")
echo "增加计数器脚本SHA: $incr_script_sha"

# 使用缓存的脚本
redis-cli EVALSHA $incr_script_sha 1 my_counter
redis-cli EVALSHA $incr_script_sha 1 my_counter
redis-cli EVALSHA $incr_script_sha 1 my_counter

# 检查脚本缓存状态
redis-cli SCRIPT EXISTS $incr_script_sha

# 获取脚本缓存统计
redis-cli INFO memory | grep script
```

## 实践操作