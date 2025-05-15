-- TRABAJO EN GRUPO. ADMINISTRACIÓN DE BASES DE DATOS
-- JAVIER CARRASCO, JUAN ELÍAS LARA, JUAN MANUEL GARCÍA, PABLO


-- NIVEL FISICO 1

-- EN SYSTEM
-- AL REINICIAR LA MAQUINA VIRTUAL, CREAMOS TDE Y ABRIMOS WALLET

alter system set "WALLET_ROOT" = 'C:\app\alumnos\admin\orcl\wallet' scope = spfile;

alter system set tde_configuration = "KEYSTORE_CONFIGURATION=FILE" scope = both;

--Creamos tablespaces
create tablespace ts_plytix
   datafile 'TS_PLYTIX.DBF' size 10M
   autoextend on;
create tablespace ts_indices
   datafile 'TS_INDICES.DBF' size 50M
   autoextend on;

--Creamos el usuario, asignamos tablespace y quota
create user plytix identified by plytix123;
alter user plytix
   default tablespace ts_plytix;
alter user plytix
   quota 1G on ts_plytix;
alter user plytix
   quota 1G on ts_indices;

grant connect,resource,
   create table
to plytix;

-- Comprobamos que existen tablespaces y datafiles y que TS_PLYTIX está configurado por defecto
select *
  from dba_tablespaces;
select username,
       default_tablespace
  from dba_users
 where username = 'PLYTIX';
select tablespace_name,
       file_name
  from dba_data_files
 where tablespace_name in ( 'TS_PLYTIX',
                            'TS_INDICES' );


-- CREAMOS DIRECTORIO TABLAS EXTERNAS
create or replace directory directorio_ext as 'C:\app\alumnos\admin\orcl\dpdump';
-- Damos acceso a Plytix a realizar numerosas cosas
grant read,write on directory directorio_ext to plytix;
grant create materialized view to plytix;
grant create public synonym to plytix;
grant create sequence to plytix;


-- En Plytix
-- 2)CREACIÓN DEL ESQUEMA

create table activo (
   id       integer not null,
   nombre   varchar2(100 char) not null,
   tamano   integer not null,
   tipo     varchar2(100 char),
   url      varchar2(200 char),
   cuentaid integer not null
);



alter table activo
   add constraint activopk
      primary key ( id,
                    cuentaid )
         using index tablespace ts_indices;



create table atributo (
   id       integer not null,
   nombre   varchar2(100 char) not null,
   tipo     varchar2(50 char),
   creado   date not null,
   cuentaid integer not null
);



alter table atributo
   add constraint atributopk
      primary key ( id,
                    cuentaid )
         using index tablespace ts_indices;



create table atributosproducto (
   valor            varchar2(100 char) not null,
   productogtin     integer not null,
   atributoid       integer not null,
   productocuentaid integer not null
);



alter table atributosproducto
   add constraint atributosproductopk
      primary key ( productogtin,
                    productocuentaid,
                    atributoid )
         using index tablespace ts_indices;



create table categoria (
   id       integer not null,
   nombre   varchar2(100 char) not null,
   cuentaid integer not null
);



alter table categoria
   add constraint categoriapk
      primary key ( id,
                    cuentaid )
         using index tablespace ts_indices;



create table categoriaactivos (
   id       integer not null,
   nombre   varchar2(100 char) not null,
   cuentaid integer not null
);



alter table categoriaactivos
   add constraint categoriaactivospk
      primary key ( id,
                    cuentaid )
         using index tablespace ts_indices;



create table cuenta (
   id              integer not null,
   nombre          varchar2(100 char) not null,
   direcciónfiscal varchar2(200 char) not null,
   nif             varchar2(50 char) not null,
   fechaalta       date not null,
   planid          integer not null,
   usuariocuentaid integer,
   usuarioid       integer
);

create unique index cuentaidx on
   cuenta (
      usuarioid
   asc )
      tablespace ts_indices;



alter table cuenta
   add constraint cuentapk primary key ( id )
      using index tablespace ts_indices;



create table plan (
   id                 integer not null,
   productos          varchar2(100 char) not null,
   activos            varchar2(100 char) not null,
   almacenamiento     varchar2(100 char) not null,
   categoriasproducto varchar2(100 char) not null,
   categoriasactivos  varchar2(100 char) not null,
   relaciones         varchar2(100 char) not null,
   precioanual        varchar2(50 char) not null,
   nombre             varchar2(100 char) not null
);



alter table plan
   add constraint planpk primary key ( id )
      using index tablespace ts_indices;



create table producto (
   gtin       integer not null,
   sku        varchar2(100 char) not null,
   nombre     varchar2(100 char) not null,
   miniatura  varchar2(300 char),
   textocorto varchar2(300 char),
   creado     date not null,
   modificado date,
   cuentaid   integer not null
);



alter table producto
   add constraint productopk
      primary key ( gtin,
                    cuentaid )
         using index tablespace ts_indices;



create table relacionactivocategoriaactivo (
   activoid                 integer not null,
   activocuentaid           integer not null,
   categoriaactivosid       integer not null,
   categoriaactivoscuentaid integer not null
);



alter table relacionactivocategoriaactivo
   add constraint relacionactivocategoriaactivopk
      primary key ( activoid,
                    activocuentaid,
                    categoriaactivosid,
                    categoriaactivoscuentaid )
         using index tablespace ts_indices;



create table relacionproductoactivo (
   activoid         integer not null,
   activocuentaid   integer not null,
   productogtin     integer not null,
   productocuentaid integer not null
);



alter table relacionproductoactivo
   add constraint relacionproductoactivopk
      primary key ( activoid,
                    activocuentaid,
                    productogtin,
                    productocuentaid )
         using index tablespace ts_indices;



