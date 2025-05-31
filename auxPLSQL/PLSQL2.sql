-- PAQUETE FUNCIONES AVANZADAS ---
--SI COMPILAN--


create or replace package pkg_admin_productos_avanzado is
  ---------------------------------------------------------------------------
  -- EXCEPCIONES PERSONALIZADAS
  ---------------------------------------------------------------------------
   exception_plan_no_asignado exception;

  ---------------------------------------------------------------------------
  -- FUNCIONES
  ---------------------------------------------------------------------------
   function f_validar_plan_suficiente (
      p_cuenta_id in cuenta.id%type
   ) return varchar2;

   function f_lista_categorias_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuentaid%type
   ) return varchar2;

  ---------------------------------------------------------------------------
  -- PROCEDIMIENTOS
  ---------------------------------------------------------------------------
   procedure p_migrar_productos_a_categoria (
      p_categoria_id       in categoria.id%type,
      p_categoria_cuentaid in categoria.cuentaid%type
   );

   procedure p_replicar_atributos (
      p_gtin_origen in producto.gtin%type,
      p_cuenta_id   in producto.cuentaid%type
   );

end pkg_admin_productos_avanzado;
/



--CUERPO DEL PAQUETE
create or replace package body pkg_admin_productos_avanzado IS

--F1:: f_validar_plan_suficiente

FUNCTION f_validar_plan_suficiente (
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

--F2: f_lista_categorias_producto

FUNCTION f_lista_categorias_producto (
  p_producto_gtin IN producto.gtin%TYPE,
  p_cuenta_id     IN producto.cuentaid%TYPE
) RETURN VARCHAR2
IS
  v_lista   VARCHAR2(1000) := '';
  v_mensaje VARCHAR2(500);
BEGIN
  --------------------------------------------------------------------------
  -- Paso 1: Verificar acceso del usuario a la cuenta
  --------------------------------------------------------------------------
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado.');
  END IF;

  --------------------------------------------------------------------------
  -- Paso 2: Verificar que el producto existe en la tabla PRODUCTO
  --------------------------------------------------------------------------
  DECLARE
    v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy
    FROM producto
    WHERE gtin = p_producto_gtin AND cuentaid = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE NO_DATA_FOUND; -- Producto no existe
  END;

  --------------------------------------------------------------------------
  -- Paso 3: Obtener categorías y concatenarlas con delimitador ' ; '
  --------------------------------------------------------------------------
  FOR cat IN (
    SELECT c.nombre
    FROM relacionproductocategoria rpc
    JOIN categoria c
      ON rpc.categoriaid = c.id AND rpc.categoriacuentaid = c.cuentaid
    WHERE rpc.productogtin = p_producto_gtin
      AND rpc.productocuentaid = p_cuenta_id
  ) LOOP
    IF v_lista IS NOT NULL AND v_lista != '' THEN
      v_lista := v_lista || ' ; ' || cat.nombre;
    ELSE
      v_lista := cat.nombre;
    END IF;
  END LOOP;

  --------------------------------------------------------------------------
  -- Paso 4: Devolver la lista (o cadena vacía si no hay categorías)
  --------------------------------------------------------------------------
  RETURN NVL(v_lista, '');

EXCEPTION
  --------------------------------------------------------------------------
  -- Si no se encuentra el producto
  --------------------------------------------------------------------------
  WHEN NO_DATA_FOUND THEN
    RETURN 'Sin categoría'; -- O RETURN '' si prefieres cadena vacía

  --------------------------------------------------------------------------
  -- Captura de cualquier otro error: registrar en TRAZA y relanzar
  --------------------------------------------------------------------------
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'f_lista_categorias_producto',
      v_mensaje
    );
    RAISE;
END f_lista_categorias_producto;

--P3: p_migrar_productos_a_categorias
PROCEDURE p_migrar_productos_a_categoria (
  p_cuenta_id            IN cuenta.id%TYPE,
  p_categoria_origen_id  IN categoria.id%TYPE,
  p_categoria_destino_id IN categoria.id%TYPE
)
IS
  v_mensaje VARCHAR2(500);
  dummy NUMBER;

  -- Cursor para recorrer productos en la categoría origen
  CURSOR c_productos IS
    SELECT productogtin, productocuentaid
    FROM relacionproductocategoria
    WHERE categoriaid = p_categoria_origen_id
      AND categoriacuentaid = p_cuenta_id
    FOR UPDATE;

