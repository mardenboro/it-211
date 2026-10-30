-- ============================================================
-- Практическая работа: анализ данных с помощью SQL-запросов
-- База данных «Колледж» (kazakbiev_bd), студент: Казакбиев Даниял Махачевич
-- Перед запуском выполните college_db.sql (таблицы, данные, таблица оценок).
-- Команды, которые по заданию должны завершиться ошибкой, заключены в блоки DO ...
-- EXCEPTION: ошибка выводится как сообщение (NOTICE), и скрипт выполняется до конца.
-- Роли teacher_role / student_role и пользователи — общие для сервера: при повторном
-- запуске раздела 8 сначала удалите их (DROP ROLE).
-- ============================================================


-- ============================================================
-- 1. Анализ данных с помощью SQL-запросов
-- ============================================================

-- Список всех студентов с названиями их групп
SELECT
    s.student_id,
    s.last_name || ' ' || s.first_name || ' ' || COALESCE(s.middle_name, '') AS ФИО,
    g.group_name AS группа,
    g.specialty AS специальность
FROM students s
JOIN groups g ON s.group_id = g.group_id
ORDER BY g.group_name, s.last_name;

-- Количество студентов в каждой группе
SELECT
    g.group_name AS группа,
    COUNT(s.student_id) AS количество_студентов
FROM groups g
LEFT JOIN students s ON g.group_id = s.group_id
GROUP BY g.group_id, g.group_name
ORDER BY g.group_name;

-- Расписание занятий с полной информацией
SELECT
    l.lesson_date AS дата,
    g.group_name AS группа,
    d.discipline_name AS дисциплина,
    t.last_name || ' ' || t.first_name AS преподаватель,
    l.lesson_type AS вид_занятия
FROM lessons l
JOIN groups g ON l.group_id = g.group_id
JOIN disciplines d ON l.discipline_id = d.discipline_id
JOIN teachers t ON l.teacher_id = t.teacher_id
ORDER BY l.lesson_date, g.group_name;

-- Нагрузка преподавателей (количество занятий)
SELECT
    t.last_name || ' ' || t.first_name AS преподаватель,
    t.department AS кафедра,
    COUNT(l.lesson_id) AS количество_занятий
FROM teachers t
LEFT JOIN lessons l ON t.teacher_id = l.teacher_id
GROUP BY t.teacher_id, t.last_name, t.first_name, t.department
ORDER BY количество_занятий DESC;

-- Студенты, родившиеся после 2007 года
SELECT
    last_name || ' ' || first_name AS ФИО,
    birth_date AS дата_рождения
FROM students
WHERE birth_date > '2007-01-01'
ORDER BY birth_date;

-- Дисциплины с количеством часов больше 72
SELECT
    discipline_name AS дисциплина,
    hours AS часы
FROM disciplines
WHERE hours > 72
ORDER BY hours DESC;

-- Группы, в которых больше одного студента
SELECT
    g.group_name AS группа,
    COUNT(s.student_id) AS количество_студентов
FROM groups g
JOIN students s ON g.group_id = s.group_id
GROUP BY g.group_id, g.group_name
HAVING COUNT(s.student_id) > 1
ORDER BY g.group_name;

-- Средняя нагрузка на преподавателя
SELECT
    ROUND(AVG(занятий), 2) AS среднее_количество_занятий
FROM (
    SELECT
        teacher_id,
        COUNT(lesson_id) AS занятий
    FROM lessons
    GROUP BY teacher_id
) AS subquery;

-- Список групп и специальностей (без дубликатов)
SELECT DISTINCT specialty AS специальность
FROM groups
ORDER BY специальность;

-- Студенты и их группы (с использованием подзапроса)
SELECT
    s.last_name || ' ' || s.first_name AS студент,
    (SELECT g.group_name FROM groups g WHERE g.group_id = s.group_id) AS группа
FROM students s
ORDER BY s.last_name;


-- ============================================================
-- 2. Проверка ограничений целостности (практические эксперименты)
-- ============================================================

-- Вставка группы с существующим group_id (нарушение первичного ключа)
DO $$
BEGIN
    -- Попробуем вставить группу с существующим group_id
    INSERT INTO groups (group_id, group_name, specialty, admission_year)
    VALUES (1, 'Новая группа', 'Тест', 2026);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;

-- Вставка студента без фамилии (нарушение NOT NULL)
DO $$
BEGIN
    -- Попробуем вставить студента без фамилии
    INSERT INTO students (first_name, birth_date, group_id)
    VALUES ('Иван', '2007-01-01', 1);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;

-- Изменение типа данных столбца
-- Изменим тип данных для столбца middle_name (увеличим длину)
ALTER TABLE students ALTER COLUMN middle_name TYPE VARCHAR(100);

-- Вставка группы с существующим названием (нарушение UNIQUE)
DO $$
BEGIN
    -- Попробуем вставить группу с существующим названием
    INSERT INTO groups (group_name, specialty, admission_year)
    VALUES ('П-21', 'Другая специальность', 2026);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;

