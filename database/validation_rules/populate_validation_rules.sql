-- Populate ValidationRules Table
-- Inserts metadata for all 100+ validation rules

USE CredentialingDB;
GO

-- Clear existing rules (optional - comment out if you want to preserve existing data)
-- DELETE FROM cred.ValidationRules;
-- GO

-- Provider Validation Rules (PRV001 - PRV035)
INSERT INTO cred.ValidationRules (RuleCode, RuleName, RuleDescription, RuleCategory, RuleType, Severity, IsActive)
VALUES
('PRV001', 'NPI Format Validation', 'NPI must be exactly 10 digits', 'Provider', 'Data Quality', 'High', 1),
('PRV002', 'NPI Required', 'NPI cannot be null', 'Provider', 'Data Quality', 'Critical', 1),
('PRV003', 'First Name Required', 'First Name cannot be null or empty', 'Provider', 'Data Quality', 'High', 1),
('PRV004', 'Last Name Required', 'Last Name cannot be null or empty', 'Provider', 'Data Quality', 'High', 1),
('PRV005', 'Date of Birth Past Date', 'Date of Birth must be in the past', 'Provider', 'Data Quality', 'High', 1),
('PRV006', 'Date of Birth Age Range', 'Date of Birth must indicate age between 18 and 100', 'Provider', 'Business Logic', 'Medium', 1),
('PRV007', 'SSN Format Validation', 'SSN must be in format XXX-XX-XXXX if provided', 'Provider', 'Data Quality', 'High', 1),
('PRV008', 'Email Format Validation', 'Email must be in valid format', 'Provider', 'Data Quality', 'Medium', 1),
('PRV009', 'Phone Number Format', 'Phone number must be valid format', 'Provider', 'Data Quality', 'Medium', 1),
('PRV010', 'State Code Length', 'State code must be 2 characters if provided', 'Provider', 'Data Quality', 'Medium', 1),
('PRV011', 'ZIP Code Format', 'ZIP code must be 5 or 9 digits if provided', 'Provider', 'Data Quality', 'Medium', 1),
('PRV012', 'Status Valid Values', 'Status must be valid value', 'Provider', 'Data Quality', 'High', 1),
('PRV013', 'NPI Uniqueness', 'NPI must be unique', 'Provider', 'Data Quality', 'Critical', 1),
('PRV014', 'Specialty Required for Active', 'Specialty should not be empty if provider is active', 'Provider', 'Business Logic', 'Medium', 1),
('PRV015', 'First Name No Numbers', 'First Name should not contain numbers', 'Provider', 'Data Quality', 'Low', 1),
('PRV016', 'Last Name No Numbers', 'Last Name should not contain numbers', 'Provider', 'Data Quality', 'Low', 1),
('PRV017', 'Address Completeness', 'Address Line 1 should be provided if other address fields are present', 'Provider', 'Data Quality', 'Medium', 1),
('PRV018', 'City Required with Address', 'City should be provided if State or ZipCode is present', 'Provider', 'Data Quality', 'Medium', 1),
('PRV019', 'State Required with Address', 'State should be provided if City or ZipCode is present', 'Provider', 'Data Quality', 'Medium', 1),
('PRV020', 'Modified Date Logic', 'ModifiedDate should not be before CreatedDate', 'Provider', 'Data Quality', 'Low', 1),
('PRV021', 'Entity Association', 'Provider with Active status should have EntityID if EntityID is required', 'Provider', 'Business Logic', 'Low', 1),
('PRV022', 'EntityID Valid Reference', 'EntityID must reference valid Entity', 'Provider', 'Data Quality', 'High', 1),
('PRV023', 'Email Domain Validation', 'Email domain should be valid', 'Provider', 'Data Quality', 'Medium', 1),
('PRV024', 'Phone No Letters', 'Phone number should not contain letters', 'Provider', 'Data Quality', 'Low', 1),
('PRV025', 'State Uppercase', 'State code should be uppercase', 'Provider', 'Data Quality', 'Low', 1),
('PRV026', 'Name Whitespace', 'Name fields should not have excessive whitespace', 'Provider', 'Data Quality', 'Low', 1),
('PRV027', 'First Name Length', 'First Name length should be reasonable', 'Provider', 'Data Quality', 'Low', 1),
('PRV028', 'Last Name Length', 'Last Name length should be reasonable', 'Provider', 'Data Quality', 'Low', 1),
('PRV029', 'Email Lowercase', 'Email should be lowercase', 'Provider', 'Data Quality', 'Low', 1),
('PRV030', 'SSN Not 000 Start', 'SSN should not start with 000', 'Provider', 'Data Quality', 'High', 1),
('PRV031', 'SSN Not All Zeros', 'SSN should not be all zeros', 'Provider', 'Data Quality', 'High', 1),
('PRV032', 'Validation Recency', 'Provider should have been validated within last 90 days if active', 'Provider', 'Business Logic', 'Medium', 1),
('PRV033', 'Created Date Future', 'CreatedDate should not be in the future', 'Provider', 'Data Quality', 'Medium', 1),
('PRV034', 'Modified Date Future', 'ModifiedDate should not be in the future', 'Provider', 'Data Quality', 'Medium', 1),
('PRV035', 'Active Provider Credential Requirement', 'Provider should have at least one credential if status is Active', 'Provider', 'Business Logic', 'Medium', 1);

