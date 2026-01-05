"""
Configuration file for Credentialing Data Validation System
Contains database connection settings and configuration parameters
"""

import os
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# SQL Server Connection Configuration
SQL_SERVER = os.getenv('SQL_SERVER', 'localhost')
SQL_DATABASE = os.getenv('SQL_DATABASE', 'CredentialingDB')
SQL_USERNAME = os.getenv('SQL_USERNAME', 'sa')
SQL_PASSWORD = os.getenv('SQL_PASSWORD', 'YourPassword123!')
SQL_DRIVER = os.getenv('SQL_DRIVER', '{ODBC Driver 17 for SQL Server}')

# Connection String
CONNECTION_STRING = f"DRIVER={SQL_DRIVER};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};UID={SQL_USERNAME};PWD={SQL_PASSWORD}"

# Alternative connection string for SQLAlchemy
SQLALCHEMY_CONNECTION_STRING = f"mssql+pyodbc://{SQL_USERNAME}:{SQL_PASSWORD}@{SQL_SERVER}/{SQL_DATABASE}?driver=ODBC+Driver+17+for+SQL+Server"

# Validation Configuration
VALIDATION_RUN_TYPE_SCHEDULED = 'Scheduled'
VALIDATION_RUN_TYPE_MANUAL = 'Manual'
VALIDATION_RUN_TYPE_ONDEMAND = 'OnDemand'

# Data Refresh Configuration
DATA_REFRESH_SCHEDULE_HOUR = 2  # 2 AM daily
DATA_REFRESH_SCHEDULE_MINUTE = 0

# File Paths (if using file-based data sources)
DATA_SOURCE_PATH = os.getenv('DATA_SOURCE_PATH', './data')
PROVIDERS_FILE = os.path.join(DATA_SOURCE_PATH, 'providers.csv')
CREDENTIALS_FILE = os.path.join(DATA_SOURCE_PATH, 'credentials.csv')
ENTITIES_FILE = os.path.join(DATA_SOURCE_PATH, 'entities.csv')

# Logging Configuration
LOG_LEVEL = os.getenv('LOG_LEVEL', 'INFO')
LOG_FILE = os.getenv('LOG_FILE', 'credentialing_validation.log')

# Email Configuration (for alerts - optional)
EMAIL_ENABLED = os.getenv('EMAIL_ENABLED', 'False').lower() == 'true'
EMAIL_SMTP_SERVER = os.getenv('EMAIL_SMTP_SERVER', 'smtp.gmail.com')
EMAIL_SMTP_PORT = int(os.getenv('EMAIL_SMTP_PORT', '587'))
EMAIL_FROM = os.getenv('EMAIL_FROM', '')
EMAIL_TO = os.getenv('EMAIL_TO', '').split(',')
EMAIL_USERNAME = os.getenv('EMAIL_USERNAME', '')
EMAIL_PASSWORD = os.getenv('EMAIL_PASSWORD', '')

# Validation Thresholds
MAX_VALIDATION_FAILURES_THRESHOLD = 100  # Alert if more than 100 failures
CREDENTIAL_EXPIRATION_WARNING_DAYS = 30  # Warn if credential expires within 30 days

