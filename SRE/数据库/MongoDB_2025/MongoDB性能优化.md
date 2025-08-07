# MongoDB 性能监控与调优

为了确保 MongoDB 数据库持续、稳定、高效地运行，必须对其进行有效的性能监控和及时的调优。本章节将介绍 MongoDB 的关键性能指标、常用的监控工具以及针对常见性能问题的调优策略。

---

## 关键性能指标

监控 MongoDB 时，应重点关注以下几类指标：

### 操作计数器 (Operation Counters)

- **`opcounters`**: 显示自 `mongod` 启动以来执行的数据库操作（insert, query, update, delete, getmore, command）的总数。通过观察其增长率，可以了解数据库的负载情况。

### 锁 (Locks)

- **`globalLock`**: 反映全局锁的使用情况。在 WiredTiger 存储引擎中，全局锁的使用已大大减少，但仍需关注。
- **`locks`**: 提供数据库、集合等更细粒度锁的信息。长时间的锁等待（`timeAcquiringMicros`）可能表示存在锁竞争，需要优化查询或索引。

### 网络 (Network)

- **`network.bytesIn` / `network.bytesOut`**: 进出数据库的网络流量。
- **`network.numRequests`**: 接收到的请求总数。
- 监控网络指标有助于发现网络瓶颈或异常的客户端行为。

### 内存 (Memory)

- **`mem.resident`**: 进程占用的物理内存（RAM）大小。
- **`mem.virtual`**: 进程使用的虚拟内存大小。
- **`mem.mapped`**: 内存映射文件的大小。
- 监控内存使用情况，特别是 WiredTiger 的内部缓存（`wiredTiger.cache`），对于确保性能至关重要。

### Oplog

- **Oplog Window**: Oplog 中记录的操作所覆盖的时间范围。如果 oplog window 太小，从节点可能会因为跟不上主节点的更新速度而掉队（stale）。

### 慢查询 (Slow Queries)

- **`system.profile` 集合**: 当开启数据库分析（profiling）后，执行时间超过阈值的查询会被记录到该集合中。这是识别和优化慢查询的主要工具。

---

## 监控工具

### `mongostat`

- **描述**: 一个命令行工具，可以实时地、逐秒地显示 MongoDB 实例的主要性能指标，类似于 Linux 的 `vmstat`。
- **用途**: 快速了解数据库当前的操作负载和性能状况。

  ```bash
  mongostat
  ```

### `mongotop`

- **描述**: 一个命令行工具，用于跟踪 MongoDB 实例花费时间最多的读写操作。
- **用途**: 快速定位哪些集合是当前系统的性能热点。

  ```bash
  mongotop 10 # 每 10 秒刷新一次
  ```

### `db.serverStatus()`

- **描述**: 一个数据库命令，返回一个包含大量服务器状态信息的文档。
- **用途**: 获取详细的、全面的性能指标，是大多数监控系统的主要数据来源。

  ```javascript
  db.serverStatus()
  ```

### MongoDB Cloud Manager / Ops Manager

- **描述**: 提供了一个功能强大的图形化监控界面，可以收集、可视化并告警各种性能指标。
- **用途**: 长期、系统化的性能监控和趋势分析。

---

## 性能调优策略

### 索引优化

- **识别缺失的索引**: 通过分析 `system.profile` 集合中的慢查询日志，找出那些因为缺少合适索引而导致全集合扫描（`COLLSCAN`）的查询。
- **评估现有索引**: 使用 `$indexStats` 聚合阶段检查索引的使用频率。对于很少使用或从不使用的索引，应考虑删除以减少写操作的开销和存储空间。
- **创建复合索引**: 根据 ESR 法则设计高效的复合索引，使其能够覆盖多种查询模式。

### 查询优化

