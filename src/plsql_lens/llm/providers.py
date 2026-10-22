"""LLM backends behind one interface: claude-cli (default), anthropic-api, fake (recordings)."""

from __future__ import annotations

import hashlib
import json
import os
import subprocess
import urllib.error
import urllib.request
from collections.abc import Callable, Mapping
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Protocol

DEFAULT_MODEL = "claude-haiku-5-5"  # SPEC §9: explanations use Haiku; confirm pricing in F2 report
API_URL = "https://api.anthropic.com/v1/messages"


class LLMError(RuntimeError):
    """Backend failure (never swallowed silently; findings do not depend on it)."""


@dataclass(frozen=True, slots=True)
class LLMResponse:
    text: str
    input_tokens: int
    output_tokens: int
    cost_usd: float | None  # only when the backend reports it
    model: str


class LLMProvider(Protocol):
    def complete(self, prompt: str) -> LLMResponse: ...


@dataclass
class UsageLog:
    """Accumulates the tokens and cost reported by the backend across calls."""

    calls: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    cost_usd: float = 0.0
    cost_reported: bool = False
    models: set[str] = field(default_factory=set)

    def add(self, r: LLMResponse) -> None:
        self.calls += 1
        self.input_tokens += r.input_tokens
        self.output_tokens += r.output_tokens
        if r.cost_usd is not None:
            self.cost_usd += r.cost_usd
            self.cost_reported = True
        self.models.add(r.model)

    def to_dict(self) -> dict[str, object]:
        return {
            "calls": self.calls,
            "input_tokens": self.input_tokens,
            "output_tokens": self.output_tokens,
            "cost_usd": self.cost_usd if self.cost_reported else None,
            "models": sorted(self.models),
        }


def _key(prompt: str) -> str:
    return hashlib.sha256(prompt.encode()).hexdigest()


class FakeProvider:
    """Replays recorded responses keyed by prompt; an unrecorded prompt is an error."""

    def __init__(self, responses: Mapping[str, LLMResponse]) -> None:
        self._by_key = {_key(p): r for p, r in responses.items()}

    def complete(self, prompt: str) -> LLMResponse:
        try:
            return self._by_key[_key(prompt)]
        except KeyError:
            raise LLMError(
                "no recorded response for this prompt (re-record the fixtures)"
            ) from None

    def save(self, path: Path) -> None:
        entries = [{"key": k, "response": asdict(r)} for k, r in sorted(self._by_key.items())]
        path.write_text(json.dumps({"entries": entries}, indent=1))

    @classmethod
    def load(cls, path: Path) -> FakeProvider:
        provider = cls({})
        for e in json.loads(path.read_text())["entries"]:
            provider._by_key[e["key"]] = LLMResponse(**e["response"])
        return provider


Runner = Callable[[list[str], str], "subprocess.CompletedProcess[str]"]


def _run_subprocess(cmd: list[str], prompt: str) -> subprocess.CompletedProcess[str]:
    try:
        return subprocess.run(cmd, input=prompt, capture_output=True, text=True, timeout=300)
    except (OSError, subprocess.TimeoutExpired) as e:
        raise LLMError(f"cannot run {cmd[0]}: {e}") from e


class ClaudeCliProvider:
    """Runs ``claude -p --output-format json``; billed to the same account as the session."""

    def __init__(self, model: str | None = DEFAULT_MODEL, runner: Runner = _run_subprocess) -> None:
        self.model, self.runner = model, runner

    def complete(self, prompt: str) -> LLMResponse:
        cmd = ["claude", "-p", "--output-format", "json"]
        if self.model:
            cmd += ["--model", self.model]
        proc = self.runner(cmd, prompt)
        if proc.returncode != 0:
            raise LLMError(f"claude exited with {proc.returncode}: {proc.stderr.strip()[:300]}")
        try:
            data = json.loads(proc.stdout)
            usage = data.get("usage", {})
            models = list(data.get("modelUsage", {}))
            if data.get("is_error"):
                raise LLMError(f"claude reported an error: {str(data.get('result'))[:300]}")
            return LLMResponse(
                text=str(data["result"]),
                input_tokens=int(usage.get("input_tokens", 0))
                + int(usage.get("cache_creation_input_tokens", 0))
                + int(usage.get("cache_read_input_tokens", 0)),
                output_tokens=int(usage.get("output_tokens", 0)),
                cost_usd=float(data["total_cost_usd"]) if "total_cost_usd" in data else None,
                model=models[0] if models else (self.model or "unknown"),
            )
        except (ValueError, KeyError, TypeError) as e:
            raise LLMError(f"unexpected claude output: {e}") from e


Transport = Callable[[str, dict[str, str], bytes], str]


def _urllib_transport(url: str, headers: dict[str, str], data: bytes) -> str:
    req = urllib.request.Request(url, data=data, headers=headers, method="POST")
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:  # noqa: S310 - fixed https URL
            return str(resp.read().decode())
    except (urllib.error.URLError, OSError) as e:
        raise LLMError(f"Anthropic API request failed: {e}") from e


class AnthropicApiProvider:
    """Messages API over HTTPS; reports tokens but not cost."""

    def __init__(
        self,
        api_key: str,
        model: str = DEFAULT_MODEL,
        transport: Transport = _urllib_transport,
        max_tokens: int = 1024,
    ) -> None:
        self.api_key, self.model, self.transport, self.max_tokens = (
            api_key,
            model,
            transport,
            max_tokens,
        )

    def complete(self, prompt: str) -> LLMResponse:
        body = json.dumps(
            {
                "model": self.model,
                "max_tokens": self.max_tokens,
                "messages": [{"role": "user", "content": prompt}],
            }
        ).encode()
        headers = {
            "x-api-key": self.api_key,
            "anthropic-version": "2023-06-01",
            "content-type": "application/json",
        }
        raw = self.transport(API_URL, headers, body)
        try:
            data = json.loads(raw)
            text = "".join(b.get("text", "") for b in data["content"] if b.get("type") == "text")
            u = data.get("usage", {})
            return LLMResponse(text, int(u.get("input_tokens", 0)), int(u.get("output_tokens", 0)),
                               None, self.model)  # fmt: skip
        except (ValueError, KeyError, TypeError) as e:
            raise LLMError(f"unexpected API response: {e}") from e


def make_provider(
    name: str,
    env: Mapping[str, str] | None = None,
    model: str | None = None,
    recordings: Path | None = None,
) -> LLMProvider:
    env = os.environ if env is None else env
    if name == "claude-cli":
        return ClaudeCliProvider(model or DEFAULT_MODEL)
    if name == "anthropic-api":
        key = env.get("ANTHROPIC_API_KEY")
        if not key:
            raise LLMError("anthropic-api needs ANTHROPIC_API_KEY in the environment")
        return AnthropicApiProvider(key, model or DEFAULT_MODEL)
    if name == "fake":
        if recordings is None:
            raise LLMError("the fake provider needs --llm-recordings PATH")
        return FakeProvider.load(recordings)
    raise LLMError(f"unknown LLM provider: {name}")
