/*
=======================================================
Stored Procedure : Load Bronze Layer (Source -> Bronze)
=======================================================

The purpose of the script is to load data into the bronze schema from external CSV files.
-It truncates the bronze table before loading.
-It uses the 'BULK INSERT' for loading the data from CSV to bronze tables.

========================================================
*/

CREATE OR ALTER PROCEDURE bronze.load_bronze AS
BEGIN
	DECLARE @start_time DATETIME, @end_time DATETIME, @batch_start_time DATETIME, @batch_end_time DATETIME
	
	BEGIN TRY
		PRINT '========================'
		PRINT 'LOADING THE BRONZE LAYER'
		PRINT '========================'

		PRINT'-------------------------'
		PRINT'LOADING THE CRM LAYER'
		PRINT'-------------------------'

		SET @batch_start_time = GETDATE()

		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.crm_cust_info'
		TRUNCATE TABLE bronze.crm_cust_info

		PRINT'INSERTING TABLE : bronze.crm_cust_info'
		BULK INSERT bronze.crm_cust_info
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_crm\cust_info.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';


		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.crm_prd_info'
		TRUNCATE TABLE bronze.crm_prd_info

		PRINT'INSERTING TABLE : bronze.crm_prd_info'
		BULK INSERT bronze.crm_prd_info
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_crm\prd_info.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.crm_sales_details'
		TRUNCATE TABLE bronze.crm_sales_details

		PRINT'INSERTING TABLE : bronze.crm_sales_details'
		BULK INSERT bronze.crm_sales_details
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_crm\sales_details.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

		PRINT'-------------------------'
		PRINT'CRM LAYER LOADED'
		PRINT'-------------------------'

		PRINT'-------------------------'
		PRINT'LOADING THE ERP LAYER'
		PRINT'-------------------------'

		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.erp_cust_az12'
		TRUNCATE TABLE bronze.erp_cust_az12

		PRINT'INSERTING TABLE : bronze.erp_cust_az12'
		BULK INSERT bronze.erp_cust_az12
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_erp\cust_az12.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.erp_loc_a101'
		TRUNCATE TABLE bronze.erp_loc_a101

		PRINT'INSERTING TABLE : bronze.erp_loc_a101'
		BULK INSERT bronze.erp_loc_a101
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_erp\loc_a101.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()
		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

		SET @start_time = GETDATE()
		PRINT'TRUNCATING TABLE : bronze.erp_px_cat_g1v2'
		TRUNCATE TABLE bronze.erp_px_cat_g1v2

		PRINT'INSERTING TABLE : bronze.erp_px_cat_g1v2'
		BULK INSERT bronze.erp_px_cat_g1v2
		FROM 'D:\SQL Course\3rdMarch_Project\datasets\source_erp\px_cat_g1v2.csv'
		WITH 
			(
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			TABLOCK
			)
		SET @end_time = GETDATE()

		SET @batch_end_time = GETDATE()

		PRINT'TOTAL LOAD TIME : '+ CAST(DATEDIFF(second, @start_time, @end_time) AS NVARCHAR) + 'seconds';

		PRINT'-------------------------'
		PRINT'ERP LAYER LOADED'
		PRINT'-------------------------'

		PRINT '========================'
		PRINT 'BRONZE LAYER LOADING COMPLETED'
		PRINT '========================'

		PRINT'TOTAL TIME TAKEN TO LOAD BRONZE LAYER : '+ CAST(DATEDIFF(second,@batch_start_time,@batch_end_time) AS NVARCHAR)+ 'seconds'
	END TRY
	BEGIN CATCH
		PRINT'ERROR WHILE LOADING THE TABLES'
		PRINT'ERROR MESSAGE : '+ ERROR_MESSAGE()
	END CATCH
END