create table relacionproductocategoria (
   categoriaid       integer not null,
   categoriacuentaid integer not null,
   productogtin      integer not null,
   productocuentaid  integer not null
);



alter table relacionproductocategoria
   add constraint relacionproductocategoriapk
      primary key ( categoriaid,
                    categoriacuentaid,
                    productogtin,
                    productocuentaid )
         using index tablespace ts_indices;



create table relacionado (
   nombre            varchar2(100 char) not null,
   sentido           varchar2(100 char),
   productogtin      integer not null,
   productogtin1     integer not null,
   productocuentaid  integer not null,
   productocuentaid1 integer not null
);



alter table relacionado
   add constraint relacionadopk
      primary key ( productogtin,
                    productocuentaid,
                    productogtin1,
                    productocuentaid1 )
         using index tablespace ts_indices;



create table usuario (
   id                integer not null,
   nombreusuario     varchar2(100 char) not null,
   nombrecompleto    varchar2(100 char) not null,
   avatar            varchar2(200 char),
   correoelectronico varchar2(150 char) encrypt,
   telefono          integer encrypt,
   cuentaid          integer not null,
   cuentadueno       integer
);

create unique index usuarioidx on
   usuario (
      cuentadueno
   asc )
      tablespace ts_indices;



alter table usuario
   add constraint usuariopk primary key ( id )
      using index tablespace ts_indices;



alter table activo
   add constraint activocuentafk foreign key ( cuentaid )
      references cuenta ( id );



alter table atributosproducto
   add constraint atributosproductoatributofk
      foreign key ( atributoid,
                    productocuentaid )
         references atributo ( id,
                               cuentaid );



alter table atributosproducto
   add constraint atributosproductoproductofk
      foreign key ( productogtin,
                    productocuentaid )
         references producto ( gtin,
                               cuentaid );



alter table categoriaactivos
   add constraint categoriaactivoscuentafk foreign key ( cuentaid )
      references cuenta ( id );



alter table categoria
   add constraint categoriacuentafk foreign key ( cuentaid )
      references cuenta ( id );



alter table cuenta
   add constraint cuentaplanfk foreign key ( planid )
      references plan ( id );



alter table cuenta
   add constraint cuentausuariofk foreign key ( usuarioid )
      references usuario ( id );



alter table producto
   add constraint productocuentafk foreign key ( cuentaid )
      references cuenta ( id );



alter table relacionactivocategoriaactivo
   add constraint relacionactivocategoriaactivofk
      foreign key ( activoid,
                    activocuentaid )
         references activo ( id,
                             cuentaid );



alter table relacionactivocategoriaactivo
   add constraint relactivcategoriaactivosfk
      foreign key ( categoriaactivosid,
                    categoriaactivoscuentaid )
         references categoriaactivos ( id,
                                       cuentaid );



alter table relacionproductoactivo
   add constraint relacionproductoactivoactivofk
      foreign key ( activoid,
                    activocuentaid )
         references activo ( id,
                             cuentaid );



alter table relacionproductoactivo
   add constraint relacionproductoactivoproductofk
      foreign key ( productogtin,
                    productocuentaid )
         references producto ( gtin,
                               cuentaid );



alter table relacionproductocategoria
   add constraint relacionproductocategoriacategoriafk
      foreign key ( categoriaid,
                    categoriacuentaid )
         references categoria ( id,
                                cuentaid );



alter table relacionproductocategoria
   add constraint relacionproductocategoriaproductofk
      foreign key ( productogtin,
                    productocuentaid )
         references producto ( gtin,
                               cuentaid );



alter table relacionado
   add constraint relacionadoproductofk
      foreign key ( productogtin,
                    productocuentaid )
         references producto ( gtin,
                               cuentaid );



alter table relacionado
   add constraint relacionadoproductofkv2
      foreign key ( productogtin1,
                    productocuentaid1 )
         references producto ( gtin,
                               cuentaid );



alter table usuario
   add constraint usuariocuentafk foreign key ( cuentaid )
      references cuenta ( id );



alter table usuario
   add constraint usuariocuentafkv2 foreign key ( cuentadueno )
      references cuenta ( id );


-- Ponemos el NIF UNIQUE en cuenta
ALTER TABLE cuenta
ADD CONSTRAINT uq_cuenta_nif UNIQUE (nif);

-- 3. HEMOS IMPORTADO DATOS (TODO OK)
-- ¿COMO HEMOS IMPORTADO LOS DATOS? SIGUIENDO EL MANUAL DE LA PRACTICA E IMPORTANDO LOS CSV

-- 4. CREAMOS LAS TABLAS EXTERNAS
create table productos_ext (
   sku        varchar2(50),
   nombre     varchar2(100),
   textocorto varchar2(1000),
   creado     date,
   cuentaid   number
)
organization external ( type oracle_loader
   default directory directorio_ext access parameters (
      records delimited by newline
         skip 1
         characterset utf8
      fields terminated by ';' optionally enclosed by '"' missing field values are null (
         sku,
         nombre,
         textocorto,
         creado char ( 10 ) date_format date mask "dd/mm/yyyy",
         cuentaid
      )
   ) location ( 'productos.csv' )
) reject limit unlimited;

--Comprobamos que va todo en orden haciendo algunas consultas sobre la tabla productos_ext
select * from productos_ext;

-- 5. INDICES
-- Añadimos clave primaria a Usuario y creamos el indices relevantes en TS_INDICES
--ÍNDICE FUNCIONAL SOBRE UPPER(nombrecompleto)
create index ix_upper_nombre on
   usuario (upper(nombrecompleto)) tablespace ts_indices;

-- INDICE FUNCIONAL SOBRE NOMBREUSUARIO
create index ix_nombreusuario on
   usuario (nombreusuario) tablespace ts_indices;

-- INDICE BITMAP SOBRE CUENTAID
create bitmap index ix_cuentaid_bitmap on
   usuario (
      cuentaid
   )
      tablespace ts_indices;

