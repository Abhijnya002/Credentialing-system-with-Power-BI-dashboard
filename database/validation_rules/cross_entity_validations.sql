-- Cross-Entity Validation Rules (15+ Rules)
-- Business Logic Validations Across Providers, Credentials, and Entities

USE CredentialingDB;
GO

-- =============================================
-- Stored Procedure: Run Cross-Entity Validations
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.sp_RunCrossEntityValidations') AND type in (N'P', N'PC'))
    DROP PROCEDURE cred.sp_RunCrossEntityValidations;
GO

CREATE PROCEDURE cred.sp_RunCrossEntityValidations
    @ValidationRunID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RuleID INT;
    
    -- Rule CROSS001: Provider NPI should not match Entity NPI
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS001');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS001', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN e.EntityID IS NOT NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN e.EntityID IS NOT NULL THEN 'Provider NPI should not match an Entity NPI' ELSE NULL END,
           'High'
    FROM cred.Providers p
    LEFT JOIN cred.Entities e ON p.NPI = e.NPI
    WHERE p.IsActive = 1 AND p.NPI IS NOT NULL;
    
    -- Rule CROSS002: Provider EntityID must reference an Active Entity
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS002');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CROSS002', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.EntityID IS NOT NULL AND (e.EntityID IS NULL OR e.IsActive = 0 OR e.Status != 'Active') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.EntityID IS NOT NULL AND (e.EntityID IS NULL OR e.IsActive = 0 OR e.Status != 'Active') THEN 'Provider EntityID must reference an Active Entity' ELSE NULL END,
           'EntityID', 'High'
    FROM cred.Providers p
    LEFT JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.EntityID IS NOT NULL;
    
    -- Rule CROSS003: Provider State should match Entity State if EntityID is provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS003');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS003', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.State IS NOT NULL AND e.State IS NOT NULL AND p.State != e.State THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.State IS NOT NULL AND e.State IS NOT NULL AND p.State != e.State THEN 'Provider State does not match Entity State' ELSE NULL END,
           'Low'
    FROM cred.Providers p
    INNER JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.State IS NOT NULL AND e.State IS NOT NULL;
    
    -- Rule CROSS004: Provider should have at least one Active credential if Provider Status is Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS004');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS004', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Active Provider must have at least one Active credential' ELSE NULL END,
           'High'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active'
    WHERE p.IsActive = 1 AND p.Status = 'Active';
    
    -- Rule CROSS005: Credential StateIssued should match Provider State for State License
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS005');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS005', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN c.CredentialType LIKE '%License%' AND c.StateIssued IS NOT NULL AND p.State IS NOT NULL AND c.StateIssued != p.State THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN c.CredentialType LIKE '%License%' AND c.StateIssued IS NOT NULL AND p.State IS NOT NULL AND c.StateIssued != p.State THEN 'Credential StateIssued does not match Provider State for License type' ELSE NULL END,
           'Medium'
    FROM cred.Credentials c
    INNER JOIN cred.Providers p ON c.ProviderID = p.ProviderID
    WHERE c.CredentialType LIKE '%License%' AND c.StateIssued IS NOT NULL AND p.State IS NOT NULL;
    
    -- Rule CROSS006: Provider should have at least one Primary credential
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS006');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS006', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Active Provider should have at least one Primary credential' ELSE NULL END,
           'Medium'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.IsPrimary = 1
    WHERE p.IsActive = 1 AND p.Status = 'Active';
    
    -- Rule CROSS007: Expired credentials should not be associated with Active providers
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS007');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS007', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN p.Status = 'Active' AND c.ExpirationDate IS NOT NULL AND c.ExpirationDate < GETDATE() AND c.Status != 'Expired' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.ExpirationDate IS NOT NULL AND c.ExpirationDate < GETDATE() AND c.Status != 'Expired' THEN 'Expired credentials associated with Active providers should have Status = Expired' ELSE NULL END,
           'High'
    FROM cred.Credentials c
    INNER JOIN cred.Providers p ON c.ProviderID = p.ProviderID
    WHERE p.Status = 'Active' AND c.ExpirationDate IS NOT NULL;
    
    -- Rule CROSS008: Entity should have at least one associated Provider if Entity Status is Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS008');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS008', @ValidationRunID, 'Entity', e.EntityID, e.NPI,
           CASE WHEN e.Status = 'Active' AND p.ProviderID IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN e.Status = 'Active' AND p.ProviderID IS NULL THEN 'Active Entity should have at least one associated Provider' ELSE NULL END,
           'Low'
    FROM cred.Entities e
    LEFT JOIN cred.Providers p ON e.EntityID = p.EntityID AND p.IsActive = 1
    WHERE e.IsActive = 1 AND e.Status = 'Active';
    
    -- Rule CROSS009: Provider CreatedDate should not be before Entity CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS009');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS009', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.EntityID IS NOT NULL AND p.CreatedDate < e.CreatedDate THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.EntityID IS NOT NULL AND p.CreatedDate < e.CreatedDate THEN 'Provider CreatedDate should not be before Entity CreatedDate' ELSE NULL END,
           'Low'
    FROM cred.Providers p
    INNER JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.EntityID IS NOT NULL;
    
    -- Rule CROSS010: Credential IssueDate should not be before Provider CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS010');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS010', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN c.IssueDate IS NOT NULL AND c.IssueDate < CAST(p.CreatedDate AS DATE) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN c.IssueDate IS NOT NULL AND c.IssueDate < CAST(p.CreatedDate AS DATE) THEN 'Credential IssueDate should not be before Provider CreatedDate' ELSE NULL END,
           'Low'
    FROM cred.Credentials c
    INNER JOIN cred.Providers p ON c.ProviderID = p.ProviderID
    WHERE c.IssueDate IS NOT NULL;
    
    -- Rule CROSS011: Provider with Suspended status should not have Active credentials
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS011');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS011', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Suspended' AND c.CredentialID IS NOT NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Suspended' AND c.CredentialID IS NOT NULL THEN 'Suspended Provider should not have Active credentials' ELSE NULL END,
           'Medium'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active'
    WHERE p.IsActive = 1 AND p.Status = 'Suspended';
    
    -- Rule CROSS012: Provider with Terminated status should not have Active credentials
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS012');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS012', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Terminated' AND c.CredentialID IS NOT NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Terminated' AND c.CredentialID IS NOT NULL THEN 'Terminated Provider should not have Active credentials' ELSE NULL END,
           'High'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active'
    WHERE p.IsActive = 1 AND p.Status = 'Terminated';
    
    -- Rule CROSS013: Credentials expiring within 60 days for Active providers should be flagged
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS013');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS013', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN p.Status = 'Active' AND c.Status = 'Active' AND c.ExpirationDate IS NOT NULL AND c.ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 60, GETDATE()) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.Status = 'Active' AND c.ExpirationDate IS NOT NULL AND c.ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 60, GETDATE()) THEN 'Active Provider has credential expiring within 60 days' ELSE NULL END,
           'Medium'
    FROM cred.Credentials c
    INNER JOIN cred.Providers p ON c.ProviderID = p.ProviderID
    WHERE p.Status = 'Active' AND c.Status = 'Active' AND c.ExpirationDate IS NOT NULL;
    
    -- Rule CROSS014: Provider Email domain should match Entity Email domain if EntityID is provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS014');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS014', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.EmailAddress IS NOT NULL AND e.EmailAddress IS NOT NULL 
                AND SUBSTRING(p.EmailAddress, CHARINDEX('@', p.EmailAddress) + 1, LEN(p.EmailAddress)) != 
                    SUBSTRING(e.EmailAddress, CHARINDEX('@', e.EmailAddress) + 1, LEN(e.EmailAddress))
                THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.EmailAddress IS NOT NULL AND e.EmailAddress IS NOT NULL 
                AND SUBSTRING(p.EmailAddress, CHARINDEX('@', p.EmailAddress) + 1, LEN(p.EmailAddress)) != 
                    SUBSTRING(e.EmailAddress, CHARINDEX('@', e.EmailAddress) + 1, LEN(e.EmailAddress))
                THEN 'Provider Email domain does not match Entity Email domain' ELSE NULL END,
           'Low'
    FROM cred.Providers p
    INNER JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.EmailAddress IS NOT NULL AND e.EmailAddress IS NOT NULL;
    
    -- Rule CROSS015: Provider ZipCode should match Entity ZipCode if EntityID is provided and both are present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS015');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS015', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.ZipCode IS NOT NULL AND e.ZipCode IS NOT NULL AND REPLACE(p.ZipCode, '-', '') != REPLACE(e.ZipCode, '-', '') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.ZipCode IS NOT NULL AND e.ZipCode IS NOT NULL AND REPLACE(p.ZipCode, '-', '') != REPLACE(e.ZipCode, '-', '') THEN 'Provider ZipCode does not match Entity ZipCode' ELSE NULL END,
           'Low'
    FROM cred.Providers p
    INNER JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.ZipCode IS NOT NULL AND e.ZipCode IS NOT NULL;
    
    -- Rule CROSS016: Provider should have at least one credential with expiration date more than 30 days away if Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS016');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS016', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Active' AND (c.CredentialID IS NULL OR c.ExpirationDate IS NULL OR c.ExpirationDate < DATEADD(DAY, 30, GETDATE())) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND (c.CredentialID IS NULL OR c.ExpirationDate IS NULL OR c.ExpirationDate < DATEADD(DAY, 30, GETDATE())) THEN 'Active Provider should have at least one credential valid for more than 30 days' ELSE NULL END,
           'Medium'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active' AND c.ExpirationDate > DATEADD(DAY, 30, GETDATE())
    WHERE p.IsActive = 1 AND p.Status = 'Active';
    
    -- Rule CROSS017: Entity with Inactive status should not have Active providers
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CROSS017');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CROSS017', @ValidationRunID, 'Entity', e.EntityID, e.NPI,
           CASE WHEN e.Status IN ('Inactive', 'Suspended', 'Terminated') AND p.ProviderID IS NOT NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN e.Status IN ('Inactive', 'Suspended', 'Terminated') AND p.ProviderID IS NOT NULL THEN 'Inactive Entity should not have Active providers' ELSE NULL END,
           'Medium'
    FROM cred.Entities e
    LEFT JOIN cred.Providers p ON e.EntityID = p.EntityID AND p.Status = 'Active' AND p.IsActive = 1
    WHERE e.IsActive = 1 AND e.Status IN ('Inactive', 'Suspended', 'Terminated');
    
END
GO

PRINT 'Stored procedure cred.sp_RunCrossEntityValidations created successfully';
GO

