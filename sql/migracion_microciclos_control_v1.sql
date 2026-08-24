-- ==========================================
-- MIGRACION ADT - control de microciclos v1
-- ==========================================
-- Ejecutar si la base ya fue creada con v3.6 y no quieres hacer reset total.

CREATE TABLE IF NOT EXISTS adt.microciclos_control (
    id_microciclo SERIAL PRIMARY KEY,
    id_mesociclo INTEGER REFERENCES adt.mesociclos(id_mesociclo) ON DELETE CASCADE,
    semana_meso INTEGER NOT NULL,
    fecha_inicio_iso DATE NOT NULL,
    fecha_fin_iso DATE NOT NULL,
    entrenamientos_esperados INTEGER DEFAULT 0,
    entrenamientos_completados INTEGER DEFAULT 0,
    estado VARCHAR(50) DEFAULT 'pendiente',
    fecha_ultima_evaluacion TIMESTAMP,
    requiere_recalculo BOOLEAN DEFAULT FALSE,
    comentario TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT microciclos_control_unico UNIQUE (id_mesociclo, semana_meso)
);

CREATE INDEX IF NOT EXISTS idx_microciclos_control_estado
    ON adt.microciclos_control (estado, requiere_recalculo);

CREATE INDEX IF NOT EXISTS idx_microciclos_control_mesociclo
    ON adt.microciclos_control (id_mesociclo, semana_meso);

