# MongoDB 备份与恢复

制定可靠的备份和恢复策略是数据库管理中至关重要的一环，它可以帮助在发生数据损坏、误操作或灾难性故障时恢复数据。本章节将介绍 MongoDB 常用的备份方法、恢复流程以及灾难恢复的最佳实践。

---

## 备份策略

选择哪种备份方法取决于具体需求，如恢复时间目标 (RTO)、恢复点目标 (RPO)、数据库规模以及部署架构（独立实例、副本集、分片集群）。

### 备份方法

1.  **`mongodump` 和 `mongorestore`**
    - **描述**: MongoDB 提供的官方命令行工具，用于创建数据库的 BSON 文件备份，并可以从这些文件恢复数据。
    - **优点**: 简单易用，适合小型数据集或对备份窗口要求不高的场景。
    - **缺点**: 备份期间可能会影响数据库性能。对于大型数据集，备份和恢复过程可能非常耗时。在恢复 `mongodump` 的备份时，它会重建索引，这会增加恢复时间。

2.  **文件系统快照 (Filesystem Snapshots)**
    - **描述**: 利用文件系统（如 LVM）或云存储（如 AWS EBS）的快照功能，对 MongoDB 的数据文件进行即时备份。
    - **优点**: 备份速度快，对数据库性能影响小。恢复速度也很快，因为数据和索引都无需重建。
    - **缺点**: 必须确保在创建快照时，数据处于一致性状态。这通常需要开启 journaling 并确保在快照前执行 `fsync` 和 lock 操作。

3.  **MongoDB Cloud Manager / Ops Manager**
    - **描述**: MongoDB 提供的企业级管理工具，提供持续的、时间点恢复的备份服务。
    - **优点**: 提供图形化界面，管理方便。支持副本集和分片集群的持续备份和时间点恢复，可以恢复到任意时刻。
    - **缺点**: 是商业服务，需要额外成本。

---

## 使用 `mongodump` 和 `mongorestore`

### `mongodump`

`mongodump` 可以导出整个数据库、特定数据库或特定集合。

```shell
# 备份整个 MongoDB 实例
mongodump --out /data/backup/`date +%F`

# 备份指定的数据库
mongodump --db myAppDB --out /data/backup/myAppDB

# 备份指定的集合
mongodump --db myAppDB --collection users --out /data/backup/users_collection

# 备份远程数据库并启用压缩
mongodump --host mongodb.example.com --port 27017 --username myUser --password myPass --authenticationDatabase admin --db myAppDB --gzip --out /data/backup/myAppDB.gz
```

### `mongorestore`

`mongorestore` 用于将 `mongodump` 创建的备份恢复到数据库中。

```shell
# 恢复整个实例的备份
mongorestore /data/backup/2023-10-27/

# 恢复指定的数据库备份
# mongorestore 会将数据恢复到备份时同名的数据库中
mongorestore --db myAppDB /data/backup/myAppDB/

# 恢复并删除现有数据
# 使用 --drop 选项可以在恢复前删除目标集合
mongorestore --db myAppDB --collection users --drop /data/backup/users_collection/users.bson
```

---

## 副本集和分片集群的备份

### 备份副本集

- **使用 `mongodump`**: 建议连接到一个从节点进行备份，以减少对主节点的影响。可以使用 `--oplog` 选项来创建一个包含 oplog 条目的时间点快照，这对于在恢复后与其他副本集成员同步非常重要。

  ```bash
  mongodump --host secondary.example.com --oplog --out /data/backup/repl_set_backup
  ```

- **使用文件系统快照**: 可以在一个被停止（或锁定）的从节点上进行，以保证数据一致性。

### 备份分片集群

备份分片集群要复杂得多，因为必须保证整个集群的数据是一致的。

- **核心挑战**: 必须在同一时刻捕获所有分片和配置服务器的数据快照。
- **推荐方法**: **强烈建议使用 MongoDB Cloud Manager 或 Ops Manager** 来处理分片集群的备份，因为它们专门设计用于处理这种复杂性。
- **手动备份（不推荐，风险高）**:
  1.  禁用 Balancer。
  2.  对配置服务器进行 `mongodump`。
  3.  对每个分片副本集进行 `mongodump`。
  4.  重新启用 Balancer。
  恢复过程同样复杂且容易出错。

---

## 恢复策略与灾难恢复

### 恢复误操作的数据

- **使用延迟从节点**: 如果配置了一个延迟从节点，可以停止它的复制，从其数据文件中恢复误删或误改的数据。
- **使用时间点恢复**: 如果使用 Cloud Manager / Ops Manager，可以将数据库恢复到误操作发生前的任意时间点。

