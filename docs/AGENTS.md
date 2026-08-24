# AGENTS.md - Generacion de rutinas ADT

Este proyecto automatiza la generacion de rutinas deportivas para el sistema
"A Darlo Todo". La fuente metodologica mas actual es:

- `Metodologia de rutina 10 de Junio.pdf` (en Downloads si aun no esta copiado
  al workspace)
- `metodologia-de-rutinas-julio.pdf` (en Downloads si aun no esta copiado al
  workspace)
- `base de rutina - versión mesociclos.xlsx` (en Downloads si aun no esta
  copiado al workspace)
- `RUTINA PERDIDA GRASA.xlsx` (en Downloads si aun no esta copiado al
  workspace)
- `manual-oficial-de-iteracion-de-microciclos-p1-y-p2-a4.pdf` (en Downloads si
  aun no esta copiado al workspace)
- `n8n/algoritmo-rutinas-a-darlo-todo.json`
- `n8n/reset-rutinas-a-darlo-todo.json`
- `Algoritmo de Rutina_matriz_v3_6_5_fix_conteo_dias_normalizado.json`
- `Algoritmo de Rutina_matriz_v3_6_4_fix_torso_pierna_microciclo_base.json`
- `Algoritmo de Rutina_matriz_v3_6_3_fix_activo_ejercicios.json`
- `Algoritmo de Rutina_matriz_v3_6_2_fix_referencias_contexto.json`
- `Algoritmo de Rutina_matriz_v3_6_1_fix_orden_nivel.json`
- `Algoritmo de Rutina_matriz_v3_6_microciclos_iterativos.json`
- `Algoritmo de Rutina_matriz_v3_5_enfoques_perdida_grasa.json`
- `Algoritmo de Rutina_matriz_v3_4_mesociclos_activo.json`
- `Algoritmo de Rutina_matriz_v3_2_junio_microciclo.json`
- `Algoritmo de Rutina_matriz_v3_1_slot7_orden1.json`
- `Algoritmo de Rutina_matriz_v3.json`
- `Algoritmo de Rutina_mayo_v2.json`
- `Metodologia de rutina mayo.pdf`
- `Manual de Metodolog.pdf`
- `Tipos de rutinas y criterios a seguir maetro-.pdf`
- `lvl de rutina para diego.pdf`

Cuando haya conflicto entre documentos antiguos y el workflow actual, usar el
workflow mas actualizado como referencia de implementacion y `Metodologia de
rutina 10 de Junio.pdf` como referencia metodologica. El PDF de mayo queda como
referencia historica salvo que junio no cubra el caso.

Nota V2: la metodologia V2 entregada por Felipe Alarcon redefine el slot 1 y
las rutinas excepcionales. En conflicto directo, aplicar V2 sobre reglas
anteriores del proyecto.

## Principios base

- No se busca "confundir al musculo"; se busca adaptacion progresiva,
  cuantificable y repetible.
- La rutina debe respetar continuidad: macrociclo, mesociclo y microciclo.
- Un mesociclo mantiene estructura base estable para permitir aprendizaje motor,
  progresion de carga y medicion real.
- La seleccion de ejercicios depende de nivel, frecuencia semanal, objetivo,
  enfoque principal, enfoque especifico, debilidades y restricciones activas.
- La ejecucion debe estandarizar ROM, tempo, descanso e intencion de velocidad.
- Los cambios deben ser trazables en `bloques_ejercicios`.
- Los criterios se aplican en orden de prioridad metodologica:
  1. objetivo
  2. debilidades
  3. enfoque especifico
- La base de ejercicios del mesociclo debe mantenerse estable en sus
  microciclos para medir progresion real.
- No se debe repetir el mismo ejercicio dentro de un microciclo. Esto aplica a
  toda la semana del alumno, no solo al mismo dia.

## Contrato del webhook

Endpoint esperado por n8n:

