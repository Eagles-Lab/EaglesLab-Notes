# Redis 数据类型

Redis 支持五种基本数据类型，每种数据类型都有其特定的应用场景和操作命令。理解这些数据类型的特点和使用方法是掌握 Redis 的关键。

## 字符串 (String)

### 字符串的特点和应用

字符串是 Redis 最基本的数据类型，也是最常用的类型。在 Redis 中，字符串是二进制安全的，可以存储任何数据，包括数字、文本、序列化对象、甚至是图片。

**主要特点：**
- **二进制安全**：可以存储任何二进制数据
- **最大长度**：单个字符串最大 512MB
- **编码优化**：Redis 会根据内容自动选择最优编码
- **原子操作**：所有字符串操作都是原子性的

**常见应用场景：**
- 缓存数据（JSON、XML、HTML 等）
- 计数器（访问量、点赞数等）
- 分布式锁
- 会话存储
- 配置信息存储

### 基本操作命令

**设置和获取**

```shell
# 设置键值
# 用法：SET key value
SET name "张三"
SET age 25

# 获取值
# 用法：GET key
GET name        # 返回 "张三"
GET age         # 返回 "25"
GET nonexistent # 返回 (nil)

# 批量设置
# 用法：MSET key1 value1 key2 value2 key3 value3
MSET user:1:name "张三" user:1:age 25 user:1:city "北京"

# 批量获取
# 用法：MGET key1 key2 key3
MGET key1 key2 key3
MGET user:1:name user:1:age user:1:city

# 设置并返回旧值
# 用法：GETSET key newvalue
GETSET key newvalue
GETSET counter 100  # 返回旧值，设置新值为100
```

**条件设置**

```shell
# 仅当键不存在时设置
# 用法：SETNX key value
SETNX lock:resource "server1"  # 分布式锁应用

# 设置键值和过期时间
# 用法：SETEX key seconds value
SETEX session:abc123 3600 "user_data"  # 3600秒后过期

# 仅当键不存在时设置，并指定过期时间
# 用法：SET key value EX seconds NX
SET lock:order:1001 "processing" EX 30 NX

# 仅当键存在时设置
# 用法：SET key value XX
SET existing_key "new_value" XX
```

**字符串操作**

```shell
# 追加字符串
# 用法：APPEND key value
SET message "Hello"
APPEND message " World"  # message 现在是 "Hello World"

# 获取字符串长度
# 用法：STRLEN key
STRLEN message  # 返回 11

# 获取子字符串
# 用法：GETRANGE key start end
GETRANGE message 0 4   # 返回 "Hello"
GETRANGE message -5 -1 # 返回 "World"

# 设置子字符串
# 用法：SETRANGE key offset value
SETRANGE message 6 "Redis"  # message 现在是 "Hello Redis"
```

### 数值操作

Redis 可以将字符串当作数字进行操作，支持整数和浮点数。

```shell
# 整数操作
SET counter 10

# 增加指定值
INCR counter        # counter = 11
INCRBY counter 5    # counter = 16
DECR counter        # counter = 15
DECRBY counter 3    # counter = 12

# 浮点数操作
SET price 19.99
INCRBYFLOAT price 5.01  # price = 25.00
INCRBYFLOAT price -2.50 # price = 22.50

# 应用示例：网站访问计数
INCR page:home:views
INCR user:1001:login_count
INCRBY article:123:likes 1
```

### 位操作

Redis 支持对字符串进行位级操作，适用于布尔值存储和位图应用。

