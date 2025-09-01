-- ==============================
-- Semana 11 — Vistas (SQLite / DBeaver)
-- Esquema (según material semana 10):
--   clients(id INTEGER PRIMARY KEY, rut TEXT, nombre TEXT)
--   web_clients(client_id INTEGER), app_clients(client_id INTEGER), atm_clients(client_id INTEGER)
-- ==============================

DROP VIEW IF EXISTS v_clients_channels_overview;
DROP VIEW IF EXISTS v_clients_two_channels;
DROP VIEW IF EXISTS v_channel_totals;

-- 1) Panorama por cliente
CREATE VIEW v_clients_channels_overview AS
SELECT
  c.id,
  c.rut,
  c.nombre,
  CASE WHEN w.client_id IS NOT NULL THEN 1 ELSE 0 END AS usa_web,
  CASE WHEN a.client_id IS NOT NULL THEN 1 ELSE 0 END AS usa_app,
  CASE WHEN t.client_id IS NOT NULL THEN 1 ELSE 0 END AS usa_atm,
  (CASE WHEN w.client_id IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN a.client_id IS NOT NULL THEN 1 ELSE 0 END
   + CASE WHEN t.client_id IS NOT NULL THEN 1 ELSE 0 END) AS total_canales
FROM clients c
LEFT JOIN web_clients w  ON w.client_id = c.id
LEFT JOIN app_clients a  ON a.client_id = c.id
LEFT JOIN atm_clients t  ON t.client_id = c.id;

-- 2) Exactamente dos canales
CREATE VIEW v_clients_two_channels AS
SELECT * FROM v_clients_channels_overview
WHERE total_canales = 2;

-- 3) Totales por canal
CREATE VIEW v_channel_totals AS
SELECT 'web' AS canal, COUNT(*) AS clientes FROM web_clients
UNION ALL
SELECT 'app', COUNT(*) FROM app_clients
UNION ALL
SELECT 'atm', COUNT(*) FROM atm_clients;

-- Nota: SQLite no define procedimientos/funciones almacenadas via SQL.
-- Alternativa didáctica: usar estas vistas y/o TRIGGERS para encapsular lógica.