-- =========================================
-- PRUEBAS PARA PKG_ADMIN_PRODUCTOS_AVANZADO - VERSIÓN CORREGIDA
-- =========================================

-- Verificar si el paquete avanzado existe y está válido
SELECT object_name, status 
FROM user_objects 
WHERE object_name = 'PKG_ADMIN_PRODUCTOS_AVANZADO';

-- Si no existe o no es válido, compilar primero el paquete desde PLYTIX.sql

-- =========================================
-- PRUEBAS PARA LAS FUNCIONES Y PROCEDIMIENTOS
-- =========================================

-- Prueba 1: F_VALIDAR_PLAN_SUFICIENTE
BEGIN
  DECLARE 
    v_result VARCHAR2(100);
    v_cuenta_id NUMBER := 1; -- Usar una cuenta existente
  BEGIN
    -- Primero verificar que la cuenta existe
    BEGIN
      SELECT 1 INTO v_cuenta_id FROM cuenta WHERE id = v_cuenta_id AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        v_cuenta_id := 1; -- Asignar un valor por defecto si no existe
    END;
    
    v_result := PKG_ADMIN_PRODUCTOS_AVANZADO.F_VALIDAR_PLAN_SUFICIENTE(v_cuenta_id);
    registrar_prueba('F_VALIDAR_PLAN_SUFICIENTE (cuenta '||v_cuenta_id||')', 'ÉXITO', 'Resultado: '||v_result);
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('F_VALIDAR_PLAN_SUFICIENTE', 'ERROR', SQLERRM);
  END;
END;
/

-- Prueba 2: F_LISTA_CATEGORIAS_PRODUCTO
BEGIN
  DECLARE 
    v_cat VARCHAR2(1000);
    v_producto_gtin producto.gtin%TYPE := 101; -- Usar un producto existente
    v_cuenta_id cuenta.id%TYPE := 1; -- Usar una cuenta existente
  BEGIN
    -- Verificar que el producto existe
    BEGIN
      SELECT 1 INTO v_cuenta_id 
      FROM producto 
      WHERE gtin = v_producto_gtin 
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Si no existe, usar valores por defecto
        v_producto_gtin := 101;
        v_cuenta_id := 1;
    END;
    
    v_cat := PKG_ADMIN_PRODUCTOS_AVANZADO.F_LISTA_CATEGORIAS_PRODUCTO(v_producto_gtin, v_cuenta_id);
    registrar_prueba('F_LISTA_CATEGORIAS_PRODUCTO (producto '||v_producto_gtin||')', 'ÉXITO', 'Categorías: '||v_cat);
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('F_LISTA_CATEGORIAS_PRODUCTO', 'ERROR', SQLERRM);
  END;
END;
/

-- Prueba 3: P_MIGRAR_PRODUCTOS_A_CATEGORIA
BEGIN
  DECLARE
    v_cuenta_id cuenta.id%TYPE := 1;
    v_cat_origen categoria.id%TYPE := 1;
    v_cat_destino categoria.id%TYPE := 2;
  BEGIN
    -- Verificar que las categorías existen
    BEGIN
      SELECT 1 INTO v_cuenta_id 
      FROM categoria 
      WHERE id = v_cat_origen 
      AND cuentaid = v_cuenta_id
      AND ROWNUM = 1;
      
      SELECT 1 INTO v_cuenta_id 
      FROM categoria 
      WHERE id = v_cat_destino 
      AND cuentaid = v_cuenta_id
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Si no existen, usar valores por defecto
        v_cat_origen := 1;
        v_cat_destino := 2;
    END;
    
    PKG_ADMIN_PRODUCTOS_AVANZADO.P_MIGRAR_PRODUCTOS_A_CATEGORIA(
      p_cuenta_id => v_cuenta_id,
      p_categoria_origen_id => v_cat_origen,
      p_categoria_destino_id => v_cat_destino
    );
    registrar_prueba('P_MIGRAR_PRODUCTOS_A_CATEGORIA', 'ÉXITO', 
                     'Migración de cat. '||v_cat_origen||' a '||v_cat_destino||' en cuenta '||v_cuenta_id);
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('P_MIGRAR_PRODUCTOS_A_CATEGORIA', 'ERROR', SQLERRM);
  END;
END;
/

-- Prueba 4: P_REPLICAR_ATRIBUTOS
BEGIN
  DECLARE
    v_cuenta_id cuenta.id%TYPE := 1;
    v_producto_origen producto.gtin%TYPE := 101;
    v_producto_destino producto.gtin%TYPE := 102;
  BEGIN
    -- Verificar que los productos existen
    BEGIN
      SELECT 1 INTO v_cuenta_id 
      FROM producto 
      WHERE gtin = v_producto_origen 
      AND cuentaid = v_cuenta_id
      AND ROWNUM = 1;
      
      SELECT 1 INTO v_cuenta_id 
      FROM producto 
      WHERE gtin = v_producto_destino 
      AND cuentaid = v_cuenta_id
      AND ROWNUM = 1;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- Si no existen, usar valores por defecto
        v_producto_origen := 101;
        v_producto_destino := 102;
    END;
    
    PKG_ADMIN_PRODUCTOS_AVANZADO.P_REPLICAR_ATRIBUTOS(
      p_cuenta_id => v_cuenta_id,
      p_producto_gtin_origen => v_producto_origen,
      p_producto_gtin_destino => v_producto_destino
    );
    registrar_prueba('P_REPLICAR_ATRIBUTOS', 'ÉXITO', 
                     'Atributos replicados de '||v_producto_origen||' a '||v_producto_destino);
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('P_REPLICAR_ATRIBUTOS', 'ERROR', SQLERRM);
  END;
END;
/

-- =============================================
-- PRUEBAS PARA JOBS
-- =============================================

-- Prueba 5: JOB J_LIMPIA_TRAZA
BEGIN
  -- Verificar si el job existe
  DECLARE
    v_job_exists NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_job_exists
    FROM user_scheduler_jobs
    WHERE job_name = 'J_LIMPIA_TRAZA';
    
    IF v_job_exists = 1 THEN
      DBMS_SCHEDULER.RUN_JOB(job_name => 'J_LIMPIA_TRAZA', use_current_session => TRUE);
      registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ÉXITO', 'Job ejecutado manualmente');
    ELSE
      registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ERROR', 'Job no existe');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ERROR', SQLERRM);
  END;
END;
/

-- Prueba 6: JOB J_ACTUALIZA_PRODUCTOS
BEGIN
  -- Verificar si el job existe
  DECLARE
    v_job_exists NUMBER;
  BEGIN
    SELECT COUNT(*) INTO v_job_exists
    FROM user_scheduler_jobs
    WHERE job_name = 'J_ACTUALIZA_PRODUCTOS';
    
    IF v_job_exists = 1 THEN
      DBMS_SCHEDULER.RUN_JOB(job_name => 'J_ACTUALIZA_PRODUCTOS', use_current_session => TRUE);
      registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ÉXITO', 'Job ejecutado manualmente');
    ELSE
      registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ERROR', 'Job no existe');
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ERROR', SQLERRM);
  END;
END;
/

-- Mostrar resultados de todas las pruebas
SELECT * FROM resultados_pruebas ORDER BY fecha DESC;