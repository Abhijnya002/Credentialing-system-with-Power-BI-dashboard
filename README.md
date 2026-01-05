# Credentialing Data Validation & BI Reporting System

## Project Overview

A comprehensive enterprise-grade system designed to validate credentialing data across healthcare providers, credentials, and entities. The system includes a centralized SQL Server database with automated daily refreshes, 117 SQL validation and business logic rules, and a fully automated Power BI dashboard with DAX measures to surface data issues, trends, and performance metrics in near real-time.

**Technologies**: SQL Server, Power BI, Python  
**Timeline**: January 2025 – March 2025

## System Architecture

The system is built on three core components:

1. **SQL Server Database**: Centralized database schema with 7 core tables supporting credentialing data validation
2. **Validation Engine**: 117 SQL validation rules implemented as stored procedures covering data quality, business logic, and compliance
3. **Power BI Dashboard**: Interactive dashboard with DAX measures providing real-time analytics and data quality insights

## Database Schema

### Core Tables

**Providers Table**
- Stores provider information including NPI, demographic data, contact information, specialty, and entity associations
- Primary key: ProviderID
- Foreign key: EntityID (references Entities table)
- Indexes on NPI, EntityID, Status, and name fields for optimized queries

**Credentials Table**
- Manages credential and license information including expiration dates, verification status, and issuing organizations
- Primary key: CredentialID
- Foreign key: ProviderID (references Providers table)
- Indexes on ProviderID, ExpirationDate, CredentialType, and CredentialNumber

**Entities Table**
- Contains healthcare entity and organization information including addresses, accreditation status, and contact details
- Primary key: EntityID
- Indexes on NPI, TaxID, and Status fields

**ValidationResults Table**
- Audit log storing all validation check results with timestamps, error messages, and resolution tracking
- Primary key: ValidationResultID
- Foreign key: RuleID (references ValidationRules table)
- Indexed on RuleID, ValidationDate, ValidationStatus, and EntityType for performance

**ValidationRules Table**
- Metadata table containing information about all validation rules including category, severity, and active status
- Primary key: RuleID
- Stores 117 active validation rules

**ValidationRunLog Table**
- Tracks execution history of validation runs including execution time, status, and summary statistics
- Primary key: RunID

**DataRefreshLog Table**
- Logs all data refresh operations with timestamps, record counts, and execution status
- Primary key: RefreshID

### Relationships

The database implements a relational model with the following key relationships:
- Providers to Entities: Many-to-One (multiple providers can belong to one entity)
- Providers to Credentials: One-to-Many (one provider can have multiple credentials)
- ValidationResults to ValidationRules: Many-to-One (validation results reference validation rules)

## Validation Rules

The system includes 117 validation rules organized into four categories:

**Provider Validations (35 rules)**
- Data quality checks: NPI format validation, name completeness, address validation, contact information format
- Business logic: Status validation, entity associations, date logic, specialty requirements
- Examples: NPI must be 10 digits, First Name required, Date of Birth must be in past, Email format validation

**Credential Validations (40 rules)**
- Expiration tracking: Credentials expiring within 30/60/90 days, expired credential identification
- Data integrity: Credential number uniqueness, expiration date logic, status compliance
- Business rules: Primary credential constraints, verification requirements, license state validation
- Examples: ExpirationDate must be after IssueDate, Active credentials cannot be expired, License credentials require StateIssued

**Entity Validations (25 rules)**
- Entity data quality: Entity name validation, TaxID format, NPI uniqueness, address completeness
- Compliance: Accreditation status validation, entity type standardization
- Examples: EntityName required, TaxID must be 9 digits, Active entities require complete address information

**Cross-Entity Validations (17 rules)**
- Relationship validation: Provider-Entity relationships, credential-provider matching
- Consistency checks: State matching, date logic across entities, status coherence
- Examples: Provider EntityID must reference active Entity, Credential StateIssued should match Provider State for licenses

### Validation Rule Severity Levels

- Critical: 15 rules requiring immediate action
- High: 35 rules indicating significant data quality issues
- Medium: 45 rules for moderate issues requiring attention
- Low: 22 rules for minor issues and warnings

## Python Automation Scripts

The system includes Python scripts for data management and automation:

**data_ingestion.py**
- Loads data from source systems (CSV files, databases, APIs)
- Supports bulk data operations with error handling
- Logs all data refresh operations to DataRefreshLog table
- Handles data transformation and validation during ingestion

**validation_runner.py**
- Executes all validation stored procedures
- Logs validation execution to ValidationRunLog table
- Generates summary reports of validation results
- Supports manual and scheduled execution modes

**daily_refresh.py**
- Orchestrates daily data refresh and validation processes
- Executes data ingestion followed by validation execution
- Designed to run as scheduled task (Windows Task Scheduler, cron, SQL Server Agent)
- Comprehensive error handling and logging

**config.py**
- Centralized configuration management
- Database connection settings
- Validation thresholds and parameters
- Logging configuration