- **使用投影 (Projection)**: 只返回查询所需的字段，减少网络传输量和客户端处理数据的负担。
- **避免使用 `$where` 和 `$function`**: 这类操作无法使用索引，并且会在每个文档上执行 JavaScript，性能极差。
- **优化正则表达式**: 尽量使用前缀表达式（如 `/^prefix/`），这样可以利用索引。避免使用不区分大小写的正则表达式，因为它无法有效利用索引。

### Schema 设计调优

- **遵循数据建模模式**: 根据应用的读写模式选择合适的建模策略（嵌入 vs. 引用），可以从根本上提升性能。
- **避免大文档和无界数组**: 过大的文档会增加内存使用和网络传输，无限制增长的数组会给更新操作带来性能问题。

### 硬件和拓扑结构调优

- **内存**: 确保 WiredTiger 的缓存大小（默认为 `(RAM - 1GB) / 2`）足够容纳工作集（Working Set），即最常访问的数据和索引。
- **磁盘**: 使用 SSD 可以显著提升 I/O 性能，特别是对于写密集型应用。
- **网络**: 确保数据库服务器之间的网络延迟尽可能低，特别是在分片集群和地理分布的副本集中。
- **读写分离**: 在读密集型应用中，通过将读请求路由到从节点来扩展读取能力。

---

## 实践操作

### 需求描述

构建一个完整的 MongoDB 性能监控与调优实践环境，掌握性能指标监控、慢查询分析、索引优化等核心技能。通过实际操作理解如何识别性能瓶颈、分析查询执行计划、创建高效索引，以及使用各种监控工具来持续优化数据库性能。

### 实践细节和结果验证

