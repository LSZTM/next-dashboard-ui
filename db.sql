-- Schools
CREATE TABLE schools (
    school_id UUID PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    code VARCHAR(10) UNIQUE NOT NULL,
    district VARCHAR(50)
);

-- Users (Minimized)
CREATE TABLE users (
    user_id UUID PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- User Profiles
CREATE TABLE user_profiles (
    user_id UUID PRIMARY KEY REFERENCES users(user_id),
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL
);

-- Parents
CREATE TABLE parents (
    parent_id UUID PRIMARY KEY,
    user_id UUID UNIQUE REFERENCES users(user_id),
    family_code VARCHAR(20)
);

-- Parent Contacts
CREATE TABLE parent_contacts (
    contact_id UUID PRIMARY KEY,
    parent_id UUID REFERENCES parents(parent_id),
    phone VARCHAR(20) NOT NULL,
    relationship VARCHAR(20),
    is_primary BOOLEAN DEFAULT false
);

-- Students
CREATE TABLE students (
    student_id UUID PRIMARY KEY,
    parent_id UUID REFERENCES parents(parent_id),
    date_of_birth DATE NOT NULL,
    legal_name VARCHAR(100)
);

-- School Enrollment
CREATE TABLE student_enrollments (
    enrollment_id UUID PRIMARY KEY,
    student_id UUID REFERENCES students(student_id),
    school_id UUID REFERENCES schools(school_id),
    student_code VARCHAR(20) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE,
    grade_level VARCHAR(10),
    UNIQUE(school_id, student_code)
);

-- School Subjects
CREATE TABLE school_subjects (
    subject_id UUID PRIMARY KEY,
    school_id UUID REFERENCES schools(school_id),
    subject_code VARCHAR(10) NOT NULL,
    name VARCHAR(100) NOT NULL,
    UNIQUE(school_id, subject_code)
);

-- School Classes
CREATE TABLE school_classes (
    class_id UUID PRIMARY KEY,
    school_id UUID REFERENCES schools(school_id),
    class_name VARCHAR(50) NOT NULL,
    academic_year VARCHAR(9) NOT NULL
);
