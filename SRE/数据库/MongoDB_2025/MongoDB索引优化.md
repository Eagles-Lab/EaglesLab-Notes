# 索引优化

索引是提升 MongoDB 查询性能的关键。本章节将深入探讨索引的类型、创建策略、如何分析查询性能以及索引的维护方法，帮助大家构建高性能的数据库应用。

---

## 索引基础

### 什么是索引？

索引是一种特殊的数据结构，它以易于遍历的形式存储了集合中一小部分的数据。通过索引，MongoDB 可以直接定位到符合查询条件的文档，而无需扫描整个集合，从而极大地提高了查询速度。

### 索引的类型

MongoDB 支持多种类型的索引，以适应不同的查询需求。

1.  **单字段索引 (Single Field Index)**
    - 最基础的索引类型，针对单个字段创建。
    - 示例: `db.inventory.createIndex({ price: 1 })` (按价格升序)

2.  **复合索引 (Compound Index)**
    - 在多个字段上创建的索引。字段的顺序非常重要，决定了索引的查询效率。
    - 示例: `db.inventory.createIndex({ price: 1, qty: -1 })` (先按价格升序，再按数量降序)

3.  **多键索引 (Multikey Index)**
    - 为数组字段创建的索引。MongoDB 会为数组中的每个元素创建一条索引项。
    - 示例: `db.inventory.createIndex({ tags: 1 })` (为 `tags` 数组中的每个标签创建索引)

4.  **文本索引 (Text Index)**
    - 用于支持对字符串内容的文本搜索查询。
    - 示例: `db.inventory.createIndex({ description: "text" })`

5.  **地理空间索引 (Geospatial Index)**
    - 用于高效地查询地理空间坐标数据。
    - 类型: `2dsphere` (用于球面几何) 和 `2d` (用于平面几何)。
    - 示例: `db.places.createIndex({ location: "2dsphere" })`

6.  **哈希索引 (Hashed Index)**
    - 计算字段值的哈希值并对哈希值建立索引，主要用于哈希分片。
    - 示例: `db.inventory.createIndex({ status: "hashed" })`

---

## 索引策略与创建

### 创建索引

使用 `createIndex()` 方法在集合上创建索引。

```javascript
// 在 students 集合的 email 字段上创建一个唯一的升序索引
db.students.createIndex({ student_id: 1 }, { unique: true })

// 创建一个后台索引，避免阻塞数据库操作
db.students.createIndex({ name: 1 }, { background: true })
```

### 索引属性

- **`unique`**: 强制索引字段的值唯一，拒绝包含重复值的文档插入或更新。
- **`sparse`**: 稀疏索引，只为包含索引字段的文档创建索引项，节省空间。
- **`background`**: 在后台创建索引，允许在创建过程中进行读写操作（但会稍慢）。
- **`expireAfterSeconds`**: TTL (Time-To-Live) 索引，自动从集合中删除超过指定时间的文档。

### 复合索引的字段顺序

复合索引的字段顺序遵循 **ESR (Equality, Sort, Range)** 法则：

1.  **等值查询 (Equality)** 字段应放在最前面。
2.  **排序 (Sort)** 字段其次。
3.  **范围查询 (Range)** 字段（如 `$gt`, `$lt`）应放在最后。

正确的字段顺序可以使一个索引服务于多种查询，提高索引的复用率。

**案例分析**:

假设我们有一个 `products` 集合，需要频繁执行一个查询：查找特定 `category` 的商品，按 `brand` 排序，并筛选出价格 `price` 大于某个值的商品。

**查询语句**:
```javascript
db.products.find(
  { 
    category: "electronics",       // 等值查询 (Equality)
    price: { $gt: 500 }            // 范围查询 (Range)
  }
).sort({ brand: 1 })                 // 排序 (Sort)
```

**根据 ESR 法则创建索引**:

遵循 ESR 法则，我们应该将等值查询字段 `category` 放在最前面，然后是排序字段 `brand`，最后是范围查询字段 `price`。

**最佳索引**:
```javascript
db.products.createIndex({ category: 1, brand: 1, price: 1 })
```

**为什么这个顺序是最高效的？**

1.  **等值查询优先 (`category`)**: MongoDB 可以立即通过索引定位到所有 `category` 为 `"electronics"` 的文档，快速缩小查询范围。
2.  **排序字段次之 (`brand`)**: 在已筛选出的 `"electronics"` 索引条目中，数据已经按 `brand` 排好序。因此，MongoDB 无需在内存中执行额外的排序操作 (`in-memory sort`)，极大地提升了性能。
3.  **范围查询最后 (`price`)**: 在已经按 `brand` 排序的索引条目上，MongoDB 可以顺序扫描，高效地过滤出 `price` 大于 500 的条目。

如果索引顺序不当，例如 `{ price: 1, brand: 1, category: 1 }`，MongoDB 将无法有效利用索引进行排序，可能导致性能下降。

---

## 查询性能分析

### `explain()` 方法

`explain()` 是分析查询性能的利器。它可以显示查询的执行计划，包括是否使用了索引、扫描了多少文档等信息。

```javascript
db.students.find({ age: { $gt: 21 } }).explain("executionStats")
```

### 分析 `explain()` 结果

关注 `executionStats` 中的关键指标：

