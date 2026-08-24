# Instrucción_algoritmo_rutinas.md

## Objetivo del documento

Este documento define la instrucción operativa actualizada para el algoritmo generador de rutinas de **A Darlo Todo**. Debe ser usado como referencia para implementar, mantener o modificar el workflow de generación de rutinas en n8n y su integración con Appsmith/Supabase.

La actualización incorpora la lectura completa del Excel `base de rutina(1).xlsx`, considerando todas sus pestañas y enfocándose en:

- Tipo de rutina, inferido desde el nombre de hoja y los bloques internos.
- Frecuencia semanal.
- Día de entrenamiento.
- Orden del ejercicio dentro del día.
- Patrón de movimiento esperado por orden.
- Uso esperado de máquina por orden.
- Tipo de ejercicio esperado: primario, secundario o terciario.
- Músculo/zona prioritaria cuando el Excel la explicita.

Cuando exista conflicto entre este documento y una instrucción anterior, usar este documento como referencia para el orden de slots y la selección por patrón/máquina/tipo.

---

## Principios base del algoritmo

- La rutina debe buscar adaptación progresiva, cuantificable y repetible.
- La rutina debe respetar continuidad entre macrociclo, mesociclo y microciclo.
- El mesociclo mantiene una estructura base estable para permitir aprendizaje motor, progresión de carga y medición real.
- La selección de ejercicios depende de nivel, frecuencia semanal, objetivo, enfoque principal, enfoque específico, debilidad y restricciones activas.
- La ejecución debe estandarizar ROM, tempo, descanso e intención de velocidad.
- Todo cambio debe quedar trazable en `adt.bloques_ejercicios`.
- La matriz de orden del Excel define la estructura base del día. El algoritmo debe seleccionar ejercicios que cumplan el slot, no inventar el orden libremente.

---

## Contrato general del webhook

Endpoint esperado por n8n:

```text
POST /webhook/routines_automation
Content-Type: application/json
```

El workflow debe aceptar un objeto o un array de objetos. Payload recomendado desde Appsmith:

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

### Parámetros aceptados

#### `id_alumno`

- Tipo: entero.
- Obligatorio.
- Debe existir en `adt.alumnos`.

#### `objetivo`

Valores recomendados:

- `perdida_de_grasa`
- `musculatura`
- `recomposicion_corporal`

Aliases aceptados:

- `grasa`
- `perdida_grasa`
- `musculo`
- `ganancia_masa_muscular`
- `masa_muscular`
- `rc`
- `recomposicion`

#### `prioridad_recomposicion`

Valores recomendados:

- `musculatura`
- `perdida_de_grasa`

Solo afecta cuando `objetivo = recomposicion_corporal`. Si el objetivo no es recomposición, usar `musculatura` como default seguro.

#### `enfoque_principal`

Representa el tipo de rutina o distribución semanal, no un músculo.

Valores recomendados:

- `full_body`
- `torso`
- `pierna`
- `torso_pierna`
- `fullbody_torso_pierna`
- `torso_pierna_torso`
- `pierna_torso_pierna`
- `pierna_torso_pierna_torso`
- `torso_torso_pierna_torso`

Aliases aceptados:

- `fullbody`
- `cuerpo_completo`
- `piernas`
- `tp`
- `pt`
- `fpt`
- `tpt`
- `ptp`
- `ptpt`
- `ttpt`

#### `enfoque_especifico`

Representa músculo o zona prioritaria. No debe cambiar la distribución semanal, sino la prioridad de selección dentro de slots compatibles.

Valores recomendados:

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

#### `debilidad`

Define el ejercicio 1 del día cuando existe una debilidad a mejorar.

Valores recomendados:

- `null`
- `gluteo`
- `abdomen`
- `manguito_rotador`

Si no hay debilidad, enviar `null`, no el texto `ninguna`.

---

## Datos que el workflow debe completar desde base

El webhook puede sobreescribir criterios, pero la base debe entregar contexto del alumno:

- `nivel_experiencia`
- `frecuencia_semanal`
- `objetivo`
- `enfoque_principal`
- `enfoque_especifico`
- `debilidad`
- `prioridad_recomposicion`
- restricciones activas desde `adt.alumno_problemas` y `adt.problemas_restricciones`
- última sesión de evaluación para cargas de referencia