```shell
# 设置位值
# 用法：SETBIT key offset value
SETBIT user:1001:login 0 1  # 设置第0位为1
SETBIT user:1001:login 1 0  # 设置第1位为0
SETBIT user:1001:login 2 1  # 设置第2位为1

# 获取位值
# 用法：GETBIT key offset
GETBIT user:1001:login 0    # 返回 1
GETBIT user:1001:login 1    # 返回 0

# 统计位为1的数量
BITCOUNT key [start end]
BITCOUNT user:1001:login    # 返回 2

# 位运算
# 用法：BITOP operation destkey key [key ...]
SETBIT user:1001 0 1
SETBIT user:1001 1 0
SETBIT user:1002 0 1
SETBIT user:1002 1 1
BITOP AND result user:1001 user:1002  # 按位与运算
BITOP OR result user:1001 user:1002   # 按位或运算

# 查找第一个指定位值的位置
# 用法：BITPOS key bit [start] [end]
BITPOS user:1001:login 1    # 查找第一个1的位置
```

## 列表 (List)

### 列表的特点和应用

Redis 列表是简单的字符串列表，按照插入顺序排序。可以添加元素到列表的头部或尾部。

**主要特点：**
- **有序性**：元素按插入顺序排列
- **可重复**：允许重复元素
- **双端操作**：支持头部和尾部操作
- **最大长度**：理论上可包含 2^32 - 1 个元素

**常见应用场景：**
- 消息队列
- 最新消息列表
- 用户操作历史
- 任务队列
- 时间线功能

### 基本操作命令

**添加元素**

```shell
# 从左侧（头部）添加
# 用法：LPUSH key element [element ...]
LPUSH messages "消息3" "消息2" "消息1"
# 结果：["消息1", "消息2", "消息3"]

# 从右侧（尾部）添加
# 用法：RPUSH key element [element ...]
RPUSH messages "消息4" "消息5"
# 结果：["消息1", "消息2", "消息3", "消息4", "消息5"]

# 仅当列表存在时添加
# 用法：LPUSHX key element
# 用法：RPUSHX key element
LPUSHX messages "消息6"
RPUSHX messages "消息7"
```

**获取元素**

```shell
# 获取指定范围的元素
# 用法：LRANGE key start stop
LRANGE messages 0 -1    # 获取所有元素
LRANGE messages 0 2     # 获取前3个元素
LRANGE messages -3 -1   # 获取最后3个元素
```

**删除元素**

```shell
# 从左侧（头部）删除
# 用法：LPOP key
LPOP messages           # 弹出并返回第一个元素

# 从右侧（尾部）删除
# 用法：RPOP key
RPOP messages           # 弹出并返回最后一个元素

# 在指定元素前/后插入
# 用法：LINSERT key BEFORE|AFTER pivot element
LINSERT messages BEFORE "消息3" "消息2.5"
```

**获取元素**

```shell
# 获取指定范围的元素
# 用法：LRANGE key start stop
LRANGE messages 0 -1    # 获取所有元素
LRANGE messages 0 2     # 获取前3个元素
LRANGE messages -3 -1   # 获取最后3个元素

# 获取指定索引的元素
# 用法：LINDEX key index
LINDEX messages 0       # 获取第一个元素
LINDEX messages -1      # 获取最后一个元素

# 获取列表长度
# 用法：LLEN key
LLEN messages           # 返回列表长度
```

**删除元素**

```shell
# 从左侧（头部）弹出
# 用法：LPOP key
LPOP messages           # 弹出并返回第一个元素

# 从右侧（尾部）弹出
# 用法：RPOP key
RPOP messages           # 弹出并返回最后一个元素

# 删除指定值的元素
# 用法：LREM key count element
LREM messages 1 "消息2"   # 从头开始删除1个"消息2"
LREM messages -1 "消息2"  # 从尾开始删除1个"消息2"
LREM messages 0 "消息2"   # 删除所有"消息2"

# 保留指定范围的元素
# 用法：LTRIM key start stop
LTRIM messages 0 99     # 只保留前100个元素
```

**修改元素**

```shell
# 设置指定索引的元素值
# 用法：LSET key index element
LSET messages 0 "新消息1"
```

### 阻塞操作

阻塞操作是 Redis 列表的重要特性，常用于实现消息队列。