--VERIFICAR LOS ÍNDICES CREADOS
select index_name,
       index_type,
       tablespace_name
  from user_indexes
 where table_name = 'USUARIO';

-- VERIFICAR EN QUÉ TABLESPACE ESTÁ LA TABLA USUARIO
select table_name,
       tablespace_name
  from user_tables
 where table_name = 'USUARIO';

--6. CREAMOS VISTA MATERIALIZADA
create materialized view vm_productos build immediate
   refresh complete
   start with trunc(sysdate + 1)
   next trunc(sysdate + 1)
as
   select *
     from productos_ext;

--7 CREAMOS SINONIMO
create public synonym s_productos for vm_productos;

--8 CREAR SECUENCIA
create sequence seq_productos start with 1 increment by 1 nocache nocycle;

--CREAR TRIGGER PARA ASIGNAR GTIN AUTOMÁTICAMENTE
create or replace trigger tr_productos before
   insert on producto
   for each row
begin
   if :new.gtin is null then
      :new.gtin := seq_productos.nextval;
   end if;
end tr_productos;
/

-- CARGAR DATOS DESDE LA TABLA EXTERNA USANDO EL SINÓNIMO S_PRODUCTOS

insert into producto (
   sku,
   nombre,
   textocorto,
   creado,
   cuentaid
)
   select sku,
          nombre,
          textocorto,
          creado,
          cuentaid
     from s_productos;


---------------------------------------------------------------------------
-- NIVEL FISICO 2

-- en system :Crear roles
CREATE ROLE administrador_sistema;
CREATE ROLE usuario_estandar;
CREATE ROLE gestor_cuentas;
CREATE ROLE planificador_servicios;
--en sys, PARA EL VPD (permite implementar VPD)
GRANT EXECUTE ON DBMS_RLS TO PLYTIX;

-- desde plytix
-- Añadir campo PUBLICO a la tabla PRODUCTO si no existe
ALTER TABLE PRODUCTO ADD PUBLICO CHAR(1) DEFAULT 'S' CHECK (PUBLICO IN ('S', 'N'));
-- creamos vista que muestra solo productos públicos
CREATE OR REPLACE VIEW V_PRODUCTO_PUBLICO AS
SELECT * FROM PRODUCTO WHERE PUBLICO = 'S';

-- Otorgar permisos CRUD al rol usuario_estandar
--Porque el usuario_estandar debe poder gestionar sus productos (alta, baja, modificación) y consultar productos públicos.
GRANT SELECT, INSERT, UPDATE, DELETE ON PRODUCTO TO usuario_estandar;
GRANT SELECT ON V_PRODUCTO_PUBLICO TO usuario_estandar;


-- Permitimos que el usuario estándar gestione (CRUD) los activos de su cuenta.
-- Este permiso se otorga sobre la tabla ACTIVO, pero el control real de acceso por cuenta
-- debe garantizarse con VPD (Política de seguridad) o mediante triggers.

GRANT SELECT, INSERT, UPDATE, DELETE ON ACTIVO TO usuario_estandar;

-- Permitimos gestionar la tabla de relación entre activos y categorías.
-- De nuevo, se asume que se controla que los activos y categorías sean de la misma cuenta.

GRANT SELECT, INSERT, UPDATE, DELETE ON Categoriaactivos TO usuario_estandar;
GRANT SELECT, INSERT, UPDATE, DELETE ON RELACIONACTIVOCATEGORIAACTIVO TO usuario_estandar;


--PARA QUE El usuario no puede insertar productos en otra cuenta distinta a la suya
--cuenta_id en producto debe venir de USUARIO
CREATE OR REPLACE TRIGGER TR_PRODUCTOS
BEFORE INSERT ON PRODUCTO
FOR EACH ROW
DECLARE
  v_cuenta_id NUMBER;
BEGIN
  -- Generar GTIN si no se indica
  IF :NEW.GTIN IS NULL THEN
    :NEW.GTIN := SEQ_PRODUCTOS.NEXTVAL;
  END IF;

  -- Obtener la cuenta del usuario conectado por nombre de sesión (igual que la vista V_PRODUCTOS_USUARIO)
  SELECT CuentaId INTO v_cuenta_id
  FROM USUARIO
  WHERE NombreUsuario = USER;

  -- Asignar la cuenta al producto
  :NEW.CuentaId := v_cuenta_id;
END;
/

--ASIGNAR AUTOMATICAMENTE CUENTAID AL ACTIVO AL INSERTARLO, PARA NO DEJAR Q SE INSERTE DESDE UNA CUENTA Q NO SEA LA SUYA
CREATE OR REPLACE TRIGGER TR_ACTIVO
BEFORE INSERT ON ACTIVO
FOR EACH ROW
DECLARE
  v_cuenta_id NUMBER;
BEGIN
  -- Obtener la cuenta del usuario conectado
  SELECT CuentaId INTO v_cuenta_id
  FROM USUARIO
  WHERE NombreUsuario = USER;

  -- Asignar la cuenta al activo
  :NEW.CuentaId := v_cuenta_id;
END;
/

--Esta vista garantiza que muestra relaciones validas entre Categoría y Activo que pertenezcan a la misma cuenta
CREATE OR REPLACE VIEW V_REL_ACTIVO_CAT_VALIDAS AS
SELECT r.* FROM RelacionActivoCategoriaActivo r
JOIN Activo a ON r.ActivoId = a.Id AND r.ActivoCuentaId = a.CuentaId
JOIN CategoriaActivos c ON r.CategoriaActivosId = c.Id AND r.CategoriaActivosCuentaId = c.CuentaId
WHERE a.CuentaId = c.CuentaId;

GRANT SELECT ON V_REL_ACTIVO_CAT_VALIDAS TO usuario_estandar;