---

## Normalización obligatoria de valores del Excel

El Excel contiene algunas variaciones de escritura. El algoritmo debe normalizarlas antes de consultar `adt.ejercicios`.

### Patrones de movimiento

Usar estos valores canónicos:

- `SENTADILLA`
- `CADERA`
- `EMPUJE`
- `TRACCION`
- `AGARRE`
- `AEROBICO`

Reglas importantes:

- `AGARRE` debe conservarse como patrón diferenciado cuando el Excel lo indique.
- No convertir automáticamente `AGARRE` a `TRACCION`, salvo que el equipo defina explícitamente una equivalencia funcional en base de datos.
- Si la biblioteca de ejercicios no tiene `AGARRE`, se debe implementar una capa de fallback documentada, por ejemplo buscar `TRACCION` con énfasis en agarre/bíceps/espalda según corresponda. Ese fallback debe quedar trazado.

### Máquina

Valores canónicos:

- `NO`: preferir ejercicios sin máquina.
- `SI`: preferir ejercicios con máquina.
- `NO/SI`: slot flexible; puede usar libre o máquina según disponibilidad, nivel, restricción y músculo objetivo.
- `null`: no hay restricción explícita de máquina para ese slot.

### Tipo de ejercicio

Valores canónicos:

- `PRIMARIO`
- `SECUNDARIO`
- `TERCIARIO`
- `AEROBICO`

Normalizar errores del Excel:

- `TERCEARIO` -> `TERCIARIO`
- `TRECERIO` -> `TERCIARIO`

---

## Reglas generales de slots por día

El Excel estructura la mayoría de los días con ejercicios numerados del 1 al 7, pero la base efectiva de fuerza está concentrada en los slots 2 a 5.

### Slot 1

- Reservado para `debilidad` cuando exista.
- Si `debilidad = null`, no debe forzarse un ejercicio de debilidad.
- Puede omitirse o usarse como accesorio/preactivación solo si el diseño metodológico lo requiere.

### Slots 2 a 5

- Son los slots estructurales principales de la matriz.
- Deben respetar estrictamente patrón, máquina y tipo definidos por la matriz del Excel.
- No se debe cambiar el orden de patrones salvo por restricción médica o ausencia de ejercicio elegible.

### Slots 6 y 7

- El Excel los deja mayoritariamente vacíos.
- Deben tratarse como slots complementarios configurables por objetivo.
- Reglas recomendadas:
  - `perdida_de_grasa`: asignar trabajo `AEROBICO` al slot complementario definido por el workflow.
  - `musculatura`: asignar `TERCIARIO` compatible con enfoque específico o grupo rezagado.
  - `recomposicion_corporal`: usar `prioridad_recomposicion`.
- Si se decide usar solo 6 ejercicios por día, el slot 7 debe omitirse.
- Si se usan 7 ejercicios, el slot 7 debe ser accesorio, correctivo, movilidad, core o aeróbico; no debe introducir otro primario pesado.

---

## Niveles de alumno

Jerarquía:

- `P1`: principiante, control motor, seguridad, bajo riesgo.
- `P2`: principiante consolidado, fuerza base e hipertrofia inicial.
- `P3`: principiante avanzado, mayor uso de pesos libres y ejercicios complejos.
- `I1`: intermedio, mayor capacidad de trabajo y técnicas avanzadas controladas.

Reglas:

- No seleccionar ejercicios sobre el nivel mínimo requerido del alumno.
- Para `P1`, evitar ejercicios axiales cuando exista alternativa más segura.
- Técnicas avanzadas solo para `I1`, no en compuestos axiales pesados.

---

## Matriz de distribución por tipo de rutina

Las siguientes matrices son la referencia actualizada desde el Excel.

Convenciones de tablas:

- `Orden`: número de ejercicio dentro del día.
- `Patrón`: patrón de movimiento requerido.
- `Máquina`: preferencia/restricción de máquina.
- `Tipo`: tipo de slot.
- `Músculo`: zona prioritaria cuando el Excel la declara.

---

# 1. FULL BODY

Hoja: `FULL BODY`.

Aplica para frecuencias 1, 2 y 3.

## FULL BODY - Frecuencia 1

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | TRACCION | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |

