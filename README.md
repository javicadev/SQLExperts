# 📦 Proyecto PL/SQL - Administración de Productos y Activos (UMA 2024-25)

Este proyecto implementa la lógica de negocio y administración de productos, cuentas y activos, en dos niveles de complejidad (paquete básico y paquete avanzado), integrando además el nivel físico y seguridad de base de datos, pruebas automatizadas y jobs programados.

---

## 📁 Contenido del proyecto

| Archivo SQL                                             | Descripción                                                                 |
|---------------------------------------------------------|------------------------------------------------------------------|
| 'PLYTIX.sql'                                            | Archivo SQL con todo el contenido del trabajo
| 'InfraestructuraYBateriaPruebasPKGBasico.sql'           | Infraestructura (Pruebas automatizadas) + Pruebas paquete básico |
| 'BateriaPruebasPKGAvanzado'                             | Pruebas paquete avanzado + ejecución de jobs del paquete avanzado.

---

## 🧱 Nivel físico 1 y 2 (Seguridad y diseño físico)

Incluido en los scripts y prácticas:
- Creación del usuario `PLYTIX`, tablespaces `TS_PLYTIX` y `TS_INDICES`.
- Configuración de quotas y permisos (`CONNECT`, `RESOURCE`, `CREATE TABLE`, etc.).
- Creación de índices (normales, funcionales y bitmap), triggers y sinónimos.
- Vista materializada `VM_PRODUCTOS` con refresco diario.
- Sinónimo público `S_PRODUCTOS`.
- Integración con tabla externa `PRODUCTOS_EXT` desde archivo CSV.
- Creación de secuencia `SEQ_PRODUCTOS` y trigger `TR_PRODUCTOS`.

---

## 📦 Paquetes PL/SQL

### ✅ `PKG_ADMIN_PRODUCTOS` (Básico)

- Gestión de productos, categorías, activos, relaciones y usuarios.
- Verificación de límites de plan y validación de atributos.
- Manejo robusto de excepciones.
- Registro en tabla `TRAZA`.
- Validación obligatoria de pertenencia de cuenta mediante `F_VERIFICAR_CUENTA_USUARIO`.

### ✅ `PKG_ADMIN_PRODUCTOS_AVANZADO`

- `F_VALIDAR_PLAN_SUFICIENTE`: Verifica si la cuenta respeta los límites de su plan.
- `F_LISTA_CATEGORIAS_PRODUCTO`: Devuelve los nombres de categorías de un producto.
- `P_MIGRAR_PRODUCTOS_A_CATEGORIA`: Migra productos de una categoría a otra.
- `P_REPLICAR_ATRIBUTOS`: Copia o actualiza atributos de un producto a otro.


## 🧪 Sistema de pruebas automatizado
En la tabla de resultados_pruebas -> SELECT * FROM resultados_pruebas ORDER BY fecha DESC;


