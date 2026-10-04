USE library_management;

INSERT INTO categories (name) VALUES
  ('Computer Science'), ('Fiction'), ('History'), ('Science'), ('Urdu Literature');

INSERT INTO authors (name) VALUES
  ('Thomas H. Cormen'), ('Charles E. Leiserson'), ('Robert C. Martin'),
  ('Mirza Ghalib'), ('Allama Iqbal'), ('Stephen Hawking'),
  ('Ibn-e-Safi'), ('Khaled Hosseini');

INSERT INTO books (isbn, title, category_id, published_year, total_copies, available_copies) VALUES
  ('9780262033848', 'Introduction to Algorithms',      1, 2009, 3, 3),
  ('9780132350884', 'Clean Code',                      1, 2008, 2, 2),
  ('9780553380163', 'A Brief History of Time',         4, 1988, 2, 2),
  ('9780747532743', 'The Kite Runner',                 2, 2003, 2, 2),
  ('9789690000011', 'Deewan-e-Ghalib',                 5, 1841, 1, 1),
  ('9789690000028', 'Bang-e-Dra',                      5, 1924, 1, 1),
  ('9789690000035', 'Imran Series: Khofnak Imarat',    2, 1955, 2, 2);

INSERT INTO book_authors (book_id, author_id) VALUES
  (1, 1), (1, 2), (2, 3), (3, 6), (4, 8), (5, 4), (6, 5), (7, 7);

INSERT INTO members (full_name, email, phone, joined_on) VALUES
  ('Ayesha Khan',  'ayesha@example.com', '0300-1111111', '2026-01-10'),
  ('Bilal Ahmed',  'bilal@example.com',  '0300-2222222', '2026-02-05'),
  ('Hina Malik',   'hina@example.com',   '0300-3333333', '2026-02-20'),
  ('Usman Ali',    'usman@example.com',  '0300-4444444', '2026-03-01');

-- Loans go through the stored procedures so triggers keep stock correct
CALL issue_book(1, 1, 14, '2026-09-01');
CALL issue_book(2, 2, 14, '2026-09-03');
CALL issue_book(3, 3, 14, '2026-09-10');
CALL issue_book(1, 2, 14, '2026-09-12');
CALL issue_book(4, 1, 14, '2026-09-20');

-- Some are returned: loan 1 on time, loan 2 eight days late
CALL return_book(1, '2026-09-14');
CALL return_book(2, '2026-09-25');
