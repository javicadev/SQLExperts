-- PAQUETE FUNCIONES AVANZADAS ---
--SI COMPILAN--


-----------------------------------------------------------------------------------------
--RECORDAR EXCEPCIONESSSSS!!! DECLARACCION EN EL PAQUETE, para probar podemos declararla en la misma funcion
------------------------------------------------------------------

--F1:: f_validar_plan_suficiente

CREATE OR REPLACE FUNCTION f_validar_plan_suficiente (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN VARCHAR2 IS
  v_mensaje   VARCHAR2(500);
  v_resultado VARCHAR2(100);

  -- Contadores actuales
  v_total_productos         NUMBER;
  v_total_activos           NUMBER;
  v_total_cat_producto      NUMBER;
  v_total_cat_activos       NUMBER;
  v_total_relaciones        NUMBER;

  -- Límites del plan
  v_lim_productos           NUMBER;
  v_lim_activos             NUMBER;
  v_lim_cat_producto        NUMBER;
  v_lim_cat_activos         NUMBER;
  v_lim_relaciones          NUMBER;

  -- ID del plan
  v_plan_id                 plan.id%TYPE;

BEGIN
  -- Validar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Verificar que la cuenta existe y tiene plan
  BEGIN
    SELECT planid INTO v_plan_id
    FROM cuenta
    WHERE id = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE;
  END;

  IF v_plan_id IS NULL THEN
    RAISE exception_plan_no_asignado;
  END IF;

  -- Obtener límites del plan
  SELECT
    TO_NUMBER(productos),
    TO_NUMBER(activos),
    TO_NUMBER(categoriasproducto),
    TO_NUMBER(categoriasactivos),
    TO_NUMBER(relaciones)
  INTO
    v_lim_productos, v_lim_activos,
    v_lim_cat_producto, v_lim_cat_activos, v_lim_relaciones
  FROM plan
  WHERE id = v_plan_id;

  -- Contar recursos usados por la cuenta
  SELECT COUNT(*) INTO v_total_productos
  FROM producto WHERE cuentaid = p_cuenta_id;

  SELECT COUNT(*) INTO v_total_activos
  FROM activo WHERE cuentaid = p_cuenta_id;

  SELECT COUNT(*) INTO v_total_cat_producto
  FROM categoria WHERE cuentaid = p_cuenta_id;

  SELECT COUNT(*) INTO v_total_cat_activos
  FROM categoriaactivos WHERE cuentaid = p_cuenta_id;

  SELECT COUNT(*) INTO v_total_relaciones
  FROM relacionado
  WHERE productocuentaid = p_cuenta_id
     OR productocuentaid1 = p_cuenta_id;

  -- Comparaciones
  IF v_total_productos > v_lim_productos THEN
    RETURN 'INSUFICIENTE: PRODUCTOS';
  ELSIF v_total_activos > v_lim_activos THEN
    RETURN 'INSUFICIENTE: ACTIVOS';
  ELSIF v_total_cat_producto > v_lim_cat_producto THEN
    RETURN 'INSUFICIENTE: CATEGORIASPRODUCTO';
  ELSIF v_total_cat_activos > v_lim_cat_activos THEN
    RETURN 'INSUFICIENTE: CATEGORIASACTIVOS';
  ELSIF v_total_relaciones > v_lim_relaciones THEN
    RETURN 'INSUFICIENTE: RELACIONES';
  ELSE
    RETURN 'SUFICIENTE';
  END IF;

EXCEPTION
  WHEN exception_plan_no_asignado THEN
    v_mensaje := 'La cuenta no tiene plan asociado.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_validar_plan_suficiente',
      v_mensaje
    );
    RAISE;

  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta no encontrada.';
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_validar_plan_suficiente',
      v_mensaje
    );
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_validar_plan_suficiente',
      v_mensaje
    );
    RAISE;
END;
/

--F2: f_lista_categorias_producto

CREATE OR REPLACE FUNCTION f_lista_categorias_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) RETURN VARCHAR2 IS
  v_lista   VARCHAR2(1000);
  v_mensaje VARCHAR2(500);
BEGIN
  -- Verificar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado.');
  END IF;

  -- Obtener lista de categorías
  SELECT LISTAGG(c.nombre, ', ')
         WITHIN GROUP (ORDER BY c.nombre)
  INTO v_lista
  FROM relacionproductocategoria rpc
  JOIN categoria c
    ON rpc.categoriaid = c.id AND rpc.categoriacuentaid = c.cuentaid
  WHERE rpc.productogtin = p_producto_gtin
    AND rpc.productocuentaid = p_cuenta_id;

  RETURN NVL(v_lista, '');

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN ''; -- Producto sin categorías

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_lista_categorias_producto',
      v_mensaje
    );
    RAISE;
END;
/

--P3: p_migrar_productos_a_categorias
CREATE OR REPLACE PROCEDURE p_migrar_productos_a_categoria (
  p_categoria_id       IN categoria.id%TYPE,
  p_categoria_cuentaid IN categoria.cuentaid%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar que el usuario conectado tiene acceso a la cuenta de la categoría
  IF NOT f_verificar_cuenta_usuario(p_categoria_cuentaid) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que la categoría existe
  DECLARE
    v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy
    FROM categoria
    WHERE id = p_categoria_id
      AND cuentaid = p_categoria_cuentaid;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'La categoría indicada no existe.');
  END;

  -- Paso 3: Insertar relaciones para productos sin categoría
  INSERT INTO relacionproductocategoria (
    categoriaid, categoriacuentaid, productogtin, productocuentaid
  )
  SELECT
    p_categoria_id, p_categoria_cuentaid, pr.gtin, pr.cuentaid
  FROM producto pr
  WHERE pr.cuentaid = p_categoria_cuentaid
    AND NOT EXISTS (
      SELECT 1 FROM relacionproductocategoria rpc
      WHERE rpc.productogtin = pr.gtin
        AND rpc.productocuentaid = pr.cuentaid
    );

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_migrar_productos_a_categoria',
      v_mensaje
    );
    RAISE;
END;
/