```shell
# 阻塞式左侧弹出
# 用法：BLPOP key [key ...] timeout
BLPOP task_queue 30     # 等待30秒，如果有元素则弹出

# 阻塞式右侧弹出
# 用法：BRPOP key [key ...] timeout
BRPOP task_queue 0      # 无限等待

# 阻塞式右侧弹出并左侧推入
# 用法：BRPOPLPUSH source destination timeout
BRPOPLPUSH pending_tasks processing_tasks 60
```

### 列表的应用场景

**消息队列实现**

```shell
# 生产者：添加任务到队列
LPUSH task_queue "发送邮件:user@example.com"
LPUSH task_queue "生成报表:monthly_report"
LPUSH task_queue "数据备份:database_backup"

# 消费者：从队列获取任务
BRPOP task_queue 30
# 返回：1) "task_queue" 2) "发送邮件:user@example.com"
```

**最新消息列表**

```shell
# 添加新消息（保持最新100条）
LPUSH latest_news "新闻标题1"
LTRIM latest_news 0 99

# 获取最新10条消息
LRANGE latest_news 0 9
```

**用户操作历史**

```shell
# 记录用户操作
LPUSH user:1001:actions "登录:2024-01-15 10:30:00"
LPUSH user:1001:actions "查看商品:product_123"
LPUSH user:1001:actions "加入购物车:product_123"

# 获取最近操作历史
LRANGE user:1001:actions 0 9
```

## 集合 (Set)

### 集合的特点和应用

Redis 集合是字符串的无序集合，集合中的元素是唯一的。

**主要特点：**
- **唯一性**：不允许重复元素
- **无序性**：元素没有固定顺序
- **快速查找**：O(1) 时间复杂度判断元素是否存在
- **集合运算**：支持交集、并集、差集运算

**常见应用场景：**
- 标签系统
- 好友关系
- 权限管理
- 去重统计
- 抽奖系统

### 基本操作命令

**添加和删除元素**

```shell
# 添加元素
# 用法：SADD key member [member ...]
SADD tags "Redis" "数据库" "缓存" "NoSQL"
SADD user:1001:skills "Java" "Python" "Redis"

# 删除元素
# 用法：SREM key member [member ...]
SREM tags "缓存"
SREM user:1001:skills "Java"

# 随机删除并返回元素
# 用法：SPOP key [count]
SPOP tags           # 随机删除一个元素
SPOP tags 2         # 随机删除两个元素
```

**查询操作**

```shell
# 获取所有元素
# 用法：SMEMBERS key
SMEMBERS tags

# 判断元素是否存在
# 用法：SISMEMBER key member
SISMEMBER tags "Redis"      # 返回 1（存在）
SISMEMBER tags "MySQL"      # 返回 0（不存在）

# 获取集合大小
# 用法：SCARD key
SCARD tags                  # 返回集合元素数量

# 随机获取元素（不删除）
# 用法：SRANDMEMBER key [count]
SRANDMEMBER tags            # 随机返回一个元素
SRANDMEMBER tags 3          # 随机返回三个元素
```

**移动元素**

```shell
# 将元素从一个集合移动到另一个集合
# 用法：SMOVE source destination member
SMOVE user:1001:skills user:1002:skills "Python"
```

### 集合运算

Redis 支持集合间的数学运算，这是集合类型的强大特性。

```shell
# 准备测试数据
SADD set1 "a" "b" "c" "d"
SADD set2 "c" "d" "e" "f"
SADD set3 "d" "e" "f" "g"

# 交集运算
# 用法：SINTER key [key ...]
SINTER set1 set2            # 返回 {"c", "d"}
SINTER set1 set2 set3       # 返回 {"d"}

# 并集运算
# 用法：SUNION key [key ...]
SUNION set1 set2            # 返回 {"a", "b", "c", "d", "e", "f"}

# 差集运算
# 用法：SDIFF key [key ...]
SDIFF set1 set2             # 返回 {"a", "b"}
SDIFF set2 set1             # 返回 {"e", "f"}

# 将运算结果存储到新集合
# 用法：[SINTERSTORE | SUNIONSTORE | SDIFFSTORE] destination key [key ...]

SINTERSTORE result set1 set2
SMEMBERS result             # 查看交集结果
```