## FULL BODY - Frecuencia 2

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | CUADRICEPS |
| 3 | TRACCION | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Día 2

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | CUADRICEPS |
| 5 | AGARRE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## FULL BODY - Frecuencia 3

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | CUADRICEPS |
| 3 | TRACCION | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Día 2

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | CUADRICEPS |
| 5 | CADERA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Día 3

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | CUADRICEPS |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica FULL BODY

- Slots 2 y 3 priorizan ejercicios sin máquina.
- Slots 4 y 5 priorizan ejercicios con máquina.
- La frecuencia 3 rota el estrés principal entre sentadilla/tracción o agarre/cadera/empuje.
- `AGARRE` aparece explícitamente en día 2 y día 3 de frecuencia 3, y en día 2 de frecuencia 2.

---

# 2. PIERNA

Hoja: `PIERNA`.

Aplica para frecuencias 1 y 2 según el Excel entregado. La instrucción anterior mencionaba frecuencia 3 para pierna, pero esta pestaña no contiene un bloque de pierna frecuencia 3 independiente. Para pierna frecuencia 3 se debe usar la matriz compuesta `PTP` o definir una matriz adicional antes de implementarla como rutina pura.

## PIERNA - Frecuencia 1

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | - |
| 5 | CADERA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## PIERNA - Frecuencia 2

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | - |
| 5 | CADERA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Día 2

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | SENTADILLA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica PIERNA

- Alternar `SENTADILLA` y `CADERA` entre días cuando la frecuencia sea 2.
- Slots 2 y 3 son primarios sin máquina.
- Slots 4 y 5 son secundarios con máquina.
- Pierna no debe superar 5 ejercicios estructurales de fuerza por día, salvo que el slot complementario sea core, movilidad, correctivo o aeróbico.

---

# 3. TORSO

Hoja: `torso`.

Aplica para frecuencias 1, 2 y 3 según el Excel entregado. La instrucción anterior mencionaba frecuencia 4 para torso puro, pero esta pestaña no contiene un bloque frecuencia 4 independiente; para estructuras de 4 días usar `PTPT` o `TTPT`.

## TORSO - Frecuencia 1

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | TRACCION | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | TRACCION | SI | SECUNDARIO | - |
| 5 | TRACCION | - | TERCIARIO | BICEPS |
| 6 | EMPUJE | - | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

## TORSO - Frecuencia 2

### Día 1

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | TRACCION | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | TRACCION | SI | SECUNDARIO | - |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

### Día 2

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | EMPUJE | NO | PRIMARIO | PECHO |
| 3 | TRACCION | NO | PRIMARIO | - |
| 4 | EMPUJE | SI | SECUNDARIO | HOMBRO |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

## TORSO - Frecuencia 3

### Día 1: énfasis tracción

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | TRACCION | NO | PRIMARIO | - |
| 3 | TRACCION | NO | SECUNDARIO | - |
| 4 | TRACCION | SI | TERCIARIO | HOMBRO |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

### Día 2: énfasis empuje

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | EMPUJE | NO | PRIMARIO | PECHO |
| 3 | EMPUJE | NO | SECUNDARIO | HOMBRO |
| 4 | EMPUJE | SI | TERCIARIO | PECHO/HOMBRO |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

### Día 3: mixto

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | TRACCION | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | TRACCION | SI | SECUNDARIO | - |
| 5 | TRACCION | NO | TERCIARIO | BICEPS |
| 6 | EMPUJE | - | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

### Regla específica TORSO

- En frecuencia 1 y 2, torso funciona como mixto con alternancia de tracción y empuje.
- En frecuencia 3, día 1 es tracción, día 2 es empuje y día 3 es mixto.
- Bíceps se modela como terciario de `TRACCION`.
- Tríceps se modela como terciario de `EMPUJE`.
- Los slots `NO/SI` son flexibles y deben resolverse por disponibilidad, nivel, restricción y prioridad muscular.

---

# 4. PT / TORSO_PIERNA

Hoja: `PT`.

El Excel muestra una rutina compuesta de 2 días: pierna + torso. Aunque el bloque de torso indica `FRECUENCIA 4` en la celda superior, la hoja representa una estructura `PT` de dos jornadas. Para implementación debe normalizarse como `torso_pierna` o `pierna_torso` según el nombre interno que use el sistema. Dado el orden de la hoja, la secuencia efectiva es **Pierna día 1, Torso día 2**.

