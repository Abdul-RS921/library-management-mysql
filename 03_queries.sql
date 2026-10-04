USE library_management;

-- 1. Catalog with authors and live availability
SELECT book_id, title, category, authors, available_copies, total_copies
FROM v_book_catalog ORDER BY title;

-- 2. Books currently out (not returned yet)
SELECT * FROM v_open_loans ORDER BY due_date;

-- 3. Overdue books as of a chosen date
SELECT loan_id, member, title, due_date, DATEDIFF('2026-10-04', due_date) AS days_late
FROM v_open_loans
WHERE due_date < '2026-10-04'
ORDER BY days_late DESC;

-- 4. Most borrowed books
SELECT b.title, COUNT(*) AS times_borrowed
FROM loans l JOIN books b ON b.book_id = l.book_id
GROUP BY b.book_id, b.title
ORDER BY times_borrowed DESC, b.title;

-- 5. Fines owed per member
SELECT m.full_name, SUM(l.fine_amount) AS total_fine
FROM loans l JOIN members m ON m.member_id = l.member_id
GROUP BY m.member_id, m.full_name
HAVING total_fine > 0;

-- 6. Members who never borrowed anything (LEFT JOIN + IS NULL)
SELECT m.full_name
FROM members m LEFT JOIN loans l ON l.member_id = m.member_id
WHERE l.loan_id IS NULL;

-- 7. Books per category (aggregation)
SELECT c.name AS category, COUNT(b.book_id) AS titles, SUM(b.total_copies) AS copies
FROM categories c LEFT JOIN books b ON b.category_id = c.category_id
GROUP BY c.category_id, c.name
ORDER BY copies DESC;

-- 8. Check that the trigger blocks an impossible loan (no copies left of book 5 after this):
CALL issue_book(5, 4, 14, '2026-10-01');   -- ok, takes the only copy
CALL issue_book(5, 3, 14, '2026-10-02');   -- fails: No copies of this book are available
