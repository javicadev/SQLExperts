--PRUEBAS INDIVIDUALES DE LAS FUNCIONES

-- Caso 1: Usuario válido
BEGIN
  IF pkg_admin_productos.f_verificar_cuenta_usuario(1) THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (válido): OK');
  ELSE
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (válido): acceso denegado');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (válido): ERROR - ' || SQLERRM);
END;
/

-- Caso 2: Usuario inválido
BEGIN
  IF pkg_admin_productos.f_verificar_cuenta_usuario(9999) THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (inválido): ERROR - acceso concedido incorrectamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (inválido): acceso correctamente denegado');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (inválido): ERROR - ' || SQLERRM);
END;
/

-- Cuenta válida con plan
BEGIN
  DECLARE
    v_plan plan%ROWTYPE;
  BEGIN
    v_plan := pkg_admin_productos.f_obtener_plan_cuenta(1);
    DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (válida): OK - Plan ID: ' || v_plan.id);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (válida): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta inexistente
BEGIN
  DECLARE
    v_plan plan%ROWTYPE;
  BEGIN
    v_plan := pkg_admin_productos.f_obtener_plan_cuenta(9999);
    DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (inexistente): inesperado');
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (inexistente): OK - ' || SQLERRM);
  END;
END;
/

-- Cuenta con productos
BEGIN
  DECLARE
    v_total NUMBER;
  BEGIN
    v_total := pkg_admin_productos.f_contar_productos_cuenta(1);
    DBMS_OUTPUT.PUT_LINE('f_contar_productos_cuenta (con productos): OK - Total: ' || v_total);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_contar_productos_cuenta (con productos): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta sin productos
BEGIN
  DECLARE
    v_total NUMBER;
  BEGIN
    v_total := pkg_admin_productos.f_contar_productos_cuenta(9999);
    DBMS_OUTPUT.PUT_LINE('f_contar_productos_cuenta (sin productos): Total: ' || v_total);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_contar_productos_cuenta (sin productos): ERROR - ' || SQLERRM);
  END;
END;
/

-- Producto con atributos completos ---- FALTA POR METER DATOS EN LA TABLA ATRIBUTOS PRODUCTO
BEGIN
  DECLARE
    v_ok BOOLEAN;
  BEGIN
    v_ok := pkg_admin_productos.f_validar_atributos_producto(128, 1);
    DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (completo): Resultado: ' || CASE WHEN v_ok THEN 'TRUE' ELSE 'FALSE' END);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (completo): ERROR - ' || SQLERRM);
  END;
END;
/

-- Producto inexistente
BEGIN
  DECLARE
    v_ok BOOLEAN;
  BEGIN
    v_ok := pkg_admin_productos.f_validar_atributos_producto(9999, 1);
    DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (inexistente): Resultado: ' || CASE WHEN v_ok THEN 'TRUE' ELSE 'FALSE' END);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (inexistente): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta con categorías
BEGIN
  DECLARE
    v_cat NUMBER;
  BEGIN
    v_cat := pkg_admin_productos.f_num_categorias_cuenta(1);
    DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (con categorías): OK - Total: ' || v_cat);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (con categorías): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta sin categorías----
BEGIN
  DECLARE
    v_cat NUMBER;
  BEGIN
    v_cat := pkg_admin_productos.f_num_categorias_cuenta(9999);
    DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (sin categorías): Total: ' || v_cat);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (sin categorías): ERROR - ' || SQLERRM);
  END;
END;
/


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

-- Caso 1: Asociación válida
BEGIN
  pkg_admin_productos.p_asociar_activo_a_producto(128, 1, 502, 1);
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
/

-- Caso 1: Producto existente
BEGIN
  pkg_admin_productos.p_eliminar_producto_y_asociaciones(128, 1);
  DBMS_OUTPUT.PUT_LINE('p_eliminar_producto_y_asociaciones (existe): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_eliminar_producto_y_asociaciones (existe): ERROR - ' || SQLERRM);
END;
/

-- Caso 2: Producto inexistente
BEGIN
  pkg_admin_productos.p_eliminar_producto_y_asociaciones(9999, 1);
  DBMS_OUTPUT.PUT_LINE('p_eliminar_producto_y_asociaciones (no existe): ERROR - Se esperaba error por producto inexistente');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_eliminar_producto_y_asociaciones (no existe): OK - Error controlado: ' || SQLERRM);
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

-- Caso 1: Usuario Nuevo --- Fallo con los permisos de create user

DECLARE
  v_usuario usuario%ROWTYPE;
BEGIN
  -- Asignar valores
  v_usuario.id := 999;
  v_usuario.nombreusuario := 'usrtest';
  v_usuario.nombrecompleto := 'Usuario de Prueba';
  v_usuario.avatar := NULL;
  v_usuario.correoelectronico := 'prueba@correo.com';
  v_usuario.telefono := 600000000;
  v_usuario.cuentaid := 1;
  v_usuario.cuentadueno := 1;

  -- Llamada al procedimiento
  pkg_admin_productos.p_crear_usuario(
    p_usuario  => v_usuario,
    p_rol      => '',
    p_password => 'Test1234'
  );

  DBMS_OUTPUT.PUT_LINE('Usuario creado correctamente.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/



