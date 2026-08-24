-- ==========================================
-- MIGRACION: COLUMNA ACTIVO EN ADT.EJERCICIOS
-- ==========================================
-- Usar si la base fue creada con un reset anterior que no incluia
-- adt.ejercicios.activo.

ALTER TABLE adt.ejercicios
ADD COLUMN IF NOT EXISTS activo BOOLEAN DEFAULT TRUE;

UPDATE adt.ejercicios
SET activo = TRUE
WHERE activo IS NULL;

ALTER TABLE adt.ejercicios
ALTER COLUMN activo SET DEFAULT TRUE;

