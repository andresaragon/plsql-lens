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
- **Siguiente (F4b):** convertir los casos (quitar los marcadores, escribir un manifiesto), sellarlos con un commit, correr las reglas congeladas y la línea base solo-LLM, y adjudicar uno por uno cada hallazgo en línea sin marcar, publicando los motivos. Las reglas nunca se ajustan con este split.