```shell
# 1. 准备测试数据和环境
# 创建性能测试数据库
use performanceTestDB

# 创建大量测试数据
for (let i = 0; i < 100000; i++) {
  db.products.insertOne({
    productId: "PROD" + i.toString().padStart(6, '0'),
    name: "Product " + i,
    category: ["electronics", "books", "clothing", "home"][i % 4],
    price: Math.floor(Math.random() * 1000) + 10,
    rating: Math.floor(Math.random() * 5) + 1,
    inStock: Math.random() > 0.3,
    tags: ["popular", "new", "sale", "featured"].slice(0, Math.floor(Math.random() * 3) + 1),
    createdAt: new Date(Date.now() - Math.floor(Math.random() * 365 * 24 * 60 * 60 * 1000))
  });
}

# 验证数据插入
db.products.countDocuments()  # 预期结果: 100000

# 2. 开启数据库性能分析 (Profiling)
# 设置慢查询阈值为100ms，记录所有慢查询
db.setProfilingLevel(1, { slowms: 100 })

# 验证profiling设置
db.getProfilingStatus()
# 预期结果: { "was" : 1, "slowms" : 100, "sampleRate" : 1.0 }

# 3. 生成慢查询进行性能分析
# 执行没有索引的复杂查询（故意制造慢查询）
db.products.find({ 
  category: "electronics", 
  price: { $gte: 500 }, 
  rating: { $gte: 4 },
  inStock: true 
}).sort({ createdAt: -1 }).limit(10)

# 执行正则表达式查询（通常较慢）
db.products.find({ name: /Product 1.*/ })

# 执行范围查询
db.products.find({ 
  price: { $gte: 100, $lte: 500 },
  createdAt: { $gte: new Date("2023-01-01") }
})

# 4. 分析慢查询日志
# 查看最近的慢查询记录
db.system.profile.find().sort({ ts: -1 }).limit(5).pretty()
# 预期结果: 显示最近5条慢查询记录，包含执行时间、查询语句等信息

# 查看特定类型的慢查询
db.system.profile.find({ 
  "command.find": "products",
  "millis": { $gte: 100 }
}).sort({ ts: -1 })

# 统计慢查询数量
db.system.profile.countDocuments({ "millis": { $gte: 100 } })
# 预期结果: 显示慢查询总数

# 5. 使用 explain() 分析查询执行计划
# 分析复杂查询的执行计划
db.products.find({ 
  category: "electronics", 
  price: { $gte: 500 }, 
  rating: { $gte: 4 }
}).explain("executionStats")
# 预期结果: 显示详细的执行统计，包括扫描的文档数、执行时间等

# 查看查询是否使用了索引
db.products.find({ category: "electronics" }).explain("queryPlanner")
# 预期结果: winningPlan.stage 应该显示 "COLLSCAN"（全集合扫描）

# 6. 创建索引优化查询性能
# 为常用查询字段创建单字段索引
db.products.createIndex({ category: 1 })
db.products.createIndex({ price: 1 })
db.products.createIndex({ rating: 1 })
db.products.createIndex({ createdAt: -1 })

# 创建复合索引（遵循ESR法则：Equality, Sort, Range）
db.products.createIndex({ 
  category: 1,
  createdAt: -1,
  price: 1
})

# 创建文本索引用于搜索
db.products.createIndex({ name: "text", tags: "text" })

# 验证索引创建
db.products.getIndexes()
# 预期结果: 显示所有已创建的索引

# 7. 验证索引优化效果
# 重新执行之前的慢查询，观察性能提升
db.products.find({ 
  category: "electronics", 
  price: { $gte: 500 }, 
  rating: { $gte: 4 }
}).sort({ createdAt: -1 }).explain("executionStats")
# 预期结果: 应该显示 "IXSCAN"（索引扫描），执行时间显著减少

# 比较优化前后的查询性能
var startTime = new Date();
db.products.find({ category: "electronics", price: { $gte: 500 } }).toArray();
var endTime = new Date();
print("查询执行时间: " + (endTime - startTime) + "ms");
# 预期结果: 执行时间应该显著减少

# 8. 使用监控工具进行性能监控
# 在终端中使用 mongostat 监控实时性能
# mongostat --host localhost:27017
# 预期结果: 显示实时的操作统计、内存使用、网络流量等

# 使用 mongotop 监控集合级别的读写活动
# mongotop 10
# 预期结果: 每10秒显示各集合的读写时间统计

# 9. 服务器状态监控
# 获取详细的服务器状态信息
db.serverStatus()
# 预期结果: 返回包含操作计数器、锁信息、内存使用、网络统计等的详细报告

# 监控特定的性能指标
db.serverStatus().opcounters
# 预期结果: 显示各种操作（insert、query、update等）的计数

db.serverStatus().wiredTiger.cache
# 预期结果: 显示WiredTiger缓存的使用情况

db.serverStatus().locks
# 预期结果: 显示锁的使用统计

# 10. 索引使用情况分析
# 查看索引使用统计
db.products.aggregate([
  { $indexStats: {} }
])
# 预期结果: 显示每个索引的使用次数和访问模式

# 识别未使用的索引
db.products.aggregate([
  { $indexStats: {} },
  { $match: { "accesses.ops": 0 } }
])
# 预期结果: 显示从未被使用的索引（可考虑删除）

# 11. 查询优化最佳实践验证
# 使用投影减少网络传输
var startTime = new Date();
db.products.find(
  { category: "electronics" }, 
  { name: 1, price: 1, _id: 0 }  # 只返回需要的字段
).toArray();
var endTime = new Date();
print("投影查询执行时间: " + (endTime - startTime) + "ms");

# 对比不使用投影的查询时间
var startTime = new Date();
db.products.find({ category: "electronics" }).toArray();
var endTime = new Date();
print("完整文档查询执行时间: " + (endTime - startTime) + "ms");
# 预期结果: 使用投影的查询应该更快

# 12. 清理和总结
# 关闭profiling
db.setProfilingLevel(0)

# 查看profiling总结
db.system.profile.aggregate([
  {
    $group: {
      _id: "$command.find",
      avgDuration: { $avg: "$millis" },
      maxDuration: { $max: "$millis" },
      count: { $sum: 1 }
    }
  },
  { $sort: { avgDuration: -1 } }
])
# 预期结果: 显示各集合查询的平均执行时间统计
```