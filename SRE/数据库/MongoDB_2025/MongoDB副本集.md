# 副本集（Replica Set）

为了提供高可用性和数据冗余，MongoDB 使用副本集（Replica Set）的机制。本章节将详细介绍副本集的概念、架构、工作原理以及如何配置和管理一个副本集，确保数据库服务能够抵御单点故障。

---

## 副本集概述

### 什么是副本集？

副本集是一组维护相同数据集的 `mongod` 进程。它由一个**主节点 (Primary)** 和多个**从节点 (Secondary)** 组成，共同保证了数据的冗余和高可用性。

- **主节点 (Primary)**: 接收所有的写操作。一个副本集在任何时候最多只能有一个主节点。
- **从节点 (Secondary)**: 从主节点异步复制数据。从节点可以接受读操作，从而分担主节点的读负载。

### 副本集的目标

1.  **数据冗余 (Data Redundancy)**: 数据在多个服务器上有副本，防止因单台服务器硬件故障导致的数据丢失。
2.  **高可用性 (High Availability)**: 当主节点发生故障时，副本集会自动进行故障转移（Failover），从剩下的从节点中选举出一个新的主节点，从而保证服务的持续可用。
3.  **读写分离 (Read Scaling)**: 客户端可以将读请求路由到从节点，从而分散读负载，提高读取性能。

---

## 副本集架构与工作原理

### 副本集成员

一个典型的副本集包含以下成员：

- **主节点 (Primary)**: 唯一的写操作入口。
- **从节点 (Secondary)**: 复制主节点的数据，可以处理读请求。从节点也可以被配置为：
  - **优先级为 0 的成员 (Priority 0 Member)**: 不能被选举为主节点，适合用于备份或离线分析。
  - **隐藏成员 (Hidden Member)**: 对客户端不可见，不能处理读请求，通常用于备份。
  - **延迟成员 (Delayed Member)**: 数据会比主节点延迟一段时间，可用于恢复误操作的数据。
- **仲裁者 (Arbiter)**: 只参与选举投票，不存储数据副本。它的存在是为了在成员数量为偶数时，打破平局，确保能够选举出主节点。

### 数据同步（复制）

- 主节点记录其所有的操作到一个特殊的 capped collection 中，称为 **oplog (operations log)**。
- 从节点持续地从主节点的 oplog 中拉取新的操作，并在自己的数据集上应用这些操作，从而保持与主节点的数据同步。
- 这个过程是异步的，因此从节点的数据可能会有轻微的延迟。

### 选举过程（Failover）

当主节点在一定时间内（默认为 10 秒）无法与副本集中的其他成员通信时，会触发一次选举。

1.  **触发选举**: 从节点发现主节点不可达。
2.  **选举投票**: 剩下的健康成员会进行投票，选举一个新的主节点。投票的依据包括成员的优先级、oplog 的新旧程度等。
3.  **产生新的主节点**: 获得大多数票数（`(N/2) + 1`，其中 N 是副本集总成员数）的从节点会成为新的主节点。
4.  **恢复同步**: 旧的主节点恢复后，会作为从节点重新加入副本集。

---

## 读写关注点（Read and Write Concern）

### 写关注点 (Write Concern)

写关注点决定了写操作在向客户端确认成功之前，需要被多少个副本集成员确认。

- **`w: 1` (默认)**: 写操作只需在主节点成功即可返回。
- **`w: "majority"`**: 写操作需要被大多数（`(N/2) + 1`）数据承载成员确认后才返回。这是推荐的设置，可以防止在故障转移期间发生数据回滚。
- **`j: true`**: 要求写操作在返回前写入到磁盘日志（journal）。

### 读偏好 (Read Preference)

读偏好决定了客户端从哪个成员读取数据。

- **`primary` (默认)**: 只从主节点读取，保证数据最新。
- **`primaryPreferred`**: 优先从主节点读取，如果主节点不可用，则从从节点读取。
- **`secondary`**: 只从从节点读取，可以分担主节点负载，但可能读到稍有延迟的数据。
- **`secondaryPreferred`**: 优先从从节点读取，如果没有可用的从节点，则从主节点读取。
- **`nearest`**: 从网络延迟最低的成员读取，不关心是主节点还是从节点。

