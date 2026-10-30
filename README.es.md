# PL/SQL Lens

Librería Python + CLI que analiza paquetes Oracle PL/SQL: inventaría unidades y grafos de llamadas, revisa el código
con siete reglas deterministas, genera y ejecuta tests utPLSQL, y mide las reglas con un benchmark sembrado.

## Estado

Las fases F1 a F4b están implementadas (plan y decisiones: [SPEC.md](SPEC.md); un informe por fase en
[Informes y lecturas](#informes-y-lecturas)):

| Fase | Qué entrega | Requiere |
|---|---|---|
| F1 | Parser e inventario: unidades, subprogramas, parámetros, grafo de llamadas (JSON, Mermaid) | nada |
| F2 | Reglas de revisión PLL001–PLL007 con salida tabla, JSON y SARIF; explicaciones opcionales con LLM | nada (LLM solo para `--explain`) |
| F3 | Generación de tests utPLSQL, compilar/reparar/ejecutar en Oracle Free, informe de métricas | Oracle; un LLM solo para generar |
| F4 | Benchmark sembrado de las reglas (antes/después del ajuste, línea base solo-LLM) | nada (un LLM solo para la línea base) |
| F4b | Split de autor externo: comprobación cruzada de las reglas congeladas | nada (un LLM solo para la línea base) |

## Inicio rápido

```bash
uv sync
uv run plsql-lens inventory corpus/ --format json -o inventory.json
uv run plsql-lens inventory corpus/ --format mermaid -o callgraph.mmd   # --level unit para subprogramas
uv run plsql-lens review corpus/logger/logger.pkb                       # tabla de hallazgos
uv run pytest            # tests unitarios y de aceptación, sin red ni Docker
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

```bash
uv run plsql-lens review corpus/logger/logger.pkb --explain --format json -o review.json   # llama al LLM
```

Salida de ejemplo y los archivos SARIF/JSON: [docs/reports/phase-2/](docs/reports/phase-2/).

## Comandos

| Comando | Qué hace | Requiere |
|---|---|---|
| `plsql-lens inventory RUTA` | Unidades, subprogramas y grafo de llamadas resuelto; `--format json\|mermaid`, `--level package\|unit` | nada |
| `plsql-lens review RUTA` | Reglas de revisión PLL001–PLL007; `--format table\|json\|sarif`, `--rules`, `--explain` | nada (LLM solo con `--explain`) |
| `plsql-lens testgen RUTA --unit U` | Genera un paquete de tests utPLSQL para una unidad; `--run` lo compila, repara y ejecuta | LLM (cuesta dinero); Oracle para `--run` |
| `plsql-lens testgen-setup` | Instala los objetos objetivo (Logger, HR, paquetes de test) en el esquema Oracle configurado | Oracle |
| `plsql-lens testgen-suite` | Ejecuta los tests commiteados y escribe `report.json` / `junit.xml`; `--generate` los regenera | Oracle; LLM solo con `--generate` (cuesta dinero) |
| `plsql-lens bench` | Regenera los splits del benchmark, corre las reglas antes/después, puntúa y escribe `results.md` | nada |
| `plsql-lens bench-llm` | Línea base solo-LLM sobre una muestra con semilla del split `test`, limitada con `--max-usd` | LLM (cuesta dinero) |
| `plsql-lens bench-external` | Evaluación sobre el split de autor externo: `convert`, `run`, `run-before`, `llm`, `report` | nada; `llm` cuesta dinero |

Ejecuta `uv run plsql-lens COMANDO --help` para ver todas las opciones. Los comandos que cuestan dinero lo indican en su ayuda.

## Parser e inventario (F1)

* Lexer tolerante + parser estructural de descenso recursivo (sin dependencias de parsing externas);
  nunca lanza excepción por sintaxis desconocida y reporta problemas en `FileIR.issues`.
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

* Plan y decisiones: [SPEC.md](SPEC.md). Contrato de las reglas de revisión: [docs/rules.md](docs/rules.md).
* Informes por fase: [F1](docs/reports/phase-1.md) · [F2](docs/reports/phase-2.md) · [F3](docs/reports/phase-3.md) ·
  [F4](docs/reports/phase-4.md) · [F4b](docs/reports/phase-4b.md).
* Benchmark: [metodología](docs/benchmarks/README.md) · [resultados](docs/benchmarks/results.md) ·
  [split de autor externo](docs/benchmarks/external/README.es.md) ([resultados](docs/benchmarks/external/results.md)).
* Decisiones de diseño: [ADR 0001 (parser)](docs/adr/0001-parser.md) ·
  [ADR 0002 (capa de sentencias)](docs/adr/0002-statement-layer.md).

El PL/SQL de terceros usado como entrada de pruebas está en `corpus/` y listado en [NOTICE](NOTICE).
Licencia: MIT.
