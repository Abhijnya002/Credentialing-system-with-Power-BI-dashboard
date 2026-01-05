-- Index Creation Script
-- Optimize queries for validation and reporting

USE CredentialingDB;
GO

-- =============================================
-- Indexes on Providers Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Providers_NPI')
    CREATE NONCLUSTERED INDEX IX_Providers_NPI ON cred.Providers(NPI);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Providers_EntityID')
    CREATE NONCLUSTERED INDEX IX_Providers_EntityID ON cred.Providers(EntityID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Providers_Status')
    CREATE NONCLUSTERED INDEX IX_Providers_Status ON cred.Providers(Status, IsActive);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Providers_Name')
    CREATE NONCLUSTERED INDEX IX_Providers_Name ON cred.Providers(LastName, FirstName);
GO

-- =============================================
-- Indexes on Credentials Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Credentials_ProviderID')
    CREATE NONCLUSTERED INDEX IX_Credentials_ProviderID ON cred.Credentials(ProviderID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Credentials_ExpirationDate')
    CREATE NONCLUSTERED INDEX IX_Credentials_ExpirationDate ON cred.Credentials(ExpirationDate, Status);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Credentials_Type')
    CREATE NONCLUSTERED INDEX IX_Credentials_Type ON cred.Credentials(CredentialType, Status);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Credentials_Number')
    CREATE NONCLUSTERED INDEX IX_Credentials_Number ON cred.Credentials(CredentialNumber, CredentialType);
GO

-- =============================================
-- Indexes on Entities Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Entities_NPI')
    CREATE NONCLUSTERED INDEX IX_Entities_NPI ON cred.Entities(NPI);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Entities_TaxID')
    CREATE NONCLUSTERED INDEX IX_Entities_TaxID ON cred.Entities(TaxID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Entities_Status')
    CREATE NONCLUSTERED INDEX IX_Entities_Status ON cred.Entities(Status, IsActive);
GO

-- =============================================
-- Indexes on ValidationResults Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_RuleID')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_RuleID ON cred.ValidationResults(RuleID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_ValidationDate')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_ValidationDate ON cred.ValidationResults(ValidationDate DESC);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_Status')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_Status ON cred.ValidationResults(ValidationStatus, Resolved);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_Entity')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_Entity ON cred.ValidationResults(EntityType, EntityID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_RunID')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_RunID ON cred.ValidationResults(ValidationRunID);
GO

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationResults_RuleCode')
    CREATE NONCLUSTERED INDEX IX_ValidationResults_RuleCode ON cred.ValidationResults(RuleCode);
GO

-- =============================================
-- Indexes on ValidationRunLog Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_ValidationRunLog_RunStartTime')
    CREATE NONCLUSTERED INDEX IX_ValidationRunLog_RunStartTime ON cred.ValidationRunLog(RunStartTime DESC);
GO

-- =============================================
-- Indexes on DataRefreshLog Table
-- =============================================
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_DataRefreshLog_RefreshStartTime')
    CREATE NONCLUSTERED INDEX IX_DataRefreshLog_RefreshStartTime ON cred.DataRefreshLog(RefreshStartTime DESC);
GO

PRINT 'All indexes created successfully';
GO