```text
POST /webhook/routines_automation
Content-Type: application/json
```

El workflow acepta un objeto o un array de objetos. El payload recomendado desde
Appsmith es:

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

### Parametros aceptados

`id_alumno`

- Tipo: entero.
- Obligatorio.
- Debe existir en `adt.alumnos`.

`objetivo`

- Valores recomendados para dropdown:
  - `perdida_de_grasa`
  - `musculatura`
  - `recomposicion_corporal`
- Aliases aceptados:
  - `grasa`
  - `perdida_grasa`
  - `musculo`
  - `ganancia_masa_muscular`
  - `masa_muscular`
  - `rc`
  - `recomposicion`

`prioridad_recomposicion`

- Valores recomendados:
  - `musculatura`
  - `perdida_de_grasa`
- Parametro legado del contrato. Segun la metodologia del 10 de junio,
  `recomposicion_corporal` se programa con el mismo criterio aerobico de
  perdida de grasa, salvo decision explicita posterior del equipo.
- Si el objetivo no es recomposicion, usar `musculatura` como default seguro.

`enfoque_principal`

- Representa el tipo de rutina o distribucion semanal, no un musculo.
- Valores recomendados para dropdown:
  - `full_body`
  - `torso`
  - `pierna`
  - `fullbody_torso_pierna`
  - `torso_pierna_torso`
  - `pierna_torso_pierna`
  - `torso_pierna`
  - `pierna_torso_pierna_torso`
  - `torso_torso_pierna_torso`
  - `ff`
  - `aem`
  - `aepm`
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
  - `ff`
  - `agarre_empuje_mixto`
  - `agarre_empuje_pierna_mixto`

`enfoque_especifico`

- Representa musculo o zona prioritaria.
- Valores recomendados para dropdown:
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

- Define el ejercicio 1 del dia cuando existe una debilidad a mejorar.
- Valores recomendados para dropdown:
  - `null`
  - `gluteo`
  - `abdomen`
  - `manguito_rotador`
- Si no hay debilidad, enviar `null`, no el texto `ninguna`.
- Si `debilidad = null`, V2 indica que el slot 1 debe ser abdomen por defecto.
  El slot metodologico 7 queda solo como mecanismo excepcional interno.

## Datos que el workflow completa desde la base

El webhook puede sobreescribir criterios, pero la base entrega contexto del
alumno:

- `nivel_experiencia`
- `frecuencia_semanal`
- `objetivo`
- `enfoque_principal`
- `enfoque_especifico`
- `debilidad`
- `prioridad_recomposicion`
- restricciones activas desde `alumno_problemas` y `problemas_restricciones`
- ultima sesion de evaluacion para cargas de referencia

## Niveles de alumno

Usar estos niveles como jerarquia:

- `P1`: principiante, control motor, seguridad, bajo riesgo.
- `P2`: principiante consolidado, fuerza base e hipertrofia inicial.
- `I1`: intermedio 1, antes `P3`; mayor uso de pesos libres y ejercicios
  complejos.
- `I2`: intermedio 2, antes `I1`; alta intensidad con prioridad de seguridad
  por fatiga.

Aliases de compatibilidad:

- Si la base entrega `P3`, tratarlo como `I1`.
- Si la base entrega el `I1` antiguo, revisar migracion a `I2` antes de aplicar
  reglas avanzadas.

Reglas generales:

- No seleccionar ejercicios sobre el nivel minimo requerido del alumno.
- `P1`: total 6 ejercicios por sesion; ratio objetivo 4 maquinas / 2 libres;
  dificultad solo baja y media; si es dificultad media debe ser maquina; si es
  libre debe ser baja dificultad y monoarticular o abdomen.
- `P2`: total 6 ejercicios por sesion; ratio objetivo 3 maquinas / 3 libres;
  dificultad baja y media.
