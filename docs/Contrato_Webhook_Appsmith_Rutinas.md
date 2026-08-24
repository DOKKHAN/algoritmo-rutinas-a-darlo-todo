# Contrato Webhook Appsmith - Algoritmo de Rutina

Endpoint n8n:

```text
POST /webhook/routines_automation
Content-Type: application/json
```

El workflow acepta un objeto o un array de objetos.

## Payload recomendado

```json
{
  "id_alumno": 260,
  "objetivo": "recomposicion_corporal",
  "prioridad_recomposicion": "musculatura",
  "enfoque_principal": "full_body",
  "enfoque_especifico": "gluteo",
  "debilidad": null
}
```

## Campos

`id_alumno`

- Tipo: entero.
- Obligatorio.
- Debe existir en `adt.alumnos`.

`objetivo`

- Opciones para dropdown:
  - `perdida_de_grasa`
  - `musculatura`
  - `recomposicion_corporal`
- Aliases aceptados por el workflow:
  - `grasa`
  - `perdida_grasa`
  - `musculo`
  - `ganancia_masa_muscular`
  - `masa_muscular`
  - `rc`
  - `recomposicion`

`prioridad_recomposicion`

- Opciones para dropdown:
  - `musculatura`
  - `perdida_de_grasa`
- Solo afecta cuando `objetivo` es `recomposicion_corporal`.
- Valor por defecto recomendado: `musculatura`.

`enfoque_principal`

- Es el tipo de rutina, no el musculo.
- Opciones para dropdown:
  - `full_body`
  - `torso`
  - `pierna`
  - `fullbody_torso_pierna`
  - `torso_pierna_torso`
  - `pierna_torso_pierna`
  - `torso_pierna`
  - `pierna_torso_pierna_torso`
  - `torso_torso_pierna_torso`
- Aliases aceptados:
  - `fullbody`
  - `cuerpo_completo`
  - `piernas`
  - `fpt`
  - `tpt`
  - `ptp`
  - `tp`
  - `ptpt`
  - `ttpt`

`enfoque_especifico`

- Es musculo o zona prioritaria.
- Opciones para dropdown:
  - `null`
  - `gluteo`
  - `abdomen`
  - `manguito_rotador`
  - `espalda`
  - `hombro`
  - `pectoral`
  - `brazos`
  - `cuadriceps`
  - `isquio`
  - `gastrocnemio`

`debilidad`

- Define el ejercicio 1 del dia cuando corresponde.
- Opciones para dropdown:
  - `null`
  - `gluteo`
  - `abdomen`
  - `manguito_rotador`

## Reglas de frecuencia implementadas

- `full_body`: frecuencia 1 a 3. Frecuencia 4 y 5 no aplican.
- `torso`: frecuencia 1 a 4. Frecuencia 5 usa la frecuencia 4 y agrega dia 5 cardio.
- `pierna`: frecuencia 1 a 3. Maximo 5 ejercicios por dia.
- `fullbody_torso_pierna`: frecuencia 3.
- `torso_pierna_torso`: frecuencia 3.
- `pierna_torso_pierna`: frecuencia 3.
- `torso_pierna`: frecuencia 2.
- `pierna_torso_pierna_torso`: frecuencia 4. Frecuencia 5 agrega dia 5 cardio.
- `torso_torso_pierna_torso`: frecuencia 4. Frecuencia 5 agrega dia 5 cardio.

## Alternancia de patrones

- Torso mixto: orden interno `TRACCION`, `EMPUJE`, `TRACCION`, `EMPUJE`.
- Torso traccion: todos los slots principales/secundarios son `TRACCION`.
- Torso empuje: todos los slots principales/secundarios son `EMPUJE`.
- Pierna mixta: orden interno `CADERA`, `SENTADILLA`, `CADERA`, `SENTADILLA`.
- Full body respeta los ordenes por frecuencia definidos en la metodologia de mayo.
