# 数据建模

与关系型数据库不同，MongoDB 灵活的文档模型为数据建模提供了更多的选择。本章节将介绍 MongoDB 数据建模的核心思想、常见模式以及如何根据应用需求选择合适的模型，以实现最佳的性能和可扩展性。

---

## 数据建模核心思想

### 嵌入（Embedding） vs. 引用（Referencing）

这是 MongoDB 数据建模中最核心的决策点。

- **嵌入 (Embedding / Denormalization)**
  - **描述**: 将相关的数据直接嵌入到主文档中，形成一个嵌套的文档结构。
  - **优点**:
    - **性能好**: 只需一次数据库查询即可获取所有相关数据，减少了读操作的次数。
    - **数据原子性**: 对单个文档的更新是原子操作。
  - **缺点**:
    - **文档体积大**: 可能导致文档超过 16MB 的大小限制。
    - **数据冗余**: 如果嵌入的数据在多处被使用，更新时需要修改所有包含它的文档。
  - **适用场景**: “一对一”或“一对多”关系，且“多”的一方数据不经常变动，或者总是和“一”的一方一起被查询。

- **引用 (Referencing / Normalization)**
  - **描述**: 将数据存储在不同的集合中，通过在文档中存储对另一个文档的引用（通常是 `_id`）来建立关系。
  - **优点**:
    - **数据一致性**: 更新数据时只需修改一处。
    - **文档体积小**: 避免了数据冗余。
  - **缺点**:
    - **查询性能较低**: 需要多次查询（或使用 `$lookup`）来获取关联数据。
  - **适用场景**: “多对多”关系，或者“一对多”关系中“多”的一方数据量巨大、经常变动或经常被独立查询。

### 决策依据

选择嵌入还是引用，主要取决于应用的**数据访问模式**：

- **读多写少**: 优先考虑嵌入，优化读取性能。
- **写操作频繁**: 优先考虑引用，避免更新大量冗余数据。
- **数据一致性要求高**: 优先考虑引用。
- **数据关联性强，总是一起访问**: 优先考虑嵌入。

---

## 常见数据建模模式

MongoDB 社区总结了一些行之有效的数据建模模式，可以作为设计的参考。

### 属性模式 (Attribute Pattern)

- **问题**: 当文档有大量字段，但大部分查询只关心其中一小部分时。
- **解决方案**: 将不常用或具有相似特征的字段分组到一个子文档中。
- **示例**: 一个产品文档，将详细规格参数放到 `specs` 子文档中。

  ```json
  {
    "product_id": "123",
    "name": "Laptop",
    "specs": {
      "cpu": "Intel i7",
      "ram_gb": 16,
      "storage_gb": 512
    }
  }
  ```

### 扩展引用模式 (Extended Reference Pattern)

- **问题**: 在引用模型中，为了获取被引用文档的某个常用字段，需要执行额外的查询。
- **解决方案**: 在引用文档中，除了存储 `_id` 外，还冗余存储一些经常需要一起显示的字段。
- **示例**: 在文章（`posts`）集合中，除了存储作者的 `author_id`，还冗余存储 `author_name`。

  ```json
  // posts collection
  {
    "title": "My First Post",
    "author_id": "xyz",
    "author_name": "John Doe" // Extended Reference
  }
  ```

### 子集模式 (Subset Pattern)

- **问题**: 一个文档中有一个巨大的数组（如评论、日志），导致文档过大，且大部分时间只需要访问数组的最新一部分。
- **解决方案**: 将数组的一个子集（如最新的 10 条评论）与主文档存储在一起，完整的数组存储在另一个集合中。
- **示例**: 产品文档中存储最新的 5 条评论，所有评论存储在 `reviews` 集合。

  ```json
  // products collection
  {
    "product_id": "abc",
    "name": "Super Widget",
    "reviews_subset": [
      { "review_id": 1, "text": "Great!" },
      { "review_id": 2, "text": "Awesome!" }
    ]
  }
  ```

### 计算模式 (Computed Pattern)

- **问题**: 需要频繁计算某些值（如总数、平均值），每次读取时计算会消耗大量资源。
- **解决方案**: 在写操作时预先计算好这些值，并将其存储在文档中。当数据更新时，同步更新计算结果。
- **示例**: 在用户文档中存储其发布的帖子总数 `post_count`。

  ```json
  {
    "user_id": "user123",
    "name": "Jane Doe",
    "post_count": 42 // Computed value
  }
  ```

---

## Schema 验证

虽然 MongoDB 是 schema-less 的，但在应用层面保持数据结构的一致性非常重要。从 MongoDB 3.2 开始，引入了 Schema 验证功能。

- **作用**: 可以在集合级别定义文档必须满足的结构规则（如字段类型、必需字段、范围等）。
- **好处**: 确保写入数据库的数据符合预期格式，提高数据质量。

