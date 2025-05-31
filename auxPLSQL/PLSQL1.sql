-- PAQUETE FUNCIONES BÁSICAS ---
--SI COMPILAN--

--auxiliar
CREATE OR REPLACE FUNCTION f_verificar_cuenta_usuario (
  p_cuentaid IN cuenta.id%TYPE
) RETURN BOOLEAN IS
  v_dummy   NUMBER;
  v_mensaje VARCHAR2(500);
BEGIN
  SELECT 1
  INTO v_dummy
  FROM usuario
  WHERE UPPER(nombreusuario) = UPPER(SYS_CONTEXT('USERENV','SESSION_USER'))
    AND cuentaid = p_cuentaid;

  RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'El usuario no pertenece a la cuenta indicada.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      v_mensaje
    );
    RETURN FALSE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      v_mensaje
    );
    RETURN FALSE;
END;
/


--F1:f_obtener_plan_cuenta
CREATE OR REPLACE FUNCTION f_obtener_plan_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN plan%ROWTYPE IS
  v_plan     plan%ROWTYPE;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Verificar si el usuario conectado pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Obtener el plan asociado a la cuenta
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
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_obtener_plan_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_obtener_plan_cuenta',
      v_mensaje
    );
    RAISE;
END;
/

--F2:f_contar_productos_cuenta
CREATE OR REPLACE FUNCTION f_contar_productos_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total    NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar que el usuario pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Contar productos asociados a la cuenta
  SELECT COUNT(*)
  INTO v_total
  FROM producto
  WHERE cuentaid = p_cuenta_id;

  RETURN v_total;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta no encontrada';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_contar_productos_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_contar_productos_cuenta',
      v_mensaje
    );
    RAISE;
END;
/

--F3:f_validar_atributos_producto 
CREATE OR REPLACE FUNCTION f_validar_atributos_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) RETURN BOOLEAN IS
  v_faltan   NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar que el usuario tiene acceso a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto existe
  BEGIN
    SELECT 1
    INTO v_faltan
    FROM producto
    WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_mensaje := 'Producto no encontrado para la cuenta indicada.';
      INSERT INTO traza VALUES (
        SYSDATE,
        SYS_CONTEXT('USERENV','SESSION_USER'),
        'f_validar_atributos_producto',
        v_mensaje
      );
      RAISE;
  END;

  -- Paso 3: Verificar si hay atributos sin valor
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

  -- Paso 4: Devolver TRUE si todos los atributos tienen valor
  RETURN v_faltan = 0;

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_validar_atributos_producto',
      v_mensaje
    );
    RAISE;
END;
/

--F4:f_num_categorias_cuenta 
CREATE OR REPLACE FUNCTION f_num_categorias_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total    NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Validar acceso del usuario a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Contar las categorías asociadas a esa cuenta
  SELECT COUNT(*)
  INTO v_total
  FROM categoria
  WHERE cuentaid = p_cuenta_id;

  RETURN v_total;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta no encontrada o sin categorías.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_num_categorias_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_num_categorias_cuenta',
      v_mensaje
    );
    RAISE;
END;
/

--P5: p_actualizar_nombre_producto
CREATE OR REPLACE PROCEDURE p_actualizar_nombre_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE,
  p_nuevo_nombre  IN producto.nombre%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Validar que el nuevo nombre no es nulo ni vacío
  IF p_nuevo_nombre IS NULL OR TRIM(p_nuevo_nombre) = '' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Nombre de producto no válido.');
  END IF;

  -- Paso 3: Actualizar el nombre
  UPDATE producto
  SET nombre = p_nuevo_nombre
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

  -- Paso 4: Verificar que se ha actualizado alguna fila
  IF SQL%ROWCOUNT = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto no encontrado para actualización.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_actualizar_nombre_producto',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_actualizar_nombre_producto',
      v_mensaje
    );
    RAISE;
END;
/

