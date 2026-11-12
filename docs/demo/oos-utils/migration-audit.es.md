# Auditoría de migración Oracle → PostgreSQL (muestra): `oos-utils`

*English: [migration-audit.md](migration-audit.md).*

Este informe es una **muestra** hecha con PL/SQL Lens sobre código público contra el que no se desarrolló la herramienta. Las
cifras salen de la salida cruda de la herramienta ([`raw/`](raw/)) o de la revisión manual de una muestra (señaladas como tales);
los bloques de cifras se generan y se comprueban con [`tables.py`](tables.py). Lee «Lo que este informe no cubre» antes de sacar
conclusiones.

**Revisión 2 (2026-11-04).** Publicado primero con las reglas MIG001–MIG011 (36 hallazgos, muestra revisada de 20). Regenerado tras fusionar las reglas MIG012–MIG017 (95 hallazgos, muestra de 37); el texto de la sección 4.6 y las cifras que cambiaron son nuevos, el resto sigue igual. La primera revisión queda en el historial de git de este archivo.

## 1. Alcance

| Elemento | Valor |
|---|---|
| Proyecto | `oos-utils` (OraOpenSource), una biblioteca de utilidades PL/SQL |
| URL | https://github.com/OraOpenSource/oos-utils |
| Commit analizado | `b6217292bc744211eaee9e1d11ca7a0b495bc44d` |
| Licencia | MIT, leída en el archivo `LICENSE` de ese commit (copyright 2015 OraOpenSource); el SHA-256 del archivo está en [`raw/meta.txt`](raw/meta.txt) |
| Ruta analizada | `source/` (paquetes, `source/future/` y los scripts SQL). Se deja fuera `install/`: su cabecera dice que se genera automáticamente a partir de las mismas fuentes, y contarlo sería contarlas dos veces |
| PL/SQL Lens | versión 0.1.0; último commit que cambió `src/`: `558dcee3664ca4c794e723f9c1ee574350420c1e`; reglas de migración MIG001–MIG017 |
| Comando | `bash scripts/demo_migration_audit.sh` (clona en el commit fijo, ejecuta `plsql-lens migrate` en formato JSON y tabla y `plsql-lens inventory`, y escribe [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Medida | Valor |
|---|---|
| Archivos PL/SQL analizados | 26 |
| Líneas en esos archivos | 6449 |
| Hallazgos | 95 |
| Archivos con al menos un hallazgo | 14 |
| Hallazgos por severidad: `high` | 18 |
| Hallazgos por severidad: `medium` | 54 |
| Hallazgos por severidad: `low` | 23 |
<!-- END:facts -->

El código de terceros no se guarda en este repositorio, solo la URL, el commit y la salida de la herramienta. Los extractos de
abajo tienen como máximo 5 líneas y provienen de `oos-utils` (MIT, © 2015 OraOpenSource). Las fuentes contienen etiquetas de
autoría de desarrolladores en comentarios (un nombre y un correo) y una dirección de ejemplo ficticia en un comentario; ningún
extracto las reproduce. En `data/` y `tests/` (no analizados) no encontré datos personales mediante búsqueda por patrones y
lectura parcial.

## 2. Resumen ejecutivo

* PL/SQL Lens (reglas de migración MIG001–MIG017) reporta **95 hallazgos en 14 de 26 archivos**: 18 `high`, 54 `medium`, 23 `low`
  (salida cruda). 36 vienen de MIG001–MIG011 y 59 de las seis reglas añadidas tras la primera revisión (MIG012–MIG017). Los 23
  hallazgos `low` son mecánicos (NVL, `FROM DUAL`, `DBMS_OUTPUT`, un DECODE). MIG016 cuenta referencias a `DBMS_LOB` y `DBMS_SQL`
  (también tipos y constantes), no rutinas por rediseñar.
* **Riesgos principales, en términos de negocio:**
  1. *Diferencias silenciosas con el texto vacío.* Cinco de los hallazgos `high` (MIG011) asignan `''` (que en Oracle es NULL) a un búfer
     dentro de rutinas de hash. En mi lectura el resultado no cambia aquí, pero es la categoría de defecto que convierte una
     migración de «compila» en «devuelve otros datos», y requiere una prueba, no solo una revisión.
  2. *Código que depende de la hora.* Un bucle de espera usa `SYSTIMESTAMP`; el reemplazo que sugiere la herramienta
     (`CURRENT_TIMESTAMP`) es fijo durante una transacción de PostgreSQL y haría que ese bucle no termine nunca (issue #3).
  3. *Código que hay que rediseñar, no portar.* Los 13 hallazgos de `DBMS_SQL` (`high`) están en una sola rutina que convierte un
     REF CURSOR en un cursor de `DBMS_SQL` y describe sus columnas; PostgreSQL no tiene una API equivalente (sección 4.6).
  4. *Características exclusivas de Oracle alrededor de los hallazgos que esta versión no mira* (funciones sobre bytes,
     funciones XML, vistas de APEX y el texto dentro del SQL dinámico, que las reglas señalan pero no leen). Los 95 hallazgos son
     lo que ven 17 reglas, no una estimación del trabajo.
* Revisión manual de una muestra de 37 hallazgos (Claude, provisional): 33 aciertos reales, 4 dudosos, 0 falsos positivos. Treinta
  y siete hallazgos no permiten estimar la precisión sobre los otros 58.

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
| MIG012 | medium | 2 | 1 |
| MIG014 | medium | 13 | 3 |
| MIG015 | medium | 3 | 2 |
| MIG016 | high | 13 | 1 |
| MIG016 | medium | 24 | 5 |
| MIG017 | medium | 4 | 2 |
<!-- END:by_rule -->

Los diez archivos con más hallazgos (todos los que tienen hallazgos, si son menos):

<!-- BEGIN:by_file -->
| Archivo | Hallazgos |
|---|---|
| `source/future/oos_util_transform.pkb` | 21 |
| `source/packages/oos_util_crypto.pkb` | 18 |
| `source/future/reusable_table_create_template.sql` | 15 |
| `source/packages/oos_util_lob.pkb` | 15 |
| `source/packages/oos_util_string.pkb` | 6 |
| `source/scripts/prereqs.sql` | 6 |
| `source/packages/oos_util.pkb` | 3 |
| `source/packages/oos_util_apex.pkb` | 2 |
| `source/packages/oos_util_string.pks` | 2 |
| `source/packages/oos_util_totp.pkb` | 2 |
| **Total** (14) | 95 |
<!-- END:by_file -->

## 4. Riesgos principales

Se leyeron en contexto los 13 hallazgos `high` y `medium` de MIG001–MIG011 (5 `high`, 8 `medium`). De los 59 de MIG012–MIG017 solo
se leyeron los 17 de la muestra de la sección 5, y la 4.6 describe lo que mostró esa lectura. Lo que se dice de PostgreSQL es mi
lectura del código; **nada se ejecutó en una base de datos**.

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

### 4.6 SQL dinámico y `DBMS_SQL` (MIG014 y MIG016) — `oos_util_transform.pkb`, `reusable_table_create_template.sql`

```plsql
    v_cur_id := dbms_sql.to_cursor_number(p_rc);

    dbms_sql.describe_columns3(v_cur_id, v_col_count, v_col_desc);
```
*(`source/future/oos_util_transform.pkb:218-220`, oos-utils, MIT, © 2015 OraOpenSource)*

* **Qué cambia:** los 13 hallazgos de `DBMS_SQL` están en esta rutina de un archivo bajo `source/future/`: convierte un REF CURSOR
  en un cursor de `DBMS_SQL` y describe sus columnas para escribir texto. PostgreSQL no tiene una API de números de cursor, así que
  en mi lectura esto es un rediseño y no un porte. De los 13 hallazgos de `EXECUTE IMMEDIATE` (MIG014), 11 están en un script
  plantilla de creación de tablas que arma texto `CREATE` / `ALTER` desde constantes con `replace()` y lo ejecuta; cada sentencia
  se porta como `EXECUTE`, pero la regla no analiza el texto del DDL.
* **Qué hacer:** decidir primero si el código bajo `source/future/` entra en el alcance de la migración: concentra 24 de estos 26
  hallazgos. No comprobé si el resto del proyecto lo usa.

## 5. Revisión manual de una muestra

**Método.** La muestra está estratificada por regla: los primeros 4 hallazgos de cada regla ordenados por ruta, línea y columna
(todos, si la regla tiene menos de 4). Salen 37 hallazgos. Es reproducible y **no es aleatoria**: favorece los archivos que van
primero alfabéticamente. **Los veredictos son una revisión de Claude, provisional, sobre una muestra pequeña;** no son salida de
la herramienta y nadie más los ha comprobado.

*Acierto real*: el token es la construcción de Oracle que nombra la regla y su mensaje encaja con este uso. *Dudoso*: la
construcción está, pero no pude demostrar que cambie el comportamiento aquí, o la severidad no encaja. *Falso positivo*: el token
es otra cosa.

<!-- BEGIN:sample_totals -->
Muestra revisada: 37 hallazgos, 33 aciertos reales, 4 dudosos, 0 falsos positivos.
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
| 21 | MIG012 | medium | `source/future/reusable_table_create_template.sql:190` | acierto real | SELECT ... BULK COLLECT INTO una colección de nombres de restricciones leídos de user_constraints: en PostgreSQL se usa SELECT array_agg(...) INTO, y user_constraints es una vista del diccionario de Oracle sin equivalente directo (esta versión no lo reporta). |
| 22 | MIG012 | medium | `source/future/reusable_table_create_template.sql:329` | acierto real | Mismo patrón que la línea 190, leyendo user_triggers. |
| 23 | MIG014 | medium | `source/future/reusable_table_create_template.sql:94` | acierto real | DDL dinámico: l_sql es la constante plantilla c_table_sql con %table_name% sustituido. EXECUTE l_sql se porta, pero la regla no analiza el texto del DDL, así que la sintaxis solo de Oracle que lleve dentro necesitaría su propia revisión. |
| 24 | MIG014 | medium | `source/future/reusable_table_create_template.sql:129` | acierto real | ALTER TABLE ... ADD dinámico armado desde c_add_column_sql con replace(); el tipo de dato viene de una variable. Misma salvedad que la línea 94: el texto del DDL no se analiza. |
| 25 | MIG014 | medium | `source/future/reusable_table_create_template.sql:159` | acierto real | ALTER TABLE ... DROP COLUMN dinámico desde c_drop_column_sql; misma salvedad que la línea 94. |
| 26 | MIG014 | medium | `source/future/reusable_table_create_template.sql:177` | acierto real | CREATE SEQUENCE dinámico desde c_sequence_sql (un literal q'!...!'); misma salvedad que la línea 94. |
| 27 | MIG015 | medium | `source/packages/oos_util.pkb:70` | acierto real | Llamada con la constante del paquete gc_assert_error_number (-20000, definida en la línea 5 del cuerpo): la regla no ve el valor. Quien compare SQLCODE = -20000 necesita la correspondencia con un ERRCODE. |
| 28 | MIG015 | medium | `source/scripts/prereqs.sql:46` | acierto real | -20000 en un bloque anónimo de la comprobación de instalación para SQL*Plus; RAISE EXCEPTION ... USING ERRCODE porta la llamada, pero el script completo es un ayudante de instalación de Oracle. |
| 29 | MIG015 | medium | `source/scripts/prereqs.sql:51` | acierto real | -20001, mismo script y misma salvedad que la línea 46. |
| 30 | MIG016 | high | `source/future/oos_util_transform.pkb:206` | acierto real | Una variable declarada con el tipo dbms_sql.desc_tab3: la regla cuenta la referencia al tipo. La rutina describe las columnas de un cursor arbitrario con DBMS_SQL (describe_columns3), que no tiene equivalente en PostgreSQL: es un rediseño, no un porte. |
| 31 | MIG016 | medium | `source/future/oos_util_transform.pkb:214` | acierto real | dbms_lob.createtemporary para un CLOB local: en PostgreSQL el valor es una variable text; no hay ciclo de vida ni duración de LOB temporal. |
| 32 | MIG016 | medium | `source/future/oos_util_transform.pkb:216` | acierto real | La constante dbms_lob.call usada como argumento de la llamada anterior (cuenta como acierto por el contrato); desaparece con esa llamada. |
| 33 | MIG016 | high | `source/future/oos_util_transform.pkb:218` | acierto real | dbms_sql.to_cursor_number convierte un REF CURSOR en un número de cursor de DBMS_SQL: no hay equivalente, y el resto de la rutina depende de eso. |
| 34 | MIG017 | medium | `source/packages/oos_util_string.pkb:455` | acierto real | Función pipelined (listunagg, sobrecarga varchar2) en el cuerpo: RETURNS SETOF con RETURN NEXT, y PIPE ROW desaparece. El tipo devuelto oos_util.tab_vc2 es un tipo de colección. |
| 35 | MIG017 | medium | `source/packages/oos_util_string.pkb:484` | acierto real | La segunda sobrecarga de listunagg (clob), en el cuerpo; misma salvedad que la línea 455. |
| 36 | MIG017 | medium | `source/packages/oos_util_string.pks:81` | acierto real | La misma función en la especificación del paquete: el contrato cuenta especificación y cuerpo, así que una función da dos hallazgos. |
| 37 | MIG017 | medium | `source/packages/oos_util_string.pks:86` | acierto real | Especificación de la sobrecarga clob; misma salvedad que la línea 81. |
<!-- END:sample -->

Los datos están en [`review.json`](review.json); [`tables.py`](tables.py) falla si no coinciden con la selección de arriba. Treinta y siete
hallazgos no permiten estimar la precisión de los 95, y ninguno de los 33 *aciertos reales* dice cuánto cuesta la migración.

## 6. Lo que este informe no cubre

* **Construcciones fuera de las 17 reglas de esta versión.** `BULK COLLECT` / `FORALL`, `EXECUTE IMMEDIATE`,
  `RAISE_APPLICATION_ERROR`, los paquetes `DBMS_LOB`, `DBMS_SQL` y `UTL_FILE` y las funciones pipelined se detectan desde
  MIG012–MIG017, que solo detectan y nunca reescriben, y el texto dentro del SQL dinámico no se analiza. También aparecen otros
  elementos exclusivos de Oracle que ninguna regla cubre (`utl_raw`, `dbms_utility`, funciones
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
