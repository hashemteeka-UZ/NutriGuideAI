from functools import lru_cache
from pathlib import Path
from typing import Literal

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

REPO_ROOT = Path(__file__).resolve().parents[3]


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=REPO_ROOT / ".env",
        env_file_encoding="utf-8",
        extra="ignore",
        case_sensitive=True,
    )

    DATABASE_URL: str
    APP_ENV: Literal["development", "test", "production"] = "development"

    @field_validator("DATABASE_URL")
    @classmethod
    def require_psycopg_driver(cls, value: str) -> str:
        if not value.startswith("postgresql+psycopg://"):
            raise ValueError("DATABASE_URL must use the psycopg 3 driver: postgresql+psycopg://...")
        return value


@lru_cache
def get_settings() -> Settings:
    return Settings()
