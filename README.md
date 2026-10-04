# Library Management System (MySQL)

A complete relational database for a library: books, authors, categories, members and loans, with business rules enforced inside the database.

## What it demonstrates

- **Normalised design:** `books`, `authors`, `categories`, `members`, `loans`, plus the junction table `book_authors` for the many-to-many relationship between books and authors
- **Constraints:** primary and foreign keys, `UNIQUE` (ISBN, email), `CHECK` (copy counts, dates), defaults
- **Triggers:**
  - refuse a loan if no copy is available or the member is inactive
  - decrease available copies when a book is issued and increase them when it is returned
  - calculate the fine automatically on return (Rs. 10 per late day)
- **Stored procedures:** `issue_book(book, member, days, date)` and `return_book(loan, date)`
- **Views:** `v_book_catalog` (book + authors + availability) and `v_open_loans` (books currently out with days overdue)
- **Queries:** joins, `LEFT JOIN ... IS NULL`, `GROUP BY` / `HAVING`, aggregation, `GROUP_CONCAT`

## Run it (MySQL 8.0.16 or newer)

```bash
mysql -u root -p < 01_schema.sql     # creates the library_management database, tables, triggers, procedures, views
mysql -u root -p < 02_seed.sql       # sample books, members and loans
mysql -u root -p --table --force < 03_queries.sql
```

`01_schema.sql` drops and recreates the `library_management` database, so running it again resets the sample data.

## Example

```sql
CALL issue_book(1, 2, 14, '2026-09-01');    -- member 2 borrows book 1 for 14 days
CALL return_book(1, '2026-09-25');          -- returned 10 days late -> fine Rs. 100 added automatically
SELECT * FROM v_open_loans;
```

## Files

| File | Purpose |
|------|---------|
| `01_schema.sql` | Database, tables, triggers, procedures, views |
| `02_seed.sql` | Sample data (loaded through the procedures) |
| `03_queries.sql` | Eight example reports |
