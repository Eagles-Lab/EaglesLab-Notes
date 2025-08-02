# 聚合框架

聚合框架是 MongoDB 提供的一个强大的数据处理工具，它允许对集合中的数据进行一系列的转换和计算，最终得到聚合后的结果。本章节将深入探讨聚合管道、常用的聚合阶段以及如何利用聚合框架进行复杂的数据分析。

---

## 聚合管道（Aggregation Pipeline）

聚合操作的核心是聚合管道。管道由一个或多个**阶段 (Stage)** 组成，每个阶段都会对输入的文档流进行处理，并将结果传递给下一个阶段。

### 聚合管道的语法

聚合操作使用 `aggregate()` 方法，其参数是一个包含所有阶段的数组。

```javascript
db.collection.aggregate([
  { <stage1> },
  { <stage2> },
  ...
])
```

### 聚合管道的优势

- **功能强大**: 支持复杂的数据转换、分组、计算和重塑。
- **性能高效**: 许多操作在数据库服务端以原生代码执行，减少了数据在网络中的传输。
- **灵活性高**: 可以通过组合不同的阶段来满足各种复杂的数据处理需求。

---

## 常用聚合阶段

以下是一些最常用的聚合阶段，通过组合它们可以实现强大的数据处理能力。

### `$match`

- **功能**: 过滤文档，只将满足条件的文档传递给下一个阶段。类似于 `find()` 方法的查询条件。
- **建议**: 尽可能将 `$match` 放在管道的开头，以尽早减少需要处理的文档数量，提高效率。
- **示例**: 筛选出状态为 "A" 的订单。

  ```javascript
  { $match: { status: "A" } }
  ```

### `$project`

- **功能**: 重塑文档流。可以包含、排除、重命名字段，或者通过表达式计算新字段。
- **示例**: 只保留 `_id`、`name` 字段，并创建一个新的 `bonus` 字段。

  ```javascript
  { $project: { name: 1, bonus: { $multiply: ["$salary", 0.1] } } }
  ```

### `$group`

- **功能**: 按指定的 `_id` 表达式对文档进行分组，并对每个分组应用累加器表达式进行计算。
- **核心**: `_id` 字段定义了分组的键。
- **示例**: 按 `cust_id` 分组，并计算每个客户的订单总金额。

  ```javascript
  {
    $group: {
      _id: "$cust_id",
      totalAmount: { $sum: "$amount" }
    }
  }
  ```

### `$sort`

- **功能**: 对文档流进行排序，与 `find()` 中的 `sort()` 类似。
- **建议**: 如果需要排序，尽量在管道的早期阶段进行，特别是当排序字段有索引时。
- **示例**: 按 `totalAmount` 降序排序。

  ```javascript
  { $sort: { totalAmount: -1 } }
  ```

### `$limit` 和 `$skip`

- **功能**: 分别用于限制和跳过文档数量，实现分页。
- **示例**: 返回排序后的前 5 个结果。

  ```javascript
  { $limit: 5 }
  ```

### `$unwind`

- **功能**: 将文档中的数组字段拆分成多个文档，数组中的每个元素都会生成一个新的文档（与其他字段组合）。
- **示例**: 将 `tags` 数组拆分。

  ```javascript
  // 输入: { _id: 1, item: "A", tags: ["x", "y"] }
  { $unwind: "$tags" }
  // 输出:
  // { _id: 1, item: "A", tags: "x" }
  // { _id: 1, item: "A", tags: "y" }
  ```

### `$lookup`

- **功能**: 实现左外连接（Left Outer Join），将当前集合与另一个集合的文档进行关联。
- **示例**: 将 `orders` 集合与 `inventory` 集合关联起来。

  ```javascript
  {
    $lookup: {
      from: "inventory",
      localField: "item",
      foreignField: "sku",
      as: "inventory_docs"
    }
  }
  ```

---

## 聚合累加器表达式

累加器主要在 `$group` 阶段使用，用于对分组后的数据进行计算。

| 累加器 | 描述 |
| :--- | :--- |
| `$sum` | 计算总和 |
| `$avg` | 计算平均值 |
| `$min` | 获取最小值 |
| `$max` | 获取最大值 |
| `$first` | 获取每个分组的第一条文档的字段值 |
| `$last` | 获取每个分组的最后一条文档的字段值 |
| `$push` | 将字段值添加到一个数组中 |
| `$addToSet` | 将唯一的字段值添加到一个数组中 |

