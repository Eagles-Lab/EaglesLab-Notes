# 分片（Sharding）

当数据量增长到单个副本集无法承载，或者写操作的吞吐量达到单台主节点的极限时，就需要通过分片（Sharding）来进行水平扩展。本章节将深入探讨 MongoDB 分片集群的架构、核心组件、分片键的选择策略以及如何部署和管理一个分片集群。

---

## 分片概述

### 什么是分片？

分片是一种将大型数据集水平分区到多个服务器（或分片）上的数据库架构模式。每个分片都是一个独立的副本集，存储着整个数据集的一部分。通过分片，MongoDB 可以将读写负载分布到多个服务器上，从而实现近乎无限的水平扩展能力。

### 为什么需要分片？

1.  **存储容量扩展**: 当数据量超过单台服务器的磁盘容量时，可以通过增加分片来扩展存储空间。
2.  **读写吞吐量提升**: 通过将负载分布到多个分片，可以显著提高整个集群的读写处理能力。
3.  **高可用性**: 分片集群的每个分片本身就是一个副本集，因此继承了副本集的高可用性特性。

---

## 分片集群架构

一个 MongoDB 分片集群由以下三个核心组件构成：

1.  **分片 (Shard)**
    - **作用**: 存储数据的单元。每个分片都是一个独立的 MongoDB 副本集，以保证其高可用性。
    - **职责**: 存储集合数据的一个子集（Chunk）。

2.  **查询路由 (Query Router / `mongos`)**
    - **作用**: 客户端的入口。`mongos` 是一个轻量级的无状态进程，它接收客户端的请求，并将其路由到正确的分片上。
    - **职责**: 从配置服务器获取元数据，根据分片键将查询路由到目标分片，并聚合来自多个分片的结果返回给客户端。

3.  **配置服务器 (Config Server)**
    - **作用**: 存储集群的元数据。这些元数据包含了数据在各个分片上的分布情况（哪个 Chunk 在哪个 Shard）。
    - **职责**: 管理集群的配置信息。从 MongoDB 3.4 开始，配置服务器必须部署为副本集（CSRS），以保证其高可用性。

