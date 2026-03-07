/*
===============================
QUALITY CHECKS 
===============================
Script Purpose : 
  The script various quality checks for data consistency, accuracy,
  and standardization across the silver schema. It includes checks for : 
  - NULLS and duplicates in the primary keys.
  - Unwanted spaces in the string fields.
  - Data Standardization and consistency.
  - Invalid date ranges and orders.
  - Data consistency between related fields.

Usage Notes : 
  - Run these checks after loading data into the Silver Layer.
  - Investigate and resolve any discrepancies found during the chekcs.

*/

--CUSTOMER TABLE
--CHECK FOR NULLS AND DUPLICATES IN PRIMARY KEY 

SELECT *
FROM 
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY cst_id) AS flag
FROM silver.crm_cust_info
) AS t
WHERE t.flag > 1 OR t.cst_id IS NULL

-- CHECK FOR UNWANTED SPACES IN STRING COLOUMNS
SELECT *
FROM silver.crm_cust_info
WHERE cst_key <> TRIM(cst_key) OR cst_key IS NULL

SELECT *
FROM silver.crm_cust_info
WHERE cst_firstname <> TRIM(cst_firstname) 

SELECT *
FROM silver.crm_cust_info
WHERE cst_lastname <> TRIM(cst_lastname) 

--CHECK FOR DISTINCT VALUES IN CARDINAL COLOUMNS
SELECT DISTINCT cst_marital_status
FROM silver.crm_cust_info

SELECT DISTINCT cst_gndr
FROM silver.crm_cust_info

--PRODUCT TABLE
-- CHECK FOR NULLS AND DUPLICATES IN THE PRIMARY KEY
SELECT *
FROM
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY prd_id) AS Flag
FROM silver.crm_prd_info
) AS t
WHERE t.Flag > 1 OR t.prd_id IS NULL

--CHECK FOR UNWANTED SPACES AND NULLS IN STRING VALUES
SELECT *
FROM silver.crm_prd_info
WHERE prd_key <> TRIM(prd_key) OR prd_key IS NULL

SELECT *
FROM silver.crm_prd_info
WHERE prd_nm <> TRIM(prd_nm) OR prd_nm IS NULL

--CHECK FOR CARDINAL COLOUMNS
SELECT DISTINCT prd_line
FROM silver.crm_prd_info

--CHECK FOR NUMERICAL COLOUMNS
SELECT *
FROM silver.crm_prd_info
WHERE prd_cost IS NULL or prd_cost < 0

--CHECK FOR DATE COLOUMS
SELECT *
FROM silver.crm_prd_info

--ORDERS TABLE
--CHECK FOR NULLS AND DUPLICATES IN THE PRIMARY KEY
-- 
SELECT *
FROM
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY sales_ord_num) AS flag
FROM silver.crm_sales_details
) AS t
WHERE t.flag > 1 OR t.sales_ord_num IS NULL

--CHECK FOR UNWANTED SPACES IN THE STRING COLOUMNS
SELECT *
FROM silver.crm_sales_details
WHERE sales_ord_num <> TRIM(sales_ord_num)

--CHECK FOR INVALID DATE COLOUMNS
SELECT sales_order_date
FROM silver.crm_sales_details
WHERE sales_order_date < = 0
OR LEN(sales_order_date) <> 8
OR sales_order_date < 19000101
OR sales_order_date > 20500101

SELECT sales_due_date
FROM bronze.crm_sales_details
WHERE sales_due_date < = 0
OR LEN(sales_due_date) <> 8
OR sales_due_date < 19000101
OR sales_due_date > 20500101

SELECT sales_ship_date
FROM bronze.crm_sales_details
WHERE sales_ship_date < = 0
OR LEN(sales_ship_date) <> 8
OR sales_ship_date < 19000101
OR sales_ship_date > 20500101

--CHECK FOR ORDER OF DATES (ORDER DATE CANNOT BE GREATER THAN SHIP OR DUE DATE)
SELECT *
FROM bronze.crm_sales_details
WHERE sales_order_date > sales_due_date OR sales_order_date > sales_ship_date

--CHECK FOR THE NUMERICAL COLOUMNS (SALES = QUANTITY * PRICE)
SELECT DISTINCT
	sales_sales,
	sales_quantity,
	sales_price
FROM silver.crm_sales_details
WHERE sales_sales <> sales_price * sales_quantity
OR sales_sales IS NULL OR sales_quantity IS NULL OR sales_price IS NULL
OR sales_sales < = 0 OR sales_quantity < = 0 OR sales_price < = 0
ORDER BY sales_sales, sales_quantity, sales_price

--CUST_AZ12 TABLE
-- CHECK FOR NULLS AND DUPLICATES IN THE PRIMARY KEY
SELECT *
FROM
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY cid) AS flag
FROM silver.erp_cust_az12
) AS t
WHERE t.flag > 1 OR t.cid IS NULL

--CHECK FOR DATE COLOUMN
SELECT 
	bdate
FROM silver.erp_cust_az12
WHERE bdate < '1924-01-01' OR bdate > GETDATE()

--CHECK FOR CARDINAL COLOUMns
SELECT DISTINCT gen
FROM silver.erp_cust_az12

--TABLE LOC101
--CHECK THE PRIMARY KEY
SELECT *
FROM
(
SELECT 
	*,
	COUNT(*) OVER(PARTITION BY cid) AS flag
FROM silver.erp_loc_a101
) AS t
WHERE t.flag > 1 OR t.cid IS NULL

--CHECK FOR CARDINAL COLOUMNS
SELECT DISTINCT country
FROM silver.erp_loc_a101

--TABLE PX_CAT
--CHECK FRO NULLS AND DUPLICATES IN THE PRIMARY KEY
SELECT *
FROM
(
SELECT *,
	COUNT(*) OVER(PARTITION BY id) AS flag
FROM bronze.erp_px_cat_g1v2
) AS t
WHERE t.flag > 1 OR t.id IS NULL

--CHECK FOR STRING COLOUMNS
SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE cat <> TRIM(cat)

SELECT *
FROM bronze.erp_px_cat_g1v2
WHERE subcat <> TRIM(subcat)

--CHECK FOR CARDINAL COLOUMNS
SELECT DISTINCT maintenance
FROM bronze.erp_px_cat_g1v2
