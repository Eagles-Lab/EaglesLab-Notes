# 查询进阶

本章节将带大家深入了解 MongoDB 强大的查询功能，包括使用查询操作符、投影、排序、分页以及正则表达式查询，可以更精确、更高效地从数据库中检索数据。

---

## 查询操作符

查询操作符是 MongoDB 查询语言的核心，它们可以帮助大家构建更复杂的查询条件。

### 比较操作符

| 操作符 | 描述 | 示例 |
| :--- | :--- | :--- |
| `$eq` | 等于 (Equal) | `db.inventory.find({ qty: { $eq: 20 } })` |
| `$ne` | 不等于 (Not Equal) | `db.inventory.find({ qty: { $ne: 20 } })` |
| `$gt` | 大于 (Greater Than) | `db.inventory.find({ qty: { $gt: 20 } })` |
| `$gte` | 大于等于 (Greater Than or Equal) | `db.inventory.find({ qty: { $gte: 20 } })` |
| `$lt` | 小于 (Less Than) | `db.inventory.find({ qty: { $lt: 20 } })` |
| `$lte` | 小于等于 (Less Than or Equal) | `db.inventory.find({ qty: { $lte: 20 } })` |
| `$in` | 在指定数组内 (In) | `db.inventory.find({ qty: { $in: [5, 15] } })` |
| `$nin` | 不在指定数组内 (Not In) | `db.inventory.find({ qty: { $nin: [5, 15] } })` |

### 逻辑操作符

| 操作符 | 描述 | 示例 |
| :--- | :--- | :--- |
| `$and` | 逻辑与，连接多个查询条件 | `db.inventory.find({ $and: [{ qty: { $lt: 20 } }, { price: { $gt: 10 } }] })` |
| `$or` | 逻辑或，满足任一查询条件 | `db.inventory.find({ $or: [{ qty: { $lt: 20 } }, { price: { $gt: 50 } }] })` |
| `$nor` | 逻辑非或，所有条件都不满足 | `db.inventory.find({ $nor: [{ price: 1.99 }, { sale: true }] })` |
| `$not` | 逻辑非，对指定条件取反 | `db.inventory.find({ price: { $not: { $gt: 1.99 } } })` |

### 元素操作符

| 操作符 | 描述 | 示例 |
| :--- | :--- | :--- |
| `$exists` | 判断字段是否存在 | `db.inventory.find({ qty: { $exists: true } })` |
| `$type` | 判断字段的数据类型 | `db.inventory.find({ qty: { $type: "number" } })` |

### 数组操作符

| 操作符 | 描述 | 示例 |
| :--- | :--- | :--- |
| `$all` | 匹配包含所有指定元素的数组 | `db.inventory.find({ tags: { $all: ["appliance", "school"] } })` |
| `$elemMatch` | 数组中至少有一个元素满足所有指定条件 | `db.inventory.find({ results: { $elemMatch: { product: "xyz", score: { $gte: 8 } } } })` |
| `$size` | 匹配指定大小的数组 | `db.inventory.find({ tags: { $size: 3 } })` |

---

## 投影（Projection）

投影用于限制查询结果中返回的字段，可以减少网络传输的数据量，并保护敏感字段。

- **包含字段**: 在 `find()` 方法的第二个参数中，将需要返回的字段设置为 `1`。

  ```javascript
  // 只返回 name 和 price 字段，_id 默认返回
  db.products.find({}, { name: 1, price: 1 })
  ```

- **排除字段**: 将不需要返回的字段设置为 `0`。

  ```javascript
  // 返回除 description 之外的所有字段
  db.products.find({}, { description: 0 })
  ```

- **排除 `_id` 字段**:

  ```javascript
  db.products.find({}, { name: 1, price: 1, _id: 0 })
  ```

---

## 排序（Sorting）

使用 `sort()` 方法对查询结果进行排序。

- **升序 (Ascending)**: 将字段值设置为 `1`。
- **降序 (Descending)**: 将字段值设置为 `-1`。

```javascript
// 按价格升序排序
db.products.find().sort({ price: 1 })

// 按库存降序、名称升序排序
db.products.find().sort({ stock: -1, name: 1 })
```

---

## 分页（Pagination）

通过组合使用 `limit()` 和 `skip()` 方法，可以实现对查询结果的分页。

- **`limit()`**: 限制返回的文档数量。
- **`skip()`**: 跳过指定数量的文档。

```javascript
// 获取第 2 页数据，每页 10 条 (跳过前 10 条，返回 10 条)
db.products.find().skip(10).limit(10)
```

**注意**: 对于大数据量的集合，使用 `skip()` 进行深度分页可能会有性能问题。在这种情况下，建议使用基于范围的查询（如使用 `_id` 或时间戳）。

---

## 正则表达式查询

MongoDB 支持使用 PCRE (Perl Compatible Regular Expression) 语法的正则表达式进行字符串匹配。

```javascript
// 查询 name 字段以 'A' 开头的文档 (不区分大小写)
db.products.find({ name: { $regex: '^A', $options: 'i' } })

// 查询 name 字段包含 'pro' 的文档
db.products.find({ name: /pro/ })
```

---

## 实践操作

假设有一个 `students` 集合，包含以下字段：`name`, `age`, `major`, `gpa`, `courses` (数组)。

### 需求描述

1.  **查询练习**:
    - 查询所有主修 'Computer Science' 且 GPA 大于 3.5 的学生。
    - 查询年龄在 20 到 22 岁之间（含）的学生。
    - 查询选修了 'Database Systems' 和 'Data Structures' 两门课的学生。

2.  **投影练习**:
    - 只返回学生的姓名和专业。

3.  **排序和分页练习**:
    - 按 GPA 降序显示前 10 名学生。

4.  **正则表达式练习**:
    - 查询所有姓 'Li' 的学生。

### 实践细节和结果验证

```javascript
// 1. 查询练习
// 查询所有主修 'Computer Science' 且 GPA 大于 3.5 的学生
db.students.find({ major: 'Computer Science', gpa: { $gt: 3.5 } });

// 查询年龄在 20 到 22 岁之间（含）的学生
db.students.find({ age: { $gte: 20, $lte: 22 } });

// 查询选修了 'Database Systems' 和 'Data Structures' 两门课的学生
db.students.find({ courses: { $all: ['Database Systems', 'Data Structures'] } });

// 2. 投影练习
// 只返回学生的姓名和专业
db.students.find({}, { name: 1, major: 1, _id: 0 });

// 3. 排序和分页练习
// 按 GPA 降序显示前 10 名学生
db.students.find().sort({ gpa: -1 }).limit(10);

// 4. 正则表达式练习
// 查询所有姓 'Li' 的学生
db.students.find({ name: /^Li/ });
```