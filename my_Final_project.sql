-- =========================================================
-- Project: AAU Library Management
-- Description: Full-featured relational schema for an academic library
-- Database: MySQL 8+ (InnoDB, utf8mb4)
-- Author: <Your Name>
-- Date: 2025-08-16
-- Notes:
--   * This file creates the database, tables, constraints, indexes,
--     and sample users/roles suitable for local testing.
--   * Engine: InnoDB to support FK constraints and transactions.
--   * Character set: utf8mb4 for full Unicode support.
--
-- To run:
--   1) In MySQL Workbench or CLI: SOURCE /path/to/aau_library_management.sql;
--   2) Or copy-paste into a new SQL script and execute.
-- =========================================================

-- ---------- Safety: create a clean database (optional) ----------
-- DROP DATABASE IF EXISTS aau_library_management;

CREATE DATABASE IF NOT EXISTS aau_library_management
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_0900_ai_ci;

USE aau_library_management;

-- ---------- Table: branches (library branches) ----------
CREATE TABLE branches (
  branch_id      BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name           VARCHAR(120) NOT NULL UNIQUE,
  address_line1  VARCHAR(200) NOT NULL,
  address_line2  VARCHAR(200),
  city           VARCHAR(80) NOT NULL,
  state_province VARCHAR(80),
  postal_code    VARCHAR(30),
  country        VARCHAR(80) NOT NULL DEFAULT 'Ethiopia',
  phone          VARCHAR(40),
  created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- Table: publishers ----------
CREATE TABLE publishers (
  publisher_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name         VARCHAR(160) NOT NULL UNIQUE,
  website      VARCHAR(200),
  created_at   TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- ---------- Table: authors ----------
CREATE TABLE authors (
  author_id  BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  full_name  VARCHAR(160) NOT NULL,
  birth_date DATE,
  death_date DATE,
  UNIQUE KEY uk_authors_name (full_name)
) ENGINE=InnoDB;

-- ---------- Table: categories (subjects) ----------
CREATE TABLE categories (
  category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(120) NOT NULL UNIQUE,
  parent_id   BIGINT UNSIGNED,
  CONSTRAINT fk_categories_parent
    FOREIGN KEY (parent_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Table: books (bibliographic record) ----------
CREATE TABLE books (
  book_id          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  isbn13           CHAR(13) UNIQUE,         -- allow NULL for older/local items
  title            VARCHAR(300) NOT NULL,
  subtitle         VARCHAR(300),
  edition          VARCHAR(40),
  language_code    VARCHAR(16) DEFAULT 'en',
  publication_year SMALLINT,
  pages            INT,
  publisher_id     BIGINT UNSIGNED,
  description      TEXT,
  cover_url        VARCHAR(500),
  created_at       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at       TIMESTAMP NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_books_publisher
    FOREIGN KEY (publisher_id) REFERENCES publishers(publisher_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL
) ENGINE=InnoDB;

-- ---------- Table: book_authors (M:N) ----------
CREATE TABLE book_authors (
  book_id   BIGINT UNSIGNED NOT NULL,
  author_id BIGINT UNSIGNED NOT NULL,
  author_order INT NOT NULL DEFAULT 1,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_book_authors_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_book_authors_author
    FOREIGN KEY (author_id) REFERENCES authors(author_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Table: book_categories (M:N) ----------
CREATE TABLE book_categories (
  book_id     BIGINT UNSIGNED NOT NULL,
  category_id BIGINT UNSIGNED NOT NULL,
  PRIMARY KEY (book_id, category_id),
  CONSTRAINT fk_book_categories_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE,
  CONSTRAINT fk_book_categories_category
    FOREIGN KEY (category_id) REFERENCES categories(category_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Table: members (library patrons: students, faculty, etc.) ----------
CREATE TABLE members (
  member_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  card_number   VARCHAR(40) NOT NULL UNIQUE,
  first_name    VARCHAR(80) NOT NULL,
  last_name     VARCHAR(80) NOT NULL,
  email         VARCHAR(160) NOT NULL UNIQUE,
  phone         VARCHAR(40) UNIQUE,
  member_type   ENUM('Student','Faculty','Staff','External') NOT NULL DEFAULT 'Student',
  status        ENUM('Active','Suspended','Closed') NOT NULL DEFAULT 'Active',
  address_line1 VARCHAR(200),
  address_line2 VARCHAR(200),
  city          VARCHAR(80),
  state_province VARCHAR(80),
  postal_code   VARCHAR(30),
  country       VARCHAR(80) DEFAULT 'Ethiopia',
  registered_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

-- Example of a 1:1 relationship: each member can have one optional profile row
-- (e.g., for extended demographics kept separately)
CREATE TABLE member_profiles (
  member_id     BIGINT UNSIGNED PRIMARY KEY,
  date_of_birth DATE,
  gender        ENUM('Male','Female','Other','PreferNotToSay'),
  department    VARCHAR(160),  -- e.g., AAU department
  notes         TEXT,
  CONSTRAINT fk_member_profiles_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE
    ON DELETE CASCADE
) ENGINE=InnoDB;

-- ---------- Table: staff (librarians/operators) ----------
CREATE TABLE staff (
  staff_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  branch_id   BIGINT UNSIGNED NOT NULL,
  first_name  VARCHAR(80) NOT NULL,
  last_name   VARCHAR(80) NOT NULL,
  email       VARCHAR(160) NOT NULL UNIQUE,
  phone       VARCHAR(40) UNIQUE,
  role        ENUM('Librarian','Assistant','Manager','Admin') NOT NULL DEFAULT 'Librarian',
  hired_at    DATE NOT NULL,
  active      BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT fk_staff_branch
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Table: copies (physical items) ----------
CREATE TABLE copies (
  copy_id        BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  book_id        BIGINT UNSIGNED NOT NULL,
  branch_id      BIGINT UNSIGNED NOT NULL,
  barcode        VARCHAR(64) NOT NULL UNIQUE,
  shelf_location VARCHAR(80) NOT NULL,
  acquisition_date DATE,
  status         ENUM('Available','OnLoan','Reserved','Lost','Damaged','Withdrawn') NOT NULL DEFAULT 'Available',
  CONSTRAINT fk_copies_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_copies_branch
    FOREIGN KEY (branch_id) REFERENCES branches(branch_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Table: loans (borrow transactions) ----------
CREATE TABLE loans (
  loan_id     BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  copy_id     BIGINT UNSIGNED NOT NULL,
  member_id   BIGINT UNSIGNED NOT NULL,
  issued_by   BIGINT UNSIGNED NOT NULL, -- staff who issued
  loan_date   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  due_date    DATETIME NOT NULL,
  return_date DATETIME,
  status      ENUM('Open','Returned','Overdue','Lost') NOT NULL DEFAULT 'Open',
  CONSTRAINT fk_loans_copy
    FOREIGN KEY (copy_id) REFERENCES copies(copy_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_loans_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_loans_staff
    FOREIGN KEY (issued_by) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  INDEX idx_loans_member (member_id),
  INDEX idx_loans_copy (copy_id)
) ENGINE=InnoDB;

-- ---------- Table: reservations (holds/waitlist for a title) ----------
CREATE TABLE reservations (
  reservation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  book_id        BIGINT UNSIGNED NOT NULL,
  member_id      BIGINT UNSIGNED NOT NULL,
  reserved_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  status         ENUM('Active','Fulfilled','Cancelled','Expired') NOT NULL DEFAULT 'Active',
  fulfilled_at   DATETIME,
  fulfilled_by   BIGINT UNSIGNED, -- staff who fulfilled (optional)
  CONSTRAINT fk_reservations_book
    FOREIGN KEY (book_id) REFERENCES books(book_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_reservations_member
    FOREIGN KEY (member_id) REFERENCES members(member_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_reservations_staff
    FOREIGN KEY (fulfilled_by) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE SET NULL,
  UNIQUE KEY uk_reservation_active (book_id, member_id, status)
) ENGINE=InnoDB;

-- ---------- Table: fines (fees assessed per loan) ----------
CREATE TABLE fines (
  fine_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  loan_id    BIGINT UNSIGNED NOT NULL,
  amount     DECIMAL(10,2) NOT NULL CHECK (amount >= 0),
  reason     ENUM('Overdue','Lost','Damaged','Other') NOT NULL DEFAULT 'Overdue',
  issued_at  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  paid_at    DATETIME NULL,
  status     ENUM('Unpaid','PartiallyPaid','Paid','Waived') NOT NULL DEFAULT 'Unpaid',
  CONSTRAINT fk_fines_loan
    FOREIGN KEY (loan_id) REFERENCES loans(loan_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Table: payments (settling fines) ----------
CREATE TABLE payments (
  payment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  fine_id    BIGINT UNSIGNED NOT NULL,
  amount     DECIMAL(10,2) NOT NULL CHECK (amount > 0),
  method     ENUM('Cash','Card','Transfer','MobileMoney') NOT NULL,
  paid_at    DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  received_by BIGINT UNSIGNED NOT NULL, -- staff
  CONSTRAINT fk_payments_fine
    FOREIGN KEY (fine_id) REFERENCES fines(fine_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT,
  CONSTRAINT fk_payments_staff
    FOREIGN KEY (received_by) REFERENCES staff(staff_id)
    ON UPDATE CASCADE
    ON DELETE RESTRICT
) ENGINE=InnoDB;

-- ---------- Helpful indexes ----------
CREATE INDEX idx_books_title ON books(title);
CREATE INDEX idx_books_isbn ON books(isbn13);
CREATE INDEX idx_copies_book_status ON copies(book_id, status);
CREATE INDEX idx_reservations_member ON reservations(member_id);
CREATE INDEX idx_members_email ON members(email);

-- ---------- Optional: seed minimal reference data (comment out in production) ----------
INSERT INTO branches (name, address_line1, city, country, phone)
VALUES ('AAU Main Library', 'King George VI St', 'Addis Ababa', 'Ethiopia', '+251-11-111-1111');

INSERT INTO publishers (name, website) VALUES ('Addis Academic Press', 'https://example.com');
INSERT INTO authors (full_name) VALUES ('Alemayehu G.'), ('Hanna T.');
INSERT INTO categories (name) VALUES ('Computer Science'), ('Mathematics');

INSERT INTO books (isbn13, title, language_code, publication_year, publisher_id, pages)
VALUES ('9781234567890', 'Database Systems', 'en', 2023, 1, 640);

INSERT INTO book_authors (book_id, author_id, author_order) VALUES (1, 1, 1);
INSERT INTO book_categories (book_id, category_id) VALUES (1, 1);

INSERT INTO staff (branch_id, first_name, last_name, email, role, hired_at)
VALUES (1, 'Lulit', 'K.', 'lulit.k@example.edu', 'Librarian', '2022-01-15');

INSERT INTO copies (book_id, branch_id, barcode, shelf_location, acquisition_date)
VALUES (1, 1, 'AAU-DB-0001', 'CS-DB-01', '2023-10-10');

INSERT INTO members (card_number, first_name, last_name, email, member_type)
VALUES ('AAU-STU-0001', 'Yonatan', 'A.', 'yonatan.a@example.edu', 'Student');

-- Sample loan (due 14 days later)
INSERT INTO loans (copy_id, member_id, issued_by, loan_date, due_date)
VALUES (1, 1, 1, NOW(), DATE_ADD(NOW(), INTERVAL 14 DAY));

-- Optional sample fine
-- INSERT INTO fines (loan_id, amount, reason) VALUES (1, 25.00, 'Overdue');

-- =========================================================
-- END OF SCHEMA
-- =========================================================