-- Credential Validation Rules (CRED001 - CRED040)
INSERT INTO cred.ValidationRules (RuleCode, RuleName, RuleDescription, RuleCategory, RuleType, Severity, IsActive)
VALUES
('CRED001', 'ProviderID Required', 'ProviderID is required', 'Credential', 'Data Quality', 'Critical', 1),
('CRED002', 'CredentialType Required', 'CredentialType is required', 'Credential', 'Data Quality', 'High', 1),
('CRED003', 'CredentialNumber Required', 'CredentialNumber is required', 'Credential', 'Data Quality', 'High', 1),
('CRED004', 'ProviderID Valid Reference', 'ProviderID must reference valid Provider', 'Credential', 'Data Quality', 'High', 1),
('CRED005', 'Expiration After Issue', 'ExpirationDate must be after IssueDate', 'Credential', 'Business Logic', 'High', 1),
('CRED006', 'Expired Status', 'Expired credentials should have Status = Expired', 'Credential', 'Business Logic', 'High', 1),
('CRED007', 'Expiration Date Reasonable', 'ExpirationDate cannot be more than 20 years in the future', 'Credential', 'Business Logic', 'Medium', 1),
('CRED008', 'Issue Date Future', 'IssueDate cannot be in the future', 'Credential', 'Data Quality', 'High', 1),
('CRED009', 'Issue Date Past', 'IssueDate cannot be more than 50 years in the past', 'Credential', 'Business Logic', 'Medium', 1),
('CRED010', 'Status Valid Values', 'Status must be valid value', 'Credential', 'Data Quality', 'High', 1),
('CRED011', 'Primary Credential Uniqueness', 'Only one credential per Provider can be Primary for same CredentialType', 'Credential', 'Business Logic', 'High', 1),
('CRED012', 'Credential Expiring 30 Days', 'Credentials expiring within 30 days should be flagged', 'Credential', 'Business Logic', 'Medium', 1),
('CRED013', 'Credential Expiring 90 Days', 'Credentials expiring within 90 days should be flagged', 'Credential', 'Business Logic', 'Low', 1),
('CRED014', 'Issuing Organization Required', 'IssuingOrganization should be provided for most credential types', 'Credential', 'Business Logic', 'Medium', 1),
('CRED015', 'State Issued Length', 'StateIssued should be 2 characters if provided', 'Credential', 'Data Quality', 'Medium', 1),
('CRED016', 'State Issued Uppercase', 'StateIssued should be uppercase', 'Credential', 'Data Quality', 'Low', 1),
('CRED017', 'Verification Date Future', 'VerificationDate cannot be in the future', 'Credential', 'Data Quality', 'Medium', 1),
('CRED018', 'Verified By Required', 'VerifiedBy should be provided if VerificationDate is present', 'Credential', 'Business Logic', 'Low', 1),
('CRED019', 'Modified Date Logic', 'ModifiedDate should not be before CreatedDate', 'Credential', 'Data Quality', 'Low', 1),
('CRED020', 'Created Date Future', 'CreatedDate should not be in the future', 'Credential', 'Data Quality', 'Medium', 1),
('CRED021', 'Modified Date Future', 'ModifiedDate should not be in the future', 'Credential', 'Data Quality', 'Medium', 1),
('CRED022', 'CredentialNumber Uniqueness', 'CredentialNumber should be unique per CredentialType and Provider', 'Credential', 'Data Quality', 'High', 1),
('CRED023', 'Active Credential Expiration', 'Active credentials should have valid expiration date', 'Credential', 'Business Logic', 'Medium', 1),
('CRED024', 'CredentialNumber No Spaces Only', 'CredentialNumber should not contain only spaces', 'Credential', 'Data Quality', 'High', 1),
('CRED025', 'CredentialType No Spaces Only', 'CredentialType should not contain only spaces', 'Credential', 'Data Quality', 'High', 1),
('CRED026', 'License State Required', 'License credentials should have StateIssued', 'Credential', 'Business Logic', 'High', 1),
('CRED027', 'Expiration Issue Date Logic', 'ExpirationDate cannot be before IssueDate by more than 1 day', 'Credential', 'Business Logic', 'High', 1),
('CRED028', 'CredentialNumber Length', 'CredentialNumber length should be reasonable', 'Credential', 'Data Quality', 'Low', 1),
('CRED029', 'Issuing Organization Length', 'IssuingOrganization length should be reasonable', 'Credential', 'Data Quality', 'Low', 1),
('CRED030', 'Verification After Issue', 'VerificationDate should be after IssueDate', 'Credential', 'Business Logic', 'Low', 1),
('CRED031', 'Active Not Expired', 'Active credentials should not be expired', 'Credential', 'Business Logic', 'Critical', 1),
('CRED032', 'Suspended Credential Review', 'Suspended credentials should not be Active', 'Credential', 'Business Logic', 'Low', 1),
('CRED033', 'Revoked Status Check', 'Revoked credentials should have Status = Revoked', 'Credential', 'Business Logic', 'Medium', 1),
('CRED034', 'CredentialType Standard List', 'CredentialType should be from standard list', 'Credential', 'Data Quality', 'Low', 1),
('CRED035', 'Provider Active Credential', 'Provider should have at least one Active credential', 'Credential', 'Business Logic', 'Medium', 1),
('CRED036', 'CredentialNumber Special Characters', 'CredentialNumber should not contain special characters', 'Credential', 'Data Quality', 'Low', 1),
('CRED037', 'Expiration Before Created', 'ExpirationDate cannot be before CreatedDate', 'Credential', 'Business Logic', 'Medium', 1),
('CRED038', 'Issue Date Before Created', 'IssueDate should not be more than 10 years before CreatedDate', 'Credential', 'Business Logic', 'Low', 1),
('CRED039', 'Primary Credential Status', 'Primary credential should typically be Active', 'Credential', 'Business Logic', 'Low', 1),
('CRED040', 'Credential Verification Recency', 'Credentials should have been verified within last 5 years if Active', 'Credential', 'Business Logic', 'Medium', 1);

