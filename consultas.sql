-- 1 consultas básicas de selección

-- nombre y correos de los Usuarios
SELECT nombre, email 
FROM Usuarios;

-- salario y nombre Empleados (producto cartesiano)
SELECT Usuarios.nombre, Empleados.salario
FROM Empleados, Usuarios
WHERE Usuarios.id = Empleados.usuarioId;

-- salario y nombre Empleados (join)
SELECT Usuarios.nombre, Empleados.salario
FROM Usuarios JOIN Empleados ON Usuarios.id = Empleados.usuarioId;

-- Productos precio >= 20.00
SELECT *
FROM Productos 
WHERE Productos.precio >= 20.00;

-- direccionEnvio, codigoPostal, fechaNacimiento de Clientes
SELECT Usuarios.nombre, Clientes.direccionEnvio, Clientes.codigoPostal, Clientes.fechaNacimiento 
FROM Usuarios JOIN Clientes ON Clientes.usuarioId = Usuarios.id;


-- 2 consultas con condiciones específicas y funciones agregadas

-- salario promedio empleados
SELECT AVG(Empleados.salario)
FROM Empleados;

-- número productos de cada tipo (solo conteo)
SELECT COUNT(*)
FROM Productos
GROUP BY Productos.tipoProductoId;

-- número productos de cada tipo (id y conteo)
SELECT Productos.tipoProductoId, COUNT(*)
FROM Productos
GROUP BY Productos.tipoProductoId;

-- número productos de cada tipo (nombre y conteo) con join
SELECT TiposProducto.nombre, COUNT(*)
FROM Productos JOIN TiposProducto ON Productos.tipoProductoId = TiposProducto.id
GROUP BY Productos.tipoProductoId;

-- número productos de cada tipo (nombre y conteo) con producto cartesiano
SELECT TiposProducto.nombre, COUNT(*)
FROM Productos, TiposProducto
WHERE Productos.tipoProductoId = TiposProducto.id
GROUP BY Productos.tipoProductoId;

-- nombre, fecha realizacion de los pedidos de cada cliente con join
SELECT Usuarios.nombre, Pedidos.fechaRealizacion
FROM Clientes 
    JOIN Pedidos ON Clientes.id = Pedidos.clienteId
    JOIN Usuarios ON Usuarios.id = Clientes.usuarioId;
    
-- nombre, fecha realizacion de los pedidos de cada cliente con producto cartesiano
SELECT Usuarios.nombre, Pedidos.fechaRealizacion
FROM Clientes, Pedidos, Usuarios
WHERE Clientes.id = Pedidos.clienteId AND Usuarios.id = Clientes.usuarioId;

-- cliente menor variedad producto <--
SELECT Usuarios.nombre AS cliente, COUNT(DISTINCT LineasPedido.productoId) AS numero_productos_distintos
FROM Clientes
JOIN Pedidos ON Clientes.id = Pedidos.clienteId
JOIN LineasPedido ON Pedidos.id = LineasPedido.pedidoId
JOIN Usuarios ON Clientes.usuarioId = Usuarios.id;
GROUP BY Clientes.id, Clientes.nombre
ORDER BY numero_productos_distintos ASC
LIMIT 1;


-- 3 Consultas con JOIN y filtrado avanzado

-- pedidos clientes edad >= 18
SELECT Usuarios.nombre, Pedidos.*
FROM Clientes 
    JOIN Pedidos ON Clientes.id = Pedidos.clienteId
    JOIN Usuarios ON Usuarios.id = Clientes.usuarioId
WHERE TIMESTAMPDIFF(YEAR, Clientes.fechaNacimiento, Pedidos.fechaRealizacion)>=18;

-- productos no pedidos por cliente <18 <--
SELECT Productos.id, Productos.nombre
FROM Productos
WHERE Productos.id NOT IN (
  SELECT LineasPedido.productoId
  FROM LineasPedido
  JOIN Pedidos ON LineasPedido.pedidoId = Pedidos.id
  JOIN Clientes ON Pedidos.clienteId = Clientes.id
  WHERE TIMESTAMPDIFF(YEAR, Clientes.fechaNacimiento, CURDATE()) < 18
);

-- pedidos, lineaspedido (asociadas), nombre producto, unidades asociadas <--
SELECT Pedidos.id, Productos.nombre, LineasPedido.unidades
FROM Productos
    JOIN LineasPedido ON LineasPedido.productoId = Productos.id
    JOIN Pedidos ON Pedidos.id = LineasPedido.pedidoId
GROUP BY LineasPedido.id, Productos.id;

-- productos no menores, precio <--
SELECT nombre, precio
FROM Productos
WHERE puedeVenderseAMenores = FALSE;

-- clientes mayor productos pedidos para <18 <--
SELECT Usuarios.nombre
FROM Usuarios
    JOIN Clientes ON Usuarios.id = Clientes.usuarioId
    JOIN Pedidos ON Pedidos.clienteId = Clientes.id 
    JOIN LineasPedido ON  LineasPedido.pedidoId = Pedidos.id
    JOIN Productos ON Productos.id = LineasPedido.productoId
GROUP BY Clientes.id
HAVING 
  (SELECT SUM(lp1.unidades)
   FROM LineasPedido lp1
   JOIN Productos pr1 ON lp1.productoId = pr1.id
   JOIN Pedidos p1 ON lp1.pedidoId = p1.id
   WHERE p1.clienteId = Clientes.id AND pr1.puedeVenderseAMenores = FALSE)
	>
  (SELECT SUM(lp2.unidades)
   FROM LineasPedido lp2
   JOIN Productos pr2 ON lp2.productoId = pr2.id
   JOIN Pedidos p2 ON lp2.pedidoId = p2.id
   WHERE p2.clienteId = Clientes.id AND pr2.puedeVenderseAMenores = TRUE);


