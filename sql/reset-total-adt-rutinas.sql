-- ==========================================
-- RESET TOTAL ADT - v3.6 microciclos iterativos
-- ==========================================
-- Este script borra y recrea el esquema completo usado por el workflow
-- Algoritmo de Rutina_matriz_v3_6_microciclos_iterativos.json.
-- No ejecutar en produccion sin respaldo previo.

CREATE SCHEMA IF NOT EXISTS adt;

DROP TABLE IF EXISTS adt.log_entrenamiento CASCADE;
DROP TABLE IF EXISTS adt.evaluaciones_movimiento CASCADE;
DROP TABLE IF EXISTS adt.evaluaciones_sesion CASCADE;
DROP TABLE IF EXISTS adt.microciclos_control CASCADE;
DROP TABLE IF EXISTS adt.bloques_ejercicios CASCADE;
DROP TABLE IF EXISTS adt.mesociclos CASCADE;
DROP TABLE IF EXISTS adt.rutinas_maestras CASCADE;
DROP TABLE IF EXISTS adt.macrociclos CASCADE;
DROP TABLE IF EXISTS adt.alumno_problemas CASCADE;
DROP TABLE IF EXISTS adt.problemas_restricciones CASCADE;
DROP TABLE IF EXISTS adt.ejercicios CASCADE;
DROP TABLE IF EXISTS adt.alumnos CASCADE;
DROP TABLE IF EXISTS adt.metodologia_rir CASCADE;
DROP TABLE IF EXISTS adt.metodologia_niveles CASCADE;

-- ==========================================
-- MODULO 0: TABLAS MAESTRAS DE METODOLOGIA
-- ==========================================

CREATE TABLE adt.metodologia_niveles (
    codigo_nivel VARCHAR(5) PRIMARY KEY,
    descripcion TEXT,
    riesgo_aceptable VARCHAR(50),
    enfoque_principal VARCHAR(100),
    orden_nivel INTEGER NOT NULL DEFAULT 0
);

INSERT INTO adt.metodologia_niveles
    (codigo_nivel, descripcion, riesgo_aceptable, enfoque_principal, orden_nivel)
VALUES
    ('P1', 'Principiante - Fase Adaptacion', 'Minimo', 'Aprendizaje patron y control motor', 1),
    ('P2', 'Principiante - Consolidacion', 'Bajo', 'Incremento de carga tecnica', 2),
    ('I1', 'Intermedio 1', 'Medio', 'Tension mecanica progresiva', 3),
    ('I2', 'Intermedio 2', 'Alto', 'Tension mecanica y tecnicas avanzadas controladas', 4),
    ('P3', 'Alias legado de I1', 'Medio', 'Compatibilidad historica', 3),
    ('', 'Sin Dato', 'Sin Dato', 'Sin Dato', 0);

CREATE TABLE adt.metodologia_rir (
    id_regla SERIAL PRIMARY KEY,
    codigo_nivel VARCHAR(5) REFERENCES adt.metodologia_niveles(codigo_nivel),
    semana_mesociclo INTEGER,
    rir_objetivo_min INTEGER,
    rir_objetivo_max INTEGER,
    rpe_objetivo_sugerido INTEGER
);

INSERT INTO adt.metodologia_rir
    (codigo_nivel, semana_mesociclo, rir_objetivo_min, rir_objetivo_max, rpe_objetivo_sugerido)
VALUES
    ('P1', 1, 4, 5, 6), ('P1', 2, 4, 5, 6), ('P1', 3, 4, 5, 6),
    ('P1', 4, 4, 5, 6), ('P1', 5, 4, 5, 6), ('P1', 6, 4, 5, 6),
    ('P2', 1, 3, 4, 7), ('P2', 2, 3, 4, 7), ('P2', 3, 3, 4, 7),
    ('P2', 4, 3, 4, 7), ('P2', 5, 3, 4, 7), ('P2', 6, 3, 4, 7),
    ('I1', 1, 4, 4, 6), ('I1', 2, 3, 3, 7), ('I1', 3, 3, 3, 7),
    ('I1', 4, 2, 2, 8), ('I1', 5, 1, 1, 9), ('I1', 6, 0, 0, 10),
    ('I2', 1, 4, 4, 6), ('I2', 2, 3, 3, 7), ('I2', 3, 3, 3, 7),
    ('I2', 4, 2, 2, 8), ('I2', 5, 1, 1, 9), ('I2', 6, 0, 0, 10),
    ('P3', 1, 4, 4, 6), ('P3', 2, 3, 3, 7), ('P3', 3, 3, 3, 7),
    ('P3', 4, 2, 2, 8), ('P3', 5, 1, 1, 9), ('P3', 6, 0, 0, 10);

