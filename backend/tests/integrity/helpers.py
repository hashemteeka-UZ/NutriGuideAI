"""Helpers for integrity tests: SAVEPOINT-wrapped rejections and catalog queries."""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any

import pytest
from sqlalchemy import and_, select
from sqlalchemy.engine import Connection
from sqlalchemy.exc import DBAPIError, IntegrityError
from sqlalchemy.sql import text

from tests.builders import MAKERS, make_row, table

BAD_ID = 900_000_000_000

CONFTYPE_ONDELETE = {
    "a": "NO ACTION",
    "r": "RESTRICT",
    "c": "CASCADE",
    "n": "SET NULL",
    "d": "SET DEFAULT",
}


def constraint_name(exc: IntegrityError) -> str | None:
    orig = exc.orig
    diag = getattr(orig, "diag", None)
    if diag is None:
        return None
    return diag.constraint_name


def assert_rejects(conn: Connection, expected: str, fn: Callable[[], object]) -> IntegrityError:
    """Run fn inside a SAVEPOINT; expect IntegrityError naming `expected`."""
    with pytest.raises(IntegrityError) as caught, conn.begin_nested():
        fn()
    actual = constraint_name(caught.value)
    assert actual == expected, f"expected constraint {expected!r}, got {actual!r}\n{caught.value}"
    return caught.value


def assert_rejected(conn: Connection, fn: Callable[[], object]) -> BaseException:
    """Run fn inside a SAVEPOINT; expect the statement to be rejected by PostgreSQL."""
    with pytest.raises(DBAPIError) as caught, conn.begin_nested():
        fn()
    return caught.value


def insert_invalid(conn: Connection, table_name: str, **overrides: Any) -> None:
    make_row(conn, table_name, **overrides)


@dataclass(frozen=True)
class ForeignKeyInfo:
    table: str
    column: str
    referred_table: str
    referred_column: str
    ondelete: str
    name: str


def pg_check_names(conn: Connection) -> set[str]:
    rows = conn.execute(
        text(
            "SELECT con.conname FROM pg_constraint con "
            "JOIN pg_class c ON c.oid = con.conrelid "
            "JOIN pg_namespace n ON n.oid = c.relnamespace "
            "WHERE con.contype = 'c' AND n.nspname = 'public' "
            "AND c.relname <> 'alembic_version'"
        )
    )
    return set(rows.scalars())


def pg_unique_names(conn: Connection) -> set[str]:
    rows = conn.execute(
        text(
            "SELECT con.conname FROM pg_constraint con "
            "JOIN pg_class c ON c.oid = con.conrelid "
            "JOIN pg_namespace n ON n.oid = c.relnamespace "
            "WHERE con.contype = 'u' AND n.nspname = 'public' "
            "AND c.relname <> 'alembic_version'"
        )
    )
    return set(rows.scalars())


def pg_partial_unique_index_names(conn: Connection) -> set[str]:
    rows = conn.execute(
        text(
            "SELECT idx.relname FROM pg_index i "
            "JOIN pg_class idx ON idx.oid = i.indexrelid "
            "JOIN pg_class tbl ON tbl.oid = i.indrelid "
            "JOIN pg_namespace n ON n.oid = tbl.relnamespace "
            "WHERE i.indisunique AND NOT i.indisprimary "
            "AND i.indpred IS NOT NULL "
            "AND n.nspname = 'public' AND tbl.relname <> 'alembic_version'"
        )
    )
    return set(rows.scalars())


@dataclass(frozen=True)
class IndexInfo:
    name: str
    table: str
    columns: tuple[str, ...]
    method: str
    predicate: str | None


def pg_non_unique_indexes(conn: Connection) -> list[IndexInfo]:
    rows = conn.execute(
        text(
            "SELECT idx.relname AS name, tbl.relname AS table_name, am.amname AS method, "
            "pg_get_expr(i.indpred, i.indrelid) AS predicate, "
            "array(SELECT att.attname FROM unnest(i.indkey) WITH ORDINALITY AS k(attnum, ord) "
            "JOIN pg_attribute att ON att.attrelid = tbl.oid AND att.attnum = k.attnum "
            "ORDER BY k.ord) AS columns "
            "FROM pg_index i "
            "JOIN pg_class idx ON idx.oid = i.indexrelid "
            "JOIN pg_class tbl ON tbl.oid = i.indrelid "
            "JOIN pg_am am ON am.oid = idx.relam "
            "JOIN pg_namespace n ON n.oid = tbl.relnamespace "
            "WHERE NOT i.indisunique AND NOT i.indisprimary "
            "AND n.nspname = 'public' AND tbl.relname <> 'alembic_version'"
        )
    )
    return [
        IndexInfo(
            name=row.name,
            table=row.table_name,
            columns=tuple(row.columns),
            method=row.method,
            predicate=row.predicate,
        )
        for row in rows
    ]


