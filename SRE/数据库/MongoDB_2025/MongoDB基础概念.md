# 基础概念

本章节将介绍 NoSQL 数据库的基本概念，并深入探讨 MongoDB 的核心概念、架构原理，为后续的学习打下坚实的基础。

---

## NoSQL 数据库概述

NoSQL（Not Only SQL）泛指非关系型数据库，它们在数据结构、可扩展性和事务模型上与传统的关系型数据库（如 MySQL）有显著不同。

### 关系型数据库 vs NoSQL 数据库

| 特性 | 关系型数据库 (RDBMS) | NoSQL 数据库 |
| :--- | :--- | :--- |
| **数据模型** | 基于表（Table）和行（Row）的结构化数据 | 多样化模型（文档、键值、列族、图） |
| **Schema** | 固定（Schema-on-Write），需预先定义表结构 | 动态（Schema-on-Read），数据结构灵活 |
| **扩展性** | 主要通过垂直扩展（Scale-Up）提升单机性能 | 主要通过水平扩展（Scale-Out）构建分布式集群 |
| **事务** | 遵循 ACID 原则，保证强一致性 | 通常遵循 BASE 原则，保证最终一致性 |
| **适用场景** | 事务性要求高、数据结构稳定的应用 | 大数据、高并发、需要快速迭代的应用 |

### NoSQL 数据库分类

NoSQL 数据库根据其数据模型的不同，主要分为以下几类：

1.  **文档型数据库 (Document-Oriented)**
    - **特点**：以文档（通常是 JSON 或 BSON 格式）为单位存储数据，结构灵活。
    - **代表**：MongoDB, CouchDB

2.  **键值型数据库 (Key-Value)**
    - **特点**：数据以简单的键值对形式存储，查询速度快。
    - **代表**：Redis, Memcached

3.  **列族型数据库 (Column-Family)**
    - **特点**：数据按列族存储，适合大规模数据聚合分析。
    - **代表**：Cassandra, HBase

4.  **图形型数据库 (Graph)**
    - **特点**：专注于节点和边的关系，适合社交网络、推荐系统等场景。
    - **代表**：Neo4j, ArangoDB

### MongoDB 在 NoSQL 生态中的定位

MongoDB 是文档型数据库的杰出代表，它凭借其灵活的数据模型、强大的查询语言和高可扩展性，在 NoSQL 生态中占据了重要地位。它特别适用于需要快速开发、数据结构多变、高并发读写的应用场景。

---

## 核心概念

理解 MongoDB 的核心概念是掌握其使用的第一步。

### 文档（Document）与 BSON 格式

- **文档 (Document)**：是 MongoDB 中数据的基本单元，由一组键值对（key-value）组成，类似于 JSON 对象。文档的结构是动态的，同一个集合中的文档可以有不同的字段。

  ```json
  {
    "_id": ObjectId("60c72b2f9b1d8b3b8c8b4567"),
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com",
    "tags": ["mongodb", "database", "nosql"]
  }
  ```

- **BSON (Binary JSON)**：MongoDB 在内部使用 BSON 格式存储文档。BSON 是 JSON 的二进制表示形式，它支持更多的数据类型（如日期、二进制数据），并优化了存储空间和查询性能。

### 集合（Collection）概念

- **集合 (Collection)**：是 MongoDB 文档的容器，可以看作是关系型数据库中的表（Table）。但与表不同，集合不需要预先定义结构（schema-less）。

### 数据库（Database）结构

- **数据库 (Database)**：是集合的物理容器。一个 MongoDB 实例可以承载多个数据库，每个数据库都有自己独立的权限和文件。

### MongoDB 与关系型数据库术语对比

| MongoDB | 关系型数据库 (RDBMS) |
| :--- | :--- |
| Database | Database |
| Collection | Table |
| Document | Row (or Record) |
| Field | Column (or Attribute) |
| Index | Index |
| Replica Set | Master-Slave Replication |
| Sharding | Partitioning |

---

## 架构原理

了解 MongoDB 的底层架构有助于我们更好地进行性能调优和故障排查。

### 存储引擎（WiredTiger）

WiredTiger 是 MongoDB 默认的存储引擎，它提供了文档级别的并发控制、数据压缩和快照等高级功能，是 MongoDB 高性能的关键。

### 内存映射文件系统

MongoDB 使用内存映射文件（Memory-Mapped Files）来处理数据。它将磁盘上的数据文件映射到内存中，使得 MongoDB 可以像访问内存一样访问数据，从而将数据管理委托给操作系统的虚拟内存管理器，简化了代码并提升了性能。

### 索引机制

为了提高查询效率，MongoDB 支持在任意字段上创建索引。与关系型数据库类似，MongoDB 的索引也采用 B-Tree 数据结构，能够极大地加速数据检索过程。

### 查询优化器

MongoDB 内置了一个查询优化器，它会分析查询请求，并从多个可能的查询计划中选择一个最优的执行计划，以确保查询的高效性。

---

## 文档学习

- 阅读 MongoDB 官方文档中关于“核心概念”的部分。