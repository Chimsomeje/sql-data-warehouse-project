/*
-------------------------------------------------------------------------------------------
DDL Script: Creat gold views
-------------------------------------------------------------------------------------------
Script Purpose:
       This scripts creates view for the gold layer.
       The gold layer represents the final dimensions and fact tables.
       Each view performs transformations and combine data from the silver layer to produce
       clean and enriched business ready dataset.
-------------------------------------------------------------------------------------------
*/


--create the dimension gold.dim_customers as a view

IF OBJECT_ID('gold.dim_customers', 'V') IS NOT NULL
   DROP VIEW gold.dim_customers;
 GO

CREATE VIEW gold.dim_customers AS
SELECT
ROW_NUMBER() OVER (ORDER BY cst_id) AS customer_key,
ci.cst_id AS customer_id,
ci.cst_key AS customer_number,
ci.cst_firstname AS first_name,
ci.cst_lastname AS last_name,
la.cntry AS country,
ci.cst_marital_status AS marital_status,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
     ELSE COALESCE(ca.gen, 'n/a')
	 END gender,
ca.bdate AS birthdate,
ci.cst_create_date AS create_date
FROM [Silver].[crm_cust_info] ci
LEFT JOIN
[Silver].[erp_cust_az12] ca
ON ci.cst_key = ca.cid
LEFT JOIN
[Silver].[erp_loc_a101] la
ON ci.cst_key = la.cid



--create the dimension gold.dim_products as a view

IF OBJECT_ID('gold.dim_products', 'V') IS NOT NULL
   DROP VIEW gold.dim_products;
 GO

CREATE VIEW gold.dim_products AS
SELECT
ROW_NUMBER() OVER (ORDER BY prd_start_dt, prd_key) AS product_key,
pn.prd_id AS product_id,
pn.prd_key AS product_number,
pn.prd_nm AS product_name,
pn.cat_id AS category_id,
cat AS category,
subcat AS subcategory,
maintenance,
pn.prd_cost AS product_cost,
pn.prd_line AS product_line,
pn.prd_start_dt AS start_date
FROM [Silver].[crm_prd_info] pn
LEFT JOIN
[Silver].[erp_px_cat_g1v2] pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL



--Create fact object gold.fact_sales as a view

IF OBJECT_ID('gold.fact_sales', 'V') IS NOT NULL
   DROP VIEW gold.fact_sales;
 GO

CREATE VIEW gold.fact_sales AS
SELECT
sd.sls_ord_num AS order_number,
dp.product_key,
dc.customer_key,
sd.sls_order_dt AS order_date,
sd.sls_ship_dt AS shipping_date,
sd.sls_due_dt AS due_date,
sd.sls_sales AS sales_amount,
sd.sls_quantity AS quantity,
sd.sls_price AS price
FROM [Silver].[crm_sales_details] sd
LEFT JOIN
gold.dim_products dp
ON sd.sls_prd_key = dp.product_number
LEFT JOIN
gold.dim_customers dc
ON sd.sls_cust_id = dc.customer_id