### 随机操作

集合的随机操作常用于抽奖、推荐等场景。

```shell
# 抽奖系统示例
SADD lottery_pool "用户1" "用户2" "用户3" "用户4" "用户5"

# 随机抽取一个中奖者（不删除）
SRANDMEMBER lottery_pool

# 随机抽取并移除中奖者
SPOP lottery_pool

# 抽取多个中奖者
SPOP lottery_pool 3
```

## 有序集合 (Sorted Set)

### 有序集合的特点和应用

有序集合是 Redis 中最复杂的数据类型，它结合了集合和列表的特点。

**主要特点：**
- **唯一性**：成员唯一，不允许重复
- **有序性**：按分数（score）排序
- **双重索引**：可以按成员或分数查找
- **范围查询**：支持按分数或排名范围查询

**常见应用场景：**
- 排行榜系统
- 优先级队列
- 时间线排序
- 范围查询
- 权重计算

### 基本操作命令

**添加和删除元素**

```shell
# 添加元素（分数 成员）
# 用法：ZADD key [NX|XX] [CH] [INCR] score member [score member ...]
ZADD leaderboard 1500 "玩家A"
ZADD leaderboard 2300 "玩家B" 1800 "玩家C" 2100 "玩家D"
# 批量添加
ZADD leaderboard 1200 "玩家E" 1900 "玩家F" 2500 "玩家G"

# 删除元素
# 用法：ZREM key member [member ...]
ZREM leaderboard "玩家E"

# 按分数范围删除
# 用法：ZREMRANGEBYSCORE key min max
ZREMRANGEBYSCORE leaderboard 0 1000

# 按排名范围删除
# 用法：ZREMRANGEBYRANK key start stop
ZREMRANGEBYRANK leaderboard 0 2    # 删除前3名
```

**查询操作**

```shell
# 获取元素数量
# 用法：ZCARD key
ZCARD leaderboard

# 获取元素分数
# 用法：ZSCORE key member
ZSCORE leaderboard "玩家B"

# 获取元素排名
# 用法：ZRANK key member        # 正序排名（从0开始）
# 用法：ZREVRANK key member     # 逆序排名（从0开始）
ZRANK leaderboard "玩家B"
ZREVRANK leaderboard "玩家B"

# 统计分数范围内的元素数量
# 用法：ZCOUNT key min max  
ZCOUNT leaderboard 1500 2000

# 获取分数范围内的元素数量（字典序）
# 用法：ZLEXCOUNT key min max
ZLEXCOUNT leaderboard a c
```

### 范围操作

有序集合的范围操作是其最强大的功能之一。

**按排名范围查询**

```shell
# 按排名获取元素（正序）
# 用法：ZRANGE key start stop [WITHSCORES]
ZRANGE leaderboard 0 2              # 获取前3名
ZRANGE leaderboard 0 2 WITHSCORES   # 获取前3名及分数
ZRANGE leaderboard 0 -1             # 获取所有元素

# 按排名获取元素（逆序）
# 用法：ZREVRANGE key start stop [WITHSCORES]
ZREVRANGE leaderboard 0 2 WITHSCORES # 获取前3名（高分到低分）
```

**按分数范围查询**

```shell
# 按分数范围获取元素（正序）
# 用法：ZRANGEBYSCORE key min max [WITHSCORES] [LIMIT offset count]
ZRANGEBYSCORE leaderboard 1500 2000
ZRANGEBYSCORE leaderboard 1500 2000 WITHSCORES
ZRANGEBYSCORE leaderboard 1500 2000 LIMIT 0 5

# 按分数范围获取元素（逆序）
# 用法：ZREVRANGEBYSCORE key max min [WITHSCORES] [LIMIT offset count]
ZREVRANGEBYSCORE leaderboard 2000 1500 WITHSCORES

# 使用开区间
ZRANGEBYSCORE leaderboard 1500 2000    # 不包含1500和2000
ZRANGEBYSCORE leaderboard -inf +inf     # 所有元素
```

