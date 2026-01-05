-- Master Validation Runner
-- Executes all validation stored procedures and logs results

USE CredentialingDB;
GO

-- =============================================
-- Stored Procedure: Run All Validations
-- =============================================
IF EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'cred.sp_RunAllValidations') AND type in (N'P', N'PC'))
    DROP PROCEDURE cred.sp_RunAllValidations;
GO

CREATE PROCEDURE cred.sp_RunAllValidations
    @RunType NVARCHAR(50) = 'Scheduled'
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ValidationRunID INT;
    DECLARE @RunStartTime DATETIME2 = GETDATE();
    DECLARE @RunEndTime DATETIME2;
    DECLARE @TotalRulesRun INT = 0;
    DECLARE @TotalFailures INT = 0;
    DECLARE @TotalWarnings INT = 0;
    DECLARE @TotalPasses INT = 0;
    DECLARE @ExecutionTimeSeconds INT;
    DECLARE @ErrorMessage NVARCHAR(MAX) = NULL;
    
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Create validation run log entry
        INSERT INTO cred.ValidationRunLog (RunStartTime, RunStatus, RunType)
        VALUES (@RunStartTime, 'Running', @RunType);
        
        SET @ValidationRunID = SCOPE_IDENTITY();
        
        -- Run Provider Validations
        EXEC cred.sp_RunProviderValidations @ValidationRunID = @ValidationRunID;
        SET @TotalRulesRun = @TotalRulesRun + 35;
        
        -- Run Credential Validations
        EXEC cred.sp_RunCredentialValidations @ValidationRunID = @ValidationRunID;
        SET @TotalRulesRun = @TotalRulesRun + 40;
        
        -- Run Entity Validations
        EXEC cred.sp_RunEntityValidations @ValidationRunID = @ValidationRunID;
        SET @TotalRulesRun = @TotalRulesRun + 25;
        
        -- Run Cross-Entity Validations
        EXEC cred.sp_RunCrossEntityValidations @ValidationRunID = @ValidationRunID;
        SET @TotalRulesRun = @TotalRulesRun + 17;
        
        SET @RunEndTime = GETDATE();
        SET @ExecutionTimeSeconds = DATEDIFF(SECOND, @RunStartTime, @RunEndTime);
        
        -- Calculate summary statistics
        SELECT 
            @TotalFailures = COUNT(*)
        FROM cred.ValidationResults
        WHERE ValidationRunID = @ValidationRunID AND ValidationStatus = 'Fail';
        
        SELECT 
            @TotalWarnings = COUNT(*)
        FROM cred.ValidationResults
        WHERE ValidationRunID = @ValidationRunID AND ValidationStatus = 'Warning';
        
        SELECT 
            @TotalPasses = COUNT(*)
        FROM cred.ValidationResults
        WHERE ValidationRunID = @ValidationRunID AND ValidationStatus = 'Pass';
        
        -- Update validation run log
        UPDATE cred.ValidationRunLog
        SET RunEndTime = @RunEndTime,
            RunStatus = 'Completed',
            TotalRulesRun = @TotalRulesRun,
            TotalRecordsValidated = (SELECT COUNT(DISTINCT EntityID) FROM cred.ValidationResults WHERE ValidationRunID = @ValidationRunID),
            TotalFailures = @TotalFailures,
            TotalWarnings = @TotalWarnings,
            TotalPasses = @TotalPasses,
            ExecutionTimeSeconds = @ExecutionTimeSeconds
        WHERE RunID = @ValidationRunID;
        
        COMMIT TRANSACTION;
        
        -- Return summary
        SELECT 
            @ValidationRunID AS ValidationRunID,
            @RunStartTime AS RunStartTime,
            @RunEndTime AS RunEndTime,
            @TotalRulesRun AS TotalRulesRun,
            @TotalFailures AS TotalFailures,
            @TotalWarnings AS TotalWarnings,
            @TotalPasses AS TotalPasses,
            @ExecutionTimeSeconds AS ExecutionTimeSeconds,
            'Completed' AS RunStatus;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        
        SET @RunEndTime = GETDATE();
        SET @ExecutionTimeSeconds = DATEDIFF(SECOND, @RunStartTime, @RunEndTime);
        SET @ErrorMessage = ERROR_MESSAGE();
        
        -- Update validation run log with error
        IF @ValidationRunID IS NOT NULL
        BEGIN
            UPDATE cred.ValidationRunLog
            SET RunEndTime = @RunEndTime,
                RunStatus = 'Failed',
                ExecutionTimeSeconds = @ExecutionTimeSeconds,
                ErrorMessage = @ErrorMessage
            WHERE RunID = @ValidationRunID;
        END
        ELSE
        BEGIN
            INSERT INTO cred.ValidationRunLog (RunStartTime, RunEndTime, RunStatus, ExecutionTimeSeconds, ErrorMessage, RunType)
            VALUES (@RunStartTime, @RunEndTime, 'Failed', @ExecutionTimeSeconds, @ErrorMessage, @RunType);
        END
        
        -- Re-throw error
        THROW;
    END CATCH
END
GO

PRINT 'Stored procedure cred.sp_RunAllValidations created successfully';
GO

-- Example usage:
-- EXEC cred.sp_RunAllValidations @RunType = 'Manual';
-- EXEC cred.sp_RunAllValidations @RunType = 'Scheduled';

