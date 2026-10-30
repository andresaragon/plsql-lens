"""Oracle→PostgreSQL migration hints (F5a): rules MIG001–MIG011, see docs/migration-rules.md.

The rules are token-based and live apart from ``plsql_lens.rules.RULES`` (the review rules).
"""

from __future__ import annotations

from .rules import MIGRATION_RULES, migrate_file, migrate_source

__all__ = ["MIGRATION_RULES", "migrate_file", "migrate_source"]
