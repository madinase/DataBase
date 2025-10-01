--PART A

DROP DATABASE IF EXISTS advanced_lab;
CREATE DATABASE advanced_lab;

CREATE TABLE IF NOT EXISTS employees (
emp_id SERIAL PRIMARY KEY,
first_name VARCHAR(100),
last_name VARCHAR(100),
department VARCHAR(100),
salary INT,
hire_date DATE,
status VARCHAR(50) DEFAULT 'Active'
);

CREATE TABLE IF NOT EXISTS departments (
dept_id SERIAL PRIMARY KEY,
dept_name VARCHAR(100),
budget INT,
manager_id INT
);

CREATE TABLE IF NOT EXISTS projects (
project_id SERIAL PRIMARY KEY,
project_name VARCHAR(100),
dept_id INT,
start_date DATE,
end_date DATE,
budjet INT
);

--PART B

INSERT INTO employees (first_name , last_name , department)
VALUES ('John' , 'Doe' , 'IT');

INSERT INTO employees (first_name , last_name) 
VALUES ('Alice' , 'Smith');

INSERT INTO departments (dept_name , budget , manager_id)
VALUES
  ('IT' , 200000 , 1),
  ('HR' , 100000 , 2),
  ('Sales' , 150000 , 3);

INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bob', 'Taylor', 'Finance', 50000 * 1.1, CURRENT_DATE);

CREATE TEMP TABLE temp_employees AS
SELECT * FROM employees WHERE department = 'IT';

--PART C

--UPDATE with arithmetic
UPDATE employees SET salary = salary * 1.1;

--UPDATE with conditions
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000 AND hire_date < '2020-01-01';

--UPDATE with CASE
UPDATE employees
SET department = CASE
    WHEN salary > 80000 THEN 'Management'
    WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
    ELSE 'Junior'
END;

--UPDATE with DEFAULT
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

--UPDATE with subquery
UPDATE departments d
SET budget = (
    SELECT AVG(salary) * 1.2
    FROM employees e
    WHERE e.department = d.dept_name
);

--UPDATE multiple columns
UPDATE employees
SET salary = salary * 1.15,
    status = 'Promoted'
WHERE department = 'Sales';

--PART D

--DELETE simple
DELETE FROM employees WHERE status = 'Terminated';

--DELETE with complex WHERE
DELETE FROM employees
WHERE salary < 40000 AND hire_date > '2023-01-01' AND department IS NULL;

--DELETE with subquery
DELETE FROM departments
WHERE dept_name NOT IN (
    SELECT DISTINCT department
    FROM employees
    WHERE department IS NOT NULL
);

--DELETE with RETURNING
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;


--Part E


--INSERT with NULLs
INSERT INTO employees (first_name, last_name, salary, department)
VALUES ('NullGuy', 'Test', NULL, NULL);

--UPDATE NULL handling
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

--DELETE with NULL conditions
DELETE FROM employees
WHERE salary IS NULL OR department IS NULL;

--PART F

--INSERT with RETURNING
INSERT INTO employees (first_name, last_name, department)
VALUES ('Eve', 'Johnson', 'IT')
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

--UPDATE with RETURNING
UPDATE employees
SET salary = salary + 5000
WHERE department = 'IT'
RETURNING emp_id, salary - 5000 AS old_salary, salary AS new_salary;

--DELETe with RETURNING all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;


--Part G


--Conditional INSERT (NOT EXISTS)
INSERT INTO employees (first_name, last_name, department)
SELECT 'Sam', 'Brown', 'HR'
WHERE NOT EXISTS (
    SELECT 1 FROM employees
    WHERE first_name = 'Sam' AND last_name = 'Brown'
);

--UPDATE with JOIN-like logic
UPDATE employees e
SET salary = salary * CASE
    WHEN (SELECT budget FROM departments d WHERE d.dept_name = e.department) > 100000
        THEN 1.10
    ELSE 1.05
END;

--Bulk operations
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES
 ('A1','Test','Sales',45000,CURRENT_DATE),
 ('A2','Test','Sales',46000,CURRENT_DATE),
 ('A3','Test','Sales',47000,CURRENT_DATE),
 ('A4','Test','Sales',48000,CURRENT_DATE),
 ('A5','Test','Sales',49000,CURRENT_DATE);

UPDATE employees
SET salary = salary * 1.10
WHERE last_name = 'Test';

--Data migration
CREATE TABLE employee_archive (LIKE employees INCLUDING ALL);

INSERT INTO employee_archive
SELECT * FROM employees WHERE status = 'Inactive';

DELETE FROM employees WHERE status = 'Inactive';

--Complex business logic
UPDATE projects
SET end_date = end_date + INTERVAL '30 days'
WHERE budget > 50000
AND dept_id IN (
    SELECT d.dept_id
    FROM departments d
    JOIN employees e ON e.department = d.dept_name
    GROUP BY d.dept_id
    HAVING COUNT(e.emp_id) > 3
);