-- ==========================================
-- MODULO 1: ALUMNOS Y SALUD
-- ==========================================

CREATE TABLE adt.alumnos (
    id_alumno SERIAL PRIMARY KEY,
    nombre_completo VARCHAR(255) NOT NULL,
    rut VARCHAR(20) UNIQUE,
    fecha_nacimiento DATE,
    genero VARCHAR(50),
    frecuencia_semanal INTEGER,
    nivel_experiencia VARCHAR(5) REFERENCES adt.metodologia_niveles(codigo_nivel) DEFAULT 'P1',
    objetivo_id INTEGER,
    objetivo VARCHAR(100),
    enfoque_principal VARCHAR(100),
    enfoque_especifico VARCHAR(100),
    debilidad VARCHAR(100),
    prioridad_recomposicion VARCHAR(100),
    fecha_ingreso DATE DEFAULT CURRENT_DATE,
    estado_activo BOOLEAN DEFAULT TRUE,
    evaluacion_inicial BOOLEAN DEFAULT FALSE,
    plan VARCHAR(255),
    observaciones TEXT
);

CREATE TABLE adt.problemas_restricciones (
    id_problema VARCHAR(50) PRIMARY KEY,
    nombre_problema VARCHAR(255) NOT NULL,
    tipo_impacto TEXT,
    patron_a_evitar VARCHAR(255),
    articulacion_afectada TEXT,
    instruccion_automatica TEXT,
    comentario TEXT
);

