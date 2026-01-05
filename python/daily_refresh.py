"""
Daily Refresh Script
Automated daily refresh of data and validation execution
Designed to run as a scheduled task (Windows Task Scheduler, cron, etc.)
"""

import sys
import logging
from datetime import datetime
from validation_runner import ValidationRunner
from data_ingestion import DataIngestion
from config import VALIDATION_RUN_TYPE_SCHEDULED

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler(f'daily_refresh_{datetime.now().strftime("%Y%m%d")}.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


def run_daily_refresh():
    """Execute daily refresh process"""
    logger.info("=" * 80)
    logger.info(f"Starting Daily Refresh Process - {datetime.now()}")
    logger.info("=" * 80)
    
    overall_start_time = datetime.now()
    validation_runner = None
    data_ingestion = None
    
    try:
        # Step 1: Data Ingestion
        logger.info("Step 1: Starting data ingestion...")
        data_ingestion = DataIngestion()
        data_ingestion.run_daily_refresh()
        logger.info("Step 1: Data ingestion completed")
        
        # Step 2: Run Validations
        logger.info("Step 2: Starting validation execution...")
        validation_runner = ValidationRunner()
        validation_results = validation_runner.run_all_validations(
            run_type=VALIDATION_RUN_TYPE_SCHEDULED
        )
        
        if validation_results:
            logger.info("Step 2: Validation execution completed")
            logger.info(f"  Validation Run ID: {validation_results['validation_run_id']}")
            logger.info(f"  Total Rules: {validation_results['total_rules']}")
            logger.info(f"  Failures: {validation_results['failures']}")
            logger.info(f"  Warnings: {validation_results['warnings']}")
            logger.info(f"  Passes: {validation_results['passes']}")
        else:
            logger.warning("Step 2: Validation execution returned no results")
        
        # Step 3: Generate Summary Report
        logger.info("Step 3: Generating summary report...")
        if validation_results:
            summary = validation_runner.get_validation_summary(
                validation_results['validation_run_id']
            )
            failures = validation_runner.get_failure_details(
                validation_results['validation_run_id'], 
                limit=100
            )
            
            logger.info(f"Summary Report Generated:")
            logger.info(f"  Total Failures: {validation_results['failures']}")
            logger.info(f"  Total Warnings: {validation_results['warnings']}")
            logger.info(f"  Unresolved Issues: {len(failures)}")
        
        # Calculate total execution time
        overall_end_time = datetime.now()
        total_execution_time = (overall_end_time - overall_start_time).total_seconds()
        
        logger.info("=" * 80)
        logger.info(f"Daily Refresh Process Completed Successfully")
        logger.info(f"Total Execution Time: {total_execution_time:.2f} seconds")
        logger.info("=" * 80)
        
        return 0  # Success
        
    except Exception as e:
        logger.error("=" * 80)
        logger.error(f"Daily Refresh Process Failed: {str(e)}")
        logger.error("=" * 80)
        logger.exception(e)  # Log full traceback
        return 1  # Failure
        
    finally:
        # Cleanup
        if validation_runner:
            validation_runner.close()
        if data_ingestion:
            # Close any open connections if needed
            pass


def main():
    """Main entry point for scheduled execution"""
    exit_code = run_daily_refresh()
    sys.exit(exit_code)


if __name__ == "__main__":
    main()

