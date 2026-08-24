# Instrucciones webhook Appsmith - rutinas v3.6 V2

Este documento define el contrato que Appsmith debe respetar para ejecutar el
workflow `n8n/algoritmo-rutinas-a-darlo-todo.json`.

Endpoint:

```text
POST /webhook/routines_automation
Content-Type: application/json
```

El workflow acepta:

- un objeto JSON;
- un array con un objeto;
- un string JSON dentro de `body`;
- el formato nativo del Webhook node de n8n, donde la data real viene dentro de
  `body`.

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

## Campos del payload

`id_alumno`

- Tipo: entero.
- Obligatorio.
- Debe existir en `adt.alumnos`.

`objetivo`

- Tipo: string.
- Recomendado desde Appsmith, aunque el workflow puede usar el valor guardado en
  `adt.alumnos`.
- Valores canonicos para dropdown:

```text
perdida_de_grasa
musculatura
recomposicion_corporal
```

Aliases tolerados:

```text
grasa
perdida_grasa
musculo
masa_muscular
ganancia_masa_muscular
rc
recomposicion
```

`prioridad_recomposicion`

- Tipo: string o null.
- Solo aplica cuando `objetivo = recomposicion_corporal`.
- Valores canonicos:

```text
musculatura
perdida_de_grasa
```

`enfoque_principal`

- Tipo: string.
- Define la distribucion semanal. No debe recibir musculos.
- Valores canonicos para dropdown:

```text
full_body
torso
pierna
pierna_torso
torso_pierna
fullbody_torso_pierna
torso_pierna_torso
pierna_torso_pierna
pierna_torso_pierna_torso
torso_torso_pierna_torso
ff
aem
aepm
```

Aliases tolerados:

```text
fullbody
cuerpo_completo
piernas
pt
tp
fpt
tpt
ptp
ptpt
ttpt
ff
aem
aepm
agarre_empuje_mixto
agarre_empuje_pierna_mixto
```

`enfoque_especifico`

- Tipo: string o null.
- Define musculo o zona prioritaria. No cambia por si solo la distribucion
  semanal.
- Valores canonicos para dropdown:

```text
null
gluteo
abdomen
manguito_rotador
espalda
hombro
pectoral
brazos
cuadriceps
isquio
gastrocnemio
```

Aliases tolerados:

```text
gluteos
core
rotadores
deltoides
pecho
biceps
triceps
isquios
femoral
gemelos
pantorrilla
```

`debilidad`

- Tipo: string o null.
- Define slot metodologico 1. En V2, si no se envia debilidad, el workflow usa
  abdomen por defecto.
- Valores canonicos para dropdown:

```text
null
gluteo
abdomen
manguito_rotador
```

Enviar `null` real cuando no aplique. No enviar `"null"`, `"ninguna"` ni string
vacio.

Reglas V2:

- `null` se transforma en abdomen.
- `gluteo` aplica como gluteo en full body y pierna.
- `gluteo` en torso/AEM se transforma en abdomen.
- `manguito_rotador` aplica como slot 1 en cualquier tipo de dia.

## Dropdowns recomendados por frecuencia

La frecuencia semanal normalmente viene desde `adt.alumnos.frecuencia_semanal`.
Si Appsmith la muestra o la envia, debe restringir `enfoque_principal` asi:

Frecuencia 1:

```text
full_body
pierna
torso
```

Frecuencia 2:

```text
full_body
ff
pierna
torso
pierna_torso
torso_pierna
```

Frecuencia 3:

```text
torso
aem
fullbody_torso_pierna
torso_pierna_torso
pierna_torso_pierna
```

Nota V2: si Appsmith envia `full_body` con frecuencia 3, el algoritmo redirige
a `fullbody_torso_pierna`.

Frecuencia 4:

```text
pierna_torso_pierna_torso
torso_torso_pierna_torso
aepm
```

Frecuencia 5:

```text
torso
pierna_torso_pierna_torso
torso_torso_pierna_torso
```

Regla: frecuencia 5 se interpreta como frecuencia 4 de fuerza mas dia 5
cardio cuando la distribucion lo permite.

## Iteracion de microciclos

La version v3.6 evalua los ultimos registros de `adt.log_entrenamiento` por
ejercicio y por isosemana lunes-domingo. Luego recalcula los bloques del
mesociclo activo.

La iteracion automatica no debe ejecutarse desde el workflow de generacion
inicial. Usar el workflow:

```text
Rutinas_actualizador_nocturno_microciclos_v1.json
```

Entradas del workflow:

```text
Schedule Nocturno: todos los dias 23:30
POST /webhook/routines_automation_simular_dia
Ejecucion manual desde n8n
```

Payload opcional para simular el paso de un dia:

```json
{
  "fecha_proceso": "2026-08-13",
  "dias_a_sumar": 1,
  "id_alumno": 260,
  "id_mesociclo": null,
  "forzar_recalculo": false,
  "dry_run": true
}
```

