USE ecommerce_analysis;
# now comes the analysis

-- 1 Total number of orders 

SELECT count(distinct(order_id))AS total_orders FROM fact_orders;

-- 2 Total revenue

WITH AGGREGATED  AS (SELECT order_id,SUM(payment_value) AS total_revenue FROM fact_orders group by order_id)
SELECT sum(total_revenue) AS revenue from AGGREGATED;
  
-- 3 Unique customer count

SELECT count(distinct(customer_id)) AS unique_customers from dim_customers;

-- 4 Revenue per order

WITH aggregated_2 AS (select SUM(payment_value) AS total,order_id  from fact_orders group by order_id)
SELECT avg(total) as AOV FROM aggregated_2;

-- 5 MONTHLY REVENUE

WITH aggregated_3 AS (select order_id,order_purchase_timestamp,SUM(payment_value) AS total  from fact_orders group by order_id,order_purchase_timestamp)
select year(order_purchase_timestamp) as purchase_year,month(order_purchase_timestamp) as MONth_purchased,SUM(total) AS monthly_revenue from aggregated_3 
group by purchase_year,MONth_purchased;

-- 6 ORDER PER MONTH

select year(order_purchase_timestamp) as purchase_year,month(order_purchase_timestamp) as MONth_purchased,count(distinct(order_id)) AS order_purchased_monthly from fact_orders 
group by  purchase_year,MONth_purchased;

-- 7 growth per month

WITH monthly AS (select order_id,order_purchase_timestamp,SUM(payment_value) AS total  from fact_orders group by order_id,order_purchase_timestamp),
month_table as (
select year(order_purchase_timestamp) as purchase_year,month(order_purchase_timestamp) as MONth_purchased,SUM(total) AS monthly_revenue from monthly 
group by purchase_year,MONth_purchased)
, lagged as (select purchase_year,MONth_purchased,monthly_revenue,lag(monthly_revenue) over (order by purchase_year,MONth_purchased) AS previous_month_revenue from month_table)
SELECT 
    purchase_year,month_purchased,
    monthly_revenue,previous_month_revenue,
    case 
    when previous_month_revenue is null then null
    when previous_month_revenue = 0  then null
     else ((monthly_revenue - previous_month_revenue) / previous_month_revenue) * 100
    end as growth 
FROM lagged;

-- 8 Customers with highest total spending

with order_level as (select customer_id,order_id,sum(payment_value) as total_spending from fact_orders group by customer_id,order_id)
select customer_id,sum(total_spending) as revenue from order_level group by customer_id
order by revenue desc;

-- 9 repeat vs new customers 
select customer_id,count(distinct(order_id)) as order_count,
case
when count(distinct(order_id)) >1 then 'Repeated'
else 'new'
end as customer_type from fact_orders group by customer_id;

-- 10 Total revenue per customer
WITH order_level AS (
    SELECT order_id, customer_id, SUM(payment_value) AS order_revenue
    FROM fact_orders
    GROUP BY order_id, customer_id
)
SELECT customer_id, SUM(order_revenue) AS total_revenue
FROM order_level
GROUP BY customer_id;

-- 11 Top 10 customers by revenu
WITH order_level AS (
    SELECT order_id, customer_id, SUM(payment_value) AS order_revenue
    FROM fact_orders
    GROUP BY order_id, customer_id
)
SELECT customer_id, SUM(order_revenue) AS total_revenue
FROM order_level
GROUP BY customer_id
order by total_revenue desc
limit 10;

-- customer segmentation
WITH order_level AS (
    SELECT order_id, customer_id, SUM(payment_value) AS order_revenue
    FROM fact_orders
    GROUP BY order_id, customer_id
),
customer_total AS (
    SELECT customer_id, SUM(order_revenue) AS total_revenue
    FROM order_level
    GROUP BY customer_id
)
SELECT customer_id,
       total_revenue,
       CASE 
           WHEN total_revenue > 50000 THEN 'High Value'
           WHEN total_revenue > 20000 THEN 'Mid Value'
           ELSE 'Low Value'
       END AS customer_segment
FROM customer_total;

-- average orders per customers 

with order_count as (select customer_id, count(distinct(order_id)) as order_count_per_cust from fact_orders group by customer_id)
select avg(order_count_per_cust) as average_order_count from order_count;

-- Top selling products by quantity

SELECT product_id, COUNT(*) AS total_quantity_sold
FROM fact_orders
GROUP BY product_id
ORDER BY total_quantity_sold DESC;


-- most revenue generating products 

SELECT product_id, SUM(price + freight_value) AS revenue
FROM fact_orders
GROUP BY product_id
ORDER BY revenue DESC;

-- Category wise revenue

select  coalesce(dp.product_category_name,'UnKnown'),sum(fo.price+fo.freight_value) AS category_wise_revenue from fact_orders fo left join dim_products dp on fo.product_id = dp.product_id
group by dp.product_category_name;

-- profit analysis

SELECT COALESCE(dp.product_category_name, 'Unknown') AS category,
       SUM(fo.price - fo.freight_value) AS total_profit
FROM fact_orders fo
LEFT JOIN dim_products dp 
    ON fo.product_id = dp.product_id
GROUP BY category;

-- data import for bi
select * from dim_customers;
select * from dim_products;
select * from dim_sellers;
select * from fact_orders;