--P6: p_asociar_activo_a_producto
CREATE OR REPLACE PROCEDURE p_asociar_activo_a_producto (
  p_producto_gtin         IN producto.gtin%TYPE,
  p_producto_cuenta_id    IN producto.cuentaid%TYPE,
  p_activo_id             IN activo.id%TYPE,
  p_activo_cuenta_id      IN activo.cuentaid%TYPE
) IS
  v_dummy   NUMBER;
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario a la cuenta del producto
  IF NOT f_verificar_cuenta_usuario(p_producto_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto existe
  SELECT 1 INTO v_dummy
  FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_producto_cuenta_id;

  -- Paso 3: Verificar que el activo existe
  SELECT 1 INTO v_dummy
  FROM activo
  WHERE id = p_activo_id AND cuentaid = p_activo_cuenta_id;

  -- Paso 4: Verificar que la relación no existe ya
  BEGIN
    SELECT 1 INTO v_dummy
    FROM relacionproductoactivo
    WHERE productogtin = p_producto_gtin
      AND productocuentaid = p_producto_cuenta_id
      AND activoid = p_activo_id
      AND activocuentaid = p_activo_cuenta_id;

    -- Si encuentra, ya existe
    RAISE_APPLICATION_ERROR(-20002, 'Asociación ya existente.');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- No existe: OK
      NULL;
  END;

  -- Paso 5: Insertar la asociación
  INSERT INTO relacionproductoactivo (
    activoid, activocuentaid,
    productogtin, productocuentaid
  ) VALUES (
    p_activo_id, p_activo_cuenta_id,
    p_producto_gtin, p_producto_cuenta_id
  );

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto o activo no encontrado.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_asociar_activo_a_producto',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_asociar_activo_a_producto',
      v_mensaje
    );
    RAISE;
END;
/

--P7: p_eliminar_producto_y_asociaciones
CREATE OR REPLACE PROCEDURE p_eliminar_producto_y_asociaciones (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Validar que el usuario tiene acceso a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Eliminar relaciones con activos
  DELETE FROM relacionproductoactivo
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 3: Eliminar atributos asociados
  DELETE FROM atributosproducto
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 4: Eliminar asociaciones con categorías
  DELETE FROM relacionproductocategoria
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 5: Eliminar relaciones con otros productos (en ambos sentidos)
  DELETE FROM relacionado
  WHERE (productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id)
     OR (productogtin1 = p_producto_gtin AND productocuentaid1 = p_cuenta_id);

  -- Paso 6: Eliminar el producto
  DELETE FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

  IF SQL%ROWCOUNT = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto no encontrado para eliminación.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_eliminar_producto_y_asociaciones',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_eliminar_producto_y_asociaciones',
      v_mensaje
    );
    RAISE;
END;
/