- `I1`: total 6 ejercicios por sesion; ratio objetivo 2 maquinas / 4 libres;
  dificultad baja, media y alta.
- `I2`: total 6 ejercicios por sesion; ratio permitido 3 maquinas / 3 libres o
  4 maquinas / 2 libres, priorizando seguridad por fatiga.
- Para `P1`, evitar ejercicios axiales cuando exista alternativa mas segura.
- Tecnicas avanzadas solo para niveles intermedios habilitados, no en compuestos
  axiales pesados.

## Estructura temporal

Macrociclo:

- Contenedor global del progreso.
- Duracion estimada: 4 a 5 meses.
- Se obtiene o crea automaticamente un macrociclo activo por alumno.

Mesociclo:

- Bloque estable de trabajo.
- Duracion actual del workflow: 6 semanas.
- Se inserta en `adt.mesociclos` con `semanas_totales = 6`.
- La base de ejercicios del mesociclo debe mantenerse estable durante sus 6
  semanas. Cambian RIR, carga, tempo, descanso o comentario, no la seleccion
  semanal de ejercicios, salvo restriccion o ajuste justificado.
- Entre mesociclos no se deben repetir ejercicios como regla general; puede
  haber excepciones justificadas por continuidad, seguridad o falta de
  alternativas.

Microciclo:

- Semana de entrenamiento.
- Las variables semanales se guardan por bloque: semana, RIR, carga sugerida,
  tempo, descanso y comentario.
- No repetir el mismo `id_ejercicio` dentro del microciclo del alumno. La regla
  cruza todos los dias de la semana, no solo el mismo dia.

## Distribuciones de rutina

El `enfoque_principal` define la distribucion. La frecuencia semanal limita que
distribuciones aplican.

### 1. full_body

Aplica frecuencia 1 a 2. En V2, si se solicita `full_body` con frecuencia 3,
redirigir a `fullbody_torso_pierna` (`FPT`). Frecuencia 4 y 5 no aplican.

Ordenes principales segun frecuencia:

- Frecuencia 1, dia 1:
  - `SENTADILLA`
  - `AGARRE`
  - `CADERA`
  - `EMPUJE`
- Frecuencia 2:
  - Dia 1: `SENTADILLA`, `AGARRE`, `CADERA`, `EMPUJE`
  - Dia 2: `CADERA`, `EMPUJE`, `SENTADILLA`, `AGARRE`
En full body:

- Slots 2 y 3 priorizan ejercicios libres.
- Slots 4 y 5 priorizan maquinas.

### 2. torso

Aplica frecuencia 1 a 4. Frecuencia 5 equivale a frecuencia 4 mas dia 5 cardio.

- Frecuencia 1 y 2: torso mixto.
- Frecuencia 3:
  - Dia 1: traccion
  - Dia 2: empuje
  - Dia 3: mixto
- Frecuencia 4:
  - Dia 1: traccion
  - Dia 2: empuje
  - Dia 3: traccion
  - Dia 4: empuje
- Frecuencia 5:
  - Dias 1 a 4 como frecuencia 4
  - Dia 5: cardio

Torso mixto debe alternar patrones internamente:

- Slot 2: `TRACCION`
- Slot 3: `EMPUJE`
- Slot 4: `TRACCION`
- Slot 5: `EMPUJE`

### 3. pierna

Aplica frecuencia 1 a 3. En V2 pierna usa 6 slots; si el objetivo es perdida de
grasa o recomposicion con criterio aerobico, el slot 6 es aerobico.

- Frecuencia 1 y 2: pierna mixta.
- Frecuencia 3:
  - Dia 1: cadera
  - Dia 2: sentadilla
  - Dia 3: mixto

Pierna mixta debe alternar internamente:

- Slot 2: `CADERA`
- Slot 3: `SENTADILLA`
- Slot 4: `CADERA`
- Slot 5: `SENTADILLA`

### 4. fullbody_torso_pierna

Aplica frecuencia 3.