--Asegura que la relación Activo-Categoría sea entre ambos elementos sean de la misma cuenta
-- y la vista permite consultar solo relaciones válidas.
create or replace trigger tr_valida_rel_activo_cat before
   insert or update on relacionactivocategoriaactivo
   for each row
declare
   v_cuenta_activo    number;
   v_cuenta_categoria number;
begin

  -- Obtener la cuenta real del activo
   select cuentaid
     into v_cuenta_activo
     from activo
    where id = :new.activoid;
  -- Obtener la cuenta real de la categoría
   select cuentaid
     into v_cuenta_categoria
     from categoriaactivos
    where id = :new.categoriaactivosid;
  -- Validar que ambos pertenezcan a la misma cuenta
   if v_cuenta_activo != v_cuenta_categoria then
      raise_application_error(
         -20001,
         'El Activo y la Categoría deben pertenecer a la misma cuenta.'
      );
   end if;
end;
/

-- Permisos sobre la tabla CATEGORIA
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIA TO usuario_estandar;

-- Permisos sobre la tabla intermedia de relación producto-categoría
GRANT SELECT, INSERT, UPDATE, DELETE ON RelacionProductoCategoria TO usuario_estandar;

CREATE OR REPLACE VIEW V_REL_PRODUCTO_CATEGORIA_VALIDAS AS
SELECT rpc.*
FROM RelacionProductoCategoria rpc
JOIN Producto p ON rpc.ProductoGTIN = p.GTIN AND rpc.ProductoCuentaId = p.CuentaId
JOIN Categoria c ON rpc.CategoriaId = c.Id AND rpc.CategoriaCuentaId = c.CuentaId
WHERE p.CuentaId = c.CuentaId;
GRANT SELECT ON V_REL_PRODUCTO_CATEGORIA_VALIDAS TO usuario_estandar;


CREATE OR REPLACE TRIGGER TR_REL_PRODUCTO_CATEGORIA
BEFORE INSERT OR UPDATE ON RelacionProductoCategoria
FOR EACH ROW
DECLARE
  v_cuenta_producto NUMBER;
  v_cuenta_categoria NUMBER;
BEGIN
  SELECT CuentaId INTO v_cuenta_producto
  FROM Producto
  WHERE GTIN = :NEW.ProductoGTIN;

  SELECT CuentaId INTO v_cuenta_categoria
  FROM Categoria
  WHERE Id = :NEW.CategoriaId;

  IF v_cuenta_producto != v_cuenta_categoria THEN
    RAISE_APPLICATION_ERROR(-20020, 'Producto y categoría deben pertenecer a la misma cuenta.');
  END IF;
END;
/
--PARA EL PUNTO DE RELACIONADO USAMOS VPD PARA CUMPLIR CON LA RUBRICA
CREATE OR REPLACE FUNCTION POLITICA_RELACIONADO (
  p_schema VARCHAR2,
  p_object VARCHAR2
)
RETURN VARCHAR2
AS
  v_cuenta_id NUMBER;
BEGIN
  -- Obtener el CuentaId del usuario conectado
  SELECT CuentaId INTO v_cuenta_id
  FROM USUARIO
  WHERE NombreUsuario = USER;

  -- Solo permitir acceso a relaciones donde ambos productos son de esa cuenta
  RETURN 'ProductoCuentaId = ' || v_cuenta_id || ' AND ProductoCuentaId1 = ' || v_cuenta_id;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN '1=0'; -- No permitir acceso si el usuario no está en la tabla USUARIO
END;
/
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'PLYTIX',
    object_name     => 'RELACIONADO',
    policy_name     => 'POLITICA_RELACIONADO_VPD',
    function_schema => 'PLYTIX',
    policy_function => 'POLITICA_RELACIONADO',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE
  );
END;
/
-- Dar permisos de CRUD al usuario estándar (VPD se encargará de restringir el acceso real)
GRANT SELECT, INSERT, UPDATE, DELETE ON RELACIONADO TO usuario_estandar;

--para atributo:Para que el usuario_estándar no pueda insertar atributos en cuentas ajenas, usamos este trigger:
CREATE OR REPLACE TRIGGER TR_ATRIBUTO
BEFORE INSERT ON ATRIBUTO
FOR EACH ROW
DECLARE
  v_cuenta_id NUMBER;
BEGIN
  SELECT CuentaId INTO v_cuenta_id
  FROM USUARIO
  WHERE NombreUsuario = USER;

  :NEW.CuentaId := v_cuenta_id;
END;
/
--Este trigger garantiza que el atributo y el producto pertenezcan a la misma cuenta del usuario conectado
CREATE OR REPLACE TRIGGER TR_ATRIBUTOS_PRODUCTO
BEFORE INSERT OR UPDATE ON AtributosProducto
FOR EACH ROW
DECLARE
  v_cuenta_usuario   NUMBER;
  v_cuenta_producto  NUMBER;
  v_cuenta_atributo  NUMBER;
BEGIN
  -- Cuenta del usuario conectado
  SELECT CuentaId INTO v_cuenta_usuario
  FROM USUARIO
  WHERE NombreUsuario = USER;

  -- Cuenta del producto
  SELECT CuentaId INTO v_cuenta_producto
  FROM PRODUCTO
  WHERE GTIN = :NEW.ProductoGTIN;

  -- Cuenta del atributo
  SELECT CuentaId INTO v_cuenta_atributo
  FROM ATRIBUTO
  WHERE Id = :NEW.AtributoId;

  -- Verificación
  IF v_cuenta_producto != v_cuenta_atributo OR v_cuenta_producto != v_cuenta_usuario THEN
    RAISE_APPLICATION_ERROR(-20040, 'El producto y el atributo deben ser de la misma cuenta del usuario.');
  END IF;
END;
/