--P8: p_actualizar_productos
CREATE OR REPLACE PROCEDURE p_actualizar_productos (
  p_cuenta_id IN cuenta.id%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Insertar o actualizar productos de productos_ext
  FOR r IN (
    SELECT * FROM productos_ext
    WHERE cuentaid = p_cuenta_id
  ) LOOP
    BEGIN
      -- Intentar actualizar si existe (comparando por SKU + cuentaid)
      UPDATE producto
      SET nombre = r.nombre,
          textocorto = r.textocorto
      WHERE sku = r.sku AND cuentaid = r.cuentaid;

      IF SQL%ROWCOUNT = 0 THEN
        -- Si no existe, insertar
        INSERT INTO producto (
          gtin, sku, nombre, textocorto, creado, cuentaid
        ) VALUES (
          seq_productos.NEXTVAL,
          r.sku, r.nombre, r.textocorto, r.creado, r.cuentaid
        );
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
        INSERT INTO traza VALUES (
          SYSDATE,
          SYS_CONTEXT('USERENV','SESSION_USER'),
          'p_actualizar_productos',
          v_mensaje
        );
    END;
  END LOOP;

  -- Paso 3: Eliminar productos que ya no están en productos_ext
  FOR p IN (
    SELECT gtin
    FROM producto
    WHERE cuentaid = p_cuenta_id
      AND sku NOT IN (
        SELECT sku FROM productos_ext WHERE cuentaid = p_cuenta_id
      )
  ) LOOP
    BEGIN
      p_eliminar_producto_y_asociaciones(p.gtin, p_cuenta_id);
    EXCEPTION
      WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
        INSERT INTO traza VALUES (
          SYSDATE,
          SYS_CONTEXT('USERENV','SESSION_USER'),
          'p_actualizar_productos',
          v_mensaje
        );
    END;
  END LOOP;

END;
/

--P9:p_crear_usuario
CREATE OR REPLACE PROCEDURE p_crear_usuario (
  p_usuario   IN usuario%ROWTYPE,
  p_rol       IN VARCHAR2,
  p_password  IN VARCHAR2
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Crear el usuario en Oracle
  EXECUTE IMMEDIATE 'CREATE USER "' || p_usuario.nombreusuario || '" IDENTIFIED BY "' || p_password || '"';

  -- Paso 2: Conceder permisos mínimos y el rol correspondiente
  EXECUTE IMMEDIATE 'GRANT CONNECT TO "' || p_usuario.nombreusuario || '"';
  EXECUTE IMMEDIATE 'GRANT "' || p_rol || '" TO "' || p_usuario.nombreusuario || '"';

  -- Paso 3: Insertar datos del usuario en la tabla USUARIO
  INSERT INTO usuario (
    id, nombreusuario, nombrecompleto, avatar,
    correoelectronico, telefono, cuentaid, cuentadueno
  ) VALUES (
    p_usuario.id, p_usuario.nombreusuario, p_usuario.nombrecompleto, p_usuario.avatar,
    p_usuario.correoelectronico, p_usuario.telefono, p_usuario.cuentaid, p_usuario.cuentadueno
  );

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_crear_usuario',
      v_mensaje
    );
    RAISE;
END;
/

CREATE OR REPLACE PACKAGE pkg_admin_productos IS

  -- Excepciones personalizadas
  exception_plan_no_asignado EXCEPTION;

  -- Función auxiliar
  FUNCTION f_verificar_cuenta_usuario (
    p_cuentaid IN cuenta.id%TYPE
  ) RETURN BOOLEAN;

  -- Funciones
  FUNCTION f_obtener_plan_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN plan%ROWTYPE;

  FUNCTION f_contar_productos_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER;

  FUNCTION f_validar_atributos_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  ) RETURN BOOLEAN;

  FUNCTION f_num_categorias_cuenta (
    p_cuenta_id IN cuenta.id%TYPE
  ) RETURN NUMBER;

  -- Procedimientos
  PROCEDURE p_actualizar_nombre_producto (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE,
    p_nuevo_nombre  IN producto.nombre%TYPE
  );

  PROCEDURE p_asociar_activo_a_producto (
    p_producto_gtin         IN producto.gtin%TYPE,
    p_producto_cuenta_id    IN producto.cuentaid%TYPE,
    p_activo_id             IN activo.id%TYPE,
    p_activo_cuenta_id      IN activo.cuentaid%TYPE
  );

  PROCEDURE p_eliminar_producto_y_asociaciones (
    p_producto_gtin IN producto.gtin%TYPE,
    p_cuenta_id     IN producto.cuentaid%TYPE
  );

  PROCEDURE p_actualizar_productos (
    p_cuenta_id IN cuenta.id%TYPE
  );

  PROCEDURE p_crear_usuario (
    p_usuario   IN usuario%ROWTYPE,
    p_rol       IN VARCHAR2,
    p_password  IN VARCHAR2
  );

END pkg_admin_productos;
/


CREATE OR REPLACE PACKAGE BODY pkg_admin_productos IS
--auxiliar
FUNCTION f_verificar_cuenta_usuario (
  p_cuentaid IN cuenta.id%TYPE
) RETURN BOOLEAN IS
  v_dummy   NUMBER;
  v_mensaje VARCHAR2(500);
BEGIN
  SELECT 1
  INTO v_dummy
  FROM usuario
  WHERE UPPER(nombreusuario) = UPPER(SYS_CONTEXT('USERENV','SESSION_USER'))
    AND cuentaid = p_cuentaid;

  RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'El usuario no pertenece a la cuenta indicada.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      v_mensaje
    );
    RETURN FALSE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      v_mensaje
    );
    RETURN FALSE;
END f_verificar_cuenta_usuario;

--F1:f_obtener_plan_cuenta
FUNCTION f_obtener_plan_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN plan%ROWTYPE IS
  v_plan     plan%ROWTYPE;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Verificar si el usuario conectado pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Obtener el plan asociado a la cuenta
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
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_obtener_plan_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_obtener_plan_cuenta',
      v_mensaje
    );
    RAISE;
END f_obtener_plan_cuenta;


--F2:f_contar_productos_cuenta
FUNCTION f_contar_productos_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total    NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar que el usuario pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Contar productos asociados a la cuenta
  SELECT COUNT(*)
  INTO v_total
  FROM producto
  WHERE cuentaid = p_cuenta_id;

  RETURN v_total;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta no encontrada';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_contar_productos_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_contar_productos_cuenta',
      v_mensaje
    );
    RAISE;