---

## 实践操作

### 需求描述

某电商公司的 MongoDB 数据库需要实现高可用性架构，要求：
1. 数据库服务 24/7 不间断运行
2. 单节点故障时自动故障转移
3. 支持读写分离以提升性能
4. 数据冗余备份防止数据丢失

我们需要搭建一个三成员副本集来满足这些需求，并验证其高可用性和读写分离功能。

### 实践细节和结果验证

```shell
# 1. 创建数据目录
mkdir -p /data/rs{1,2,3}

# 2. 启动三个 mongod 实例
# 实例 1 (Primary 候选)
mongod --port 27027 --dbpath /data/rs1 --replSet myReplicaSet --fork --logpath /var/log/mongodb/rs1.log

# 实例 2 (Secondary 候选)
mongod --port 27028 --dbpath /data/rs2 --replSet myReplicaSet --fork --logpath /var/log/mongodb/rs2.log

# 实例 3 (Secondary 候选)
mongod --port 27029 --dbpath /data/rs3 --replSet myReplicaSet --fork --logpath /var/log/mongodb/rs3.log

# 3. 连接到第一个实例并初始化副本集
mongosh --port 27027

# 在 mongo shell 中执行以下命令
# 初始化副本集配置
config = {
  _id: "myReplicaSet",
  members: [
    { _id: 0, host: "localhost:27027", priority: 2 },
    { _id: 1, host: "localhost:27028", priority: 1 },
    { _id: 2, host: "localhost:27029", priority: 1 }
  ]
}

# 执行初始化
rs.initiate(config)

# 等待几秒后验证副本集状态
rs.status()

# 预期结果：显示一个 PRIMARY 节点和两个 SECONDARY 节点

# 4. 测试写操作（在主节点执行）
use testDB
db.products.insertOne({name: "iPhone 14", price: 999, stock: 100})
db.products.insertOne({name: "MacBook Pro", price: 2499, stock: 50})

# 验证写入成功
db.products.find()
# 预期结果：显示刚插入的两条记录

# 5. 测试读写分离
# 连接到副本集不设置读偏好，默认从主节点读取
mongosh "mongodb://localhost:27027,localhost:27028,localhost:27029/?replicaSet=myReplicaSet"
# 数据来源一直为 27027
use testDB
myReplicaSet [primary] test> db.products.find().explain().serverInfo

# 连接到副本集并设置读偏好为从节点
mongosh "mongodb://localhost:27027,localhost:27028,localhost:27029/?replicaSet=myReplicaSet&readPreference=secondary"
# readPreference 仅控制查询路由，不改变连接目标，但数据来源为 27028/27029
use testDB
db.products.find().explain().serverInfo

# 6. 模拟故障转移测试
# 在另一个终端中找到主节点进程并停止
ps aux | grep "mongod.*27027"
kill <主节点进程ID>

# 回到 mongo shell 观察选举过程
rs.status()
# 等待 10-30 秒后再次检查
rs.status()

# 预期结果：原来的一个从节点变成新的主节点
# 例如 localhost:27028 变成 PRIMARY 状态

# 7. 验证故障转移后的读写功能
# 在新主节点上执行写操作
mongosh --port 27028
use testDB
db.products.insertOne({name: "iPad Air", price: 599, stock: 75})

# 验证数据写入成功
db.products.find()
# 预期结果：显示包括新插入记录在内的所有数据

# 8. 恢复故障节点
# 重新启动之前停止的节点
mongod --port 27027 --dbpath /data/rs1 --replSet myReplicaSet --fork --logpath /var/log/mongodb/rs1.log

# 验证节点重新加入副本集
rs.status()
# 预期结果：localhost:27027 重新出现在成员列表中，状态为 SECONDARY，因为 27027 节点优先级配置更高，会主动出发选举并抢占主节点角色，这是MongoDB副本集设计的​​正常行为​​

# 9. 验证数据同步
# 连接到恢复的节点
mongosh --port 27027
use testDB
db.getMongo().setReadPref("secondary")
db.products.find()
# 预期结果：显示所有数据，包括故障期间插入的记录，证明数据同步正常

# [扩展] 10. 性能测试 - 验证读写分离效果
```