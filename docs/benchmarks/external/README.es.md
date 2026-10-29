# Split de casos de modelo externo (variante F4b) — Gemini vía Antigravity

Este split de benchmark rompe el efecto techo observado en el split sembrado original, en el cual los casos fueron generados por subagentes Claude a partir del mismo contrato de reglas.

## Avisos clave y reglas de integridad
1. **No escrito por humanos (not human-written)**: Este conjunto fue generado por un modelo de lenguaje externo (`gemini-3.8-flash-high` vía Antigravity / `agy`). No es un split escrito por una persona. El split humano (`docs/benchmarks/human/`) sigue pendiente y reservado para cuando Santiago escriba los casos.
2. **No se ejecutó PL/SQL Lens (plsql-lens was not run)**: Durante la redacción de los casos, `plsql-lens was not run` (ni `review` ni `bench` ni analizadores estáticos de PL/SQL). El autor no tuvo acceso a la implementación interna ni ejecutó el motor sobre los casos. Solo se ejecutó la prueba de aceptación estructural (`test_external_split.py`).
3. **Escrito desde cero en dominios neutros**: Todos los casos se escribieron desde cero en dominios comerciales estándar y neutrales (`library loans`, `retail store`, `payroll`, `ticketing`, `inventory`, `hotel booking`, `school grades`, `clinic appointments`, `car rental`, `logistics tracking`, `gym memberships`, `restaurant orders`, `airline baggage`, `parking permits`). No contiene secretos, datos reales ni código de empleadores o clientes.

## Estructura y cantidades
- Total de casos: 40 archivos contiguos (`e001.pkb` a `e040.pkb`), con longitudes entre 20 y 120 líneas (con casos profundos e036–e040 de 60–120 líneas).
- Dificultades: 11 fáciles (easy), 17 medias (medium), 12 difíciles (hard).
- Marcadores empleados:
  - `-- expect: PLL00n`: Defecto cubierto por el contrato en la línea exacta.
  - `-- clean: PLL00n`: Negativo difícil (patrón que parece defecto pero es correcto).
  - `-- beyond: PLL00n`: Defecto real de la misma familia no cubierto por la regla determinista.
- Cantidades de marcadores:
  - Al menos 8 marcadores `expect` y 8 marcadores `clean` por cada regla (PLL001 a PLL007).
  - 9 marcadores `beyond` en total.
  - Marcadores `expect: PLL007` agrupados en al menos 3 ocurrencias por archivo.

## Procedencia y revisión (añadido al entrar el split en `main`)
- **Autor:** `gemini-3.8-flash-high` a través de Antigravity. **Revisor:** Claude, como checker del flujo `/delegar`, leyó cada caso contra [`docs/rules.md`](../../rules.md) antes de que el split se commiteara. No existía ninguna salida del motor de reglas y no se compartió ninguna con el autor.
- **El revisor corrigió siete marcadores** tras las entregas del autor, siempre contra el texto del contrato: `e018` y `e022` (`beyond` → `expect`: la exención de agregados de PLL004 no aplica con `GROUP BY`/`HAVING`; un parámetro `DATE` comparado con un literal de texto lo cubre PLL006(b)), `e026` (se quitó un `beyond` sobre código correcto), `e037` (un `SELECT … INTO` envuelto por `WHEN OTHERS` cuenta como manejado para PLL004 → `clean`; el handler `OTHERS` que solo asigna una variable recibió `expect: PLL001`) y `e038` (faltaba `expect: PLL005` por el DML en un bucle con `FETCH` y `expect: PLL001` por un handler `OTHERS` que solo hace `rollback to` un savepoint).
- **Qué significa:** los marcadores finales son de un split escrito por Gemini cuya verdad base revisó un modelo Claude leyendo el mismo contrato que implementan las reglas. Da consistencia, pero **no es independiente de la lectura que hace Claude del contrato**, y la línea base solo-LLM también es un modelo Claude. Este split es una comprobación con otro autor, no un estándar de oro humano.
- **Límites conocidos:** 35 de los 40 casos son cortos (21–35 líneas) y siguen la forma de manual «defecto + negativo sencillo»; solo `e036`–`e040` son largos. Es probable que las notas en este split sean altas. Hay solo 9 marcadores `beyond`, así que el «recall en el mundo real» se apoyará en una muestra pequeña. Los casos no se compilaron y ninguna persona senior de PL/SQL los ha revisado.
- **Hecho (F4b):** la evaluación se ejecutó y se publicó; ver «Evaluación (F4b)» abajo.

## Evaluación (F4b) — qué se ejecutó y en qué orden
Resultados: [results.md](results.md) · crudos: [raw/engine.json](raw/engine.json), [raw/engine_before.json](raw/engine_before.json),
[llm_baseline/responses.json](llm_baseline/responses.json) · adjudicación: [adjudication/](adjudication/).
Se reproduce con `plsql-lens bench-external convert|run|run-before|llm|report`.

1. **Reglas de referencia congeladas** (`frozen.json`, commit `6c2982c`; parser, reglas y `docs/rules.md` con hash y una prueba unitaria).
2. **Conversor y evaluador**, escritos y probados solo con datos sintéticos.
3. **Commit-sello** `d2755f2`: 40 casos (64 `expect`, 60 `clean`, 9 `beyond`; marcadores y cabecera descriptiva fuera, mismas líneas),
   SHA-256 del manifiesto `5f1e1eeef047026120541f8973d6fc02e31a84e4e0a9772f1c4fca12d167f11f` en `../seal.json`.
4. **Motor congelado, una sola vez** (`bench-external run` rechaza una segunda ejecución sin `--force`).
5. **Reglas «before», una sola vez** (`bench-external run-before`): el `BEFORE_SHA` de F4 (`67afb85`, exportado de git) sobre los mismos
   casos sellados, con la misma regla de «una vez». Sin LLM y sin costo; solo mide qué hizo el ajuste de F4 sobre `dev` en un split que nunca vio.
6. **Línea base solo-LLM** (`claude-sonnet-5-5`, contrato de `docs/rules.md`, sin motor): 40 archivos, 0,596 USD.
7. **Dos tablas.** *Estricta*: todo hallazgo en una línea sin marcador es falso positivo. *Adjudicada*: cada hallazgo sin marcar se leyó en el caso original
   contra el contrato y se decidió uno por uno (`adjudication/*.json`, con motivos); es **provisional (Claude), pendiente de revisión del propietario**.

| Método | Estricto TP/FP/FN | Adjudicado (provisional) |
|---|---|---|
| Reglas «before» (`67afb85`) | 64 / 3 / 0 | 65 / 2 / 0 |
| Reglas congeladas (`6c2982c`) | 64 / 2 / 0 | 65 / 1 / 0 |
| Solo LLM | 64 / 2 / 0 | 65 / 1 / 0 |

* La única diferencia entre «before» y las congeladas es `e012:22` PLL004 (`select nvl(max(price), 0) into …`, una trampa `clean`): el contrato exime
  los agregados dentro de expresiones y el código «before» solo los buscaba a profundidad 0; el ajuste de F4 sobre `dev` lo corrigió. Un caso ilustra, no es estadística.
* `beyond` (defectos reales fuera del contrato): 0 de 9 para los tres. Es esperable: las reglas implementan el contrato y al LLM también se le dio.
* Límites: 40 casos cortos, un autor no humano revisado por Claude, verdad base no independiente de la lectura de Claude del contrato, sin revisor senior.
  Notas casi perfectas indican que el split es fácil para un verificador literal del contrato, no que las reglas sean buenas en código de producción.
  El split escrito por una persona (`../human/`) sigue pendiente.