CREATE OR REPLACE VIEW V_ATRIBUTOS_PRODUCTO_VALIDOS AS
SELECT ap.*
FROM AtributosProducto ap
JOIN PRODUCTO p ON ap.ProductoGTIN = p.GTIN AND ap.ProductoCuentaId = p.CuentaId
JOIN ATRIBUTO a ON ap.AtributoId = a.Id AND ap.ProductoCuentaId = a.CuentaId
WHERE p.CuentaId = a.CuentaId;


-- Permisos sobre tabla ATRIBUTO
GRANT SELECT, INSERT, UPDATE, DELETE ON ATRIBUTO TO usuario_estandar;

-- Permisos sobre tabla intermedia AtributosProducto
GRANT SELECT, INSERT, UPDATE, DELETE ON AtributosProducto TO usuario_estandar;

-- Permiso de lectura segura por vista
GRANT SELECT ON V_ATRIBUTOS_PRODUCTO_VALIDOS TO usuario_estandar;
--RF3 GESTION CUENTAS
GRANT SELECT, INSERT, UPDATE, DELETE ON CUENTA TO gestor_cuentas;
-- Se otorgan permisos de lectura y escritura completos sobre la tabla CUENTA al rol gestor_cuentas.
-- Además, se otorgan permisos de lectura parcial sobre la tabla USUARIO, limitados a campos no sensibles,
-- evitando el acceso a datos como correo electrónico o teléfono por razones de privacidad.

-- Crear vista solo con columnas NO sensibles
CREATE OR REPLACE VIEW V_USUARIO_PUBLICO AS
SELECT Id, NombreUsuario, NombreCompleto, Avatar, CuentaId
FROM USUARIO;

-- Otorgar permiso solo sobre la vista
GRANT SELECT ON V_USUARIO_PUBLICO TO gestor_cuentas;

--PARA EL RF4
GRANT SELECT, INSERT, UPDATE, DELETE ON PLAN TO planificador_servicios;

-----------------------------------------------------------------------------------------------
-- PL/SQL (PARTE 1)

-- Trabajo en grupo parte 1 PL/SQL --

-- PRIMERO: Creamos la tabla traza para poder registrar lo que pasa
create table traza (
   fecha       date default sysdate,
   usuario     varchar2(40),
   causante    varchar2(40),
   descripcion varchar2(500)
);
-- FECHA: se llena automáticamente con SYSDATE si no se especifica
-- USUARIO: quién está ejecutando el procedimiento.
-- CAUSANTE: nombre del procedimiento/función que falló ($$PLSQL_UNIT).
-- DESCRIPCION: mensaje del error (SQLCODE || ' ' || SQLERRM).

-- Ahora toca desarrollar el paquete que nos pide en el enunciado

create or replace package pkg_admin_productos is

   -- Excepciones personalizadas
   exception_plan_no_asignado exception;
   invalid_data exception;
   exception_asociacion_duplicada exception;

   -- Función de control de pertenencia
   function f_verificar_cuenta_usuario (
      p_cuenta_id in cuenta.id%type
   ) return boolean;

   -- FUNCIONES
   function f_obtener_plan_cuenta (
      p_cuenta_id in cuenta.id%type
   ) return plan%rowtype;

   function f_contar_productos_cuenta (
      p_cuenta_id in cuenta.id%type
   ) return number;

   function f_validar_atributos_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuenta_id%type
   ) return boolean;

   function f_num_categorias_cuenta (
      p_cuenta_id in cuenta.id%type
   ) return number;

   -- PROCEDIMIENTOS
   procedure p_actualizar_nombre_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuenta_id%type,
      p_nuevo_nombre  in producto.nombre%type
   );

   procedure p_asociar_activo_a_producto (
      p_producto_gtin      in producto.gtin%type,
      p_producto_cuenta_id in producto.cuenta_id%type,
      p_activo_id          in activos.id%type,
      p_activo_cuenta_id   in activos.cuenta_id%type
   );

   procedure p_eliminar_producto_y_asociaciones (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuenta_id%type
   );

   procedure p_actualizar_productos (
      p_cuenta_id in cuenta.id%type
   );

   procedure p_crear_usuario (
      p_usuario  in usuario%rowtype,
      p_rol      in varchar2,
      p_password in varchar2
   );

end pkg_admin_productos;

-- AHORA DEBEMOS DESARROLLAR EL CUERPO DEL PAQUETE