- Dia 1: full body
- Dia 2: torso
- Dia 3: pierna

### 5. torso_pierna_torso

Aplica frecuencia 3.

- Dia 1: torso
- Dia 2: pierna
- Dia 3: torso

### 6. pierna_torso_pierna

Aplica frecuencia 3.

- Dia 1: pierna
- Dia 2: torso
- Dia 3: pierna

### 7. torso_pierna

Aplica frecuencia 2.

- Dia 1: torso
- Dia 2: pierna

### 8. pierna_torso_pierna_torso

Aplica frecuencia 4. Frecuencia 5 agrega dia 5 cardio.

- Dia 1: pierna
- Dia 2: torso
- Dia 3: pierna
- Dia 4: torso
- Dia 5, si frecuencia 5: cardio

### 9. torso_torso_pierna_torso

Aplica frecuencia 4. Frecuencia 5 agrega dia 5 cardio.

- Dia 1: torso traccion
- Dia 2: torso empuje
- Dia 3: pierna
- Dia 4: torso mixto
- Dia 5, si frecuencia 5: cardio

### 10. ff

Alias V2 de `full_body` frecuencia 2.

- Dia 1: full body
- Dia 2: full body

### 11. aem

Alias V2 de torso frecuencia 3: agarre, empuje y mixto.

- Dia 1: torso traccion/agarre
- Dia 2: torso empuje
- Dia 3: torso mixto

### 12. aepm

Alias V2 de `torso_torso_pierna_torso`: agarre, empuje, pierna y mixto.

- Dia 1: torso traccion/agarre
- Dia 2: torso empuje
- Dia 3: pierna
- Dia 4: torso mixto

## Orden de ejercicios por dia

La matriz metodologica usa slots 1 a 7, pero la rutina entregada al alumno debe
guardar siempre el `orden` desde 1 en adelante dentro de cada dia.

Slots metodologicos:

- Slot 1: debilidad del alumno. Si no existe, abdomen por defecto.
- Slot 2: primario.
- Slot 3: primario.
- Slot 4: primario o secundario.
- Slot 5: primario, secundario o terciario.
- Slot 6: terciario o aerobico segun objetivo y enfoque.
- Slot 7: excepcional, solo para resguardar compatibilidad interna si un slot
  queda vacio por falta de candidatos. No reemplaza el abdomen por defecto V2.

Reglas de guardado:

- Con debilidad: se seleccionan slots metodologicos 1 a 6 y se guardan como
  orden 1 a 6.
- Sin debilidad: se selecciona abdomen en slot 1 y se guardan slots 1 a 6 como
  orden 1 a 6.
- Mantener trazabilidad del slot metodologico original en comentario o campo
  auxiliar cuando exista, por ejemplo `orden_matriz`.

Regla por objetivo:

- `perdida_de_grasa`: ejercicio/slot 6 siempre aerobico.
  - `P1` y `P2`: aerobico en maquina.
  - `I1` e `I2`: aerobico libre o maquina.
  - En matrices full body y pierna se usa slot 6 aerobico y no se crea slot
    metodologico 7.
  - En matrices torso, el slot 6 es aerobico; los slots 2 a 5 se ajustan segun
    el dia de torso definido por la planilla `RUTINA PERDIDA GRASA.xlsx`.
- `musculatura`: no hay ejercicio aerobico por objetivo.
  - Si no hay debilidad, el primer ejercicio debe ser abdomen.
  - El sexto ejercicio es terciario/hipertrofia segun tipo de dia.
- `recomposicion_corporal`: segun metodologia del 10 de junio, el ejercicio 6
  va siempre aerobico con el mismo criterio que perdida de grasa. Si no hay
  debilidad ni enfoque especifico, el primer ejercicio puede ser abdomen.

## Enfoque especifico

El enfoque especifico cambia prioridad muscular y orden de seleccion, no la
distribucion semanal. Debe influir principalmente en:

