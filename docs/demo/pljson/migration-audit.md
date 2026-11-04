# Sample Oracle → PostgreSQL migration audit: `pljson`

*Español: [migration-audit.es.md](migration-audit.es.md).*

This is a **sample** produced with PL/SQL Lens on public code that the tool was not developed against. It is the second sample, after
[`oos-utils`](../oos-utils/migration-audit.md), and it differs in kind: `pljson` is a JSON library built on Oracle **object types**
(`create type ... as object`, type bodies, subtypes), not only on packages. Numbers come from the tool's raw output
([`raw/`](raw/)) or from the manual review of a sample (marked as such); the blocks of numbers are generated and checked by
[`tables.py`](tables.py). Read "What this report does not cover" before drawing conclusions.

## 1. Scope

| Item | Value |
|---|---|
| Project | `pljson` (pljson/pljson), a JSON library for Oracle PL/SQL |
| URL | https://github.com/pljson/pljson |
| Commit analyzed | `09a54e4e9318af36c6d27f0e7170bd4a376276b2` (branch `develop_v3`) |
| License | MIT. The first line of the `LICENSE` file at that commit is "This software has been released under the MIT license:", followed by the copyright line (Copyright (c) 2016 Jonas Krogsboell, Lewis R Cunningham) and the standard MIT permission and warranty text, which I read in full. GitHub shows the license as undetermined because of that first line. SHA-256 of the file in [`raw/meta.txt`](raw/meta.txt) |
| Path analyzed | `src/` (the library, with `src/addons/`). Left out: `examples/`, `testsuite/` and `testsuite-utplsql/` (sample and test code, not the library), and `install.sql` / `uninstall.sql` (not analyzed) |
| Files the tool takes | Every file under `src/` has the extension `.sql`, which the tool accepts, so none was skipped; no file failed to parse (the `ok` and `issues` fields of every file in [`raw/inventory.json`](raw/inventory.json)) |
| PL/SQL Lens | version 0.1.0; last commit that changed `src/`: `558dcee3664ca4c794e723f9c1ee574350420c1e`; migration rules MIG001–MIG017 |
| Command | `bash scripts/demo_migration_audit.sh pljson` (clones at the fixed commit, runs `plsql-lens migrate` in JSON and table format and `plsql-lens inventory`, writes [`raw/`](raw/)) |

<!-- BEGIN:facts -->
| Measure | Value |
|---|---|
| PL/SQL files analyzed | 24 |
| Lines in those files | 7801 |
| Findings | 238 |
| Files with at least one finding | 15 |
| Findings by severity: `high` | 83 |
| Findings by severity: `medium` | 127 |
| Findings by severity: `low` | 28 |
<!-- END:facts -->

The third-party code is not stored in this repository, only the URL, the commit and the tool's output. The excerpts below are
limited to 5 lines each and come from `pljson` (MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham). The sources contain no e-mail
addresses (I searched `src/` by pattern), but they have comments that name developers; no excerpt reproduces them. The test data
and the examples were not analyzed or read.

## 2. Executive summary

<!-- BEGIN:headline -->
PL/SQL Lens (migration rules MIG001–MIG017) reports **238 findings in 15 of 24 files**: 83 `high`, 127 `medium`, 28 `low` (raw output).
<!-- END:headline -->

* MIG016 counts references to `DBMS_LOB` and `DBMS_SQL` (types and constants too), not routines to redesign. There is no
  `UTL_FILE` finding, and no `SYSDATE` / `SYSTIMESTAMP` finding (MIG003), so the clock-hint caveat of issue #3 does not come up here.
* **Main risks, in business terms:**
  1. *Dynamic queries built on `DBMS_SQL`.* The `high` MIG016 findings are the `DBMS_SQL` references of one add-on package that
     runs a query given as text and turns the result into JSON. PostgreSQL has no equivalent API: in my reading this is a redesign
     (section 4.1).
  2. *Empty text versus NULL.* The `high` MIG011 findings are `''` (NULL in Oracle). Most look harmless by my reading (a buffer
     starts empty and is appended to), but some decide what the JSON output contains, and the library has an option whose whole
     point is to produce an empty string, which Oracle cannot (section 4.2).
  3. *The library's own structure.* The object types, an interface-based table function and the error numbers raised with
     `RAISE_APPLICATION_ERROR` are what a migration would have to redesign or map. This version has no rule for object types and
     reports only part of this (sections 3.1, 4.3 and 4.4).