create or replace package body pkg_admin_productos is

   -- Función auxiliar: valida que el usuario conectado pertenece a la cuenta dada
   function f_verificar_cuenta_usuario (
      p_cuenta_id in cuenta.id%type
   ) return boolean is
      v_dummy number;
   begin
      select 1
        into v_dummy
        from usuario
       where upper(nombre_usuario) = upper(user)
         and cuenta_id = p_cuenta_id;

      return true;
   exception
      when no_data_found then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    'Acceso denegado a cuenta ID: ' || p_cuenta_id );
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
      p_cuenta_id in cuenta.id%type
   ) return plan%rowtype is
      v_plan    plan%rowtype;
      v_plan_id cuenta.plan_id%type;
   begin
      -- Paso 0: Verificar que el usuario conectado tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Buscar el plan_id de la cuenta. Esto también valida que la cuenta existe
      select plan_id
        into v_plan_id
        from cuenta
       where id = p_cuenta_id;

      -- Paso 2: Verificar si el plan está asignado
      if v_plan_id is null then
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
       where id = v_plan_id;

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
      p_cuenta_id in cuenta.id%type
   ) return number is
      v_total number;
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Comprobar que la cuenta existe
      select 1
        into v_dummy
        from cuenta
       where id = p_cuenta_id;

      -- Paso 2: Contar los productos asociados a esa cuenta
      select count(*)
        into v_total
        from producto
       where cuenta_id = p_cuenta_id;

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
      p_cuenta_id     in producto.cuenta_id%type
   ) return boolean is
      v_total_atributos     number;
      v_atributos_asignados number;
      v_dummy               number;
   begin
      -- Paso 0: Verificar que el usuario tiene permiso sobre la cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
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
         and cuenta_id = p_cuenta_id;

      -- Paso 2: Contar atributos definidos para la cuenta
      select count(*)
        into v_total_atributos
        from atributo
       where cuenta_id = p_cuenta_id;

      -- Paso 3: Contar atributos asignados al producto en ATRIBUTO_PRODUCTO
      select count(distinct atributo_codigo)
        into v_atributos_asignados
        from atributo_producto
       where producto_gtin = p_producto_gtin
         and producto_cuenta_id = p_cuenta_id;

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
      p_cuenta_id in cuenta.id%type
   ) return number is
      v_total number;
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario conectado tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado: esta cuenta no pertenece al usuario.'
         );
      end if;

      -- Paso 1: Comprobar que la cuenta existe
      select 1
        into v_dummy
        from cuenta
       where id = p_cuenta_id;

      -- Paso 2: Contar las categorías asociadas a la cuenta
      select count(*)
        into v_total
        from categoria
       where cuenta_id = p_cuenta_id;

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
      p_cuenta_id     in producto.cuenta_id%type,
      p_nuevo_nombre  in producto.nombre%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a la cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
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
         and cuenta_id = p_cuenta_id;

      -- Paso 3: Actualizar el nombre del producto
      update producto
         set
         nombre = p_nuevo_nombre
       where gtin = p_producto_gtin
         and cuenta_id = p_cuenta_id;

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
      p_producto_cuenta_id in producto.cuenta_id%type,
      p_activo_id          in activos.id%type,
      p_activo_cuenta_id   in activos.cuenta_id%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a ambas cuentas
      if not f_verificar_cuenta_usuario(p_producto_cuenta_id)
      or not f_verificar_cuenta_usuario(p_activo_cuenta_id) then
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
            and cuenta_id = p_producto_cuenta_id;
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
           from activos
          where id = p_activo_id
            and cuenta_id = p_activo_cuenta_id;
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
            and producto_cuenta_id = p_producto_cuenta_id
            and activo_id = p_activo_id
            and activo_cuenta_id = p_activo_cuenta_id;

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
         producto_cuenta_id,
         activo_id,
         activo_cuenta_id
      ) values ( p_producto_gtin,
                 p_producto_cuenta_id,
                 p_activo_id,
                 p_activo_cuenta_id );

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
      p_cuenta_id     in producto.cuenta_id%type
   ) is
      v_dummy number;
   begin
      -- Paso 0: Verificar acceso del usuario a la cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
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
         and cuenta_id = p_cuenta_id;

      -- Paso 2: Iniciar bloque transaccional
      begin
         -- Eliminar relaciones de la tabla ACT_PRO
         delete from act_pro
          where producto_gtin = p_producto_gtin
            and producto_cuenta_id = p_cuenta_id;

         -- Eliminar valores de la tabla ATRIBUTO_PRODUCTO
         delete from atributo_producto
          where producto_gtin = p_producto_gtin
            and producto_cuenta_id = p_cuenta_id;

         -- Eliminar asociaciones de categoría en PROD_CAT
         delete from prod_cat
          where producto_gtin = p_producto_gtin
            and producto_cuenta_id = p_cuenta_id;

         -- Eliminar relaciones en la tabla RELACIONADO
         delete from relacionado
          where ( producto1_gtin = p_producto_gtin
            and producto1_cuenta_id = p_cuenta_id )
             or ( producto2_gtin = p_producto_gtin
            and producto2_cuenta_id = p_cuenta_id );

         -- Finalmente, eliminar el producto
         delete from producto
          where gtin = p_producto_gtin
            and cuenta_id = p_cuenta_id;

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
      p_cuenta_id in cuenta.id%type
   ) is
      cursor c_ext is
      select gtin,
             nombre
        from productos_ext
       where cuenta_id = p_cuenta_id;

      v_gtin          producto.gtin%type;
      v_nombre        producto.nombre%type;
      v_nombre_actual producto.nombre%type;
      cursor c_internos is
      select gtin
        from producto
       where cuenta_id = p_cuenta_id;

      type t_gtns is
         table of producto.gtin%type index by varchar2(40);
      tabla_ext_gtns  t_gtns;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a esta cuenta
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
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
               and cuenta_id = p_cuenta_id;

            -- Si el nombre ha cambiado, se actualiza
            if v_nombre_actual != r.nombre then
               p_actualizar_nombre_producto(
                  r.gtin,
                  p_cuenta_id,
                  r.nombre
               );
            end if;

         exception
            when no_data_found then
               -- El producto no existe: insertamos uno nuevo
               insert into producto (
                  gtin,
                  nombre,
                  cuenta_id
               ) values ( r.gtin,
                          r.nombre,
                          p_cuenta_id );

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
               p_cuenta_id
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
         nombre_usuario,
         cuenta_id,
         nombre_completo,
         email,
         telefono
      ) values ( p_usuario.nombre_usuario,
                 p_usuario.cuenta_id,
                 p_usuario.nombre_completo,
                 p_usuario.email,
                 p_usuario.telefono );

      -- Paso 2: Crear usuario de base de datos
      execute immediate 'CREATE USER '
                        || p_usuario.nombre_usuario
                        || ' IDENTIFIED BY "'
                        || p_password
                        || '"';

      -- Paso 3: Asignar rol
      execute immediate 'GRANT '
                        || p_rol
                        || ' TO '
                        || p_usuario.nombre_usuario;

      -- Paso 4: Conceder permisos básicos (ejemplo: conexión, uso de sinónimos, etc.)
      execute immediate 'GRANT CONNECT TO ' || p_usuario.nombre_usuario;
      execute immediate 'GRANT SELECT, INSERT, UPDATE, DELETE ON producto TO ' || p_usuario.nombre_usuario;

      -- Paso 5: Crear sinónimos (ejemplo)
      execute immediate 'CREATE SYNONYM '
                        || p_usuario.nombre_usuario
                        || '.producto FOR producto';
      dbms_output.put_line('Usuario creado correctamente con nombre: ' || p_usuario.nombre_usuario);
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