## Power BI Dashboard

The Power BI dashboard provides real-time visualization of credentialing data and validation results:

**Key Features**
- Interactive dashboards with drill-down capabilities
- Real-time data quality metrics and KPIs
- Validation failure tracking and trends
- Credential expiration monitoring
- Provider and entity compliance tracking
- Geographic distribution visualizations

**DAX Measures**
The dashboard includes 50+ DAX measures for analytics including:
- Total validation failures and warnings by severity
- Credential expiration tracking (30, 60, 90 day windows)
- Data quality scores and compliance rates
- Trend analysis with month-over-month and year-over-year comparisons
- Provider and entity performance metrics

**Dashboard Pages**
- Executive Summary: High-level KPIs and trends for leadership
- Credentialing Analysis: Detailed credential status and expiration tracking
- Provider Analytics: Provider-specific metrics and compliance
- Entity Management: Entity-level insights and distribution
- Trend Analysis: Historical trends and forecasting
- Validation Results: Detailed validation failure reporting

## Installation and Setup

### Prerequisites

- SQL Server 2019 or higher
- Python 3.8 or higher
- Power BI Desktop
- ODBC Driver 17 for SQL Server (or compatible version)

### Database Setup

1. Create the database by running database/schema/01_create_database.sql
2. Create tables by running database/schema/02_create_tables.sql
3. Create indexes by running database/schema/03_create_indexes.sql
4. Populate validation rules by running database/validation_rules/populate_validation_rules.sql
5. Create validation stored procedures:
   - database/validation_rules/provider_validations.sql
   - database/validation_rules/credential_validations.sql
   - database/validation_rules/entity_validations.sql
   - database/validation_rules/cross_entity_validations.sql
   - database/validation_rules/master_validation_runner.sql

### Python Environment Setup

1. Install required packages: pip install -r requirements.txt
2. Configure database connection in python/config.py
3. Set up environment variables or update configuration file with SQL Server credentials

### Power BI Setup

1. Connect Power BI Desktop to the SQL Server database
2. Import tables: Providers, Credentials, Entities, ValidationResults, ValidationRules, ValidationRunLog, DataRefreshLog
3. Create relationships between tables
4. Import DAX measures from powerbi/dax_measures.md
5. Build dashboard pages following powerbi/dashboard_requirements.md

### Automated Daily Refresh

Configure daily refresh using one of these methods:

**Option 1: Windows Task Scheduler**
- Create scheduled task to run python/daily_refresh.py daily at 2:00 AM

**Option 2: SQL Server Agent**
- Create SQL Server Agent job to execute validation stored procedures
- Schedule for daily execution

**Option 3: Python Schedule Library**
- Modify daily_refresh.py to use schedule library for continuous execution

## Usage

### Running Validations Manually

Execute validation rules manually using the Python script:
```
python python/validation_runner.py
```

Or execute directly in SQL Server:
```sql
EXEC cred.sp_RunAllValidations @RunType = 'Manual';
```

### Data Ingestion

Load data from source systems:
```
python python/data_ingestion.py
```

### Viewing Results

- Access validation results through Power BI dashboard
- Query ValidationResults table directly in SQL Server
- Review ValidationRunLog for execution history

## Project Structure

```
CredentialingDB/
├── database/
│   ├── schema/
│   │   ├── 01_create_database.sql
│   │   ├── 02_create_tables.sql
│   │   └── 03_create_indexes.sql
│   └── validation_rules/
│       ├── provider_validations.sql
│       ├── credential_validations.sql
│       ├── entity_validations.sql
│       ├── cross_entity_validations.sql
│       ├── populate_validation_rules.sql
│       └── master_validation_runner.sql
├── python/
│   ├── config.py
│   ├── data_ingestion.py
│   ├── validation_runner.py
│   └── daily_refresh.py
├── powerbi/
│   ├── dax_measures.md
│   └── dashboard_requirements.md
├── requirements.txt
└── README.md
```

## Technical Specifications

**Database**
- SQL Server 2019+
- Schema: cred (credentialing)
- 7 core tables with proper indexing
- 5 stored procedures for validation execution
- 117 active validation rules

**Python**
- Python 3.8+
- Key libraries: pyodbc, pandas, sqlalchemy
- 4 main automation scripts
- Comprehensive error handling and logging

**Power BI**
- Interactive dashboards with real-time refresh
- 50+ DAX measures for analytics
- Multiple dashboard pages for different user personas
- Drill-down and filtering capabilities

## Performance

- Validation execution: Typically completes in 30-60 seconds for 10,000+ records
- Database queries: Optimized with proper indexing strategy
- Power BI refresh: Configurable refresh schedule (near real-time supported)
- Scalability: Designed to handle millions of records with proper indexing

## Security

- SQL Server authentication and authorization
- Row-level security support in Power BI
- Encrypted database connections
- Audit logging for all operations
- Sensitive data handling best practices

## License

This project is provided as-is for credentialing data validation and reporting purposes.
