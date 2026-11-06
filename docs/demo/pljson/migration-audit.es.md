# Auditoría de migración Oracle → PostgreSQL (muestra): `pljson`

*English: [migration-audit.md](migration-audit.md).*

Este informe es una **muestra** hecha con PL/SQL Lens sobre código público contra el que no se desarrolló la herramienta. Es la
segunda muestra, después de [`oos-utils`](../oos-utils/migration-audit.es.md), y es distinta en naturaleza: `pljson` es una
biblioteca JSON construida sobre **tipos de objeto** de Oracle (`create type ... as object`, cuerpos de tipo, subtipos), no solo
sobre paquetes. Las cifras salen de la salida cruda de la herramienta ([`raw/`](raw/)) o de la revisión manual de una muestra
(señaladas como tales); los bloques de cifras se generan y se comprueban con [`tables.py`](tables.py). Lee «Lo que este informe no
cubre» antes de sacar conclusiones.

## 1. Alcance

| Elemento | Valor |
|---|---|
| Proyecto | `pljson` (pljson/pljson), una biblioteca JSON para PL/SQL de Oracle |
| URL | https://github.com/pljson/pljson |
| Commit analizado | `09a54e4e9318af36c6d27f0e7170bd4a376276b2` (rama `develop_v3`) |
| Licencia | MIT. La primera línea del archivo `LICENSE` de ese commit es «This software has been released under the MIT license:», seguida de la línea de copyright (Copyright (c) 2016 Jonas Krogsboell, Lewis R Cunningham) y del texto estándar de permisos y garantía de MIT, que leí completo. GitHub muestra la licencia como no determinada por esa primera línea. El SHA-256 del archivo está en [`raw/meta.txt`](raw/meta.txt) |
| Ruta analizada | `src/` (la biblioteca, con `src/addons/`). Se dejan fuera `examples/`, `testsuite/` y `testsuite-utplsql/` (código de ejemplo y de pruebas, no la biblioteca), y `install.sql` / `uninstall.sql` (no analizados) |
| Archivos que toma la herramienta | Todo archivo bajo `src/` tiene la extensión `.sql`, que la herramienta acepta, así que ninguno se omitió; ningún archivo falló al analizarse (los campos `ok` e `issues` de cada archivo en [`raw/inventory.json`](raw/inventory.json)) |
| PL/SQL Lens | versión 0.1.0; último commit que cambió `src/`: `558dcee3664ca4c794e723f9c1ee574350420c1e`; reglas de migración MIG001–MIG017 |
| Comando | `bash scripts/demo_migration_audit.sh pljson` (clona en el commit fijo, ejecuta `plsql-lens migrate` en formato JSON y tabla y `plsql-lens inventory`, y escribe [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Medida | Valor |
|---|---|
| Archivos PL/SQL analizados | 24 |
| Líneas en esos archivos | 7801 |
| Hallazgos | 238 |
| Archivos con al menos un hallazgo | 15 |
| Hallazgos por severidad: `high` | 83 |
| Hallazgos por severidad: `medium` | 127 |
| Hallazgos por severidad: `low` | 28 |
<!-- END:facts -->

El código de terceros no se guarda en este repositorio, solo la URL, el commit y la salida de la herramienta. Los extractos de
abajo tienen como máximo 5 líneas y provienen de `pljson` (MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham). Las fuentes no
contienen direcciones de correo (busqué por patrón en `src/`), pero sí comentarios que nombran a desarrolladores; ningún extracto
los reproduce. Los datos de prueba y los ejemplos no se analizaron ni se leyeron.

## 2. Resumen ejecutivo

<!-- BEGIN:headline -->
PL/SQL Lens (reglas de migración MIG001–MIG017) reporta **238 hallazgos en 15 de 24 archivos**: 83 `high`, 127 `medium`, 28 `low` (salida cruda).
<!-- END:headline -->

* MIG016 cuenta referencias a `DBMS_LOB` y `DBMS_SQL` (también tipos y constantes), no rutinas por rediseñar. No hay ningún
  hallazgo de `UTL_FILE` ni de `SYSDATE` / `SYSTIMESTAMP` (MIG003), así que la salvedad de la pista del reloj del issue #3 no
  aparece aquí.
* **Riesgos principales, en términos de negocio:**
  1. *Consultas dinámicas construidas sobre `DBMS_SQL`.* Los hallazgos `high` de MIG016 son las referencias a `DBMS_SQL` de un
     paquete adicional que ejecuta una consulta recibida como texto y convierte el resultado en JSON. PostgreSQL no tiene una API
     equivalente: en mi lectura es un rediseño (sección 4.1).
  2. *Texto vacío frente a NULL.* Los hallazgos `high` de MIG011 son `''` (NULL en Oracle). La mayoría parecen inofensivos en mi
     lectura (un búfer empieza vacío y se le añade texto), pero algunos deciden qué contiene la salida JSON, y la biblioteca
     tiene una opción cuyo único fin es producir una cadena vacía, algo que Oracle no puede (sección 4.2).
  3. *La estructura propia de la biblioteca.* Los tipos de objeto, una función de tabla basada en interfaz y los números de error
     lanzados con `RAISE_APPLICATION_ERROR` son lo que una migración tendría que rediseñar o mapear. Esta versión no tiene
     regla para tipos de objeto y reporta solo una parte de esto (secciones 3.1, 4.3 y 4.4).
* Revisión manual de una muestra (Claude, provisional), en la línea siguiente; una muestra de este tamaño no permite estimar la
  precisión sobre el resto de los hallazgos, y contiene falsos positivos.

<!-- BEGIN:sample_totals -->
Muestra revisada: 27 hallazgos, 24 aciertos reales, 1 dudosos, 2 falsos positivos.
<!-- END:sample_totals -->

## 3. Hallazgos por regla y severidad, y por archivo

Salida cruda: [`raw/migrate.json`](raw/migrate.json), [`raw/migrate.txt`](raw/migrate.txt).

<!-- BEGIN:by_rule -->
| Regla | Severidad | Ocurrencias | Archivos |
|---|---|---|---|
| MIG001 | low | 5 | 3 |
| MIG002 | low | 2 | 2 |
| MIG006 | medium | 1 | 1 |
| MIG009 | low | 19 | 6 |
| MIG010 | low | 2 | 2 |
| MIG011 | high | 35 | 7 |
| MIG012 | medium | 1 | 1 |
| MIG015 | medium | 42 | 6 |
| MIG016 | high | 48 | 1 |
| MIG016 | medium | 82 | 8 |
| MIG017 | medium | 1 | 1 |
<!-- END:by_rule -->

Los diez archivos con más hallazgos (todos los que tienen hallazgos, si son menos):

<!-- BEGIN:by_file -->
| Archivo | Hallazgos |
|---|---|
| `src/addons/pljson_dyn.package.sql` | 62 |
| `src/pljson_ext.impl.sql` | 52 |
| `src/pljson_printer.package.sql` | 34 |
| `src/pljson_parser.impl.sql` | 33 |
| `src/pljson_element.type.impl.sql` | 18 |
| `src/addons/pljson_table_impl.type.impl.sql` | 9 |
| `src/addons/pljson_xml.package.sql` | 7 |
| `src/pljson_string.type.sql` | 7 |
| `src/addons/pljson_object_cache.impl.sql` | 5 |
| `src/addons/pljson_util_pkg.package.sql` | 5 |
| **Total** (15) | 238 |
<!-- END:by_file -->

MIG017 cuenta dos veces una función pipelined que tenga especificación y cuerpo; aquí el único hallazgo está en la
especificación de un tipo (sección 4.3).

### 3.1 Tipos de objeto y lo que muestra el inventario

`plsql-lens inventory` ([`raw/inventory.json`](raw/inventory.json)) lista, para este proyecto:

<!-- BEGIN:inventory -->
| Tipo de unidad en el inventario | Unidades |
|---|---|
| `function` | 150 |
| `package` | 9 |
| `procedure` | 54 |
| `type` | 12 |
| **Total** | 225 |
<!-- END:inventory -->

Las funciones y procedimientos miembro de un tipo aparecen como unidades `function` / `procedure`; los tipos y los paquetes son
los otros tipos de unidad. En esa lista no hay un tipo aparte para los cuerpos de tipo. Lo que pude y no pude establecer, y cómo:

* **La detección no depende del inventario.** Las reglas de migración leen los tokens del archivo completo, así que reportan
  hallazgos dentro de cuerpos de tipo. Por ejemplo, los constructores de `pljson_string` (un archivo con el tipo y su cuerpo)
  tienen hallazgos.
* **El inventario reporta de menos los tipos cuando un archivo tiene más de uno.** En `src/pljson_element.type.decl.sql` la
  fuente tiene cuatro sentencias `create type` (`pljson_path_segment`, `pljson_path`, `pljson_element` y `pljson_element_array`);
  ejecuté el parser sobre el archivo y devuelve una unidad, `pljson_path_segment`. `pljson_element`, el tipo base de la
  biblioteca, no tiene unidad desde ese archivo.
* **Cuando un tipo y su cuerpo están en el mismo archivo, el cuerpo no es una unidad.** Ejecuté el parser sobre los cuatro tipos
  de un solo archivo (`pljson_bool`, `pljson_null`, `pljson_number`, `pljson_string`, extensión `.type.sql`): cada uno devuelve
  una unidad `type` con los miembros declarados en la especificación y ninguna unidad `type_body`. El mismo tipo en dos archivos
  (`.type.decl.sql` y `.type.impl.sql`) sí tiene una unidad `type_body` para el archivo del cuerpo. Los hallazgos en el cuerpo de
  dos de ellos (`pljson_number`, `pljson_string`) llevan el nombre del tipo en su campo `unit`, no el del miembro.
* **Reproducción mínima** (dos fuentes que escribí yo; se ejecuta con `uv run python` y usa solo el parser de la biblioteca):

  ```python
  from plsql_lens.parser import parse_source

  SPEC_AND_BODY = """create or replace type t_a as object (
    member function is_a return boolean
  )
  /
  create or replace type body t_a as
    member function is_a return boolean as
    begin
      return true;
    end;
  end;
  /
  """
  TWO_TYPES = """create or replace type t_one as object (
    n number
  )
  /
  create or replace type t_two as object (
    member function is_two return boolean
  )
  /
  """
  for name, src in (("spec and body", SPEC_AND_BODY), ("two types", TWO_TYPES)):
      ir = parse_source(src, "x.sql")
      print(name, [(u.kind, u.name, [s.name for s in u.subprograms]) for u in ir.units])
  ```

  Salida al ejecutarlo: `spec and body [('type', 't_a', ['is_a'])]` y `two types [('type', 't_one', [])]`. No investigué la
  causa; es una observación de la herramienta, no un diagnóstico, y no la cambié. Probé solo estas formas y los archivos de este
  proyecto.
* **El campo `unit` no se usa en este informe** para decir dónde está un hallazgo (issue #4: el campo puede nombrar una rutina
  equivocada). Las ubicaciones son `archivo:línea` en la fuente del commit fijado.

## 4. Riesgos principales

Lo que se dice de PostgreSQL es mi lectura del código; **nada se ejecutó en una base de datos**. Lo que leí: los hallazgos de la
muestra de la sección 5 en su contexto (las líneas alrededor), el código alrededor de las líneas citadas abajo y el texto de la
línea de cada hallazgo de MIG011. No leí en contexto el resto de los hallazgos de ninguna regla, y el informe no dice nada de
ellos más allá de los conteos.

### 4.1 `DBMS_SQL` (MIG016, `high`) — `addons/pljson_dyn.package.sql`

```plsql
      bind_elem := bindvar.get(i);
      if (bind_elem.is_number()) then
        dbms_sql.bind_variable(l_cur, ':'||key_str, bind_elem.get_number());
```
*(`src/addons/pljson_dyn.package.sql:91-93`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **Qué cambia:** este paquete recibe una consulta como texto más valores de enlace, la ejecuta con la API de cursores de
  `DBMS_SQL` y devuelve las filas como JSON. PostgreSQL no tiene una API de números de cursor.
* **Qué hacer:** decidir si el paquete adicional está dentro del alcance. Si lo está, rediseñarlo con `EXECUTE ... USING` y una
  forma de describir las columnas del resultado; el trabajo está en el diseño, no en la cantidad de referencias. Leí la parte de
  enlace del paquete (líneas 91–118) y no el resto.

### 4.2 `''` donde Oracle quiere decir NULL (MIG011, `high`) — varios archivos

```plsql
          if (l_val is null) then
            if (null_as_empty_string) then
              inner_obj.put(l_dtbl(i).col_name, ''); --treat as emptystring?
```
*(`src/addons/pljson_dyn.package.sql:215-217`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **Qué cambia:** en Oracle `''` es NULL; en PostgreSQL es una cadena vacía. La línea de arriba muestra una opción que pide una
  cadena vacía y no puede obtenerla en Oracle (el propio comentario lleva un signo de interrogación); tras una migración la misma
  opción produciría una cadena vacía real, así que el JSON diferiría del que producía Oracle.
* **Lectura de los demás.** Muchos de los hallazgos son un búfer declarado como `varchar2(32767) := ''` (`pljson_printer`,
  `pljson_parser`, `pljson_xml`), el comienzo habitual de una cadena a la que luego se añade texto; vi el añadido en `tab()` de
  `pljson_printer` y no leí el código alrededor de los otros. Si eso es todo lo que hacen, el resultado es el mismo en ambas
  bases de datos. Algunos son `return ''` de una función (`pljson_printer`, `pljson_ext`) y un parámetro de constructor con
  `default ''` (`pljson_string`): devolverían o tomarían por defecto una cadena vacía en lugar de NULL, lo que importa solo si un
  llamador prueba si es NULL; no revisé los llamadores. Uno es el nombre de un miembro:

  ```plsql
      if (nulljsonvalue is not null) then
        validated.put('', nulljsonvalue);
      end if;
  ```
  *(`src/pljson_parser.impl.sql:913-915`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

  Un miembro cuyo nombre es `''` tiene nombre NULL en Oracle y nombre vacío en PostgreSQL. No seguí el código más allá para ver
  qué hace la biblioteca con ese miembro.
* **Qué hacer:** decidir en cada lugar si se quiere NULL o cadena vacía, y probar la salida JSON de la biblioteca con documentos
  conocidos en ambas bases de datos (pruebas diferenciales, sección 8).

### 4.3 Función pipelined basada en interfaz (MIG017, `medium`) — `addons/pljson_table_impl.type.decl.sql`

```plsql
    table_mode varchar2 := 'cartesian'
  ) return anydataset
  pipelined using pljson_table_impl
```
*(`src/addons/pljson_table_impl.type.decl.sql:156-158`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **Qué cambia:** es una función de tabla implementada mediante una interfaz de Oracle: el tipo declara los métodos
  `ODCITable...` que Oracle invoca para preparar, leer y cerrar las filas. La sugerencia de la herramienta (`RETURNS SETOF` con
  `RETURN NEXT`) no describe este trabajo; la interfaz no tiene contraparte en PostgreSQL. Por eso clasifiqué el hallazgo como
  *dudoso* en la muestra (la construcción está; el consejo no encaja).
* **Qué hacer:** sustituir el tipo entero por una función que devuelva un conjunto (su lógica es la conversión de JSON a filas),
  después de decidir si la funcionalidad está dentro del alcance.

### 4.4 Números de error (MIG015, `medium`) — varios archivos

```plsql
        if not starts_with(nested_path_prefix, last_nested_path_full) then
          --dbms_output.put_line('column paths are not nested, column# ' || i);
          raise_application_error(-20120, 'column paths are not nested, column# ' || i);
```
*(`src/addons/pljson_table_impl.type.impl.sql:268-270`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **Qué cambia:** la biblioteca señala errores con `RAISE_APPLICATION_ERROR` y números del rango -20000 (vi -20110 y -20120 en la
  muestra). `RAISE EXCEPTION ... USING ERRCODE` traslada la llamada; el código que prueba el número no se traslada solo.
* **Qué hacer:** listar los números que lanza la biblioteca, asignarles códigos y revisar los llamadores que los tratan (las
  suites de prueba del proyecto serían el lugar donde mirar; aquí no se leyeron).

## 5. Revisión manual de una muestra

**Método.** La muestra está estratificada por regla: los primeros 4 hallazgos de cada regla que tenga hallazgos, ordenados por
ruta, línea y columna (todos, si la regla tiene menos de 4). Es reproducible y **no es aleatoria**: favorece los archivos que van
primero alfabéticamente (aquí los complementos van antes que los archivos de `src/`). **Los veredictos son una revisión de
Claude, provisional, sobre una muestra pequeña;** no son salida de la herramienta y nadie más los ha comprobado. Leí cada
hallazgo en la fuente del commit fijado, con las líneas alrededor.

*Acierto real*: el token es la construcción de Oracle que nombra la regla y su mensaje encaja con este uso. *Dudoso*: la
construcción está, pero no pude demostrar que cambie el comportamiento aquí, o el consejo o la severidad no encajan. *Falso
positivo*: el token es otra cosa.

<!-- BEGIN:sample_totals -->
Muestra revisada: 27 hallazgos, 24 aciertos reales, 1 dudosos, 2 falsos positivos.
<!-- END:sample_totals -->

<!-- BEGIN:sample -->
| # | Regla | Severidad | Ubicación | Veredicto | Motivo |
|---|---|---|---|---|---|
| 1 | MIG001 | low | `src/addons/pljson_table_impl.type.impl.sql:274` | acierto real | NVL(length(...), 0) dentro de substr(): un COALESCE mecánico. |
| 2 | MIG001 | low | `src/addons/pljson_table_impl.type.impl.sql:291` | acierto real | El mismo patrón que la fila anterior (NVL alrededor de length()). |
| 3 | MIG001 | low | `src/addons/pljson_xml.package.sql:141` | acierto real | NVL(tagname, 'array') como argumento: un COALESCE mecánico. |
| 4 | MIG001 | low | `src/pljson_number.type.sql:47` | acierto real | NVL(num, 0) en el constructor de un tipo: un COALESCE mecánico. |
| 5 | MIG002 | low | `src/pljson_ext.decl.sql:108` | falso positivo | Es la declaración de la propia función del paquete llamada decode (function decode(v pljson_string) return blob), no una llamada al DECODE de Oracle. El contrato dice que las reglas no tienen semántica. |
| 6 | MIG002 | low | `src/pljson_ext.impl.sql:1017` | falso positivo | El cuerpo de la misma función decode definida por el usuario; la misma observación que la fila anterior. |
| 7 | MIG006 | medium | `src/pljson_parser.impl.sql:45` | acierto real | CONNECT BY LEVEL <= n usado como generador de filas sobre dual para partir una cadena en caracteres; PostgreSQL necesita generate_series() o una consulta recursiva (lectura mía). |
| 8 | MIG009 | low | `src/addons/pljson_dyn.package.sql:197` | acierto real | dbms_output.put_line de un mensaje 'unhandled col_type'; RAISE NOTICE, mecánico. |
| 9 | MIG009 | low | `src/addons/pljson_dyn.package.sql:371` | acierto real | El mismo mensaje en una segunda rutina del mismo paquete; mecánico. |
| 10 | MIG009 | low | `src/addons/pljson_object_cache.impl.sql:42` | acierto real | La primera de varias llamadas a dbms_output.put_line de un procedimiento que imprime estadísticas; RAISE NOTICE, mecánico. |
| 11 | MIG009 | low | `src/addons/pljson_object_cache.impl.sql:43` | acierto real | La línea siguiente del mismo procedimiento; la misma observación. |
| 12 | MIG010 | low | `src/addons/pljson_util_pkg.package.sql:325` | acierto real | FROM DUAL en una consulta que además llama a los métodos de XMLType transform() y getclobval(); quitar el FROM es trivial, los métodos XML requieren su propio cambio y no se reportan. |
| 13 | MIG010 | low | `src/pljson_parser.impl.sql:44` | acierto real | FROM DUAL en la misma sentencia que el CONNECT BY de la fila MIG006 anterior. |
| 14 | MIG011 | high | `src/addons/pljson_dyn.package.sql:102` | acierto real | '' asignado a un elemento de una tabla de cadenas que luego se enlaza con dbms_sql.bind_array para un null de JSON: Oracle enlaza NULL y PostgreSQL enlazaría una cadena vacía (lectura mía de la semántica, no ejecutada). |
| 15 | MIG011 | high | `src/addons/pljson_dyn.package.sql:118` | acierto real | '' pasado como valor de enlace para un null de JSON: NULL en Oracle, cadena vacía en PostgreSQL. |
| 16 | MIG011 | high | `src/addons/pljson_dyn.package.sql:217` | acierto real | El código pide una cadena vacía cuando una columna es nula (el propio comentario dice 'treat as emptystring?'), pero en Oracle '' es NULL; en PostgreSQL la opción produciría una cadena vacía real, así que la salida difiere de la que daba Oracle. |
| 17 | MIG011 | high | `src/addons/pljson_dyn.package.sql:261` | acierto real | El mismo patrón para una columna CLOB de longitud 0. |
| 18 | MIG012 | medium | `src/pljson_parser.impl.sql:43` | acierto real | SELECT ... BULK COLLECT INTO s.src_array sobre un generador de filas con CONNECT BY: PostgreSQL necesita array_agg() o un bucle. |
| 19 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:270` | acierto real | Llamada con el número de error -20120 y un mensaje; RAISE EXCEPTION ... USING ERRCODE traslada la llamada, y quien pruebe el número necesita una correspondencia. |
| 20 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:277` | acierto real | El mismo número de error en una segunda rama del mismo método. |
| 21 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:389` | acierto real | El mismo número de error otra vez, en el camino de lectura del tipo de la función de tabla. |
| 22 | MIG015 | medium | `src/pljson.type.impl.sql:517` | acierto real | Error -20110 lanzado desde el tipo de objeto pljson; la misma observación. |
| 23 | MIG016 | high | `src/addons/pljson_dyn.package.sql:93` | acierto real | dbms_sql.bind_variable dentro de un ejecutor de consultas dinámicas: DBMS_SQL no tiene equivalente en PostgreSQL, hay que rediseñar con EXECUTE ... USING. |
| 24 | MIG016 | high | `src/addons/pljson_dyn.package.sql:96` | acierto real | Una variable declarada con el tipo dbms_sql.varchar2_table: la regla cuenta la referencia al tipo. |
| 25 | MIG016 | high | `src/addons/pljson_dyn.package.sql:107` | acierto real | dbms_sql.bind_array con el arreglo anterior; el mismo rediseño. |
| 26 | MIG016 | high | `src/addons/pljson_dyn.package.sql:115` | acierto real | dbms_sql.bind_variable con una fecha; el mismo rediseño. |
| 27 | MIG017 | medium | `src/addons/pljson_table_impl.type.decl.sql:158` | dudoso | 'pipelined using pljson_table_impl' es una función de tabla basada en interfaz (el tipo implementa los métodos ODCITable). La construcción está, pero la sugerencia (RETURNS SETOF con RETURN NEXT) no describe el trabajo: la interfaz no tiene contraparte en PostgreSQL, así que es un rediseño. |
<!-- END:sample -->

Los datos están en [`review.json`](review.json); [`tables.py`](tables.py) falla si no coinciden con la selección de arriba. Los dos
falsos positivos son los dos hallazgos de MIG002 del proyecto, sobre una función que la propia biblioteca define con el nombre
`decode`: las reglas comparan tokens y no tienen semántica (lo dice el contrato). La muestra contiene todos los hallazgos de
MIG002; de las demás reglas no dice nada más allá de sus propias filas.

## 6. Comparación con `oos-utils`

Ocurrencias por regla en las dos muestras (misma versión de la herramienta, MIG001–MIG017, salida cruda de cada proyecto). MIG016
cuenta referencias y MIG017 cuenta por separado especificación y cuerpo; los conteos no son comparables como cantidad de trabajo.

<!-- BEGIN:compare -->
| Regla | oos-utils | pljson |
|---|---|---|
| MIG001 | 14 | 5 |
| MIG002 | 1 | 2 |
| MIG003 | 6 | 0 |
| MIG006 | 0 | 1 |
| MIG009 | 5 | 19 |
| MIG010 | 3 | 2 |
| MIG011 | 7 | 35 |
| MIG012 | 2 | 1 |
| MIG014 | 13 | 0 |
| MIG015 | 3 | 42 |
| MIG016 | 37 | 130 |
| MIG017 | 4 | 1 |
| **Total** | **95** | **238** |
<!-- END:compare -->

Dos proyectos no son una muestra del mundo Oracle, y nada de esto respalda una conclusión sobre qué tan frecuente es una
construcción.

## 7. Lo que este informe no cubre

* **Tipos de objeto.** La herramienta no tiene regla para `create type ... as object`, los métodos `member` / `constructor` /
  `overriding`, `under` (subtipos), `self` ni la interfaz `ODCITable`; y el inventario tiene los límites de la sección 3.1. Lo
  que costaría migrar los tipos (tipos compuestos más funciones, sin métodos ni herencia en PostgreSQL, en mi lectura) no está
  medido.
* **Otros elementos exclusivos de Oracle que ninguna regla cubre, vistos al leer:** la prueba `IS OF (tipo)`, tipos de colección
  como `pljson_varray`, `anydataset`, métodos de XMLType (`transform`, `getclobval`) y `CONNECT BY LEVEL` usado como generador de
  filas (este último lo reporta MIG006, pero su reemplazo requiere diseño).
* **La lista de fuera de alcance del contrato** ([`docs/migration-rules.md`](../../migration-rules.md)): tipos de datos, estado
  de paquete (variables de paquete e inicialización), DDL y reescritura de código. La herramienta reporta; no convierte.
* **SQL dinámico.** El texto dentro de cadenas es opaco para todas las reglas: una construcción de Oracle dentro de una cadena
  nunca se reporta.
* **Tipos de datos.** `NUMBER`, `VARCHAR2`, `DATE`, `RAW`, los LOB, el manejo de `CLOB` y el resto de la correspondencia de tipos
  no se examinan. Una biblioteca JSON mueve mucho texto y números; sus reglas de conversión quedan fuera de este informe.
* **Rendimiento.** Nada aquí dice cómo se comportaría el código en PostgreSQL.
* **Equivalencia con datos reales.** Ninguna prueba comparó resultados en Oracle y PostgreSQL para este código. Todo lo que se
  afirma del comportamiento de PostgreSQL es una lectura del código.
* **Falsos negativos.** Las reglas comparan tokens, sin semántica (secciones 5 y anteriores): se le escapa una construcción
  escondida en una cadena o escrita de una forma que el contrato no lista, y se marca una función definida por el usuario que
  tiene el nombre de una de Oracle. La precisión de arriba es sobre lo reportado; de lo no reportado no se sabe nada.
* **Límites de la propia herramienta.** El campo `unit` de algunos hallazgos puede estar equivocado (issue #4) y el inventario
  reporta de menos los tipos (sección 3.1). Este informe no usa ninguno de los dos para ubicar hallazgos.
* **Un solo proyecto, un solo commit.** Nada de esto se generaliza a otras bases de código.

## 8. Cómo sería la auditoría completa

1. **Inventario.** Unidades, subprogramas, parámetros y grafo de llamadas (`plsql-lens inventory`), contrastados con una lectura
   directa para las formas que la herramienta reporta de menos (los tipos de objeto en particular), más una lista de las
   características de Oracle de las que depende cada unidad más allá de lo que cubren las reglas.
2. **Hallazgos.** Las reglas de migración sobre todo el código, con el conjunto de reglas más reciente, y una lista de
   construcciones que ninguna regla cubre, hecha leyendo.
3. **Revisión humana.** Una persona con experiencia en Oracle y PostgreSQL revisa los hallazgos y el código que los rodea,
   decide qué se reescribe, qué se sustituye y qué se rediseña, y deja cada decisión por escrito.
4. **Pruebas diferenciales.** Rutinas seleccionadas se ejecutan en Oracle y en PostgreSQL con las mismas entradas y se comparan
   los resultados, clasificando las diferencias. Es el único paso que da evidencia de comportamiento equivalente.
5. **Informe.** Hallazgos, decisiones y resultados de las pruebas, y lo que queda sin verificar.

## 9. Cómo reproducirlo

```bash
bash scripts/demo_migration_audit.sh pljson          # clona en el commit fijo, ejecuta la herramienta, escribe docs/demo/pljson/raw/
uv run python docs/demo/pljson/tables.py             # comprueba que las cifras de ambos informes coinciden con raw/ y review.json
```

Necesita `git`, `uv` y acceso de red a github.com. El mismo commit da los mismos hallazgos.
