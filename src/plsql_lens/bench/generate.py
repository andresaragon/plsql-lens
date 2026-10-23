"""Seeded, deterministic generation of benchmark items from templates.

Two kinds of items: small standalone packages made of snippets, and copies of real corpus package
bodies with snippets inserted before the closing ``END``. Every snippet is a *region* in the manifest;
the expected finding lines come from the ``-- @expect`` markers of its template (stripped from the
emitted source).
"""

from __future__ import annotations

import hashlib
import json
import random
import re
from dataclasses import dataclass
from pathlib import Path

from .model import RULE_IDS, Manifest, Region

TEMPLATES_ROOT = Path(__file__).parent / "templates"
_MARKER = re.compile(r"[ \t]*--[ \t]*@expect\b.*$")
_TOKEN = re.compile(r"@@(\w+)@@")

_VERBS = ["load", "sync", "audit", "purge", "calc", "check", "apply", "build", "close", "refresh",
          "archive", "scan", "merge", "verify", "collect", "rebuild"]  # fmt: skip
_NOUNS = ["orders", "stock", "invoices", "ledger", "users", "batches", "events", "rates", "claims",
          "tasks", "payments", "shipments", "tickets", "accounts", "reports", "quotas"]  # fmt: skip
_COLS = ["status", "amount", "qty", "code", "label", "created_on", "owner_id", "priority", "region",
         "balance", "kind", "ref_no"]  # fmt: skip
_WORDS = ["amber", "birch", "cobalt", "delta", "ember", "fjord", "garnet", "harbor", "indigo", "juniper",
          "kestrel", "lagoon", "maple", "nectar", "onyx", "pebble", "quartz", "raven", "sable", "tundra"]  # fmt: skip


@dataclass(frozen=True)
class Snippet:
    rule: str
    kind: str
    template: str
    code: str  # markers stripped
    expected: tuple[int, ...]  # 1-based line offsets inside ``code``


def load_templates(templates_dir: Path) -> dict[str, dict[str, list[dict[str, str]]]]:
    """Templates per rule; ``PLL001.json`` plus any ``PLL001.<extra>.json`` (e.g. ``.hard``) are merged."""
    out: dict[str, dict[str, list[dict[str, str]]]] = {}
    for rule in RULE_IDS:
        paths = sorted(templates_dir.glob(f"{rule}.json")) + sorted(
            templates_dir.glob(f"{rule}.*.json")
        )
        for p in paths:
            d = json.loads(p.read_text())
            e = out.setdefault(rule, {"defects": [], "negatives": []})
            e["defects"].extend(d["defects"])
            e["negatives"].extend(d["negatives"])
    return out


class _Namer:
    """Unique-per-split random names and literals."""

    def __init__(self, rng: random.Random) -> None:
        self.rng = rng
        self.used_nums: set[int] = set()
        self.counter = 0

    def values(self) -> dict[str, str]:
        r = self.rng
        self.counter += 1
        c = self.counter
        pick = r.choice
        nums: list[str] = []
        while len(nums) < 2:
            n = r.randint(1000, 99999)
            if n not in self.used_nums:
                self.used_nums.add(n)
                nums.append(str(n))
        v: dict[str, str] = {
            "proc": f"{pick(_VERBS)}_{pick(_NOUNS)}_{c:04d}",
            "proc2": f"{pick(_VERBS)}_{pick(_NOUNS)}_{c:04d}b",
            "tab": f"bm_{pick(_NOUNS)}_{c:04d}",
            "tab2": f"bm_{pick(_NOUNS)}_{c:04d}b",
            "col": pick(_COLS),
            "col2": pick(_COLS) + "_2",
            "var": f"l_{pick(_WORDS)}_{c:04d}",
            "var2": f"l_{pick(_WORDS)}_{c:04d}b",
            "var3": f"l_{pick(_WORDS)}_{c:04d}c",
            "num": nums[0],
            "num2": nums[1],
            "str": f"{pick(_WORDS)}_{r.randint(100, 999)}",
            "str2": f"{pick(_WORDS)}_{r.randint(100, 999)}",
        }
        return v


_LIT = re.compile(
    r"""(?P<cmt>--[^\n]*|/\*.*?\*/)
      | (?P<qstr>[nN]?[qQ]'(?:\[.*?\]|\{.*?\}|\(.*?\)|<.*?>)')
      | (?P<str>'(?:[^']|'')*')
      | (?P<qid>"[^"\n]*")
      | (?P<num>(?<![\w@$#.])\d+(?:\.\d+)?(?![\w@$#]))""",
    re.VERBOSE | re.DOTALL,
)
_SIZED = re.compile(r"(?i)\b(?:varchar2|nvarchar2|char|nchar|raw|number|float|timestamp)\s*\($")


