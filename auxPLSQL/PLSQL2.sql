-- PAQUETE FUNCIONES AVANZADAS ---
--SI COMPILAN--
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