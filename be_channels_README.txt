
BancoEstado — Operadores SET (DATASET)

Archivos:
- be_channels.sqlite  → usar en DBeaver (SQLite)
- be_channels_mysql.sql → importar/ejecutar en phpMyAdmin (MySQL)

Tablas (idénticas en ambas versiones):
  clients(id, rut, nombre)
  web_clients(client_id)
  app_clients(client_id)
  atm_clients(client_id)

Contexto: Cada cliente puede usar 1 a 3 canales (web, app, ATM). El objetivo del negocio es migrar a los clientes hacia APP (canal más barato).

Consultas de práctica — SQLite (tiene UNION, UNION ALL, INTERSECT, EXCEPT):
1) Todos los clientes que usan web o app (sin duplicados)
   SELECT c.* FROM clients c
   WHERE c.id IN (
     SELECT client_id FROM web_clients
     UNION
     SELECT client_id FROM app_clients
   )
   ORDER BY c.id;

2) Todos los clientes que usan web o app (con duplicados por pertenencia a ambos)
   SELECT client_id FROM web_clients
   UNION ALL
   SELECT client_id FROM app_clients;

3) Intersección: clientes que usan web Y app
   SELECT client_id FROM web_clients
   INTERSECT
   SELECT client_id FROM app_clients;

4) Diferencia (EXCEPT): clientes que usan web pero NO app
   SELECT client_id FROM web_clients
   EXCEPT
   SELECT client_id FROM app_clients;

5) Clientes que usan los TRES canales
   SELECT client_id FROM web_clients
   INTERSECT
   SELECT client_id FROM app_clients
   INTERSECT
   SELECT client_id FROM atm_clients;

6) Clientes que no usan ningún canal móvil (APP): (debería ser 0, por diseño todos tienen al menos 1 canal)
   SELECT * FROM clients c
   WHERE c.id NOT IN (SELECT client_id FROM app_clients);

Consultas equivalentes — MySQL (si tu versión no soporta INTERSECT/EXCEPT):
A) Unión (idéntico)
   SELECT client_id FROM web_clients
   UNION
   SELECT client_id FROM app_clients;

B) Intersección (equivalente con INNER JOIN)
   SELECT w.client_id
   FROM web_clients w
   INNER JOIN app_clients a USING (client_id);

C) Diferencia (equivalente con LEFT JOIN + IS NULL)
   SELECT w.client_id
   FROM web_clients w
   LEFT JOIN app_clients a USING (client_id)
   WHERE a.client_id IS NULL;

D) TRES canales (encadenando JOINs)
   SELECT w.client_id
   FROM web_clients w
   INNER JOIN app_clients a USING (client_id)
   INNER JOIN atm_clients t USING (client_id);

Extras útiles:
- Listar nombres RUT de los clientes que sólo usan ATM
  -- SQLite:
  WITH only_atm AS (
    SELECT client_id FROM atm_clients
    EXCEPT SELECT client_id FROM web_clients
    EXCEPT SELECT client_id FROM app_clients
  )
  SELECT c.rut, c.nombre FROM clients c
  WHERE c.id IN (SELECT client_id FROM only_atm)
  ORDER BY c.nombre;

  -- MySQL (LEFT JOIN)
  SELECT c.rut, c.nombre
  FROM clients c
  JOIN atm_clients t ON t.client_id = c.id
  LEFT JOIN web_clients w ON w.client_id = c.id
  LEFT JOIN app_clients a ON a.client_id = c.id
  WHERE w.client_id IS NULL AND a.client_id IS NULL
  ORDER BY c.nombre;

- Métrica: ¿cuántos clientes hay por canal?
  SELECT 'web' canal, COUNT(*) n FROM web_clients
  UNION ALL
  SELECT 'app', COUNT(*) FROM app_clients
  UNION ALL
  SELECT 'atm', COUNT(*) FROM atm_clients;

Sugerencias para la clase:
- Pida a los estudiantes escribir las 5 consultas con SET en SQLite y las equivalentes con JOIN en MySQL.
- Extienda el ejercicio para identificar candidatos a migración a APP (usan sólo web o sólo ATM).