**按字典序范围查询**

```shell
# 按字典序范围获取元素
# 用法：ZRANGEBYLEX key min max [LIMIT offset count]
ZRANGEBYLEX leaderboard a c
# 用法：ZREVRANGEBYLEX key max min [LIMIT offset count]
ZREVRANGEBYLEX leaderboard c a

# 示例：相同分数的元素按字典序排列
ZADD words 0 "apple" 0 "banana" 0 "cherry" 0 "date"
ZRANGEBYLEX words a c              # 获取a到c之间的单词
ZRANGEBYLEX words banana date      # 获取banana到date之间的单词
```

### 排行榜应用

有序集合最典型的应用就是排行榜系统。

```shell
# 游戏排行榜示例
# 添加玩家分数
ZADD game:leaderboard 15000 "张三"
ZADD game:leaderboard 23000 "李四"
ZADD game:leaderboard 18000 "王五"
ZADD game:leaderboard 21000 "赵六"
ZADD game:leaderboard 19000 "钱七"

# 获取排行榜前10名
ZREVRANGE game:leaderboard 0 9 WITHSCORES

# 获取某玩家的排名
ZREVRANK game:leaderboard "张三"     # 返回排名（从0开始）

# 获取某玩家的分数
ZSCORE game:leaderboard "张三"

# 增加玩家分数
ZINCRBY game:leaderboard 1000 "张三"

# 获取分数范围内的玩家
ZRANGEBYSCORE game:leaderboard 20000 25000 WITHSCORES

# 获取排名范围内的玩家
ZREVRANGE game:leaderboard 10 19 WITHSCORES  # 第11-20名
```

## 哈希 (Hash)

### 哈希的特点和应用

Redis 哈希是一个键值对集合，特别适合存储对象。

**主要特点：**
- **结构化存储**：键值对形式存储
- **内存优化**：小哈希使用压缩编码
- **部分更新**：可以只更新某个字段
- **原子操作**：字段级别的原子操作

**常见应用场景：**
- 用户信息存储
- 配置信息管理
- 购物车实现
- 对象缓存
- 计数器组合

### 基本操作命令

**设置和获取字段**

```shell
# 用法：HSET key field value
HSET user:1001 name "张三"
HSET user:1001 age 28
HSET user:1001 city "北京"
HSET user:1001 email "zhangsan@example.com"

# 用法：HMSET key field value [field value ...]
HMSET user:1002 name "李四" age 25 city "上海" email "lisi@example.com"

# 仅当字段不存在时设置
# 用法：HSETNX key field value
HSETNX user:1001 phone "13800138000"

# 获取单个字段
# 用法：HGET key field
HGET user:1001 name
HGET user:1001 age

# 获取多个字段
# 用法：HMGET key field [field ...]
HMGET user:1001 name age city

# 获取所有字段和值
# 用法：HGETALL key
HGETALL user:1001

# 获取所有字段名
# 用法：HKEYS key
HKEYS user:1001

# 获取所有值
# 用法：HVALS key
HVALS user:1001
```

**删除和检查字段**

```shell
# 删除字段
# 用法：HDEL key field [field ...]
HDEL user:1001 email
HDEL user:1001 phone city

# 检查字段是否存在
# 用法：HEXISTS key field
HEXISTS user:1001 name      # 返回 1（存在）
HEXISTS user:1001 phone     # 返回 0（不存在）

# 获取字段数量
# 用法：HLEN key
HLEN user:1001
```

### 批量操作

哈希支持高效的批量操作，减少网络往返次数。

```shell
# 批量设置用户信息
HMSET user:1003 \
  name "王五" \
  age 30 \
  city "广州" \
  email "wangwu@example.com" \
  phone "13900139000" \
  department "技术部" \
  position "高级工程师"

# 批量获取用户信息
HMGET user:1003 name age city department position

# 获取完整用户信息
HGETALL user:1003
```