- orden de ejercicios primarios/secundarios
- musculo mas atacado
- seleccion del slot 6

Reglas de slot 6 por enfoque especifico, siempre subordinadas al objetivo:

- `brazos`:
  - Full body, dia 1, perdida de grasa: slots 2 sentadilla, 3 cadera, 4 biceps,
    5 triceps y 6 aerobico.
  - Full body, dia 1, musculatura: slots 2 sentadilla, 3 cadera, 4 espalda,
    5 biceps y 6 triceps.
  - Torso, perdida de grasa: slots 4 biceps, 5 triceps y 6 aerobico.
  - Torso, musculatura: slots 5 biceps y 6 triceps.
  - Pierna: slots 5 y 6 pueden ser biceps/triceps si la metodologia lo permite.
- `hombro`:
  - Full body con perdida de grasa y sin debilidad: slot 1
    empuje/hombro/terciario; el empuje priorizado debe ser hombro.
  - Torso con musculatura o perdida de grasa y sin debilidad: slot 1
    empuje/hombro/terciario.
  - Torso: slot 2 empuje/hombro, slot 3 traccion, slot 4 empuje/pecho,
    slot 5 traccion y slot 6 empuje/hombro/terciario o aerobico si el objetivo
    es perdida de grasa.
- `espalda`:
  - Full body con perdida de grasa y sin debilidad: slot 1
    traccion/espalda/terciario.
  - Torso con perdida de grasa y sin debilidad: slot 1
    traccion/espalda/terciario.
  - Torso: slots 2 y 4 traccion/espalda, slots 3 y 5 empuje/pecho y slot 6
    traccion/espalda/terciario o aerobico si el objetivo es perdida de grasa.
  - Pierna: no aplica.
- `pectoral`:
  - Full body con musculatura o perdida de grasa y sin debilidad: slot 1
    empuje/pecho/terciario.
  - Torso con musculatura o perdida de grasa y sin debilidad: slot 1
    empuje/pecho/terciario.
  - Torso: slots 2 y 4 empuje/pecho, slots 3 y 5 traccion y slot 6
    empuje/pecho/terciario o aerobico si el objetivo es perdida de grasa.
  - Pierna: no aplica.
- `gluteo`:
  - En pierna y full body, el segundo ejercicio puede ser gluteo primario.
  - Slot 6 puede ser gluteo secundario o terciario en full body/pierna.
  - Si choca con perdida de grasa o recomposicion, pasa a reemplazar el
    ejercicio primario compatible.
- `gastrocnemio`, `cuadriceps`, `isquio`:
  - No aplican a torso.
  - Pueden aplicar a slot 6 en full body o pierna como secundario/terciario
    segun la zona y el patron.
  - Si chocan con perdida de grasa o recomposicion, pasan a reemplazar el
    ejercicio primario compatible.

## Debilidades

Las debilidades solo pueden ser:

- gluteo
- abdomen
- manguito rotador

La debilidad ocupa el slot 1 y debe seleccionar ejercicios de baja dificultad o
seguros para el nivel del alumno. Si no hay debilidad, V2 usa abdomen como slot
1 por defecto.

Reglas especificas de debilidad:

- La debilidad afecta el primer ejercicio de la rutina, salvo excepcion de
  manguito rotador en pierna.
- El ejercicio de debilidad siempre debe ser de bajo nivel/dificultad baja.
- `gluteo`:
  - En pierna y full body, usar progresion por mesociclo: meso 1 gluteo medio
    abduccion; meso 2 patada lateral cuadrupedia; meso 3 patada lateral.
  - Si el contexto del dia es torso/AEM, pasar a abdomen como alternativa V2.
- `abdomen`:
  - Primeros ejercicios y sextos ejercicios pueden ser abdomen.
  - No debe chocar con otros criterios prioritarios.
