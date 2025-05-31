--PRUEBAS INDIVIDUALES DE LAS FUNCIONES

-- Caso 1: Usuario vÃ¡lido
BEGIN
  IF pkg_admin_productos.f_verificar_cuenta_usuario(1) THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (vÃ¡lido): OK');
  ELSE
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (vÃ¡lido): acceso denegado');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (vÃ¡lido): ERROR - ' || SQLERRM);
END;
/

-- Caso 2: Usuario invÃ¡lido
BEGIN
  IF pkg_admin_productos.f_verificar_cuenta_usuario(9999) THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (invÃ¡lido): ERROR - acceso concedido incorrectamente');
  ELSE
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (invÃ¡lido): acceso correctamente denegado');
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('f_verificar_cuenta_usuario (invÃ¡lido): ERROR - ' || SQLERRM);
END;
/

-- Cuenta vÃ¡lida con plan
BEGIN
  DECLARE
    v_plan plan%ROWTYPE;
  BEGIN
    v_plan := pkg_admin_productos.f_obtener_plan_cuenta(1);
    DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (vÃ¡lida): OK - Plan ID: ' || v_plan.id);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_obtener_plan_cuenta (vÃ¡lida): ERROR - ' || SQLERRM);
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


-- Producto con atributos completos
BEGIN
  DECLARE
    v_ok BOOLEAN;
  BEGIN
    v_ok := pkg_admin_productos.f_validar_atributos_producto(128, 1);
    DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (completo): Resultado: ' || 
                         CASE WHEN v_ok THEN 'TRUE (todos los atributos tienen valor)' 
                              ELSE 'FALSE (faltan atributos)' END);
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
    DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (inexistente): Resultado inesperado: ' || 
                         CASE WHEN v_ok THEN 'TRUE' ELSE 'FALSE' END);
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (inexistente): OK - Error esperado (producto no encontrado)');
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_validar_atributos_producto (inexistente): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta con categorÃ­as
BEGIN
  DECLARE
    v_cat NUMBER;
  BEGIN
    v_cat := pkg_admin_productos.f_num_categorias_cuenta(1);
    DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (con categorÃ­as): OK - Total: ' || v_cat);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (con categorÃ­as): ERROR - ' || SQLERRM);
  END;
END;
/

-- Cuenta sin categorÃ­as
BEGIN
  DECLARE
    v_cat NUMBER;
  BEGIN
    v_cat := pkg_admin_productos.f_num_categorias_cuenta(9999);
    DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (sin categorÃ­as): Total: ' || v_cat);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_num_categorias_cuenta (sin categorÃ­as): ERROR - ' || SQLERRM);
  END;
END;
/

-- Prueba para f_lista_categorias_producto
BEGIN
  DECLARE
    v_lista VARCHAR2(1000);
  BEGIN
    v_lista := pkg_admin_productos_avanzado.f_lista_categorias_producto(26, 1);
    DBMS_OUTPUT.PUT_LINE('f_lista_categorias_producto (producto existente): OK - CategorÃ­as: ' || v_lista);
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_lista_categorias_producto (producto existente): ERROR - ' || SQLERRM);
  END;
END;
/

-- Prueba para f_lista_categorias_producto con producto inexistente
BEGIN
  DECLARE
    v_lista VARCHAR2(1000);
  BEGIN
    v_lista := pkg_admin_productos_avanzado.f_lista_categorias_producto(9999, 1);
    IF v_lista = 'Sin categoría' THEN
      DBMS_OUTPUT.PUT_LINE('f_lista_categorias_producto (producto inexistente): OK - Retornó "Sin categoría" como esperado');
    ELSE
      DBMS_OUTPUT.PUT_LINE('f_lista_categorias_producto (producto inexistente): Resultado inesperado: ' || v_lista);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('f_lista_categorias_producto (producto inexistente): ERROR - ' || SQLERRM);
  END;
END;
/

-- Caso 1: ActualizaciÃ³n vÃ¡lida
BEGIN
  pkg_admin_productos.p_actualizar_nombre_producto(128, 1, 'Nombre Actualizado');
  DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (vÃ¡lido): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_actualizar_nombre_producto (vÃ¡lido): ERROR - ' || SQLERRM);
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

-- Caso 1: AsociaciÃ³n vÃ¡lida
BEGIN
  pkg_admin_productos.p_asociar_activo_a_producto(128, 1, 502, 1);
  DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (vÃ¡lido): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_asociar_activo_a_producto (vÃ¡lido): ERROR - ' || SQLERRM);
END;
/

-- Caso 2: AsociaciÃ³n duplicada
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

-- Prueba para p_migrar_productos_a_categoria
BEGIN
  -- Asume que existen las categorÃ­as 1 y 2 en la cuenta 1
  pkg_admin_productos_avanzado.p_migrar_productos_a_categoria(1, 1, 2);
  DBMS_OUTPUT.PUT_LINE('p_migrar_productos_a_categoria (vÃ¡lido): OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_migrar_productos_a_categoria (vÃ¡lido): ERROR - ' || SQLERRM);
END;
/

-- Prueba para p_migrar_productos_a_categoria con categorÃ­a no existente
BEGIN
  pkg_admin_productos_avanzado.p_migrar_productos_a_categoria(1, 999, 998);
  DBMS_OUTPUT.PUT_LINE('p_migrar_productos_a_categoria (categorÃ­as no existentes): ERROR - Se esperaba error');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_migrar_productos_a_categoria (categorÃ­as no existentes): OK - Error controlado: ' || SQLERRM);
END;
/

-- Caso 1: Actualizar Producto
BEGIN
  pkg_admin_productos.p_actualizar_productos(1);
  DBMS_OUTPUT.PUT_LINE('p_actualizar_productos: OK');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('p_actualizar_productos: ERROR - ' || SQLERRM);
END;
/

-- Caso 1: Usuario Nuevo
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
    p_rol      => 'ROL_CLIENTE', -- Rol debe ser especificado
    p_password => 'Test1234'
  );

  DBMS_OUTPUT.PUT_LINE('Usuario creado correctamente.');

EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('ERROR: ' || SQLERRM);
END;
/