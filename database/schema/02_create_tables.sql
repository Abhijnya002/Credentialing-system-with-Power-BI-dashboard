-- Table Creation Script
-- Credentialing Data Validation System
-- Core Tables: Providers, Credentials, Entities, ValidationResults

USE CredentialingDB;
GO

-- =============================================
-- Table: Providers
-- Purpose: Store provider information
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.Providers') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.Providers (
        ProviderID INT IDENTITY(1,1) PRIMARY KEY,
        NPI NVARCHAR(10) NOT NULL UNIQUE,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        MiddleName NVARCHAR(100) NULL,
        DateOfBirth DATE NULL,
        SSN NVARCHAR(11) NULL,
        Specialty NVARCHAR(200) NULL,
        SubSpecialty NVARCHAR(200) NULL,
        PhoneNumber NVARCHAR(20) NULL,
        EmailAddress NVARCHAR(255) NULL,
        AddressLine1 NVARCHAR(255) NULL,
        AddressLine2 NVARCHAR(255) NULL,
        City NVARCHAR(100) NULL,
        State NVARCHAR(2) NULL,
        ZipCode NVARCHAR(10) NULL,
        EntityID INT NULL,
        Status NVARCHAR(50) DEFAULT 'Active',
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        LastValidatedDate DATETIME2 NULL,
        IsActive BIT DEFAULT 1
    );
    PRINT 'Table cred.Providers created successfully';
END
GO

-- =============================================
-- Table: Credentials
-- Purpose: Store credential/license information
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.Credentials') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.Credentials (
        CredentialID INT IDENTITY(1,1) PRIMARY KEY,
        ProviderID INT NOT NULL,
        CredentialType NVARCHAR(100) NOT NULL, -- License, Certification, Board Certification, etc.
        CredentialNumber NVARCHAR(100) NOT NULL,
        IssuingOrganization NVARCHAR(200) NULL,
        IssueDate DATE NULL,
        ExpirationDate DATE NULL,
        StateIssued NVARCHAR(2) NULL,
        Status NVARCHAR(50) DEFAULT 'Active',
        IsPrimary BIT DEFAULT 0,
        VerificationDate DATETIME2 NULL,
        VerifiedBy NVARCHAR(100) NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (ProviderID) REFERENCES cred.Providers(ProviderID) ON DELETE CASCADE
    );
    PRINT 'Table cred.Credentials created successfully';
END
GO

-- =============================================
-- Table: Entities
-- Purpose: Store entity/organization information
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.Entities') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.Entities (
        EntityID INT IDENTITY(1,1) PRIMARY KEY,
        EntityName NVARCHAR(255) NOT NULL,
        EntityType NVARCHAR(100) NULL, -- Hospital, Clinic, Group Practice, etc.
        TaxID NVARCHAR(20) NULL UNIQUE,
        NPI NVARCHAR(10) NULL UNIQUE,
        AddressLine1 NVARCHAR(255) NULL,
        AddressLine2 NVARCHAR(255) NULL,
        City NVARCHAR(100) NULL,
        State NVARCHAR(2) NULL,
        ZipCode NVARCHAR(10) NULL,
        PhoneNumber NVARCHAR(20) NULL,
        EmailAddress NVARCHAR(255) NULL,
        Status NVARCHAR(50) DEFAULT 'Active',
        AccreditationStatus NVARCHAR(100) NULL,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE(),
        IsActive BIT DEFAULT 1
    );
    PRINT 'Table cred.Entities created successfully';
END
GO

-- Add Foreign Key Constraint for Provider-Entity relationship
IF NOT EXISTS (SELECT * FROM sys.foreign_keys WHERE name = 'FK_Providers_Entities')
BEGIN
    ALTER TABLE cred.Providers
    ADD CONSTRAINT FK_Providers_Entities
    FOREIGN KEY (EntityID) REFERENCES cred.Entities(EntityID);
    PRINT 'Foreign key FK_Providers_Entities added';
END
GO

