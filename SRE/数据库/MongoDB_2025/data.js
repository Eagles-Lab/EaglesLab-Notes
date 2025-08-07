// This file contains sample data for all MongoDB practice sessions.
// Load this file into your mongo shell using: load('/path/to/this/file/data.js')

// --- Data for: MongoDB基础操作.md ---
db.inventory.drop();
db.inventory.insertMany([
  { item: "journal", qty: 25, size: { h: 14, w: 21, uom: "cm" }, status: "A", tags: ["blank", "red"], price: 15, sale: false },
  { item: "notebook", qty: 50, size: { h: 8.5, w: 11, uom: "in" }, status: "A", tags: ["school", "office"], price: 20, sale: true },
  { item: "paper", qty: 100, size: { h: 8.5, w: 11, uom: "in" }, status: "D", tags: ["office", "storage"], price: 10, sale: false },
  { item: "planner", qty: 75, size: { h: 22.85, w: 30, uom: "cm" }, status: "D", tags: ["school", "organization"], price: 12, sale: true },
  { item: "postcard", qty: 45, size: { h: 10, w: 15.25, uom: "cm" }, status: "A", tags: ["appliance", "school", "storage"], price: 5, sale: false },
  { item: "mousepad", qty: 20, size: { h: 19, w: 22, uom: "cm" }, status: "P", price: 25, sale: true, results: [{ product: "xyz", score: 10 }, { product: "abc", score: 8 }] },
  { item: "keyboard", qty: 5, price: 55, sale: false, results: [{ product: "xyz", score: 7 }, { product: "abc", score: 6 }] },
  { item: "stapler", qty: 15, price: 1.99, sale: true, results: [{ product: "xyz", score: 9 }, { product: "abc", score: 4 }] }
]);

db.books.drop();
db.books.insertMany([
    {
        "title": "Dune",
        "author": "Frank Herbert",
        "published_year": 1965,
        "genres": ["Science Fiction", "Fantasy"],
        "stock": 8
    },
    {
        "title": "Foundation",
        "author": "Isaac Asimov",
        "published_year": 1951,
        "genres": ["Science Fiction"],
        "stock": 15
    },
    {
        "title": "1984",
        "author": "George Orwell",
        "published_year": 1949,
        "genres": ["Science Fiction", "Dystopian"],
        "stock": 5
    },
    {
        "title": "Pride and Prejudice",
        "author": "Jane Austen",
        "published_year": 1813,
        "genres": ["Romance", "Classic"],
        "stock": 12
    },
    {
        "title": "The Hobbit",
        "author": "J.R.R. Tolkien",
        "published_year": 1937,
        "genres": ["Fantasy", "Adventure"],
        "stock": 20
    }
]);

// --- Data for: MongoDB进阶查询.md ---
db.students.drop();
db.students.insertMany([
    { student_id: 'S1001', name: 'Li Wei', age: 21, major: 'Computer Science', gpa: 3.8, courses: ['Database Systems', 'Data Structures', 'Operating Systems'] },
    { student_id: 'S1002', name: 'Zhang Min', age: 20, major: 'Computer Science', gpa: 3.6, courses: ['Algorithms', 'Computer Networks'] },
    { student_id: 'S1003', name: 'Wang Fang', age: 22, major: 'Mathematics', gpa: 3.9, courses: ['Calculus', 'Linear Algebra'] },
    { student_id: 'S1004', name: 'Li Juan', age: 20, major: 'Computer Science', gpa: 3.4, courses: ['Database Systems', 'Data Structures'] },
    { student_id: 'S1005', name: 'Chen Hao', age: 23, major: 'Physics', gpa: 3.2, courses: ['Mechanics', 'Electromagnetism'] },
    { student_id: 'S1006', name: 'Liu Yang', age: 21, major: 'Computer Science', gpa: 3.7, courses: ['Database Systems', 'Artificial Intelligence'] }
]);

// --- Data for: MongoDB索引优化.md ---
db.products_for_indexing.drop();
db.products_for_indexing.insertMany([
  { "category": "Electronics", "brand": "Sony", "price": 1200 },
  { "category": "Electronics", "brand": "Samsung", "price": 950 },
  { "category": "Electronics", "brand": "Apple", "price": 1500 },
  { "category": "Clothing", "brand": "Nike", "price": 150 },
  { "category": "Clothing", "brand": "Adidas", "price": 120 },
  { "category": "Books", "brand": "PublisherA", "price": 25 },
  { "category": "Books", "brand": "PublisherB", "price": 30 },
  { "category": "Electronics", "brand": "Sony", "price": 800 }
]);

// --- Data for: MongoDB聚合框架.md ---
db.sales.drop();
db.sales.insertMany([
    { "product": "Laptop", "quantity": 1, "price": 1200, "date": new Date("2023-01-15") },
    { "product": "Mouse", "quantity": 2, "price": 25, "date": new Date("2023-01-15") },
    { "product": "Keyboard", "quantity": 1, "price": 75, "date": new Date("2023-01-16") },
    { "product": "Laptop", "quantity": 1, "price": 1300, "date": new Date("2023-02-10") },
    { "product": "Monitor", "quantity": 1, "price": 300, "date": new Date("2023-02-12") },
    { "product": "Mouse", "quantity": 3, "price": 25, "date": new Date("2023-02-20") },
    { "product": "Laptop", "quantity": 2, "price": 1100, "date": new Date("2023-03-05") },
    { "product": "Webcam", "quantity": 1, "price": 50, "date": new Date("2023-03-07") }
]);

db.products_for_aggregation.drop();
db.products_for_aggregation.insertMany([
    { "name": "Laptop", "category": "Electronics" },
    { "name": "Mouse", "category": "Electronics" },
    { "name": "Keyboard", "category": "Electronics" },
    { "name": "Monitor", "category": "Electronics" },
    { "name": "Webcam", "category": "Accessories" },
    { "name": "T-Shirt", "category": "Apparel" }
]);

// --- Data for: MongoDB数据建模.md ---
// Note: The following commands use shell-specific functions like ObjectId() and ISODate().
// They are intended to be run directly in the mongo shell.

db.users.drop();
db.posts.drop();
db.comments.drop();

const userJohnId = new ObjectId();
db.users.insertOne({
  "_id": userJohnId,
  "username": "john_doe",
  "email": "john@example.com"
});

const postMongoId = new ObjectId();
db.posts.insertOne({
  "_id": postMongoId,
  "author_id": userJohnId,
  "author_name": "john_doe",
  "title": "MongoDB 入门",
  "content": "MongoDB 是一个强大的 NoSQL 数据库...",
  "created_at": new Date("2024-01-15"),
  "tags": ["MongoDB", "Database", "NoSQL"]
});

const userAliceId = new ObjectId();
db.users.insertOne({
  "_id": userAliceId,
  "username": "alice",
  "email": "alice@example.com"
});

db.comments.insertOne({
  "_id": new ObjectId(),
  "post_id": postMongoId,
  "user_id": userAliceId,
  "username": "alice",
  "content": "写得很好！",
  "created_at": new Date("2024-01-16")
});

print("All sample data have been loaded.");