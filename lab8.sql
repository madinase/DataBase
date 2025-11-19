CREATE TABLE departments (
dept_id INT PRIMARY KEY,
dept_name VARCHAR(50),
location VARCHAR(50)
);

CREATE TABLE employees (
emp_id INT PRIMARY KEY,
emp_name VARCHAR(100),
dept_id INT,
salary DECIMAL(10,2),
FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE TABLE projects (
 proj_id INT PRIMARY KEY,
 proj_name VARCHAR(100),
 budget DECIMAL(12,2),
 dept_id INT,
 FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

INSERT INTO departments VALUES
(101, 'IT' , 'Building A'),
(102, 'HR', 'Building B'),
(103, 'Operations', 'Building C');

INSERT INTO employees VALUES
(1, 'John Smith', 101, 50000),
(2, 'Jane Doe', 101, 55000),
(3, 'Mike Johnson', 102, 48000),
(4, 'Sarah Williams', 102, 52000),
(5, 'Tom Brown', 103, 60000);

INSERT INTO projects VALUES
(201, 'Website Redesign', 75000, 101),
(202, 'Database Migration', 120000, 101),
(203, 'HR System Upgrade', 50000, 102);

--Part 2: CREATING BASIC INDEXES

--2.1 Create a simple B-tree Index

CREATE INDEX emp_salary_idx ON employees(salary);

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees';

--How many indexes exist on the employees table?
--2 indexes. Because PRIMARY KEY creates an automatic index(employees_pkey); The newly emp_salary_idx index

--2.2 Create an Index on a FOREIGN Key

CREATE INDEX emp_dept_idx ON employees(dept_id);

SELECT * FROM employees WHERE dept_id = 101;

--Why is it beneficial to index foreign key columns?
--Indexing foreign key columns is beneficial because it speeds up lookups, joins, and parent table integrity checks, reducing full-table scans and lock contention.

--2.3: View Index Information

SELECT 
	tablename,
	indexname,
	indexdef
FROM pg_indexes
WHERE schemaname ='public'
ORDER BY tablename, indexname;

--List all indexes u see. Which ones created automatically?
--departments_pkey, dept_summary_mv_dept_id_idx, emp_dept_idx, emp_salary_idx, employees_pkey, projects_pkey
--Created automatically:
--departments_pkey
--dept_summary_mv_dept_id_idx (unique constraint(уникальное ограничение))
--employees_pkey
--projects_pkey

--PART 3: Multicolumn Indexes

--3.1: Create a Multicolumn Index

CREATE INDEX emp_dept_salary_idx ON employees(dept_id, salary);

SELECT emp_name, salary
FROM employees
WHERE dept_id = 101 AND salary > 52000;

--Would this index be useful for a query that only filters by salary (without
--dept_id)? Why or why not?

--NO, The index is sorted first by dept_id, so the database cannot directly jump to the right salary values without scanning all dept_ids
--For a multicolumn index (A, B):
--Useful for queries filtering on:
--A
--A and B
--Not very useful for queries filtering only on B.

--3.2: Understanding Column Order

CREATE INDEX emp_salary_dept_idx ON employees(salary, dept_id);
--This index is sorted first by salary, and then by dept_id within each salary.
SELECT* FROM employees WHERE dept_id = 102 AND salary > 50000;

SELECT* FROM employees WHERE salary > 50000 AND dept_id = 102;

--The order of columns in a multicolumn index matters a lot.
--

--PART 4:Unique Indexes
--4.1:Create a Unique Index

ALTER TABLE employees ADD COLUMN email VARCHAR(100);

UPDATE employees SET email= 'john.smith@company.com' WHERE emp_id = 1;
UPDATE employees SET email = 'jane.doe@company.com' WHERE emp_id = 2;
UPDATE employees SET email = 'mike.johnson@company.com' WHERE emp_id = 3;
UPDATE employees SET email = 'sarah.williams@company.com' WHERE emp_id = 4;
UPDATE employees SET email = 'tom.brown@company.com' WHERE emp_id = 5;

CREATE UNIQUE INDEX emp_email_unique_idx ON employees(email);

INSERT INTO employees (emp_id , emp_name , dept_id , salary , email) 
VALUES (6, 'New Employee' , 101 , 55000 , 'john.smith@company.com');

--What error message did you receive?
--повторяющееся значение ключа нарушает ограничение уникальности "employees_pkey"
--Ключ "(emp_id)=(6)" уже существует. 
--The unique index emp_email_unique_idx ensures that no two rows can have the same email.
--Attempting to insert 'john.smith@company.com' again violates this constraint, so the database raises an error and cancels the insert. (чекаем на юник)

--4.2: Unique Index vs UNIQUE Constraint

ALTER TABLE employees ADD COLUMN phone VARCHAR(20) UNIQUE;

SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'employees' AND indexname LIKE '%phone%';

--Did PostgreSQL automatically create an index? What type of index?
--Yes, bcs postrgresql automatically creates an index when u add a unique constraint.
--type of index btree(тип индекса по умолчанию)

--PART 5: Indexes and Sorting

--5.1: Create an Index for Sorting

CREATE INDEX emp_salary_desc_idx ON employees(salary DESC); 

SELECT emp_name, salary
FROM employees
ORDER BY salary DESC;

--How does this index help with ORDER BY queries?
--The descending index pre-sorts data in the order your query needs.
--This allows PostgreSQL to skip a costly sort operation, making ORDER BY salary DESC queries faster, especially with large datasets or LIMIT clauses.

--5.2: Index with NULL Handling

CREATE INDEX proj_budget_nulls_first_idx ON projects(budget NULLS FIRST);

SELECT project_name, budget
FROM projects
ORDER BY budget NULLS FIRST;

--PART 6: Indexes on Expressions
--6.1: Create a Function-Based Index

CREATE INDEX emp_name_lower_idx ON employees(LOWER(emp_name));

SELECT * FROM employees WHERE LOWER(emp_name) = 'john smith';
--Without this index, how would PostgreSQL search for names case-insensitively?
--Without the function-based index, PostgreSQL must scan the whole table and apply the function to each row, which is slow.
--With the index, PostgreSQL can directly look up the lowercase value in the index, making the query much faster.

--6.2; Index on Calculated Values

ALTER TABLE employees ADD COLUMN hire_date DATE;

UPDATE employees SET hire_date = '2020-01-15' WHERE emp_id = 1;
UPDATE employees SET hire_date = '2019-06-20' WHERE emp_id = 2;
UPDATE employees SET hire_date = '2021-03-10' WHERE emp_id = 3;
UPDATE employees SET hire_date = '2020-11-05' WHERE emp_id = 4;
UPDATE employees SET hire_date = '2018-08-25' WHERE emp_id = 5;

CREATE INDEX emp_hire_year_idx ON employees(EXTRACT(YEAR FROM hire_date));

SELECT emp_name, hire_date
FROM employees
WHERE EXTRACT(YEAR FROM hire_date) = 2020;

--PART 7: Managing Indexes

--7.1: rENAME an Index

ALTER INDEX emp_salary_idx RENAME TO employees_salary_index;

SELECT indexname FROM pg_indexes WHERE tablename = 'employees';

--7.2: Drop Unused indexes

DROP INDEX emp_salary_dept_idx;

--Why might you want to drop an index? 

--You drop an index when it is unused, redundant, or negatively impacts write performance, to optimize storage, write speed, and maintenance overhead.

--7.3: Reindex

REINDEX INDEX employees_salary_index;
--When is REINDEX useful?
--• After bulk INSERT operations
--• When index becomes bloated
--• After significant data modifications

--PART 8: Practical Scenarios
--8.1 Optimize a Slow Query

SELECT e.emp_name, e.salary, d.dept_name
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
WHERE e.salary > 50000
ORDER BY e.salary DESC;

CREATE INDEX emp_salary_filter_idx ON employees(salary) WHERE salary > 50000;

--8.2 Partial Index
CREATE INDEX proj_high_budget_idx ON projects(budget)
WHERE budget > 80000;

SELECT project_name, budget
FROM projects
WHERE budget > 80000;

--A partial index is:
--Smaller
--Faster for queries matching the condition
--Less maintenance overhead
--Focused on important data

--8.3: Analyze Index Usage
EXPLAIN SELECT * FROM employees WHERE salary > 52000; --(чтобы проверить  используется ли индексы)

--Output is Seq Scan.
--PostgreSQL is scanning every row in the table.
--Applies the filter (salary > 52000) to each row.
--Can be slower for large tables, especially if only a few rows match.
--If you see Seq Scan, your index is not being used, possibly because:
--There is no suitable index on the column(s).
--PostgreSQL estimates that a sequential scan is cheaper.

--PART 9: Index Types Comparison
--9.1: Create a Hash Index

CREATE INDEX dept_name_hash_idx ON departments USING HASH (dept_name);
SELECT * FROM departments WHERE dept_name = 'IT';

-- When should you use a HASH index instead of a B-tree index?
--Equality comparisons only: = operator.
--High-cardinality columns: Many distinct values.
--Small, frequently queried tables where equality lookups are very common.

--9.2: Compare Index Types

CREATE INDEX project_name_btree_idx ON projects(project_name);

CREATE INDEX project_name_hash_idx ON projects USING HASH (project_name);

SELECT * FROM projects WHERE project_name = 'Website Redesign';

SELECT * FROM projects WHERE project_name > 'Database';

--PART 10: Cleanup and BEST practices
--10.1 : review all indexes

SELECT
 schemaname,
 tablename,
 indexname,
 pg_size_pretty(pg_relation_size(indexname::regclass)) as index_size
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

--the largest index is 32 dept_name_hash_idx and project_name_hash_idx

--10.2 : Drop Unnecessary indexes
DROP INDEX IF EXISTS project_name_hash_idx;

--10.3 Document ur indexes

CREATE VIEW index_documentation AS
SELECT
 tablename,
 indexname,
 indexdef,
 'Improves salary-based queries' as purpose
FROM pg_indexes
WHERE schemaname = 'public'
 AND indexname LIKE '%salary%';
SELECT * FROM index_documentation;

--Summary Questions
-- 1. What is the default index type in PostgreSQL?
-- B-tree

-- 2. Name three scenarios where you should create an index:
-- - Columns frequently used in WHERE conditions
-- - Columns used in JOIN conditions
-- - Columns used in ORDER BY or GROUP BY

-- 3. Name two scenarios where you should NOT create an index:
-- - Columns that are rarely queried
-- - Columns with low cardinality (мало уникальных значений)

-- 4. What happens to indexes when you INSERT, UPDATE, or DELETE data?
-- PostgreSQL automatically updates indexes; more indexes = slower writes

-- 5. How can you check if a query is using an index?
-- Use EXPLAIN; look for "Index Scan" instead of "Seq Scan"

-- Additional Challenges 

CREATE INDEX emp_hire_month_idx ON employees (EXTRACT(MONTH FROM hire_date));

CREATE UNIQUE INDEX emp_dept_email_unique_idx ON employees(dept_id, email);

EXPLAIN ANALYZE
SELECT * FROM employees WHERE salary > 50000;

CREATE INDEX emp_cover_idx ON employees(dept_id) INCLUDE (emp_name, salary);


-- Индексы ускоряют поиск, фильтрацию и сортировку данных.
-- Но каждый индекс замедляет вставку и обновление строк.
-- Поэтому индексы нужно создавать там, где они реально ускоряют запросы, и не делать лишних.