### 数值操作

哈希字段支持数值操作，常用于计数器场景。

```shell
# 增加字段的数值
# 用法：HINCRBY key field increment
HSET user:1001 login_count 0
HINCRBY user:1001 login_count 1     # login_count = 1
HINCRBY user:1001 login_count 5     # login_count = 6

# 增加字段的浮点数值
HINCRBYFLOAT key field increment
HSET user:1001 balance 100.50
HINCRBYFLOAT user:1001 balance 25.30   # balance = 125.80
HINCRBYFLOAT user:1001 balance -10.00  # balance = 115.80
```

### 对象存储应用

哈希非常适合存储对象数据，提供了比字符串更好的结构化存储。

**用户信息管理**

```shell
# 创建用户信息
HMSET user:1001 \
  name "张三" \
  age 28 \
  email "zhangsan@example.com" \
  city "北京" \
  department "研发部" \
  position "软件工程师" \
  salary 15000 \
  join_date "2023-01-15" \
  status "active"

# 更新用户信息
HSET user:1001 age 29
HSET user:1001 salary 16000
HSET user:1001 position "高级软件工程师"

# 获取用户基本信息
HMGET user:1001 name age email city

# 获取用户工作信息
HMGET user:1001 department position salary

# 检查用户状态
HGET user:1001 status
```

**购物车实现**

```shell
# 用户购物车：cart:user_id，字段为商品ID，值为数量
HSET cart:1001 product:123 2
HSET cart:1001 product:456 1
HSET cart:1001 product:789 3

# 增加商品数量
HINCRBY cart:1001 product:123 1     # 数量变为3

# 减少商品数量
HINCRBY cart:1001 product:456 -1    # 数量变为0

# 删除商品（数量为0时）
HDEL cart:1001 product:456

# 获取购物车所有商品
HGETALL cart:1001

# 获取购物车商品数量
HLEN cart:1001

# 清空购物车
DEL cart:1001
```

**配置信息管理**

```shell
# 应用配置
HMSET app:config \
  database_host "localhost" \
  database_port 3306 \
  database_name "myapp" \
  redis_host "localhost" \
  redis_port 6379 \
  cache_ttl 3600 \
  max_connections 100 \
  debug_mode "false"

# 获取数据库配置
HMGET app:config database_host database_port database_name

# 获取缓存配置
HMGET app:config redis_host redis_port cache_ttl

# 更新配置
HSET app:config debug_mode "true"
HSET app:config max_connections 200

# 获取所有配置
HGETALL app:config
```

## 实践操作

### 需求描述

使用 Redis 的不同数据类型构建一个完整的用户信息存储系统，包括用户基本信息、用户标签、用户行为记录等。

### 实践细节和结果验证

