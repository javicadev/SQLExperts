--Muestra todos los triggers
SELECT trigger_name AS "Nombre del Trigger"
FROM user_triggers
ORDER BY trigger_name;

-- Muestra todos los jobs
SELECT job_name AS "NOMBRE"
FROM user_scheduler_jobs
ORDER BY job_name;

--Muestra todos los procedimientos
SELECT object_name AS "NOMBRE"
FROM user_procedures
WHERE object_type = 'PROCEDURE'
ORDER BY object_name;

--Muestra todas las funciones
SELECT object_name AS "NOMBRE"
FROM user_procedures
WHERE object_type = 'FUNCTION'
ORDER BY object_name;

--Mostrar todos los tablespaces
SELECT tablespace_name AS "NOMBRE"
FROM user_tablespaces
ORDER BY tablespace_name;

--Mostrar los indices
SELECT 
    index_name AS "NOMBRE",
    index_type AS "TIPO",
    CASE 
        WHEN uniqueness = 'UNIQUE' THEN 'Único'
        ELSE 'No único'
    END AS "UNICIDAD"
FROM user_indexes
ORDER BY table_name, index_name;

--Muesta todas las vistas
SELECT view_name AS "NOMBRE"
FROM user_views
ORDER BY view_name;

--Muesta todas las vistas materializadas
SELECT mview_name AS "NOMBRE"
FROM user_mviews
ORDER BY mview_name;

--Muesta todos los paquetes
SELECT object_name AS "NOMBRE"
FROM user_objects
WHERE object_type = 'PACKAGE'
ORDER BY object_name;

