"""Optional LLM layer: explanations and fix proposals for findings (never creates findings)."""

from .explain import Explanation, build_prompt, explain_findings, parse_explanation
from .providers import (
    AnthropicApiProvider,
    ClaudeCliProvider,
    FakeProvider,
    LLMError,
    LLMProvider,
    LLMResponse,
    UsageLog,
    make_provider,
)

__all__ = [
    "AnthropicApiProvider",
    "ClaudeCliProvider",
    "Explanation",
    "FakeProvider",
    "LLMError",
    "LLMProvider",
    "LLMResponse",
    "UsageLog",
    "build_prompt",
    "explain_findings",
    "make_provider",
    "parse_explanation",
]
