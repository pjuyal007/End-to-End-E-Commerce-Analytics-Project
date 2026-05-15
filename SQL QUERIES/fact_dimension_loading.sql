USE ecommerce_analysis;
CREATE TABLE fact_orders(
    order_id CHAR(32),
    customer_id CHAR(32),
    order_purchase_timestamp DATETIME,
    order_delivered_customer_date DATETIME,
    
    product_id CHAR(32),
    seller_id CHAR(32),
    
    price DECIMAL(10,2),
    freight_value DECIMAL(10,2),
    payment_value DECIMAL(10,2)
);

INSERT INTO fact_orders
SELECT 
    o.order_id,
    o.customer_id,
    
    STR_TO_DATE(o.order_purchase_timestamp, '%m/%d/%Y %H:%i'),
    STR_TO_DATE(o.order_delivered_customer_date, '%m/%d/%Y %H:%i'), -- to make date in format for sql
    
    oi.product_id,
    oi.seller_id,
    
    CAST(oi.price AS DECIMAL(10,2)),
    CAST(oi.freight_value AS DECIMAL(10,2)),  -- corrected the data type beacause in order item table they are of double type
    
    CASE 
        WHEN p.total_payment IS NULL THEN 0
        ELSE CAST(TRIM(p.total_payment) AS DECIMAL(10,2))
    END
FROM orders_raw o
JOIN order_items_raw oi 
    ON o.order_id = oi.order_id
LEFT JOIN payment_aggregation p 
    ON o.order_id = p.order_id;