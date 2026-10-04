-- Library Management System (MySQL 8)
-- Run order: 01_schema.sql, 02_seed.sql, 03_queries.sql

DROP DATABASE IF EXISTS library_management;
CREATE DATABASE library_management CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE library_management;

-- ---------------------------------------------------------------
-- Tables
-- ---------------------------------------------------------------
CREATE TABLE categories (
  category_id INT AUTO_INCREMENT PRIMARY KEY,
  name        VARCHAR(80) NOT NULL UNIQUE
);

CREATE TABLE authors (
  author_id INT AUTO_INCREMENT PRIMARY KEY,
  name      VARCHAR(120) NOT NULL
);

CREATE TABLE books (
  book_id          INT AUTO_INCREMENT PRIMARY KEY,
  isbn             VARCHAR(20)  NOT NULL UNIQUE,
  title            VARCHAR(200) NOT NULL,
  category_id      INT NOT NULL,
  published_year   SMALLINT,
  total_copies     INT NOT NULL DEFAULT 1,
  available_copies INT NOT NULL DEFAULT 1,
  CONSTRAINT fk_books_category FOREIGN KEY (category_id) REFERENCES categories(category_id),
  CONSTRAINT chk_copies CHECK (total_copies >= 0 AND available_copies >= 0 AND available_copies <= total_copies)
);

-- Many-to-many: a book can have several authors, an author can have several books
CREATE TABLE book_authors (
  book_id   INT NOT NULL,
  author_id INT NOT NULL,
  PRIMARY KEY (book_id, author_id),
  CONSTRAINT fk_ba_book   FOREIGN KEY (book_id)   REFERENCES books(book_id)     ON DELETE CASCADE,
  CONSTRAINT fk_ba_author FOREIGN KEY (author_id) REFERENCES authors(author_id) ON DELETE CASCADE
);

CREATE TABLE members (
  member_id  INT AUTO_INCREMENT PRIMARY KEY,
  full_name  VARCHAR(120) NOT NULL,
  email      VARCHAR(150) NOT NULL UNIQUE,
  phone      VARCHAR(20),
  joined_on  DATE NOT NULL DEFAULT (CURRENT_DATE),
  is_active  BOOLEAN NOT NULL DEFAULT TRUE
);

CREATE TABLE loans (
  loan_id     INT AUTO_INCREMENT PRIMARY KEY,
  book_id     INT NOT NULL,
  member_id   INT NOT NULL,
  issue_date  DATE NOT NULL,
  due_date    DATE NOT NULL,
  return_date DATE NULL,
  fine_amount DECIMAL(8,2) NOT NULL DEFAULT 0,
  CONSTRAINT fk_loans_book   FOREIGN KEY (book_id)   REFERENCES books(book_id),
  CONSTRAINT fk_loans_member FOREIGN KEY (member_id) REFERENCES members(member_id),
  CONSTRAINT chk_dates CHECK (due_date >= issue_date AND (return_date IS NULL OR return_date >= issue_date)),
  INDEX idx_loans_member (member_id),
  INDEX idx_loans_open (return_date, due_date)
);

-- ---------------------------------------------------------------
-- Triggers: keep available_copies correct and calculate fines
-- (fine rule: Rs. 10 for every day a book is returned after its due date)
-- ---------------------------------------------------------------
DELIMITER //

CREATE TRIGGER trg_loan_before_insert
BEFORE INSERT ON loans
FOR EACH ROW
BEGIN
  DECLARE copies_left INT;
  DECLARE member_ok BOOLEAN;
  SELECT available_copies INTO copies_left FROM books WHERE book_id = NEW.book_id;
  SELECT is_active INTO member_ok FROM members WHERE member_id = NEW.member_id;
  IF copies_left IS NULL OR copies_left <= 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No copies of this book are available';
  END IF;
  IF member_ok IS NULL OR member_ok = FALSE THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Member is not active';
  END IF;
END//

CREATE TRIGGER trg_loan_after_insert
AFTER INSERT ON loans
FOR EACH ROW
BEGIN
  UPDATE books SET available_copies = available_copies - 1 WHERE book_id = NEW.book_id;
END//

CREATE TRIGGER trg_loan_before_update
BEFORE UPDATE ON loans
FOR EACH ROW
BEGIN
  IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
    SET NEW.fine_amount = GREATEST(DATEDIFF(NEW.return_date, NEW.due_date), 0) * 10;
  END IF;
END//

CREATE TRIGGER trg_loan_after_update
AFTER UPDATE ON loans
FOR EACH ROW
BEGIN
  IF OLD.return_date IS NULL AND NEW.return_date IS NOT NULL THEN
    UPDATE books SET available_copies = available_copies + 1 WHERE book_id = NEW.book_id;
  END IF;
END//

-- ---------------------------------------------------------------
-- Stored procedures
-- ---------------------------------------------------------------
CREATE PROCEDURE issue_book(IN p_book_id INT, IN p_member_id INT, IN p_days INT, IN p_issue_date DATE)
BEGIN
  INSERT INTO loans (book_id, member_id, issue_date, due_date)
  VALUES (p_book_id, p_member_id, p_issue_date, DATE_ADD(p_issue_date, INTERVAL p_days DAY));
END//

CREATE PROCEDURE return_book(IN p_loan_id INT, IN p_return_date DATE)
BEGIN
  UPDATE loans SET return_date = p_return_date WHERE loan_id = p_loan_id AND return_date IS NULL;
  IF ROW_COUNT() = 0 THEN
    SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Loan not found or already returned';
  END IF;
END//

DELIMITER ;

-- ---------------------------------------------------------------
-- Views
-- ---------------------------------------------------------------
CREATE VIEW v_book_catalog AS
SELECT b.book_id, b.isbn, b.title, c.name AS category,
       GROUP_CONCAT(a.name ORDER BY a.name SEPARATOR ', ') AS authors,
       b.published_year, b.total_copies, b.available_copies
FROM books b
JOIN categories c ON c.category_id = b.category_id
LEFT JOIN book_authors ba ON ba.book_id = b.book_id
LEFT JOIN authors a ON a.author_id = ba.author_id
GROUP BY b.book_id, b.isbn, b.title, c.name, b.published_year, b.total_copies, b.available_copies;

CREATE VIEW v_open_loans AS
SELECT l.loan_id, m.full_name AS member, b.title, l.issue_date, l.due_date,
       GREATEST(DATEDIFF(CURRENT_DATE, l.due_date), 0) AS days_overdue
FROM loans l
JOIN members m ON m.member_id = l.member_id
JOIN books b   ON b.book_id   = l.book_id
WHERE l.return_date IS NULL;
