# 基础操作

本章节将引导大家学习 MongoDB 的基础操作，包括如何使用 MongoDB Shell、管理数据库和集合，以及对文档进行核心的增删改查（CRUD）操作。掌握这些基础是进行更高级应用的前提。

---

## MongoDB Shell 使用

MongoDB Shell 是一个功能强大的交互式 JavaScript 接口，用于管理和操作 MongoDB 数据库。

- **连接数据库**:
  打开终端，输入 `mongo` 或 `mongosh` 命令即可连接到本地默认的 MongoDB 实例 (mongodb://127.0.0.1:27017)。
  ```shell
  mongosh "mongodb://<host>:<port>/<database>" -u <username> -p
  ```

- **基本命令**:
  - `show dbs`: 显示所有数据库列表。
  - `use <db_name>`: 切换到指定数据库，如果不存在则在首次插入数据时创建。
  - `show collections`: 显示当前数据库中的所有集合。
  - `db`: 显示当前所在的数据库。
  - `db.stats()`: 显示当前数据库的状态信息。
  - `exit` 或 `quit()`: 退出 Shell。

---

## 数据库操作

- **创建数据库**: 无需显式创建，当向一个不存在的数据库中的集合插入第一条数据时，该数据库会自动创建。
- **查看数据库**: `show dbs`
- **切换数据库**: `use myNewDB`
- **删除数据库**: 首先切换到要删除的数据库，然后执行 `db.dropDatabase()`。

---

## 集合操作

- **创建集合**:
  - **隐式创建**: 当向一个不存在的集合插入第一条数据时，集合会自动创建。
  - **显式创建**: 使用 `db.createCollection()` 方法，可以指定更多选项，如大小限制、验证规则等。
    ```javascript
    db.createCollection("myCollection", { capped: true, size: 100000 })
    ```

- **查看集合**: `show collections`

- **删除集合**: `db.myCollection.drop()`

---

## 文档 CRUD 操作

CRUD 代表创建 (Create)、读取 (Read)、更新 (Update) 和删除 (Delete) 操作。

### 插入文档 (Create)

- **`insertOne()`**: 插入单个文档。
  ```javascript
  db.inventory.insertOne({ item: "canvas", qty: 100, tags: ["cotton"], size: { h: 28, w: 35.5, uom: "cm" } })
  ```
- **`insertMany()`**: 插入多个文档。
  ```javascript
  db.inventory.insertMany([
    { item: "journal", qty: 25, tags: ["blank", "red"], size: { h: 14, w: 21, uom: "cm" } },
    { item: "mat", qty: 85, tags: ["gray"], size: { h: 27.9, w: 35.5, uom: "cm" } }
  ])
  ```

### 查询文档 (Read)

- **`find()`**: 查询集合中所有匹配的文档。
  ```javascript
  // 查询所有文档
  db.inventory.find({})

  // 查询 qty 大于 50 的文档
  db.inventory.find({ qty: { $gt: 50 } })
  ```
- **`findOne()`**: 只返回匹配的第一个文档。
  ```javascript
  db.inventory.findOne({ item: "journal" })
  ```

### 更新文档 (Update)

- **`updateOne()`**: 更新匹配的第一个文档。
  ```javascript
  db.inventory.updateOne(
    { item: "journal" },
    { $set: { "size.uom": "in" }, $currentDate: { lastModified: true } }
  )
  ```
- **`updateMany()`**: 更新所有匹配的文档。
  ```javascript
  db.inventory.updateMany(
    { qty: { $gt: 50 } },
    { $set: { "size.uom": "in" }, $currentDate: { lastModified: true } }
  )
  ```
- **`replaceOne()`**: 替换匹配的第一个文档。

### 删除文档 (Delete)

- **`deleteOne()`**: 删除匹配的第一个文档。
  ```javascript
  db.inventory.deleteOne({ item: "journal" })
  ```
- **`deleteMany()`**: 删除所有匹配的文档。
  ```javascript
  db.inventory.deleteMany({ qty: { $gt: 50 } })
  ```

---

## 实践操作

### 需求描述

1.  **创建与切换**: 创建一个名为 `bookstore` 的数据库并切换过去。
2.  **插入数据**: 在 `bookstore` 数据库中创建一个 `books` 集合，并批量插入至少 5 本书的数据，每本书包含 `title`, `author`, `published_year`, `genres` (数组), `stock` (库存) 字段。
3.  **查询练习**: 
    - 查询所有库存量小于 10 本的书。
    - 查询所有 `Science Fiction` 类型的书。
3.  **更新练习**: 将指定一本书的库存量增加 5。
4.  **删除练习**: 删除所有 `published_year` 在 1950 年之前的书。
5.  **数据导入导出**: 使用 `mongoexport` 将 `books` 集合导出为 JSON 文件，然后使用 `mongoimport` 将其导入到一个新的集合 `books_backup` 中。

### 实践细节和结果验证

```javascript
// 1. 创建与切换数据库
use bookstore;

// 2. 插入数据
// 参考 data.js 文件中 Data for: MongoDB基础操作.md 下 books 集合的插入数据部分

// 3. 查询练习
// 查询所有库存量小于 10 本的书
db.books.find({ stock: { $lt: 10 } });

// 查询所有 Science Fiction 类型的书
db.books.find({ genres: "Science Fiction" });

// 4. 更新练习
// 将指定一本书的库存量增加 5
db.books.updateOne(
    { title: "Dune" },
    { $inc: { stock: 5 } }
);

// 5. 删除练习
// 删除所有 published_year 在 1950 年之前的书
db.books.deleteMany({ published_year: { $lt: 1950 } });

// 6. 数据导入导出
// 使用 mongoexport 将 books 集合导出为 JSON 文件
// mongoexport --db bookstore --collection books --out books.json --jsonArray

// 使用 mongoimport 将其导入到一个新的集合 books_backup 中
// mongoimport --db bookstore --collection books_backup --file books.json --jsonArray
```