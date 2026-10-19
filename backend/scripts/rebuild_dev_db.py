"""Rebuild the local dev database from the catalog only (#166).

Drops the schema, migrates to head, and loads the reference seed plus the catalog.
Refuses to run without --yes, and refuses any database host other than localhost,
127.0.0.1, or the compose service name db.

    uv run python -m scripts.rebuild_dev_db --yes
"""

from __future__ import annotations

import argparse
import sys

from sqlalchemy import create_engine, func, select
from sqlalchemy.engine import make_url
from sqlalchemy.orm import Session

from app.core.config import get_settings
from app.db.admin import downgrade_base, upgrade_head
from app.db.models import Meal, MealStep
from app.pipeline.build import DEFAULT_DATA_DIR, build_catalog

LOCAL_HOSTS = frozenset({"localhost", "127.0.0.1", "db"})


class RebuildRefusedError(Exception):
    """The rebuild guard rejected the command before touching the database."""


def refuse_unless_local(url: str, *, yes: bool) -> None:
    if not yes:
        raise RebuildRefusedError("refusing to rebuild without --yes")
    host = make_url(url).host
    if host not in LOCAL_HOSTS:
        raise RebuildRefusedError(f"refusing to rebuild a database on host {host!r}")


def _print_counts(session: Session) -> None:
    rows = session.execute(
        select(Meal.dataset_version, func.count())
        .where(Meal.is_active.is_(True))
        .group_by(Meal.dataset_version)
        .order_by(Meal.dataset_version)
    ).all()
    print("active meals by dataset_version:")
    for version, count in rows:
        print(f"  {version}: {count}")
    steps = session.execute(select(func.count()).select_from(MealStep)).scalar_one()
    with_form = session.execute(
        select(func.count()).select_from(Meal).where(Meal.dish_form.is_not(None))
    ).scalar_one()
    print(f"meal_steps rows: {steps}")
    print(f"meals with dish_form set: {with_form}")


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0] if __doc__ else None)
    parser.add_argument(
        "--yes",
        action="store_true",
        help="Rebuild the database named by DATABASE_URL.",
    )
    args = parser.parse_args(argv)
    url = get_settings().DATABASE_URL
    try:
        refuse_unless_local(url, yes=args.yes)
    except RebuildRefusedError as exc:
        print(exc, file=sys.stderr)
        return 1
    print(f"target database: {make_url(url).database}", flush=True)
    engine = create_engine(url)
    try:
        downgrade_base(engine)
        upgrade_head(engine)
        with Session(engine) as session:
            result = build_catalog(DEFAULT_DATA_DIR, session=session, load=True)
            session.commit()
            _print_counts(session)
        accepted = sum(
            1 for record in result.classified.meals.values() if record.outcome.value == "accepted"
        )
        print(f"accepted meals in the catalog files: {accepted}")
    finally:
        engine.dispose()
    return 0


if __name__ == "__main__":
    sys.exit(main())
