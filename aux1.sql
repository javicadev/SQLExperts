-- ESPECIFICACIÓN DEL PAQUETE
CREATE OR REPLACE PACKAGE pkg_admin_productos IS

  -- Excepciones personalizadas
  exception_plan_no_asignado      EXCEPTION;
  invalid_data                    EXCEPTION;
  exception_asociacion_duplicada EXCEPTION;

  -- Función de control de pertenencia
  FUNCTION f_verificar_cuenta_usuario (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN BOOLEAN;

  -- Funciones principales
  FUNCTION f_obtener_plan_cuenta (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN plan%ROWTYPE;

  FUNCTION f_contar_productos_cuenta (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN NUMBER;

  FUNCTION f_validar_atributos_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuentaid      IN producto.cuentaid%TYPE
  ) RETURN BOOLEAN;

  FUNCTION f_num_categorias_cuenta (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN NUMBER;

  -- Procedimientos principales
  PROCEDURE p_actualizar_nombre_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuentaid      IN producto.cuentaid%TYPE,
    p_nuevo_nombre  IN producto.nombre%TYPE
  );

  PROCEDURE p_asociar_activo_a_producto (
    p_producto_gtin      IN producto.gtin%TYPE,
    p_producto_cuentaid  IN producto.cuentaid%TYPE,
    p_activo_id          IN activo.id%TYPE,
    p_activo_cuentaid    IN activo.cuentaid%TYPE
  );

  PROCEDURE p_eliminar_producto_y_asociaciones (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuentaid      IN producto.cuentaid%TYPE
  );

  PROCEDURE p_actualizar_productos (
    p_cuentaid IN cuenta.id%TYPE
  );

  PROCEDURE p_crear_usuario (
    p_usuario  IN usuario%ROWTYPE,
    p_rol      IN VARCHAR2,
    p_password IN VARCHAR2
  );

END pkg_admin_productos;
/



-- AHORA DEBEMOS DESARROLLAR EL CUERPO DEL PAQUETE
create or replace package body pkg_admin_productos is

-- Función auxiliar que comprueba si el usuario actual pertenece a la cuenta indicada.
-- Si no pertenece, registra la traza y devuelve FALSE. Si sí pertenece, devuelve TRUE.
-- Esta función se usa como control de seguridad en todas las demás funciones y procedimientos.

FUNCTION f_verificar_cuenta_usuario (
  p_cuentaid IN cuenta.id%TYPE
) RETURN BOOLEAN IS
  v_dummy NUMBER;  -- Variable para verificar existencia
BEGIN
  -- Paso 1: Consultar la tabla USUARIO buscando que el usuario conectado (USER)
  -- tenga asignado el ID de cuenta que se pasa como parámetro
  SELECT 1 INTO v_dummy
  FROM usuario
  WHERE UPPER(nombreusuario) = UPPER(USER)
    AND cuentaid = p_cuentaid;

  -- Si encuentra una fila, es que pertenece a la cuenta
  RETURN TRUE;

EXCEPTION
  -- Si no hay coincidencia, el usuario no pertenece a esa cuenta
  WHEN NO_DATA_FOUND THEN
    INSERT INTO traza VALUES (
      SYSDATE, USER, $$PLSQL_UNIT,
      'Acceso denegado: el usuario no pertenece a la cuenta ' || p_cuentaid
    );
    RETURN FALSE;

  -- Otros errores (por ejemplo, fallo en la consulta)
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (
      SYSDATE, USER, $$PLSQL_UNIT,
      SQLCODE || ' ' || SQLERRM
    );
    RETURN FALSE;
END f_verificar_cuenta_usuario;

--F1: F_OBTENER_PLAN_CUENTA
-- Función que devuelve todo el registro del plan asociado a una cuenta.
-- Si no existe la cuenta o no tiene plan, lanza excepciones registrando en la traza.

FUNCTION f_obtener_plan_cuenta (
  p_cuentaid IN cuenta.id%TYPE
) RETURN plan%ROWTYPE IS
  v_plan   plan%ROWTYPE;           -- Variable para devolver el registro del plan
  v_planid cuenta.planid%TYPE;     -- ID del plan asociado a la cuenta
BEGIN
  -- Paso 0: Validar que el usuario pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Obtener planid de la cuenta
  SELECT planid INTO v_planid
  FROM cuenta
  WHERE id = p_cuentaid;

  -- Paso 2: Comprobar si tiene plan asignado
  IF v_planid IS NULL THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'La cuenta no tiene plan asignado');
    RAISE exception_plan_no_asignado;
  END IF;

  -- Paso 3: Devolver el registro completo del plan
  SELECT * INTO v_plan
  FROM plan
  WHERE id = v_planid;

  RETURN v_plan;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Cuenta o plan no encontrados');
    RAISE;
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END f_obtener_plan_cuenta;
   

--F2: F_CONTAR_PRODUCTOS_CUENTA
-- Devuelve el número total de productos de una cuenta concreta.
-- Si no existe la cuenta, lanza NO_DATA_FOUND.

FUNCTION f_contar_productos_cuenta (
  p_cuentaid IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total NUMBER;  -- Contador de productos
BEGIN
  -- Paso 0: Validar que el usuario tiene acceso a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Comprobar existencia de la cuenta
  DECLARE v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy FROM cuenta WHERE id = p_cuentaid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Cuenta no encontrada');
      RAISE;
  END;

  -- Paso 2: Contar los productos
  SELECT COUNT(*) INTO v_total
  FROM producto
  WHERE cuentaid = p_cuentaid;

  RETURN v_total;

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END f_contar_productos_cuenta;


--F3: F_VALIDAR_ATRIBUTOS_PRODUCTOS
-- Verifica si un producto tiene todos los atributos definidos para su cuenta.
-- Devuelve TRUE si están todos; FALSE si falta alguno.
-- Si no existe el producto, lanza NO_DATA_FOUND.

FUNCTION f_validar_atributos_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuentaid      IN producto.cuentaid%TYPE
) RETURN BOOLEAN IS
  v_definidos NUMBER;  -- Número de atributos definidos para la cuenta
  v_asignados NUMBER;  -- Número de atributos asignados al producto
BEGIN
  -- Paso 0: Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Comprobar que el producto existe
  DECLARE v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy
    FROM producto
    WHERE gtin = p_producto_gtin AND cuentaid = p_cuentaid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado');
      RAISE;
  END;

  -- Paso 2: Contar atributos definidos
  SELECT COUNT(*) INTO v_definidos
  FROM atributo
  WHERE cuentaid = p_cuentaid;

  -- Paso 3: Contar atributos asignados al producto
  SELECT COUNT(DISTINCT atributoid) INTO v_asignados
  FROM atributosproducto
  WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuentaid;

  -- Paso 4: Comparar y devolver
  RETURN (v_definidos = v_asignados);

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END f_validar_atributos_producto;



--F4:F_NUM_CATEGORIAS_CUENTA
-- Devuelve el número de categorías registradas para una cuenta.
-- Lanza NO_DATA_FOUND si no existe la cuenta.

FUNCTION f_num_categorias_cuenta (
  p_cuentaid IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  -- Paso 0: Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Verificar que la cuenta existe
  DECLARE v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy FROM cuenta WHERE id = p_cuentaid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Cuenta no encontrada');
      RAISE;
  END;

  -- Paso 2: Contar las categorías
  SELECT COUNT(*) INTO v_total
  FROM categoria
  WHERE cuentaid = p_cuentaid;

  RETURN v_total;

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END f_num_categorias_cuenta;

-- P5: p_actualizar_nombre_producto
-- Procedimiento que actualiza el nombre de un producto.
-- Parámetros:
--   p_producto_gtin: identificador del producto.
--   p_cuentaid: ID de la cuenta propietaria del producto.
--   p_nuevo_nombre: nuevo nombre que se quiere asignar.

PROCEDURE p_actualizar_nombre_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuentaid      IN producto.cuentaid%TYPE,
  p_nuevo_nombre  IN producto.nombre%TYPE
) IS
BEGIN
  -- Paso 0: Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Validar que el nuevo nombre no sea nulo o vacío
  IF p_nuevo_nombre IS NULL OR TRIM(p_nuevo_nombre) = '' THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Nombre nulo o vacío');
    RAISE invalid_data;
  END IF;

  -- Paso 2: Intentar actualizar
  UPDATE producto
  SET nombre = p_nuevo_nombre
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuentaid;

  -- Paso 3: Verificar que la actualización se haya realizado
  IF SQL%ROWCOUNT = 0 THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado');
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END;

-- P6: p_asociar_activo_a_producto
-- Asocia un activo ya existente a un producto.
-- Parámetros:
--   p_producto_gtin, p_producto_cuentaid: identificación del producto.
--   p_activo_id, p_activo_cuentaid: identificación del activo.

PROCEDURE p_asociar_activo_a_producto (
  p_producto_gtin     IN producto.gtin%TYPE,
  p_producto_cuentaid IN producto.cuentaid%TYPE,
  p_activo_id         IN activo.id%TYPE,
  p_activo_cuentaid   IN activo.cuentaid%TYPE
) IS
  v_dummy NUMBER;
BEGIN
  -- Paso 0: Verificar acceso a ambas cuentas
  IF NOT f_verificar_cuenta_usuario(p_producto_cuentaid)
     OR NOT f_verificar_cuenta_usuario(p_activo_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Verificar que existen producto y activo
  SELECT 1 INTO v_dummy FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_producto_cuentaid;

  SELECT 1 INTO v_dummy FROM activo
  WHERE id = p_activo_id AND cuentaid = p_activo_cuentaid;

  -- Paso 2: Verificar que no exista la relación aún
  BEGIN
    SELECT 1 INTO v_dummy FROM relacionproductoactivo
    WHERE productogtin = p_producto_gtin AND productocuentaid = p_producto_cuentaid
      AND activoid = p_activo_id AND activocuentaid = p_activo_cuentaid;

    -- Si existe, lanzar excepción
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Asociación duplicada');
    RAISE exception_asociacion_duplicada;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN NULL; -- Correcto, no hay duplicado
  END;

  -- Paso 3: Crear asociación
  INSERT INTO relacionproductoactivo (
    activoid, activocuentaid, productogtin, productocuentaid
  ) VALUES (
    p_activo_id, p_activo_cuentaid, p_producto_gtin, p_producto_cuentaid
  );

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END;

--P7: P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES
-- Elimina un producto y todas sus asociaciones (atributos, categorías, activos, relaciones).
-- Parámetros:
--   p_producto_gtin: identificador del producto.
--   p_cuentaid: cuenta propietaria.

PROCEDURE p_eliminar_producto_y_asociaciones (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuentaid      IN producto.cuentaid%TYPE
) IS
BEGIN
  -- Paso 0: Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Eliminar relaciones (en orden por dependencias)
  DELETE FROM relacionproductoactivo
  WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuentaid;

  DELETE FROM atributosproducto
  WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuentaid;

  DELETE FROM relacionproductocategoria
  WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuentaid;

  DELETE FROM relacionado
  WHERE (productogtin = p_producto_gtin AND productocuentaid = p_cuentaid)
     OR (productogtin1 = p_producto_gtin AND productocuentaid1 = p_cuentaid);

  -- Paso 2: Eliminar el producto
  DELETE FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuentaid;

  -- Paso 3: Verificar eliminación
  IF SQL%ROWCOUNT = 0 THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado para borrar');
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END;

--P8: P_ACTUALIZAR_PRODUCTOS
-- Revisa PRODUCTOS_EXT y sincroniza con PRODUCTO: añade nuevos, actualiza nombres, elimina obsoletos.
-- Parámetro:
--   p_cuentaid: ID de la cuenta.
PROCEDURE p_actualizar_productos (
  p_cuentaid IN cuenta.id%TYPE
) IS
  CURSOR c_ext IS
    SELECT gtin, nombre FROM productos_ext WHERE cuentaid = p_cuentaid;
  CURSOR c_int IS
    SELECT gtin FROM producto WHERE cuentaid = p_cuentaid;

  v_nombre_actual producto.nombre%TYPE;

  TYPE t_gtins IS TABLE OF BOOLEAN INDEX BY PLS_INTEGER;
  tabla_ext t_gtins;
BEGIN
  -- Paso 0: Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso denegado');
  END IF;

  -- Paso 1: Recorrer productos externos
  FOR r IN c_ext LOOP
    BEGIN
      SELECT nombre INTO v_nombre_actual
      FROM producto
      WHERE gtin = r.gtin AND cuentaid = p_cuentaid;

      IF v_nombre_actual != r.nombre THEN
        p_actualizar_nombre_producto(r.gtin, p_cuentaid, r.nombre);
      END IF;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO producto (gtin, nombre, cuentaid)
        VALUES (r.gtin, r.nombre, p_cuentaid);
    END;

    tabla_ext(r.gtin) := TRUE;
  END LOOP;

  -- Paso 2: Eliminar productos que ya no están
  FOR r IN c_int LOOP
    IF NOT tabla_ext.EXISTS(r.gtin) THEN
      p_eliminar_producto_y_asociaciones(r.gtin, p_cuentaid);
    END IF;
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SQLCODE || ' ' || SQLERRM);
    RAISE;
END;

--P9: P_CREAR_USUARIO
-- Crea un nuevo usuario de base de datos, lo asocia a cuenta y otorga permisos.
-- Parámetros:
--   p_usuario: estructura USUARIO%ROWTYPE con los datos.
--   p_rol: nombre del rol a asignar.
--   p_password: contraseña para el usuario.

PROCEDURE p_crear_usuario (
  p_usuario  IN usuario%ROWTYPE,
  p_rol      IN VARCHAR2,
  p_password IN VARCHAR2
) IS
BEGIN
  -- Paso 1: Insertar en tabla USUARIO
  INSERT INTO usuario (
    nombreusuario, cuentaid, nombrecompleto, correoelectronico, telefono
  ) VALUES (
    p_usuario.nombreusuario, p_usuario.cuentaid,
    p_usuario.nombrecompleto, p_usuario.correoelectronico,
    p_usuario.telefono
  );

  -- Paso 2: Crear usuario en Oracle
  EXECUTE IMMEDIATE 'CREATE USER ' || p_usuario.nombreusuario ||
                    ' IDENTIFIED BY "' || p_password || '"';

  -- Paso 3: Asignar rol
  EXECUTE IMMEDIATE 'GRANT ' || p_rol || ' TO ' || p_usuario.nombreusuario;

  -- Paso 4: Otorgar permisos básicos
  EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || p_usuario.nombreusuario;

  -- Paso 5: Crear sinónimo
  EXECUTE IMMEDIATE 'CREATE SYNONYM ' || p_usuario.nombreusuario || '.producto FOR producto';

EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Error creación usuario: ' || SQLCODE || ' ' || SQLERRM);
    RAISE;
END;

-- CERRAMOS PAQUETE
end pkg_admin_productos;
/