-- ==========================================
-- VALIDACION MICRO CICLO BASE - ADT v3.6.4
-- ==========================================
-- Cambiar el valor de id_alumno en el CTE params antes de ejecutar.

-- 1) Total de bloques generados por mesociclo
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  mc.id_alumno,
  m.id_mesociclo,
  m.semanas_totales,
  COUNT(*) AS total_bloques,
  MIN(b.semana_meso) AS primera_semana,
  MAX(b.semana_meso) AS ultima_semana,
  COUNT(DISTINCT b.dia_numero) AS dias_distintos
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
GROUP BY mc.id_alumno, m.id_mesociclo, m.semanas_totales
ORDER BY m.id_mesociclo DESC;

-- 2) Ejercicios repetidos dentro de la misma semana/microciclo
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  m.id_mesociclo,
  b.semana_meso,
  b.id_ejercicio,
  e.nombre AS ejercicio,
  COUNT(*) AS veces_en_microciclo
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
JOIN adt.ejercicios e ON e.id_ejercicio = b.id_ejercicio
GROUP BY m.id_mesociclo, b.semana_meso, b.id_ejercicio, e.nombre
HAVING COUNT(*) > 1
ORDER BY m.id_mesociclo DESC, b.semana_meso, veces_en_microciclo DESC;

-- 3) Ejercicios de pierna o patrones prohibidos en dias torso
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  m.id_mesociclo,
  b.semana_meso,
  b.dia_numero,
  b.orden,
  b.dia_tipo,
  e.nombre AS ejercicio,
  e.patron_movimiento,
  e.grupo_muscular_primario,
  e.grupo_muscular_secundario,
  e.grupo_muscular_terciario
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
JOIN adt.ejercicios e ON e.id_ejercicio = b.id_ejercicio
WHERE b.dia_tipo = 'torso'
  AND (
    e.patron_movimiento IN ('SENTADILLA', 'CADERA')
    OR e.grupo_muscular_primario IN ('CUADRICEPS', 'ISQUIO', 'GLUTEO', 'ADUCTOR', 'GASTROCNEMIO', 'GASTROGNEMIO', 'PANTORRILLA')
  )
ORDER BY m.id_mesociclo DESC, b.semana_meso, b.dia_numero, b.orden;

-- 4) Cantidad de ejercicios por dia
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  m.id_mesociclo,
  b.semana_meso,
  b.dia_numero,
  b.dia_tipo,
  COUNT(*) AS ejercicios_dia
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
GROUP BY m.id_mesociclo, b.semana_meso, b.dia_numero, b.dia_tipo
ORDER BY m.id_mesociclo DESC, b.semana_meso, b.dia_numero;

-- 5) Dias pierna que superen el maximo metodologico de 5 ejercicios
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  m.id_mesociclo,
  b.semana_meso,
  b.dia_numero,
  b.dia_tipo,
  COUNT(*) AS ejercicios_dia
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
WHERE b.dia_tipo = 'pierna'
GROUP BY m.id_mesociclo, b.semana_meso, b.dia_numero, b.dia_tipo
HAVING COUNT(*) > 5
ORDER BY m.id_mesociclo DESC, b.semana_meso, b.dia_numero;

-- 6) Estabilidad de ejercicios entre semanas para cada dia/orden
WITH params AS (
  SELECT 260::integer AS id_alumno
)
SELECT
  m.id_mesociclo,
  b.dia_numero,
  b.orden,
  COUNT(DISTINCT b.id_ejercicio) AS ejercicios_distintos,
  string_agg(DISTINCT e.nombre, ' | ' ORDER BY e.nombre) AS ejercicios,
  string_agg(DISTINCT b.semana_meso::text, ', ' ORDER BY b.semana_meso::text) AS semanas
FROM params p
JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
JOIN adt.ejercicios e ON e.id_ejercicio = b.id_ejercicio
GROUP BY m.id_mesociclo, b.dia_numero, b.orden
HAVING COUNT(DISTINCT b.id_ejercicio) > 1
ORDER BY m.id_mesociclo DESC, b.dia_numero, b.orden;

-- 7) Dias con conteo fuera de rango metodologico
-- Esperado actual:
-- - full_body: 6 ejercicios
-- - torso: 6 ejercicios
-- - pierna: maximo 5 ejercicios
-- - cardio: 1 ejercicio
WITH params AS (
  SELECT 260::integer AS id_alumno
), conteos AS (
  SELECT
    m.id_mesociclo,
    b.semana_meso,
    b.dia_numero,
    b.dia_tipo,
    COUNT(*) AS ejercicios_dia
  FROM params p
  JOIN adt.macrociclos mc ON mc.id_alumno = p.id_alumno
  JOIN adt.mesociclos m ON m.id_macrociclo = mc.id_macrociclo
  JOIN adt.bloques_ejercicios b ON b.id_mesociclo = m.id_mesociclo
  GROUP BY m.id_mesociclo, b.semana_meso, b.dia_numero, b.dia_tipo
)
SELECT *
FROM conteos
WHERE
  (dia_tipo = 'full_body' AND ejercicios_dia <> 6)
  OR (dia_tipo = 'torso' AND ejercicios_dia <> 6)
  OR (dia_tipo = 'pierna' AND ejercicios_dia > 5)
  OR (dia_tipo = 'cardio' AND ejercicios_dia <> 1)
ORDER BY id_mesociclo DESC, semana_meso, dia_numero;
