-- Credential Validation Rules (40 Rules)
-- Data Quality and Business Logic Validations for Credentials

USE CredentialingDB;
GO

-- =============================================
-- Stored Procedure: Run Credential Validations
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.sp_RunCredentialValidations') AND type in (N'P', N'PC'))
    DROP PROCEDURE cred.sp_RunCredentialValidations;
GO

CREATE PROCEDURE cred.sp_RunCredentialValidations
    @ValidationRunID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RuleID INT;
    
    -- Rule CRED001: ProviderID is required
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED001');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED001', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ProviderID IS NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ProviderID IS NULL THEN 'ProviderID is required' ELSE NULL END,
           'ProviderID', 'Critical'
    FROM cred.Credentials;
    
    -- Rule CRED002: CredentialType is required
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED002');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED002', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialType IS NULL OR LTRIM(RTRIM(CredentialType)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CredentialType IS NULL OR LTRIM(RTRIM(CredentialType)) = '' THEN 'CredentialType is required' ELSE NULL END,
           'CredentialType', CredentialType, 'High'
    FROM cred.Credentials;
    
    -- Rule CRED003: CredentialNumber is required
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED003');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED003', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialNumber IS NULL OR LTRIM(RTRIM(CredentialNumber)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CredentialNumber IS NULL OR LTRIM(RTRIM(CredentialNumber)) = '' THEN 'CredentialNumber is required' ELSE NULL END,
           'CredentialNumber', CredentialNumber, 'High'
    FROM cred.Credentials;
    
    -- Rule CRED004: ProviderID must reference valid Provider
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED004');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED004', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN p.ProviderID IS NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.ProviderID IS NULL THEN 'ProviderID does not reference a valid Provider' ELSE NULL END,
           'ProviderID', CAST(c.ProviderID AS NVARCHAR(10)), 'High'
    FROM cred.Credentials c
    LEFT JOIN cred.Providers p ON c.ProviderID = p.ProviderID
    WHERE c.ProviderID IS NOT NULL;
    
    -- Rule CRED005: ExpirationDate must be after IssueDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED005');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED005', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL AND ExpirationDate <= IssueDate THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL AND ExpirationDate <= IssueDate THEN 'ExpirationDate must be after IssueDate' ELSE NULL END,
           'High'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL;
    
    -- Rule CRED006: Expired credentials should have Status = 'Expired'
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED006');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED006', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate < GETDATE() AND Status != 'Expired' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate < GETDATE() AND Status != 'Expired' THEN 'Expired credentials should have Status = Expired' ELSE NULL END,
           'Status', Status, 'High'
    FROM cred.Credentials
    WHERE ExpirationDate IS NOT NULL;
    
    -- Rule CRED007: ExpirationDate cannot be more than 20 years in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED007');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED007', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate > DATEADD(YEAR, 20, GETDATE()) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate > DATEADD(YEAR, 20, GETDATE()) THEN 'ExpirationDate cannot be more than 20 years in the future' ELSE NULL END,
           'ExpirationDate', 'Medium'
    FROM cred.Credentials
    WHERE ExpirationDate IS NOT NULL;
    
    -- Rule CRED008: IssueDate cannot be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED008');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED008', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND IssueDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND IssueDate > GETDATE() THEN 'IssueDate cannot be in the future' ELSE NULL END,
           'IssueDate', 'High'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL;
    
    -- Rule CRED009: IssueDate cannot be more than 50 years in the past
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED009');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED009', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND IssueDate < DATEADD(YEAR, -50, GETDATE()) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND IssueDate < DATEADD(YEAR, -50, GETDATE()) THEN 'IssueDate cannot be more than 50 years in the past' ELSE NULL END,
           'IssueDate', 'Medium'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL;
    
    -- Rule CRED010: Status must be valid value
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED010');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED010', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Expired', 'Suspended', 'Revoked', 'Pending') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Expired', 'Suspended', 'Revoked', 'Pending') THEN 'Status must be one of: Active, Inactive, Expired, Suspended, Revoked, Pending' ELSE NULL END,
           'Status', Status, 'High'
    FROM cred.Credentials;
    
    -- Rule CRED011: Only one credential per Provider can be marked as Primary for same CredentialType
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED011');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED011', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN c.IsPrimary = 1 AND dup_count.Count > 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN c.IsPrimary = 1 AND dup_count.Count > 1 THEN 'Only one credential per Provider can be Primary for the same CredentialType' ELSE NULL END,
           'High'
    FROM cred.Credentials c
    INNER JOIN (SELECT ProviderID, CredentialType, COUNT(*) as Count 
                FROM cred.Credentials 
                WHERE IsPrimary = 1 
                GROUP BY ProviderID, CredentialType 
                HAVING COUNT(*) > 1) dup_count
        ON c.ProviderID = dup_count.ProviderID AND c.CredentialType = dup_count.CredentialType
    WHERE c.IsPrimary = 1;
    
    -- Rule CRED012: Credentials expiring within 30 days should be flagged
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED012');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED012', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE()) AND Status = 'Active' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE()) AND Status = 'Active' THEN 'Credential expires within 30 days' ELSE NULL END,
           'Medium'
    FROM cred.Credentials
    WHERE ExpirationDate IS NOT NULL AND Status = 'Active';
    
    -- Rule CRED013: Credentials expiring within 90 days should be flagged
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED013');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED013', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate BETWEEN DATEADD(DAY, 30, GETDATE()) AND DATEADD(DAY, 90, GETDATE()) AND Status = 'Active' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate BETWEEN DATEADD(DAY, 30, GETDATE()) AND DATEADD(DAY, 90, GETDATE()) AND Status = 'Active' THEN 'Credential expires within 90 days' ELSE NULL END,
           'Low'
    FROM cred.Credentials
    WHERE ExpirationDate IS NOT NULL AND Status = 'Active';
    
    -- Rule CRED014: IssuingOrganization should be provided for most credential types
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED014');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED014', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialType IN ('License', 'Certification', 'Board Certification') AND (IssuingOrganization IS NULL OR LTRIM(RTRIM(IssuingOrganization)) = '') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN CredentialType IN ('License', 'Certification', 'Board Certification') AND (IssuingOrganization IS NULL OR LTRIM(RTRIM(IssuingOrganization)) = '') THEN 'IssuingOrganization should be provided for this CredentialType' ELSE NULL END,
           'IssuingOrganization', 'Medium'
    FROM cred.Credentials;
    
    -- Rule CRED015: StateIssued should be 2 characters if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED015');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED015', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN StateIssued IS NOT NULL AND LEN(StateIssued) != 2 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN StateIssued IS NOT NULL AND LEN(StateIssued) != 2 THEN 'StateIssued must be 2 characters' ELSE NULL END,
           'StateIssued', StateIssued, 'Medium'
    FROM cred.Credentials
    WHERE StateIssued IS NOT NULL;
    
    -- Rule CRED016: StateIssued should be uppercase
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED016');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED016', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN StateIssued IS NOT NULL AND StateIssued != UPPER(StateIssued) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN StateIssued IS NOT NULL AND StateIssued != UPPER(StateIssued) THEN 'StateIssued should be uppercase' ELSE NULL END,
           'StateIssued', StateIssued, 'Low'
    FROM cred.Credentials
    WHERE StateIssued IS NOT NULL;
    
    -- Rule CRED017: VerificationDate cannot be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED017');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED017', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN VerificationDate IS NOT NULL AND VerificationDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN VerificationDate IS NOT NULL AND VerificationDate > GETDATE() THEN 'VerificationDate cannot be in the future' ELSE NULL END,
           'VerificationDate', 'Medium'
    FROM cred.Credentials
    WHERE VerificationDate IS NOT NULL;
    
    -- Rule CRED018: VerifiedBy should be provided if VerificationDate is present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED018');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED018', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN VerificationDate IS NOT NULL AND (VerifiedBy IS NULL OR LTRIM(RTRIM(VerifiedBy)) = '') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN VerificationDate IS NOT NULL AND (VerifiedBy IS NULL OR LTRIM(RTRIM(VerifiedBy)) = '') THEN 'VerifiedBy should be provided when VerificationDate is present' ELSE NULL END,
           'VerifiedBy', 'Low'
    FROM cred.Credentials
    WHERE VerificationDate IS NOT NULL;
    
    -- Rule CRED019: ModifiedDate should not be before CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED019');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED019', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ModifiedDate < CreatedDate THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate < CreatedDate THEN 'ModifiedDate cannot be before CreatedDate' ELSE NULL END,
           'Low'
    FROM cred.Credentials;
    
    -- Rule CRED020: CreatedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED020');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED020', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CreatedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CreatedDate > GETDATE() THEN 'CreatedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Credentials;
    
    -- Rule CRED021: ModifiedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED021');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED021', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ModifiedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate > GETDATE() THEN 'ModifiedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Credentials;
    
    -- Rule CRED022: CredentialNumber should be unique per CredentialType and Provider
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED022');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED022', @ValidationRunID, 'Credential', c.CredentialID, c.CredentialNumber,
           CASE WHEN dup_count.Count > 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN dup_count.Count > 1 THEN 'CredentialNumber should be unique per Provider and CredentialType' ELSE NULL END,
           'High'
    FROM cred.Credentials c
    INNER JOIN (SELECT ProviderID, CredentialType, CredentialNumber, COUNT(*) as Count 
                FROM cred.Credentials 
                GROUP BY ProviderID, CredentialType, CredentialNumber 
                HAVING COUNT(*) > 1) dup_count
        ON c.ProviderID = dup_count.ProviderID 
        AND c.CredentialType = dup_count.CredentialType 
        AND c.CredentialNumber = dup_count.CredentialNumber;
    
    -- Rule CRED023: Active credentials should have valid expiration date
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED023');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED023', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status = 'Active' AND ExpirationDate IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND ExpirationDate IS NULL THEN 'Active credentials should have an ExpirationDate' ELSE NULL END,
           'Medium'
    FROM cred.Credentials
    WHERE Status = 'Active';
    
    -- Rule CRED024: CredentialNumber should not contain only spaces
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED024');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED024', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialNumber IS NOT NULL AND LTRIM(RTRIM(CredentialNumber)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CredentialNumber IS NOT NULL AND LTRIM(RTRIM(CredentialNumber)) = '' THEN 'CredentialNumber cannot contain only spaces' ELSE NULL END,
           'CredentialNumber', 'High'
    FROM cred.Credentials;
    
    -- Rule CRED025: CredentialType should not contain only spaces
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED025');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED025', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialType IS NOT NULL AND LTRIM(RTRIM(CredentialType)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CredentialType IS NOT NULL AND LTRIM(RTRIM(CredentialType)) = '' THEN 'CredentialType cannot contain only spaces' ELSE NULL END,
           'CredentialType', 'High'
    FROM cred.Credentials;
    
    -- Rule CRED026: License credentials should have StateIssued
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED026');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED026', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialType LIKE '%License%' AND (StateIssued IS NULL OR LTRIM(RTRIM(StateIssued)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CredentialType LIKE '%License%' AND (StateIssued IS NULL OR LTRIM(RTRIM(StateIssued)) = '') THEN 'License credentials should have StateIssued' ELSE NULL END,
           'StateIssued', 'High'
    FROM cred.Credentials;
    
    -- Rule CRED027: ExpirationDate cannot be before IssueDate by more than 1 day (data entry error check)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED027');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED027', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL AND DATEDIFF(DAY, IssueDate, ExpirationDate) < 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL AND DATEDIFF(DAY, IssueDate, ExpirationDate) < 1 THEN 'ExpirationDate must be at least 1 day after IssueDate' ELSE NULL END,
           'High'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL AND ExpirationDate IS NOT NULL;
    
    -- Rule CRED028: CredentialNumber length should be reasonable (1-50 characters)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED028');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED028', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN LEN(LTRIM(RTRIM(CredentialNumber))) < 1 OR LEN(LTRIM(RTRIM(CredentialNumber))) > 50 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN LEN(LTRIM(RTRIM(CredentialNumber))) < 1 OR LEN(LTRIM(RTRIM(CredentialNumber))) > 50 THEN 'CredentialNumber length should be between 1 and 50 characters' ELSE NULL END,
           'CredentialNumber', 'Low'
    FROM cred.Credentials
    WHERE CredentialNumber IS NOT NULL;
    
    -- Rule CRED029: IssuingOrganization length should be reasonable
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED029');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED029', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssuingOrganization IS NOT NULL AND LEN(LTRIM(RTRIM(IssuingOrganization))) > 200 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN IssuingOrganization IS NOT NULL AND LEN(LTRIM(RTRIM(IssuingOrganization))) > 200 THEN 'IssuingOrganization length exceeds maximum (200 characters)' ELSE NULL END,
           'IssuingOrganization', 'Low'
    FROM cred.Credentials
    WHERE IssuingOrganization IS NOT NULL;
    
    -- Rule CRED030: VerificationDate should be after IssueDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED030');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED030', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND VerificationDate IS NOT NULL AND VerificationDate < IssueDate THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND VerificationDate IS NOT NULL AND VerificationDate < IssueDate THEN 'VerificationDate should be after IssueDate' ELSE NULL END,
           'Low'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL AND VerificationDate IS NOT NULL;
    
    -- Rule CRED031: Active credentials should not be expired
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED031');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED031', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status = 'Active' AND ExpirationDate IS NOT NULL AND ExpirationDate < GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND ExpirationDate IS NOT NULL AND ExpirationDate < GETDATE() THEN 'Active credentials cannot be expired' ELSE NULL END,
           'Critical'
    FROM cred.Credentials
    WHERE Status = 'Active' AND ExpirationDate IS NOT NULL;
    
    -- Rule CRED032: Suspended credentials should not be Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED032');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED032', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status = 'Suspended' AND ExpirationDate > GETDATE() THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Suspended' AND ExpirationDate > GETDATE() THEN 'Suspended credentials may need review' ELSE NULL END,
           'Low'
    FROM cred.Credentials
    WHERE Status = 'Suspended' AND ExpirationDate IS NOT NULL;
    
    -- Rule CRED033: Revoked credentials should have Status = 'Revoked'
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED033');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED033', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status != 'Revoked' AND VerifiedBy LIKE '%Revoked%' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status != 'Revoked' AND VerifiedBy LIKE '%Revoked%' THEN 'Credential appears to be revoked but Status is not Revoked' ELSE NULL END,
           'Medium'
    FROM cred.Credentials
    WHERE VerifiedBy IS NOT NULL;
    
    -- Rule CRED034: CredentialType should be from standard list
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED034');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'CRED034', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialType NOT IN ('License', 'Medical License', 'DEA License', 'State License', 'Certification', 'Board Certification', 'Specialty Certification', 'Other') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN CredentialType NOT IN ('License', 'Medical License', 'DEA License', 'State License', 'Certification', 'Board Certification', 'Specialty Certification', 'Other') THEN 'CredentialType should be from standard list' ELSE NULL END,
           'CredentialType', CredentialType, 'Low'
    FROM cred.Credentials;
    
    -- Rule CRED035: Provider should have at least one Active credential
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED035');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED035', @ValidationRunID, 'Credential', NULL, p.NPI,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Active provider should have at least one Active credential' ELSE NULL END,
           'Medium'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active'
    WHERE p.IsActive = 1 AND p.Status = 'Active';
    
    -- Rule CRED036: CredentialNumber should not contain special characters (unless allowed)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED036');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'CRED036', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN CredentialNumber LIKE '%[^A-Za-z0-9\-]%' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN CredentialNumber LIKE '%[^A-Za-z0-9\-]%' THEN 'CredentialNumber contains unexpected special characters' ELSE NULL END,
           'CredentialNumber', 'Low'
    FROM cred.Credentials
    WHERE CredentialNumber IS NOT NULL;
    
    -- Rule CRED037: ExpirationDate cannot be before CreatedDate (logic check)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED037');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED037', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate < CAST(CreatedDate AS DATE) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ExpirationDate IS NOT NULL AND ExpirationDate < CAST(CreatedDate AS DATE) THEN 'ExpirationDate cannot be before record CreatedDate' ELSE NULL END,
           'Medium'
    FROM cred.Credentials
    WHERE ExpirationDate IS NOT NULL;
    
    -- Rule CRED038: IssueDate should not be more than 10 years before CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED038');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED038', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IssueDate IS NOT NULL AND DATEDIFF(YEAR, IssueDate, CreatedDate) > 10 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN IssueDate IS NOT NULL AND DATEDIFF(YEAR, IssueDate, CreatedDate) > 10 THEN 'IssueDate is more than 10 years before record creation date' ELSE NULL END,
           'Low'
    FROM cred.Credentials
    WHERE IssueDate IS NOT NULL;
    
    -- Rule CRED039: Multiple primary credentials of different types allowed, but check for duplicates
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED039');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED039', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN IsPrimary = 1 AND Status != 'Active' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN IsPrimary = 1 AND Status != 'Active' THEN 'Primary credential should typically be Active' ELSE NULL END,
           'Low'
    FROM cred.Credentials
    WHERE IsPrimary = 1;
    
    -- Rule CRED040: Credentials should have been verified within last 5 years if Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'CRED040');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'CRED040', @ValidationRunID, 'Credential', CredentialID, CredentialNumber,
           CASE WHEN Status = 'Active' AND (VerificationDate IS NULL OR DATEDIFF(YEAR, VerificationDate, GETDATE()) > 5) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND (VerificationDate IS NULL OR DATEDIFF(YEAR, VerificationDate, GETDATE()) > 5) THEN 'Active credentials should be verified within last 5 years' ELSE NULL END,
           'Medium'
    FROM cred.Credentials
    WHERE Status = 'Active';
    
END
GO

PRINT 'Stored procedure cred.sp_RunCredentialValidations created successfully';
GO

