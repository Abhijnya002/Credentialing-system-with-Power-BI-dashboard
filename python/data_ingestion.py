"""
Data Ingestion Script
Loads data from source systems into the CredentialingDB database
Supports CSV files, database connections, and API integrations
"""

import pyodbc
import pandas as pd
import logging
from datetime import datetime
from config import CONNECTION_STRING, SQL_SERVER, SQL_DATABASE
from sqlalchemy import create_engine
from sqlalchemy.engine import URL

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('data_ingestion.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DataIngestion:
    """Handles data ingestion into CredentialingDB"""
    
    def __init__(self):
        """Initialize database connection"""
        try:
            self.connection_string = CONNECTION_STRING
            self.engine = create_engine(
                f"mssql+pyodbc:///?odbc_connect={CONNECTION_STRING.replace(' ', '')}",
                fast_executemany=True
            )
            logger.info("Database connection established")
        except Exception as e:
            logger.error(f"Failed to establish database connection: {str(e)}")
            raise
    
    def log_refresh_start(self, source_system):
        """Log the start of a data refresh operation"""
        try:
            with pyodbc.connect(self.connection_string) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    INSERT INTO cred.DataRefreshLog 
                    (RefreshStartTime, RefreshStatus, SourceSystem)
                    VALUES (?, ?, ?)
                    SELECT SCOPE_IDENTITY()
                """, datetime.now(), 'Running', source_system)
                refresh_id = cursor.fetchone()[0]
                conn.commit()
                return refresh_id
        except Exception as e:
            logger.error(f"Failed to log refresh start: {str(e)}")
            return None
    
    def log_refresh_end(self, refresh_id, status, records_processed=0, 
                       records_inserted=0, records_updated=0, records_deleted=0,
                       error_message=None):
        """Log the end of a data refresh operation"""
        try:
            with pyodbc.connect(self.connection_string) as conn:
                cursor = conn.cursor()
                cursor.execute("""
                    UPDATE cred.DataRefreshLog
                    SET RefreshEndTime = ?,
                        RefreshStatus = ?,
                        RecordsProcessed = ?,
                        RecordsInserted = ?,
                        RecordsUpdated = ?,
                        RecordsDeleted = ?,
                        ExecutionTimeSeconds = DATEDIFF(SECOND, RefreshStartTime, ?),
                        ErrorMessage = ?
                    WHERE RefreshID = ?
                """, datetime.now(), status, records_processed, records_inserted,
                    records_updated, records_deleted, datetime.now(), error_message, refresh_id)
                conn.commit()
        except Exception as e:
            logger.error(f"Failed to log refresh end: {str(e)}")
    
    def load_providers_from_csv(self, file_path):
        """Load provider data from CSV file"""
        refresh_id = self.log_refresh_start('CSV - Providers')
        records_inserted = 0
        records_updated = 0
        
        try:
            # Read CSV file
            df = pd.read_csv(file_path)
            logger.info(f"Loaded {len(df)} provider records from {file_path}")
            
            # Data transformation and validation
            df['CreatedDate'] = datetime.now()
            df['ModifiedDate'] = datetime.now()
            df['IsActive'] = df.get('IsActive', 1)
            
            # Use merge to handle inserts and updates
            # This is a simplified version - in production, you'd use MERGE SQL statement
            df.to_sql('Providers_temp', self.engine, schema='cred', 
                     if_exists='replace', index=False, method='multi')
            
            # Execute merge statement (upsert logic)
            with self.engine.connect() as conn:
                # Use stored procedure or MERGE statement for upsert
                # For simplicity, using INSERT with conflict handling
                conn.execute("""
                    MERGE cred.Providers AS target
                    USING cred.Providers_temp AS source
                    ON target.NPI = source.NPI
                    WHEN MATCHED THEN
                        UPDATE SET 
                            FirstName = source.FirstName,
                            LastName = source.LastName,
                            ModifiedDate = GETDATE()
                    WHEN NOT MATCHED THEN
                        INSERT (NPI, FirstName, LastName, CreatedDate, ModifiedDate, IsActive)
                        VALUES (source.NPI, source.FirstName, source.LastName, 
                                source.CreatedDate, source.ModifiedDate, source.IsActive);
                    
                    DROP TABLE cred.Providers_temp;
                """)
            
            records_inserted = len(df)
            self.log_refresh_end(refresh_id, 'Completed', len(df), 
                               records_inserted, records_updated, 0)
            logger.info(f"Successfully loaded {records_inserted} provider records")
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error loading providers: {error_msg}")
            self.log_refresh_end(refresh_id, 'Failed', 0, 0, 0, 0, error_msg)
            raise
    
    def load_credentials_from_csv(self, file_path):
        """Load credential data from CSV file"""
        refresh_id = self.log_refresh_start('CSV - Credentials')
        records_inserted = 0
        
        try:
            df = pd.read_csv(file_path)
            logger.info(f"Loaded {len(df)} credential records from {file_path}")
            
            # Data transformation
            df['CreatedDate'] = datetime.now()
            df['ModifiedDate'] = datetime.now()
            
            # Insert credentials (assuming ProviderID mapping is handled)
            df.to_sql('Credentials', self.engine, schema='cred', 
                     if_exists='append', index=False, method='multi')
            
            records_inserted = len(df)
            self.log_refresh_end(refresh_id, 'Completed', len(df), 
                               records_inserted, 0, 0)
            logger.info(f"Successfully loaded {records_inserted} credential records")
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error loading credentials: {error_msg}")
            self.log_refresh_end(refresh_id, 'Failed', 0, 0, 0, 0, error_msg)
            raise
    
    def load_entities_from_csv(self, file_path):
        """Load entity data from CSV file"""
        refresh_id = self.log_refresh_start('CSV - Entities')
        records_inserted = 0
        
        try:
            df = pd.read_csv(file_path)
            logger.info(f"Loaded {len(df)} entity records from {file_path}")
            
            # Data transformation
            df['CreatedDate'] = datetime.now()
            df['ModifiedDate'] = datetime.now()
            df['IsActive'] = df.get('IsActive', 1)
            
            df.to_sql('Entities', self.engine, schema='cred', 
                     if_exists='append', index=False, method='multi')
            
            records_inserted = len(df)
            self.log_refresh_end(refresh_id, 'Completed', len(df), 
                               records_inserted, 0, 0)
            logger.info(f"Successfully loaded {records_inserted} entity records")
            
        except Exception as e:
            error_msg = str(e)
            logger.error(f"Error loading entities: {error_msg}")
            self.log_refresh_end(refresh_id, 'Failed', 0, 0, 0, 0, error_msg)
            raise
    
    def load_from_source_database(self, source_connection_string, query):
        """Load data from another database source"""
        try:
            source_engine = create_engine(source_connection_string)
            df = pd.read_sql(query, source_engine)
            logger.info(f"Loaded {len(df)} records from source database")
            return df
        except Exception as e:
            logger.error(f"Error loading from source database: {str(e)}")
            raise
    
    def run_daily_refresh(self):
        """Execute daily data refresh process"""
        logger.info("Starting daily data refresh...")
        refresh_start = datetime.now()
        
        try:
            # In production, this would connect to your source systems
            # For demonstration, showing the structure
            
            # Example: Load from source database
            # source_query = "SELECT * FROM SourceProviders WHERE LastModifiedDate >= DATEADD(DAY, -1, GETDATE())"
            # providers_df = self.load_from_source_database(source_conn, source_query)
            
            # Example: Load from CSV files
            # self.load_providers_from_csv('data/providers.csv')
            # self.load_credentials_from_csv('data/credentials.csv')
            # self.load_entities_from_csv('data/entities.csv')
            
            logger.info("Daily data refresh completed successfully")
            
        except Exception as e:
            logger.error(f"Daily data refresh failed: {str(e)}")
            raise


def main():
    """Main execution function"""
    try:
        ingestion = DataIngestion()
        
        # Example usage - uncomment and modify as needed
        # ingestion.load_providers_from_csv('data/providers.csv')
        # ingestion.load_credentials_from_csv('data/credentials.csv')
        # ingestion.load_entities_from_csv('data/entities.csv')
        
        # Or run daily refresh
        # ingestion.run_daily_refresh()
        
        logger.info("Data ingestion process completed")
        
    except Exception as e:
        logger.error(f"Data ingestion process failed: {str(e)}")
        raise


if __name__ == "__main__":
    main()

