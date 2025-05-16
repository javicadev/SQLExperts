CREATE OR REPLACE PACKAGE pkg_admin_productos IS
  ---------------------------------------------------------------------------
  -- PAQUETE DE ADMINISTRACIÓN DE PRODUCTOS Y ACTIVOS (PARTE BÁSICA)
  -- Universidad de Málaga - Administración de Bases de Datos (2024-25)
  ---------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  -- EXCEPCIONES PERSONALIZADAS
  ----------------------------------------------------------------------------
  exception_plan_no_asignado EXCEPTION;
  exception_asociacion_duplicada EXCEPTION;
  invalid_data EXCEPTION;

  ----------------------------------------------------------------------------
  -- FUNCIÓN AUXILIAR: F_VERIFICAR_CUENTA_USUARIO
  -- Verifica si el usuario actual pertenece a la cuenta indicada
  ----------------------------------------------------------------------------
  FUNCTION f_verificar_cuenta_usuario (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN BOOLEAN;

  ----------------------------------------------------------------------------
  -- FUNCIÓN 1: F_OBTENER_PLAN_CUENTA
  ----------------------------------------------------------------------------
  FUNCTION f_obtener_plan_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN plan%ROWTYPE;

  ----------------------------------------------------------------------------
  -- FUNCIÓN 2: F_CONTAR_PRODUCTOS_CUENTA
  ----------------------------------------------------------------------------
  FUNCTION f_contar_productos_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER;

  ----------------------------------------------------------------------------
  -- FUNCIÓN 3: F_VALIDAR_ATRIBUTOS_PRODUCTO
  ----------------------------------------------------------------------------
  FUNCTION f_validar_atributos_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  ) RETURN BOOLEAN;

  ----------------------------------------------------------------------------
  -- FUNCIÓN 4: F_NUM_CATEGORIAS_CUENTA
  ----------------------------------------------------------------------------
  FUNCTION f_num_categorias_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER;

  ----------------------------------------------------------------------------
  -- PROCEDIMIENTO 5: P_ACTUALIZAR_NOMBRE_PRODUCTO
  ----------------------------------------------------------------------------
  PROCEDURE p_actualizar_nombre_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE,
    p_nuevo_nombre  IN producto.nombre%TYPE
  );

  ----------------------------------------------------------------------------
  -- PROCEDIMIENTO 6: P_ASOCIAR_ACTIVO_A_PRODUCTO
  ----------------------------------------------------------------------------
  PROCEDURE p_asociar_activo_a_producto (
    p_producto_gtin         IN producto.gtin%TYPE,
    p_producto_cuenta_id    IN producto.cuentaid%TYPE,
    p_activo_id             IN activo.id%TYPE,
    p_activo_cuenta_id      IN activo.cuentaid%TYPE
  );

  ----------------------------------------------------------------------------
  -- PROCEDIMIENTO 7: P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES
  ----------------------------------------------------------------------------
  PROCEDURE p_eliminar_producto_y_asociaciones (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  );

  ----------------------------------------------------------------------------
  -- PROCEDIMIENTO 8: P_ACTUALIZAR_PRODUCTOS
  ----------------------------------------------------------------------------
  PROCEDURE p_actualizar_productos (
    p_cuenta_id IN cuenta.id%TYPE
  );

  ----------------------------------------------------------------------------
  -- PROCEDIMIENTO 9: P_CREAR_USUARIO
  ----------------------------------------------------------------------------
  PROCEDURE p_crear_usuario (
    p_usuario   IN usuario%ROWTYPE,
    p_rol       IN VARCHAR2,
    p_password  IN VARCHAR2
  );

END pkg_admin_productos;
/

