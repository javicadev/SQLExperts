-- Administración de bases de datos 24/25. Practica Triggers
-- Javier Carrasco Delgado

-- 1. Creamos tablas
CREATE TABLE MENSAJES (
    Codigo NUMBER(20) PRIMARY KEY,
    Texto VARCHAR2(200)
);

CREATE TABLE AUDITA_MENSAJES (
    Quien VARCHAR2(20),
    Como VARCHAR2(20),
    Cuando DATE
);

-- Trigger a nivel de sentencia para auditar INSERT, UPDATE y DELETE sobre MENSAJES
CREATE OR REPLACE TRIGGER TR_AUDITA_MENSAJES
AFTER INSERT OR UPDATE OR DELETE ON MENSAJES
DECLARE
    v_usuario VARCHAR2(20) := USER;
    v_operacion VARCHAR2(20);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
    END IF;

    INSERT INTO AUDITA_MENSAJES (Quien, Como, Cuando)
    VALUES (v_usuario, v_operacion, SYSDATE);
END;
/

-- 2. añadimos TIPO a MENSAJES
ALTER TABLE MENSAJES ADD TIPO VARCHAR2(20) 
    CHECK (TIPO IN ('INFORMACION', 'RESTRICCION', 'ERROR', 'AVISO', 'AYUDA'));

-- Tabla auxiliar para contar cuántos mensajes hay de cada tipo y su último mensaje
CREATE TABLE MENSAJES_INFO (
    Tipo VARCHAR2(30) PRIMARY KEY,
    Cuantos_Mensajes NUMBER(2),
    Ultimo VARCHAR2(200)
);

-- Trigger tras insertar en MENSAJES para actualizar MENSAJES_INFO
CREATE OR REPLACE TRIGGER TR_INS_MENSAJES
AFTER INSERT ON MENSAJES
FOR EACH ROW
BEGIN
    MERGE INTO MENSAJES_INFO m
    USING (SELECT :NEW.TIPO AS TIPO, :NEW.TEXTO AS TEXTO FROM dual) src
    ON (m.TIPO = src.TIPO)
    WHEN MATCHED THEN
        UPDATE SET m.Cuantos_Mensajes = m.Cuantos_Mensajes + 1,
                   m.Ultimo = src.TEXTO
    WHEN NOT MATCHED THEN
        INSERT (TIPO, Cuantos_Mensajes, Ultimo)
        VALUES (src.TIPO, 1, src.TEXTO);
END;
/

-- Trigger tras borrar en MENSAJES para actualizar MENSAJES_INFO
CREATE OR REPLACE TRIGGER TR_DEL_MENSAJES
AFTER DELETE ON MENSAJES
FOR EACH ROW
BEGIN
    UPDATE MENSAJES_INFO
    SET Cuantos_Mensajes = Cuantos_Mensajes - 1,
        Ultimo = NULL
    WHERE Tipo = :OLD.TIPO;
END;
/

-- 3. Separar MENSAJES en dos tablas: MENSAJES_TEXTO y MENSAJES_TIPO
CREATE TABLE MENSAJES_TEXTO (
    Codigo NUMBER(20) PRIMARY KEY,
    Texto VARCHAR2(200)
);

CREATE TABLE MENSAJES_TIPO (
    Codigo NUMBER(20) PRIMARY KEY,
    Tipo VARCHAR2(20),
    CONSTRAINT fk_tipo FOREIGN KEY (Codigo) REFERENCES MENSAJES_TEXTO (Codigo)
);

-- Vista unificada para consultas
CREATE OR REPLACE VIEW MENSAJES AS
SELECT t.Codigo, t.Texto, tp.Tipo
FROM MENSAJES_TEXTO t
JOIN MENSAJES_TIPO tp ON t.Codigo = tp.Codigo;

-- Nota: No se puede hacer INSERT directamente sobre la vista MENSAJES a menos que uses un INSTEAD OF TRIGGER

-- 4. Crear tabla MENSAJES_BORRADOS
CREATE TABLE MENSAJES_BORRADOS (
    Codigo NUMBER(20),
    Texto VARCHAR2(200),
    Tipo VARCHAR2(20),
    Fecha_Borrado DATE DEFAULT SYSDATE
);

-- Trigger que guarda los borrados de MENSAJES_TEXTO en MENSAJES_BORRADOS
CREATE OR REPLACE TRIGGER TR_BORRA_MENSAJES
BEFORE DELETE ON MENSAJES_TEXTO
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(20);
BEGIN
    SELECT Tipo INTO v_tipo FROM MENSAJES_TIPO WHERE Codigo = :OLD.Codigo;

    INSERT INTO MENSAJES_BORRADOS (Codigo, Texto, Tipo)
    VALUES (:OLD.Codigo, :OLD.Texto, v_tipo);
END;
/

-- 5. Crear un trabajo programado para borrar MENSAJES_BORRADOS cada 2 minutos
BEGIN
    DBMS_SCHEDULER.CREATE_JOB (
        job_name        => 'BORRA_MENSAJES_ANTIGUOS',
        job_type        => 'PLSQL_BLOCK',
        job_action      => '
            BEGIN
                DELETE FROM MENSAJES_BORRADOS
                WHERE Fecha_Borrado < SYSTIMESTAMP - NUMTODSINTERVAL(2, 'MINUTE');
            END;',
        start_date      => SYSTIMESTAMP,
        repeat_interval => 'FREQ=MINUTELY;INTERVAL=2',
        enabled         => TRUE
    );
END;
/