BEGIN
  ---------------------------------------------------------------------------
  -- Paso 1: Verificar que el usuario tiene acceso a la cuenta
  ---------------------------------------------------------------------------
  IF NOT pkg_admin_productos.f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  ---------------------------------------------------------------------------
  -- Paso 2: Verificar que ambas categorías existen y pertenecen a la cuenta
  ---------------------------------------------------------------------------
  BEGIN
    -- Verificar categoría origen
    SELECT 1
    INTO dummy
    FROM categoria
    WHERE id = p_categoria_origen_id AND cuentaid = p_cuenta_id;

    -- Verificar categoría destino
    SELECT 1
    INTO dummy
    FROM categoria
    WHERE id = p_categoria_destino_id AND cuentaid = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'Una de las categorías no existe o no pertenece a la cuenta.');
  END;

  ---------------------------------------------------------------------------
  -- Paso 3: Migrar los productos de la categoría origen a la categoría destino
  ---------------------------------------------------------------------------
  FOR r IN c_productos LOOP
    -- Evitar duplicados: comprobar si ya existe en la categoría destino
    BEGIN
      SELECT 1 INTO dummy
      FROM relacionproductocategoria
      WHERE categoriaid = p_categoria_destino_id
        AND categoriacuentaid = p_cuenta_id
        AND productogtin = r.productogtin
        AND productocuentaid = r.productocuentaid;

      -- Si llega aquí, ya existe => lo borramos de la categoría origen
      DELETE FROM relacionproductocategoria
      WHERE categoriaid = p_categoria_origen_id
        AND categoriacuentaid = p_cuenta_id
        AND productogtin = r.productogtin
        AND productocuentaid = r.productocuentaid;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        -- No existe en la categoría destino, lo actualizamos (migramos)
        UPDATE relacionproductocategoria
        SET categoriaid = p_categoria_destino_id
        WHERE CURRENT OF c_productos;
    END;
  END LOOP;

  COMMIT;

EXCEPTION
  WHEN OTHERS THEN
    ROLLBACK;
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_migrar_productos_a_categoria',
      v_mensaje
    );
    RAISE;
END p_migrar_productos_a_categoria;

--P4:p_replicar_atributos

PROCEDURE p_replicar_atributos (
  p_gtin_origen IN producto.gtin%TYPE,
  p_cuenta_id   IN producto.cuentaid%TYPE
) IS
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Validar acceso
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto origen existe
  DECLARE
    v_dummy NUMBER;
  BEGIN
    SELECT 1 INTO v_dummy
    FROM producto
    WHERE gtin = p_gtin_origen AND cuentaid = p_cuenta_id;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RAISE_APPLICATION_ERROR(-20002, 'El producto origen no existe en la cuenta.');
  END;

  -- Paso 3: Insertar atributos del origen en productos que no los tienen
  INSERT INTO atributosproducto (
    atributoid, productogtin, productocuentaid, valor
  )
  SELECT
    ap.atributoid,
    pr.gtin,
    pr.cuentaid,
    ap.valor
  FROM atributosproducto ap
  JOIN producto pr ON pr.cuentaid = p_cuenta_id
  WHERE ap.productogtin = p_gtin_origen
    AND ap.productocuentaid = p_cuenta_id
    AND pr.gtin != p_gtin_origen
    AND NOT EXISTS (
      SELECT 1
      FROM atributosproducto ap2
      WHERE ap2.atributoid = ap.atributoid
        AND ap2.productogtin = pr.gtin
        AND ap2.productocuentaid = pr.cuentaid
    );

EXCEPTION
  WHEN OTHERS THEN
    v_mensaje := SUBSTR(SQLCODE || ' ' || SQLERRM, 1, 500);
    INSERT INTO traza VALUES (
      SYSDATE,
      SYS_CONTEXT('USERENV','SESSION_USER'),
      'p_replicar_atributos',
      v_mensaje
    );
    RAISE;
END;
--FIN DEL PAQUETE
END pkg_admin_productos_avanzado;
/


--JOBS
BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'J_LIMPIA_TRAZA',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
      BEGIN
        DELETE FROM traza
        WHERE fecha < SYSDATE - (1/1440);  -- 1 minuto para pruebas
        COMMIT;
      END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=MINUTELY;INTERVAL=2',
    enabled         => TRUE,
    comments        => 'Limpia entradas de TRAZA de más de 1 minuto (simula 1 año para pruebas)'
  );
END;
/

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'J_ACTUALIZA_PRODUCTOS',
    job_type        => 'PLSQL_BLOCK',
    job_action      => '
      DECLARE
        CURSOR c_cuentas IS SELECT id FROM cuenta;
      BEGIN
        FOR r IN c_cuentas LOOP
          pkg_admin_productos.p_actualizar_productos(r.id);
        END LOOP;
      END;',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=0;BYSECOND=0',
    enabled         => TRUE,
    comments        => 'Actualiza productos desde productos_ext para todas las cuentas cada noche'
  );
END;
/