-- Переименование столбца и возврат обратно
-- Переименуем столбец department в teachers
ALTER TABLE teachers RENAME COLUMN department TO kafedra;

-- Вернём обратно
ALTER TABLE teachers RENAME COLUMN kafedra TO department;

-- Добавление и удаление столбца
-- Добавим временный столбец
ALTER TABLE teachers ADD COLUMN temp_column VARCHAR(50);

-- Удалим его
ALTER TABLE teachers DROP COLUMN temp_column;

-- Добавление ограничения CHECK на год поступления
-- Добавим ограничение CHECK на год поступления
ALTER TABLE groups ADD CONSTRAINT chk_admission_year
    CHECK (admission_year BETWEEN 2000 AND 2100);


-- ============================================================
-- 3. Работа с транзакциями (TCL)
-- ============================================================

-- Транзакция с фиксацией (COMMIT)
BEGIN TRANSACTION;

-- Переводим студента из одной группы в другую
UPDATE students SET group_id = 2 WHERE student_id = 1;
UPDATE groups SET group_name = 'П-21 (обновлена)' WHERE group_id = 1;

-- Если всё хорошо — фиксируем
COMMIT;

-- Проверяем
SELECT * FROM students WHERE student_id = 1;

-- Транзакция с откатом (ROLLBACK)
BEGIN TRANSACTION;

-- Пытаемся удалить всех студентов
DELETE FROM students;

-- Проверяем (внутри транзакции)
SELECT COUNT(*) FROM students;  -- 0

-- Откатываем изменения
ROLLBACK;

-- Проверяем после отката
SELECT COUNT(*) FROM students;  -- 5 (данные восстановлены)

-- Точка сохранения (SAVEPOINT)
BEGIN TRANSACTION;

INSERT INTO groups (group_name, specialty, admission_year)
VALUES ('ВРЕМ-01', 'Временная', 2026);

SAVEPOINT sp1;

INSERT INTO groups (group_name, specialty, admission_year)
VALUES ('ВРЕМ-02', 'Временная', 2026);

-- Откатываемся только к SAVEPOINT (ВРЕМ-02 не будет добавлена)
ROLLBACK TO SAVEPOINT sp1;

-- Фиксируем (ВРЕМ-01 останется)
COMMIT;

SELECT * FROM groups WHERE group_name LIKE 'ВРЕМ%';

-- Возврат исходных данных после экспериментов с транзакциями
UPDATE groups SET group_name = 'П-21' WHERE group_id = 1;
UPDATE students SET group_id = 1 WHERE student_id = 1;
DELETE FROM groups WHERE group_name LIKE 'ВРЕМ%';

SELECT * FROM groups ORDER BY group_id;


-- ============================================================
-- 4. Создание представлений (VIEW)
-- ============================================================

-- Создание представления v_students_with_groups
CREATE VIEW v_students_with_groups AS
SELECT
    s.student_id,
    s.last_name || ' ' || s.first_name AS full_name,
    s.birth_date,
    g.group_name,
    g.specialty
FROM students s
JOIN groups g ON s.group_id = g.group_id;

-- Выборка из представления
SELECT * FROM v_students_with_groups WHERE group_name = 'П-21';

-- Удаление представления
DROP VIEW v_students_with_groups;


-- ============================================================
-- 5. Создание индексов
-- ============================================================

-- Создание индексов
-- Индекс по фамилии студента (ускоряет поиск по фамилии)
CREATE INDEX idx_students_last_name ON students(last_name);

-- Индекс по дате занятия (ускоряет поиск по дате)
CREATE INDEX idx_lessons_date ON lessons(lesson_date);

-- План выполнения запроса (EXPLAIN ANALYZE)
EXPLAIN ANALYZE
SELECT * FROM students WHERE last_name = 'Иванов';

-- Удаление индексов
DROP INDEX idx_students_last_name;
DROP INDEX idx_lessons_date;


-- ============================================================
-- 6. Таблица «Оценки» (grades) и аналитические запросы
-- ============================================================

-- Таблица grades и 10 оценок
-- Таблица grades и 10 оценок созданы в college_db.sql (практическая работа №7). Проверка:
SELECT * FROM grades ORDER BY grade_id;

-- Средний балл по студентам
SELECT
    s.last_name || ' ' || s.first_name AS студент,
    ROUND(AVG(g.grade), 2) AS средний_балл
FROM grades g
JOIN students s ON g.student_id = s.student_id
GROUP BY s.student_id, s.last_name, s.first_name
ORDER BY средний_балл DESC;

-- Средний балл по дисциплинам
SELECT
    d.discipline_name AS дисциплина,
    ROUND(AVG(g.grade), 2) AS средний_балл,
    COUNT(g.grade_id) AS количество_оценок
