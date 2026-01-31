/*
------------------------------------------------------------------------
Data transformation and quality checks
------------------------------------------------------------------------
Script Purpose: 
       This scripts shows all the steps in the gold layer transfomation
------------------------------------------------------------------------
*/


-------Creating the Customer Dimension
--Join all the CUSTOMER related table
SELECT 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
FROM [Silver].[crm_cust_info] ci
LEFT JOIN
[Silver].[erp_cust_az12] ca
ON ci.cst_key = ca.cid
LEFT JOIN
[Silver].[erp_loc_a101] la
ON ci.cst_key = la.cid


--Check for duplicate primary key
SELECT cst_id, COUNT(*)
FROM
(SELECT 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_gndr,
ci.cst_create_date,
ca.bdate,
ca.gen,
la.cntry
FROM [Silver].[crm_cust_info] ci
LEFT JOIN
[Silver].[erp_cust_az12] ca
ON ci.cst_key = ca.cid
LEFT JOIN
[Silver].[erp_loc_a101] la
ON ci.cst_key = la.cid)t
GROUP BY cst_id
HAVING COUNT(*) > 1

--Integrate the gender columns from the joined table
--Check for gender mismatch in the cust_info and cust_az112 gender columns

SELECT DISTINCT
ci.cst_gndr,
ca.gen
FROM [Silver].[crm_cust_info] ci
LEFT JOIN
[Silver].[erp_cust_az12] ca
ON ci.cst_key = ca.cid
LEFT JOIN
[Silver].[erp_loc_a101] la
ON ci.cst_key = la.cid


--Integrate the gender columns from the join by adopting the cust_info as the Master
SELECT 
ci.cst_id,
ci.cst_key,
ci.cst_firstname,
ci.cst_lastname,
ci.cst_marital_status,
ci.cst_create_date,
ca.bdate,
CASE WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr
     ELSE COALESCE(ca.gen, 'n/a')
	 END new_gen,
la.cntry
FROM [Silver].[crm_cust_info] ci
LEFT JOIN
[Silver].[erp_cust_az12] ca
ON ci.cst_key = ca.cid
LEFT JOIN
[Silver].[erp_loc_a101] la
ON ci.cst_key = la.cid


--Rename columns to friendly column names & reorder columns

SELECT 
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


--generate a surrogate key for the demension customers

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


SELECT * FROM gold.dim_customers


------Creating the Product Dimension with current prduct data
--Join all related product tables

SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
cat,
subcat,
maintenance
FROM [Silver].[crm_prd_info] pn
LEFT JOIN
[Silver].[erp_px_cat_g1v2] pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL  --Filters current data


--Check for duplicate product key

SELECT prd_key, COUNT(*)
FROM
(SELECT 
pn.prd_id,
pn.cat_id,
pn.prd_key,
pn.prd_nm,
pn.prd_cost,
pn.prd_line,
pn.prd_start_dt,
cat,
subcat,
maintenance
FROM [Silver].[crm_prd_info] pn
LEFT JOIN
[Silver].[erp_px_cat_g1v2] pc
ON pn.cat_id = pc.id
WHERE pn.prd_end_dt IS NULL)t
GROUP BY prd_key
HAVING COUNT(*) > 1


--Rename columms and sort then in a logical order

SELECT 
pn.prd_id AS product_id,
pn.prd_key AS product_key,
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

--Create surrogate key for dimension products

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


------Joining the customer & product dimensions to the sales fact table in order to bring in the product & customer surrogate keys
--Replace sls_prd_key with product_key (product dimension surrogate key) also replace sls_cust_id with customer_key (customer dimension surrogate key)

SELECT
sd.sls_ord_num,
dp.product_key,
dc.customer_key,
sd.sls_order_dt,
sd.sls_ship_dt,
sd.sls_due_dt,
sd.sls_sales,
sd.sls_quantity,
sd.sls_price
FROM [Silver].[crm_sales_details] sd
LEFT JOIN
gold.dim_products dp
ON sd.sls_prd_key = dp.product_number
LEFT JOIN
gold.dim_customers dc
ON sd.sls_cust_id = dc.customer_id


--Rename columns

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