-- Entity Validation Rules (ENT001 - ENT025)
INSERT INTO cred.ValidationRules (RuleCode, RuleName, RuleDescription, RuleCategory, RuleType, Severity, IsActive)
VALUES
('ENT001', 'EntityName Required', 'EntityName is required', 'Entity', 'Data Quality', 'High', 1),
('ENT002', 'TaxID Uniqueness', 'TaxID must be unique if provided', 'Entity', 'Data Quality', 'High', 1),
('ENT003', 'NPI Format Validation', 'NPI must be 10 digits if provided', 'Entity', 'Data Quality', 'High', 1),
('ENT004', 'NPI Uniqueness', 'NPI must be unique if provided', 'Entity', 'Data Quality', 'High', 1),
('ENT005', 'Email Format Validation', 'Email must be valid format', 'Entity', 'Data Quality', 'Medium', 1),
('ENT006', 'Phone Number Format', 'Phone number must be valid format', 'Entity', 'Data Quality', 'Medium', 1),
('ENT007', 'State Code Length', 'State code must be 2 characters if provided', 'Entity', 'Data Quality', 'Medium', 1),
('ENT008', 'ZIP Code Format', 'ZIP code must be 5 or 9 digits if provided', 'Entity', 'Data Quality', 'Medium', 1),
('ENT009', 'Status Valid Values', 'Status must be valid value', 'Entity', 'Data Quality', 'High', 1),
('ENT010', 'Address Completeness', 'Address Line 1 should be provided if other address fields are present', 'Entity', 'Data Quality', 'Medium', 1),
('ENT011', 'City Required with Address', 'City should be provided if State or ZipCode is present', 'Entity', 'Data Quality', 'Medium', 1),
('ENT012', 'State Required with Address', 'State should be provided if City or ZipCode is present', 'Entity', 'Data Quality', 'Medium', 1),
('ENT013', 'Modified Date Logic', 'ModifiedDate should not be before CreatedDate', 'Entity', 'Data Quality', 'Low', 1),
('ENT014', 'Created Date Future', 'CreatedDate should not be in the future', 'Entity', 'Data Quality', 'Medium', 1),
('ENT015', 'Modified Date Future', 'ModifiedDate should not be in the future', 'Entity', 'Data Quality', 'Medium', 1),
('ENT016', 'EntityName Length', 'EntityName length should be reasonable', 'Entity', 'Data Quality', 'Low', 1),
('ENT017', 'TaxID Format', 'TaxID format should be valid', 'Entity', 'Data Quality', 'High', 1),
('ENT018', 'EntityType Standard List', 'EntityType should be from standard list', 'Entity', 'Data Quality', 'Low', 1),
('ENT019', 'State Uppercase', 'State code should be uppercase', 'Entity', 'Data Quality', 'Low', 1),
('ENT020', 'Email Domain Validation', 'Email domain should be valid', 'Entity', 'Data Quality', 'Medium', 1),
('ENT021', 'Phone No Letters', 'Phone number should not contain letters', 'Entity', 'Data Quality', 'Low', 1),
('ENT022', 'Email Lowercase', 'Email should be lowercase', 'Entity', 'Data Quality', 'Low', 1),
('ENT023', 'Active Entity Address Complete', 'Active entities should have complete address information', 'Entity', 'Business Logic', 'Medium', 1),
('ENT024', 'Hospital Accreditation', 'AccreditationStatus should be provided for hospitals', 'Entity', 'Business Logic', 'Low', 1),
('ENT025', 'EntityName Contains Letters', 'EntityName should not contain only numbers', 'Entity', 'Data Quality', 'Low', 1);