![Sharded Cluster Architecture](https://docs.mongodb.com/manual/images/sharded-cluster-production-architecture.bakedsvg.svg)

---

## 分片键（Shard Key）

分片键是决定数据如何在各个分片之间分布的关键。选择一个好的分片键至关重要，它直接影响到分片集群的性能和效率。

### 分片键的选择策略

一个理想的分片键应该具备以下特征：

- **高基数 (High Cardinality)**: 分片键应该有大量可能的值，以便将数据均匀地分布到多个 Chunk 中。
- **低频率 (Low Frequency)**: 分片键的值应该被均匀地访问，避免出现热点数据（Hot Spot）。
- **非单调变化 (Non-Monotonic)**: 分片键的值不应随时间单调递增或递减，这会导致所有的写操作都集中在最后一个分片上。

### 分片策略

1.  **范围分片 (Ranged Sharding)**
    - **描述**: 根据分片键的范围将数据分成不同的块（Chunk）。
    - **优点**: 对于基于范围的查询（如 `find({ x: { $gt: 10, $lt: 20 } })`）非常高效，因为 `mongos` 可以直接将查询路由到存储该范围数据的分片。
    - **缺点**: 如果分片键是单调变化的（如时间戳），容易导致写操作集中在单个分片上。

2.  **哈希分片 (Hashed Sharding)**
    - **描述**: 计算分片键的哈希值，并根据哈希值的范围来分片。
    - **优点**: 能够将数据在各个分片之间均匀分布，保证了写操作的负载均衡。
    - **缺点**: 对于范围查询不友好，因为相邻的分片键值可能被哈希到不同的分片上，导致查询需要广播到所有分片。

3.  **标签感知分片 (Tag Aware Sharding)**
    - **描述**: 允许管理员通过标签（Tag）将特定范围的数据块（Chunk）分配到特定的分片上。例如，可以将美国用户的数据放在位于美国的服务器上，以降低延迟。

---

## Chunks 和 Balancer

### 数据块 (Chunk)

- Chunk 是分片集合中一段连续的数据范围（基于分片键）。MongoDB 会试图保持 Chunk 的大小在一个可配置的范围内（默认为 64MB）。
- 当一个 Chunk 的大小超过配置值时，它会分裂成两个更小的 Chunk。

### 均衡器 (Balancer)

- Balancer 是一个后台进程，它负责在各个分片之间迁移 Chunk，以确保数据在整个集群中均匀分布。
- 当某个分片的 Chunk 数量远多于其他分片时，Balancer 会自动启动，并将一些 Chunk 从最拥挤的分片迁移到最空闲的分片。
- 均衡过程会消耗 I/O 和网络资源，可以在业务高峰期临时禁用 Balancer。

---

## 实践操作

### 需求描述

构建一个完整的 MongoDB 分片集群，模拟电商平台的订单数据存储场景。该场景需要处理大量的订单数据，要求系统具备高可用性和水平扩展能力。通过实际操作来理解分片集群的部署、配置和管理过程。

### 实践细节和结果验证

```shell
# 1. 创建数据目录
mkdir -p /data/mongodb-sharding/{config1,config2,config3,shard1,shard2,mongos}

# 2. 启动配置服务器副本集 (CSRS)
# 启动三个配置服务器实例
mongod --configsvr --replSet configReplSet --port 27019 --dbpath /data/mongodb-sharding/config1 --fork --logpath /data/mongodb-sharding/config1.log
mongod --configsvr --replSet configReplSet --port 27020 --dbpath /data/mongodb-sharding/config2 --fork --logpath /data/mongodb-sharding/config2.log
mongod --configsvr --replSet configReplSet --port 27021 --dbpath /data/mongodb-sharding/config3 --fork --logpath /data/mongodb-sharding/config3.log

# 连接到配置服务器并初始化副本集
mongosh --port 27019
# 在 mongosh shell 中执行：
rs.initiate({
  _id: "configReplSet",
  configsvr: true,
  members: [
    { _id: 0, host: "localhost:27019" },
    { _id: 1, host: "localhost:27020" },
    { _id: 2, host: "localhost:27021" }
  ]
})

# 验证配置服务器状态
rs.status()
# 预期结果：显示三个配置服务器节点，其中一个为 PRIMARY，两个为 SECONDARY

# 3. 启动分片副本集
# 启动第一个分片
mongod --shardsvr --replSet shard1ReplSet --port 27022 --dbpath /data/mongodb-sharding/shard1 --fork --logpath /data/mongodb-sharding/shard1.log

# 启动第二个分片
mongod --shardsvr --replSet shard2ReplSet --port 27023 --dbpath /data/mongodb-sharding/shard2 --fork --logpath /data/mongodb-sharding/shard2.log

# 初始化分片副本集
mongosh --port 27022
# 在 mongosh shell 中执行：
rs.initiate({
  _id: "shard1ReplSet",
  members: [{ _id: 0, host: "localhost:27022" }]
})

mongosh --port 27023
# 在 mongosh shell 中执行：
rs.initiate({
  _id: "shard2ReplSet",
  members: [{ _id: 0, host: "localhost:27023" }]
})

# 4. 启动 mongos 查询路由
mongos --configdb configReplSet/localhost:27019,localhost:27020,localhost:27021 --port 27017 --fork --logpath /data/mongodb-sharding/mongos.log

# 5. 连接到 mongos 并添加分片
mongosh --port 27017
# 在 mongosh shell 中执行：
sh.addShard("shard1ReplSet/localhost:27022")
sh.addShard("shard2ReplSet/localhost:27023")

# 验证分片状态
sh.status()
# 预期结果：显示两个分片已成功添加到集群中

# 6. 为数据库和集合启用分片
# 启用数据库分片
sh.enableSharding("ecommerce")

# 为订单集合创建分片键并启用分片
sh.shardCollection("ecommerce.orders", { "customerId": 1 })
# 为订单集合创建分片键：哈希策略
#  sh.shardCollection("ecommerce.orders", {"customerId": "hashed"})

# 设置新的 chunk 大小（单位：MB）
db.settings.updateOne(
  { _id: "chunksize" },
  { $set: { value: 1 } },
  { upsert: true }
)

# 7. 插入测试数据
use ecommerce
for (let i = 1; i <= 100000; i++) {
  db.orders.insertOne({
    customerId: Math.floor(Math.random() * 1000) + 1,
    orderDate: new Date(2024, Math.floor(Math.random() * 12), Math.floor(Math.random() * 28) + 1),
    amount: Math.random() * 1000,
    products: ["product" + (Math.floor(Math.random() * 100) + 1)]
  })
}

# 8. 等待3min后，观察数据分布和均衡过程
##  partitioned: false 新版本已默认开启，可以忽略
sh.status()
# 预期结果：显示数据已分布到不同的分片上，可以看到 chunks 的分布情况

# 查看集合的分片信息
db.orders.getShardDistribution()
# 预期结果：显示每个分片上的文档数量和数据大小
sh.getShardedDataDistribution()
# 预期结果：显示每个分片上的数据库和集合的分布情况

# 9. 测试分片键查询性能
db.orders.find({customerId: 123}).explain("executionStats")
# 预期结果：查询只会路由到包含该 customerId 数据的特定分片

# 加速迁移
use config
db.settings.update(
  { "_id": "balancer" },
  { $set: 
    { 
    "_waitForDelete": false,
    "_secondaryThrottle": false,
    "writeConcern": { "w": "1" } 
    } 
  },
  { upsert: true }
)
```
