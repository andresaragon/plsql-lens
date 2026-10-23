# Actionable-rate rubric

The question per finding: **would a maintainer reading this finding at this line plausibly change the code
(or add an explicit suppression with a reason) because of it?**

* **Actionable (yes)** — the contract in `docs/rules.md` holds *and* the code is a plausible defect or
  smell: errors swallowed where the caller needs to know, SQL text built from parameters or configuration
  values, per-row transaction control in a loop that is not a deliberate batch commit, a single-row
  `SELECT INTO` that can really return zero/many rows, DML per fetched row that could be set-based, a
  conversion that can really fail or depend on NLS, a literal repeated enough that a named constant helps.
* **Not actionable (no)** — either (a) the contract does not hold (a false positive), or (b) it holds but
  the code is deliberate and harmless: a probe idiom (`WHEN OTHERS THEN RETURN FALSE` in an `is_number`
  check), identifiers/fragments produced by the program itself rather than by input, a batch commit every N
  rows, a comparison whose text operand is known to be numeric, separators/log tags/keywords repeated.
* When in doubt after reading the whole subprogram, answer **no**.

The labels in `labels.json` were produced by the working session (a Sonnet subagent following this rubric,
reading only the code, and spot-checked by the lead), not by the code's maintainers. The sample is seeded
(`scripts/sample_actionable.py`, seed 4004, at most 15 findings per rule, current rules, real corpus without
the held-out reserve).
