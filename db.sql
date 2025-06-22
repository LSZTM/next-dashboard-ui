-- Database Schema for Student Information System

-- Schools Table: Stores information about each school.
CREATE TABLE schools (
    school_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL, -- Unique short code for the school
    district VARCHAR(50),
    address TEXT -- Added address for completeness, as per previous schema
);

-- Users Table: Manages user authentication and basic account details.
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL, -- User's unique email for login
    password_hash VARCHAR(255) NOT NULL, -- Hashed password for security
    is_active BOOLEAN DEFAULT TRUE NOT NULL, -- Account status: active (true) or disabled (false)
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP NOT NULL, -- Timestamp of account creation
    last_login TIMESTAMP WITH TIME ZONE -- Timestamp of the user's last login
);

-- User Profiles Table: Stores additional, non-authentication related user details.
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE, -- Ensures profile is deleted if user is
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20) -- User's primary phone number
);

-- Parents Table: Stores specific information for users designated as parents.
CREATE TABLE parents (
    parent_id UUID PRIMARY KEY,
    user_id UUID UNIQUE REFERENCES users(user_id) ON DELETE CASCADE, -- Links to user account, cascade delete
    family_code VARCHAR(20) UNIQUE -- Shared code for family members, useful for siblings
);

-- Parent Contacts Table: Holds additional contact information for parents.
-- Renamed 'is_primary' to 'is_emergency' for clarity and consistency with previous discussion.
CREATE TABLE parent_contacts (
    contact_id UUID PRIMARY KEY,
    parent_id UUID NOT NULL REFERENCES parents(parent_id) ON DELETE CASCADE, -- Links contact to a parent, cascade delete
    phone VARCHAR(20) NOT NULL,
    relationship VARCHAR(50), -- e.g., 'Mother', 'Father', 'Grandparent', 'Emergency Contact'
    is_emergency BOOLEAN DEFAULT FALSE NOT NULL -- Flag for emergency contact
);

-- Students Table: Stores core information about each student.
CREATE TABLE students (
    student_id UUID PRIMARY KEY,
    parent_id UUID NOT NULL REFERENCES parents(parent_id) ON DELETE RESTRICT, -- A student must have a parent; restrict deletion of parent if student exists
    date_of_birth DATE NOT NULL,
    legal_name VARCHAR(100) NOT NULL -- Full legal name of the student
);

-- Student Enrollments Table: Manages a student's enrollment at a specific school.
CREATE TABLE student_enrollments (
    enrollment_id UUID PRIMARY KEY,
    student_id UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE, -- Enrollment depends on student, cascade delete
    school_id UUID NOT NULL REFERENCES schools(school_id) ON DELETE RESTRICT, -- Enrollment depends on school, restrict deletion of school if enrollments exist
    student_code VARCHAR(20) NOT NULL, -- Unique code assigned by the specific school for this enrollment
    start_date DATE NOT NULL,
    end_date DATE, -- Can be NULL if currently enrolled
    grade_level VARCHAR(10), -- e.g., 'KG', '1st', '12th'
    UNIQUE(school_id, student_code) -- Ensures unique student code within each school
);

-- School Subjects Table: Defines academic subjects offered at schools.
CREATE TABLE school_subjects (
    subject_id UUID PRIMARY KEY,
    school_id UUID NOT NULL REFERENCES schools(school_id) ON DELETE CASCADE, -- Subjects are school-specific, cascade delete
    subject_code VARCHAR(10) NOT NULL, -- Short, unique code for the subject within the school
    name VARCHAR(100) NOT NULL, -- Full name of the subject
    UNIQUE(school_id, subject_code) -- Ensures unique subject code within each school
);

-- School Classes Table: Defines academic classes offered at schools.
CREATE TABLE school_classes (
    class_id UUID PRIMARY KEY,
    school_id UUID NOT NULL REFERENCES schools(school_id) ON DELETE CASCADE, -- Classes are school-specific, cascade delete
    class_name VARCHAR(50) NOT NULL, -- Name of the class (e.g., 'Grade 5 A', 'Science Lab 1')
    academic_year VARCHAR(9) NOT NULL -- e.g., '2024-2025'
);

-- Attendance Table: Records student attendance.
CREATE TABLE attendance (
    attendance_id UUID PRIMARY KEY,
    enrollment_id UUID NOT NULL REFERENCES student_enrollments(enrollment_id) ON DELETE CASCADE, -- Links attendance to a specific enrollment
    attendance_date DATE NOT NULL, -- Renamed 'date' to 'attendance_date' to avoid keyword conflict
    status VARCHAR(20) NOT NULL -- e.g., 'Present', 'Absent', 'Tardy', 'Excused Absent'
);

-- Course Grades Table: Stores grades received by students for subjects.
CREATE TABLE course_grades (
    grade_id UUID PRIMARY KEY,
    enrollment_id UUID NOT NULL REFERENCES student_enrollments(enrollment_id) ON DELETE CASCADE, -- Links grade to a specific enrollment
    subject_id UUID NOT NULL REFERENCES school_subjects(subject_id) ON DELETE RESTRICT, -- Links grade to a specific subject; restrict deletion of subject if grades exist
    term VARCHAR(20), -- e.g., 'Fall Semester', 'Q1'
    grade DECIMAL(5,2) -- Numerical grade (e.g., 92.50, 78.00)
);
