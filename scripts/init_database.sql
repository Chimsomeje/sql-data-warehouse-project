------------
Script purpose: 
              The scripts creates new database called Datawarehouse database and creates 3 schemas namesly: Bronze, Silver & Gold


USE master;


--Create DataWarehouse database
CREATE DATABASE DataWarehouse;
GO
USE DataWarehouse;
GO

--Create schemas
CREATE SCHEMA Bronze;
GO
CREATE SCHEMA Silver;
GO
CREATE SCHEMA Gold;
GO
