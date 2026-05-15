USE ecommerce_analysis;
-- checking how many nulls each column have and filtering them based on the result
SELECT 
    COUNT(*) AS total_rows,
    SUM(customer_id IS NULL) AS null_customer_id,
    SUM(customer_unique_id IS NULL) AS null_unique_id,
    SUM(customer_zip_code_prefix IS NULL) AS null_zip,
    SUM(customer_city IS NULL) AS null_city,
    SUM(customer_state IS NULL) AS null_state
FROM customers_raw;
-- now we can insert the filtered result
INSERT INTO dim_customers (customer_id, customer_unique_id, customer_zip_code_prefix, customer_city, customer_state)
SELECT DISTINCT
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state
FROM customers_raw
WHERE customer_id IS NOT NULL;

SELECT 
    COUNT(*) AS total_rows,
    SUM(product_id IS NULL) AS null_product_id,
    SUM(product_name_lenght IS NULL) AS null_name_length,
    SUM(product_weight_g IS NULL) AS null_weight,
    SUM(product_length_cm IS NULL) AS null_length,
    SUM(product_width_cm IS NULL) AS null_width
FROM products_raw;
-- here name_length column  has almost 600 nulls so we can not filter on basis of that we can filter on weigth and width because they have very less null rows 

INSERT INTO dim_products
SELECT DISTINCT *
FROM products_raw
WHERE product_id IS NOT NULL and product_weight_g is not null and product_length_cm is not null and product_width_cm is not null;

INSERT INTO dim_sellers
SELECT DISTINCT
    seller_id,
    seller_zip_code_prefix,
    seller_city,
    seller_state
FROM sellers_raw
WHERE seller_id IS NOT NULL;

create temporary table payment_aggregation as 
select order_id,sum(payment_value) as total_payment from order_payments_raw
group by order_id ;