CREATE TABLE adt.alumno_problemas (
    id_relacion SERIAL PRIMARY KEY,
    id_alumno INTEGER REFERENCES adt.alumnos(id_alumno) ON DELETE CASCADE,
    id_problema VARCHAR(50) REFERENCES adt.problemas_restricciones(id_problema),
    fecha_deteccion DATE DEFAULT CURRENT_DATE,
    esta_activo BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- MODULO 2: BIBLIOTECA TECNICA
-- ==========================================

CREATE TABLE adt.ejercicios (
    id_ejercicio SERIAL PRIMARY KEY,
    nombre VARCHAR(255) NOT NULL,
    multi_mono VARCHAR(50),
    patron_movimiento VARCHAR(100),
    tren VARCHAR(50),
    contraccion VARCHAR(100),
    articulacion VARCHAR(100),
    grupo_muscular_primario VARCHAR(100),
    grupo_muscular_secundario VARCHAR(100),
    grupo_muscular_terciario VARCHAR(100),
    maquina VARCHAR(100),
    equipo_necesario VARCHAR(100),
    accesorio VARCHAR(100),
    unilateral_bilateral VARCHAR(50),
    dificultad VARCHAR(50),
    lvl_min_requerido VARCHAR(50),
    es_axial BOOLEAN DEFAULT FALSE,
    nivel_minimo_requerido VARCHAR(5) REFERENCES adt.metodologia_niveles(codigo_nivel) DEFAULT 'P1',
    es_primario BOOLEAN DEFAULT FALSE,
    es_secundario BOOLEAN DEFAULT FALSE,
    es_terciario BOOLEAN DEFAULT FALSE,
    activo BOOLEAN DEFAULT TRUE
);

-- ==========================================
-- MODULO 3: PROGRAMACION TEMPORAL
-- ==========================================

CREATE TABLE adt.macrociclos (
    id_macrociclo SERIAL PRIMARY KEY,
    id_alumno INTEGER REFERENCES adt.alumnos(id_alumno) ON DELETE CASCADE,
    nombre_macro VARCHAR(255) DEFAULT 'Ciclo General de Progreso',
    fecha_inicio DATE DEFAULT CURRENT_DATE,
    fecha_fin_estimada DATE,
    objetivo_global VARCHAR(255),
    esta_activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE adt.rutinas_maestras (
    id_rutina SERIAL PRIMARY KEY,
    id_macrociclo INTEGER REFERENCES adt.macrociclos(id_macrociclo) ON DELETE CASCADE,
    id_alumno INTEGER REFERENCES adt.alumnos(id_alumno) ON DELETE CASCADE,
    nombre_plan VARCHAR(255),
    fecha_inicio DATE DEFAULT CURRENT_DATE,
    fecha_fin_estimada DATE,
    dias_semanales INTEGER DEFAULT 3,
    objetivo_fase VARCHAR(100),
    esta_activa BOOLEAN DEFAULT TRUE
);

CREATE TABLE adt.mesociclos (
    id_mesociclo SERIAL PRIMARY KEY,
    id_macrociclo INTEGER REFERENCES adt.macrociclos(id_macrociclo) ON DELETE CASCADE,
    numero_meso_en_macro INTEGER,
    fase_tipo VARCHAR(50),
    fecha_inicio DATE DEFAULT CURRENT_DATE,
    fecha_fin_estimada DATE,
    semanas_totales INTEGER DEFAULT 6,
    esta_activo BOOLEAN DEFAULT TRUE
);

CREATE TABLE adt.bloques_ejercicios (
    id_bloque SERIAL PRIMARY KEY,
    id_mesociclo INTEGER REFERENCES adt.mesociclos(id_mesociclo) ON DELETE CASCADE,
    id_ejercicio INTEGER REFERENCES adt.ejercicios(id_ejercicio),
    semana_meso INTEGER NOT NULL DEFAULT 1,
    dia_numero INTEGER NOT NULL,
    dia_tipo VARCHAR(50),
    orden INTEGER NOT NULL,
    orden_matriz INTEGER,
    tipo_slot VARCHAR(50),
    zona VARCHAR(50),
    objetivo_muscular VARCHAR(100),
    patron_slot VARCHAR(100),
    maquina_slot VARCHAR(50),
    tipo_slot_original VARCHAR(100),
    fuente_matriz VARCHAR(100),
    series INTEGER DEFAULT 3,
    reps_min INTEGER,
    reps_max INTEGER,
    rir_objetivo INTEGER,
    rir_objetivo_min INTEGER,
    rir_objetivo_max INTEGER,
    peso_sugerido_inicial DECIMAL(8,2),
    tempo VARCHAR(20) DEFAULT '1-1-2',
    descanso_seg INTEGER DEFAULT 90,
    duracion_objetivo_min INTEGER,
    estado_microciclo VARCHAR(100),
    tecnica_avanzada VARCHAR(100),
    fallback_aplicado BOOLEAN DEFAULT FALSE,
    motivo_fallback TEXT,
    comentario_semanal TEXT,
    creado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    actualizado_en TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bloques_ejercicios_slot_unico UNIQUE
        (id_mesociclo, semana_meso, dia_numero, orden)
);

CREATE TABLE adt.microciclos_control (
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

-- ==========================================
-- MODULO 4: EVALUACION Y SEGUIMIENTO
-- ==========================================

CREATE TABLE adt.evaluaciones_sesion (
    id_sesion SERIAL PRIMARY KEY,
    id_alumno INTEGER REFERENCES adt.alumnos(id_alumno) ON DELETE CASCADE,
    fecha DATE DEFAULT CURRENT_DATE
);

CREATE TABLE adt.evaluaciones_movimiento (
    id_mov_eval SERIAL PRIMARY KEY,
    id_sesion INTEGER REFERENCES adt.evaluaciones_sesion(id_sesion) ON DELETE CASCADE,
    id_ejercicio INTEGER REFERENCES adt.ejercicios(id_ejercicio),
    punto_evaluado VARCHAR(255),
    peso_manejado DECIMAL(8,2),
    reps_logradas INTEGER,
    rpe_observado INTEGER,
    tecnica_calificacion INTEGER
);

CREATE TABLE adt.log_entrenamiento (
    id_log SERIAL PRIMARY KEY,
    id_bloque INTEGER REFERENCES adt.bloques_ejercicios(id_bloque) ON DELETE CASCADE,
    semana_del_meso INTEGER,
    fecha_realizada TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    iso_year INTEGER,
    iso_semana INTEGER,
    serie_numero INTEGER,
    series_realizadas INTEGER,
    peso_utilizado DECIMAL(8,2),
    reps_logradas INTEGER,
    reps_promedio DECIMAL(6,2),
    duracion_realizada_min INTEGER,
    rir_reportado INTEGER,
    rpe_reportado INTEGER,
    comentario_alumno TEXT
);

CREATE INDEX idx_alumnos_estado ON adt.alumnos (estado_activo);
CREATE INDEX idx_macrociclos_alumno_activo ON adt.macrociclos (id_alumno, esta_activo);
CREATE INDEX idx_mesociclos_macro_activo ON adt.mesociclos (id_macrociclo, esta_activo);
CREATE INDEX idx_bloques_mesociclo_semana ON adt.bloques_ejercicios (id_mesociclo, semana_meso);
CREATE INDEX idx_bloques_ejercicio ON adt.bloques_ejercicios (id_ejercicio);
CREATE INDEX idx_log_bloque_fecha ON adt.log_entrenamiento (id_bloque, fecha_realizada DESC);
CREATE INDEX idx_microciclos_control_estado ON adt.microciclos_control (estado, requiere_recalculo);
CREATE INDEX idx_microciclos_control_mesociclo ON adt.microciclos_control (id_mesociclo, semana_meso);
