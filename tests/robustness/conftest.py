"""Keep the robustness suite out of the default run without touching ``pyproject.toml``.

``addopts`` carries ``-m 'not integration'`` and the last ``-m`` wins, so these tests only run when
asked for: ``uv run pytest tests/robustness -m robustness``.
"""

from __future__ import annotations

from pathlib import Path

import pytest

HERE = Path(__file__).resolve().parent


def pytest_configure(config: pytest.Config) -> None:
    config.addinivalue_line(
        "markers", "robustness: parser fuzzing with seeded mutations (run with -m robustness)"
    )


def _requested(markexpr: str) -> bool:
    words = markexpr.replace("(", " ").replace(")", " ").split()
    return any(w == "robustness" and (i == 0 or words[i - 1] != "not") for i, w in enumerate(words))


def pytest_collection_modifyitems(config: pytest.Config, items: list[pytest.Item]) -> None:
    ours = [i for i in items if HERE in Path(str(i.path)).resolve().parents]
    for item in ours:
        item.add_marker(pytest.mark.robustness)
    if _requested(config.getoption("markexpr") or ""):
        return
    config.hook.pytest_deselected(items=ours)
    items[:] = [i for i in items if i not in ours]
