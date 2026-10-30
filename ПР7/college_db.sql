-- ============================================================
-- Практическая работа: Создание таблиц и базы данных
-- Информационная система «Колледж»
-- Студент: Казакбиев Даниял Махачевич
-- ============================================================

-- ============================================================
-- 0. Создание пользователя
-- ============================================================

CREATE USER kazakbiev WITH PASSWORD 'secret1';

-- ============================================================
-- 1. Создание базы данных
-- ============================================================

-- Удаляем базу данных, если она уже существует (с осторожностью!)
-- DROP DATABASE IF EXISTS kazakbiev_bd;

CREATE DATABASE kazakbiev_bd
    ENCODING = 'UTF8';

GRANT ALL PRIVILEGES ON DATABASE kazakbiev_bd TO kazakbiev;

-- ============================================================
-- 2. Подключение к базе данных
-- ============================================================

-- В psql используется команда: \c kazakbiev_bd
-- В скрипте эта команда не выполняется, подключение нужно делать отдельно.

-- ============================================================
-- 3. Создание таблиц
-- ============================================================

-- Таблица "Группы"
CREATE TABLE IF NOT EXISTS groups (
    group_id SERIAL PRIMARY KEY,
    group_name VARCHAR(20) NOT NULL UNIQUE,
    specialty VARCHAR(100) NOT NULL,
    admission_year INTEGER NOT NULL
);