CREATE OR REPLACE PACKAGE BODY pkg_admin_productos IS

  ---------------------------------------------------------------------------
  -- FUNCIÓN AUXILIAR: f_verificar_cuenta_usuario
  -- Verifica si el usuario conectado pertenece a la cuenta indicada
  ---------------------------------------------------------------------------
  FUNCTION f_verificar_cuenta_usuario (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN BOOLEAN IS
    v_dummy NUMBER;
  BEGIN
    SELECT 1
    INTO v_dummy
    FROM usuario
    WHERE UPPER(nombreusuario) = UPPER(USER)
      AND cuentaid = p_cuentaid;

    RETURN TRUE;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'El usuario no pertenece a la cuenta indicada.');
      RETURN FALSE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (
        SYSDATE, USER, $$PLSQL_UNIT,
        SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500)
      );
      RETURN FALSE;
  END f_verificar_cuenta_usuario;

  ---------------------------------------------------------------------------
  -- FUNCIÓN 1: f_obtener_plan_cuenta
  ---------------------------------------------------------------------------
  FUNCTION f_obtener_plan_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN plan%ROWTYPE IS
    v_plan    plan%ROWTYPE;
    v_mensaje VARCHAR2(500);
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    SELECT p.id, p.productos, p.activos, p.almacenamiento,
           p.categoriasproducto, p.categoriasactivos,
           p.relaciones, p.precioanual, p.nombre
    INTO v_plan
    FROM cuenta c
    JOIN plan p ON c.planid = p.id
    WHERE c.id = p_cuenta_id;

    RETURN v_plan;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_mensaje := 'Cuenta inexistente o sin plan asociado';
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, v_mensaje);
      RAISE;

    WHEN exception_plan_no_asignado THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'La cuenta no tiene plan asignado');
      RAISE;

    WHEN OTHERS THEN
      v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
      DBMS_OUTPUT.PUT_LINE(v_mensaje);
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, v_mensaje);
      RAISE;
  END f_obtener_plan_cuenta;

  ---------------------------------------------------------------------------
  -- FUNCIÓN 2: f_contar_productos_cuenta
  ---------------------------------------------------------------------------
  FUNCTION f_contar_productos_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM producto
    WHERE cuentaid = p_cuenta_id;

    RETURN v_total;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Cuenta no encontrada');
      RAISE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (
        SYSDATE, USER, $$PLSQL_UNIT,
        SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500)
      );
      RAISE;
  END f_contar_productos_cuenta;

  ---------------------------------------------------------------------------
  -- FUNCIÓN 3: f_validar_atributos_producto
  ---------------------------------------------------------------------------
  FUNCTION f_validar_atributos_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  ) RETURN BOOLEAN IS
    v_faltan NUMBER;
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    BEGIN
      SELECT 1
      INTO v_faltan
      FROM producto
      WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;
    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado');
        RAISE;
    END;

    SELECT COUNT(*)
    INTO v_faltan
    FROM atributo a
    WHERE a.cuentaid = p_cuenta_id
      AND NOT EXISTS (
        SELECT 1
        FROM atributosproducto ap
        WHERE ap.atributoid = a.id
          AND ap.productogtin = p_producto_gtin
          AND ap.productocuentaid = p_cuenta_id
      );

    RETURN v_faltan = 0;

  EXCEPTION
    WHEN OTHERS THEN
      INSERT INTO traza VALUES (
        SYSDATE, USER, $$PLSQL_UNIT,
        SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500)
      );
      RAISE;
  END f_validar_atributos_producto;

  ---------------------------------------------------------------------------
  -- FUNCIÓN 4: f_num_categorias_cuenta
  ---------------------------------------------------------------------------
  FUNCTION f_num_categorias_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER IS
    v_total NUMBER;
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    SELECT COUNT(*)
    INTO v_total
    FROM categoria
    WHERE cuentaid = p_cuenta_id;

    RETURN v_total;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Cuenta no encontrada');
      RAISE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (
        SYSDATE, USER, $$PLSQL_UNIT,
        SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500)
      );
      RAISE;
  END f_num_categorias_cuenta;
  ---------------------------------------------------------------------------
  -- PROCEDIMIENTO 5: p_actualizar_nombre_producto
  ---------------------------------------------------------------------------
  PROCEDURE p_actualizar_nombre_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE,
    p_nuevo_nombre  IN producto.nombre%TYPE
  ) IS
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    IF p_nuevo_nombre IS NULL OR TRIM(p_nuevo_nombre) = '' THEN
      RAISE invalid_data;
    END IF;

    UPDATE producto
    SET nombre = p_nuevo_nombre
    WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;

  EXCEPTION
    WHEN invalid_data THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Nombre nuevo inválido.');
      RAISE;

    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado.');
      RAISE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT,
        SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500));
      RAISE;
  END p_actualizar_nombre_producto;

  ---------------------------------------------------------------------------
  -- PROCEDIMIENTO 6: p_asociar_activo_a_producto
  ---------------------------------------------------------------------------
  PROCEDURE p_asociar_activo_a_producto (
    p_producto_gtin         IN producto.gtin%TYPE,
    p_producto_cuenta_id    IN producto.cuentaid%TYPE,
    p_activo_id             IN activo.id%TYPE,
    p_activo_cuenta_id      IN activo.cuentaid%TYPE
  ) IS
    v_dummy NUMBER;
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_producto_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    SELECT 1 INTO v_dummy FROM producto WHERE gtin = p_producto_gtin AND cuentaid = p_producto_cuenta_id;
    SELECT 1 INTO v_dummy FROM activo WHERE id = p_activo_id AND cuentaid = p_activo_cuenta_id;

    BEGIN
      SELECT 1 INTO v_dummy
      FROM relacionproductoactivo
      WHERE productogtin = p_producto_gtin AND productocuentaid = p_producto_cuenta_id
        AND activoid = p_activo_id AND activocuentaid = p_activo_cuenta_id;

      -- Si llega aquí, ya existe
      RAISE exception_asociacion_duplicada;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        INSERT INTO relacionproductoactivo VALUES (
          p_activo_id, p_activo_cuenta_id,
          p_producto_gtin, p_producto_cuenta_id
        );
    END;

  EXCEPTION
    WHEN exception_asociacion_duplicada THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Asociación ya existente.');
      RAISE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500));
      RAISE;
  END p_asociar_activo_a_producto;

  ---------------------------------------------------------------------------
  -- PROCEDIMIENTO 7: p_eliminar_producto_y_asociaciones
  ---------------------------------------------------------------------------
  PROCEDURE p_eliminar_producto_y_asociaciones (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  ) IS
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    DELETE FROM relacionproductoactivo
     WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id;

    DELETE FROM atributosproducto
     WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id;

    DELETE FROM relacionproductocategoria
     WHERE productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id;

    DELETE FROM relacionado
     WHERE (productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id)
        OR (productogtin1 = p_producto_gtin AND productocuentaid1 = p_cuenta_id);

    DELETE FROM producto
     WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

    IF SQL%ROWCOUNT = 0 THEN
      RAISE NO_DATA_FOUND;
    END IF;

  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, 'Producto no encontrado al eliminar.');
      RAISE;

    WHEN OTHERS THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500));
      RAISE;
  END p_eliminar_producto_y_asociaciones;

  ---------------------------------------------------------------------------
  -- PROCEDIMIENTO 8: p_actualizar_productos
  ---------------------------------------------------------------------------
  PROCEDURE p_actualizar_productos (
    p_cuenta_id IN cuenta.id%TYPE
  ) IS
  BEGIN
    IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
      RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
    END IF;

    FOR r IN (
      SELECT * FROM productos_ext pe
      WHERE pe.cuentaid = p_cuenta_id
    ) LOOP
      BEGIN
        UPDATE producto
        SET nombre = r.nombre, textocorto = r.textocorto
        WHERE sku = r.sku AND cuentaid = r.cuentaid;

        IF SQL%ROWCOUNT = 0 THEN
          INSERT INTO producto (
            gtin, sku, nombre, textocorto, creado, cuentaid
          ) VALUES (
            seq_productos.NEXTVAL, r.sku, r.nombre, r.textocorto, r.creado, r.cuentaid
          );
        END IF;

      EXCEPTION
        WHEN OTHERS THEN
          INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500));
      END;
    END LOOP;
  END p_actualizar_productos;

  ---------------------------------------------------------------------------
  -- PROCEDIMIENTO 9: p_crear_usuario
  ---------------------------------------------------------------------------
  PROCEDURE p_crear_usuario (
    p_usuario   IN usuario%ROWTYPE,
    p_rol       IN VARCHAR2,
    p_password  IN VARCHAR2
  ) IS
  BEGIN
    EXECUTE IMMEDIATE 'CREATE USER "' || p_usuario.nombreusuario || '" IDENTIFIED BY "' || p_password || '"';
    EXECUTE IMMEDIATE 'GRANT CONNECT TO "' || p_usuario.nombreusuario || '"';
    EXECUTE IMMEDIATE 'GRANT ' || p_rol || ' TO "' || p_usuario.nombreusuario || '"';

    INSERT INTO usuario (
      id, nombreusuario, nombrecompleto, avatar,
      correoelectronico, telefono, cuentaid, cuentadueno
    ) VALUES (
      p_usuario.id, p_usuario.nombreusuario, p_usuario.nombrecompleto, p_usuario.avatar,
      p_usuario.correoelectronico, p_usuario.telefono, p_usuario.cuentaid, p_usuario.cuentadueno
    );

  EXCEPTION
    WHEN OTHERS THEN
      INSERT INTO traza VALUES (SYSDATE, USER, $$PLSQL_UNIT, SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500));
      RAISE;
  END p_crear_usuario;

END pkg_admin_productos;
/