---

## 聚合管道优化

- **尽早过滤**: 将 `$match` 阶段放在管道的最前面。
- **尽早投影**: 使用 `$project` 移除不需要的字段，减少后续阶段的数据处理量。
- **利用索引**: 如果 `$match` 或 `$sort` 阶段的字段有索引，MongoDB 可以利用它来优化性能。
- **避免在分片键上 `$unwind`**: 这可能会导致性能问题。

---

## 实践环节

### 需求描述

假设有一个 `sales` 集合，包含 `product`, `quantity`, `price`, `date` 字段。

1.  **计算总销售额**: 计算每个产品的总销售额（`quantity * price`）。
2.  **查找最畅销产品**: 按销售额降序排列，找出销售额最高的前 5 个产品。
3.  **按月统计销售**: 按月份对所有销售数据进行分组，并计算每月的总销售额和平均订单金额。
4.  **关联查询**: 假设还有一个 `products_for_aggregation` 集合（包含 `name`, `category`），使用 `$lookup` 将销售数据与产品类别关联起来，并按类别统计销售额。
5.  

### 实践细节和结果验证

```javascript
// 准备工作：确保已在 mongo shell 中加载 data.js 文件

// 1. 计算每个产品的总销售额
db.sales.aggregate([
  {
    $group: {
      _id: "$product",
      totalRevenue: { $sum: { $multiply: ["$quantity", "$price"] } }
    }
  }
])
/*
  预期结果:
  [
    { _id: 'Mouse', totalRevenue: 125 },
    { _id: 'Keyboard', totalRevenue: 75 },
    { _id: 'Monitor', totalRevenue: 300 },
    { _id: 'Webcam', totalRevenue: 50 },
    { _id: 'Laptop', totalRevenue: 4700 }
  ]
*/

// 2. 查找最畅销的前 5 个产品（按销售额）
db.sales.aggregate([
  {
    $group: {
      _id: "$product",
      totalRevenue: { $sum: { $multiply: ["$quantity", "$price"] } }
    }
  },
  {
    $sort: { totalRevenue: -1 }
  },
  {
    $limit: 5
  }
])
/*
  预期结果:
  [
    { _id: 'Laptop', totalRevenue: 4700 },
    { _id: 'Monitor', totalRevenue: 300 },
    { _id: 'Mouse', totalRevenue: 125 },
    { _id: 'Keyboard', totalRevenue: 75 },
    { _id: 'Webcam', totalRevenue: 50 }
  ]
*/

// 3. 按月统计销售额
db.sales.aggregate([
  {
    $group: {
      _id: { $month: "$date" }, // 按月份分组
      totalMonthlyRevenue: { $sum: { $multiply: ["$quantity", "$price"] } },
      averageOrderValue: { $avg: { $multiply: ["$quantity", "$price"] } }
    }
  },
  {
    $sort: { _id: 1 } // 按月份升序排序
  }
])
/*
  预期结果:
  [
    { _id: 1, totalMonthlyRevenue: 1325, averageOrderValue: 441.666... },
    { _id: 2, totalMonthlyRevenue: 1675, averageOrderValue: 558.333... },
    { _id: 3, totalMonthlyRevenue: 2250, averageOrderValue: 1125 }
  ]
*/

// 4. 关联查询：按产品类别统计销售额
db.sales.aggregate([
  // 阶段一: 计算每笔销售的销售额
  {
    $project: {
      product: 1,
      revenue: { $multiply: ["$quantity", "$price"] }
    }
  },
  // 阶段二: 关联 products 集合获取类别信息
  {
    $lookup: {
      from: "products_for_aggregation",
      localField: "product",
      foreignField: "name",
      as: "productDetails"
    }
  },
  // 阶段三: 展开 productDetails 数组
  {
    $unwind: "$productDetails"
  },
  // 阶段四: 按类别分组统计总销售额
  {
    $group: {
      _id: "$productDetails.category",
      totalCategoryRevenue: { $sum: "$revenue" }
    }
  }
])
/*
  预期结果:
  [
    { _id: 'Accessories', totalCategoryRevenue: 50 },
    { _id: 'Electronics', totalCategoryRevenue: 5200 }
  ]
*/
```