### 灾难恢复 (Disaster Recovery)

灾难恢复计划旨在应对整个数据中心或区域级别的故障。

- **异地备份**: 将备份数据存储在与生产数据中心物理位置不同的地方。
- **多数据中心部署**: 将副本集的成员分布在不同的地理位置。例如，一个主节点和从节点在主数据中心，另一个从节点在灾备数据中心。当主数据中心发生故障时，可以手动或自动将灾备中心的从节点提升为新的主节点。

---

## 实践操作

### 需求描述

构建一个完整的 MongoDB 备份与恢复实践环境，掌握不同场景下的备份策略和恢复操作。通过实际操作理解备份工具的使用方法、副本集备份的最佳实践，以及制定符合业务需求的备份恢复策略。

### 实践细节和结果验证

```shell
# 1. 准备测试数据
# 创建测试数据库和集合
use myAppDB
db.users.insertMany([
  {name: "Alice", age: 25, email: "alice@example.com"},
  {name: "Bob", age: 30, email: "bob@example.com"},
  {name: "Charlie", age: 35, email: "charlie@example.com"}
])

db.orders.insertMany([
  {orderId: "ORD001", userId: "Alice", amount: 100.50, status: "completed"},
  {orderId: "ORD002", userId: "Bob", amount: 250.75, status: "pending"},
  {orderId: "ORD003", userId: "Charlie", amount: 89.99, status: "completed"}
])

# 验证数据插入
db.users.countDocuments()  # 预期结果: 3
db.orders.countDocuments() # 预期结果: 3

# 2. 使用 mongodump 备份数据库
# 创建备份目录
mkdir -pv /data/mongodb/backup

# 备份整个 myAppDB 数据库
mongodump --db myAppDB --out /data/mongodb/backup/$(date +%F)/dbs/

# 验证备份文件
ls -la /data/mongodb/backup/$(date +%F)/dbs/
# 预期结果: 应该看到 users.bson, users.metadata.json, orders.bson, orders.metadata.json 等文件

# 备份指定集合（带压缩）
mongodump --db myAppDB --collection users --gzip --out /data/mongodb/backup/$(date +%F)/collections/

# 验证压缩备份
ls -la /data/mongodb/backup/$(date +%F)/users_backup/myAppDB/
# 预期结果: 应该看到 users.bson.gz 和 users.metadata.json.gz 文件

# 3. 模拟数据丢失并恢复
# 删除 users 集合模拟数据丢失
use myAppDB
db.users.drop()

# 验证数据已删除
db.users.countDocuments()  # 预期结果: 0
show collections             # 预期结果: 只显示 orders 集合

# 使用 mongorestore 恢复 users 集合
gzip /data/mongodb/backup/$(date +%F)/collections/myAppDB/users.bson.gz -d /data/mongodb/backup/$(date +%F)/collections/myAppDB/
mongorestore --db myAppDB --collection users /data/mongodb/backup/$(date +%F)/collections/myAppDB/users.bson

# 验证数据恢复
db.users.countDocuments()  # 预期结果: 3
db.users.find().pretty()    # 预期结果: 显示所有用户数据

# 4. 完整数据库恢复测试
# 删除整个数据库
use myAppDB
db.dropDatabase()

# 验证数据库已删除
show dbs  # 预期结果: myAppDB 不在列表中

# 恢复整个数据库
mongorestore /data/mongodb/backup/$(date +%F)/dbs/myAppDB/

# 验证数据库恢复
use myAppDB
show collections             # 预期结果: 显示 users 和 orders 集合
db.users.countDocuments()    # 预期结果: 3
db.orders.countDocuments()   # 预期结果: 3

# 5. 副本集备份实践（如果已配置副本集）
# 连接到副本集的从节点进行备份
mongodump --host secondary.example.com:27017 --oplog --out /data/backup/replica_backup

# 验证副本集备份
ls -la /data/backup/replica_backup/
# 预期结果: 应该看到各个数据库目录和 oplog.bson 文件

# 6.[扩展] 制定生产环境备份策略
# 电商订单数据库备份策略设计

# 业务需求分析:
# - RTO (恢复时间目标): 4小时
# - RPO (恢复点目标): 1小时
# - 数据重要性: 订单数据极其重要，用户数据重要
# - 业务特点: 24/7运行，高并发读写

# 推荐备份策略:
# 1. 每日全量备份 (使用文件系统快照)
# 2. 每小时增量备份 (使用 oplog)
# 3. 异地备份存储
# 4. 副本集跨数据中心部署

```