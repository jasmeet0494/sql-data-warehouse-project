/*
===========================================================================
DDL SCRIPT: CREATE GOLD VIEWS
===========================================================================
SCRIPT PURPOSE : 
This script creates views for the gold layer in the data warehouse.
The gold layer represents the final dimension and fact tables (Star Schema)

Each view performs transformations and combines data from the Silver Layer 
to produce a clean, enriched, and business ready dataset.

USAGE : The views can be directly queried for analytics and reporting.
===========================================================================
*/

==========================================================================
  CREATE CUSTOMERS DIMENSION TABLE
==========================================================================
  
IF OBJECT_ID ('gold.dim_customers', 'U') IS NOT NULL
DROP VIEW gold.dim_customers

GO

CREATE VIEW gold.dim_customers AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY ci.cst_id) AS customer_key,
	ci.cst_id AS customer_id,
	ci.cst_key AS customer_number,
	ci.cst_firstname AS first_name,
	ci.cst_lastname AS last_name,
	(CASE
		WHEN ci.cst_gndr = 'N/A' AND ca.gen IS NOT NULL THEN ca.gen
		ELSE ci.cst_gndr
		END
	) AS gender,
	la.country AS country,
	ci.cst_marital_status AS marital_status,
	ca.bdate AS birth_date,		
	ci.cst_create_date AS create_date
FROM silver.crm_cust_info AS ci
LEFT JOIN silver.erp_cust_az12 ca
ON ci.cst_key = ca.cid
LEFT JOIN silver.erp_loc_a101 la
ON ci.cst_key = la.cid



==========================================================================
  CREATE PRODUCTS DIMENSION TABLE
==========================================================================   
IF OBJECT_ID ('gold.dim_products', 'U') IS NOT NULL
DROP VIEW gold.dim_products

GO

CREATE VIEW gold.dim_products AS
SELECT 
	ROW_NUMBER() OVER(ORDER BY prd_start_date) AS product_key,
	pn.prd_id AS product_id,
	pn.prd_key AS product_number,
	pn.prd_nm AS product_name,
	pn.prd_line AS product_line,
	pn.prd_cat_id AS category_id,
	pc.cat AS category,
	pc.subcat AS sub_category,
	pn.prd_cost AS product_cost,
	pn.prd_start_date AS start_date,
	pc.maintenance AS maintenance
FROM silver.crm_prd_info AS pn
LEFT JOIN silver.erp_px_cat_g1v2 AS pc
ON pn.prd_cat_id = pc.id
WHERE pn.prd_end_date IS NULL



==========================================================================
  CREATE SALES FACT TABLE
==========================================================================    
IF OBJECT_ID ('gold.fact_sales', 'U') IS NOT NULL
DROP VIEW gold.fact_sales

GO

CREATE VIEW gold.fact_sales AS
SELECT 
	sd.sales_ord_num AS order_number,
	pp.product_key,
	pr.customer_key,
	sd.sales_order_date AS order_date,
	sd.sales_ship_date AS ship_date,
	sd.sales_due_date AS due_date,
	sd.sales_sales AS sales,
	sd.sales_quantity AS quantity,
	sd.sales_price AS price
FROM silver.crm_sales_details AS sd
LEFT JOIN gold.dim_customers AS pr
ON sd.sales_cust_id = pr.customer_id
LEFT JOIN gold.dim_products AS pp
ON sd.sales_prd_key = pp.product_number





