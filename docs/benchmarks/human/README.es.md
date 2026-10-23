# Split escrito a mano (F4b) — guía para el autor

El split sembrado `test` mostró un efecto techo: las reglas y la línea base solo-LLM sacaron casi la nota
perfecta, porque los defectos los escribió un LLM a partir del mismo contrato (`docs/rules.md`). Este split
rompe ese círculo. Cada caso lo escribe a mano un desarrollador senior de PL/SQL, desde cero, sin pasar
PL/SQL Lens sobre él antes.

## Reglas para el autor
1. **Escribir desde cero.** No copiar, parafrasear ni reconstruir código, esquemas, nombres de tablas ni
   reglas de negocio de ningún empleador o cliente. Usar dominios neutros (biblioteca, tienda, nómina,
   tiquetes, inventario…).
2. **No correr `plsql-lens` sobre un caso antes de commitearlo.** El motor de reglas ve cada caso por
   primera vez durante la adjudicación (ver abajo).
3. Un archivo por caso, de 20 a 120 líneas, con PL/SQL verosímil. No tiene que compilar, pero un revisor
   tiene que creer que viene de un código real.
4. Sin secretos, nombres reales ni datos reales.

## Marcadores
Van como **comentario al final de la línea exacta** que indica la columna *Location* de `docs/rules.md`
(por ejemplo, la línea del `WHEN OTHERS` en PLL001 o la del `COMMIT` en PLL003).

| Marcador | Significado | Cuenta para |
|---|---|---|
| `-- expect: PLL00n` | Un defecto que el contrato de la regla cubre. La regla debería dispararse en esta línea. | recall y precisión (tabla principal) |
| `-- beyond: PLL00n` | Un defecto real de la misma familia que el contrato no cubre (por ejemplo, un `COMMIT` dentro de un procedimiento que llama un bucle). | «recall en el mundo real», reportado aparte |
| `-- clean: PLL00n` | Un negativo difícil: código que parece el defecto pero es correcto. La regla no debe dispararse en todo el subprograma que lo contiene. | falsos positivos |

Varios marcadores pueden ir en la misma línea: `-- expect: PLL002 expect: PLL007`. Se permite texto libre
después de un marcador (`-- beyond: PLL003 (renew_one commits)`).
Lo que no esté marcado se da por limpio. Un hallazgo en una línea sin marcar cuenta como falso positivo,
así que hay que marcar **todos** los defectos que conozcas, incluso los incidentales.

## Encabezado (primeras líneas de cada archivo)
```sql
-- case: h001
-- domain: library loans
-- difficulty: easy | medium | hard
-- note: una línea sobre qué hace realista o difícil este caso
```

## Qué hace un buen caso
- Patrones que has visto en revisiones de código reales, escritos en otro dominio: defectos escondidos en
  procedimientos largos, bloques anidados, handlers en un alcance exterior, SQL dinámico armado en varios
  pasos, cursores con `FETCH` manual.
- Negativos difíciles que un patrón ingenuo marcaría: binds que parecen concatenación,
  `ROLLBACK TO savepoint` dentro de un bucle, `SELECT INTO` protegido por un handler exterior, `FORALL`
  con DML, un `TO_DATE` con la máscara en la línea siguiente.
- Mezcla de dificultades. Ni solo casos que las reglas van a atrapar seguro, ni solo trampas.

## Tamaño objetivo
Al menos **5 marcadores `expect` y 5 `clean` por regla** (70 y 70), más los `beyond` que salgan de forma
natural, repartidos en 30–40 archivos. PLL007 (literales repetidos) solo necesita el mínimo.

## Flujo
1. Escribe los casos en `docs/benchmarks/human/cases/` (`h001.pkb`, `h002.pkb`, …). `_TEMPLATE.pkb` es
   un ejemplo y no se puntúa.
2. Commitéalos. Ese commit es el sello: su SHA va a `docs/benchmarks/seal.json`.
3. Un conversor (se construye en F4b) quita los marcadores, escribe los archivos limpios y un manifiesto
   con el mismo formato de los splits sembrados, y corre las reglas «después» congeladas y la línea base
   solo-LLM.
4. **Adjudicación:** se listan todos los hallazgos en líneas sin marcar. El autor decide uno por uno si es
   un defecto real que se le pasó (agrega el marcador y se registra el cambio) o un falso positivo (se
   deja). Cada decisión se publica con su motivo. Las reglas nunca se ajustan con este split.
