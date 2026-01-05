-- Entity Validation Rules (25 Rules)
-- Data Quality and Business Logic Validations for Entities

USE CredentialingDB;
GO

-- =============================================
-- Stored Procedure: Run Entity Validations
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.sp_RunEntityValidations') AND type in (N'P', N'PC'))
    DROP PROCEDURE cred.sp_RunEntityValidations;
GO

CREATE PROCEDURE cred.sp_RunEntityValidations
    @ValidationRunID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RuleID INT;
    
    -- Rule ENT001: EntityName is required
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT001');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT001', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EntityName IS NULL OR LTRIM(RTRIM(EntityName)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN EntityName IS NULL OR LTRIM(RTRIM(EntityName)) = '' THEN 'EntityName is required' ELSE NULL END,
           'EntityName', EntityName, 'High'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT002: TaxID must be unique if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT002');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT002', @ValidationRunID, 'Entity', e.EntityID, e.NPI,
           CASE WHEN e.TaxID IS NOT NULL AND dup_count.Count > 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN e.TaxID IS NOT NULL AND dup_count.Count > 1 THEN 'TaxID must be unique' ELSE NULL END,
           'TaxID', e.TaxID, 'High'
    FROM cred.Entities e
    INNER JOIN (SELECT TaxID, COUNT(*) as Count FROM cred.Entities WHERE TaxID IS NOT NULL GROUP BY TaxID HAVING COUNT(*) > 1) dup_count
        ON e.TaxID = dup_count.TaxID
    WHERE e.IsActive = 1;
    
    -- Rule ENT003: NPI must be 10 digits if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT003');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT003', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN NPI IS NOT NULL AND (LEN(LTRIM(RTRIM(NPI))) != 10 OR NPI LIKE '%[^0-9]%') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN NPI IS NOT NULL AND (LEN(LTRIM(RTRIM(NPI))) != 10 OR NPI LIKE '%[^0-9]%') THEN 'NPI must be exactly 10 digits' ELSE NULL END,
           'NPI', NPI, 'High'
    FROM cred.Entities
    WHERE IsActive = 1 AND NPI IS NOT NULL;
    
    -- Rule ENT004: NPI must be unique if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT004');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT004', @ValidationRunID, 'Entity', e.EntityID, e.NPI,
           CASE WHEN e.NPI IS NOT NULL AND dup_count.Count > 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN e.NPI IS NOT NULL AND dup_count.Count > 1 THEN 'NPI must be unique' ELSE NULL END,
           'NPI', e.NPI, 'High'
    FROM cred.Entities e
    INNER JOIN (SELECT NPI, COUNT(*) as Count FROM cred.Entities WHERE NPI IS NOT NULL GROUP BY NPI HAVING COUNT(*) > 1) dup_count
        ON e.NPI = dup_count.NPI
    WHERE e.IsActive = 1;
    
    -- Rule ENT005: Email must be valid format
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT005');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT005', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND (EmailAddress NOT LIKE '%@%.%' OR EmailAddress LIKE '@%' OR EmailAddress LIKE '%@' OR CHARINDEX('..', EmailAddress) > 0) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND (EmailAddress NOT LIKE '%@%.%' OR EmailAddress LIKE '@%' OR EmailAddress LIKE '%@' OR CHARINDEX('..', EmailAddress) > 0) THEN 'Email address format is invalid' ELSE NULL END,
           'EmailAddress', EmailAddress, 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL;
    
    -- Rule ENT006: Phone number must be valid format
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT006');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT006', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN PhoneNumber IS NOT NULL AND (LEN(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, '(', ''), ')', ''), '-', ''), ' ', '')) < 10) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN PhoneNumber IS NOT NULL AND (LEN(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, '(', ''), ')', ''), '-', ''), ' ', '')) < 10) THEN 'Phone number must contain at least 10 digits' ELSE NULL END,
           'PhoneNumber', PhoneNumber, 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1 AND PhoneNumber IS NOT NULL;
    
    -- Rule ENT007: State code must be 2 characters if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT007');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT007', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN State IS NOT NULL AND LEN(State) != 2 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN State IS NOT NULL AND LEN(State) != 2 THEN 'State must be 2 characters' ELSE NULL END,
           'State', State, 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1 AND State IS NOT NULL;
    
    -- Rule ENT008: ZIP code must be 5 or 9 digits if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT008');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT008', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN ZipCode IS NOT NULL AND (LEN(REPLACE(ZipCode, '-', '')) NOT IN (5, 9) OR REPLACE(ZipCode, '-', '') LIKE '%[^0-9]%') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ZipCode IS NOT NULL AND (LEN(REPLACE(ZipCode, '-', '')) NOT IN (5, 9) OR REPLACE(ZipCode, '-', '') LIKE '%[^0-9]%') THEN 'ZIP code must be 5 or 9 digits' ELSE NULL END,
           'ZipCode', ZipCode, 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1 AND ZipCode IS NOT NULL;
    
    -- Rule ENT009: Status must be valid value
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT009');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT009', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Pending', 'Suspended', 'Terminated') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Pending', 'Suspended', 'Terminated') THEN 'Status must be one of: Active, Inactive, Pending, Suspended, Terminated' ELSE NULL END,
           'Status', Status, 'High'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT010: Address Line 1 should be provided if other address fields are present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT010');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'ENT010', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN (City IS NOT NULL OR State IS NOT NULL OR ZipCode IS NOT NULL) AND (AddressLine1 IS NULL OR LTRIM(RTRIM(AddressLine1)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (City IS NOT NULL OR State IS NOT NULL OR ZipCode IS NOT NULL) AND (AddressLine1 IS NULL OR LTRIM(RTRIM(AddressLine1)) = '') THEN 'Address Line 1 is required when other address fields are present' ELSE NULL END,
           'AddressLine1', 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT011: City should be provided if State or ZipCode is present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT011');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'ENT011', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN (State IS NOT NULL OR ZipCode IS NOT NULL) AND (City IS NULL OR LTRIM(RTRIM(City)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (State IS NOT NULL OR ZipCode IS NOT NULL) AND (City IS NULL OR LTRIM(RTRIM(City)) = '') THEN 'City is required when State or ZipCode is provided' ELSE NULL END,
           'City', 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT012: State should be provided if City or ZipCode is present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT012');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'ENT012', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN (City IS NOT NULL OR ZipCode IS NOT NULL) AND (State IS NULL OR LTRIM(RTRIM(State)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (City IS NOT NULL OR ZipCode IS NOT NULL) AND (State IS NULL OR LTRIM(RTRIM(State)) = '') THEN 'State is required when City or ZipCode is provided' ELSE NULL END,
           'State', 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT013: ModifiedDate should not be before CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT013');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'ENT013', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN ModifiedDate < CreatedDate THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate < CreatedDate THEN 'ModifiedDate cannot be before CreatedDate' ELSE NULL END,
           'Low'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT014: CreatedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT014');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'ENT014', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN CreatedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CreatedDate > GETDATE() THEN 'CreatedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT015: ModifiedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT015');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'ENT015', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN ModifiedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate > GETDATE() THEN 'ModifiedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT016: EntityName length should be reasonable (2-255 characters)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT016');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT016', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN LEN(LTRIM(RTRIM(EntityName))) < 2 OR LEN(LTRIM(RTRIM(EntityName))) > 255 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN LEN(LTRIM(RTRIM(EntityName))) < 2 OR LEN(LTRIM(RTRIM(EntityName))) > 255 THEN 'EntityName length should be between 2 and 255 characters' ELSE NULL END,
           'EntityName', EntityName, 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND EntityName IS NOT NULL;
    
    -- Rule ENT017: TaxID format should be valid (9 digits, optionally formatted as XX-XXXXXXX)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT017');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT017', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN TaxID IS NOT NULL AND LEN(REPLACE(TaxID, '-', '')) != 9 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN TaxID IS NOT NULL AND LEN(REPLACE(TaxID, '-', '')) != 9 THEN 'TaxID must be 9 digits (format: XX-XXXXXXX or XXXXXXXXX)' ELSE NULL END,
           'TaxID', TaxID, 'High'
    FROM cred.Entities
    WHERE IsActive = 1 AND TaxID IS NOT NULL;
    
    -- Rule ENT018: EntityType should be from standard list
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT018');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT018', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EntityType IS NOT NULL AND EntityType NOT IN ('Hospital', 'Clinic', 'Group Practice', 'Individual Practice', 'Urgent Care', 'Surgery Center', 'Other') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN EntityType IS NOT NULL AND EntityType NOT IN ('Hospital', 'Clinic', 'Group Practice', 'Individual Practice', 'Urgent Care', 'Surgery Center', 'Other') THEN 'EntityType should be from standard list' ELSE NULL END,
           'EntityType', EntityType, 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND EntityType IS NOT NULL;
    
    -- Rule ENT019: State code should be uppercase
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT019');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT019', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN State IS NOT NULL AND State != UPPER(State) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN State IS NOT NULL AND State != UPPER(State) THEN 'State code should be uppercase' ELSE NULL END,
           'State', State, 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND State IS NOT NULL;
    
    -- Rule ENT020: Email domain should be valid
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT020');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT020', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND CHARINDEX('.', SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, LEN(EmailAddress))) = 0 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND CHARINDEX('.', SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, LEN(EmailAddress))) = 0 THEN 'Email domain must contain at least one dot' ELSE NULL END,
           'EmailAddress', EmailAddress, 'Medium'
    FROM cred.Entities
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL AND EmailAddress LIKE '%@%';
    
    -- Rule ENT021: Phone number should not contain letters
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT021');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT021', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN PhoneNumber IS NOT NULL AND PhoneNumber LIKE '%[A-Za-z]%' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN PhoneNumber IS NOT NULL AND PhoneNumber LIKE '%[A-Za-z]%' THEN 'Phone number should not contain letters' ELSE NULL END,
           'PhoneNumber', PhoneNumber, 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND PhoneNumber IS NOT NULL;
    
    -- Rule ENT022: Email should be lowercase (best practice)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT022');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'ENT022', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND EmailAddress != LOWER(EmailAddress) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND EmailAddress != LOWER(EmailAddress) THEN 'Email address should be lowercase' ELSE NULL END,
           'EmailAddress', 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL;
    
    -- Rule ENT023: Active entities should have complete address information
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT023');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'ENT023', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN Status = 'Active' AND (AddressLine1 IS NULL OR City IS NULL OR State IS NULL OR ZipCode IS NULL) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND (AddressLine1 IS NULL OR City IS NULL OR State IS NULL OR ZipCode IS NULL) THEN 'Active entities should have complete address information' ELSE NULL END,
           'Medium'
    FROM cred.Entities
    WHERE IsActive = 1;
    
    -- Rule ENT024: AccreditationStatus should be provided for hospitals
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT024');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'ENT024', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EntityType = 'Hospital' AND (AccreditationStatus IS NULL OR LTRIM(RTRIM(AccreditationStatus)) = '') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN EntityType = 'Hospital' AND (AccreditationStatus IS NULL OR LTRIM(RTRIM(AccreditationStatus)) = '') THEN 'Hospitals should have AccreditationStatus' ELSE NULL END,
           'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND EntityType = 'Hospital';
    
    -- Rule ENT025: EntityName should not contain only numbers
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'ENT025');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'ENT025', @ValidationRunID, 'Entity', EntityID, NPI,
           CASE WHEN EntityName IS NOT NULL AND EntityName NOT LIKE '%[A-Za-z]%' THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN EntityName IS NOT NULL AND EntityName NOT LIKE '%[A-Za-z]%' THEN 'EntityName should contain at least one letter' ELSE NULL END,
           'EntityName', EntityName, 'Low'
    FROM cred.Entities
    WHERE IsActive = 1 AND EntityName IS NOT NULL;
    
END
GO

PRINT 'Stored procedure cred.sp_RunEntityValidations created successfully';
GO

