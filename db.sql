-- ============================================================================
-- Student Information System - Database Schema
-- Created: 2025-06-20
-- Version: 1.2
-- PostgreSQL Compatible with 'IF NOT EXISTS' protection
-- ============================================================================

-- Enable UUID generation (safe)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================================
-- 1. CORE TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS users (
    user_id        UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email          VARCHAR(255) UNIQUE NOT NULL,
    password_hash  VARCHAR(255) NOT NULL,
    is_active      BOOLEAN NOT NULL DEFAULT TRUE,
    created_at     TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login     TIMESTAMP
);

CREATE TABLE IF NOT EXISTS user_profiles (
    user_id     UUID PRIMARY KEY REFERENCES users(user_id) ON DELETE CASCADE,
    first_name  VARCHAR(50) NOT NULL,
    last_name   VARCHAR(50) NOT NULL,
    phone       VARCHAR(20) NOT NULL,
    updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS schools (
    school_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name          VARCHAR(100) NOT NULL,
    code          VARCHAR(10) UNIQUE NOT NULL,
    district      VARCHAR(50) NOT NULL,
    address       TEXT NOT NULL,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 2. PARENT MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS parents (
    parent_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id      UUID UNIQUE NOT NULL REFERENCES users(user_id) ON DELETE CASCADE,
    family_code  VARCHAR(20) NOT NULL
);

CREATE TABLE IF NOT EXISTS parent_contacts (
    contact_id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id     UUID NOT NULL REFERENCES parents(parent_id) ON DELETE CASCADE,
    phone         VARCHAR(20) NOT NULL,
    relationship  VARCHAR(20) NOT NULL CHECK (relationship IN ('Mother', 'Father', 'Grandparent', 'Guardian', 'Other')),
    is_emergency  BOOLEAN NOT NULL DEFAULT FALSE,
    created_at    TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ============================================================================
-- 3. STUDENT MANAGEMENT
-- ============================================================================

CREATE TABLE IF NOT EXISTS students (
    student_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    parent_id      UUID NOT NULL REFERENCES parents(parent_id) ON DELETE RESTRICT,
    date_of_birth  DATE NOT NULL,
    legal_name     VARCHAR(100) NOT NULL,
    created_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS student_enrollments (
    enrollment_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    student_id      UUID NOT NULL REFERENCES students(student_id) ON DELETE CASCADE,
    school_id       UUID NOT NULL REFERENCES schools(school_id) ON DELETE RESTRICT,
    student_code    VARCHAR(20) NOT NULL,
    start_date      DATE NOT NULL,
    end_date        DATE,
    grade_level     VARCHAR(10) NOT NULL CHECK (grade_level IN ('KG', '1st', '2nd', '3rd', '4th', '5th', '6th', '7th', '8th', '9th', '10th', '11th', '12th')),
    created_at      TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uniq_student_school_code UNIQUE (school_id, student_code),
    CONSTRAINT chk_valid_dates CHECK (end_date IS NULL OR end_date > start_date)
);

-- ============================================================================
-- 4. ACADEMIC STRUCTURE
-- ============================================================================

CREATE TABLE IF NOT EXISTS school_subjects (
    subject_id     UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id      UUID NOT NULL REFERENCES schools(school_id) ON DELETE CASCADE,
    subject_code   VARCHAR(10) NOT NULL,
    name           VARCHAR(100) NOT NULL,
    CONSTRAINT uniq_subject_code_per_school UNIQUE (school_id, subject_code)
);

CREATE TABLE IF NOT EXISTS school_classes (
    class_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    school_id      UUID NOT NULL REFERENCES schools(school_id) ON DELETE CASCADE,
    class_name     VARCHAR(50) NOT NULL,
    academic_year  VARCHAR(9) NOT NULL CHECK (academic_year ~ '^\d{4}-\d{4}$'),
    subject_id     UUID REFERENCES school_subjects(subject_id) ON DELETE SET NULL
);

-- ============================================================================
-- 5. OPERATIONAL TABLES
-- ============================================================================

CREATE TABLE IF NOT EXISTS attendance (
    attendance_id   UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id   UUID NOT NULL REFERENCES student_enrollments(enrollment_id) ON DELETE CASCADE,
    date            DATE NOT NULL,
    status          VARCHAR(20) NOT NULL CHECK (status IN ('Present', 'Absent', 'Tardy', 'Excused Absent')),
    CONSTRAINT uniq_attendance_record UNIQUE (enrollment_id, date)
);

CREATE TABLE IF NOT EXISTS course_grades (
    grade_id       UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    enrollment_id  UUID NOT NULL REFERENCES student_enrollments(enrollment_id) ON DELETE CASCADE,
    subject_id     UUID NOT NULL REFERENCES school_subjects(subject_id) ON DELETE CASCADE,
    term           VARCHAR(10) NOT NULL,
    grade          DECIMAL(5,2) NOT NULL CHECK (grade BETWEEN 0 AND 100),
    CONSTRAINT uniq_grade_entry UNIQUE (enrollment_id, subject_id, term)
);

-- ============================================================================
-- 6. PERFORMANCE INDEXES
-- ============================================================================

DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_family_code           ON parents(family_code);
    CREATE INDEX IF NOT EXISTS idx_student_by_parent     ON students(parent_id);
    CREATE INDEX IF NOT EXISTS idx_enrollments_student   ON student_enrollments(student_id);
    CREATE INDEX IF NOT EXISTS idx_enrollments_school    ON student_enrollments(school_id);
    CREATE INDEX IF NOT EXISTS idx_attendance_by_date    ON attendance(date);
    CREATE INDEX IF NOT EXISTS idx_grades_by_term        ON course_grades(term);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Index may already exist or creation skipped: %', SQLERRM;
END
$$;

-- ============================================================================
-- 7. COMMENTS (Safe Blocked)
-- ============================================================================

DO $$
BEGIN
    -- Safe comments to avoid failure if tables missing
    PERFORM 1 FROM pg_tables WHERE tablename = 'schools';
    IF FOUND THEN
        COMMENT ON TABLE schools IS 'Stores metadata for educational institutions.';
        COMMENT ON COLUMN schools.code IS 'Short, unique institutional code (e.g., SCH-001).';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'users';
    IF FOUND THEN
        COMMENT ON TABLE users IS 'Handles login credentials and user account status.';
        COMMENT ON COLUMN users.password_hash IS 'BCrypt hashed password.';
        COMMENT ON COLUMN users.is_active IS 'Flag indicating account availability.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'user_profiles';
    IF FOUND THEN
        COMMENT ON TABLE user_profiles IS 'Non-authentication personal details of users.';
        COMMENT ON COLUMN user_profiles.user_id IS '1:1 relation with users table.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'parents';
    IF FOUND THEN
        COMMENT ON TABLE parents IS 'Links users to their role as student guardians.';
        COMMENT ON COLUMN parents.family_code IS 'Shared identifier across siblings.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'parent_contacts';
    IF FOUND THEN
        COMMENT ON TABLE parent_contacts IS 'Stores parent contact and emergency details.';
        COMMENT ON COLUMN parent_contacts.is_emergency IS 'Flag for emergency contact (true/false).';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'students';
    IF FOUND THEN
        COMMENT ON TABLE students IS 'Student demographic and guardian mapping.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'student_enrollments';
    IF FOUND THEN
        COMMENT ON TABLE student_enrollments IS 'Tracks students’ school-wise enrollment history.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'school_subjects';
    IF FOUND THEN
        COMMENT ON TABLE school_subjects IS 'Maintains the subject catalog for each school.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'school_classes';
    IF FOUND THEN
        COMMENT ON TABLE school_classes IS 'Academic class definitions per school and year.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'attendance';
    IF FOUND THEN
        COMMENT ON TABLE attendance IS 'Student daily attendance logs.';
        COMMENT ON COLUMN attendance.status IS 'Standardized attendance values.';
    END IF;

    PERFORM 1 FROM pg_tables WHERE tablename = 'course_grades';
    IF FOUND THEN
        COMMENT ON TABLE course_grades IS 'Stores subject-wise performance per term.';
    END IF;
END
$$;

-- ============================================================================
-- 8. RELATIONSHIPS & CAPABILITIES
-- ============================================================================
/*
RELATIONSHIPS:
- parents → students (1:N)
- students → student_enrollments (1:N)
- schools → student_enrollments (1:N)
- student_enrollments → course_grades (1:N)
- schools → school_subjects, school_classes (1:N)

CAPABILITIES:
✔ Multiple students per parent
✔ School-specific student codes
✔ Grade history & term tracking
✔ Emergency contact structure
✔ Validated academic years
✔ Normalized and optimized schema
*/
