/* 
About: This script creates the table structure for the SILVER schema
of data from Olist.

Notes:
- The Silver layer contains cleansed, standardized, and deduplicated data.
- Primary keys and basic constraints (like NOT NULL) are enforced here to ensure data integrity.
- An audit column (silver_insert_time) is added to track pipeline loads.
*/

-- customers table
CREATE TABLE IF NOT EXISTS silver.customers(
    customer_id Text PRIMARY KEY,
    customer_unique_id Text NOT NULL,
    customer_zip_code_prefix Text NOT NULL,
    customer_city varchar(100) NOT NULL ,
    customer_state char(2) NOT NULL,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- geolocation table
-- Note: no PK here — zip code prefixes repeat many times
CREATE TABLE IF NOT EXISTS silver.geolocation(
    geolocation_zip_code_prefix Text NOT NULL  ,
    geolocation_lat double precision NOT NULL , 
    geolocation_lng double precision NOT NULL ,
    geolocation_city Text NOT NULL ,
    geolocation_state char(2) NOT NULL ,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- order_items table
-- Note: Composite PK using order_id and order_item_id
CREATE TABLE IF NOT EXISTS silver.order_items(
    order_id Text NOT NULL,
    order_item_id int NOT NULL,
    product_id Text NOT NULL,
    seller_id Text NOT NULL,
    shipping_limit_date Timestamp,
    price double precision NOT NULL,
    freight_value double precision NOT NULL,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, order_item_id)
);

-- order_payments table
CREATE TABLE IF NOT EXISTS silver.order_payments(
    order_id Text NOT NULL ,
    payment_sequential int NOT NULL ,
    payment_type Text NOT NULL ,
    payment_installments int NOT NULL ,
    payment_value double precision NOT NULL ,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (order_id, payment_sequential)
);

-- order_reviews table
CREATE TABLE IF NOT EXISTS silver.order_reviews(
    review_id Text NOT NULL,
    order_id Text NOT NULL,
    review_score int,
    review_comment_title Text ,
    review_comment_message Text ,
    review_creation_date Timestamp,
    review_answer_timestamp Timestamp,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- orders table
CREATE TABLE IF NOT EXISTS silver.orders(
    order_id Text PRIMARY KEY,
    customer_id Text NOT NULL ,
    order_status Text NOT NULL ,
    order_purchase_timestamp Timestamp,
    order_approved_at Timestamp,
    order_delivered_carrier_date Timestamp,
    order_delivered_customer_date Timestamp,
    order_estimated_delivery_date Timestamp,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- products table
CREATE TABLE IF NOT EXISTS silver.products(
    product_id Text PRIMARY KEY,
    product_category_name varchar(50) NOT NULL ,
    product_name_length int NOT NULL ,
    product_description_length int NOT NULL ,
    product_photos_qty int NOT NULL ,
    product_weight_g int NOT NULL ,
    product_length_cm int NOT NULL ,
    product_height_cm int NOT NULL ,
    product_width_cm int NOT NULL ,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- sellers table
CREATE TABLE IF NOT EXISTS silver.sellers(
    seller_id Text PRIMARY KEY,
    seller_zip_code_prefix Text NOT NULL ,
    seller_city varchar(100) NOT NULL ,
    seller_state char(2) NOT NULL ,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);

-- product_category_name_translation table
CREATE TABLE IF NOT EXISTS silver.product_category_name_translation(
    product_category_name Text PRIMARY KEY,
    product_category_name_english Text,
    silver_insert_time Timestamp DEFAULT CURRENT_TIMESTAMP
);