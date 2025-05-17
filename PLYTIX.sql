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

-- ESPECIFICACIÓN DEL PAQUETE
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

--CUERPO DEL PAQUETE
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
END p_crear_usuario;
END pkg_admin_productos;
/


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