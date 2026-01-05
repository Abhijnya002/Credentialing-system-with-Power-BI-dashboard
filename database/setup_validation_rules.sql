-- Setup Script: Create All Validation Rules and Stored Procedures
-- Run this script after creating the database schema
-- This will populate validation rules and create all stored procedures

USE CredentialingDB;
GO


PRINT 'Starting Validation Rules Setup';

GO

-- Step 1: Populate Validation Rules
PRINT 'Step 1: Populating Validation Rules...';
:r database/validation_rules/populate_validation_rules.sql
GO

-- Step 2: Create Provider Validation Stored Procedure
PRINT 'Step 2: Creating Provider Validation Stored Procedure...';
:r database/validation_rules/provider_validations.sql
GO

-- Step 3: Create Credential Validation Stored Procedure
PRINT 'Step 3: Creating Credential Validation Stored Procedure...';
:r database/validation_rules/credential_validations.sql
GO

-- Step 4: Create Entity Validation Stored Procedure
PRINT 'Step 4: Creating Entity Validation Stored Procedure...';
:r database/validation_rules/entity_validations.sql
GO

-- Step 5: Create Cross-Entity Validation Stored Procedure
PRINT 'Step 5: Creating Cross-Entity Validation Stored Procedure...';
:r database/validation_rules/cross_entity_validations.sql
GO

-- Step 6: Create Master Validation Runner Stored Procedure
PRINT 'Step 6: Creating Master Validation Runner Stored Procedure...';
:r database/validation_rules/master_validation_runner.sql
GO


PRINT 'Validation Rules Setup Completed';

GO

-- Verify setup
SELECT 
    RuleCategory,
    COUNT(*) as RuleCount
FROM cred.ValidationRules
WHERE IsActive = 1
GROUP BY RuleCategory
ORDER BY RuleCategory;
GO

PRINT 'Setup verification complete. Total validation rules: ' + 
      CAST((SELECT COUNT(*) FROM cred.ValidationRules WHERE IsActive = 1) AS NVARCHAR(10));
GO

