"""
Validation Runner Script
Executes SQL validation rules and logs results
Can be run manually or scheduled
"""

import pyodbc
import logging
from datetime import datetime
from config import CONNECTION_STRING, VALIDATION_RUN_TYPE_MANUAL, VALIDATION_RUN_TYPE_SCHEDULED

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('validation_runner.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class ValidationRunner:
    """Handles execution of validation rules"""
    
    def __init__(self):
        """Initialize database connection"""
        try:
            self.connection_string = CONNECTION_STRING
            self.conn = pyodbc.connect(CONNECTION_STRING)
            logger.info("Database connection established")
        except Exception as e:
            logger.error(f"Failed to establish database connection: {str(e)}")
            raise
    
    def run_all_validations(self, run_type=VALIDATION_RUN_TYPE_MANUAL):
        """Execute all validation rules"""
        logger.info(f"Starting validation run (Type: {run_type})...")
        start_time = datetime.now()
        
        try:
            cursor = self.conn.cursor()
            
            # Execute the master validation stored procedure
            cursor.execute("EXEC cred.sp_RunAllValidations ?", run_type)
            
            # Fetch results
            results = cursor.fetchone()
            
            if results:
                validation_run_id, run_start, run_end, total_rules, failures, warnings, passes, exec_time, status = results
                
                logger.info(f"Validation run completed:")
                logger.info(f"  Run ID: {validation_run_id}")
                logger.info(f"  Status: {status}")
                logger.info(f"  Total Rules Run: {total_rules}")
                logger.info(f"  Failures: {failures}")
                logger.info(f"  Warnings: {warnings}")
                logger.info(f"  Passes: {passes}")
                logger.info(f"  Execution Time: {exec_time} seconds")
                
                # Commit transaction
                self.conn.commit()
                
                return {
                    'validation_run_id': validation_run_id,
                    'status': status,
                    'total_rules': total_rules,
                    'failures': failures,
                    'warnings': warnings,
                    'passes': passes,
                    'execution_time': exec_time
                }
            else:
                logger.warning("No results returned from validation run")
                return None
                
        except Exception as e:
            self.conn.rollback()
            logger.error(f"Validation run failed: {str(e)}")
            raise
    
    def get_validation_summary(self, validation_run_id=None):
        """Get summary of validation results"""
        try:
            cursor = self.conn.cursor()
            
            if validation_run_id:
                query = """
                    SELECT 
                        RuleCode,
                        RuleCategory,
                        ValidationStatus,
                        COUNT(*) as Count,
                        Severity
                    FROM cred.ValidationResults vr
                    INNER JOIN cred.ValidationRules vrules ON vr.RuleID = vrules.RuleID
                    WHERE vr.ValidationRunID = ?
                    GROUP BY RuleCode, RuleCategory, ValidationStatus, Severity
                    ORDER BY RuleCategory, ValidationStatus, Severity
                """
                cursor.execute(query, validation_run_id)
            else:
                query = """
                    SELECT TOP 100
                        RuleCode,
                        RuleCategory,
                        ValidationStatus,
                        COUNT(*) as Count,
                        Severity
                    FROM cred.ValidationResults vr
                    INNER JOIN cred.ValidationRules vrules ON vr.RuleID = vrules.RuleID
                    WHERE vr.ValidationDate >= DATEADD(DAY, -7, GETDATE())
                    GROUP BY RuleCode, RuleCategory, ValidationStatus, Severity
                    ORDER BY ValidationDate DESC, RuleCategory, ValidationStatus
                """
                cursor.execute(query)
            
            results = cursor.fetchall()
            
            summary = {}
            for row in results:
                rule_code, category, status, count, severity = row
                key = f"{category}_{status}"
                if key not in summary:
                    summary[key] = []
                summary[key].append({
                    'rule_code': rule_code,
                    'count': count,
                    'severity': severity
                })
            
            return summary
            
        except Exception as e:
            logger.error(f"Failed to get validation summary: {str(e)}")
            raise
    
    def get_failure_details(self, validation_run_id=None, limit=100):
        """Get detailed failure information"""
        try:
            cursor = self.conn.cursor()
            
            if validation_run_id:
                query = """
                    SELECT TOP (?)
                        vr.ValidationResultID,
                        vr.RuleCode,
                        vr.EntityType,
                        vr.RecordID,
                        vr.ErrorMessage,
                        vr.Severity,
                        vr.ValidationDate,
                        vrules.RuleName
                    FROM cred.ValidationResults vr
                    INNER JOIN cred.ValidationRules vrules ON vr.RuleID = vrules.RuleID
                    WHERE vr.ValidationRunID = ? 
                        AND vr.ValidationStatus IN ('Fail', 'Warning')
                        AND vr.Resolved = 0
                    ORDER BY vr.Severity DESC, vr.ValidationDate DESC
                """
                cursor.execute(query, limit, validation_run_id)
            else:
                query = """
                    SELECT TOP (?)
                        vr.ValidationResultID,
                        vr.RuleCode,
                        vr.EntityType,
                        vr.RecordID,
                        vr.ErrorMessage,
                        vr.Severity,
                        vr.ValidationDate,
                        vrules.RuleName
                    FROM cred.ValidationResults vr
                    INNER JOIN cred.ValidationRules vrules ON vr.RuleID = vrules.RuleID
                    WHERE vr.ValidationStatus IN ('Fail', 'Warning')
                        AND vr.Resolved = 0
                        AND vr.ValidationDate >= DATEADD(DAY, -7, GETDATE())
                    ORDER BY vr.Severity DESC, vr.ValidationDate DESC
                """
                cursor.execute(query, limit)
            
            results = cursor.fetchall()
            
            failures = []
            for row in results:
                failures.append({
                    'validation_result_id': row[0],
                    'rule_code': row[1],
                    'entity_type': row[2],
                    'record_id': row[3],
                    'error_message': row[4],
                    'severity': row[5],
                    'validation_date': row[6],
                    'rule_name': row[7]
                })
            
            return failures
            
        except Exception as e:
            logger.error(f"Failed to get failure details: {str(e)}")
            raise
    
    def close(self):
        """Close database connection"""
        if self.conn:
            self.conn.close()
            logger.info("Database connection closed")


def main():
    """Main execution function"""
    runner = None
    try:
        runner = ValidationRunner()
        
        # Run all validations
        results = runner.run_all_validations(run_type=VALIDATION_RUN_TYPE_MANUAL)
        
        if results:
            validation_run_id = results['validation_run_id']
            
            # Get summary
            summary = runner.get_validation_summary(validation_run_id)
            logger.info(f"Validation Summary: {summary}")
            
            # Get failure details
            if results['failures'] > 0 or results['warnings'] > 0:
                failures = runner.get_failure_details(validation_run_id, limit=50)
                logger.info(f"Found {len(failures)} failures/warnings")
                for failure in failures[:10]:  # Log first 10
                    logger.warning(f"  {failure['rule_code']}: {failure['error_message']}")
        
    except Exception as e:
        logger.error(f"Validation runner failed: {str(e)}")
        raise
    finally:
        if runner:
            runner.close()


if __name__ == "__main__":
    main()