## PT - Frecuencia 2

### Día 1: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | - |
| 5 | CADERA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Día 2: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

---

# 5. FPT / FULLBODY_TORSO_PIERNA

Hoja: `FPT`.

Aplica frecuencia 3.

Secuencia:

1. Full body
2. Torso
3. Pierna

## Día 1: Full body

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | AGARRE | NO | PRIMARIO | - |
| 4 | CADERA | SI | PRIMARIO | - |
| 5 | EMPUJE | SI | PRIMARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 2: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 3: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | SENTADILLA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica FPT

- El día full body de FPT usa `AGARRE`, no `TRACCION`, en el slot 3.
- A diferencia de FULL BODY puro, los slots 4 y 5 del día full body están marcados como `PRIMARIO` en el Excel.
- El algoritmo debe respetar ese tipo de slot, salvo que el equipo decida homologarlo a secundario por carga total.

---

# 6. TPT / TORSO_PIERNA_TORSO

Hoja: `TPT`.

Aplica frecuencia 3.

Secuencia:

1. Torso
2. Pierna
3. Torso

## Día 1: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 2: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | PRIMARIO | - |
| 5 | CADERA | SI | PRIMARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 3: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | EMPUJE | NO | PRIMARIO | - |
| 3 | AGARRE | NO | PRIMARIO | - |
| 4 | EMPUJE | SI | SECUNDARIO | - |
| 5 | AGARRE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica TPT

- Día 1 torso inicia con `AGARRE` y luego `EMPUJE`.
- Día 3 torso invierte el énfasis: inicia con `EMPUJE` y luego `AGARRE`.
- El día pierna usa slots 4 y 5 como `PRIMARIO` en el Excel, no secundarios.

---

# 7. PTP / PIERNA_TORSO_PIERNA

Hoja: `PTP`.

Aplica frecuencia 3.

Secuencia:

1. Pierna
2. Torso
3. Pierna

## Día 1: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | PRIMARIO | - |
| 5 | CADERA | SI | PRIMARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 2: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 3: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO_RECOMENDADO | - |
| 5 | SENTADILLA | SI | SECUNDARIO_RECOMENDADO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica PTP

- El Excel deja vacío el tipo de los slots 2 a 5 del día 3, pero por consistencia con las demás matrices debe inferirse:
  - slots 2 y 3: `PRIMARIO`
  - slots 4 y 5: `SECUNDARIO`
- Marcar esta inferencia como una normalización del algoritmo, no como dato explícito del Excel.

---

# 8. PTPT / PIERNA_TORSO_PIERNA_TORSO

Hoja: `PTPT`.

Aplica frecuencia 4. Frecuencia 5 puede agregar un día 5 de cardio si la metodología lo permite.

Secuencia:

1. Pierna
2. Torso
3. Pierna
4. Torso

## Día 1: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | SENTADILLA | NO | PRIMARIO | - |
| 3 | CADERA | NO | PRIMARIO | - |
| 4 | SENTADILLA | SI | SECUNDARIO | - |
| 5 | CADERA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 2: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 3: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | SENTADILLA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 4: Torso

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | EMPUJE | NO | PRIMARIO | - |
| 3 | AGARRE | NO | PRIMARIO | - |
| 4 | EMPUJE | SI | SECUNDARIO | - |
| 5 | AGARRE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica PTPT

- Pierna alterna día 1 `SENTADILLA -> CADERA` y día 3 `CADERA -> SENTADILLA`.
- Torso alterna día 2 `AGARRE -> EMPUJE` y día 4 `EMPUJE -> AGARRE`.
- Slots 2 y 3 son primarios sin máquina.
- Slots 4 y 5 son secundarios con máquina.

---

# 9. TTPT / TORSO_TORSO_PIERNA_TORSO

Hoja: `TTPT`.

Aplica frecuencia 4. Frecuencia 5 puede agregar un día 5 de cardio si la metodología lo permite.

Secuencia:

1. Torso tracción
2. Torso empuje
3. Pierna
4. Torso mixto