-- PRUEBAS APARTE!!

-- PL/SQL (PARTE 2)
-- Trabajo en grupo parte 2 PL/SQL

-- Creamos el paquet pkg_admin_productos_avanzado que contiene las funciones y procedimientos
-- necesarios para la migracion de productos y la asociacion de activos a productos

create or replace package pkg_admin_productos_avanzado is

   -- Excepciones personalizadas
   exception_plan_no_asignado exception;

   -- FUNCIONES
   function f_validar_plan_suficiente (
      p_cuenta_id in cuenta.id%type
   ) return varchar2;

   function f_lista_categorias_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuenta_id%type
   ) return varchar2;

   -- PROCEDIMIENTOS
   procedure p_migrar_productos_a_categoria (
      p_cuenta_id            in cuenta.id%type,
      p_categoria_origen_id  in categoria.id%type,
      p_categoria_destino_id in categoria.id%type
   );

   procedure p_replicar_atributos (
      p_cuenta_id             in cuenta.id%type,
      p_producto_gtin_origen  in producto.gtin%type,
      p_producto_gtin_destino in producto.gtin%type
   );

end pkg_admin_productos_avanzado;

create or replace package body pkg_admin_productos_avanzado is


-- 1. FUNCION: F_VALIDAR_PLAN_SUFICIENTE
   function f_validar_plan_suficiente (
      p_cuenta_id in cuenta.id%type
   ) return varchar2 is
      v_plan        plan%rowtype;
      v_productos   number;
      v_activos     number;
      v_cat_prod    number;
      v_cat_activos number;
      v_relaciones  number;
   begin
      -- Paso 0: Verificar acceso del usuario
      if not pkg_admin_productos.f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado a la cuenta.'
         );
      end if;

      -- Paso 1: Obtener plan de la cuenta
      begin
         v_plan := pkg_admin_productos.f_obtener_plan_cuenta(p_cuenta_id);
      exception
         when pkg_admin_productos.exception_plan_no_asignado then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Cuenta sin plan' );
            raise exception_plan_no_asignado;
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Cuenta no encontrada' );
            raise;
      end;

      -- Paso 2: Contar recursos directamente

      select count(*)
        into v_productos
        from producto
       where cuenta_id = p_cuenta_id;
      select count(*)
        into v_activos
        from activos
       where cuenta_id = p_cuenta_id;
      select count(distinct categoria_id)
        into v_cat_prod
        from prod_cat
       where producto_cuenta_id = p_cuenta_id;
      select count(*)
        into v_cat_activos
        from categoria_activo
       where cuenta_id = p_cuenta_id;
      select count(*)
        into v_relaciones
        from relacionado
       where producto1_cuenta_id = p_cuenta_id
          or producto2_cuenta_id = p_cuenta_id;

      -- Paso 3: Comparar con límites del plan
      if v_productos > v_plan.limite_productos then
         return 'INSUFICIENTE: PRODUCTOS';
      elsif v_activos > v_plan.limite_activos then
         return 'INSUFICIENTE: ACTIVOS';
      elsif v_cat_prod > v_plan.limite_categoriasproducto then
         return 'INSUFICIENTE: CATEGORIAS_PRODUCTO';
      elsif v_cat_activos > v_plan.limite_categoriasactivos then
         return 'INSUFICIENTE: CATEGORIAS_ACTIVOS';
      elsif v_relaciones > v_plan.limite_relaciones then
         return 'INSUFICIENTE: RELACIONES';
      else
         return 'SUFICIENTE';
      end if;

   exception
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error en F_VALIDAR_PLAN_SUFICIENTE: ' || sqlerrm);
         raise;
   end f_validar_plan_suficiente;

