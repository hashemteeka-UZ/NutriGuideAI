from sqlalchemy import text

from app.db.session import SessionLocal


def test_select_one() -> None:
    with SessionLocal() as session:
        assert session.execute(text("SELECT 1")).scalar_one() == 1


def test_server_is_postgresql_16() -> None:
    with SessionLocal() as session:
        version = session.execute(text("SELECT version()")).scalar_one()
    assert version.startswith("PostgreSQL 16"), version


def test_pg_trgm_is_available() -> None:
    with SessionLocal() as session:
        found = session.execute(
            text("SELECT 1 FROM pg_available_extensions WHERE name = 'pg_trgm'")
        ).scalar_one_or_none()
    assert found == 1
