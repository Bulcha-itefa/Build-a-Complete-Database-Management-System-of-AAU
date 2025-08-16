# Build-a-Complete-Database-Management-System-of-AAU
Description: AAU Library Management is a MySQL-based relational database system designed for managing Addis Ababa University’s library operations. It handles books, authors, publishers, categories, members, staff, loans, reservations, fines, and payments with proper normalization, constraints, and relationships.
# AAU Library Management
A relational database schema for managing an academic library at  AAU  
This project is implemented **entirely in MySQL** and demonstrates solid database design using normalization principles and proper constraints (PK, FK, NOT NULL, UNIQUE).

## 🎯 What thIS project does:

- Stores **bibliographic data**: books, authors, publishers, categories.
- Tracks **physical copies** across library **branches/ALL CAMPUS**.
- Manages **members** (students, faculty, staff, external), their profiles, and statuses.
- Records **loans**, **reservations (holds)**, **fines**, and **payments**.
- Includes **1:1**, **1:M**, and **M:N** relationships:
  - 1:1 — `members` ↔ `member_profiles`
  - 1:M — `branches` → `staff`, `books` → `copies`, `members` → `loans`
  - M:N — `books` ↔ `authors` (`book_authors`), `books` ↔ `categories` (`book_categorie

## 🚀 How to run / setup

1. **MySQL WORKBENCH 
2. Open **MySQL WorkbencH**
3. Execute the SQL file:

SOURCE /path/to/aau_library_management.sql;
This will:
- Create the database `aau_library_management`
- Create all tables, constraints, and indexes
- Insert minimal seed data (branch, one book, one copy, one member, one staff, and a sample loan)
> If you prefer a clean schema with no sample data, comment out or remove the **Optional: seed minimal reference data** section at the bottom of the SQL file.
## 📘 ERD (Overview)

```
+-----------+       +---------+      +-----------+
| publishers|---+   | books   |  +---| categories|
+-----------+   |   +---------+  |   +-----------+
                |   |book_id PK|  |         ^
                |   |publisher |<-+         |
                |   |title     |            |
                |   |isbn13 UQ |            |
                |   +---------+            |
                |        ^                  |
                |        |                  |
                |   +---------+             |
                +---| copies  |             |
                    +---------+             |
                    |copy_id PK|            |
                    |book_id FK|            |
                    |branch FK |            |
                    +----+----+             |
                         |                  |
               +---------v--------+    +----+--------------+
               | branches         |    | book_categories   |
               +------------------+    +-------------------+
                                      (book_id PK/FK, category_id PK/FK)

+---------+        +--------------+       +------------+
| authors |<--+--->| book_authors |<----->| books      |
+---------+   M:N  +--------------+       +------------+

+---------+        +-----------------+       +---------+
| members |<--1:1->| member_profiles |       | loans   |
+---------+        +-----------------+       +---------+
     ^                     ^                        ^
     |                     |                        |
     |               +-----+-----+                  |
     |               | reservations|                |
     |               +-----------+-+                |
     |                           |                  |
     |                           |                  |
     |                     +-----v-----+            |
     |                     | copies    |------------+
     |                     +-----------+
     |
+---------+
| fines   |<--- loans
+---------+
     ^
     |
+----------+
| payments |
+----------+
## 🧪 Quick smoke tests (sample queries)

 
 
