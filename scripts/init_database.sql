/*
====================================
Create Database and Schemas
====================================

The purpose of the script is to create a new database called 'DW', which will be used for creating everything within the project. 
Additionally the script also sets up three schemas within the databse : bronze, silver and gold. 

*/

USE master;
GO

-- Creating a new Databse
CREATE DATABASE DW

-- Selecting the database
USE DW;
GO

-- Creating the schemas
CREATE SCHEMA bronze;
GO
CREATE SCHEMA silver;
GO
CREATE SCHEMA gold;
GO
