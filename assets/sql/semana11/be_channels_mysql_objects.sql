-- ==============================
-- UNAB · Base de Datos Advance
-- Semana 11 — Objetos de BD (MySQL)
-- Schema esperado (confirmado en material semana 10):
--   clients(id INT AUTO_INCREMENT PRIMARY KEY, rut VARCHAR(20), nombre VARCHAR(120))
--   web_clients(client_id INT), app_clients(client_id INT), atm_clients(client_id INT)
-- =================================

-- Seguridad: borra objetos si existen
DROP VIEW IF EXISTS v_clients_channels_overview;
DROP VIEW IF EXISTS v_clients_two_channels;
DROP VIEW IF EXISTS v_channel_totals;
DROP FUNCTION IF EXISTS fn_channel_count;
DROP FUNCTION IF EXISTS fn_has_all_channels;
DROP PROCEDURE IF EXISTS sp_add_client_and_channels;

-- =================================
-- VISTAS
-- 1) Panorama compacto por cliente (booleans por canal + total canales)
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

-- 2) Clientes con exactamente dos canales
CREATE VIEW v_clients_two_channels AS
SELECT * FROM v_clients_channels_overview
WHERE total_canales = 2;

-- 3) Totales por canal (para dashboards rápidos)
CREATE VIEW v_channel_totals AS
SELECT
  'web' AS canal, COUNT(*) AS clientes
FROM web_clients
UNION ALL
SELECT 'app', COUNT(*) FROM app_clients
UNION ALL
SELECT 'atm', COUNT(*) FROM atm_clients;

-- =================================
-- FUNCIONES
DELIMITER $$

-- A) Cantidad de canales de un cliente
CREATE FUNCTION fn_channel_count(p_client_id INT)
RETURNS INT
DETERMINISTIC
BEGIN
  DECLARE cnt INT DEFAULT 0;
  SELECT
    (CASE WHEN EXISTS(SELECT 1 FROM web_clients WHERE client_id = p_client_id) THEN 1 ELSE 0 END)
  + (CASE WHEN EXISTS(SELECT 1 FROM app_clients WHERE client_id = p_client_id) THEN 1 ELSE 0 END)
  + (CASE WHEN EXISTS(SELECT 1 FROM atm_clients WHERE client_id = p_client_id) THEN 1 ELSE 0 END)
    INTO cnt;
  RETURN cnt;
END$$

-- B) ¿Tiene los tres canales?
CREATE FUNCTION fn_has_all_channels(p_client_id INT)
RETURNS TINYINT
DETERMINISTIC
BEGIN
  RETURN (fn_channel_count(p_client_id) = 3);
END$$

-- =================================
-- PROCEDIMIENTO
-- Inserta un cliente y lo asigna a canales (1/0 para cada canal)
CREATE PROCEDURE sp_add_client_and_channels(
  IN p_rut VARCHAR(20),
  IN p_nombre VARCHAR(120),
  IN p_use_web TINYINT,
  IN p_use_app TINYINT,
  IN p_use_atm TINYINT
)
BEGIN
  DECLARE new_id INT;
  INSERT INTO clients(rut, nombre) VALUES (p_rut, p_nombre);
  SET new_id = LAST_INSERT_ID();

  IF p_use_web = 1 THEN
    INSERT INTO web_clients(client_id) VALUES (new_id);
  END IF;

  IF p_use_app = 1 THEN
    INSERT INTO app_clients(client_id) VALUES (new_id);
  END IF;

  IF p_use_atm = 1 THEN
    INSERT INTO atm_clients(client_id) VALUES (new_id);
  END IF;
END$$

DELIMITER ;

-- =================================
-- PRUEBAS RÁPIDAS (puedes comentar/descomentar)
-- SELECT * FROM v_clients_channels_overview LIMIT 10;
-- SELECT * FROM v_clients_two_channels LIMIT 10;
-- SELECT * FROM v_channel_totals;
-- SELECT id, nombre, fn_channel_count(id) AS canales, fn_has_all_channels(id) AS all3 FROM clients LIMIT 10;
-- CALL sp_add_client_and_channels('99.999.999-9', 'Cliente Demo OBJ', 1, 1, 0);
-- SELECT * FROM v_clients_channels_overview WHERE rut = '99.999.999-9';