-- 4 Consultas con subconsultas y cálculos

-- cliente más pedidos <--
SELECT Usuarios.nombre, SUM(Pedidos.id) AS nPedidos
FROM Usuarios
    JOIN Clientes ON Usuarios.id = Clientes.usuarioId
    JOIN Pedidos ON Pedidos.clienteId = Clientes.id 
GROUP BY Clientes.id
ORDER BY nPedidos DESC
LIMIT 1;

-- pedidos, total (precio*unidades) <--
SELECT Pedidos.id, SUM(LineasPedido.precio*LineasPedido.unidades)
FROM LineasPedido
    JOIN Pedidos ON Pedidos.id = LineasPedido.pedidoId
GROUP BY Pedidos.id;

-- pedidos importe máx <--
SELECT 
    Pedidos.id, 
    SUM(LineasPedido.unidades*LineasPedido.unidades) AS importe,
    (
        SELECT MAX(totales.total) as importeMax
        FROM
        (
            SELECT SUM(LineasPedido.unidades*LineasPedido.unidades) as total
            FROM Pedidos
                JOIN LineasPedido ON Pedidos.id = LineasPedido.pedidoId
            GROUP BY Pedidos.id
        ) as totales
    ) AS max
FROM Pedidos
    JOIN LineasPedido ON Pedidos.id = LineasPedido.pedidoId
GROUP BY Pedidos.id
HAVING importe = max;

-- productos no vendidos <--
SELECT Productos.nombre
FROM Productos
    LEFT JOIN LineasPedido ON Productos.id = LineasPedido.productoId
WHERE LineasPedido.productoId IS NULL;

-- ganancias mensuales <--
SELECT SUM(LineasPedido.unidades*LineasPedido.precio), MONTH(Pedidos.fechaRealizacion)
FROM Pedidos
    JOIN LineasPedido ON Pedidos.id = LineasPedido.pedidoId
GROUP BY MONTH(Pedidos.fechaRealizacion);

-- empleado gestiona más dinero <--
SELECT Empleados.id, SUM(LineasPedido.unidades*LineasPedido.precio) as dinero
FROM Empleados
    JOIN Pedidos ON Pedidos.empleadoId = Empleados.id;
    JOIN LineasPedido ON LineasPedido.pedidoId = Pedidos.id;
GROUP BY Empleados.id
ORDER BY dinero DESC
LIMIT 1;

-- empleado >1000€ <--
SELECT Empleados.id, SUM(LineasPedido.unidades*LineasPedido.precio) as dinero
FROM Empleados
    JOIN Pedidos ON Pedidos.empleadoId = Empleados.id;
    JOIN LineasPedido ON LineasPedido.pedidoId = Pedidos.id;
GROUP BY Empleados.id
HAVING dinero >1000;

-- 5 pedidos mayor importe < importe medio <--
SELECT 
    Pedidos.id, 
    SUM(LineasPedido.unidades*LineasPedido.precio) AS importe
FROM Pedidos
    JOIN LineasPedido ON LineasPedido.pedidoId = Pedidos.id;
GROUP BY Pedidos.id
HAVING 
    importe < 
    (
        SELECT AVG(total.importe)
        FROM (
            SELECT SUM(LineasPedido.unidades*LineasPedido.precio) as importe
            FROM Pedidos
                JOIN LineasPedido ON LineasPedido.pedidoId = Pedidos.id;
            GROUP BY Pedidos.id
        ) as total
    )
ORDER BY importe DESC
LIMIT 5;

-- vista importe, empleado <--
CREATE OR REPLACE VIEW vistaPedidos AS
SELECT 
    Pedidos.id AS pedido,
    SUM(LineasPedido.unidades*LineasPedido.precio) as importe, 
    Usuarios.nombre AS empleado
FROM Usuarios
    JOIN Empleados ON Empleados.usuarioId = Usuarios.id
    JOIN Pedidos ON Pedidos.empleadoId = Empleados.id
    JOIN LineasPedido ON LineasPedido.pedidoId = Pedidos.id
GROUP BY Pedidos.id;

-- clientes piden en 3 meses distintos del último año
-- alguno de los 3 productos más vendidos de los últimos 5 años
SELECT Clientes.id
FROM Clientes
    JOIN Pedidos ON Clientes.id = Pedidos.clienteId
    JOIN LineasPedido ON Pedidos.id = LineasPedido.pedidoId
    JOIN (
        SELECT productoId
        FROM LineasPedido
            JOIN Pedidos ON LineasPedido.pedidoId = Pedidos.id
        WHERE Pedidos.fechaRealizacion >= DATE_SUB(CURDATE(), INTERVAL 5 YEAR)
        GROUP BY productoId
        ORDER BY SUM(unidades) DESC
        LIMIT 3
    ) AS topProductos ON LineasPedido.productoId = topProductos.productoId
WHERE Pedidos.fechaRealizacion >= DATE_FORMAT(CURDATE(), '%Y-01-01')
GROUP BY Clientes.id
HAVING COUNT(DISTINCT DATE_FORMAT(Pedidos.fechaRealizacion, '%Y-%m')) >= 3;