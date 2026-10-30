# PL/SQL Lens

Librería Python + CLI que analiza paquetes Oracle PL/SQL: inventaría unidades y grafos de llamadas, revisa el código
con siete reglas deterministas, genera y ejecuta tests utPLSQL, y mide las reglas con un benchmark sembrado.

## Estado

Las fases F1 a F4b y F5a a F5c están implementadas (plan y decisiones: [SPEC.md](SPEC.md); un informe por fase en
[Informes y lecturas](#informes-y-lecturas)):

| Fase | Qué entrega | Requiere |
|---|---|---|
| F1 | Parser e inventario: unidades, subprogramas, parámetros, grafo de llamadas (JSON, Mermaid) | nada |
| F2 | Reglas de revisión PLL001–PLL007 con salida tabla, JSON y SARIF; explicaciones opcionales con LLM | nada (LLM solo para `--explain`) |
| F3 | Generación de tests utPLSQL, compilar/reparar/ejecutar en Oracle Free, informe de métricas | Oracle; un LLM solo para generar |
| F4 | Benchmark sembrado de las reglas (antes/después del ajuste, línea base solo-LLM) | nada (un LLM solo para la línea base) |
| F4b | Split de autor externo: comprobación cruzada de las reglas congeladas | nada (un LLM solo para la línea base) |
| F5a | Reglas de migración Oracle→PostgreSQL MIG001–MIG011 y `plsql-lens migrate` (solo detección) | nada |
| F5d | Severidad por hallazgo en `MIG011` y `MIG002`, fuzzing diferencial de la reescritura en Oracle y PostgreSQL, y una auditoría previa a la publicación | nada (Oracle y PostgreSQL para la ejecución del fuzzing) |
| F5c | Medición de las reglas de migración sobre `corpus/`: 140 de 234 hallazgos adjudicados por impacto, y un defecto de la reescritura de `DECODE` que expuso y se corrigió | nada |
| F5b | Reescritura conservadora de SQL (`rewrite_sql`) de `NVL`, `DECODE`, `seq.NEXTVAL` y `FROM DUAL`, comprobada en PostgreSQL contra resultados observados en Oracle | nada (PostgreSQL 16 para la prueba de integración) |

## Inicio rápido

```bash
uv sync
uv run plsql-lens inventory corpus/ --format json -o inventory.json
uv run plsql-lens inventory corpus/ --format mermaid -o callgraph.mmd   # --level unit para subprogramas
uv run plsql-lens review corpus/logger/logger.pkb                       # tabla de hallazgos
uv run pytest            # tests unitarios y de aceptación; sin Docker y sin necesitar red (los de empaquetado se saltan sin conexión)
make demo-f1             # regenera docs/reports/phase-1/
```

```python
from plsql_lens import parse_file, build_inventory

ir = parse_file("corpus/logger/logger.pkb")  # IR: unidades, subprogramas, parámetros, llamadas
inv = build_inventory(["corpus/logger"])  # unidades + aristas de llamada resueltas
```

## Revisión: hallazgos de las siete reglas

`plsql-lens review RUTA` analiza un archivo o un directorio y reporta hallazgos de PLL001–PLL007 (contrato,
severidades y falsos negativos aceptados: [docs/rules.md](docs/rules.md)). Los hallazgos son funciones
deterministas del código analizado; no interviene la red ni un LLM salvo que uses `--explain`.

```bash
uv run plsql-lens review corpus/logger/logger.pkb                              # tabla (por defecto)
uv run plsql-lens review corpus/logger/logger.pkb --format json -o review.json
uv run plsql-lens review corpus/logger/logger.pkb --format sarif -o review.sarif   # SARIF 2.1.0
uv run plsql-lens review corpus/ --rules PLL001,PLL002                         # solo estas reglas
make demo-f2             # los tres formatos + conteos por regla en docs/reports/phase-2/
```

* `--format table|json|sarif` elige la salida (`table` por defecto); `-o ARCHIVO` la escribe en un archivo en vez de stdout.
* `--rules PLL001,PLL002` limita la ejecución a esos ids de regla (un id desconocido es un error).
* Un hallazgo se puede suprimir en el código con `-- plsql-lens: disable=PLL007,PLL003` (ver *Suppression* en
  [docs/rules.md](docs/rules.md)).
* `--explain` pide a un LLM que adjunte una explicación y un parche sugerido a cada hallazgo. Nunca añade, quita ni
  cambia hallazgos, y con un backend real cuesta dinero. El backend se elige con `--llm`: `claude-cli` (por defecto,
  ejecuta `claude -p`), `anthropic-api` (requiere `ANTHROPIC_API_KEY`) o `fake` (reproduce `--llm-recordings`,
  gratis). `--explain-max N` limita cuántos hallazgos se envían (los más graves primero, 10 por defecto).
* `--fail-on never|info|low|medium|high` hace que el comando termine con código 1 si algún hallazgo tiene al menos esa
  severidad (`never`, el valor por defecto, siempre termina con 0). El informe se escribe completo antes. Códigos de
  salida: [docs/cli-exit-codes.md](docs/cli-exit-codes.md).

```bash
uv run plsql-lens review corpus/logger/logger.pkb --explain --format json -o review.json   # llama al LLM
```

Salida de ejemplo y los archivos SARIF/JSON: [docs/reports/phase-2/](docs/reports/phase-2/) (como en F2, antes del ajuste de F4:
una ejecución limpia de `review` sobre `corpus/logger/logger.pkb` da 95 hallazgos y la muestra tiene 101).

## GitHub Action

`action.yml` en la raíz del repositorio es una acción compuesta: ejecuta `plsql-lens review`, escribe los hallazgos
como SARIF 2.1.0 y, con `fail-on`, hace fallar el paso a partir de un umbral de severidad. Instala la herramienta
desde su propio checkout (no está publicada en PyPI) y la subida a code scanning es opcional (`upload: true`).

```yaml
- uses: andresaragon/plsql-lens@<full-commit-sha>
  with:
    path: db/packages
    fail-on: high
```

Entradas y ejemplos de workflow completos: [docs/github-action.md](docs/github-action.md) (en inglés). Este repositorio comprueba la acción con
[`action-selftest.yml`](.github/workflows/action-selftest.yml) en los pull requests y en los pushes a `main`.

## Migración: pistas Oracle → PostgreSQL (F5a)

`plsql-lens migrate RUTA` reporta las construcciones Oracle que requieren atención al pasar PL/SQL a PostgreSQL: once reglas
deterministas sobre tokens, MIG001–MIG011 (`NVL`, `DECODE`, `SYSDATE`/`SYSTIMESTAMP`, `seq.NEXTVAL`/`CURRVAL`, `ROWNUM`,
`CONNECT BY`, `(+)`, `PRAGMA AUTONOMOUS_TRANSACTION`, `DBMS_OUTPUT`, `FROM DUAL` y el literal de cadena vacía `''`, que en
Oracle es `NULL` y en PostgreSQL no). Contrato, severidades y falsos positivos y negativos aceptados:
[docs/migration-rules.md](docs/migration-rules.md) (en inglés). Son independientes de las reglas de revisión (`review` no las
ejecuta), no interviene ningún LLM y el comando solo reporta: no reescribe código. El subconjunto mecánico (`NVL`, `DECODE`,
`seq.NEXTVAL`/`CURRVAL`, `FROM DUAL`) lo reescribe la función de la librería `plsql_lens.migrate.rewrite.rewrite_sql` (F5b; no
tiene comando en la CLI): nunca reescribe a medias y lista lo que deja intacto. Cada reescritura se ejecuta en PostgreSQL 16 contra
42 casos cuyos resultados se observaron en un Oracle real (`tests/fixtures/migrate/semantics.json`): 37 dan el mismo resultado y 5
difieren por razones ajenas a la reescritura (`''` no es `NULL` en PostgreSQL, y `'abc' || NULL` es `NULL` allí). Es evidencia sobre
esos casos, no una prueba de equivalencia general: [docs/reports/phase-5b.md](docs/reports/phase-5b.md) (en inglés). Adjudicar los
hallazgos sobre `corpus/` (140 de 234, por impacto) también expuso un defecto de la reescritura de `DECODE`, ya corregido, y mostró que
solo 2 de los 8 hallazgos de `''` son estrictamente benignos (una concatenación) y los otros 6 son trampas: [docs/reports/phase-5.md](docs/reports/phase-5.md) (en inglés).

```bash
uv run plsql-lens migrate corpus/logger/logger.pkb                          # tabla de hallazgos
uv run plsql-lens migrate corpus/ --format sarif -o migrate.sarif           # SARIF 2.1.0
uv run plsql-lens migrate corpus/ --rules MIG008,MIG011 --fail-on high      # solo estas reglas; sale con 1 si hay un hallazgo high
```

`--format`, `-o`, `--rules` y `--fail-on` funcionan como en `review` (códigos de salida: [docs/cli-exit-codes.md](docs/cli-exit-codes.md)),
y `-- plsql-lens: disable=MIG001` suprime un hallazgo en el código. Sobre `corpus/` reporta 234 hallazgos en 42 de 264
archivos; conteos por regla y lo que no significan: [docs/reports/phase-5a.md](docs/reports/phase-5a.md) (en inglés).

La severidad es por hallazgo: `MIG011` es `info` junto a `||`, `medium` como reemplazo de `replace`/`regexp_replace` y `high` en el
resto, y `MIG002` es `medium` si algún valor de búsqueda puede ser `NULL` y `low` si todos son literales, de modo que `--fail-on high`
solo se detiene ante las trampas reales ([docs/reports/migrate-severity.md](docs/reports/migrate-severity.md); sobre `corpus/`: 2
`info`, 4 `medium` y 2 `high` en `MIG011`). Una ejecución diferencial de 977 sentencias enteras generadas con `NVL`/`DECODE` dio el
mismo resultado en Oracle 23.26.3 y PostgreSQL 16.15, con 0 discrepancias y un control que sí detecta la reescritura ingenua con
`CASE`; las otras 1023 de las 2000 sentencias generadas las omite la reescritura a propósito y no se ejecutaron
([docs/reports/migrate-differential.md](docs/reports/migrate-differential.md), en inglés).

## Comandos

| Comando | Qué hace | Requiere |
|---|---|---|
| `plsql-lens inventory RUTA` | Unidades, subprogramas y grafo de llamadas resuelto; `--format json\|mermaid`, `--level package\|unit` | nada |
| `plsql-lens review RUTA` | Reglas de revisión PLL001–PLL007; `--format table\|json\|sarif`, `--rules`, `--explain`, `--fail-on` | nada (LLM solo con `--explain`) |
| `plsql-lens testgen RUTA --unit U` | Genera un paquete de tests utPLSQL para una unidad; `--run` lo compila, repara y ejecuta | LLM (cuesta dinero); Oracle para `--run` |
| `plsql-lens testgen-setup` | Instala los objetos objetivo (Logger, HR, paquetes de test) en el esquema Oracle configurado | Oracle |
| `plsql-lens testgen-suite` | Ejecuta los tests commiteados y escribe `report.json` / `junit.xml`; `--generate` los regenera | Oracle; LLM solo con `--generate` (cuesta dinero) |
| `plsql-lens migrate RUTA` | Reglas de migración Oracle→PostgreSQL MIG001–MIG011; `--format table\|json\|sarif`, `--rules`, `--fail-on` | nada |
| `plsql-lens bench` | Regenera los splits del benchmark, corre las reglas antes/después, puntúa y escribe `results.md` | nada |
| `plsql-lens bench-llm` | Línea base solo-LLM sobre una muestra con semilla del split `test`, limitada con `--max-usd` | LLM (cuesta dinero) |
| `plsql-lens bench-external` | Evaluación sobre el split de autor externo: `convert`, `run`, `run-before`, `llm`, `report` | nada; `llm` cuesta dinero |

Ejecuta `uv run plsql-lens COMANDO --help` para ver todas las opciones. Los comandos que cuestan dinero lo indican en su ayuda.

## Parser e inventario (F1)

* Lexer tolerante + parser estructural de descenso recursivo (sin dependencias de parsing externas);
  reporta los problemas estructurales en `FileIR.issues` y no lanzó excepción en ninguna de 2400 mutaciones con semilla del
  corpus. Cinco entradas con repeticiones extremas sí rompen «nunca lanza, y rápido» (un `RecursionError` y cuatro casos lentos):
  [docs/reports/robustness.md](docs/reports/robustness.md) (en inglés).
* Inventario de paquetes, procedimientos/funciones independientes, triggers y tipos, con parámetros y
  grafo de llamadas resuelto; salida JSON y Mermaid.
* Resultados medidos: [docs/reports/phase-1.md](docs/reports/phase-1.md); decisión del parser:
  [docs/adr/0001-parser.md](docs/adr/0001-parser.md).

## F3: tests utPLSQL generados (requiere Oracle)

```bash
make help
make demo-f3      # ejecuta los tests generados ya commiteados en Oracle (Docker o GitHub Actions) — sin llamadas al LLM
make testgen-f3   # los regenera con el LLM — cuesta dinero
uv run plsql-lens testgen corpus/logger/logger.pkb --unit logger.sprintf --manifest tests/fixtures/testgen/manifest.json
```

Oracle Database Free se descarga de Docker Hub (`gvenzl/oracle-free`) bajo los términos de licencia de Oracle;
este repositorio no lo redistribuye. Las contraseñas salen solo del entorno (`.env.example`). Ver
`docker/README.md` y `docs/reports/phase-3.md`.

## Benchmark

[docs/benchmarks/](docs/benchmarks/) mide las siete reglas de revisión sobre un split `test` congelado y con
semilla (350 defectos sembrados y 350 negativos difíciles, 7 reglas, 105 archivos; la metodología, la definición
de coincidencia y las amenazas a la validez están en su README). En `test`, las reglas ajustadas alcanzan
precisión 1,000 [0,99–1,00] y exhaustividad 0,998 [0,99–1,00] (464 TP / 0 FP / 1 FN); las reglas antes del ajuste
puntúan igual, y la línea base solo-LLM sobre una muestra de 40 archivos cuesta 1,13 USD. Lee la sección de amenazas
a la validez antes de citar estos números: el benchmark comprueba las reglas contra su propio contrato, no contra
defectos reales. `make bench` regenera todo sin llamar a un LLM.

El split de autor externo ([docs/benchmarks/external/](docs/benchmarks/external/), F4b) es una comprobación
cruzada con 40 casos escritos por otro LLM (Gemini), no por una persona: las reglas congeladas y una línea base solo-LLM puntúan igual, 64 TP / 2 FP / 0 FN (estricto;
adjudicado de forma provisional 65 / 1 / 0), y 0 de 9 defectos reales fuera del contrato (`beyond`). Valen las mismas
salvedades.

## Informes y lecturas

* Plan y decisiones: [SPEC.md](SPEC.md). Contrato de las reglas de revisión: [docs/rules.md](docs/rules.md). Contrato de las reglas de migración: [docs/migration-rules.md](docs/migration-rules.md).
* Informes por fase: [F1](docs/reports/phase-1.md) · [F2](docs/reports/phase-2.md) · [F3](docs/reports/phase-3.md) ·
  [F4](docs/reports/phase-4.md) · [F4b](docs/reports/phase-4b.md) · [F5a](docs/reports/phase-5a.md) · [F5b](docs/reports/phase-5b.md) · [F5c](docs/reports/phase-5.md) · [robustez](docs/reports/robustness.md) · [auditoría previa a la publicación](docs/reports/prepublication-audit.md).
* Benchmark: [metodología](docs/benchmarks/README.md) · [resultados](docs/benchmarks/results.md) ·
  [split de autor externo](docs/benchmarks/external/README.es.md) ([resultados](docs/benchmarks/external/results.md)).
* Decisiones de diseño: [ADR 0001 (parser)](docs/adr/0001-parser.md) ·
  [ADR 0002 (capa de sentencias)](docs/adr/0002-statement-layer.md).

El PL/SQL de terceros usado como entrada de pruebas está en `corpus/` y listado en [NOTICE](NOTICE).
Licencia: MIT.
