/*
=======================================================
STORED PROCEDURE : LOAD SILVER LAYER (BRONZE -> SILVER)
=======================================================

Script Purpose:
The stored procedure performs the ETL (Extract, Transform, Load) process to populate
the silver schema tables from the bronze schema.

Actions Performed:
  - Truncates the Silver Tables
  - Inserts transformed and cleaned data from the bronze layer to the silver tables

USAGE: EXEC silver.load_silver

========================================================
*/

CREATE OR ALTER PROCEDURE silver.load_silver AS
BEGIN
	BEGIN TRY
		DECLARE @starttime DATETIME, @endtime DATETIME, @batch_start DATETIME, @batch_end DATETIME

		SET @batch_start = GETDATE();
		PRINT '========================'
		PRINT 'LOADING THE SILVER LAYER'
		PRINT '========================'

		PRINT'-----------------------'
		PRINT'LOADING THE CRM TABLES'
		PRINT'-----------------------'



		SET @starttime = GETDATE();
		PRINT' TRUNCATING TABLE silver.crm_cust_info'
		TRUNCATE TABLE silver.crm_cust_info;
		PRINT 'LOADING DATA INTO TABLE silver.crm_cust_info'
		INSERT INTO silver.crm_cust_info
		(	
			cst_id,
			cst_key,
			cst_firstname,
			cst_lastname,
			cst_marital_status,
			cst_gndr,
			cst_create_date 
		)
		SELECT 
			t.cst_id,
			t.cst_key,
			TRIM(t.cst_firstname) AS cst_firstname,
			TRIM(t.cst_lastname) AS cst_lastname,
			(CASE 
				WHEN UPPER(TRIM(t.cst_marital_status)) = 'S' THEN 'SINGLE'
				WHEN UPPER(TRIM(t.cst_marital_status)) = 'M' THEN 'MARRIED'
				ELSE 'N/A'
				END
				) AS cst_marital_status,
			(CASE	
				WHEN UPPER(TRIM(t.cst_gndr)) = 'M' THEN 'MALE'
				WHEN UPPER(TRIM(t.cst_gndr)) = 'F' THEN 'FEMALE'
				ELSE 'N/A'
			 END) AS cst_gndr,
			t.cst_create_date
		FROM
		(
			SELECT 
				*,
				ROW_NUMBER() OVER(PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag
			FROM bronze.crm_cust_info
			WHERE cst_id IS NOT NULL
		) AS t
		WHERE t.flag = 1;

		SET @endtime = GETDATE();
		PRINT'TIME TAKEN TO LOAD TABLE : silver.crm_cust_info ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'


		SET @starttime = GETDATE()
		PRINT' TRUNCATING TABLE silver.crm_prd_info'
		TRUNCATE TABLE silver.crm_prd_info;
		PRINT 'LOADING DATA INTO TABLE silver.crm_prd_info'
		INSERT INTO silver.crm_prd_info
		(
			prd_id,
			prd_key,
			prd_cat_id,
			prd_nm,
			prd_cost,
			prd_line,
			prd_start_date,
			prd_end_date 

		)
		SELECT 
			prd_id,
			SUBSTRING (prd_key, 7, LEN(prd_key)) AS prd_key,
			REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id,
			prd_nm,
			COALESCE(prd_cost, 0) AS prd_cost,
			(CASE	
				WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'MOUNTAIN'
				WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'ROAD'
				WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'OTHER SALES'
				WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'TERRAIN'
				ELSE 'N/A'
			 END
			) AS prd_line,
			prd_start_date,
			DATEADD(DAY, - 1, LEAD(prd_start_date) OVER(PARTITION BY prd_key ORDER BY prd_start_date ASC)) AS prd_end_date
		FROM bronze.crm_prd_info;

		SET @endtime = GETDATE()
		PRINT'TIME TAKEN TO LOAD TABLE : silver.crm_prd_info ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'


		SET @starttime = GETDATE()
		PRINT' TRUNCATING TABLE silver.crm_sales_details'
		TRUNCATE TABLE silver.crm_sales_details;
		PRINT 'LOADING DATA INTO TABLE silver.crm_sales_details'
		INSERT INTO silver.crm_sales_details
		(
			sales_ord_num,
			sales_prd_key,
			sales_cust_id,
			sales_order_date,
			sales_ship_date,
			sales_due_date,
			sales_sales,
			sales_quantity,
			sales_price
		)
		SELECT 
			sales_ord_num,
			sales_prd_key,
			sales_cust_id,
			(CASE
				WHEN sales_order_date < = 0 OR LEN(sales_order_date) <> 8 THEN NULL
				ELSE CAST(CAST(sales_order_date AS VARCHAR) AS DATE)
			END
			) AS sales_order_date,
			(CASE
				WHEN sales_ship_date < = 0 OR LEN(sales_ship_date) <> 8 THEN NULL
				ELSE CAST(CAST(sales_ship_date AS VARCHAR) AS DATE)
			END
			) AS sales_ship_date,
			(CASE
				WHEN sales_due_date < = 0 OR LEN(sales_due_date) <> 8 THEN NULL
				ELSE CAST(CAST(sales_due_date AS VARCHAR) AS DATE)
			END
			) AS sales_due_date,
			(CASE 
				WHEN sales_sales IS NULL OR sales_sales < = 0 OR sales_sales <> sales_quantity * ABS(sales_price)
				THEN sales_quantity * ABS(sales_price)
				ELSE sales_sales
			 END
			 ) AS sales_sales,
			sales_quantity,
			(CASE
				WHEN sales_price IS NULL OR sales_price < = 0 
				THEN sales_sales / NULLIF(sales_quantity,0)
				ELSE sales_price
			 END
			) AS sales_price
		FROM bronze.crm_sales_details;
		SET @endtime = GETDATE()
		PRINT'TIME TAKEN TO LOAD TABLE : silver.crm_sales_details ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'


		PRINT'-----------------------'
		PRINT'LOADING THE ERP TABLES'
		PRINT'-----------------------'

		SET @starttime = GETDATE()
		PRINT' TRUNCATING TABLE silver.erp_cust_az12'
		TRUNCATE TABLE silver.erp_cust_az12;
		PRINT 'LOADING DATA INTO TABLE silver.erp_cust_az12'
		INSERT INTO silver.erp_cust_az12
		(
			cid,
			bdate,
			gen 

		)
		SELECT 
			(CASE
				WHEN cid LIKE 'NAS%' THEN SUBSTRING (cid, 4, LEN(cid)) 
				ELSE cid
			 END
			) AS id,
			(CASE
				WHEN bdate < '1924-01-01' OR bdate > GETDATE() THEN NULL
				ELSE bdate
			 END
			) AS bdate,
			(CASE
				WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'FEMALE'
				WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'MALE'
				ELSE 'N/A'
			 END
			) AS gen
		FROM bronze.erp_cust_az12;
		SET @endtime = GETDATE()
		PRINT'TIME TAKEN TO LOAD TABLE : silver.erp_cust_az12 ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'



		SET @starttime = GETDATE()
		PRINT' TRUNCATING TABLE silver.erp_loc_a101'
		TRUNCATE TABLE silver.erp_loc_a101;
		PRINT 'LOADING DATA INTO TABLE silver.erp_loc_a101'
		INSERT INTO silver.erp_loc_a101
		(
				cid,
			country

		)
		SELECT 
			REPLACE(cid,'-','') AS id,
			(CASE
				WHEN UPPER(TRIM(country)) IN ('USA', 'US','UNITED STATES') THEN 'USA'
				WHEN UPPER(TRIM(country)) IN ('DE', 'GERMANY') THEN 'DE'
				WHEN UPPER(TRIM(country)) IN ('AUSTRALIA','AU') THEN 'AUS'
				WHEN UPPER(TRIM(country)) IN ('UNITED KINGDOM', 'UK') THEN 'UK'
				WHEN UPPER(TRIM(country)) IN ('CANADA', 'CAN') THEN 'CAN'
				WHEN UPPER(TRIM(country)) IN ('FRANCE', 'FRA') THEN 'FRA'
				ELSE 'N/A'
			 END
			) AS country
		FROM bronze.erp_loc_a101;
		SET @endtime = GETDATE()
		PRINT'TIME TAKEN TO LOAD TABLE : silver.erp_loc_a101 ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'



		SET @starttime = GETDATE()
		PRINT' TRUNCATING TABLE silver.erp_px_cat_g1v2'
		TRUNCATE TABLE silver.erp_px_cat_g1v2;
		PRINT 'LOADING DATA INTO TABLE silver.erp_px_cat_g1v2'
		INSERT INTO silver.erp_px_cat_g1v2
		(
			id,
			cat,
			subcat,
			maintenance
		)
		SELECT 
			id,
			cat,
			subcat,
			maintenance
		FROM bronze.erp_px_cat_g1v2;
		SET @endtime = GETDATE()
		PRINT'TIME TAKEN TO LOAD TABLE : silver.erp_px_cat_g1v2 ' + CAST(DATEDIFF (second, @starttime,@endtime) AS VARCHAR) + ' seconds'

		SET @batch_end = GETDATE()

		PRINT '==================='
		PRINT 'SILVER LAYER LOADED'
		PRINT '==================='

		PRINT'TIME TAKEN TO LOAD SILVER LAYER ' + CAST(DATEDIFF (second, @batch_start,@batch_end) AS VARCHAR) + ' seconds'


	END TRY
	BEGIN CATCH
		PRINT'ERROR WHILE LOADING THE TABLES'
		PRINT'ERROR MESSAGE : '+ ERROR_MESSAGE()
	END CATCH
END
