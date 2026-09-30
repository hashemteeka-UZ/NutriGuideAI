# NutriGuideAI

Nutrition / meal recommendation project. Architecture and decisions live in
[`docs/PROJECT_CONTEXT_v4_7.md`](docs/PROJECT_CONTEXT_v4_7.md).

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
reserved for the integrity tests and is started with
`docker compose --profile test up -d db_test`.

Stop the database with `docker compose down` (add `-v` to delete its data volume).
