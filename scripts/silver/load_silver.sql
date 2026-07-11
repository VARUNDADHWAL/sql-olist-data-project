/* About: This procedure load raw data from bronze schema and Transform and clean it and insert into silver schema.

Notes:
	- This data is cleaned and tranformed and ready to do analysis and making insights.
	- This Truncate each table from silver schema right before insert data.
*/

CREATE OR REPLACE PROCEDURE silver.load_silver()
LANGUAGE plpgsql
AS $$ 
DECLARE 
	start_time Timestamp;
	end_time Timestamp;
	batch_start_time Timestamp;
	batch_end_time Timestamp;
BEGIN 
	batch_start_time:=clock_timestamp();
	RAISE NOTICE '=========================================';
	RAISE NOTICE 'Loading Silver Layer';
	RAISE NOTICE '=========================================';
	
	CREATE EXTENSION IF NOT EXISTS unaccent;
	
	BEGIN
		start_time:= clock_timestamp();
		RAISE NOTICE'>> Truncating table silver.customers';
		-- customer table 
		TRUNCATE TABLE silver.customers;
		RAISE NOTICE '>> Loading Data Into : silver.customers';
		INSERT INTO silver.customers (
		    customer_id,
		    customer_unique_id,
		    customer_zip_code_prefix,
		    customer_city,
		    customer_state
		) 
		SELECT
		    TRIM(customer_id),
		    TRIM(customer_unique_id),
		    TRIM(customer_zip_code_prefix),
		    COALESCE(INITCAP(TRIM(unaccent(customer_city))), 'Unknown'),
		    UPPER(TRIM(customer_state)) 
		FROM bronze.customers;
		end_time:=clock_timestamp();
		RAISE NOTICE '>> Load duration: % seconds',EXTRACT(epoch FROM (end_time - start_time));
		RAISE NOTICE ' ';
		start_time:=clock_timestamp();
		RAISE NOTICE 'Truncating table : silver.geolocation';
		-- geolocation table 
		TRUNCATE TABLE silver.geolocation;
		RAISE NOTICE ' '
		RAISE NOTICE '>> Insert Data Into : silver.geolocation';
		INSERT INTO silver.geolocation(
			geolocation_zip_code_prefix,
			geolocation_lat,
			geolocation_lng,
			geolocation_city,
			geolocation_state
		)select 
			TRIM(geolocation_zip_code_prefix),
			ROUND(AVG(geolocation_lat)::numeric,6),
			ROUND(AVG(geolocation_lng)::numeric,6),
			INITCAP(TRIM(unaccent(MODE() WITHIN GROUP (ORDER BY geolocation_city)))),
			UPPER(TRIM(MODE() WITHIN GROUP (ORDER BY geolocation_state)))
		FROM bronze.geolocation
		where geolocation_lat  BETWEEN -33.75 AND 5.27
		  AND geolocation_lng  BETWEEN -73.99 AND -34.79
		GROUP BY TRIM(geolocation_zip_code_prefix);
		end_time:=clock_timestamp();
		RAISE NOTICE ' >> Load duration : % seconds',EXTRACT(epoch FROM (end_time - start_time));
		RAISE NOTICE ' ';
		start_time:= clock_timestamp();
		RAISE NOTICE 'Truncating Table silver.order_items';
		-- order_items table
		TRUNCATE TABLE silver.order_items;
		RAISE NOTICE ' ';
		INSERT INTO silver.order_items (
		    order_id,
		    order_item_id,
		    product_id,
		    seller_id,
		    shipping_limit_date,
		    price,
		    freight_value
		)
		SELECT
		    TRIM(order_id),
		    order_item_id,
		    TRIM(product_id),
		    TRIM(seller_id),
		    shipping_limit_date,
		    price,
		    freight_value
		FROM bronze.order_items;
		end_time := clock_timestamp();
		RAISE NOTICE'>> Load duration : % seconds',EXTRACT(epoch FROM(end_time - start_time));
		RAISE NOTICE ' ';
		start_time:= clock_timestamp();
		RAISE NOTICE 'Truncating table silver.order_payments';
		RAISE NOTICE ' ';
		-- order_payments table 
		TRUNCATE TABLE silver.order_payments;
		RAISE NOTICE '>> Loading Data Into : silver.order_payments';
		INSERT INTO silver.order_payments (
		    order_id,
		    payment_sequential,
		    payment_type,
		    payment_installments,
		    payment_value
		)
		SELECT
		    TRIM(order_id),
		    payment_sequential,
		    TRIM(payment_type),
		    CASE
		        WHEN payment_installments = 0 THEN 1
		        ELSE payment_installments
		    END AS payment_installments,
		    payment_value
		FROM bronze.order_payments;
		RAISE NOTICE ' ';
		end_time:=clock_timestamp();
		RAISE NOTICE 'Load duration : % seconds',EXTRACT(epoch FROM (end_time - start_time));
		RAISE NOTICE ' ';
		start_time:=clock_timestamp();
		RAISE NOTICE'Truncating table silver.order_reviews'
		RAISE NOTICE ' ';
		-- order_reviews table 
		TRUNCATE TABLE silver.order_reviews;
		RAISE NOTICE '>> Loading Data Into : silver.order_reviews'
		INSERT INTO silver.order_reviews (
		    review_id,
		    order_id,
		    review_score,
		    review_comment_title,
		    review_comment_message,
		    review_creation_date,
		    review_answer_timestamp
		)
		SELECT
		    TRIM(review_id),
		    TRIM(order_id),
		    review_score,
		    TRIM(review_comment_title),
		    TRIM(review_comment_message),
		    review_creation_date,
		    review_answer_timestamp
		FROM bronze.order_reviews;
		RAISE NOTICE ' ';
		end_time:=clock_timestamp();
		RAISE NOTICE 'Load d'
		-- orders table 
		TRUNCATE TABLE silver.orders;
		INSERT INTO silver.orders (
		    order_id,
		    customer_id,
		    order_status,
		    order_purchase_timestamp,
		    order_approved_at,
		    order_delivered_carrier_date,
		    order_delivered_customer_date,
		    order_estimated_delivery_date
		)
		SELECT
		    TRIM(order_id),
		    TRIM(customer_id),
		    LOWER(TRIM(order_status)),
		    order_purchase_timestamp,
		
		    CASE
		        WHEN order_approved_at < order_purchase_timestamp THEN NULL
		        ELSE order_approved_at
		    END AS order_approved_at,
		
		    order_delivered_carrier_date,
		
		    CASE
		        WHEN order_delivered_customer_date < order_purchase_timestamp THEN NULL
		        WHEN order_delivered_customer_date < order_delivered_carrier_date THEN NULL
		        ELSE order_delivered_customer_date
		    END AS order_delivered_customer_date,
		
		    order_estimated_delivery_date
		
		FROM bronze.orders;
		
		-- products table
		TRUNCATE TABLE silver.products;
		INSERT INTO silver.products (
		    product_id,
		    product_category_name,
		    product_name_length,
		    product_description_length,
		    product_photos_qty,
		    product_weight_g,
		    product_length_cm,
		    product_height_cm,
		    product_width_cm
		)
		SELECT
		    TRIM(product_id),
		    COALESCE(TRIM(product_category_name), 'unknown'),
		    COALESCE(product_name_length, 0),
		    COALESCE(product_description_length, 0),
		    COALESCE(product_photos_qty, 0),
		    product_weight_g,       
		    product_length_cm,
		    product_height_cm,
		    product_width_cm
		FROM bronze.products;
		
		-- sellers table 
		TRUNCATE TABLE  silver.sellers;
		INSERT INTO silver.sellers (
		    seller_id,
		    seller_zip_code_prefix,
		    seller_city,
		    seller_state
		)
		SELECT
		    TRIM(seller_id),
		    TRIM(seller_zip_code_prefix),
		    INITCAP(TRIM(unaccent(seller_city))),
		    UPPER(TRIM(seller_state))
		FROM bronze.sellers;
		
		-- product_category_name_translation table
		TRUNCATE TABLE silver.product_category_name_translation;
		INSERT INTO silver.product_category_name_translation(
			product_category_name,
			product_category_name_english
		)SELECT
		TRIM(product_category_name),
		TRIM(product_category_name_english)
		FROM bronze.product_category_name_translation;
	





		
