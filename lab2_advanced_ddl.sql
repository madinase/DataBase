--Task 1.1

CREATE DATABASE university_main
TEMPLATE = template0
ENCODING = 'UTF8';

CREATE DATABASE university_archive
CONNECTION LIMIT = 50
TEMPLATE = template0;

CREATE DATABASE university_test
TEMPLATE = template0
CONNECTION LIMIT = 10;

ALTER DATABASE university_test
WITH IS_TEMPLATE = TRUE;

CREATE TABLESPACE student_data
LOCATION '/data/students';

CREATE TABLESPACE course_data
LOCATION '/data/courses';

CREATE DATABASE university_distributed
TABLESPACE = student_data
ENCODING = 'LATIN9';


--Task 2.1

CREATE TABLE students (
student_id SERIAL PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
email VARCHAR(100),
phone CHAR(15),
date_of_birth DATE,
enrollment_date DATE,
gpa NUMERIC(4,2),
is_active BOOLEAN,
graduation_year SMALLINT
);

CREATE TABLE professors (
professor_id SERIAL PRIMARY KEY,
first_name VARCHAR(50),
last_name VARCHAR(50),
email VARCHAR(100),
office_number VARCHAR(20),
hire_date DATE,
salary DECIMAL(10,2),
is_tenured BOOLEAN,
years_experience INT
);

CREATE TABLE courses (
course_id SERIAL PRIMARY KEY,	
course_code CHAR(8),
course_title VARCHAR(100),	
description TEXT,	
credits SMALLINT,	
max_enrollment INTEGER,	
course_fee DECIMAL(10,2),
is_online BOOLEAN,	
created_at TIMESTAMP
);

--Task 2.2

CREATE TABLE class_schedule (
    schedule_id SERIAL PRIMARY KEY,
    course_id INTEGER,
    professor_id INTEGER,
    classroom VARCHAR(20),
    class_date DATE,
    start_time TIME,
    end_time TIME,
    duration INTERVAL
);

CREATE TABLE student_records (
    record_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    course_id INTEGER,
    semester VARCHAR(20),
    year INTEGER,
    grade CHAR(2),
    attendance_percentage DECIMAL(4,1),
    submission_timestamp TIMESTAMPTZ,
    last_updated TIMESTAMPTZ
);


--Task 3.1

ALTER TABLE students
    ADD COLUMN middle_name VARCHAR(30),
    ADD COLUMN student_status VARCHAR(20) DEFAULT 'ACTIVE',
    ALTER COLUMN phone TYPE VARCHAR(20),
    ALTER COLUMN gpa SET DEFAULT 0.00;

ALTER TABLE professors
    ADD COLUMN department_code CHAR(5),
    ADD COLUMN research_area TEXT,
    ADD COLUMN last_promotion_date DATE,
    ALTER COLUMN years_experience TYPE SMALLINT,
    ALTER COLUMN is_tenured SET DEFAULT false;

ALTER TABLE courses
    ADD COLUMN prerequisite_course_id INTEGER,
    ADD COLUMN difficulty_level SMALLINT,
    ADD COLUMN lab_required BOOLEAN DEFAULT false,
    ALTER COLUMN course_code TYPE VARCHAR(10),
    ALTER COLUMN credits SET DEFAULT 3;

--Task 3.2

ALTER TABLE class_schedule
    ADD COLUMN room_capacity INTEGER,
    DROP COLUMN duration,
    ADD COLUMN session_type VARCHAR(15),
    ALTER COLUMN classroom TYPE VARCHAR(30),
    ADD COLUMN equipment_needed TEXT;

ALTER TABLE student_records
    ADD COLUMN extra_credit_points DECIMAL(4,1) DEFAULT 0.0,
    ALTER COLUMN grade TYPE VARCHAR(5),
    ADD COLUMN final_exam_date DATE,
    DROP COLUMN last_updated;

--Task 4.1

CREATE TABLE departments (
    department_id SERIAL PRIMARY KEY,
    department_name VARCHAR(100),
    department_code CHAR(5),
    building VARCHAR(50),
    phone VARCHAR(15),
    budget DECIMAL(12,2),
    established_year INTEGER
);


CREATE TABLE library_books (
    book_id SERIAL PRIMARY KEY,
    isbn CHAR(13),
    title VARCHAR(200),
    author VARCHAR(100),
    publisher VARCHAR(100),
    publication_date DATE,
    price DECIMAL(8,2),
    is_available BOOLEAN,
    acquisition_timestamp TIMESTAMP
);


CREATE TABLE student_book_loans (
    loan_id SERIAL PRIMARY KEY,
    student_id INTEGER,
    book_id INTEGER,
    loan_date DATE,
    due_date DATE,
    return_date DATE,
    fine_amount DECIMAL(8,2),
    loan_status VARCHAR(20)
);

--Task 4.2

ALTER TABLE professors
    ADD COLUMN department_id INTEGER;

ALTER TABLE students
    ADD COLUMN advisor_id INTEGER;

ALTER TABLE courses
    ADD COLUMN department_id INTEGER;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2)
);

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);

--Task 5.1

DROP TABLE IF EXISTS student_book_loans;
DROP TABLE IF EXISTS library_books;
DROP TABLE IF EXISTS grade_scale;

CREATE TABLE grade_scale (
    grade_id SERIAL PRIMARY KEY,
    letter_grade CHAR(2),
    min_percentage DECIMAL(4,1),
    max_percentage DECIMAL(4,1),
    gpa_points DECIMAL(3,2),
    description TEXT
);

DROP TABLE IF EXISTS semester_calendar CASCADE;

CREATE TABLE semester_calendar (
    semester_id SERIAL PRIMARY KEY,
    semester_name VARCHAR(20),
    academic_year INTEGER,
    start_date DATE,
    end_date DATE,
    registration_deadline TIMESTAMPTZ,
    is_current BOOLEAN
);

--Task 5.2
DROP DATABASE IF EXISTS university_test;
DROP DATABASE IF EXISTS university_distributed;

CREATE DATABASE university_backup
TEMPLATE university_main;



