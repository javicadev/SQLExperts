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

grant connect,resource,--perimitimos crrear objetos con resource
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
         using index tablespace ts_indices;--para q eñ omdoce de las clabes primarias sea tb el de ts_indices y no el por defecto



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
--No incluyo gtin ni modificado: gtin se genera automáticamente con un TRIGGER y SEQUENCE, y modificado se puede actualizar después.
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
   start with trunc(sysdate + 1)--mañana a las 00:00
   next trunc(sysdate + 1)--refrescará todos los días a las 00:00.
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

--desde system
GRANT CREATE VIEW TO plytix;

--desde plytix

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

--GRANT SELECT, INSERT, UPDATE, DELETE ON Categoriaactivos TO usuario_estandar;
GRANT SELECT, INSERT, UPDATE, DELETE ON RELACIONACTIVOCATEGORIAACTIVO TO usuario_estandar;


--PARA QUE El usuario no puede insertar productos en otra cuenta distinta a la suya
--cuenta_id en producto debe venir de USUARIO
CREATE OR REPLACE TRIGGER TR_PRODUCTOS
BEFORE INSERT ON PRODUCTO
FOR EACH ROW
DECLARE
  v_cuenta_id NUMBER;
BEGIN
if :new.GTIN is null then  
:new.GTIN := SEQ_PRODUCTOS.NEXTVAL; 
end if; 

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

--Esta vista garantiza que muestra relaciones validas entre activo y Categoría de activos  que pertenezcan a la misma cuenta
CREATE OR REPLACE VIEW V_REL_ACTIVO_CAT_VALIDAS AS
SELECT r.* FROM RelacionActivoCategoriaActivo r
JOIN Activo a ON r.ActivoId = a.Id AND r.ActivoCuentaId = a.CuentaId
JOIN CategoriaActivos c ON r.CategoriaActivosId = c.Id AND r.CategoriaActivosCuentaId = c.CuentaId
WHERE a.CuentaId = c.CuentaId;

GRANT SELECT ON V_REL_ACTIVO_CAT_VALIDAS TO usuario_estandar;

--Aseguramos que la relación Activo-Categoríaactivos sea entre ambos elementos  de la misma cuenta
-- y la vista permite consultar solo relaciones válidas.
create or replace trigger tr_valida_rel_activo_cat before
   insert or update on relacionactivocategoriaactivo
   for each row
declare
   v_cuenta_activo    number;
   v_cuenta_categoria number;
   v_cuenta_usuario number;

begin
--obtener cuenta real del user
  SELECT CuentaId INTO v_cuenta_usuario
  FROM USUARIO
  WHERE NombreUsuario = USER;
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
IF v_cuenta_activo != v_cuenta_categoria OR v_cuenta_activo != v_cuenta_usuario THEN
      raise_application_error(
         -20001,
         'El Activo y la Categoría deben pertenecer a la misma cuenta del usuario.'
      );
   end if;
end;
/

-- Permisos sobre la tabla CATEGORIA
GRANT SELECT, INSERT, UPDATE, DELETE ON CATEGORIA TO usuario_estandar;

-- Permisos sobre la tabla intermedia de relación producto-categoría
GRANT SELECT, INSERT, UPDATE, DELETE ON RelacionProductoCategoria TO usuario_estandar;
--vista para mostrar solo relaciones con producto y categoria de la misma cuenta
CREATE OR REPLACE VIEW V_REL_PRODUCTO_CATEGORIA_VALIDAS AS
SELECT rpc.*
FROM RelacionProductoCategoria rpc
JOIN Producto p ON rpc.ProductoGTIN = p.GTIN AND rpc.ProductoCuentaId = p.CuentaId
JOIN Categoria c ON rpc.CategoriaId = c.Id AND rpc.CategoriaCuentaId = c.CuentaId
WHERE p.CuentaId = c.CuentaId;
GRANT SELECT ON V_REL_PRODUCTO_CATEGORIA_VALIDAS TO usuario_estandar;

--trigger para comprobar que la cuenta del producto y la categoria es la misma al insertar o update
CREATE OR REPLACE TRIGGER TR_REL_PRODUCTO_CATEGORIA
BEFORE INSERT OR UPDATE ON RelacionProductoCategoria
FOR EACH ROW
DECLARE
  v_cuenta_producto NUMBER;
  v_cuenta_categoria NUMBER;
  v_cuenta_usuario NUMBER;
