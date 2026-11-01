"""Application settings, read from environment variables or a .env file."""

from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=(".env", "../.env"), extra="ignore")

    app_name: str = "Merchandising Intelligence POC"
    # psycopg 3 driver. Default matches docker-compose.yml.
    database_url: str = "postgresql+psycopg://merch:merch@localhost:5432/merch"
    # Used only by the test suite; tests reset this database freely.
    test_database_url: str = "postgresql+psycopg://merch:merch@localhost:5432/merch_test"
    # Comma-separated list of browser origins allowed to call the API.
    cors_origins: str = "http://localhost:5173"

    @property
    def cors_origin_list(self) -> list[str]:
        return [o.strip() for o in self.cors_origins.split(",") if o.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