```javascript
db.createCollection("students", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "major", "gpa"],
      properties: {
        name: {
          bsonType: "string",
          description: "must be a string and is required"
        },
        gpa: {
          bsonType: ["double"],
          minimum: 0,
          maximum: 4.0,
          description: "must be a double in [0, 4] and is required"
        }
      }
    }
  }
})
```

---

## 实践环节

### 需求描述

为一个博客系统设计数据模型，包含以下实体：`用户 (User)`、`文章 (Post)`、`评论 (Comment)` 和 `标签 (Tag)`。

1.  **关系分析**: 分析这些实体之间的关系（一对一、一对多、多对多）。
2.  **模型设计**: 讨论并设计至少两种不同的数据模型方案（例如，一种偏向嵌入，一种偏向引用）。
3.  **优劣对比**: 对比不同方案的优缺点，并说明它们分别适用于哪些场景。
4.  **Schema 定义**: 选择的最佳方案中的 `posts` 集合编写一个 Schema 验证规则。

### 实践细节和结果验证

```javascript
// 1. 关系分析与模型设计

// 方案一：偏向嵌入式（适合读多写少的场景）
// users 集合示例文档
db.users.insertOne({
  "_id": ObjectId(),
  "username": "john_doe",
  "email": "john@example.com",
  "posts": [{
    "_id": ObjectId(),
    "title": "MongoDB 入门",
    "content": "MongoDB 是一个强大的 NoSQL 数据库...",
    "created_at": ISODate("2024-01-15"),
    "tags": ["MongoDB", "Database", "NoSQL"],
    "comments": [{
      "user_id": ObjectId(),
      "username": "alice",
      "content": "写得很好！",
      "created_at": ISODate("2024-01-16")
    }]
  }]
});

// 方案二：偏向引用式（适合写多读少的场景）
// users 集合
db.users.insertOne({
  "_id": ObjectId(),
  "username": "john_doe",
  "email": "john@example.com"
});

// posts 集合
db.posts.insertOne({
  "_id": ObjectId(),
  "author_id": ObjectId(), // 引用 users._id
  "author_name": "john_doe", // 扩展引用
  "title": "MongoDB 入门",
  "content": "MongoDB 是一个强大的 NoSQL 数据库...",
  "created_at": ISODate("2024-01-15"),
  "tags": ["MongoDB", "Database", "NoSQL"]
});

// comments 集合
db.comments.insertOne({
  "_id": ObjectId(),
  "post_id": ObjectId(), // 引用 posts._id
  "user_id": ObjectId(), // 引用 users._id
  "username": "alice", // 扩展引用
  "content": "写得很好！",
  "created_at": ISODate("2024-01-16")
});

// 2. 性能测试

// 方案一：嵌入式查询（一次查询获取所有信息）
db.users.find(
  { "posts.tags": "MongoDB" },
  { "posts.$": 1 }
).explain("executionStats");

// 方案二：引用式查询（需要聚合或多次查询）
db.posts.aggregate([
  { $match: { tags: "MongoDB" } },
  { $lookup: {
      from: "comments",
      localField: "_id",
      foreignField: "post_id",
      as: "comments"
  }}
]).explain("executionStats");

// 3. Schema 验证规则

// 为 posts 集合创建验证规则
db.createCollection("posts", {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["author_id", "author_name", "title", "content", "created_at", "tags"],
      properties: {
        author_id: {
          bsonType: "objectId",
          description: "作者ID，必须是 ObjectId 类型且不能为空"
        },
        author_name: {
          bsonType: "string",
          description: "作者名称，必须是字符串且不能为空"
        },
        title: {
          bsonType: "string",
          minLength: 1,
          maxLength: 100,
          description: "标题长度必须在1-100字符之间"
        },
        content: {
          bsonType: "string",
          minLength: 1,
          description: "内容不能为空"
        },
        created_at: {
          bsonType: "date",
          description: "创建时间，必须是日期类型"
        },
        tags: {
          bsonType: "array",
          minItems: 1,
          uniqueItems: true,
          items: {
            bsonType: "string"
          },
          description: "标签必须是非空字符串数组，且不能重复"
        }
      }
    }
  },
  validationLevel: "strict",
  validationAction: "error"
});

// 4. 验证结果

// 测试有效文档（应该成功）
db.posts.insertOne({
  author_id: ObjectId(),
  author_name: "john_doe",
  title: "测试文章",
  content: "这是一篇测试文章",
  created_at: new Date(),
  tags: ["测试", "MongoDB"]
});

// 测试无效文档（应该失败）
db.posts.insertOne({
  author_name: "john_doe", // 缺少 author_id
  title: "测试文章",
  content: "这是一篇测试文章",
  created_at: new Date(),
  tags: [] // 空标签数组，违反 minItems 规则
});
```