Campos aceptados por el webhook de simulacion:

- `fecha_proceso`: fecha base de evaluacion. Si no se envia, usa la fecha
  actual del servidor n8n.
- `dias_a_sumar`: entero opcional para simular avance de dias.
- `id_alumno`: opcional; si se envia, limita el proceso a ese alumno.
- `id_mesociclo`: opcional; si se envia, limita el proceso a ese mesociclo.
- `forzar_recalculo`: opcional; permite recalcular aunque la semana aun no este
  completa.
- `dry_run`: opcional; si es `true`, devuelve lo que actualizaria sin modificar
  `bloques_ejercicios`.

Reglas operativas:

- Si existe un mesociclo activo para el macrociclo del alumno, el workflow lo
  reutiliza.
- Si no existe mesociclo activo, crea uno nuevo de 6 semanas.
- Los bloques se insertan o actualizan por la clave:

```text
id_mesociclo, semana_meso, dia_numero, orden
```

- Si un bloque ya tiene registros en `adt.log_entrenamiento`, el workflow no lo
  sobreescribe.
- El actualizador nocturno no vuelve a seleccionar ejercicios. Solo actualiza
  variables de bloques futuros/no ejecutados.
- La actualizacion objetivo es la semana siguiente del mismo mesociclo.
- Las semanas futuras se mantienen como plan pendiente y se recalculan con los
  ultimos datos disponibles cuando la semana origen este completa o cuando se
  use `forzar_recalculo`.

## Datos que Appsmith debe registrar al cerrar entrenamientos

Tabla principal:

```text
adt.log_entrenamiento
```

Campos minimos recomendados:

```text
id_bloque
fecha_realizada
peso_utilizado
reps_logradas
rir_reportado
rpe_reportado
```

Campos recomendados para v3.6:

```text
serie_numero
series_realizadas
reps_promedio
duracion_realizada_min
comentario_alumno
```

Si Appsmith registra una fila por serie, usar `serie_numero` y
`reps_logradas`. Si registra una fila resumen por ejercicio, usar
`series_realizadas` y `reps_promedio`.

Para aerobico, registrar `duracion_realizada_min`. El plan inicial guarda
`duracion_objetivo_min = 10`.

## Reglas de progresion implementadas

P1:

- RIR objetivo: `4-5`.
- Series iniciales: `3`, maximo `4`.
- Multiarticulares: rango inicial `10-12`.
- Monoarticulares: rango inicial `12-15`.
- En `10-12`, si promedio >= `11`, sube a `12-15`.
- En `10-12`, si hay dos fallos consecutivos, baja carga `10%`.
- En `12-15`, si promedio > `13.5` y series < `4`, sube una serie.
- En `12-15`, si promedio > `13.5` y series = `4`, sube carga `5%` y vuelve a
  `10-12`.

P2:

- RIR objetivo: `3-4`.
- Series iniciales: `3`, maximo `4`.
- Multiarticulares: rango inicial `8-10`.
- Monoarticulares: rango inicial `10-12`.
- Multi `8-10`: si promedio >= `9`, sube a `10-12`; dos fallos bajan carga
  `5%`.
- Multi `10-12`: si promedio > `11`, sube serie o carga `5%` al llegar a 4
  series.
- Monoarticulares siguen la logica P1 de `10-12` / `12-15`.

I1 e I2:

- Mantienen la curva RIR anterior `[4, 3, 3, 2, 1, 0]`.
- La progresion especifica queda como pendiente metodologico; por ahora usan
  reglas conservadoras similares, con descarga menor.

Isometricos:

- Escala provisional documentada en el workflow:

```text
15, 20, 25, 30, 35, 40, 45, 50, 55, 60 segundos
```

- Pendiente: validar escala oficial y asociarla al tipo de ejercicio.

Bandas:

- Pendiente: crear tabla oficial de colores/resistencias por ejercicio.
- Regla provisional: mantener color y subir resistencia al superar el rango
  objetivo dos semanas consecutivas.

## Campos nuevos esperados en base

El reset compatible es:

```text
reset_total_adt_v3_6_microciclos.sql
```

Si la base ya fue creada con una version anterior de este reset, ejecutar:

```text
migracion_metodologia_niveles_orden_v1.sql
```

Esta migracion agrega `adt.metodologia_niveles.orden_nivel`, usado por el nodo
`Seleccion Tecnica` para filtrar ejercicios segun nivel del alumno.

Campos clave agregados a `adt.bloques_ejercicios`:

```text
orden_matriz
patron_slot
maquina_slot
tipo_slot_original
fuente_matriz
rir_objetivo_min
rir_objetivo_max
duracion_objetivo_min
estado_microciclo
fallback_aplicado
motivo_fallback
```

Campos clave agregados a `adt.log_entrenamiento`:

```text
serie_numero
series_realizadas
reps_promedio
duracion_realizada_min
iso_year
iso_semana
```