- **`executionSuccess`**: 查询是否成功执行。
- **`nReturned`**: 查询返回的文档数量。
- **`totalKeysExamined`**: 扫描的索引键数量。
- **`totalDocsExamined`**: 扫描的文档数量。
- **`executionTimeMillis`**: 查询执行时间（毫秒）。
- **`winningPlan.stage`**: 查询计划的阶段。
    - `COLLSCAN`: 全集合扫描，性能最低。
    - `IXSCAN`: 索引扫描，性能较高。
    - `FETCH`: 根据索引指针去获取文档。

**理想情况**: `totalKeysExamined` 和 `totalDocsExamined` 应该尽可能接近 `nReturned`。

### 覆盖查询 (Covered Query)

当查询所需的所有字段都包含在索引中时，MongoDB 可以直接从索引返回结果，而无需访问文档，这称为覆盖查询。覆盖查询性能极高。

**条件**:
1.  查询的所有字段都是索引的一部分。
2.  查询返回的所有字段都在同一个索引中。
3.  查询的字段中不包含 `_id` 字段，或者 `_id` 字段是索引的一部分（默认情况下 `_id` 会被返回，除非显式排除）。

**案例分析**:

假设我们有一个 `students` 集合，并且我们经常需要通过 `student_id` 查找学生的姓名 `name`。

1.  **创建复合索引**:
    为了优化这个查询，我们可以在 `student_id` 和 `name` 字段上创建一个复合索引。

    ```javascript
    db.students.createIndex({ student_id: 1, name: 1 })
    ```

2.  **执行覆盖查询**:
    现在，我们执行一个只查询 `student_id` 并只返回 `name` 字段的查询。我们使用投影 (projection) 来显式排除 `_id` 字段，并只包含 `name` 字段。

    ```javascript
    db.students.find({ student_id: 'S1001' }, { name: 1, _id: 0 })
    ```

3.  **性能验证**:
    使用 `explain()` 方法来查看查询的执行计划。

    ```javascript
    db.students.find({ student_id: 'S1001' }, { name: 1, _id: 0 }).explain('executionStats')
    ```

    在 `executionStats` 的输出中，我们会发现：
    - `totalDocsExamined` 的值为 `0`。这表明 MongoDB 没有扫描任何文档。
    - `totalKeysExamined` 的值大于 `0`，说明扫描了索引。
    - `winningPlan.stage` 会显示为 `IXSCAN`，并且没有 `FETCH` 阶段。

    这个结果证明了该查询是一个覆盖查询。MongoDB 仅通过访问索引就获取了所有需要的数据，完全避免了读取文档的磁盘 I/O 操作，从而实现了极高的查询性能。

---

## 索引维护

### 查看索引

使用 `getIndexes()` 方法查看集合上的所有索引。

```javascript
db.students.getIndexes()
```

### 删除索引

使用 `dropIndex()` 方法删除指定的索引。

```javascript
// 按名称删除索引
db.students.dropIndex("email_1")

// 按键模式删除索引
db.students.dropIndex({ last_login: -1 })
```

### 索引大小和使用情况

使用 `$indexStats` 聚合阶段可以查看索引的大小和使用情况（自上次重启以来的操作次数）。

```javascript
db.students.aggregate([{ $indexStats: {} }])
```

---

## 实践操作

在本节中，我们将使用 `products_for_indexing` 集合进行实践，数据已在 `data.js` 中定义。

### 需求描述

假设我们有一个电商平台的 `products02` 集合，需要支持以下查询场景：
1.  频繁按商品类别 (`category`) 查找商品，并按价格 (`price`) 排序。
2.  需要快速获取特定类别和品牌的商品信息，且只关心品牌和价格。

### 实践细节和结果验证

```javascript
// 准备工作：确保 products_for_indexing 集合存在且包含数据
// (数据已在 data.js 中定义，请先加载)

// 1. 创建复合索引以优化排序查询
// 需求：按类别查找并按价格排序
db.products_for_indexing.createIndex({ category: 1, price: 1 });

// 2. 使用 explain() 分析查询性能

// -- 无索引查询 (模拟，假设索引未创建) --
// db.products_for_indexing.find({ category: 'Electronics' }).sort({ price: -1 }).explain('executionStats');
// 结果会显示 COLLSCAN (全表扫描)，效率低

// -- 有索引查询 --
db.products_for_indexing.find({ category: 'Electronics' }).sort({ price: -1 }).explain('executionStats');
// **结果验证**: 
// winningPlan.stage 应为 IXSCAN (索引扫描)，表明使用了索引。
// totalDocsExamined 数量远小于集合总数，性能高。

// 3. 构造并验证覆盖查询
// 需求：只查询电子产品的品牌和价格

// -- 创建一个能覆盖查询的索引 --
db.products_for_indexing.createIndex({ category: 1, brand: 1, price: 1 });

// -- 执行覆盖查询 --
db.products_for_indexing.find(
  { category: 'Electronics', brand: 'Sony' },
  { brand: 1, price: 1, _id: 0 }
).explain('executionStats');
// **结果验证**:
// totalDocsExamined 应为 0，表明没有读取文档。
// winningPlan.stage 为 IXSCAN，且没有 FETCH 阶段，证明是高效的覆盖查询。

// 4. 索引维护

// -- 查看当前集合上的所有索引 --
db.products_for_indexing.getIndexes();

// -- 删除一个不再需要的索引 --
// 假设 { category: 1, price: 1 } 这个索引不再需要
db.products_for_indexing.dropIndex('category_1_price_1');

// -- 再次查看索引，确认已删除 --
db.products_for_indexing.getIndexes();
```
