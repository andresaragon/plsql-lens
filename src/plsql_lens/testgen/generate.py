"""Ask the LLM for a utPLSQL test package and for repairs of compile errors."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path

from ..llm import LLMProvider, LLMResponse
from .prompt import build_generation_prompt, build_repair_prompt
from .targets import Target

_FENCE = re.compile(r"```(?:sql|plsql)?\s*\n(.*?)```", re.DOTALL | re.IGNORECASE)


@dataclass(frozen=True, slots=True)
class GeneratedTest:
    code: str
    response: LLMResponse


def extract_code(text: str) -> str:
    """The first fenced code block of the reply, or the whole reply when there is none."""
    m = _FENCE.search(text)
    code = (m.group(1) if m else text).strip()
    return code + "\n"


class TestGenerator:
    __test__ = False  # not a pytest class

    def __init__(self, provider: LLMProvider, root: Path) -> None:
        self.provider, self.root = provider, root

    def generate(self, target: Target) -> GeneratedTest:
        resp = self.provider.complete(build_generation_prompt(target, self.root))
        return GeneratedTest(extract_code(resp.text), resp)

    def repair(self, target: Target, code: str, error: str) -> GeneratedTest:
        resp = self.provider.complete(build_repair_prompt(target, self.root, code, error))
        return GeneratedTest(extract_code(resp.text), resp)