## Día 1: Torso tracción

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | TRACCION | NO | PRIMARIO | - |
| 3 | TRACCION | NO | SECUNDARIO | - |
| 4 | TRACCION | SI | TERCIARIO | HOMBRO |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

## Día 2: Torso empuje

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | EMPUJE | NO | PRIMARIO | PECHO |
| 3 | EMPUJE | NO | SECUNDARIO | HOMBRO |
| 4 | EMPUJE | SI | TERCIARIO | PECHO/HOMBRO |
| 5 | TRACCION | NO/SI | TERCIARIO | BICEPS |
| 6 | EMPUJE | NO/SI | TERCIARIO | TRICEPS |
| 7 | - | - | - | - |

## Día 3: Pierna

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | CADERA | NO | PRIMARIO | - |
| 3 | SENTADILLA | NO | PRIMARIO | - |
| 4 | CADERA | SI | SECUNDARIO | - |
| 5 | SENTADILLA | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

## Día 4: Torso mixto

| Orden | Patrón | Máquina | Tipo | Músculo |
|---:|---|---|---|---|
| 1 | - | - | - | - |
| 2 | AGARRE | NO | PRIMARIO | - |
| 3 | EMPUJE | NO | PRIMARIO | - |
| 4 | AGARRE | SI | SECUNDARIO | - |
| 5 | EMPUJE | SI | SECUNDARIO | - |
| 6 | - | - | - | - |
| 7 | - | - | - | - |

### Regla específica TTPT

- Día 1 es tracción dominante.
- Día 2 es empuje dominante.
- Día 3 es pierna con prioridad cadera antes de sentadilla.
- Día 4 es torso mixto basado en `AGARRE` y `EMPUJE`.
- Esta matriz combina patrones `TRACCION` y `AGARRE`, por lo que ambos deben estar disponibles o tener fallback explícito.

---

## Reglas de selección técnica de ejercicios

La biblioteca principal vive en `adt.ejercicios`.

Campos relevantes:

- `id_ejercicio`
- `nombre`
- `multi_mono`
- `patron_movimiento`
- `tren`
- `articulacion`
- `grupo_muscular_primario`
- `grupo_muscular_secundario`
- `grupo_muscular_terciario`
- `maquina`
- `equipo_necesario`
- `accesorio`
- `unilateral_bilateral`
- `dificultad`
- `es_axial`
- `nivel_minimo_requerido`
- `es_primario`
- `es_secundario`
- `es_terciario`

### Filtro mínimo por slot

Para cada slot estructural, filtrar por:

1. `nivel_minimo_requerido <= nivel_experiencia_alumno`.
2. `patron_movimiento = patron_slot`, salvo fallback documentado.
3. Cumplimiento de restricción de máquina:
   - `NO`: priorizar `maquina = false`.
   - `SI`: priorizar `maquina = true`.
   - `NO/SI`: no filtrar de forma excluyente por máquina; ponderar según seguridad y disponibilidad.
4. Cumplimiento de tipo:
   - `PRIMARIO`: preferir `es_primario = true` y multiarticular.
   - `SECUNDARIO`: preferir `es_secundario = true`.
   - `TERCIARIO`: preferir `es_terciario = true`.
   - `AEROBICO`: preferir `patron_movimiento = AEROBICO`.
5. Restricciones activas del alumno.
6. No repetir el mismo ejercicio dentro del mismo día.
7. Evitar repetir excesivamente el mismo ejercicio dentro del mesociclo, salvo que sea parte de una progresión intencional.

### Ponderadores recomendados

Después del filtro mínimo, ordenar candidatos por puntaje:

1. Coincidencia exacta de patrón.
2. Coincidencia exacta de máquina.
3. Coincidencia exacta de tipo de slot.
4. Coincidencia con enfoque específico.
5. Adecuación al nivel del alumno.
6. Menor riesgo técnico ante restricciones.
7. Variedad razonable respecto a días anteriores.
8. Disponibilidad de carga histórica desde evaluación o sesiones previas.

---

## Enfoque específico

El enfoque específico cambia prioridad muscular y orden de selección, pero no debe cambiar la distribución semanal.

Debe influir principalmente en:

