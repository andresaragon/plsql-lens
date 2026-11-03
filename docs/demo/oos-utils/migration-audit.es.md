# Auditoría de migración Oracle → PostgreSQL (muestra): `oos-utils`

*English: [migration-audit.md](migration-audit.md).*

Este informe es una **muestra** hecha con PL/SQL Lens sobre código público contra el que no se desarrolló la herramienta. Las
cifras salen de la salida cruda de la herramienta ([`raw/`](raw/)) o de la revisión manual de una muestra (señaladas como tales);
los bloques de cifras se generan y se comprueban con [`tables.py`](tables.py). Lee «Lo que este informe no cubre» antes de sacar
conclusiones.

## 1. Alcance

| Elemento | Valor |
|---|---|
| Proyecto | `oos-utils` (OraOpenSource), una biblioteca de utilidades PL/SQL |
| URL | https://github.com/OraOpenSource/oos-utils |
| Commit analizado | `b6217292bc744211eaee9e1d11ca7a0b495bc44d` |
| Licencia | MIT, leída en el archivo `LICENSE` de ese commit (copyright 2015 OraOpenSource); el SHA-256 del archivo está en [`raw/meta.txt`](raw/meta.txt) |
| Ruta analizada | `source/` (paquetes, `source/future/` y los scripts SQL). Se deja fuera `install/`: su cabecera dice que se genera automáticamente a partir de las mismas fuentes, y contarlo sería contarlas dos veces |
| PL/SQL Lens | versión 0.1.0; último commit que cambió `src/`: `8251b1cdb3687d8ec9204996aae6eb88f909e30c`; solo las reglas de migración MIG001–MIG011 |
| Comando | `bash scripts/demo_migration_audit.sh` (clona en el commit fijo, ejecuta `plsql-lens migrate` en formato JSON y tabla y `plsql-lens inventory`, y escribe [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Medida | Valor |
|---|---|
| Archivos PL/SQL analizados | 26 |
| Líneas en esos archivos | 6449 |
| Hallazgos | 36 |
| Archivos con al menos un hallazgo | 10 |
| Hallazgos por severidad: `high` | 5 |
| Hallazgos por severidad: `medium` | 8 |
| Hallazgos por severidad: `low` | 23 |
<!-- END:facts -->

El código de terceros no se guarda en este repositorio, solo la URL, el commit y la salida de la herramienta. Los extractos de
abajo tienen como máximo 5 líneas y provienen de `oos-utils` (MIT, © 2015 OraOpenSource). Las fuentes contienen etiquetas de
autoría de desarrolladores en comentarios (un nombre y un correo) y una dirección de ejemplo ficticia en un comentario; ningún
extracto las reproduce. En `data/` y `tests/` (no analizados) no encontré datos personales mediante búsqueda por patrones y
lectura parcial.

## 2. Resumen ejecutivo

* PL/SQL Lens (reglas de migración MIG001–MIG011) reporta **36 hallazgos en 10 de 26 archivos**: 5 `high`, 8 `medium`, 23 `low`
  (salida cruda). Los hallazgos `low`, mecánicos (NVL, `FROM DUAL`, `DBMS_OUTPUT`, un DECODE), son la mayor parte del total.
* **Riesgos principales, en términos de negocio:**
  1. *Diferencias silenciosas con el texto vacío.* Los cinco hallazgos `high` asignan `''` (que en Oracle es NULL) a un búfer
     dentro de rutinas de hash. En mi lectura el resultado no cambia aquí, pero es la categoría de defecto que convierte una
     migración de «compila» en «devuelve otros datos», y requiere una prueba, no solo una revisión.
  2. *Código que depende de la hora.* Un bucle de espera usa `SYSTIMESTAMP`; el reemplazo que sugiere la herramienta
     (`CURRENT_TIMESTAMP`) es fijo durante una transacción de PostgreSQL y haría que ese bucle no termine nunca.
  3. *Características exclusivas de Oracle alrededor de los hallazgos que esta versión no mira* (funciones sobre bytes,
     funciones XML, vistas de APEX, SQL dinámico). Los 36 hallazgos son lo que ven 11 reglas, no una estimación del trabajo.
* Revisión manual de una muestra de 20 hallazgos (Claude, provisional): 16 aciertos reales, 4 dudosos, 0 falsos positivos. Veinte
  hallazgos no permiten estimar la precisión sobre el resto.

## 3. Hallazgos por regla y severidad, y por archivo

Salida cruda: [`raw/migrate.json`](raw/migrate.json), [`raw/migrate.txt`](raw/migrate.txt).

<!-- BEGIN:by_rule -->
| Regla | Severidad | Ocurrencias | Archivos |
|---|---|---|---|
| MIG001 | low | 14 | 3 |
| MIG002 | low | 1 | 1 |
| MIG003 | medium | 6 | 3 |
| MIG009 | low | 5 | 2 |
| MIG010 | low | 3 | 2 |
| MIG011 | high | 5 | 1 |
| MIG011 | medium | 2 | 2 |
<!-- END:by_rule -->

Los diez archivos con más hallazgos (todos los que tienen hallazgos, si son menos):

<!-- BEGIN:by_file -->
| Archivo | Hallazgos |
|---|---|
| `source/packages/oos_util_crypto.pkb` | 18 |
| `source/scripts/prereqs.sql` | 4 |
| `source/future/oos_util_transform.pkb` | 2 |
| `source/future/reusable_table_create_template.sql` | 2 |
| `source/packages/oos_util.pkb` | 2 |
| `source/packages/oos_util_apex.pkb` | 2 |
| `source/packages/oos_util_string.pkb` | 2 |
| `source/packages/oos_util_totp.pkb` | 2 |
| `source/packages/oos_util_lob.pkb` | 1 |
| `source/scripts/recompile.sql` | 1 |
| **Total** (10) | 36 |
<!-- END:by_file -->

## 4. Riesgos principales

Se leyeron en contexto todos los hallazgos `high` y `medium` (13: 5 `high`, 8 `medium`). Lo que se dice de PostgreSQL es mi lectura
del código; **nada se ejecutó en una base de datos**.

### 4.1 `''` asignado a una variable (MIG011, `high`) — `oos_util_crypto.pkb:229, 383, 517, 771, 943`

```plsql
          else
            t_msg_buf := '';
          end if;
```
*(`source/packages/oos_util_crypto.pkb:228-230`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** en Oracle `''` es NULL; en PostgreSQL es una cadena vacía. La herramienta califica como `high` cualquier `''`
  que no esté en una concatenación ni sea argumento de `replace`.
* **Lectura:** el búfer se concatena después (`t_msg_buf || t_pad`) y se mide con `nvl(length(t_msg_buf), 0)`, y no encontré
  un camino donde NULL y `''` den resultados distintos. Los clasifico como *dudosos* (la construcción está; el daño no es
  evidente). El mismo patrón aparece en cada una de las cinco rutinas de hash (según los rangos de líneas que leí: `ripemd160`,
  `md4`, `md5`, `sha256` y `sha512`).
* **Qué hacer:** asignar `NULL` de forma explícita, o conservar `''` y revisar las pruebas `IS NULL`; probar cada rutina con
  resúmenes conocidos, porque un hash incorrecto no produciría ningún error.

### 4.2 `SYSTIMESTAMP` en un bucle de espera (MIG003, `medium`) — `oos_util.pkb:105, 113`

```plsql
    -- Note: Can't use systimestamp in loop since it doesn't seem to calculate a new timestamp each iteration.
    while(l_end_time > l_now) loop
      l_now := systimestamp;
    end loop;
```
*(`source/packages/oos_util.pkb:111-114`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** la sugerencia de la herramienta lista `CURRENT_TIMESTAMP`, `LOCALTIMESTAMP` o `CURRENT_DATE`. En PostgreSQL
  `CURRENT_TIMESTAMP` es el inicio de la transacción, así que este bucle no terminaría si se aplicara la sugerencia al pie de la
  letra.
* **Qué hacer:** `pg_sleep(p_seconds)` reemplaza el procedimiento entero; si se conserva el bucle, la función que avanza es
  `clock_timestamp()`.

### 4.3 `SYSDATE` sobre una vista de APEX (MIG003, `medium`) — `oos_util_apex.pkb:104-105`

```plsql
    and aws.apex_session_id = p_session_id
    and sysdate <= aws.session_idle_timeout_on
    and sysdate <= aws.session_life_timeout_on;
```
*(`source/packages/oos_util_apex.pkb:103-105`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** la comparación en sí se traslada (`LOCALTIMESTAMP` o `now()`); la tabla que lee (`apex_workspace_sessions`) es
  una vista de Oracle APEX y no existe en PostgreSQL.
* **Qué hacer:** decidir primero si esta función tiene contraparte en PostgreSQL; la función de fecha es la parte pequeña.

### 4.4 `SYSTIMESTAMP` como material de semilla (MIG003, `medium`) — `oos_util_crypto.pkb:1229, 1237`

```plsql
      t_seed := utl_raw.cast_from_number( dbms_utility.get_cpu_time )
             || utl_raw.cast_from_number( extract( second from systimestamp ) )
             || utl_raw.cast_from_number( dbms_utility.get_time );
```
*(`source/packages/oos_util_crypto.pkb:1228-1230`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** `SYSTIMESTAMP` pasa a `clock_timestamp()`, pero la línea usa además `utl_raw` y `dbms_utility`, que no tienen
  equivalente directo en PostgreSQL. La herramienta reporta solo la función de hora.
* **Qué hacer:** reemplazar el generador de bytes aleatorios por uno de PostgreSQL (por ejemplo, de la extensión `pgcrypto`) en
  lugar de trasladar la semilla.

### 4.5 `''` como argumento de `replace` (MIG011, `medium`) — `reusable_table_create_template.sql:235`, `oos_util_totp.pkb:116`

```plsql
        l_sql := replace(l_sql, '%default_val%', replace(l_columns (i).default_val, 'default', ''));
```
*(`source/future/reusable_table_create_template.sql:235`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** un reemplazo vacío da el mismo resultado salvo que deje vacía toda la cadena (entonces Oracle devuelve NULL y
  PostgreSQL `''`). En la línea de arriba el resultado solo alimenta otro `replace`, donde un reemplazo NULL también elimina el
  texto, así que no veo cambio de comportamiento (*dudoso*). No revisé `oos_util_totp.pkb:116` más allá de leer la línea
  (`regexp_replace(..., ':|;', '')`), donde se aplica la misma regla.
* **Qué hacer:** nada, salvo que el valor pueda ser exactamente el texto eliminado y luego se pruebe si es NULL.

## 5. Revisión manual de una muestra

**Método.** La muestra está estratificada por regla: los primeros 4 hallazgos de cada regla ordenados por ruta, línea y columna
(todos, si la regla tiene menos de 4). Salen 20 hallazgos. Es reproducible y **no es aleatoria**: favorece los archivos que van
primero alfabéticamente. **Los veredictos son una revisión de Claude, provisional, sobre una muestra pequeña;** no son salida de
la herramienta y nadie más los ha comprobado.

*Acierto real*: el token es la construcción de Oracle que nombra la regla y su mensaje encaja con este uso. *Dudoso*: la
construcción está, pero no pude demostrar que cambie el comportamiento aquí, o la severidad no encaja. *Falso positivo*: el token
es otra cosa.

<!-- BEGIN:sample_totals -->
Muestra revisada: 20 hallazgos, 16 aciertos reales, 4 dudosos, 0 falsos positivos.
<!-- END:sample_totals -->

<!-- BEGIN:sample -->
| # | Regla | Severidad | Ubicación | Veredicto | Motivo |
|---|---|---|---|---|---|
| 1 | MIG001 | low | `source/packages/oos_util_crypto.pkb:196` | acierto real | NVL alrededor de utl_raw.length: un COALESCE mecánico; utl_raw.length no tiene equivalente en PostgreSQL (esta versión no lo reporta). |
| 2 | MIG001 | low | `source/packages/oos_util_crypto.pkb:231` | acierto real | NVL alrededor de length() de un búfer que puede ser ''; COALESCE sirve y en PostgreSQL length('') es 0, así que la guarda es inofensiva. |
| 3 | MIG001 | low | `source/packages/oos_util_crypto.pkb:355` | acierto real | Mismo patrón que la línea 196 (NVL alrededor de utl_raw.length). |
| 4 | MIG001 | low | `source/packages/oos_util_crypto.pkb:385` | acierto real | Mismo patrón que la línea 231. |
| 5 | MIG002 | low | `source/scripts/recompile.sql:14` | acierto real | DECODE con un solo valor de búsqueda literal: equivale exactamente a un CASE. El script entero (user_objects, ALTER PACKAGE ... COMPILE) es una ayuda de instalación de Oracle sin contraparte en PostgreSQL. |
| 6 | MIG003 | medium | `source/packages/oos_util.pkb:105` | acierto real | SYSTIMESTAMP en un sleep() de espera activa. La sugerencia de la herramienta (CURRENT_TIMESTAMP, ...) sería errónea aquí: en PostgreSQL es fija durante la transacción, así que un cambio literal nunca saldría del bucle; hace falta clock_timestamp() o pg_sleep() (lectura mía, no probada). |
| 7 | MIG003 | medium | `source/packages/oos_util.pkb:113` | acierto real | El mismo bucle que la línea 105: el valor se vuelve a leer en cada iteración. |
| 8 | MIG003 | medium | `source/packages/oos_util_apex.pkb:104` | acierto real | SYSDATE comparado con una columna de fecha de una vista de APEX; la comparación se traslada, pero la vista no existe en PostgreSQL. |
| 9 | MIG003 | medium | `source/packages/oos_util_apex.pkb:105` | acierto real | La misma consulta que la línea 104. |
| 10 | MIG009 | low | `source/future/reusable_table_create_template.sql:315` | acierto real | Salida de depuración de una sentencia generada; RAISE NOTICE, mecánico. |
| 11 | MIG009 | low | `source/scripts/prereqs.sql:23` | acierto real | Salida de un script de comprobación de instalación; mecánico, pero el script es un bloque anónimo ejecutado desde SQL*Plus. |
| 12 | MIG009 | low | `source/scripts/prereqs.sql:32` | acierto real | El mismo script que la línea 23 (mensaje de error). |
| 13 | MIG009 | low | `source/scripts/prereqs.sql:40` | acierto real | El mismo script que la línea 23 (mensaje de éxito). |
| 14 | MIG010 | low | `source/future/oos_util_transform.pkb:75` | acierto real | FROM DUAL en una consulta que además usa existsnode (una función XML de Oracle): quitar el FROM es trivial; la función XML necesita su propio cambio y no se reporta. |
| 15 | MIG010 | low | `source/future/oos_util_transform.pkb:121` | acierto real | FROM DUAL alrededor de xmlquery(...); la misma observación que la línea 75. |
| 16 | MIG010 | low | `source/packages/oos_util_totp.pkb:182` | acierto real | FROM DUAL tras una expresión con bin_to_num y to_char(..., 'x'); el FROM desaparece, esas dos funciones requieren revisión y no se reportan. |
| 17 | MIG011 | medium | `source/future/reusable_table_create_template.sql:235` | dudoso | '' como reemplazo de replace(): la construcción está, pero el resultado solo entra en otro replace() cuyo reemplazo NULL también elimina el texto, así que no veo cambio de comportamiento aquí. |
| 18 | MIG011 | high | `source/packages/oos_util_crypto.pkb:229` | dudoso | Severidad high, pero el búfer solo se concatena y se mide con NVL(LENGTH(...)); no encontré un camino donde NULL frente a '' cambie el resultado (una lectura, no una prueba). |
| 19 | MIG011 | high | `source/packages/oos_util_crypto.pkb:383` | dudoso | El mismo patrón que la línea 229, en otra función de hash. |
| 20 | MIG011 | high | `source/packages/oos_util_crypto.pkb:517` | dudoso | El mismo patrón que la línea 229, en otra función de hash. |
<!-- END:sample -->

Los datos están en [`review.json`](review.json); [`tables.py`](tables.py) falla si no coinciden con la selección de arriba. Veinte
hallazgos no permiten estimar la precisión de los 36, y ninguno de los 16 *aciertos reales* dice cuánto cuesta la migración.

## 6. Lo que este informe no cubre

* **Construcciones fuera de las 11 reglas de esta versión.** En esta versión **no se detectan** `BULK COLLECT` / `FORALL`,
  `EXECUTE IMMEDIATE`, `RAISE_APPLICATION_ERROR`, los paquetes `DBMS_LOB`, `DBMS_SQL` y `UTL_FILE`, ni las funciones pipelined.
  Al leer el código vi, por ejemplo, `execute immediate l_sql;` (`reusable_table_create_template.sql:237`), que la herramienta no
  reporta. También aparecen otros elementos exclusivos de Oracle que ninguna regla cubre (`utl_raw`, `dbms_utility`, funciones
  XML como `existsnode` y `xmlquery`, `bin_to_num`, vistas de APEX).
* **La lista de fuera de alcance del contrato** ([`docs/migration-rules.md`](../../migration-rules.md)): tipos de datos, estado
  de paquete (variables de paquete e inicialización), DDL y reescritura de código. La herramienta reporta; no convierte.
* **SQL dinámico.** El texto dentro de cadenas es opaco para todas las reglas: una construcción de Oracle dentro de una cadena
  nunca se reporta.
* **Tipos de datos.** `NUMBER`, `VARCHAR2`, `DATE`, `RAW`, los LOB y el resto de la correspondencia de tipos no se examinan.
* **Rendimiento.** Nada aquí dice cómo se comportaría el código en PostgreSQL: planes, índices, hints, paralelismo.
* **Equivalencia con datos reales.** Ninguna prueba comparó resultados en Oracle y PostgreSQL para este código. Todo lo que se
  afirma del comportamiento de PostgreSQL es una lectura del código.
* **Falsos negativos.** Las reglas comparan tokens, sin semántica: no distinguen un `nvl` definido por el usuario, un `decode` de
  otro paquete o un identificador entre comillas, y se les escapa una construcción escondida en una cadena o escrita de una forma
  que el contrato no lista (por ejemplo `FROM SYS.DUAL`). La precisión de arriba es sobre lo reportado; de lo no reportado no se
  sabe nada.
* **Límites de la propia herramienta.** El campo `unit` de algunos hallazgos es impreciso: nombra `oos_util_crypto.sha256` para
  líneas que, según los rangos de líneas que leí, pertenecen a `sha512` (línea 943) y `randombytes` (líneas 1229 y 1237). Lo
  reporto y no cambié la herramienta.
* **Un solo proyecto, un solo commit.** Nada de esto se generaliza a otras bases de código.

## 7. Cómo sería la auditoría completa

1. **Inventario.** Unidades, subprogramas, parámetros y grafo de llamadas (`plsql-lens inventory`), más una lista de las
   características de Oracle de las que depende cada unidad más allá de lo que cubren las reglas.
2. **Hallazgos.** Las reglas de migración sobre todo el código, con el conjunto de reglas más reciente, y una lista de
   construcciones que ninguna regla cubre, hecha leyendo.
3. **Revisión humana.** Una persona con experiencia en Oracle y PostgreSQL revisa los hallazgos y el código que los rodea,
   decide qué se reescribe, qué se sustituye y qué se rediseña, y deja cada decisión por escrito.
4. **Pruebas diferenciales.** Rutinas seleccionadas se ejecutan en Oracle y en PostgreSQL con las mismas entradas y se comparan
   los resultados, clasificando las diferencias. Es el único paso que da evidencia de comportamiento equivalente.
5. **Informe.** Hallazgos, decisiones y resultados de las pruebas, y lo que queda sin verificar.

## 8. Cómo reproducirlo

```bash
bash scripts/demo_migration_audit.sh                 # clona en el commit fijo, ejecuta la herramienta, escribe docs/demo/oos-utils/raw/
uv run python docs/demo/oos-utils/tables.py          # comprueba que las cifras de ambos informes coinciden con raw/ y review.json
```

Necesita `git`, `uv` y acceso de red a github.com. El mismo commit da los mismos hallazgos.