* Manual review of a sample (Claude, provisional), in the line below; a sample of this size justifies no estimate of precision on
  the other findings, and it contains false positives.

<!-- BEGIN:sample_totals -->
Reviewed sample: 27 findings, 24 real hit, 1 doubtful, 2 false positive.
<!-- END:sample_totals -->

## 3. Findings by rule and severity, and by file

Raw output: [`raw/migrate.json`](raw/migrate.json), [`raw/migrate.txt`](raw/migrate.txt).

<!-- BEGIN:by_rule -->
| Rule | Severity | Occurrences | Files |
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

The ten files with most findings (all files with findings if there are fewer):

<!-- BEGIN:by_file -->
| File | Findings |
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

MIG017 counts each pipelined function twice when it has a specification and a body; here the one finding is in a type
specification (section 4.3).

### 3.1 Object types and what the inventory shows

`plsql-lens inventory` ([`raw/inventory.json`](raw/inventory.json)) lists, for this project:

<!-- BEGIN:inventory -->
| Unit kind in the inventory | Units |
|---|---|
| `function` | 150 |
| `package` | 9 |
| `procedure` | 54 |
| `type` | 12 |
| **Total** | 225 |
<!-- END:inventory -->

The member functions and procedures of a type appear as `function` / `procedure` units; types and packages are the other kinds.
There is no separate kind for type bodies in this list. What I could and could not establish, with how:

* **Detection does not depend on the inventory.** The migration rules read the tokens of the whole file, so they report
  findings inside type bodies. For example, constructors of `pljson_string` (a file with the type and its body) have findings.
* **The inventory under-reports types when a file holds more than one.** In `src/pljson_element.type.decl.sql` the source has
  four `create type` statements (`pljson_path_segment`, `pljson_path`, `pljson_element` and `pljson_element_array`); I ran the
  parser on the file and it returns one unit, `pljson_path_segment`. `pljson_element`, the base type of the library, has no unit
  from that file.
* **When a type and its body are in the same file, the body is not a unit.** I ran the parser on the four single-file types
  (`pljson_bool`, `pljson_null`, `pljson_number`, `pljson_string`, extension `.type.sql`): each returns one `type` unit with the
  members declared in the specification, and no `type_body` unit. The same type in two files (`.type.decl.sql` and
  `.type.impl.sql`) has a `type_body` unit for the body file. Findings in the body of two of them (`pljson_number`, `pljson_string`) carry
  the type name in their `unit` field, not the member's.
