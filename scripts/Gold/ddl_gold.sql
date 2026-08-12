/*
About: This script creates the table structure for the GOLD schema
of the Olist data warehouse — a star schema built for analytics
and Power BI reporting.

Notes:
- Naming convention: dim_* for dimension tables, fact_* for fact tables.
- fact_order_items carries foreign keys to every dimension, enforced with
  FOREIGN KEY constraints — standard star schema practice.
- Grain of fact_order_items: one row per order item (matches silver.order_items).
- Order/payment/review data (which are order-grain, not item-grain) is
  denormalized down to item-level for simpler, single-table Power BI queries.
*/

CREATE SCHEMA IF NOT EXISTS gold;


-- ============================================================
-- DIMENSION TABLES
-- ============================================================

-- dim_date: fully generated calendar dimension, no source table in silver
CREATE TABLE IF NOT EXISTS gold.dim_date (
    date_key INT PRIMARY KEY,
    full_date DATE NOT NULL,
    year INT,
    quarter INT,
    month INT,
    month_name TEXT,
    day INT,
    day_name TEXT,
    week_of_year INT,
    is_weekend BOOLEAN
);

-- dim_customer
CREATE TABLE IF NOT EXISTS gold.dim_customer(
    customer_key SERIAL PRIMARY KEY,
    customer_id TEXT NOT NULL,
    customer_unique_id TEXT NOT NULL,
    customer_city TEXT,
    customer_state CHAR(2),
    customer_lat DOUBLE PRECISION,
    customer_lng DOUBLE PRECISION,
	customer_type TEXT
);

-- dim_seller
CREATE TABLE IF NOT EXISTS gold.dim_seller(
    seller_key SERIAL PRIMARY KEY,
    seller_id TEXT NOT NULL,
    seller_city TEXT,
    seller_state CHAR(2),
    seller_lat DOUBLE PRECISION,
    seller_lng DOUBLE PRECISION
);

-- dim_product
CREATE TABLE IF NOT EXISTS gold.dim_product(
    product_key SERIAL PRIMARY KEY,
    product_id TEXT NOT NULL,
    product_category_english TEXT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT,
    product_volume_cm3 INT,
    product_size_category TEXT
);


-- ============================================================
-- FACT TABLE
-- ============================================================

CREATE TABLE IF NOT EXISTS gold.fact_order_items(
    order_item_key SERIAL PRIMARY KEY,
    order_id TEXT NOT NULL,
    order_item_id INT,
    customer_key INT REFERENCES gold.dim_customer(customer_key),
    seller_key INT REFERENCES gold.dim_seller(seller_key),
    product_key INT REFERENCES gold.dim_product(product_key),
    order_date_key INT REFERENCES gold.dim_date(date_key),
    order_status TEXT,
    price NUMERIC,
    freight_value NUMERIC,
    total_item_value NUMERIC,
    total_payment_value NUMERIC,
    installments INT,
    payment_type TEXT,
    review_score INT,
    order_purchase_timestamp TIMESTAMP,
    shipping_limit_date TIMESTAMP,
    order_delivered_carrier_date TIMESTAMP,
    order_delivered_customer_date TIMESTAMP,
    order_estimated_delivery_date TIMESTAMP,
    delivery_days NUMERIC,
    approval_days NUMERIC,
    carrier_to_delivery_days NUMERIC,
    is_late_shipment BOOLEAN,
    is_late_delivery BOOLEAN,
    is_delivered BOOLEAN
);