- `manguito_rotador`:
  - Independiente del tipo de rutina, el slot 1 es manguito rotador.

## Restricciones y salud

Las restricciones activas vienen desde:

- `adt.alumno_problemas`
- `adt.problemas_restricciones`

Reglas:

- Excluir patrones en `patron_a_evitar`.
- Si el problema requiere cambio de ejercicio, buscar el mismo patron o musculo
  con menor dificultad, evitando repetir el ejercicio conflictivo.
- Para molestias o dolor, priorizar seguridad y avisos al entrenador segun
  `instruccion_automatica`.
- Restriccion torso excluye `EMPUJE` y `TRACCION`.
- Restriccion pierna excluye `SENTADILLA` y `CADERA`.

## Seleccion tecnica de ejercicios

La biblioteca vive en `adt.ejercicios`.

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

Criterios de seleccion:

- Solo seleccionar ejercicios con `activo = true`.
- Nivel minimo requerido <= nivel del alumno.
- Patron no restringido.
- Coincidencia con patron del slot o musculo objetivo.
- Coincidencia de zona/tren compatible con `dia_tipo`:
  - Dia torso no debe seleccionar ejercicios cuyo grupo principal sea pierna
    (`CUADRICEPS`, `ISQUIO`, `GLUTEO`, `ADUCTOR`, `GASTROCNEMIO`) salvo slot
    correctivo explicitamente justificado.
  - Dia pierna no debe seleccionar ejercicios de torso salvo slot complementario
    permitido por metodologia.
  - No basta con que `patron_movimiento` coincida; el ejercicio debe ser
    coherente con el tren, grupo muscular y objetivo del slot.
- Slot primario favorece `es_primario` y multiarticular.
- Slot secundario favorece `es_secundario`.
- Slot terciario favorece `es_terciario`.
- Slot aerobico favorece `patron_movimiento = AEROBICO`.
- No repetir el mismo ejercicio dentro del mismo dia.
- No repetir el mismo ejercicio dentro del mismo microciclo, aunque sea en dias
  distintos.
- Mantener el mismo ejercicio para el mismo dia/slot durante las 6 semanas del
  mesociclo, salvo que una restriccion o falta de candidato obligue a fallback
  documentado.
- Aplicar la matriz de la hoja `MESOCICLOS` segun nivel, numero de mesociclo y
  orden metodologico para dificultad, maquina, monoarticularidad y repeticion
  permitida respecto del mesociclo previo.
- Preferencias de full body:
  - slots 2 y 3: preferir no maquina
  - slots 4 y 5: preferir maquina

## RIR y progresion

El workflow v3.6 usa 6 semanas y guarda `rir_objetivo_min` /
`rir_objetivo_max`.

- `P1`: RIR fijo `4-5`.
- `P2`: RIR fijo `3-4`.
- `I1`: `[4, 3, 3, 2, 1, 0]`.
- `I2`: `[4, 3, 3, 2, 1, 0]`.
- `P3` legado: tratar como `I1` hasta migrar la base.

Iteracion de microciclos:

- La semana se evalua por isosemana lunes-domingo y por cantidad de
  entrenamientos registrados.
- El workflow reutiliza el mesociclo activo si existe.
- Las semanas futuras se recalculan con los ultimos datos de
  `adt.log_entrenamiento`.
- Un bloque con logs asociados no se debe sobreescribir.
- La clave de actualizacion de bloques es
  `(id_mesociclo, semana_meso, dia_numero, orden)`.

Reglas P1:

- Series iniciales `3`, maximo `4`.
- Multiarticulares inician `10-12`; monoarticulares inician `12-15`.
- En `10-12`, promedio >= `11` sube a `12-15`.
- En `10-12`, dos fallos consecutivos bajan carga `10%`.
- En `12-15`, promedio > `13.5` sube una serie si hay menos de 4.
- En `12-15`, con 4 series, promedio > `13.5` sube carga `5%` y vuelve a
  `10-12`.