-- 2. FUNCION: F_LISTA_CATEGORIAS_PRODUCTO
   function f_lista_categorias_producto (
      p_producto_gtin in producto.gtin%type,
      p_cuenta_id     in producto.cuenta_id%type
   ) return varchar2 is
      v_lista  varchar2(1000) := '';
      v_nombre categoria.nombre%type;
      cursor c_categorias is
      select c.nombre
        from categoria c
        join prod_cat pc
      on c.id = pc.categoria_id
       where pc.producto_gtin = p_producto_gtin
         and pc.producto_cuenta_id = p_cuenta_id
         and c.cuenta_id = p_cuenta_id;
   begin
      -- Paso 0: Verificar que el usuario tiene acceso a la cuenta
      if not pkg_admin_productos.f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado a la cuenta.'
         );
      end if;

      -- Paso 1: Verificar que el producto existe en esa cuenta
      declare
         v_dummy number;
      begin
         select 1
           into v_dummy
           from producto
          where gtin = p_producto_gtin
            and cuenta_id = p_cuenta_id;
      exception
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Producto no encontrado' );
            raise;
      end;

      -- Paso 2: Concatenar nombres de categoría
      for r in c_categorias loop
         if
            v_lista is not null
            and v_lista != ''
         then
            v_lista := v_lista || ' ; ';
         end if;
         v_lista := v_lista || r.nombre;
      end loop;

      -- Paso 3: Si no hay categorías, devolver mensaje
      if v_lista is null
      or v_lista = '' then
         return 'Sin categoría';
      else
         return v_lista;
      end if;

   exception
      when others then
         insert into traza values ( sysdate,
                                    user,
                                    $$plsql_unit,
                                    sqlcode
                                    || ' '
                                    || sqlerrm );
         dbms_output.put_line('Error en F_LISTA_CATEGORIAS_PRODUCTO: ' || sqlerrm);
         raise;
   end f_lista_categorias_producto;

   procedure p_migrar_productos_a_categoria (
      p_cuenta_id            in cuenta.id%type,
      p_categoria_origen_id  in categoria.id%type,
      p_categoria_destino_id in categoria.id%type
   ) is
      cursor c_productos is
      select producto_gtin
        from prod_cat
       where categoria_id = p_categoria_origen_id
         and producto_cuenta_id = p_cuenta_id;

   begin
      -- Paso 0: Verificar que el usuario tiene acceso a la cuenta
      if not pkg_admin_productos.f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado a la cuenta.'
         );
      end if;

      -- Paso 1: Verificar existencia de la cuenta y ambas categorías
      declare
         v_dummy number;
      begin
         select 1
           into v_dummy
           from cuenta
          where id = p_cuenta_id;
         select 1
           into v_dummy
           from categoria
          where id = p_categoria_origen_id
            and cuenta_id = p_cuenta_id;
         select 1
           into v_dummy
           from categoria
          where id = p_categoria_destino_id
            and cuenta_id = p_cuenta_id;
      exception
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Cuenta o categorías no existen o no pertenecen a la cuenta' );
            raise;
      end;

      -- Paso 2: Realizar las migraciones dentro de un bloque transaccional
      begin
         for r in c_productos loop
            update prod_cat
               set
               categoria_id = p_categoria_destino_id
             where producto_gtin = r.producto_gtin
               and producto_cuenta_id = p_cuenta_id
               and categoria_id = p_categoria_origen_id;
         end loop;

         dbms_output.put_line('Productos migrados correctamente.');
      exception
         when others then
            -- ROLLBACK implícito al fallar el bloque
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       sqlcode
                                       || ' '
                                       || sqlerrm );
            dbms_output.put_line('Error en migración de productos: ' || sqlerrm);
            raise;
      end;

   end p_migrar_productos_a_categoria;

   -- 3. PROCEDURE: P_REPLICAR_ATRIBUTOS
   procedure p_replicar_atributos (
      p_cuenta_id             in cuenta.id%type,
      p_producto_gtin_origen  in producto.gtin%type,
      p_producto_gtin_destino in producto.gtin%type
   ) is
      cursor c_origen is
      select atributo_codigo,
             valor
        from atributo_producto
       where producto_gtin = p_producto_gtin_origen
         and producto_cuenta_id = p_cuenta_id;

      v_existe number;
   begin
      -- Paso 0: Verificar que el usuario puede acceder a esta cuenta
      if not pkg_admin_productos.f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso denegado a la cuenta.'
         );
      end if;

      -- Paso 1: Verificar que ambos productos existen
      declare
         v_dummy number;
      begin
         select 1
           into v_dummy
           from producto
          where gtin = p_producto_gtin_origen
            and cuenta_id = p_cuenta_id;
         select 1
           into v_dummy
           from producto
          where gtin = p_producto_gtin_destino
            and cuenta_id = p_cuenta_id;
      exception
         when no_data_found then
            insert into traza values ( sysdate,
                                       user,
                                       $$plsql_unit,
                                       'Uno o ambos productos no existen' );
            raise;
            end;

      -- Paso 2: Recorremos los atributos del producto origen
            begin
               for r in c_origen loop
            -- Verificamos si ya existe el atributo en el producto destino
                  select count(*)
                    into v_existe
                    from atributo_producto
                   where producto_gtin = p_producto_gtin_destino
                     and producto_cuenta_id = p_cuenta_id
                     and atributo_codigo = r.atributo_codigo;

                  if v_existe = 0 then
               -- No existe: insertamos
                     insert into atributo_producto (
                        producto_gtin,
                        producto_cuenta_id,
                        atributo_codigo,
                        valor
                     ) values ( p_producto_gtin_destino,
                                p_cuenta_id,
                                r.atributo_codigo,
                                r.valor );
                  else
               -- Ya existe: actualizamos valor
                     update atributo_producto
                        set
                        valor = r.valor
                      where producto_gtin = p_producto_gtin_destino
                        and producto_cuenta_id = p_cuenta_id
                        and atributo_codigo = r.atributo_codigo;
                  end if;
               end loop;

               dbms_output.put_line('Atributos replicados correctamente.');
            exception
               when others then
                  insert into traza values ( sysdate,
                                             user,
                                             $$plsql_unit,
                                             sqlcode
                                             || ' '
                                             || sqlerrm );
                  dbms_output.put_line('Error durante la replicación: ' || sqlerrm);
                  raise;
            end;

      end p_replicar_atributos;

-- CERRAMOS PAQUETE
   end pkg_admin_productos_avanzado;

-- JOBS
begin
   dbms_scheduler.create_job(
      job_name        => 'J_LIMPIA_TRAZA',
      job_type        => 'PLSQL_BLOCK',
      job_action      => '
         BEGIN
            DELETE FROM traza WHERE fecha < SYSDATE - 1/1440;  -- más de 1 minuto
            COMMIT;
         END;',
      start_date      => systimestamp,
      repeat_interval => 'FREQ=MINUTELY; INTERVAL=2',
      enabled         => true
   );
end;

begin
   dbms_scheduler.create_job(
      job_name        => 'J_ACTUALIZA_PRODUCTOS',
      job_type        => 'PLSQL_BLOCK',
      job_action      => '
         DECLARE
            CURSOR c IS SELECT id FROM cuenta;
         BEGIN
            FOR r IN c LOOP
               PKG_ADMIN_PRODUCTOS.P_ACTUALIZAR_PRODUCTOS(r.id);
            END LOOP;
         END;',
      start_date      => systimestamp,
      repeat_interval => 'FREQ=DAILY',
      enabled         => true
   );
end;

----------