BEGIN
  --obtenr cuenta real del user
  SELECT CuentaId INTO v_cuenta_usuario
  FROM USUARIO
  WHERE NombreUsuario = USER;

--obtenr cuenta real del producto
  SELECT CuentaId INTO v_cuenta_producto
  FROM Producto
  WHERE GTIN = :NEW.ProductoGTIN;

--obtengo cuenta real de la actegoria
  SELECT CuentaId INTO v_cuenta_categoria
  FROM Categoria
  WHERE Id = :NEW.CategoriaId;

IF v_cuenta_producto != v_cuenta_categoria OR v_cuenta_producto != v_cuenta_usuario THEN
    RAISE_APPLICATION_ERROR(-20020, 'Producto y categoría deben pertenecer a la misma cuenta del usuario.');
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
--aplicamos la politica
BEGIN
  DBMS_RLS.ADD_POLICY(
    object_schema   => 'PLYTIX',
    object_name     => 'RELACIONADO',
    policy_name     => 'POLITICA_RELACIONADO_VPD',
    function_schema => 'PLYTIX',
    policy_function => 'POLITICA_RELACIONADO',
    statement_types => 'SELECT, INSERT, UPDATE, DELETE',
    update_check    => TRUE--tb cd update
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


--LLENAMOS OCN MAS DATOS
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (5, 'Ropa 5', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (6, 'Deporte 6', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (7, 'Electrónica 7', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (8, 'Juguetes 8', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (9, 'Electrónica 9', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (10, 'Accesorios 10', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (11, 'Ropa 11', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (12, 'Belleza 12', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (13, 'Electrónica 13', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (14, 'Jardín 14', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (15, 'Belleza 15', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (16, 'Juguetes 16', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (17, 'Deporte 17', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (18, 'Automóvil 18', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (19, 'Cocina 19', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (20, 'Jardín 20', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (21, 'Juguetes 21', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (22, 'Deporte 22', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (23, 'Belleza 23', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (24, 'Deporte 24', 1);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (25, 'Electrónica 25', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (26, 'Ropa 26', 2);
INSERT INTO CATEGORIA (ID, NOMBRE, CUENTAID) VALUES (27, 'Electrónica 27', 2);
commit;
INSERT INTO usuario (   id,nombreusuario, nombrecompleto,avatar,correoelectronico,telefono,cuentaid,cuentadueno)
VALUES (   1000, 'PLYTIX', 'Juane','https://avatar.example.com/juane.png','juane@plytix.com',600123456,1,1);
COMMIT;


INSERT INTO ACTIVO (ID, NOMBRE, TAMANO, TIPO, URL, CUENTAID) VALUES (501, 'Manual PDF', 1, 'Documento', 'https://plytix.com/manual501.pdf', 1);
INSERT INTO ACTIVO (ID, NOMBRE, TAMANO, TIPO, URL, CUENTAID) VALUES (502, 'Imagen Producto', 2, 'Imagen', 'https://plytix.com/imagen502.png', 1);
INSERT INTO ACTIVO (ID, NOMBRE, TAMANO, TIPO, URL, CUENTAID) VALUES (503, 'Garantía', 1, 'Documento', 'https://plytix.com/garantia503.pdf', 2);
INSERT INTO ATRIBUTO (ID, NOMBRE, TIPO, CREADO, CUENTAID) VALUES (101, 'Color', 'Texto', TO_DATE('2023-03-01', 'YYYY-MM-DD'), 1);
INSERT INTO ATRIBUTO (ID, NOMBRE, TIPO, CREADO, CUENTAID) VALUES (102, 'Peso', 'Número', TO_DATE('2023-05-15', 'YYYY-MM-DD'), 1);
INSERT INTO ATRIBUTO (ID, NOMBRE, TIPO, CREADO, CUENTAID) VALUES (103, 'Material', 'Texto', TO_DATE('2024-01-10', 'YYYY-MM-DD'), 2);
commit;

-- PRODUCTO 26
INSERT INTO producto (
  gtin, sku, nombre, miniatura, textocorto, creado, cuentaid, publico
) VALUES (
  26, 'SKU026', 'Producto 26', NULL, 'Descripción 26', SYSDATE, 1, 'S'
);

-- PRODUCTO 84
INSERT INTO producto (
  gtin, sku, nombre, miniatura, textocorto, creado, cuentaid, publico
) VALUES (
  84, 'SKU084', 'Producto 84', NULL, 'Descripción 84', SYSDATE, 1, 'S'
);

-- PRODUCTO 102
INSERT INTO producto (
  gtin, sku, nombre, miniatura, textocorto, creado, cuentaid, publico
) VALUES (
  102, 'SKU102', 'Producto 102', NULL, 'Descripción 102', SYSDATE, 1, 'S'
);

-- PRODUCTO 186
INSERT INTO producto (
  gtin, sku, nombre, miniatura, textocorto, creado, cuentaid, publico
) VALUES (
  186, 'SKU186', 'Producto 186', NULL, 'Descripción 186', SYSDATE, 1, 'S'
);


INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_26_84_1', 'directo', 26, 84, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_102_128_2', 'inverso', 102, 128, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_186_26_3', 'bidireccional', 186, 26, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_84_102_4', 'directo', 84, 102, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_128_186_5', 'inverso', 128, 186, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_26_102_6', 'bidireccional', 26, 102, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_84_186_7', 'directo', 84, 186, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_128_26_8', 'inverso', 128, 26, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_102_84_9', 'bidireccional', 102, 84, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_186_128_10', 'directo', 186, 128, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_26_128_11', 'inverso', 26, 128, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_84_26_12', 'bidireccional', 84, 26, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_102_186_13', 'directo', 102, 186, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_128_84_14', 'inverso', 128, 84, 1, 1);
INSERT INTO RELACIONADO (NOMBRE, SENTIDO, PRODUCTOGTIN, PRODUCTOGTIN1, PRODUCTOCUENTAID, PRODUCTOCUENTAID1) VALUES ('rel_186_102_15', 'bidireccional', 186, 102, 1, 1);
COMMIT;
INSERT INTO producto VALUES (128, 'SKU001', 'Smartphone X', NULL, 'Teléfono inteligente', SYSDATE, NULL, 1, 'S');
INSERT INTO atributo VALUES (1, 'Color', 'Texto', SYSDATE, 1);
INSERT INTO atributosproducto VALUES ('Negro', 128, 1, 1);
INSERT INTO activo VALUES (504, 'Imagen frontal', 1024, 'Imagen', 'http://example.com/img1.jpg', 1);
INSERT INTO activo VALUES (505, 'Imagen lateral', 1024, 'Imagen', 'http://example.com/img2.jpg', 1);

-- Producto 128 (Smartphone X) con activo 501 (Imagen frontal)
INSERT INTO relacionproductoactivo VALUES (501, 1, 128, 1);

-- Producto 128 con activo 502 (Imagen lateral)
INSERT INTO relacionproductoactivo VALUES (502, 1, 128, 1);

INSERT INTO atributosproducto VALUES ('Negro', 128, 101, 1);  
INSERT INTO atributosproducto VALUES ('500g', 128, 102, 1);  
INSERT INTO atributosproducto VALUES ('Aluminio', 128, 103, 1); 

INSERT INTO categoriaactivos (id, nombre, cuentaid) VALUES 
(1, 'Imágenes Principales', 1);
INSERT INTO categoriaactivos (id, nombre, cuentaid) VALUES 
(2, 'Imágenes Secundarias', 1);
INSERT INTO categoriaactivos (id, nombre, cuentaid) VALUES 
(3, 'Manuales de Usuario', 1);
INSERT INTO categoriaactivos (id, nombre, cuentaid) VALUES 
(4, 'Fichas Técnicas', 1);
INSERT INTO categoriaactivos (id, nombre, cuentaid) VALUES 
(5, 'Videos', 1);

INSERT INTO relacionactivocategoriaactivo (activoid, activocuentaid, categoriaactivosid, categoriaactivoscuentaid) VALUES 
(501, 1, 1, 1);
INSERT INTO relacionactivocategoriaactivo (activoid, activocuentaid, categoriaactivosid, categoriaactivoscuentaid) VALUES
(502, 1, 2, 1);
INSERT INTO relacionactivocategoriaactivo (activoid, activocuentaid, categoriaactivosid, categoriaactivoscuentaid) VALUES
(503, 1, 3, 1);
INSERT INTO relacionactivocategoriaactivo (activoid, activocuentaid, categoriaactivosid, categoriaactivoscuentaid) VALUES
(504, 1, 4, 1);

commit;

--POLITICA DE CONTRASEÑAS PERFIL
CREATE PROFILE perfil_plytix LIMIT
   PASSWORD_LIFE_TIME 45
   FAILED_LOGIN_ATTEMPTS 3
   PASSWORD_LOCK_TIME 0.0416; -- 1 hora


-- AL CREAR UN NUEVO USUARIO, SE ASIGNA EL PERFIL
CREATE USER plytixBasic IDENTIFIED BY plytix123 DEFAULT TABLESPACE ts_plytix;
-- Asignar roles al usuario
ALTER USER plytixBasic PROFILE perfil_plytix;

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
-- auxiliar
   FUNCTION f_verificar_cuenta_usuario (
      p_cuentaid in cuenta.id%type
   ) return boolean is
      v_dummy   number;
      v_mensaje varchar2(500);
   begin
      select count(*)
        into v_dummy
        from usuario
       where upper(nombreusuario) = upper(sys_context('USERENV','SESSION_USER'))--usuario conectado
         and cuentaid = p_cuentaid;-- que sea igual a la cuenta indicada
      -- Si el usuario pertenece a la cuenta, v_dummy será mayor que 0
      -- Si no pertenece, se lanzará una excepción no_data_found
      -- y se registrará el error en la tabla traza.
      if v_dummy > 0 then
         return true;
      else
         return false;
      end if;
   exception
      when no_data_found then
         v_mensaje := 'El usuario no pertenece a la cuenta indicada.';
         insert into traza values ( sysdate,sys_context('USERENV','SESSION_USER'),
         'f_verificar_cuenta_usuario',
         v_mensaje );
         return false;
      when others then
         v_mensaje := substr(sqlcode|| ' '|| sqlerrm,1,500);
         insert into traza values ( sysdate,sys_context('USERENV', 'SESSION_USER'),
    'f_verificar_cuenta_usuario',v_mensaje );
         return false;
   end;

--F1:f_obtener_plan_cuenta
FUNCTION f_obtener_plan_cuenta (
  p_cuenta_id IN cuenta.id%TYPE-- le paso por parámetro el id de la cuenta
) RETURN plan%ROWTYPE IS -- devuelve una fila de la tabla plan (es decir todos los datos de un plan)
  -- Variables locales (guardamos el plan y mensajes de error)
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
  -- Si no se encuentra el plan, se lanzará una excepción NO_DATA_FOUND
  -- y se registrará el error en la tabla traza.
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
  -- Capturamos cualquier otro error
   -- SQLCODE devuelve el número del error y SQLERRM su mensaje
   -- Concatenamos ambos y lo recortamos a 500 caracteres, ademas lo metemos en la tabla traza

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
  -- Verificar que el usuario pertenece a la cuenta
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  --Contamos productos asociados a la cuenta
  SELECT COUNT(*)
  INTO v_total
  FROM producto
  WHERE cuentaid = p_cuenta_id;

  RETURN v_total;

--Excepciones para manejar errores
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
  v_total    NUMBER; --almacena el número de categorías
  v_mensaje  VARCHAR2(500); --almacena mensajes de error
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
  SET nombre = p_nuevo_nombre, modificado=SYSDATE
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
  v_1   NUMBER;
  v_mensaje VARCHAR2(500);
BEGIN
  -- Paso 1: Verificar acceso del usuario a la cuenta del producto
  IF NOT f_verificar_cuenta_usuario(p_producto_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  -- Paso 2: Verificar que el producto existe
  SELECT 1 INTO v_1
  FROM producto
  WHERE gtin = p_producto_gtin AND cuentaid = p_producto_cuenta_id;
--si falla, lanza automatic no data found
  -- Paso 3: Verificar que el activo existe
  SELECT 1 INTO v_1
  FROM activo
  WHERE id = p_activo_id AND cuentaid = p_activo_cuenta_id;
--si falla, lanza automatic no data found

  -- Paso 4: Verificar que la relación no existe ya
  BEGIN
    SELECT 1 INTO v_1
    FROM relacionproductoactivo
    WHERE productogtin = p_producto_gtin
      AND productocuentaid = p_producto_cuenta_id
      AND activoid = p_activo_id
      AND activocuentaid = p_activo_cuenta_id;
--si falla, lanza automatic la execptionde debajoo

    -- Si encuentra, ya existe
    RAISE_APPLICATION_ERROR(-20002, 'Asociación ya existente.');
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      -- No existe: OK--hacemos null para q no se lance la excepcion y continuo el procedimiento
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
  v_1 NUMBER;

BEGIN
  -- Paso 1: Verificar acceso del usuario
  IF NOT f_verificar_cuenta_usuario(p_cuenta_id) THEN
    RAISE_APPLICATION_ERROR(-20001, 'Acceso no autorizado a la cuenta.');
  END IF;

  FOR r IN (
  SELECT * FROM productos_ext WHERE cuentaid = p_cuenta_id
) LOOP
  DECLARE
    v_gtin producto.gtin%TYPE;
    v_nombre_actual producto.nombre%TYPE;
  BEGIN
    -- Intentar obtener nombre y gtin
    SELECT nombre, gtin INTO v_nombre_actual, v_gtin
    FROM producto
    WHERE sku = r.sku AND cuentaid = r.cuentaid;

    IF v_nombre_actual != r.nombre THEN
      p_actualizar_nombre_producto(
        p_producto_gtin => v_gtin,
        p_cuenta_id     => r.cuentaid,
        p_nuevo_nombre  => r.nombre
      );
    END IF;



  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      INSERT INTO producto (
        gtin, sku, nombre, textocorto, creado, cuentaid
      ) VALUES (
        seq_productos.NEXTVAL,
        r.sku, r.nombre, r.textocorto, r.creado, r.cuentaid
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


-- PRUEBAS APARTE!!

-- PL/SQL (PARTE 2)
-- Trabajo en grupo parte 2 PL/SQL

-- Creamos el paquet pkg_admin_productos_avanzado que contiene las funciones y procedimientos
-- necesarios para la migracion de productos y la asociacion de activos a productos
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
      p_cuenta_id            IN cuenta.id%TYPE,
      p_categoria_origen_id  IN categoria.id%TYPE,
      p_categoria_destino_id IN categoria.id%TYPE
   );

   procedure p_replicar_atributos (
      p_gtin_origen in producto.gtin%type,
      p_cuenta_id   in producto.cuentaid%type
   );

end pkg_admin_productos_avanzado;
/



--CUERPO DEL PAQUETE
create or replace package body pkg_admin_productos_avanzado is

--F1:: f_validar_plan_suficiente

   function f_validar_plan_suficiente (
      p_cuenta_id in cuenta.id%type
   ) return varchar2 is
      v_mensaje            varchar2(500);
      v_resultado          varchar2(100);

  -- Contadores actuales
      v_total_productos    number;
      v_total_activos      number;
      v_total_cat_producto number;
      v_total_cat_activos  number;
      v_total_relaciones   number;

  -- Límites del plan
      v_lim_productos      number;
      v_lim_activos        number;
      v_lim_cat_producto   number;
      v_lim_cat_activos    number;
      v_lim_relaciones     number;

  -- ID del plan
      v_plan_id            plan.id%type;
   begin
  -- Validar acceso
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso no autorizado a la cuenta.'
         );
      end if;

  -- Verificar que la cuenta existe y tiene plan
      begin
         select planid
           into v_plan_id
           from cuenta
          where id = p_cuenta_id;
      exception
         when no_data_found then
            raise;
      end;

      if v_plan_id is null then
         raise exception_plan_no_asignado;
      end if;

  -- Obtener límites del plan
      select to_number(productos),
             to_number(activos),
             to_number(categoriasproducto),
             to_number(categoriasactivos),
             to_number(relaciones)
        into
         v_lim_productos,
         v_lim_activos,
         v_lim_cat_producto,
         v_lim_cat_activos,
         v_lim_relaciones
        from plan
       where id = v_plan_id;

  -- Contar recursos usados por la cuenta
      select count(*)
        into v_total_productos
        from producto
       where cuentaid = p_cuenta_id;

      select count(*)
        into v_total_activos
        from activo
       where cuentaid = p_cuenta_id;

      select count(*)
        into v_total_cat_producto
        from categoria
       where cuentaid = p_cuenta_id;

      select count(*)
        into v_total_cat_activos
        from categoriaactivos
       where cuentaid = p_cuenta_id;

      select count(*)
        into v_total_relaciones
        from relacionado
       where productocuentaid = p_cuenta_id
          or productocuentaid1 = p_cuenta_id;

  -- Comparaciones
      if v_total_productos > v_lim_productos then
         return 'INSUFICIENTE: PRODUCTOS';
      elsif v_total_activos > v_lim_activos then
         return 'INSUFICIENTE: ACTIVOS';
      elsif v_total_cat_producto > v_lim_cat_producto then
         return 'INSUFICIENTE: CATEGORIASPRODUCTO';
      elsif v_total_cat_activos > v_lim_cat_activos then
         return 'INSUFICIENTE: CATEGORIASACTIVOS';
      elsif v_total_relaciones > v_lim_relaciones then
         return 'INSUFICIENTE: RELACIONES';
      else
         return 'SUFICIENTE';
      end if;

   exception
      when exception_plan_no_asignado then
         v_mensaje := 'La cuenta no tiene plan asociado.';
         insert into traza values ( sysdate,
                                    sys_context(
                                       'USERENV',
                                       'SESSION_USER'
                                    ),
                                    'f_validar_plan_suficiente',
                                    v_mensaje );
         raise;
      when no_data_found then
         v_mensaje := 'Cuenta no encontrada.';
         insert into traza values ( sysdate,
                                    sys_context(
                                       'USERENV',
                                       'SESSION_USER'
                                    ),
                                    'f_validar_plan_suficiente',
                                    v_mensaje );
         raise;
      when others then
         v_mensaje := substr(
            sqlcode
            || ' '
            || sqlerrm,
            1,
            500
         );
         insert into traza values ( sysdate,
                                    sys_context(
                                       'USERENV',
                                       'SESSION_USER'
                                    ),
                                    'f_validar_plan_suficiente',
                                    v_mensaje );
         raise;
   end;

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
      RETURN 'Sin categoría'; -- Retorna directamente aquí
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

   procedure p_replicar_atributos (
      p_gtin_origen in producto.gtin%type,
      p_cuenta_id   in producto.cuentaid%type
   ) is
      v_mensaje varchar2(500);
   begin
  -- Paso 1: Validar acceso
      if not f_verificar_cuenta_usuario(p_cuenta_id) then
         raise_application_error(
            -20001,
            'Acceso no autorizado a la cuenta.'
         );
      end if;

  -- Paso 2: Verificar que el producto origen existe
      declare
         v_dummy number;
      begin
         select 1
           into v_dummy
           from producto
          where gtin = p_gtin_origen
            and cuentaid = p_cuenta_id;
      exception
         when no_data_found then
            raise_application_error(
               -20002,
               'El producto origen no existe en la cuenta.'
            );
      end;

  -- Paso 3: Insertar atributos del origen en productos que no los tienen
      insert into atributosproducto (
         atributoid,
         productogtin,
         productocuentaid,
         valor
      )
         select ap.atributoid,
                pr.gtin,
                pr.cuentaid,
                ap.valor
           from atributosproducto ap
           join producto pr
         on pr.cuentaid = p_cuenta_id
          where ap.productogtin = p_gtin_origen
            and ap.productocuentaid = p_cuenta_id
            and pr.gtin != p_gtin_origen
            and not exists (
            select 1
              from atributosproducto ap2
             where ap2.atributoid = ap.atributoid
               and ap2.productogtin = pr.gtin
               and ap2.productocuentaid = pr.cuentaid
         );

   exception
      when others then
         v_mensaje := substr(
            sqlcode
            || ' '
            || sqlerrm,
            1,
            500
         );
         insert into traza values ( sysdate,
                                    sys_context(
                                       'USERENV',
                                       'SESSION_USER'
                                    ),
                                    'p_replicar_atributos',
                                    v_mensaje );
         raise;
   end;
--FIN DEL PAQUETE
end pkg_admin_productos_avanzado;
/

--ACTIVAMOS AUDITORIA
alter system set audit_trail = db scope = spfile;
SHUTDOWN IMMEDIATE;
startup;

--COMPROBAMOS QUE FUNCIONA
SHOW PARAMETER audit_trail;


--JOBS
 -- Borra registros antiguos de la tabla de auditoría TRAZA
begin
   dbms_scheduler.create_job(
      job_name        => 'J_LIMPIA_TRAZA',
      job_type        => 'PLSQL_BLOCK',
      job_action      => '
      BEGIN
        DELETE FROM traza
        WHERE fecha < SYSDATE - (1/1440);  -- 1 minuto para pruebas
        COMMIT;
      END;',
      start_date      => systimestamp,
      repeat_interval => 'FREQ=MINUTELY;INTERVAL=2',
      enabled         => true,
      comments        => 'Limpia entradas de TRAZA de más de 1 minuto (simula 1 año para pruebas)'
   );
end;
/

begin
  -- Cursor que recorre todas las cuentas existentes
    -- y crea un job para actualizar productos de cada cuenta
   dbms_scheduler.create_job(
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
      start_date      => systimestamp,
      repeat_interval => 'FREQ=DAILY;BYHOUR=1;BYMINUTE=0;BYSECOND=0',
      enabled         => true,
      comments        => 'Actualiza productos desde productos_ext para todas las cuentas cada noche'
   );
end;
/