def _uniquify_literals(raw: str, rng: random.Random, taken: set[int]) -> str:
    """Give the non-designed literals of a PLL007 template instance values that occur nowhere else.

    PLL007 counts repeats per unit, so a snippet that uses ``2``/``'unknown'`` incidentally would join
    the same literal of other snippets and create findings the template never labeled. Designed
    literals (``@@num@@``/``@@str@@`` placeholders) are left alone; multiplicity inside the snippet is
    preserved because equal literals map to the same new value. 0 and 1, empty and single
    non-alphanumeric strings (exempt by the contract), type sizes and ORA-20xxx codes are kept.
    """
    mapping: dict[str, str] = {}

    def new_num() -> str:
        while True:
            n = rng.randint(100000, 999999)
            if n not in taken:
                taken.add(n)
                return str(n)

    def repl(m: re.Match[str]) -> str:
        text = m.group(0)
        if m.lastgroup in ("cmt", "qid") or "@@" in text:
            return text
        if m.lastgroup == "num":
            if text in mapping:
                return mapping[text]
            if float(text) in (0.0, 1.0) or 20000 <= float(text) <= 20999:
                return text
            if _SIZED.search(raw[: m.start()]):
                return text
            mapping[text] = new_num()
            return mapping[text]
        inner = text[text.index("'") + 1 : -1]
        if inner == "" or (len(inner) == 1 and not inner.isalnum()):
            return text
        if text not in mapping:
            suffix = f"_{rng.randint(100000, 999999)}"
            if m.lastgroup == "qstr":
                mapping[text] = text[:-2] + suffix + text[-2:]
            else:
                mapping[text] = text[:-1] + suffix + "'"
        return mapping[text]

    return _LIT.sub(repl, raw)


def _instantiate(raw: str, values: dict[str, str]) -> tuple[str, tuple[int, ...]]:
    def sub(m: re.Match[str]) -> str:
        try:
            return values[m.group(1)]
        except KeyError:
            raise ValueError(f"unknown placeholder @@{m.group(1)}@@") from None

    lines, expected = [], []
    for i, line in enumerate(raw.split("\n"), 1):
        if _MARKER.search(line):
            expected.append(i)
            line = _MARKER.sub("", line)
        lines.append(_TOKEN.sub(sub, line.rstrip()))
    return "\n".join(lines), tuple(expected)


def _snippets(
    tpl: dict[str, dict[str, list[dict[str, str]]]], rng: random.Random, namer: _Namer,
    defects: int, negatives: int,
) -> list[Snippet]:  # fmt: skip
    out: list[Snippet] = []
    for rule in sorted(tpl):
        for kind, key, n in (("defect", "defects", defects), ("negative", "negatives", negatives)):
            variants = tpl[rule][key]
            order: list[int] = []
            while len(order) < n:  # balanced coverage of variants, shuffled per round
                round_ = list(range(len(variants)))
                rng.shuffle(round_)
                order.extend(round_)
            for idx in order[:n]:
                v = variants[idx]
                raw = v["code"]
                if rule == "PLL007":
                    raw = _uniquify_literals(raw, rng, namer.used_nums)
                code, expected = _instantiate(raw, namer.values())
                if kind == "defect" and not expected:
                    raise ValueError(f"{rule}/{v['id']}: defect template without @expect marker")
                if kind == "negative" and expected:
                    raise ValueError(f"{rule}/{v['id']}: negative template with @expect marker")
                out.append(Snippet(rule, kind, v["id"], code, expected))
    return out


def _chunks(items: list[Snippet], size: int) -> list[list[Snippet]]:
    return [items[i : i + size] for i in range(0, len(items), size)]


def _assemble(snips: list[Snippet], first_line: int, file: str) -> tuple[str, list[Region]]:
    """Join snippets with a blank line; return text and regions (line numbers start at first_line)."""
    lines: list[str] = []
    regions: list[Region] = []
    for s in snips:
        start = first_line + len(lines)
        body = s.code.split("\n")
        lines.extend(body)
        end = first_line + len(lines) - 1
        regions.append(Region(file, s.rule, s.kind, start, end,
                              tuple(start + e - 1 for e in s.expected), s.template))  # fmt: skip
        lines.append("")
    return "\n".join(lines), regions


