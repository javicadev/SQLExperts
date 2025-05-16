-- PAQUETE FUNCIONES BÁSICAS ---
--SI COMPILAN--

--auxiliar
CREATE OR REPLACE FUNCTION f_verificar_cuenta_usuario (
  p_cuentaid IN cuenta.id%TYPE
) RETURN BOOLEAN IS
  v_dummy NUMBER;
BEGIN
  SELECT 1
  INTO v_dummy
  FROM usuario
  WHERE UPPER(nombreusuario) = UPPER(SYS_CONTEXT('USERENV','SESSION_USER'))
    AND cuentaid = p_cuentaid;

  RETURN TRUE;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      'El usuario no pertenece a la cuenta indicada.'
    );
    RETURN FALSE;

  WHEN OTHERS THEN
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_verificar_cuenta_usuario',
      SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500)
    );
    RETURN FALSE;
END;
/


--F1
CREATE OR REPLACE FUNCTION f_obtener_plan_cuenta (
  p_cuenta_id IN cuenta.id%TYPE
) RETURN plan%ROWTYPE IS
  v_plan     plan%ROWTYPE;
  v_mensaje  VARCHAR2(500);
BEGIN
  -- QUITAMOS verificación de usuario porque no tienes función auxiliar aún

  SELECT p.id, p.productos, p.activos, p.almacenamiento,
         p.categoriasproducto, p.categoriasactivos, p.relaciones,
         p.precioanual, p.nombre
  INTO v_plan
  FROM cuenta c
  JOIN plan p ON c.planid = p.id
  WHERE c.id = p_cuenta_id;

  RETURN v_plan;

EXCEPTION
  WHEN NO_DATA_FOUND THEN
    v_mensaje := 'Cuenta inexistente o sin plan asociado';
    INSERT INTO traza VALUES (SYSDATE, USER, 'f_obtener_plan_cuenta', v_mensaje);
    RAISE;

  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (SYSDATE, USER, 'f_obtener_plan_cuenta', v_mensaje);
    RAISE;
END;
/