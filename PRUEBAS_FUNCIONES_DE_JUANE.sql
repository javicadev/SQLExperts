



-- Caso 1: Actualización válida
BEGIN
  pkg_admin_productos.p_actualizar_nombre_producto(128, 1, 'Nombre Actualizado');
  DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (válido): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (válido): ERROR - ' || SQLERRM);
END;
/


-- Caso 2: Nombre nulo
BEGIN
  pkg_admin_productos.p_actualizar_nombre_producto(128, 1, NULL);
  DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (nulo): ERROR - Se esperaba error por nombre nulo');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (nulo): OK - Error controlado: ' || SQLERRM);
END;
/

-- Caso 1: Actualizar Producto ---- PRUEBA JAVI DESDE TU ORDENADOR
BEGIN
  pkg_admin_productos.p_actualizar_productos(1);
  DBMS_OUTPUT.PUT_LINE('p_actualizar_productos: OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_actualizar_productos: ERROR - ' || SQLERRM);
END;
/


-- Caso 1: Asociación válida
BEGIN
  pkg_admin_productos.p_asociar_activo_a_producto(186, 1, 505, 1);
  DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (válido): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (válido): ERROR - ' || SQLERRM);
END;
/

-- Caso 2: Asociación duplicada --- EJECUTAR DESPUÉS DEL DE ARRIBA
BEGIN
  pkg_admin_productos.p_asociar_activo_a_producto(128, 1, 501, 1);
  DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (duplicada): ERROR - Se esperaba error por duplicado');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (duplicada): OK - Error controlado: ' || SQLERRM);
END;