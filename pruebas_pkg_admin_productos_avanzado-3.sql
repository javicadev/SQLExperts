
-- =========================================
-- PRUEBAS PARA PKG_ADMIN_PRODUCTOS_AVANZADO
-- =========================================

-- Ejecutar pruebas solo si ya existe la tabla resultados_pruebas y registrar_prueba

BEGIN
   -- Prueba de F_VALIDAR_PLAN_SUFICIENTE
   BEGIN
      DECLARE v_result VARCHAR2(100);
      BEGIN
         v_result := PKG_ADMIN_PRODUCTOS_AVANZADO.F_VALIDAR_PLAN_SUFICIENTE(101);
         registrar_prueba('F_VALIDAR_PLAN_SUFICIENTE', 'ÉXITO', v_result);
      EXCEPTION
         WHEN OTHERS THEN
            registrar_prueba('F_VALIDAR_PLAN_SUFICIENTE', 'ERROR', SQLERRM);
      END;
   END;

   -- Prueba de F_LISTA_CATEGORIAS_PRODUCTO
   BEGIN
      DECLARE v_cat VARCHAR2(1000);
      BEGIN
         v_cat := PKG_ADMIN_PRODUCTOS_AVANZADO.F_LISTA_CATEGORIAS_PRODUCTO('1234567890123', 101);
         registrar_prueba('F_LISTA_CATEGORIAS_PRODUCTO', 'ÉXITO', v_cat);
      EXCEPTION
         WHEN OTHERS THEN
            registrar_prueba('F_LISTA_CATEGORIAS_PRODUCTO', 'ERROR', SQLERRM);
      END;
   END;

   -- Prueba de P_MIGRAR_PRODUCTOS_A_CATEGORIA
   BEGIN
      BEGIN
         PKG_ADMIN_PRODUCTOS_AVANZADO.P_MIGRAR_PRODUCTOS_A_CATEGORIA(101, 1, 2);
         registrar_prueba('P_MIGRAR_PRODUCTOS_A_CATEGORIA', 'ÉXITO', 'Migración correcta');
      EXCEPTION
         WHEN OTHERS THEN
            registrar_prueba('P_MIGRAR_PRODUCTOS_A_CATEGORIA', 'ERROR', SQLERRM);
      END;
   END;

   -- Prueba de P_REPLICAR_ATRIBUTOS
   BEGIN
      BEGIN
         PKG_ADMIN_PRODUCTOS_AVANZADO.P_REPLICAR_ATRIBUTOS(101, '1234567890123', '3210987654321');
         registrar_prueba('P_REPLICAR_ATRIBUTOS', 'ÉXITO', 'Atributos replicados');
      EXCEPTION
         WHEN OTHERS THEN
            registrar_prueba('P_REPLICAR_ATRIBUTOS', 'ERROR', SQLERRM);
      END;
   END;
END;
/


-- =============================================
-- PRUEBAS PARA JOBS
-- =============================================

-- Forzar ejecución inmediata del job J_LIMPIA_TRAZA (simulación)
BEGIN
   DBMS_SCHEDULER.RUN_JOB(job_name => 'J_LIMPIA_TRAZA', use_current_session => TRUE);
   registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ÉXITO', 'Job ejecutado manualmente');
EXCEPTION
   WHEN OTHERS THEN
      registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ERROR', SQLERRM);
END;
/

-- Forzar ejecución inmediata del job J_ACTUALIZA_PRODUCTOS (simulación)
BEGIN
   DBMS_SCHEDULER.RUN_JOB(job_name => 'J_ACTUALIZA_PRODUCTOS', use_current_session => TRUE);
   registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ÉXITO', 'Job ejecutado manualmente');
EXCEPTION
   WHEN OTHERS THEN
      registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ERROR', SQLERRM);
END;
/



-- =========================================
-- PRUEBAS PARA JOBS EN PKG_ADMIN_PRODUCTOS_AVANZADO
-- =========================================

-- Ejecutar los JOBS manualmente (si están creados) y registrar resultado

BEGIN
   -- Lanzar JOB J_LIMPIA_TRAZA manualmente
   BEGIN
      DBMS_SCHEDULER.RUN_JOB('J_LIMPIA_TRAZA', TRUE);
      registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ÉXITO', 'Job ejecutado manualmente');
   EXCEPTION
      WHEN OTHERS THEN
         registrar_prueba('JOB - J_LIMPIA_TRAZA', 'ERROR', SQLERRM);
   END;

   -- Lanzar JOB J_ACTUALIZA_PRODUCTOS manualmente
   BEGIN
      DBMS_SCHEDULER.RUN_JOB('J_ACTUALIZA_PRODUCTOS', TRUE);
      registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ÉXITO', 'Job ejecutado manualmente');
   EXCEPTION
      WHEN OTHERS THEN
         registrar_prueba('JOB - J_ACTUALIZA_PRODUCTOS', 'ERROR', SQLERRM);
   END;
END;
/