END f_contar_productos_cuenta;

--F3:f_validar_atributos_producto 
FUNCTION f_validar_atributos_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) RETURN BOOLEAN IS
  v_faltan   NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar que el usuario tiene acceso a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto existe
  BEGIN
    SELECT 1
    INTO v_faltan
    FROM producto
    WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      v_mensaje := 'Producto no encontrado para la cuenta indicada.';
      INSERT INTO traza VALUES (
        SYSDATE,
        SYS_CONTEXT('USERENV','SESSION_USER'),
        'f_validar_atributos_producto',
        v_mensaje
      );
      RAISE;
  END;

  -- Paso 3: Verificar si hay atributos sin valor
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

  -- Paso 4: Devolver TRUE si todos los atributos tienen valor
  RETURN v_faltan = 0;

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_validar_atributos_producto',
      v_mensaje
    );
    RAISE;
END f_validar_atributos_producto;

--F4:f_num_categorias_cuenta 
FUNCTION f_num_categorias_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN NUMBER IS
  v_total    NUMBER;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- Paso 1: Validar acceso del usuario a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Contar las categorías asociadas a esa cuenta
  SELECT COUNT(*)
  INTO v_total
  FROM categoria
  WHERE cuentaid = p_cuenta_id;

  RETURN v_total;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta no encontrada o sin categorías.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_num_categorias_cuenta',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_num_categorias_cuenta',
      v_mensaje
    );
    RAISE;
END f_num_categorias_cuenta;


--P5: p_actualizar_nombre_producto
PROCEDURE p_actualizar_nombre_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE,
  p_nuevo_nombre  IN producto.nombre%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Validar que el nuevo nombre no es nulo ni vacío
  IF p_nuevo_nombre IS NULL OR TRIM(p_nuevo_nombre) = '' THEN
    RAISE_APPLICATION_ERROR(-20002, 'Nombre de producto no válido.');
  END IF;

  -- Paso 3: Actualizar el nombre
  UPDATE producto
  SET nombre = p_nuevo_nombre
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

  -- Paso 4: Verificar que se ha actualizado alguna fila
  IF SQL%ROWCOUNT = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto no encontrado para actualización.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_actualizar_nombre_producto',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_actualizar_nombre_producto',
      v_mensaje
    );
    RAISE;
END p_actualizar_nombre_producto;

--P6: p_asociar_activo_a_producto
PROCEDURE p_asociar_activo_a_producto (
  p_producto_gtin         IN producto.gtin%TYPE,
  p_producto_cuenta_id    IN producto.cuentaid%TYPE,
  p_activo_id             IN activo.id%TYPE,
  p_activo_cuenta_id      IN activo.cuentaid%TYPE
) IS
  v_dummy   NUMBER;
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario a la cuenta del producto
  IF NOT f_verificar_cuenta_usuario(p_producto_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto existe
  SELECT 1 INTO v_dummy
  FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_producto_cuenta_id;

  -- Paso 3: Verificar que el activo existe
  SELECT 1 INTO v_dummy
  FROM activo
  WHERE id = p_activo_id AND cuentaid = p_activo_cuenta_id;

  -- Paso 4: Verificar que la relación no existe ya
  BEGIN
    SELECT 1 INTO v_dummy
    FROM relacionproductoactivo
    WHERE productogtin = p_producto_gtin
      AND productocuentaid = p_producto_cuenta_id
      AND activoid = p_activo_id
      AND activocuentaid = p_activo_cuenta_id;

    -- Si encuentra, ya existe
    RAISE_APPLICATION_ERROR(-20002, 'Asociación ya existente.');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- No existe: OK
      NULL;
  END;

  -- Paso 5: Insertar la asociación
  INSERT INTO relacionproductoactivo (
    activoid, activocuentaid,
    productogtin, productocuentaid
  ) VALUES (
    p_activo_id, p_activo_cuenta_id,
    p_producto_gtin, p_producto_cuenta_id
  );

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto o activo no encontrado.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_asociar_activo_a_producto',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_asociar_activo_a_producto',
      v_mensaje
    );
    RAISE;
END p_asociar_activo_a_producto;

