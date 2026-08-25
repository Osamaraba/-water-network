from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    # Application
    APP_NAME: str = "Yarmouk Water Platform"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False

    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@db:5432/yarmouk_water"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 10

    # Redis
    REDIS_URL: str = "redis://redis:6379/0"

    # JWT
    JWT_SECRET_KEY: str = "change-me-in-production"
    JWT_ALGORITHM: str = "HS256"
    JWT_ACCESS_TOKEN_EXPIRE_MINUTES: int = 30
    JWT_REFRESH_TOKEN_EXPIRE_DAYS: int = 7

    # Security
    PASSWORD_MIN_LENGTH: int = 8
    MAX_LOGIN_ATTEMPTS: int = 5
    LOGIN_LOCKOUT_MINUTES: int = 30
    RATE_LIMIT_PER_MINUTE: int = 60

    # File Storage
    S3_ENDPOINT: str = "http://minio:9000"
    S3_ACCESS_KEY: str = "minioadmin"
    S3_SECRET_KEY: str = "minioadmin"
    S3_BUCKET_NAME: str = "yarmouk-water"
    S3_REGION: str = "us-east-1"

    # GPS Settings
    GPS_ACCURACY_THRESHOLD: float = 15.0
    GPS_FRESHNESS_THRESHOLD: int = 15
    GPS_DISTANCE_FILTER: float = 50.0
    GPS_TIME_INTERVAL: int = 30

    # Geofence
    GEOFENCE_DEFAULT_RADIUS: float = 50.0
    METER_READING_RADIUS: float = 15.0

    # Offline
    OFFLINE_TIMEOUT_MINUTES: int = 30
    IDLE_THRESHOLD_MINUTES: int = 10

    # Company
    COMPANY_NAME: str = "شركة مياه اليرموك"

    # Universal shared login (everyone uses the same credentials)
    UNIVERSAL_USERNAMES: list = ["ENG.OR"]

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

@lru_cache()
def get_settings() -> Settings:
    return Settings()
