from __future__ import annotations

import json
import subprocess
from pathlib import Path

import pytest
from typer.testing import CliRunner

from plsql_lens import parse_file
from plsql_lens.cli import app
from plsql_lens.llm import (
    AnthropicApiProvider,
    ClaudeCliProvider,
    FakeProvider,
    LLMError,
    LLMResponse,
    UsageLog,
    build_prompt,
    explain_findings,
    make_provider,
    parse_explanation,
)
from plsql_lens.rules import review

FIXTURES = Path(__file__).resolve().parents[1] / "fixtures"
PLL001 = FIXTURES / "rules" / "PLL001" / "pos_1.pkb"
CLI_JSON = (FIXTURES / "llm" / "claude_cli_response.json").read_text()


def _findings():  # type: ignore[no-untyped-def]
    ir = parse_file(PLL001)
    return ir, review(ir, rules=["PLL001"])


def _fake_for(findings, ir, text: str) -> FakeProvider:  # type: ignore[no-untyped-def]
    source = PLL001.read_text()
    prompts = [build_prompt(f, source) for f in findings]
    return FakeProvider({p: LLMResponse(text, 100, 50, 0.001, "fake-model") for p in prompts})


GOOD = json.dumps({"explanation": "It hides errors.", "patch": "RAISE;"})


def test_explanations_are_attached_and_findings_are_not_changed() -> None:
    ir, findings = _findings()
    before = list(findings)
    log = UsageLog()
    out = explain_findings(
        findings, {str(PLL001): PLL001.read_text()}, _fake_for(findings, ir, GOOD), log
    )
    assert findings == before  # the LLM layer never creates or removes findings
    assert [e.finding for e in out] == before
    assert out[0].explanation == "It hides errors." and out[0].patch == "RAISE;"
    assert log.calls == len(findings) and log.input_tokens == 100 * len(findings)
    assert log.cost_usd == pytest.approx(0.001 * len(findings))


@pytest.mark.parametrize("garbage", ["not json at all", "{}", '{"explanation": 5}', ""])
def test_garbage_llm_output_never_drops_a_finding(garbage: str) -> None:
    ir, findings = _findings()
    out = explain_findings(
        findings, {str(PLL001): PLL001.read_text()}, _fake_for(findings, ir, garbage), UsageLog()
    )
    assert [e.finding for e in out] == findings
    assert all(e.explanation is None for e in out)


def test_parse_explanation_accepts_fenced_json() -> None:
    text = 'Sure!\n```json\n{"explanation": "e", "patch": null}\n```'
    assert parse_explanation(text) == ("e", None)


def test_prompt_contains_rule_location_and_code_context() -> None:
    _, findings = _findings()
    prompt = build_prompt(findings[0], PLL001.read_text())
    assert "PLL001" in prompt and f":{findings[0].location.line}" in prompt
    assert "WHEN OTHERS" in prompt.upper()


def test_fake_provider_has_no_fallback() -> None:
    with pytest.raises(LLMError):
        FakeProvider({}).complete("unrecorded prompt")


def test_fake_provider_roundtrips_a_recording_file(tmp_path: Path) -> None:
    rec = tmp_path / "rec.json"
    FakeProvider({"p": LLMResponse("t", 1, 2, None, "m")}).save(rec)
    assert FakeProvider.load(rec).complete("p").text == "t"


def test_claude_cli_provider_parses_json_and_records_usage() -> None:
    seen: list[list[str]] = []

    def runner(cmd: list[str], prompt: str) -> subprocess.CompletedProcess[str]:
        seen.append(cmd)
        return subprocess.CompletedProcess(cmd, 0, CLI_JSON, "")

    resp = ClaudeCliProvider(model="claude-haiku-5-5", runner=runner).complete("hi")
    assert resp.text == '{"ok":true}'
    assert resp.cost_usd and resp.cost_usd > 0
    assert resp.output_tokens > 0 and resp.input_tokens > 0
    assert seen[0][:4] == ["claude", "-p", "--output-format", "json"]
    assert "--model" in seen[0] and "claude-haiku-5-5" in seen[0]


def test_claude_cli_provider_errors() -> None:
    def failing(cmd: list[str], prompt: str) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(cmd, 1, "", "boom")

    with pytest.raises(LLMError, match="boom"):
        ClaudeCliProvider(runner=failing).complete("x")

    def bad_json(cmd: list[str], prompt: str) -> subprocess.CompletedProcess[str]:
        return subprocess.CompletedProcess(cmd, 0, "not json", "")

    with pytest.raises(LLMError):
        ClaudeCliProvider(runner=bad_json).complete("x")


def test_anthropic_api_provider_requires_key_and_parses_response() -> None:
    with pytest.raises(LLMError, match="ANTHROPIC_API_KEY"):
        make_provider("anthropic-api", env={})
    body = json.dumps(
        {
            "content": [{"type": "text", "text": "hello"}],
            "usage": {"input_tokens": 7, "output_tokens": 3},
        }
    )
    calls: list[tuple[str, dict[str, str], bytes]] = []

    def transport(url: str, headers: dict[str, str], data: bytes) -> str:
        calls.append((url, headers, data))
        return body

    resp = AnthropicApiProvider("k", model="claude-haiku-5-5", transport=transport).complete("p")
    assert (resp.text, resp.input_tokens, resp.output_tokens, resp.cost_usd) == (
        "hello",
        7,
        3,
        None,
    )
    assert calls[0][0].startswith("https://api.anthropic.com/")
    assert calls[0][1]["x-api-key"] == "k"


def test_make_provider_choices() -> None:
    assert isinstance(make_provider("claude-cli", env={}), ClaudeCliProvider)
    with pytest.raises(LLMError, match="recordings"):
        make_provider("fake", env={})
    with pytest.raises(LLMError, match="unknown"):
        make_provider("nope", env={})


def test_cli_explain_with_recordings_json_output(tmp_path: Path) -> None:
    ir, findings = _findings()
    rec = tmp_path / "rec.json"
    _fake_for(findings, ir, GOOD).save(rec)
    res = CliRunner().invoke(
        app,
        ["review", str(PLL001), "--rules", "PLL001", "--format", "json", "--explain",
         "--llm", "fake", "--llm-recordings", str(rec)],
    )  # fmt: skip
    assert res.exit_code == 0, res.output
    data = json.loads(res.stdout)
    assert len(data["findings"]) == len(findings)
    assert data["findings"][0]["explanation"] == "It hides errors."
    assert data["llm_usage"]["calls"] == len(findings)
    assert data["llm_usage"]["cost_usd"] == pytest.approx(0.001 * len(findings))