def pg_foreign_keys(conn: Connection) -> list[ForeignKeyInfo]:
    rows = conn.execute(
        text(
            "SELECT src.relname AS table_name, src_att.attname AS column_name, "
            "tgt.relname AS referred_table, tgt_att.attname AS referred_column, "
            "con.confdeltype AS ondelete, con.conname AS name "
            "FROM pg_constraint con "
            "JOIN pg_class src ON src.oid = con.conrelid "
            "JOIN pg_class tgt ON tgt.oid = con.confrelid "
            "JOIN pg_namespace nsp ON nsp.oid = src.relnamespace "
            "JOIN unnest(con.conkey) WITH ORDINALITY AS src_k(attnum, ord) ON true "
            "JOIN unnest(con.confkey) WITH ORDINALITY AS tgt_k(attnum, ord) "
            "ON src_k.ord = tgt_k.ord "
            "JOIN pg_attribute src_att ON src_att.attrelid = src.oid "
            "AND src_att.attnum = src_k.attnum "
            "JOIN pg_attribute tgt_att ON tgt_att.attrelid = tgt.oid "
            "AND tgt_att.attnum = tgt_k.attnum "
            "WHERE con.contype = 'f' AND nsp.nspname = 'public'"
        )
    )
    return [
        ForeignKeyInfo(
            table=row.table_name,
            column=row.column_name,
            referred_table=row.referred_table,
            referred_column=row.referred_column,
            ondelete=CONFTYPE_ONDELETE[row.ondelete],
            name=row.name,
        )
        for row in rows
    ]


def pg_not_null_without_default(conn: Connection) -> list[tuple[str, str]]:
    rows = conn.execute(
        text(
            "SELECT c.relname AS table_name, a.attname AS column_name "
            "FROM pg_attribute a "
            "JOIN pg_class c ON c.oid = a.attrelid "
            "JOIN pg_namespace n ON n.oid = c.relnamespace "
            "WHERE n.nspname = 'public' AND c.relkind = 'r' AND a.attnum > 0 "
            "AND NOT a.attisdropped AND a.attnotnull AND a.attidentity = '' "
            "AND NOT a.atthasdef AND c.relname <> 'alembic_version' "
            "ORDER BY c.relname, a.attnum"
        )
    )
    return [(row.table_name, row.column_name) for row in rows]


def pg_constraints(conn: Connection) -> list[tuple[str, str, str]]:
    rows = conn.execute(
        text(
            "SELECT c.relname AS table_name, con.conname, con.contype::text "
            "FROM pg_constraint con "
            "JOIN pg_class c ON c.oid = con.conrelid "
            "JOIN pg_namespace n ON n.oid = c.relnamespace "
            "WHERE n.nspname = 'public' AND c.relname <> 'alembic_version'"
        )
    )
    return [(row.table_name, row.conname, row.contype) for row in rows]


def pg_indexes(conn: Connection) -> list[tuple[str, str]]:
    rows = conn.execute(
        text(
            "SELECT tablename, indexname FROM pg_indexes "
            "WHERE schemaname = 'public' AND tablename <> 'alembic_version'"
        )
    )
    return [(row.tablename, row.indexname) for row in rows]


def pg_btree_leading_columns(conn: Connection) -> set[tuple[str, str]]:
    """(table, column) that are the leftmost key of a non-partial B-tree index."""
    rows = conn.execute(
        text(
            "SELECT tbl.relname AS table_name, att.attname AS column_name "
            "FROM pg_index i "
            "JOIN pg_class tbl ON tbl.oid = i.indrelid "
            "JOIN pg_class idx ON idx.oid = i.indexrelid "
            "JOIN pg_am am ON am.oid = idx.relam "
            "JOIN pg_namespace n ON n.oid = tbl.relnamespace "
            "JOIN pg_attribute att ON att.attrelid = tbl.oid AND att.attnum = i.indkey[0] "
            "WHERE n.nspname = 'public' AND tbl.relkind = 'r' "
            "AND i.indpred IS NULL AND am.amname = 'btree' AND i.indnkeyatts >= 1"
        )
    )
    return {(row.table_name, row.column_name) for row in rows}


def fetch_by_pk(conn: Connection, table_name: str, pk: Any) -> Any | None:
    tbl = table(table_name)
    pk_cols = list(tbl.primary_key.columns)
    if len(pk_cols) == 1:
        where = pk_cols[0] == pk
    else:
        where = and_(*[col == val for col, val in zip(pk_cols, pk, strict=True)])
    return conn.execute(select(tbl).where(where)).first()


def maker(table_name: str) -> Callable[..., Any]:
    return MAKERS[table_name]
