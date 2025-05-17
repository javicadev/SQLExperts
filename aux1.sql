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