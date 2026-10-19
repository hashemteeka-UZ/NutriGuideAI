"""Create, migrate and drop sibling databases.

Names are validated before they are interpolated into SQL, the same rule as the
integrity-database fixture. Callers connect with AUTOCOMMIT: PostgreSQL refuses
CREATE DATABASE and DROP DATABASE inside a transaction.
"""

from __future__ import annotations

import re
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import create_engine, text
from sqlalchemy.engine import URL, Connection, Engine

ALEMBIC_INI = Path(__file__).resolve().parents[2] / "alembic.ini"
_DB_NAME_RE = re.compile(r"^[a-z][a-z0-9_]*$")


def require_db_name(name: str) -> str:
    if not _DB_NAME_RE.match(name):
        raise ValueError(f"refusing to use database name {name!r}")
    return name


def admin_engine(url: URL) -> Engine:
    return create_engine(url, isolation_level="AUTOCOMMIT", connect_args={"connect_timeout": 3})


def alembic_config(conn: Connection) -> Config:
    """Real alembic.ini, but env.py migrates `conn` instead of DATABASE_URL."""
    config = Config(str(ALEMBIC_INI))
    config.attributes["connection"] = conn
    return config


def drop_database(admin: Engine, name: str) -> None:
    ident = require_db_name(name)
    with admin.connect() as conn:
        conn.execute(text(f"DROP DATABASE IF EXISTS {ident} WITH (FORCE)"))


def create_database(admin: Engine, name: str) -> None:
    ident = require_db_name(name)
    with admin.connect() as conn:
        conn.execute(text(f"CREATE DATABASE {ident}"))


def upgrade_head(engine: Engine) -> None:
    with engine.begin() as conn:
        command.upgrade(alembic_config(conn), "head")


def downgrade_base(engine: Engine) -> None:
    with engine.begin() as conn:
        command.downgrade(alembic_config(conn), "base")
