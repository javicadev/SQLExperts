-- AHORA DEBEMOS DESARROLLAR EL CUERPO DEL PAQUETE
create or replace package body pkg_admin_productos is

   -- Función auxiliar: valida que el usuario conectado pertenece a la cuenta dada
   function f_verificar_cuenta_usuario (
      p_cuentaid in cuenta.id%type
   ) return boolean is
      v_dummy number;
   begin
      select 1
        into v_dummy
        from usuario
       where upper(nombreusuario) = upper(user)
         and cuentaid = p_cuentaid;

      return true;
   exception
      when no_data_found then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Acceso denegado a cuenta ID: ' || p_cuentaid );
         return false;
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         return false;
   end f_verificar_cuenta_usuario;



   --1. FUNCION F_OBTENER_PLAN_CUENTA
   function f_obtener_plan_cuenta (
      p_cuentaid in cuenta.id%type
   ) return plan%rowtype is
      v_plan    plan%rowtype;
      v_planid cuenta.planid%type;
   begin
      -- Paso 0: Verificar que el usuario conectado tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Buscar el planid de la cuenta. Esto también valida que la cuenta existe
      select planid
        into v_planid
        from cuenta
       where id = p_cuentaid;

      -- Paso 2: Verificar si el plan está asignado
      if v_planid is null then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'La cuenta no tiene un plan asignado' );
         raise exception_plan_no_asignado;
      end if;

      -- Paso 3: Recuperar el registro completo del plan
      select *
        into v_plan
        from plan
       where id = v_planid;

      return v_plan;
   exception
      when no_data_found then
         -- Error: no se encuentra la cuenta o el plan
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Cuenta o plan no encontrados' );
         raise;
      when others then
         -- Cualquier otro error inesperado
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en F_OBTENER_PLAN_CUENTA: ' || sqlerrm);
         raise;
   end f_obtener_plan_cuenta;


   -- 2. FUNCION F_CONTAR_PRODUCTOS_CUENTA
   function f_contar_productos_cuenta (
      p_cuentaid in cuenta.id%type
   ) return number is
      v_total number;
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Comprobar que la cuenta existe
      select 1
        into v_dummy
        from cuenta
       where id = p_cuentaid;

      -- Paso 2: Contar los productos asociados a esa cuenta
      select count(*)
        into v_total
        from producto
       where cuentaid = p_cuentaid;

      return v_total;
   exception
      when no_data_found then
         -- La cuenta no existe
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Cuenta no encontrada' );
         raise;
      when others then
         -- Cualquier otro error inesperado
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en F_CONTAR_PRODUCTOS_CUENTA: ' || sqlerrm);
         raise;
   end f_contar_productos_cuenta;

   -- 3. FUNCION F_VALIDAR_ATRIBUTOS_PRODUCTO
   function f_validar_atributos_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuentaid     in producto.cuentaid%type
   ) return boolean is
      v_total_atributos     number;
      v_atributos_asignados number;
      v_dummy               number;
   begin
      -- Paso 0: Verificar que el usuario tiene permiso sobre la cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Comprobar que el producto existe y pertenece a la cuenta
      select 1
        into v_dummy
        from producto
       where gtin = p_producto_gtin
         and cuentaid = p_cuentaid;

      -- Paso 2: Contar atributos definidos para la cuenta
      select count(*)
        into v_total_atributos
        from atributo
       where cuentaid = p_cuentaid;

      -- Paso 3: Contar atributos asignados al producto en ATRIBUTO_PRODUCTO
      select count(distinct atributo_codigo)
        into v_atributos_asignados
        from atributo_producto
       where producto_gtin = p_producto_gtin
         and producto_cuentaid = p_cuentaid;

      -- Paso 4: Comparar y devolver resultado lógico
      if v_total_atributos = v_atributos_asignados then
         return true;
      else
         return false;
      end if;
   exception
      when no_data_found then
         -- El producto no existe para esa cuenta
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Producto no encontrado con ese GTIN y cuenta' );
         raise;
      when others then
         -- Otros errores inesperados
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error en F_VALIDAR_ATRIBUTOS_PRODUCTO: ' || sqlerrm);
         raise;
   end f_validar_atributos_producto;

   -- 4. FUNCION F_NUM_CATEGORIAS_CUENTA
   function f_num_categorias_cuenta (
      p_cuentaid in cuenta.id%type
   ) return number is
      v_total number;
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario conectado tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Comprobar que la cuenta existe
      select 1
        into v_dummy
        from cuenta
       where id = p_cuentaid;

      -- Paso 2: Contar las categorías asociadas a la cuenta
      select count(*)
        into v_total
        from categoria
       where cuentaid = p_cuentaid;

      return v_total;
   exception
      when no_data_found then
         -- La cuenta no existe
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Cuenta no encontrada al contar categorías' );
         raise;
      when others then
         -- Cualquier otro error inesperado
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error en F_NUM_CATEGORIAS_CUENTA: ' || sqlerrm);
         raise;
   end f_num_categorias_cuenta;

   --5. PROCEDURE P_ACTUALIZAR_NOMBRE_PRODUCTO
   procedure p_actualizar_nombre_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuentaid     in producto.cuentaid%type,
      p_nuevo_nombre  in producto.nombre%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a la cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Validar que el nuevo nombre no es NULL ni vacío
      if p_nuevo_nombre is null
      or trim(p_nuevo_nombre) = '' then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Nombre del producto nulo o vacío' );
         raise invalid_data;
      end if;

      -- Paso 2: Comprobar que el producto existe para ese GTIN y cuenta
      select 1
        into v_dummy
        from producto
       where gtin = p_producto_gtin
         and cuentaid = p_cuentaid;

      -- Paso 3: Actualizar el nombre del producto
      update producto
         set
         nombre = p_nuevo_nombre
       where gtin = p_producto_gtin
         and cuentaid = p_cuentaid;

      dbms_output.put_line('Nombre del producto actualizado correctamente.');
   exception
      when no_data_found then
         -- No se encontró el producto
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Producto no encontrado para actualización de nombre' );
         raise;
      when invalid_data then
         -- Error personalizado ya registrado
         raise;
      when others then
         -- Otro error inesperado
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error en P_ACTUALIZAR_NOMBRE_PRODUCTO: ' || sqlerrm);
         raise;
   end p_actualizar_nombre_producto;

   --6. PROCEDURE P_ASOCIAR_ACTIVO_A_PRODUCTO

   procedure p_asociar_activo_a_producto (
      p_producto_gtin      in producto.gtin%type,
      p_producto_cuentaid in producto.cuentaid%type,
      p_activo_id          in activo.id%type,
      p_activo_cuentaid   in activo.cuentaid%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a ambas cuentas
      if not f_verificar_cuenta_usuario(p_producto_cuentaid)
      or not f_verificar_cuenta_usuario(p_activo_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: una o ambas cuentas no pertenecen al usuario.'
         );
      end if;

      -- Paso 1: Verificar que el producto existe para ese GTIN y cuenta
      begin
         select 1
           into v_dummy
           from producto
          where gtin = p_producto_gtin
            and cuentaid = p_producto_cuentaid;
      exception
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Producto no encontrado para asociación' );
            raise;
      end;

      -- Paso 2: Verificar que el activo existe para ese ID y cuenta
      begin
         select 1
           into v_dummy
           from activo
          where id = p_activo_id
            and cuentaid = p_activo_cuentaid;
      exception
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Activo no encontrado para asociación' );
            raise;
      end;

      -- Paso 3: Verificar si ya existe la asociación entre ese producto y ese activo
      begin
         select 1
           into v_dummy
           from act_pro
          where producto_gtin = p_producto_gtin
            and producto_cuentaid = p_producto_cuentaid
            and activo_id = p_activo_id
            and activo_cuentaid = p_activo_cuentaid;

         -- Si llega aquí es porque ya existe la asociación
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Asociación duplicada detectada' );
         raise exception_asociacion_duplicada;
      exception
         when no_data_found then
            null; -- Perfecto, no existe aún: seguimos
      end;

      -- Paso 4: Crear la nueva asociación
      insert into act_pro (
         producto_gtin,
         producto_cuentaid,
         activo_id,
         activo_cuentaid
      ) values ( p_producto_gtin,
                 p_producto_cuentaid,
                 p_activo_id,
                 p_activo_cuentaid );

      dbms_output.put_line('Asociación producto-activo creada correctamente.');
   exception
      when exception_asociacion_duplicada then
         -- Ya registrado arriba, solo mostramos mensaje adicional
         dbms_output.put_line('Error: asociación ya existente entre producto y activo.');
      when others then
         -- Cualquier otro error
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en P_ASOCIAR_ACTIVO_A_PRODUCTO: ' || sqlerrm);
         raise;
   end p_asociar_activo_a_producto;

   --7. PROCEDURE P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES
   procedure p_eliminar_producto_y_asociaciones (
      p_producto_gtin in producto.gtin%type,
      p_cuentaid     in producto.cuentaid%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar acceso del usuario a la cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Verificar existencia del producto
      select 1
        into v_dummy
        from producto
       where gtin = p_producto_gtin
         and cuentaid = p_cuentaid;

      -- Paso 2: Iniciar bloque transaccional
      begin
         -- Eliminar relaciones de la tabla ACT_PRO
         delete from act_pro
          where producto_gtin = p_producto_gtin
            and producto_cuentaid = p_cuentaid;

         -- Eliminar valores de la tabla ATRIBUTO_PRODUCTO
         delete from atributo_producto
          where producto_gtin = p_producto_gtin
            and producto_cuentaid = p_cuentaid;

         -- Eliminar asociaciones de categoría en PROD_CAT
         delete from prod_cat
          where producto_gtin = p_producto_gtin
            and producto_cuentaid = p_cuentaid;

         -- Eliminar relaciones en la tabla RELACIONADO
         delete from relacionado
          where ( producto1_gtin = p_producto_gtin
            and producto1_cuentaid = p_cuentaid )
             or ( producto2_gtin = p_producto_gtin
            and producto2_cuentaid = p_cuentaid );

         -- Finalmente, eliminar el producto
         delete from producto
          where gtin = p_producto_gtin
            and cuentaid = p_cuentaid;

         dbms_output.put_line('Producto y todas sus asociaciones eliminados correctamente.');
      exception
         when others then
            -- Si algo falla, se hace rollback implícito (todo dentro de mismo bloque BEGIN...END)
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       sqlcode
                                       || ' '
                                       || sqlerrm );
            dbms_output.put_line('Error en la eliminación del producto y sus asociaciones: ' || sqlerrm);
            raise;
      end;

   exception
      when no_data_found then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Producto no encontrado para eliminar' );
         raise;
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en P_ELIMINAR_PRODUCTO_Y_ASOCIACIONES: ' || sqlerrm);
         raise;
   end p_eliminar_producto_y_asociaciones;

   --8.  PROCEDURE P_ACTUALIZAR_PRODUCTOS
   procedure p_actualizar_productos (
      p_cuentaid in cuenta.id%type
   ) is
      cursor c_ext is
      select gtin,
             nombre
        from productos_ext
       where cuentaid = p_cuentaid;

      v_gtin          producto.gtin%type;
      v_nombre        producto.nombre%type;
      v_nombre_actual producto.nombre%type;
      cursor c_internos is
      select gtin
        from producto
       where cuentaid = p_cuentaid;

      type t_gtns is
         table of producto.gtin%type index by varchar2(40);
      tabla_ext_gtns  t_gtns;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuentaid) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Recorrer los productos en PRODUCTOS_EXT y sincronizar
      for r in c_ext loop
         begin
            -- Intentar obtener el nombre actual del producto en PRODUCTO
            select nombre
              into v_nombre_actual
              from producto
             where gtin = r.gtin
               and cuentaid = p_cuentaid;

            -- Si el nombre ha cambiado, se actualiza
            if v_nombre_actual != r.nombre then
               p_actualizar_nombre_producto(
                  r.gtin,
                  p_cuentaid,
                  r.nombre
               );
            end if;

         exception
            when no_data_found then
               -- El producto no existe: insertamos uno nuevo
               insert into producto (
                  gtin,
                  nombre,
                  cuentaid
               ) values ( r.gtin,
                          r.nombre,
                          p_cuentaid );

               dbms_output.put_line('Producto nuevo insertado desde PRODUCTOS_EXT: ' || r.gtin);
         end;

         -- Registrar GTIN como existente en PRODUCTOS_EXT
         tabla_ext_gtns(r.gtin) := 1;
      end loop;

      -- Paso 2: Eliminar los productos que están en PRODUCTO pero ya no en PRODUCTOS_EXT
      for r in c_internos loop
         if not tabla_ext_gtns.exists(r.gtin) then
            p_eliminar_producto_y_asociaciones(
               r.gtin,
               p_cuentaid
            );
            dbms_output.put_line('Producto eliminado por no estar en PRODUCTOS_EXT: ' || r.gtin);
         end if;
      end loop;

   exception
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en P_ACTUALIZAR_PRODUCTOS: ' || sqlerrm);
         raise;
   end p_actualizar_productos;