-- =============================================
-- Table: ValidationRules
-- Purpose: Metadata about validation rules
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.ValidationRules') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.ValidationRules (
        RuleID INT IDENTITY(1,1) PRIMARY KEY,
        RuleCode NVARCHAR(50) NOT NULL UNIQUE,
        RuleName NVARCHAR(255) NOT NULL,
        RuleDescription NVARCHAR(MAX) NULL,
        RuleCategory NVARCHAR(100) NULL, -- Provider, Credential, Entity, Cross-Entity
        RuleType NVARCHAR(50) NULL, -- Data Quality, Business Logic, Compliance
        Severity NVARCHAR(20) DEFAULT 'Medium', -- Low, Medium, High, Critical
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME2 DEFAULT GETDATE(),
        ModifiedDate DATETIME2 DEFAULT GETDATE()
    );
    PRINT 'Table cred.ValidationRules created successfully';
END
GO

-- =============================================
-- Table: ValidationResults
-- Purpose: Store validation check results
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.ValidationResults') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.ValidationResults (
        ValidationResultID BIGINT IDENTITY(1,1) PRIMARY KEY,
        RuleID INT NOT NULL,
        RuleCode NVARCHAR(50) NOT NULL,
        ValidationDate DATETIME2 DEFAULT GETDATE(),
        ValidationRunID INT NULL, -- Groups validations from same run
        EntityType NVARCHAR(50) NULL, -- Provider, Credential, Entity
        EntityID INT NULL, -- ID of the entity being validated
        RecordID NVARCHAR(100) NULL, -- Specific record identifier (NPI, CredentialNumber, etc.)
        ValidationStatus NVARCHAR(20) NOT NULL, -- Pass, Fail, Warning
        ErrorMessage NVARCHAR(MAX) NULL,
        ErrorDetails NVARCHAR(MAX) NULL,
        FieldName NVARCHAR(100) NULL,
        FieldValue NVARCHAR(500) NULL,
        Severity NVARCHAR(20) NULL,
        Resolved BIT DEFAULT 0,
        ResolvedDate DATETIME2 NULL,
        ResolvedBy NVARCHAR(100) NULL,
        ResolutionNotes NVARCHAR(MAX) NULL,
        FOREIGN KEY (RuleID) REFERENCES cred.ValidationRules(RuleID)
    );
    PRINT 'Table cred.ValidationResults created successfully';
END
GO

-- =============================================
-- Table: ValidationRunLog
-- Purpose: Track validation execution runs
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.ValidationRunLog') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.ValidationRunLog (
        RunID INT IDENTITY(1,1) PRIMARY KEY,
        RunStartTime DATETIME2 DEFAULT GETDATE(),
        RunEndTime DATETIME2 NULL,
        RunStatus NVARCHAR(20) NULL, -- Running, Completed, Failed
        TotalRulesRun INT DEFAULT 0,
        TotalRecordsValidated INT DEFAULT 0,
        TotalFailures INT DEFAULT 0,
        TotalWarnings INT DEFAULT 0,
        TotalPasses INT DEFAULT 0,
        ExecutionTimeSeconds INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL,
        RunType NVARCHAR(50) DEFAULT 'Scheduled' -- Scheduled, Manual, OnDemand
    );
    PRINT 'Table cred.ValidationRunLog created successfully';
END
GO

-- =============================================
-- Table: DataRefreshLog
-- Purpose: Track data refresh operations
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.DataRefreshLog') AND type in (N'U'))
BEGIN
    CREATE TABLE cred.DataRefreshLog (
        RefreshID INT IDENTITY(1,1) PRIMARY KEY,
        RefreshStartTime DATETIME2 DEFAULT GETDATE(),
        RefreshEndTime DATETIME2 NULL,
        RefreshStatus NVARCHAR(20) NULL, -- Running, Completed, Failed
        SourceSystem NVARCHAR(100) NULL,
        RecordsProcessed INT DEFAULT 0,
        RecordsInserted INT DEFAULT 0,
        RecordsUpdated INT DEFAULT 0,
        RecordsDeleted INT DEFAULT 0,
        ExecutionTimeSeconds INT NULL,
        ErrorMessage NVARCHAR(MAX) NULL
    );
    PRINT 'Table cred.DataRefreshLog created successfully';
END
GO

PRINT 'All tables created successfully';
GO

