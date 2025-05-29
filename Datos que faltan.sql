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