--P7: p_eliminar_producto_y_asociaciones
PROCEDURE p_eliminar_producto_y_asociaciones (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Validar que el usuario tiene acceso a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Eliminar relaciones con activos
  DELETE FROM relacionproductoactivo
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 3: Eliminar atributos asociados
  DELETE FROM atributosproducto
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 4: Eliminar asociaciones con categorías
  DELETE FROM relacionproductocategoria
  WHERE productogtin = p_producto_gtin
    AND productocuentaid = p_cuenta_id;

  -- Paso 5: Eliminar relaciones con otros productos (en ambos sentidos)
  DELETE FROM relacionado
  WHERE (productogtin = p_producto_gtin AND productocuentaid = p_cuenta_id)
     OR (productogtin1 = p_producto_gtin AND productocuentaid1 = p_cuenta_id);

  -- Paso 6: Eliminar el producto
  DELETE FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;

  IF SQL%ROWCOUNT = 0 THEN
    RAISE NO_DATA_FOUND;
  END IF;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Producto no encontrado para eliminación.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_eliminar_producto_y_asociaciones',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_eliminar_producto_y_asociaciones',
      v_mensaje
    );
    RAISE;
END p_eliminar_producto_y_asociaciones;

--P8: p_actualizar_productos
PROCEDURE p_actualizar_productos (
  p_cuenta_id IN cuenta.id%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Insertar o actualizar productos de productos_ext
  FOR r IN (
    SELECT * FROM productos_ext
    WHERE cuentaid = p_cuenta_id
  ) LOOP
    BEGIN
      -- Intentar actualizar si existe (comparando por SKU + cuentaid)
      UPDATE producto
      SET nombre = r.nombre,
          textocorto = r.textocorto
      WHERE sku = r.sku AND cuentaid = r.cuentaid;

      IF SQL%ROWCOUNT = 0 THEN
        -- Si no existe, insertar
        INSERT INTO producto (
          gtin, sku, nombre, textocorto, creado, cuentaid
        ) VALUES (
          seq_productos.NEXTVAL,
          r.sku, r.nombre, r.textocorto, r.creado, r.cuentaid
        );
      END IF;

    EXCEPTION
      WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
        INSERT INTO traza VALUES (
          SYSDATE,
          SYS_CONTEXT('USERENV','SESSION_USER'),
          'p_actualizar_productos',
          v_mensaje
        );
    END;
  END LOOP;

  -- Paso 3: Eliminar productos que ya no están en productos_ext
  FOR p IN (
    SELECT gtin
    FROM producto
    WHERE cuentaid = p_cuenta_id
      AND sku NOT IN (
        SELECT sku FROM productos_ext WHERE cuentaid = p_cuenta_id
      )
  ) LOOP
    BEGIN
      p_eliminar_producto_y_asociaciones(p.gtin, p_cuenta_id);
    EXCEPTION
      WHEN OTHERS THEN
        v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
        INSERT INTO traza VALUES (
          SYSDATE,
          SYS_CONTEXT('USERENV','SESSION_USER'),
          'p_actualizar_productos',
          v_mensaje
        );
    END;
  END LOOP;

END p_actualizar_productos;

--P9:p_crear_usuario
PROCEDURE p_crear_usuario (
  p_usuario   IN usuario%ROWTYPE,
  p_rol       IN VARCHAR2,
  p_password  IN VARCHAR2
) 
IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Crear el usuario en Oracle
  EXECUTE IMMEDIATE 'CREATE USER "' || p_usuario.nombreusuario || '" IDENTIFIED BY "' || p_password || '"';

  -- Paso 2: Conceder permisos mÃ­nimos y el rol correspondiente
  EXECUTE IMMEDIATE 'GRANT CONNECT TO "' || p_usuario.nombreusuario || '"';
  EXECUTE IMMEDIATE 'GRANT "' || p_rol || '" TO "' || p_usuario.nombreusuario || '"';
  
  
  -- Paso 3: Insertar datos del usuario en la tabla USUARIO
  INSERT INTO usuario (
    id, nombreusuario, nombrecompleto, avatar,
    correoelectronico, telefono, cuentaid, cuentadueno
  ) VALUES (
    p_usuario.id, p_usuario.nombreusuario, p_usuario.nombrecompleto, p_usuario.avatar,
    p_usuario.correoelectronico, p_usuario.telefono, p_usuario.cuentaid, p_usuario.cuentadueno
  );

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_crear_usuario',
      v_mensaje
    );
    RAISE;
END p_crear_usuario;
END pkg_admin_productos;
/