def _inject(base_text: str, snips: list[Snippet], file: str) -> tuple[str, list[Region]]:
    m = re.search(r"package\s+body\s+([A-Za-z_][\w$#]*)", base_text, re.IGNORECASE)
    if m is None:
        raise ValueError(f"{file}: not a package body")
    lines = base_text.replace("\r\n", "\n").split("\n")
    # the package's own closing END is the last non-blank line before the trailing "/"
    idx = None
    for i in range(len(lines) - 1, -1, -1):
        stripped = lines[i].strip()
        if not stripped or stripped == "/":
            continue
        if re.match(r"(?i)end\b[^;]*;$", stripped):
            idx = i
        break
    if idx is None:
        raise ValueError(f"{file}: no closing END for package body {m.group(1)}")
    block, regions = _assemble(snips, idx + 2, file)  # +1 for 1-based, +1 for the blank line
    out = lines[:idx] + [""] + block.split("\n")[:-1] + lines[idx:]
    return "\n".join(out), regions


def manifest_hash(m: Manifest) -> str:
    canon = json.dumps(m.to_dict(), sort_keys=True, separators=(",", ":"))
    return hashlib.sha256(canon.encode()).hexdigest()


def generate(
    split: str,
    seed: int,
    out_dir: Path,
    templates_dir: Path | None = None,
    base_files: list[Path] | None = None,
    defects_per_rule: int = 50,
    negatives_per_rule: int = 50,
    snippets_per_file: int = 5,
    injected_snippets_per_file: int = 10,
    base_root: Path | None = None,
) -> Manifest:
    """Write the items of one split under ``out_dir`` and return (and save) its manifest."""
    tpl = load_templates(templates_dir or TEMPLATES_ROOT / split)
    if not tpl:
        raise ValueError("no templates found")
    rng = random.Random(seed)
    snippets = _snippets(tpl, rng, _Namer(rng), defects_per_rule, negatives_per_rule)
    rng.shuffle(snippets)
    # alternate instances between the two item kinds, per rule and kind, so both are balanced
    seen: dict[tuple[str, str], int] = {}
    stand: list[Snippet] = []
    inj: list[Snippet] = []
    for s in snippets:
        k = (s.rule, s.kind)
        seen[k] = seen.get(k, 0) + 1
        (stand if seen[k] % 2 else inj).append(s)
    if not base_files:
        inj_to_stand, inj = inj, []
        stand.extend(inj_to_stand)
    out_dir.mkdir(parents=True, exist_ok=True)
    files: dict[str, str] = {}
    bases: dict[str, str] = {}
    regions: list[Region] = []
    texts: dict[str, str] = {}
    for n, chunk in enumerate(_chunks(stand, snippets_per_file), 1):
        name = f"bench_s{n:04d}"
        rel = f"standalone/{name}.pkb"
        head = f"create or replace package {name} as\n  -- generated benchmark package\nend {name};\n/\n\n"
        body_head = f"create or replace package body {name} as\n\n"
        text_body, regs = _assemble(chunk, 1, rel)  # provisional, re-based below
        prefix = head + body_head
        offset = prefix.count("\n")
        text_body, regs = _assemble(chunk, offset + 1, rel)
        texts[rel] = prefix + text_body + f"\nend {name};\n/\n"
        files[rel] = "standalone"
        regions.extend(regs)
    bases_sorted = sorted(base_files or [])
    for n, chunk in enumerate(_chunks(inj, injected_snippets_per_file), 1):
        base = bases_sorted[(n - 1) % len(bases_sorted)]
        rel = f"injected/{base.stem}_{n:03d}{base.suffix}"
        text, regs = _inject(base.read_text(encoding="utf-8", errors="replace"), chunk, rel)
        texts[rel] = text
        files[rel] = "injected"
        bases[rel] = (base.relative_to(base_root) if base_root else Path(base.name)).as_posix()
        regions.extend(regs)
    sha: dict[str, str] = {}
    for rel, text in texts.items():
        p = out_dir / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        data = (text.rstrip("\n") + "\n").encode()
        p.write_bytes(data)
        sha[rel] = hashlib.sha256(data).hexdigest()
    m = Manifest(split, seed, files, regions, sha, bases)
    (out_dir / "manifest.json").write_text(json.dumps(m.to_dict(), indent=1, sort_keys=True) + "\n")
    return m
