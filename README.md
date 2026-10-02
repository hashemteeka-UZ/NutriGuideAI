# NutriGuideAI

Nutrition / meal recommendation project. Architecture and decisions live in
[`docs/PROJECT_CONTEXT_v4_9.md`](docs/PROJECT_CONTEXT_v4_9.md).

## Local development

Requirements: Docker (with Compose), [uv](https://docs.astral.sh/uv/), git.

```bash
# 1. Configuration: copy the template and fill in every value
cp .env.example .env

# 2. Start PostgreSQL 16 and wait until it is healthy
docker compose up -d
docker compose ps          # db should show "(healthy)"

# 3. Install the backend dependencies (Python 3.12, from uv.lock)
cd backend
uv sync

# 4. Run the tests (connection check against the dev database)
uv run pytest

# 5. Code-quality checks
uv run ruff check .
uv run ruff format --check .
uv run mypy app

# 6. Install the git pre-commit hooks (run from the repository root)
cd ..
uv run --project backend pre-commit install
uv run --project backend pre-commit run --all-files
```

The optional `db_test` service (throwaway database, no persistent volume) is
reserved for schema tests and is started with
`docker compose --profile test up -d db_test`.

## Tests

Integrity tests prove the migrated schema on a real PostgreSQL database (CHECK,
UNIQUE, FK actions, NOT NULL, server defaults, enum-like columns, identity,
naming). They create a sibling database `{POSTGRES_TEST_DB}_integrity`, run
`alembic upgrade head` there, and roll back every test row.

```bash
# From the repository root: start the throwaway test database
docker compose --profile test up -d db_test

# From backend/
cd backend
uv run pytest
```

`uv run pytest` also runs connection checks against the dev database
(`DATABASE_URL`) and migration round-trip tests on empty `db_test`. CI runs
the same checks on every push and pull request (ruff, format, mypy,
`alembic upgrade head` on a main database, then pytest on an unmigrated test
database). Database tests must not skip in CI.

## Database migrations

Alembic lives in `backend/` and reads the database URL from `DATABASE_URL` in `.env`.
Run from `backend/`:

```bash
uv run alembic upgrade head    # create / update the schema
uv run alembic downgrade base  # WIPES the whole schema (all tables and data)
uv run alembic check           # fails if the models and migrations differ
```

Never edit a migration after it is committed; create a new revision instead
(`uv run alembic revision --autogenerate -m "..."`, then review the file by hand).

Stop the database with `docker compose down` (add `-v` to delete its data volume).
