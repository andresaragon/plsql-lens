"""Oracle→PostgreSQL migration hints (F5).

F5a: rules MIG001–MIG011 (see docs/migration-rules.md), token-based and apart from
``plsql_lens.rules.RULES`` (the review rules). F5b: ``plsql_lens.migrate.rewrite`` holds the
conservative SQL rewrites (``rewrite_sql``).
"""

from __future__ import annotations

from .rules import MIGRATION_RULES, migrate_file, migrate_source

__all__ = ["MIGRATION_RULES", "migrate_file", "migrate_source"]
