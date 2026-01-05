-- Credentialing Data Validation Database
-- Purpose: Centralized database for credentialing data validation and BI reporting

USE master;
GO

-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'CredentialingDB')
BEGIN
    CREATE DATABASE CredentialingDB
    ON 
    ( NAME = 'CredentialingDB_Data',
      FILENAME = 'C:\SQLData\CredentialingDB_Data.mdf',
      SIZE = 500MB,
      MAXSIZE = 10GB,
      FILEGROWTH = 100MB )
    LOG ON 
    ( NAME = 'CredentialingDB_Log',
      FILENAME = 'C:\SQLData\CredentialingDB_Log.ldf',
      SIZE = 100MB,
      MAXSIZE = 2GB,
      FILEGROWTH = 10MB );
END
GO

USE CredentialingDB;
GO

-- Create schema for organization
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'cred')
BEGIN
    EXEC('CREATE SCHEMA cred');
END
GO

PRINT 'Database CredentialingDB created successfully';
GO