-- Таблица "Студенты"
CREATE TABLE IF NOT EXISTS students (
    student_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    birth_date DATE NOT NULL,
    group_id INTEGER NOT NULL,

    CONSTRAINT fk_students_groups
        FOREIGN KEY (group_id)
        REFERENCES groups(group_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE
);

-- Таблица "Преподаватели"
CREATE TABLE IF NOT EXISTS teachers (
    teacher_id SERIAL PRIMARY KEY,
    last_name VARCHAR(50) NOT NULL,
    first_name VARCHAR(50) NOT NULL,
    department VARCHAR(100) NOT NULL
);

-- Таблица "Дисциплины"
CREATE TABLE IF NOT EXISTS disciplines (
    discipline_id SERIAL PRIMARY KEY,
    discipline_name VARCHAR(100) NOT NULL UNIQUE,
    hours INTEGER NOT NULL CHECK (hours > 0)
);

-- Таблица "Занятия"
CREATE TABLE IF NOT EXISTS lessons (
    lesson_id SERIAL PRIMARY KEY,
    group_id INTEGER NOT NULL,
    discipline_id INTEGER NOT NULL,
    teacher_id INTEGER NOT NULL,
    lesson_date DATE NOT NULL,
    lesson_type VARCHAR(30) NOT NULL,

    CONSTRAINT fk_lessons_groups
        FOREIGN KEY (group_id)
        REFERENCES groups(group_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_lessons_disciplines
        FOREIGN KEY (discipline_id)
        REFERENCES disciplines(discipline_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT,

    CONSTRAINT fk_lessons_teachers
        FOREIGN KEY (teacher_id)
        REFERENCES teachers(teacher_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- Дополнительная таблица "Оценки" (для домашнего задания)
CREATE TABLE IF NOT EXISTS grades (
    grade_id SERIAL PRIMARY KEY,
    student_id INTEGER NOT NULL,
    discipline_id INTEGER NOT NULL,
    grade INTEGER NOT NULL CHECK (grade BETWEEN 2 AND 5),
    grade_date DATE NOT NULL,

    CONSTRAINT fk_grades_students
        FOREIGN KEY (student_id)
        REFERENCES students(student_id)
        ON UPDATE CASCADE
        ON DELETE CASCADE,

    CONSTRAINT fk_grades_disciplines
        FOREIGN KEY (discipline_id)
        REFERENCES disciplines(discipline_id)
        ON UPDATE CASCADE
        ON DELETE RESTRICT
);

-- ============================================================
-- 4. Заполнение таблиц данными
-- ============================================================

-- Группы
INSERT INTO groups (group_name, specialty, admission_year) VALUES
    ('П-21', 'Программирование', 2026),
    ('ИС-22', 'Информационные системы', 2026),
    ('ЭК-21', 'Экономика', 2026);

-- Студенты
INSERT INTO students (last_name, first_name, middle_name, birth_date, group_id) VALUES
    ('Иванов', 'Иван', 'Иванович', '2007-03-15', 1),
    ('Петров', 'Алексей', 'Сергеевич', '2007-07-21', 1),
    ('Сидорова', 'Анна', 'Игоревна', '2006-11-04', 2),
    ('Кузнецов', 'Максим', 'Олегович', '2007-01-18', 2),
    ('Смирнова', 'Елена', 'Андреевна', '2006-09-27', 3);

-- Преподаватели
INSERT INTO teachers (last_name, first_name, department) VALUES
    ('Волков', 'Александр', 'Информационные технологии'),
    ('Орлова', 'Мария', 'Общеобразовательные дисциплины'),
    ('Фёдоров', 'Дмитрий', 'Программирование');

-- Дисциплины
INSERT INTO disciplines (discipline_name, hours) VALUES
    ('Основы проектирования баз данных', 72),
    ('Информационные технологии', 72),
    ('Программирование', 144),
    ('Компьютерные сети', 72);

-- Занятия
INSERT INTO lessons (group_id, discipline_id, teacher_id, lesson_date, lesson_type) VALUES
    (1, 1, 1, '2026-09-10', 'Лекция'),
    (1, 3, 3, '2026-09-11', 'Практика'),
    (2, 1, 1, '2026-09-10', 'Практика'),
    (2, 2, 2, '2026-09-12', 'Лекция'),
    (3, 2, 2, '2026-09-13', 'Практика');

-- ============================================================
-- 5. Тестовые запросы
-- ============================================================

-- Список всех студентов с названиями групп
SELECT
    s.student_id,
    s.last_name || ' ' || s.first_name AS full_name,
    g.group_name,
    g.specialty
FROM students s
JOIN groups g ON s.group_id = g.group_id
ORDER BY g.group_name, s.last_name;

-- Количество студентов в каждой группе
SELECT
    g.group_name,
    COUNT(s.student_id) AS student_count
FROM groups g
LEFT JOIN students s ON g.group_id = s.group_id
GROUP BY g.group_id, g.group_name
ORDER BY g.group_name;

-- Расписание занятий (дата, группа, дисциплина, преподаватель, вид занятия)
SELECT
    l.lesson_date,
    g.group_name,
    d.discipline_name,
    t.last_name || ' ' || t.first_name AS teacher_name,
    l.lesson_type
FROM lessons l
JOIN groups g ON l.group_id = g.group_id
JOIN disciplines d ON l.discipline_id = d.discipline_id
JOIN teachers t ON l.teacher_id = t.teacher_id
ORDER BY l.lesson_date;

-- Список дисциплин с количеством часов
SELECT
    discipline_name,
    hours
FROM disciplines
ORDER BY hours DESC;

-- ============================================================
-- 6. Дополнительное задание (оценки)
-- ============================================================

-- Добавляем оценки для студентов
INSERT INTO grades (student_id, discipline_id, grade, grade_date) VALUES
    (1, 1, 5, '2026-09-15'),
    (1, 3, 4, '2026-09-16'),
    (2, 1, 3, '2026-09-15'),
    (2, 3, 5, '2026-09-16'),
    (3, 1, 4, '2026-09-17'),
    (3, 2, 5, '2026-09-18'),
    (4, 2, 4, '2026-09-18'),
    (4, 1, 3, '2026-09-19'),
    (5, 2, 5, '2026-09-20'),
    (5, 1, 4, '2026-09-21');

-- Средний балл по дисциплинам
SELECT
    d.discipline_name,
    AVG(g.grade) AS average_grade
FROM grades g
JOIN disciplines d ON g.discipline_id = d.discipline_id
GROUP BY d.discipline_name
ORDER BY average_grade DESC;