-- 9. PROCEDURE P_CREAR USUARIO
   procedure p_crear_usuario (
      p_usuario  in usuario%rowtype,
      p_rol      in varchar2,
      p_password in varchar2
   ) is
   begin
      -- Paso 1: Insertar en la tabla USUARIO
      insert into usuario (
         nombreusuario,
         cuentaid,
         nombre_completo,
         correoelectronico,
         telefono
      ) values ( p_usuario.nombreusuario,
                 p_usuario.cuentaid,
                 p_usuario.nombre_completo,
                 p_usuario.correoelectronico,
                 p_usuario.telefono );

      -- Paso 2: Crear usuario de base de datos
      execute immediate 'CREATE USER '
                        || p_usuario.nombreusuario
                        || ' IDENTIFIED BY "'
                        || p_password
                        || '"';

      -- Paso 3: Asignar rol
      execute immediate 'GRANT '
                        || p_rol
                        || ' TO '
                        || p_usuario.nombreusuario;

      -- Paso 4: Conceder permisos básicos (ejemplo: conexión, uso de sinónimos, etc.)
      execute immediate 'GRANT CONNECT TO ' || p_usuario.nombreusuario;
      execute immediate 'GRANT SELECT, INSERT, UPDATE, DELETE ON producto TO ' || p_usuario.nombreusuario;

      -- Paso 5: Crear sinónimos (ejemplo)
      execute immediate 'CREATE SYNONYM '
                        || p_usuario.nombreusuario
                        || '.producto FOR producto';
      dbms_output.put_line('Usuario creado correctamente con nombre: ' || p_usuario.nombreusuario);
   exception
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Error al crear usuario: '
                                    || sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error inesperado en P_CREAR_USUARIO: ' || sqlerrm);
         raise;
   end p_crear_usuario;

-- CERRAMOS PAQUETE
end pkg_admin_productos;
/