FROM grades g
JOIN disciplines d ON g.discipline_id = d.discipline_id
GROUP BY d.discipline_id, d.discipline_name
ORDER BY средний_балл DESC;

-- Оценки ниже 4
SELECT
    s.last_name || ' ' || s.first_name AS студент,
    d.discipline_name AS дисциплина,
    g.grade AS оценка,
    g.grade_date AS дата
FROM grades g
JOIN students s ON g.student_id = s.student_id
JOIN disciplines d ON g.discipline_id = d.discipline_id
WHERE g.grade < 4
ORDER BY g.grade, s.last_name;

-- Лучшие студенты (средний балл > 4.5) — самостоятельно
SELECT
    s.last_name || ' ' || s.first_name AS студент,
    ROUND(AVG(g.grade), 2) AS средний_балл
FROM grades g
JOIN students s ON g.student_id = s.student_id
GROUP BY s.student_id, s.last_name, s.first_name
HAVING AVG(g.grade) > 4.5
ORDER BY средний_балл DESC;


-- ============================================================
-- 7. Триггеры
-- ============================================================

-- Таблица аудита audit_log
CREATE TABLE audit_log (
    log_id SERIAL PRIMARY KEY,
    table_name VARCHAR(50),
    operation VARCHAR(10),
    record_id INT,
    old_data JSONB,
    new_data JSONB,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT CURRENT_USER
);

-- Функция и триггер аудита студентов
CREATE OR REPLACE FUNCTION audit_students_changes()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        INSERT INTO audit_log (table_name, operation, record_id, new_data)
        VALUES ('students', 'INSERT', NEW.student_id, to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'UPDATE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data, new_data)
        VALUES ('students', 'UPDATE', NEW.student_id, to_jsonb(OLD), to_jsonb(NEW));
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO audit_log (table_name, operation, record_id, old_data)
        VALUES ('students', 'DELETE', OLD.student_id, to_jsonb(OLD));
        RETURN OLD;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_students_audit
AFTER INSERT OR UPDATE OR DELETE ON students
FOR EACH ROW EXECUTE FUNCTION audit_students_changes();

-- Проверка триггера аудита
-- Вставляем студента
INSERT INTO students (last_name, first_name, birth_date, group_id)
VALUES ('Новиков', 'Пётр', '2007-05-05', 1);

-- Обновляем
UPDATE students SET first_name = 'Петр' WHERE last_name = 'Новиков';

-- Удаляем
DELETE FROM students WHERE last_name = 'Новиков';

-- Смотрим аудит
SELECT log_id, table_name, operation, record_id, old_data->>'first_name' AS old_first_name,
       new_data->>'first_name' AS new_first_name, changed_by
FROM audit_log ORDER BY log_id;

-- Триггер проверки диапазона оценок
CREATE OR REPLACE FUNCTION check_grade_range()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.grade < 2 OR NEW.grade > 5 THEN
        RAISE EXCEPTION 'Оценка должна быть от 2 до 5, получено: %', NEW.grade;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_check_grade
BEFORE INSERT OR UPDATE ON grades
FOR EACH ROW EXECUTE FUNCTION check_grade_range();

-- Проверка триггера оценок (оценка 6)
DO $$
BEGIN
    INSERT INTO grades (student_id, discipline_id, grade, grade_date)
    VALUES (1, 1, 6, '2026-09-22');
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;


-- ============================================================
-- 8. Разграничение прав доступа (DCL)
-- ============================================================

-- Создание ролей и пользователей
-- Создаём роли
CREATE ROLE teacher_role;
CREATE ROLE student_role;

-- Создаём пользователей
CREATE USER teacher_ivanov WITH PASSWORD 'secure_password_1';
CREATE USER student_petrov WITH PASSWORD 'secure_password_2';

-- Назначаем роли
GRANT teacher_role TO teacher_ivanov;
GRANT student_role TO student_petrov;

-- Предоставление прав
-- Преподаватель может читать студентов и занятия
GRANT SELECT ON students TO teacher_role;
GRANT SELECT ON lessons TO teacher_role;
GRANT SELECT ON groups TO teacher_role;
GRANT SELECT ON disciplines TO teacher_role;

-- Студент может читать только свои оценки (через представление)
CREATE VIEW v_my_grades AS
SELECT
    gr.grade_id,
    s.student_id,
    d.discipline_name,
    gr.grade,
    gr.grade_date
FROM grades gr
JOIN students s ON gr.student_id = s.student_id
JOIN disciplines d ON gr.discipline_id = d.discipline_id;

GRANT SELECT ON v_my_grades TO student_role;

-- Проверка прав студента (роль student_role)
SET ROLE student_role;
SELECT * FROM v_my_grades ORDER BY grade_id LIMIT 3;
RESET ROLE;

-- Студент не может читать таблицу students напрямую
SET ROLE student_role;
DO $$
BEGIN
    PERFORM * FROM students;
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Ожидаемая ошибка: %', SQLERRM;
END $$;
RESET ROLE;