- desempate entre ejercicios compatibles con el mismo patrón;
- selección de músculo más atacado;
- selección de slots terciarios/complementarios;
- priorización dentro de slots donde el Excel declara músculo, como `CUADRICEPS`, `PECHO`, `HOMBRO`, `BICEPS`, `TRICEPS`.

Reglas:

- Si el enfoque específico coincide con el músculo declarado en el slot, aumentar puntaje del candidato.
- Si no hay músculo declarado, usar el patrón como filtro principal y el enfoque específico como desempate.
- No reemplazar un patrón estructural por otro solo para cumplir enfoque específico.

---

## Debilidades

Debilidades válidas:

- `gluteo`
- `abdomen`
- `manguito_rotador`

Reglas:

- La debilidad ocupa el slot 1.
- Debe seleccionar ejercicios seguros, de baja dificultad o compatibles con el nivel del alumno.
- No debe desplazar los slots estructurales 2 a 5.
- Si una debilidad entra en conflicto con restricción activa, debe omitirse o cambiarse por alternativa correctiva segura.

---

## Restricciones y salud

Las restricciones activas vienen desde:

- `adt.alumno_problemas`
- `adt.problemas_restricciones`

Reglas:

- Excluir patrones presentes en `patron_a_evitar`.
- Si el problema requiere cambio de ejercicio, buscar el mismo patrón o músculo con menor dificultad, evitando repetir el ejercicio conflictivo.
- Para molestias o dolor, priorizar seguridad y avisos al entrenador según `instruccion_automatica`.
- Restricción torso excluye o penaliza `EMPUJE`, `TRACCION` y `AGARRE`, según configuración.
- Restricción pierna excluye o penaliza `SENTADILLA` y `CADERA`.
- Si todos los ejercicios de un slot quedan excluidos, el workflow debe registrar fallback y notificar que el slot requiere revisión del entrenador.

---

## RIR y progresión

El workflow actual usa 6 semanas:

- `P1`: `[6, 5, 4, 4, 3, 3]`
- `P2`: `[5, 4, 4, 3, 2, 2]`
- `P3`: `[4, 3, 3, 2, 1, 0]`
- `I1`: `[4, 3, 3, 2, 1, 0]`

Reglas:

- P1 evita fallo muscular.
- P2/P3 progresan hacia mayor intensidad.
- P3 puede llegar a RIR 0 bajo supervisión.
- I1 puede usar técnicas avanzadas desde semanas 3 en accesorios estables.

Sobrecarga:

- Si cumple repeticiones y RIR objetivo con buena técnica: subir carga 2.5% a 5%.
- Si el esfuerzo fue demasiado bajo: ajuste más agresivo de 5% a 10%.
- Si no completa repeticiones pero llega al RIR: mantener carga y progresar por densidad o volumen.
- Si hay duda técnica: mantener o bajar carga y corregir ejecución.

---

## Persistencia en base de datos

La rutina se guarda principalmente en:

- `adt.macrociclos`
- `adt.mesociclos`
- `adt.bloques_ejercicios`
- `adt.evaluaciones_sesion`

`adt.bloques_ejercicios` debe guardar:

- `id_mesociclo`
- `id_ejercicio`
- `semana_meso`
- `dia_numero`
- `dia_tipo`
- `orden`
- `tipo_slot`
- `zona`
- `objetivo_muscular`
- `series`
- `reps_min`
- `reps_max`
- `rir_objetivo`
- `peso_sugerido_inicial`
- `tempo`
- `descanso_seg`
- `tecnica_avanzada`
- `comentario_semanal`

Campos recomendados adicionales si aún no existen:

- `patron_slot`: patrón solicitado por la matriz.
- `maquina_slot`: valor esperado de máquina desde la matriz.
- `tipo_slot_original`: valor original antes de normalización.
- `fuente_matriz`: hoja o distribución usada, por ejemplo `FULL BODY`, `PTPT`, `TTPT`.
- `fallback_aplicado`: booleano.
- `motivo_fallback`: texto breve.

---

## Reglas para implementar la matriz en n8n

