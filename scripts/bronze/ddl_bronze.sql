/* 
About: This script creates the table structure for the bronze schema
of data from Olist (a Brazilian e-commerce company).

Notes:
- No primary keys or constraints are applied in the bronze layer.
  Bronze is meant to be a raw, unfiltered mirror of the source CSVs.
  Any duplicate/dirty data issues are identified and resolved in the
  silver layer, not here.
- Column names and data types are kept as close to the raw source
  files as possible.
*/


-- customers table
CREATE TABLE IF NOT EXISTS bronze.customers(
customer_id Text,
customer_unique_id Text,
customer_zip_code_prefix Text,
customer_city varchar(50),
customer_state char(2)
);

-- geolocation table
-- Note: no PK here — zip code prefixes repeat many times (multiple lat/lng points per zip area)
CREATE TABLE IF NOT EXISTS bronze.geolocation(
geolocation_zip_code_prefix Text,
geolocation_lat double precision,
geolocation_lng double precision,
geolocation_city Text,
geolocation_state char(2)
);

-- order_items table
-- Note: order_item_id is only unique WITHIN an order, not across the table
CREATE TABLE IF NOT EXISTS bronze.order_items(
order_id Text,
order_item_id int,
product_id Text,
seller_id Text,
shipping_limit_date Timestamp,
price double precision,
freight_value double precision
);

-- order_payments table
-- Note: an order can have multiple payment rows (split/installment payments)
CREATE TABLE IF NOT EXISTS bronze.order_payments(
order_id Text,
payment_sequential int,
payment_type Text,
payment_installments int,
payment_value double precision
);

-- order_reviews table
CREATE TABLE IF NOT EXISTS bronze.order_reviews(
review_id Text,
order_id Text,
review_score int,
review_comment_title Text,
review_comment_message Text,
review_creation_date Timestamp,
review_answer_timestamp Timestamp
);

-- orders table
CREATE TABLE IF NOT EXISTS bronze.orders(
order_id Text,
customer_id Text,
order_status Text,
order_purchase_timestamp Timestamp,
order_approved_at Timestamp,
order_delivered_carrier_date Timestamp,
order_delivered_customer_date Timestamp,
order_estimated_delivery_date Timestamp
);

-- products table
CREATE TABLE IF NOT EXISTS bronze.products(
product_id Text,
product_category_name varchar(50),
product_name_length int,
product_description_length int,
product_photos_qty int,
product_weight_g int,
product_length_cm int,
product_height_cm int,
product_width_cm int
);

-- sellers table
CREATE TABLE IF NOT EXISTS bronze.sellers(
seller_id Text,
seller_zip_code_prefix Text,
seller_city varchar(50),
seller_state char(2)
);

-- product_category_name_translation table
CREATE TABLE IF NOT EXISTS bronze.product_category_name_translation(
product_category_name Text,
product_category_name_english Text
);