Reglas P2:

- Series iniciales `3`, maximo `4`.
- Multiarticulares inician `8-10`; monoarticulares inician `10-12`.
- Multi `8-10`: promedio >= `9` sube a `10-12`; dos fallos bajan carga `5%`.
- Multi `10-12`: promedio > `11` sube serie o, con 4 series, sube carga `5%` y
  vuelve a `8-10`.
- Monoarticulares usan la progresion `10-12` / `12-15` tipo P1.

Reglas pendientes:

- Isometricos se miden en segundos. Escala provisional: `15, 20, 25, 30, 35,
  40, 45, 50, 55, 60`. Falta validacion metodologica.
- Bandas progresan por color. Falta tabla oficial de colores/resistencias por
  ejercicio.
- I1/I2 aun requieren reglas especificas de porcentaje, series y repeticiones.

## Persistencia en base de datos

La rutina se guarda principalmente en:

- `adt.macrociclos`
- `adt.mesociclos`
- `adt.bloques_ejercicios`
- `adt.evaluaciones_sesion`

`bloques_ejercicios` debe guardar:

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
- `rir_objetivo_min`
- `rir_objetivo_max`
- `peso_sugerido_inicial`
- `tempo`
- `descanso_seg`
- `duracion_objetivo_min`
- `estado_microciclo`
- `orden_matriz`
- `patron_slot`
- `maquina_slot`
- `tipo_slot_original`
- `fuente_matriz`
- `fallback_aplicado`
- `motivo_fallback`
- `tecnica_avanzada`
- `comentario_semanal`

Reglas de persistencia:

- El campo `orden` guardado para el alumno debe partir siempre en 1 dentro de
  cada dia y avanzar correlativamente.
- Si se usa slot metodologico distinto del orden guardado, conservar
  trazabilidad en `comentario_semanal` o en un campo auxiliar como
  `orden_matriz`.
- Si se aplica fallback por falta de candidato, registrar el motivo en
  `comentario_semanal`.

## Reglas para modificar el workflow

- No pisar el archivo original si se esta iterando; crear una version paralela
  con sufijo claro.
- Mantener actualizado el contrato de Appsmith cuando cambien parametros.
- Validar sintaxis de todos los nodos Code antes de entregar el JSON.
- Evitar ramas fragiles para macrociclo; preferir "obtener o crear" en una sola
  query.
- Normalizar entrada del webhook antes de consultar Postgres.
- El webhook puede venir como objeto, array, string JSON u objeto dentro de
  `body`; el normalizador debe soportar esos formatos.
- Si se agrega un nuevo enfoque principal, actualizar:
  - normalizacion de aliases
  - definicion de dias
  - contrato de webhook
  - documentacion en este archivo
- Si cambia la metodologia base, revisar primero `Metodologia de rutina 10 de
  Junio.pdf` y despues los documentos historicos.

## Casos conocidos a vigilar

- Frecuencia 5 debe ser frecuencia 4 mas cardio cuando el tipo de rutina lo
  permite.
- `enfoque_principal` no debe recibir musculos; para musculos usar
  `enfoque_especifico`.
- Empuje/traccion debe alternar en torso mixto.
- Cadera/sentadilla debe alternar en pierna mixta.
- En V2, pierna puede llegar a 6 ejercicios cuando el slot 6 es aerobico o
  terciario inferior.
- Si `debilidad = null`, crear slot 1 de abdomen por defecto.
- El orden guardado en base debe partir desde 1 aunque el slot metodologico
  original sea 2.
- No repetir `id_ejercicio` dentro del microciclo.
- No permitir ejercicios de pierna en dias torso por mera coincidencia de
  `patron_movimiento`; validar `tren` y grupos musculares.
- Si el alumno no tiene evaluacion inicial validada, revisar la condicion del IF
  antes de generar rutina.