* **Minimal reproduction** (two sources I wrote; run with `uv run python`, they use the library's parser only):

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

  Output when I ran it: `spec and body [('type', 't_a', ['is_a'])]` and `two types [('type', 't_one', [])]`. I did not
  investigate the cause; this is an observation of the tool, not a diagnosis, and I did not change it. I tried only these
  shapes and the files of this project.
* **The `unit` field is not used in this report** to say where a finding is (issue #4: the field can name the wrong routine).
  Locations are `file:line` in the source at the pinned commit.

## 4. Main risks

Statements about PostgreSQL are my reading of the code; **none was run on a database**. What I read: the findings of the sample in
section 5 in their context (the lines around them), the code around the lines cited below, and the one-line text of every MIG011
finding. I did not read in context the rest of the findings of any rule, and the report does not say anything about them beyond
the counts.

### 4.1 `DBMS_SQL` (MIG016, `high`) — `addons/pljson_dyn.package.sql`

```plsql
      bind_elem := bindvar.get(i);
      if (bind_elem.is_number()) then
        dbms_sql.bind_variable(l_cur, ':'||key_str, bind_elem.get_number());
```
*(`src/addons/pljson_dyn.package.sql:91-93`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **What changes:** this package takes a query as text plus bind values, runs it through the `DBMS_SQL` cursor API and returns
  the rows as JSON. PostgreSQL has no cursor-number API.
* **What to do:** decide whether the add-on is in scope. If it is, redesign it around `EXECUTE ... USING` and a way to describe
  the result columns; the work is in the design, not in the count of references. I read the binding part of the package (lines
  91–118) and not the rest.

### 4.2 `''` where Oracle means NULL (MIG011, `high`) — several files

```plsql
          if (l_val is null) then
            if (null_as_empty_string) then
              inner_obj.put(l_dtbl(i).col_name, ''); --treat as emptystring?
```
*(`src/addons/pljson_dyn.package.sql:215-217`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **What changes:** in Oracle `''` is NULL; in PostgreSQL it is an empty string. The line above shows an option that asks for an
  empty string and cannot get one in Oracle (the comment itself has a question mark); after a migration the same option would
  produce a real empty string, so the JSON would differ from what Oracle produced.
* **Reading of the others.** Many of the findings are a buffer declared as `varchar2(32767) := ''` (`pljson_printer`, `pljson_parser`,
  `pljson_xml`), the usual start of a string that is then appended to; I saw the appending in `tab()` of `pljson_printer` and did
  not read the code around the others. If that is all they do, the result is the same in both databases. Some
  are `return ''` from a function (`pljson_printer`, `pljson_ext`) and a constructor parameter with `default ''`
  (`pljson_string`): those would return or default to an empty string instead of NULL, which matters only if a caller tests
  for NULL; I did not check the callers. One is the name of a member:

  ```plsql
      if (nulljsonvalue is not null) then
        validated.put('', nulljsonvalue);
      end if;
  ```
  *(`src/pljson_parser.impl.sql:913-915`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

  A member whose name is `''` is NULL-named in Oracle and empty-named in PostgreSQL. I did not follow the code further to see what
  the library does with that member.
* **What to do:** decide for each place whether NULL or an empty string is meant, and test the JSON output of the library
  against known documents on both databases (differential tests, section 8).

### 4.3 Interface-based pipelined function (MIG017, `medium`) — `addons/pljson_table_impl.type.decl.sql`

```plsql
    table_mode varchar2 := 'cartesian'
  ) return anydataset
  pipelined using pljson_table_impl
```
*(`src/addons/pljson_table_impl.type.decl.sql:156-158`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **What changes:** this is a table function implemented through an Oracle interface: the type declares the `ODCITable...`
  methods that Oracle calls to prepare, fetch and close the rows. The hint of the tool (`RETURNS SETOF` with `RETURN NEXT`) does not
  describe this work; the interface has no PostgreSQL counterpart. I classify the finding as *doubtful* in the sample for that
  reason (the construct is there; the advice does not fit).
* **What to do:** replace the whole type by a function returning a set (its logic is the JSON-to-rows conversion), after deciding
  whether the feature is in scope.

### 4.4 Error numbers (MIG015, `medium`) — several files

```plsql
        if not starts_with(nested_path_prefix, last_nested_path_full) then
          --dbms_output.put_line('column paths are not nested, column# ' || i);
          raise_application_error(-20120, 'column paths are not nested, column# ' || i);
```
*(`src/addons/pljson_table_impl.type.impl.sql:268-270`, pljson, MIT, © 2016 Jonas Krogsboell, Lewis R Cunningham)*

* **What changes:** the library signals errors with `RAISE_APPLICATION_ERROR` and numbers in the -20000 range (I saw -20110 and
  -20120 in the sample). `RAISE EXCEPTION ... USING ERRCODE` ports the call; code that tests the number does not carry over by
  itself.
* **What to do:** list the numbers the library raises, map them to codes, and check the callers that handle them (the test suites
  of the project would be the place to look; they were not read here).

## 5. Manual review of a sample

**Method.** The sample is stratified by rule: the first 4 findings of each rule that has findings, ordered by file path, line and
column (all of them when a rule has fewer than 4). It is reproducible, and it is **not random**: it favors the files that sort
first alphabetically (here the add-ons come before the files in `src/`). **The verdicts are a review by Claude, provisional, on a
small sample;** they are not tool output and nobody else has checked them. I read each finding in the source at the pinned commit,
with the lines around it.

*Real hit*: the token is the Oracle construct the rule names and its message fits this use. *Doubtful*: the construct is there but
I could not show that it changes behavior here, or the advice or severity does not fit. *False positive*: the token is something
else.

<!-- BEGIN:sample_totals -->
Reviewed sample: 27 findings, 24 real hit, 1 doubtful, 2 false positive.
<!-- END:sample_totals -->

<!-- BEGIN:sample -->
| # | Rule | Severity | Location | Verdict | Reason |
|---|---|---|---|---|---|
| 1 | MIG001 | low | `src/addons/pljson_table_impl.type.impl.sql:274` | real hit | NVL(length(...), 0) inside substr(): a mechanical COALESCE. |
| 2 | MIG001 | low | `src/addons/pljson_table_impl.type.impl.sql:291` | real hit | Same pattern as the previous row (NVL around length()). |
| 3 | MIG001 | low | `src/addons/pljson_xml.package.sql:141` | real hit | NVL(tagname, 'array') as an argument: a mechanical COALESCE. |
| 4 | MIG001 | low | `src/pljson_number.type.sql:47` | real hit | NVL(num, 0) in a type constructor: a mechanical COALESCE. |
| 5 | MIG002 | low | `src/pljson_ext.decl.sql:108` | false positive | This is the declaration of the package's own function named decode (function decode(v pljson_string) return blob), not a call to Oracle DECODE. The contract says the rules have no semantics. |
| 6 | MIG002 | low | `src/pljson_ext.impl.sql:1017` | false positive | The body of the same user-defined function decode; same remark as the previous row. |
| 7 | MIG006 | medium | `src/pljson_parser.impl.sql:45` | real hit | CONNECT BY LEVEL <= n used as a row generator over dual to split a string into characters; PostgreSQL needs generate_series() or a recursive query (my reading). |
| 8 | MIG009 | low | `src/addons/pljson_dyn.package.sql:197` | real hit | dbms_output.put_line of an 'unhandled col_type' message; RAISE NOTICE, mechanical. |
| 9 | MIG009 | low | `src/addons/pljson_dyn.package.sql:371` | real hit | Same message in a second routine of the same package; mechanical. |
| 10 | MIG009 | low | `src/addons/pljson_object_cache.impl.sql:42` | real hit | First of several dbms_output.put_line calls of a statistics-printing procedure; RAISE NOTICE, mechanical. |
| 11 | MIG009 | low | `src/addons/pljson_object_cache.impl.sql:43` | real hit | Next line of the same procedure; same remark. |
| 12 | MIG010 | low | `src/addons/pljson_util_pkg.package.sql:325` | real hit | FROM DUAL in a query that also calls the XMLType methods transform() and getclobval(); dropping FROM is trivial, the XML methods need their own rewrite and are not reported. |
| 13 | MIG010 | low | `src/pljson_parser.impl.sql:44` | real hit | FROM DUAL in the same statement as the CONNECT BY of the MIG006 row above. |
| 14 | MIG011 | high | `src/addons/pljson_dyn.package.sql:102` | real hit | '' assigned to an element of a table of strings that is later bound with dbms_sql.bind_array for a JSON null: Oracle binds NULL, PostgreSQL would bind an empty string (my reading of the semantics, not run). |
| 15 | MIG011 | high | `src/addons/pljson_dyn.package.sql:118` | real hit | '' passed as a bind value for a JSON null: NULL in Oracle, an empty string in PostgreSQL. |
| 16 | MIG011 | high | `src/addons/pljson_dyn.package.sql:217` | real hit | The code asks for an empty string when a column is null (the comment itself says 'treat as emptystring?'), but in Oracle '' is NULL; in PostgreSQL the option would produce a real empty string, so the output differs from what Oracle produced. |
| 17 | MIG011 | high | `src/addons/pljson_dyn.package.sql:261` | real hit | Same pattern for a CLOB column of length 0. |
| 18 | MIG012 | medium | `src/pljson_parser.impl.sql:43` | real hit | SELECT ... BULK COLLECT INTO s.src_array over a CONNECT BY row generator: PostgreSQL needs array_agg() or a loop. |
| 19 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:270` | real hit | Call with the error number -20120 and a message; RAISE EXCEPTION ... USING ERRCODE ports the call, callers that test the number need a mapping. |
| 20 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:277` | real hit | Same error number in a second branch of the same method. |
| 21 | MIG015 | medium | `src/addons/pljson_table_impl.type.impl.sql:389` | real hit | Same error number again, in the fetch path of the table-function type. |
| 22 | MIG015 | medium | `src/pljson.type.impl.sql:517` | real hit | Error -20110 raised from the pljson object type; same remark. |
| 23 | MIG016 | high | `src/addons/pljson_dyn.package.sql:93` | real hit | dbms_sql.bind_variable inside a dynamic-query runner: DBMS_SQL has no PostgreSQL equivalent, redesign with EXECUTE ... USING. |
| 24 | MIG016 | high | `src/addons/pljson_dyn.package.sql:96` | real hit | A variable declared with the type dbms_sql.varchar2_table: the rule counts the type reference. |
| 25 | MIG016 | high | `src/addons/pljson_dyn.package.sql:107` | real hit | dbms_sql.bind_array with the array above; same redesign. |
| 26 | MIG016 | high | `src/addons/pljson_dyn.package.sql:115` | real hit | dbms_sql.bind_variable with a date; same redesign. |
| 27 | MIG017 | medium | `src/addons/pljson_table_impl.type.decl.sql:158` | doubtful | 'pipelined using pljson_table_impl' is an interface-based table function (the type implements the ODCITable methods). The construct is there, but the hint (RETURNS SETOF with RETURN NEXT) does not describe the work: the interface has no PostgreSQL counterpart, so it is a redesign. |
<!-- END:sample -->

The data is in [`review.json`](review.json); [`tables.py`](tables.py) fails if it does not match the selection above. The two
false positives are the two MIG002 findings of the project, on a function that the library itself defines with the name `decode`:
the rules match tokens and have no semantics (the contract says so). The sample contains every MIG002 finding; for the other
rules it says nothing beyond its own rows.

## 6. Comparison with `oos-utils`

Occurrences per rule in the two samples (same tool version, MIG001–MIG017, raw output of each project). MIG016 counts references
and MIG017 counts specification and body separately; the counts are not comparable as amounts of work.

<!-- BEGIN:compare -->
| Rule | oos-utils | pljson |
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

Two projects are not a sample of the Oracle world, and nothing here supports a conclusion about how common any construct is.

## 7. What this report does not cover

* **Object types.** The tool has no rule for `create type ... as object`, `member` / `constructor` / `overriding` methods,
  `under` (subtypes), `self`, or the `ODCITable` interface; and the inventory has the limits of section 3.1. Whatever a migration
  of the types takes (composite types plus functions, no methods or inheritance in PostgreSQL, in my reading) is not measured.
* **Other Oracle-only elements that no rule covers, seen while reading:** the `IS OF (type)` test, collection types such as
  `pljson_varray`, `anydataset`, XMLType methods (`transform`, `getclobval`) and `CONNECT BY LEVEL` used as a row generator
  (the last one is reported by MIG006 but its replacement needs a design).
* **The out-of-scope list of the contract** ([`docs/migration-rules.md`](../../migration-rules.md)): data types, package state
  (package-level variables and initialization), DDL, and rewriting code. The tool reports; it does not convert.
* **Dynamic SQL.** Text inside string literals is opaque to every rule: an Oracle construct in a string is never reported.
* **Data types.** `NUMBER`, `VARCHAR2`, `DATE`, `RAW`, LOBs, `CLOB` handling and the rest of the type mapping are not examined.
  A JSON library moves a lot of text and numbers; their conversion rules are outside this report.
* **Performance.** Nothing here says how the code would perform in PostgreSQL.
* **Equivalence with real data.** No test compared results on Oracle and PostgreSQL for this code. Every statement about
  PostgreSQL behavior is a reading of the code.
* **False negatives.** The rules match tokens, without semantics (sections 5 and above): a construct hidden in a string, or
  written in a way the contract does not list, is missed, and a user-defined function with the name of an Oracle one is flagged.
  The precision above is about what was reported; nothing is known about what was not.
* **The tool's own limits.** The `unit` field of some findings can be wrong (issue #4), and the inventory under-reports types
  (section 3.1). This report uses neither to locate findings.
* **A single project, a single commit.** Nothing here generalizes to other code bases.

## 8. What a full audit would look like

1. **Inventory.** Units, subprograms, parameters and the call graph (`plsql-lens inventory`), checked against a direct reading
   for the shapes the tool under-reports (object types in particular), plus a list of the Oracle features each unit depends on
   beyond what the rules cover.
2. **Findings.** The migration rules on the whole code base, with the newest rule set, and a list of constructs that no rule
   covers, built by reading.
3. **Human review.** A person with Oracle and PostgreSQL experience reviews the findings and the code around them, decides what
   is rewritten, replaced or redesigned, and records each decision.
4. **Differential tests.** Selected routines run on Oracle and on PostgreSQL with the same inputs, and their results are
   compared, with the differences classified. This is the only step that gives evidence of equivalent behavior.
5. **Report.** Findings, decisions and test results, and what remains unverified.

## 9. How to reproduce

```bash
bash scripts/demo_migration_audit.sh pljson          # clone at the fixed commit, run the tool, write docs/demo/pljson/raw/
uv run python docs/demo/pljson/tables.py             # check that the numbers of both reports match raw/ and review.json
```

Needs `git`, `uv` and network access to github.com. The same commit gives the same findings.
