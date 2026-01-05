-- Provider Validation Rules (35 Rules)
-- Data Quality and Business Logic Validations for Providers

USE CredentialingDB;
GO

-- =============================================
-- Stored Procedure: Run Provider Validations
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.sp_RunProviderValidations') AND type in (N'P', N'PC'))
    DROP PROCEDURE cred.sp_RunProviderValidations;
GO

CREATE PROCEDURE cred.sp_RunProviderValidations
    @ValidationRunID INT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @RuleID INT;
    DECLARE @CurrentTime DATETIME2 = GETDATE();
    
    -- Rule PRV001: NPI must be 10 digits
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV001');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV001', @ValidationRunID, 'Provider', ProviderID, NPI, 
           CASE WHEN LEN(LTRIM(RTRIM(NPI))) != 10 OR NPI LIKE '%[^0-9]%' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN LEN(LTRIM(RTRIM(NPI))) != 10 OR NPI LIKE '%[^0-9]%' THEN 'NPI must be exactly 10 digits' ELSE NULL END,
           'NPI', NPI, 'High'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV002: NPI cannot be null
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV002');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV002', @ValidationRunID, 'Provider', ProviderID, NPI, 
           CASE WHEN NPI IS NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN NPI IS NULL THEN 'NPI is required' ELSE NULL END,
           'NPI', 'Critical'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV003: First Name cannot be null or empty
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV003');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV003', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN FirstName IS NULL OR LTRIM(RTRIM(FirstName)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN FirstName IS NULL OR LTRIM(RTRIM(FirstName)) = '' THEN 'First Name is required' ELSE NULL END,
           'FirstName', FirstName, 'High'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV004: Last Name cannot be null or empty
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV004');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV004', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN LastName IS NULL OR LTRIM(RTRIM(LastName)) = '' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN LastName IS NULL OR LTRIM(RTRIM(LastName)) = '' THEN 'Last Name is required' ELSE NULL END,
           'LastName', LastName, 'High'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV005: Date of Birth must be in the past
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV005');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV005', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN DateOfBirth IS NOT NULL AND DateOfBirth > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN DateOfBirth IS NOT NULL AND DateOfBirth > GETDATE() THEN 'Date of Birth cannot be in the future' ELSE NULL END,
           'DateOfBirth', CAST(DateOfBirth AS NVARCHAR(10)), 'High'
    FROM cred.Providers
    WHERE IsActive = 1 AND DateOfBirth IS NOT NULL;
    
    -- Rule PRV006: Date of Birth must indicate age between 18 and 100
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV006');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV006', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN DateOfBirth IS NOT NULL AND (DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 18 OR DATEDIFF(YEAR, DateOfBirth, GETDATE()) > 100) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN DateOfBirth IS NOT NULL AND (DATEDIFF(YEAR, DateOfBirth, GETDATE()) < 18 OR DATEDIFF(YEAR, DateOfBirth, GETDATE()) > 100) THEN 'Date of Birth indicates invalid age (must be 18-100 years)' ELSE NULL END,
           'DateOfBirth', CAST(DateOfBirth AS NVARCHAR(10)), 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND DateOfBirth IS NOT NULL;
    
    -- Rule PRV007: SSN must be in format XXX-XX-XXXX if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV007');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV007', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN SSN IS NOT NULL AND (LEN(SSN) != 11 OR SSN NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN SSN IS NOT NULL AND (LEN(SSN) != 11 OR SSN NOT LIKE '[0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9][0-9][0-9]') THEN 'SSN must be in format XXX-XX-XXXX' ELSE NULL END,
           'SSN', LEFT(SSN, 3) + '-XX-XXXX', 'High'
    FROM cred.Providers
    WHERE IsActive = 1 AND SSN IS NOT NULL;
    
    -- Rule PRV008: Email must be valid format
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV008');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV008', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND (EmailAddress NOT LIKE '%@%.%' OR EmailAddress LIKE '@%' OR EmailAddress LIKE '%@' OR CHARINDEX('..', EmailAddress) > 0) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND (EmailAddress NOT LIKE '%@%.%' OR EmailAddress LIKE '@%' OR EmailAddress LIKE '%@' OR CHARINDEX('..', EmailAddress) > 0) THEN 'Email address format is invalid' ELSE NULL END,
           'EmailAddress', EmailAddress, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL;
    
    -- Rule PRV009: Phone number must be valid format
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV009');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV009', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN PhoneNumber IS NOT NULL AND (LEN(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, '(', ''), ')', ''), '-', ''), ' ', '')) < 10) THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN PhoneNumber IS NOT NULL AND (LEN(REPLACE(REPLACE(REPLACE(REPLACE(PhoneNumber, '(', ''), ')', ''), '-', ''), ' ', '')) < 10) THEN 'Phone number must contain at least 10 digits' ELSE NULL END,
           'PhoneNumber', PhoneNumber, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND PhoneNumber IS NOT NULL;
    
    -- Rule PRV010: State code must be 2 characters if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV010');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV010', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN State IS NOT NULL AND LEN(State) != 2 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN State IS NOT NULL AND LEN(State) != 2 THEN 'State must be 2 characters' ELSE NULL END,
           'State', State, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND State IS NOT NULL;
    
    -- Rule PRV011: ZIP code must be 5 or 9 digits if provided
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV011');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV011', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN ZipCode IS NOT NULL AND (LEN(REPLACE(ZipCode, '-', '')) NOT IN (5, 9) OR REPLACE(ZipCode, '-', '') LIKE '%[^0-9]%') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ZipCode IS NOT NULL AND (LEN(REPLACE(ZipCode, '-', '')) NOT IN (5, 9) OR REPLACE(ZipCode, '-', '') LIKE '%[^0-9]%') THEN 'ZIP code must be 5 or 9 digits' ELSE NULL END,
           'ZipCode', ZipCode, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND ZipCode IS NOT NULL;
    
    -- Rule PRV012: Status must be valid value
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV012');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV012', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Pending', 'Suspended', 'Terminated') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN Status NOT IN ('Active', 'Inactive', 'Pending', 'Suspended', 'Terminated') THEN 'Status must be one of: Active, Inactive, Pending, Suspended, Terminated' ELSE NULL END,
           'Status', Status, 'High'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV013: NPI must be unique (check for duplicates)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV013');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV013', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN dup_count.Count > 1 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN dup_count.Count > 1 THEN 'Duplicate NPI found' ELSE NULL END,
           'NPI', p.NPI, 'Critical'
    FROM cred.Providers p
    INNER JOIN (SELECT NPI, COUNT(*) as Count FROM cred.Providers GROUP BY NPI HAVING COUNT(*) > 1) dup_count
        ON p.NPI = dup_count.NPI
    WHERE p.IsActive = 1;
    
    -- Rule PRV014: Specialty should not be empty if provider is active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV014');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV014', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN Status = 'Active' AND (Specialty IS NULL OR LTRIM(RTRIM(Specialty)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND (Specialty IS NULL OR LTRIM(RTRIM(Specialty)) = '') THEN 'Specialty is required for active providers' ELSE NULL END,
           'Specialty', Specialty, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV015: First Name should not contain numbers
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV015');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV015', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN FirstName LIKE '%[0-9]%' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN FirstName LIKE '%[0-9]%' THEN 'First Name should not contain numbers' ELSE NULL END,
           'FirstName', FirstName, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND FirstName IS NOT NULL;
    
    -- Rule PRV016: Last Name should not contain numbers
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV016');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV016', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN LastName LIKE '%[0-9]%' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN LastName LIKE '%[0-9]%' THEN 'Last Name should not contain numbers' ELSE NULL END,
           'LastName', LastName, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND LastName IS NOT NULL;
    
    -- Rule PRV017: Address Line 1 should be provided if other address fields are present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV017');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV017', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN (City IS NOT NULL OR State IS NOT NULL OR ZipCode IS NOT NULL) AND (AddressLine1 IS NULL OR LTRIM(RTRIM(AddressLine1)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (City IS NOT NULL OR State IS NOT NULL OR ZipCode IS NOT NULL) AND (AddressLine1 IS NULL OR LTRIM(RTRIM(AddressLine1)) = '') THEN 'Address Line 1 is required when other address fields are present' ELSE NULL END,
           'AddressLine1', 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV018: City should be provided if State or ZipCode is present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV018');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV018', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN (State IS NOT NULL OR ZipCode IS NOT NULL) AND (City IS NULL OR LTRIM(RTRIM(City)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (State IS NOT NULL OR ZipCode IS NOT NULL) AND (City IS NULL OR LTRIM(RTRIM(City)) = '') THEN 'City is required when State or ZipCode is provided' ELSE NULL END,
           'City', 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV019: State should be provided if City or ZipCode is present
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV019');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV019', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN (City IS NOT NULL OR ZipCode IS NOT NULL) AND (State IS NULL OR LTRIM(RTRIM(State)) = '') THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN (City IS NOT NULL OR ZipCode IS NOT NULL) AND (State IS NULL OR LTRIM(RTRIM(State)) = '') THEN 'State is required when City or ZipCode is provided' ELSE NULL END,
           'State', 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV020: ModifiedDate should not be before CreatedDate
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV020');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'PRV020', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN ModifiedDate < CreatedDate THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate < CreatedDate THEN 'ModifiedDate cannot be before CreatedDate' ELSE NULL END,
           'Low'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV021: Provider with Active status should have EntityID if EntityID is required
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV021');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV021', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN Status = 'Active' AND EntityID IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND EntityID IS NULL THEN 'Active provider should be associated with an Entity' ELSE NULL END,
           'EntityID', 'Low'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV022: EntityID must reference valid Entity
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV022');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV022', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.EntityID IS NOT NULL AND e.EntityID IS NULL THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN p.EntityID IS NOT NULL AND e.EntityID IS NULL THEN 'EntityID does not reference a valid Entity' ELSE NULL END,
           'EntityID', CAST(p.EntityID AS NVARCHAR(10)), 'High'
    FROM cred.Providers p
    LEFT JOIN cred.Entities e ON p.EntityID = e.EntityID
    WHERE p.IsActive = 1 AND p.EntityID IS NOT NULL;
    
    -- Rule PRV023: Email domain should be valid (contains at least one dot after @)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV023');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV023', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND CHARINDEX('.', SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, LEN(EmailAddress))) = 0 THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND CHARINDEX('.', SUBSTRING(EmailAddress, CHARINDEX('@', EmailAddress) + 1, LEN(EmailAddress))) = 0 THEN 'Email domain must contain at least one dot' ELSE NULL END,
           'EmailAddress', EmailAddress, 'Medium'
    FROM cred.Providers
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL AND EmailAddress LIKE '%@%';
    
    -- Rule PRV024: Phone number should not contain letters
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV024');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV024', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN PhoneNumber IS NOT NULL AND PhoneNumber LIKE '%[A-Za-z]%' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN PhoneNumber IS NOT NULL AND PhoneNumber LIKE '%[A-Za-z]%' THEN 'Phone number should not contain letters' ELSE NULL END,
           'PhoneNumber', PhoneNumber, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND PhoneNumber IS NOT NULL;
    
    -- Rule PRV025: State code should be uppercase
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV025');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV025', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN State IS NOT NULL AND State != UPPER(State) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN State IS NOT NULL AND State != UPPER(State) THEN 'State code should be uppercase' ELSE NULL END,
           'State', State, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND State IS NOT NULL;
    
    -- Rule PRV026: Name fields should not have excessive whitespace
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV026');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV026', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN (FirstName LIKE '%  %' OR LastName LIKE '%  %') THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN (FirstName LIKE '%  %' OR LastName LIKE '%  %') THEN 'Name fields contain excessive whitespace' ELSE NULL END,
           'FirstName/LastName', 'Low'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV027: First Name length should be reasonable (2-50 characters)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV027');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV027', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN LEN(LTRIM(RTRIM(FirstName))) < 2 OR LEN(LTRIM(RTRIM(FirstName))) > 50 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN LEN(LTRIM(RTRIM(FirstName))) < 2 OR LEN(LTRIM(RTRIM(FirstName))) > 50 THEN 'First Name length should be between 2 and 50 characters' ELSE NULL END,
           'FirstName', FirstName, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND FirstName IS NOT NULL;
    
    -- Rule PRV028: Last Name length should be reasonable (2-50 characters)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV028');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, FieldValue, Severity)
    SELECT @RuleID, 'PRV028', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN LEN(LTRIM(RTRIM(LastName))) < 2 OR LEN(LTRIM(RTRIM(LastName))) > 50 THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN LEN(LTRIM(RTRIM(LastName))) < 2 OR LEN(LTRIM(RTRIM(LastName))) > 50 THEN 'Last Name length should be between 2 and 50 characters' ELSE NULL END,
           'LastName', LastName, 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND LastName IS NOT NULL;
    
    -- Rule PRV029: Email should be lowercase (best practice)
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV029');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV029', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN EmailAddress IS NOT NULL AND EmailAddress != LOWER(EmailAddress) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN EmailAddress IS NOT NULL AND EmailAddress != LOWER(EmailAddress) THEN 'Email address should be lowercase' ELSE NULL END,
           'EmailAddress', 'Low'
    FROM cred.Providers
    WHERE IsActive = 1 AND EmailAddress IS NOT NULL;
    
    -- Rule PRV030: SSN should not start with 000
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV030');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV030', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN SSN IS NOT NULL AND LEFT(REPLACE(SSN, '-', ''), 3) = '000' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN SSN IS NOT NULL AND LEFT(REPLACE(SSN, '-', ''), 3) = '000' THEN 'SSN should not start with 000' ELSE NULL END,
           'SSN', 'High'
    FROM cred.Providers
    WHERE IsActive = 1 AND SSN IS NOT NULL;
    
    -- Rule PRV031: SSN should not be all zeros
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV031');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, FieldName, Severity)
    SELECT @RuleID, 'PRV031', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN SSN IS NOT NULL AND REPLACE(SSN, '-', '') = '000000000' THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN SSN IS NOT NULL AND REPLACE(SSN, '-', '') = '000000000' THEN 'SSN should not be all zeros' ELSE NULL END,
           'SSN', 'High'
    FROM cred.Providers
    WHERE IsActive = 1 AND SSN IS NOT NULL;
    
    -- Rule PRV032: Provider should have been validated within last 90 days if active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV032');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'PRV032', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN Status = 'Active' AND (LastValidatedDate IS NULL OR DATEDIFF(DAY, LastValidatedDate, GETDATE()) > 90) THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN Status = 'Active' AND (LastValidatedDate IS NULL OR DATEDIFF(DAY, LastValidatedDate, GETDATE()) > 90) THEN 'Active provider should be validated within last 90 days' ELSE NULL END,
           'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV033: CreatedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV033');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'PRV033', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN CreatedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN CreatedDate > GETDATE() THEN 'CreatedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV034: ModifiedDate should not be in the future
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV034');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'PRV034', @ValidationRunID, 'Provider', ProviderID, NPI,
           CASE WHEN ModifiedDate > GETDATE() THEN 'Fail' ELSE 'Pass' END,
           CASE WHEN ModifiedDate > GETDATE() THEN 'ModifiedDate cannot be in the future' ELSE NULL END,
           'Medium'
    FROM cred.Providers
    WHERE IsActive = 1;
    
    -- Rule PRV035: Provider should have at least one credential if status is Active
    SET @RuleID = (SELECT RuleID FROM cred.ValidationRules WHERE RuleCode = 'PRV035');
    INSERT INTO cred.ValidationResults (RuleID, RuleCode, ValidationRunID, EntityType, EntityID, RecordID, ValidationStatus, ErrorMessage, Severity)
    SELECT @RuleID, 'PRV035', @ValidationRunID, 'Provider', p.ProviderID, p.NPI,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Warning' ELSE 'Pass' END,
           CASE WHEN p.Status = 'Active' AND c.CredentialID IS NULL THEN 'Active provider should have at least one credential' ELSE NULL END,
           'Medium'
    FROM cred.Providers p
    LEFT JOIN cred.Credentials c ON p.ProviderID = c.ProviderID AND c.Status = 'Active'
    WHERE p.IsActive = 1;
    
END
GO

PRINT 'Stored procedure cred.sp_RunProviderValidations created successfully';
GO

