# Algoritmo de Rutinas A Darlo Todo

Repositorio de versionamiento para los workflows n8n y documentacion tecnica del sistema de generacion de rutinas ADT.

## Workflows n8n principales

- `n8n/algoritmo-rutinas-a-darlo-todo.json`
  - Workflow principal de generacion de rutinas.
  - Basado en `Algoritmo de Rutina_matriz_v3_6_5_fix_conteo_dias_normalizado.json`, ajustado a la metodologia V2.
  - Incluye macrociclo, mesociclo, microciclos, seleccion tecnica, RIR y persistencia en `adt.bloques_ejercicios`.

- `n8n/reset-rutinas-a-darlo-todo.json`
  - Workflow de reset/carga base para n8n.
  - Basado en `Drive a PSQL - RESET TOTAL ADT_v3_6_microciclos.json`.

- `n8n/actualizador-nocturno-microciclos.json`
  - Workflow auxiliar para recalcular microciclos futuros con los logs reales de entrenamiento.
  - Incluye ejecucion programada nocturna y webhook de simulacion de dia para pruebas.

## SQL

- `sql/reset-total-adt-rutinas.sql`
  - Reset total del esquema `adt`.
  - Define tablas, columnas y constraints esperados por el algoritmo actual.

- `sql/validacion-microciclo-base.sql`
  - Queries para validar generacion base, conteos por dia, repeticion de ejercicios y estabilidad entre semanas.

- `sql/migracion_microciclos_control_v1.sql`
- `sql/migracion_metodologia_niveles_orden_v1.sql`
- `sql/migracion_ejercicios_activo_v1.sql`
  - Migraciones puntuales para bases existentes que no fueron recreadas con el reset actual.

## Documentacion

- `docs/AGENTS.md`
  - Reglas metodologicas y tecnicas actuales del proyecto.

- `docs/instrucciones_webhook.md`
  - Contrato esperado por el webhook desde Appsmith.

- `docs/Instruccion_algoritmo_rutinas.md`
  - Instrucciones historicas/base para el algoritmo.

- `docs/Contrato_Webhook_Appsmith_Rutinas.md`
  - Contrato previo de Appsmith.

## Archivos no versionados por defecto

No se versionan CSV con alumnos, problemas/restricciones o exportaciones operativas porque pueden contener datos personales o informacion sensible.
