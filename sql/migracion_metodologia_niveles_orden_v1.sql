-- ==========================================
-- MIGRACION ADT - orden de niveles
-- ==========================================
-- Corrige bases creadas con reset v3.6 antes de agregar orden_nivel.

ALTER TABLE adt.metodologia_niveles
ADD COLUMN IF NOT EXISTS orden_nivel INTEGER NOT NULL DEFAULT 0;

UPDATE adt.metodologia_niveles
SET orden_nivel = CASE codigo_nivel
    WHEN 'P1' THEN 1
    WHEN 'P2' THEN 2
    WHEN 'P3' THEN 3
    WHEN 'I1' THEN 3
    WHEN 'I2' THEN 4
    ELSE 0
END;

