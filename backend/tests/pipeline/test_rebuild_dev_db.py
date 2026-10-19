"""Guard for the dev-database rebuild script. It never migrates."""

from __future__ import annotations

import pytest

from scripts.rebuild_dev_db import LOCAL_HOSTS, RebuildRefusedError, refuse_unless_local


def test_refuses_without_yes() -> None:
    with pytest.raises(RebuildRefusedError, match="--yes"):
        refuse_unless_local("postgresql+psycopg://nutriguide@localhost/nutriguide_dev", yes=False)


def test_refuses_non_local_host() -> None:
    with pytest.raises(RebuildRefusedError, match=r"example\.com"):
        refuse_unless_local("postgresql+psycopg://nutriguide@example.com/nutriguide_dev", yes=True)


@pytest.mark.parametrize("host", sorted(LOCAL_HOSTS))
def test_allows_local_hosts(host: str) -> None:
    refuse_unless_local(f"postgresql+psycopg://nutriguide@{host}/nutriguide_dev", yes=True)
