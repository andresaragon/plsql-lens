# PL/SQL Lens

Librería Python + CLI que analiza paquetes Oracle PL/SQL. Estado: **Fase F1 (parser e inventario)**
implementada; reglas de revisión, generación de utPLSQL y benchmark están planificados (ver [SPEC.md](SPEC.md)).

## Inicio rápido

```bash
uv sync
uv run plsql-lens inventory corpus/ --format json -o inventory.json
uv run plsql-lens inventory corpus/ --format mermaid -o callgraph.mmd   # --level unit para subprogramas
uv run pytest            # tests unitarios y de aceptación, sin red ni Docker
make demo-f1             # regenera docs/reports/phase-1/
```

```python
from plsql_lens import parse_file, build_inventory

ir = parse_file("corpus/logger/logger.pkb")  # IR: unidades, subprogramas, parámetros, llamadas
inv = build_inventory(["corpus/logger"])  # unidades + aristas de llamada resueltas
```

## Qué hace F1

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

El PL/SQL de terceros usado como entrada de pruebas está en `corpus/` y listado en [NOTICE](NOTICE).
Licencia: MIT.