```shell
# 1. 用户基本信息（使用哈希）
redis-cli << 'EOF'
# 创建用户基本信息
HMSET user:1001 \
  name "张三" \
  age 28 \
  email "zhangsan@example.com" \
  phone "13800138000" \
  city "北京" \
  department "技术部" \
  position "高级工程师" \
  join_date "2023-01-15" \
  status "active"

HMSET user:1002 \
  name "李四" \
  age 25 \
  email "lisi@example.com" \
  phone "13900139000" \
  city "上海" \
  department "产品部" \
  position "产品经理" \
  join_date "2023-03-20" \
  status "active"

# 获取用户信息
HGETALL user:1001
HMGET user:1002 name age department position
EOF

# 2. 用户标签系统（使用集合）
redis-cli << 'EOF'
# 为用户添加标签
SADD user:1001:tags "技术专家" "Redis" "Python" "团队领导" "创新者"
SADD user:1002:tags "产品专家" "用户体验" "数据分析" "沟通能力" "创新者"
SADD user:1003:tags "设计师" "UI/UX" "创意" "用户体验" "创新者"

# 查看用户标签
SMEMBERS user:1001:tags
SMEMBERS user:1002:tags

# 查找共同标签
SINTER user:1001:tags user:1002:tags
SINTER user:1002:tags user:1003:tags

# 查找所有标签
SUNION user:1001:tags user:1002:tags user:1003:tags
EOF

# 3. 用户行为记录（使用列表）
redis-cli << 'EOF'
# 记录用户行为（最新的在前面）
LPUSH user:1001:actions "登录:2024-01-15 09:00:00"
LPUSH user:1001:actions "查看文档:Redis教程"
LPUSH user:1001:actions "编辑代码:user_service.py"
LPUSH user:1001:actions "提交代码:修复缓存bug"
LPUSH user:1001:actions "参加会议:技术分享"

LPUSH user:1002:actions "登录:2024-01-15 09:30:00"
LPUSH user:1002:actions "查看报表:用户增长数据"
LPUSH user:1002:actions "创建需求:新功能设计"
LPUSH user:1002:actions "审核设计:UI界面"

# 获取用户最近行为
LRANGE user:1001:actions 0 4
LRANGE user:1002:actions 0 4

# 保持行为记录在合理范围内（最多100条）
LTRIM user:1001:actions 0 99
LTRIM user:1002:actions 0 99
EOF

# 4. 用户积分排行（使用有序集合）
redis-cli << 'EOF'
# 设置用户积分
ZADD user:points 1500 "user:1001"
ZADD user:points 2300 "user:1002"
ZADD user:points 1800 "user:1003"
ZADD user:points 2100 "user:1004"
ZADD user:points 1200 "user:1005"

# 增加用户积分
ZINCRBY user:points 200 "user:1001"
ZINCRBY user:points 150 "user:1003"

# 查看积分排行榜
ZREVRANGE user:points 0 -1 WITHSCORES

# 查看用户排名
ZREVRANK user:points "user:1001"
ZREVRANK user:points "user:1002"

# 查看用户积分
ZSCORE user:points "user:1001"
EOF

# 5. 用户会话管理（使用字符串）
redis-cli << 'EOF'
# 创建用户会话
SET session:abc123 "user:1001" EX 3600
SET session:def456 "user:1002" EX 3600

# 检查会话
GET session:abc123
TTL session:abc123

# 延长会话
EXPIRE session:abc123 7200
TTL session:abc123
EOF

# 6. 用户统计信息（使用哈希）
redis-cli << 'EOF'
# 用户统计数据
HMSET user:1001:stats \
  login_count 45 \
  last_login "2024-01-15 09:00:00" \
  total_actions 156 \
  articles_read 23 \
  code_commits 89

HMSET user:1002:stats \
  login_count 38 \
  last_login "2024-01-15 09:30:00" \
  total_actions 142 \
  reports_created 15 \
  meetings_attended 67

# 更新统计数据
HINCRBY user:1001:stats login_count 1
HSET user:1001:stats last_login "2024-01-15 14:30:00"
HINCRBY user:1001:stats total_actions 1

# 查看统计数据
HGETALL user:1001:stats
HMGET user:1002:stats login_count last_login total_actions
EOF

# 查找活跃用户（积分>1500）
redis-cli ZRANGEBYSCORE user:points 1500 +inf WITHSCORES

# 查找技术相关用户
redis-cli SISMEMBER user:1001:tags "技术专家"
redis-cli SISMEMBER user:1002:tags "技术专家"

# 获取用户完整信息
redis-cli HMGET user:1001 name age department position
redis-cli SMEMBERS user:1001:tags
redis-cli LRANGE user:1001:actions 0 2
redis-cli ZSCORE user:points "user:1001"
redis-cli ZREVRANK user:points "user:1001"
redis-cli HMGET user:1001:stats login_count total_actions

# 清理测试数据
redis-cli << 'EOF'
DEL user:1001 user:1002 user:1003
DEL user:1001:tags user:1002:tags user:1003:tags
DEL user:1001:actions user:1002:actions
DEL user:points
DEL session:abc123 session:def456
DEL user:1001:stats user:1002:stats
EOF
```