1. Normalizar payload de entrada.
2. Resolver datos del alumno desde Supabase/Postgres.
3. Determinar `enfoque_principal` final.
4. Determinar frecuencia semanal final.
5. Buscar matriz compatible por `enfoque_principal + frecuencia`.
6. Expandir matriz por día y orden.
7. Insertar slot 1 si existe debilidad.
8. Para cada slot estructural:
   - aplicar normalización de patrón, máquina y tipo;
   - consultar candidatos en `adt.ejercicios`;
   - excluir restricciones;
   - puntuar candidatos;
   - seleccionar el mejor candidato;
   - registrar fallback si aplica.
9. Completar slots complementarios según objetivo.
10. Generar semanas del mesociclo con RIR, series, repeticiones, descanso, tempo y comentarios.
11. Persistir en `adt.bloques_ejercicios`.
12. Retornar resumen al webhook/Appsmith.

---

## Casos conocidos a vigilar

- `AGARRE` aparece en múltiples hojas y no debe perderse al normalizar.
- `TERCEARIO` y `TRECERIO` deben convertirse a `TERCIARIO`.
- La hoja `PT` tiene una inconsistencia visual: el bloque de torso muestra `FRECUENCIA 4`, pero la hoja representa una estructura de 2 días. Implementar como frecuencia 2 compuesta.
- La hoja `PIERNA` no trae frecuencia 3 pura; no generar pierna pura frecuencia 3 sin matriz validada.
- La hoja `torso` no trae frecuencia 4 pura; usar `TTPT` o `PTPT` para rutinas de 4 días.
- En `PTP`, día 3 no declara tipo en slots 2 a 5; inferir tipos por consistencia y marcarlo como normalización.
- Frecuencia 5 debe ser frecuencia 4 más cardio solo en distribuciones que lo permitan y cuando el objetivo/metodología lo indiquen.
- `enfoque_principal` no debe recibir músculos; para músculos usar `enfoque_especifico`.
- Si `debilidad = null`, no crear slot de debilidad obligatorio.
- Si el alumno no tiene evaluación inicial validada, revisar condición antes de generar rutina.
- Si no hay candidatos para un patrón, no seleccionar arbitrariamente: aplicar fallback explícito o devolver alerta al entrenador.

---

## Resumen ejecutivo de patrones por distribución

| Distribución | Frecuencia | Secuencia semanal | Observación clave |
|---|---:|---|---|
| `full_body` | 1 | Full body | Base: SENTADILLA, TRACCION, CADERA, EMPUJE |
| `full_body` | 2 | Full body, Full body | Día 2 usa CADERA, EMPUJE, SENTADILLA, AGARRE |
| `full_body` | 3 | Full body x3 | Incluye `AGARRE` en días 2 y 3 |
| `pierna` | 1 | Pierna | SENTADILLA/CADERA alternadas dentro del día |
| `pierna` | 2 | Pierna, Pierna | Día 2 invierte prioridad CADERA/SENTADILLA |
| `torso` | 1 | Torso | Mixto tracción/empuje + brazos |
| `torso` | 2 | Torso, Torso | Alterna énfasis empuje/tracción |
| `torso` | 3 | Tracción, Empuje, Mixto | Usa terciarios de bíceps/tríceps |
| `pt` | 2 | Pierna, Torso | Torso usa `AGARRE` y `EMPUJE` |
| `fpt` | 3 | Full body, Torso, Pierna | Full body usa `AGARRE`; slots 4 y 5 primarios |
| `tpt` | 3 | Torso, Pierna, Torso | Torso alterna `AGARRE/EMPUJE` y `EMPUJE/AGARRE` |
| `ptp` | 3 | Pierna, Torso, Pierna | Día 3 requiere inferencia de tipo |
| `ptpt` | 4 | Pierna, Torso, Pierna, Torso | Alternancia completa pierna/torso |
| `ttpt` | 4 | Torso, Torso, Pierna, Torso | Tracción, empuje, pierna, mixto |

---

## Definición de éxito del algoritmo

Una rutina generada se considera válida si:

- Respeta la matriz por distribución, frecuencia, día y orden.
- Cada slot estructural cumple patrón, máquina y tipo, o registra fallback justificado.
- No incluye ejercicios sobre el nivel del alumno.
- No viola restricciones activas.
- No repite ejercicios dentro del mismo día.
- Mantiene trazabilidad de selección en `bloques_ejercicios`.
- Genera progresión semanal coherente para 6 semanas.
- Devuelve una salida comprensible para Appsmith y revisable por el entrenador.