-- Cross-Entity Validation Rules (CROSS001 - CROSS017)
INSERT INTO cred.ValidationRules (RuleCode, RuleName, RuleDescription, RuleCategory, RuleType, Severity, IsActive)
VALUES
('CROSS001', 'Provider Entity NPI Mismatch', 'Provider NPI should not match Entity NPI', 'Cross-Entity', 'Business Logic', 'High', 1),
('CROSS002', 'Provider Entity Active', 'Provider EntityID must reference an Active Entity', 'Cross-Entity', 'Business Logic', 'High', 1),
('CROSS003', 'Provider Entity State Match', 'Provider State should match Entity State if EntityID is provided', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS004', 'Active Provider Credential Required', 'Provider should have at least one Active credential if Provider Status is Active', 'Cross-Entity', 'Business Logic', 'High', 1),
('CROSS005', 'Credential Provider State Match', 'Credential StateIssued should match Provider State for State License', 'Cross-Entity', 'Business Logic', 'Medium', 1),
('CROSS006', 'Provider Primary Credential', 'Provider should have at least one Primary credential', 'Cross-Entity', 'Business Logic', 'Medium', 1),
('CROSS007', 'Active Provider Expired Credential', 'Expired credentials should not be associated with Active providers', 'Cross-Entity', 'Business Logic', 'High', 1),
('CROSS008', 'Active Entity Provider Required', 'Entity should have at least one associated Provider if Entity Status is Active', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS009', 'Provider Entity Created Date', 'Provider CreatedDate should not be before Entity CreatedDate', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS010', 'Credential Provider Created Date', 'Credential IssueDate should not be before Provider CreatedDate', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS011', 'Suspended Provider Active Credential', 'Provider with Suspended status should not have Active credentials', 'Cross-Entity', 'Business Logic', 'Medium', 1),
('CROSS012', 'Terminated Provider Active Credential', 'Provider with Terminated status should not have Active credentials', 'Cross-Entity', 'Business Logic', 'High', 1),
('CROSS013', 'Active Provider Credential Expiring', 'Credentials expiring within 60 days for Active providers should be flagged', 'Cross-Entity', 'Business Logic', 'Medium', 1),
('CROSS014', 'Provider Entity Email Domain Match', 'Provider Email domain should match Entity Email domain if EntityID is provided', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS015', 'Provider Entity ZipCode Match', 'Provider ZipCode should match Entity ZipCode if EntityID is provided', 'Cross-Entity', 'Business Logic', 'Low', 1),
('CROSS016', 'Active Provider Valid Credential', 'Provider should have at least one credential with expiration date more than 30 days away if Active', 'Cross-Entity', 'Business Logic', 'Medium', 1),
('CROSS017', 'Inactive Entity Active Provider', 'Entity with Inactive status should not have Active providers', 'Cross-Entity', 'Business Logic', 'Medium', 1);

PRINT 'Validation rules populated successfully';
PRINT 'Total rules inserted: ' + CAST(@@ROWCOUNT AS NVARCHAR(10));
GO

-- Verify count
SELECT RuleCategory, COUNT(*) as RuleCount
FROM cred.ValidationRules
WHERE IsActive = 1
GROUP BY RuleCategory
ORDER BY RuleCategory;
GO

