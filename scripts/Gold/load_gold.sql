/* About: This procedure loads the gold layer from the silver layer —
populates all dimension tables, then the fact table.

Usage:
	CALL gold.load_gold();
*/

CREATE OR REPLACE PROCEDURE gold.load_gold()
LANGUAGE plpgsql
AS $$
DECLARE
	start_time Timestamp;
	end_time Timestamp;
	batch_start_time Timestamp;
	batch_end_time Timestamp;
BEGIN
	batch_start_time := clock_timestamp();
	RAISE NOTICE '=========================================';
	RAISE NOTICE 'Loading Gold Layer';
	RAISE NOTICE '=========================================';

	BEGIN
		-- Step 1: truncate the fact table first (child of all dimensions)
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: gold.fact_order_items (must run before dimensions due to FK constraints)';
		TRUNCATE TABLE gold.fact_order_items;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Truncate Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		-- dim_date
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: gold.dim_date';
		TRUNCATE TABLE gold.dim_date CASCADE;
		RAISE NOTICE '>> Loading Data Into: gold.dim_date';
		INSERT INTO gold.dim_date (
			date_key,
			full_date,
			year,
			quarter,
			month,
			month_name,
			day,
			day_name,
			week_of_year,
			is_weekend
		)
		SELECT
			TO_CHAR(d, 'YYYYMMDD')::INT AS date_key,
			d::DATE AS full_date,
			EXTRACT(YEAR FROM d)::INT AS year,
			EXTRACT(QUARTER FROM d)::INT AS quarter,
			EXTRACT(MONTH FROM d)::INT AS month,
			TO_CHAR(d, 'FMMonth') AS month_name,
			EXTRACT(DAY FROM d)::INT AS day,
			TO_CHAR(d, 'FMDay') AS day_name,
			EXTRACT(WEEK FROM d)::INT AS week_of_year,
			(EXTRACT(ISODOW FROM d) IN (6,7)) AS is_weekend
		FROM generate_series(
			(SELECT MIN(order_purchase_timestamp)::DATE - INTERVAL '3 months' FROM silver.orders),
			(SELECT MAX(order_estimated_delivery_date)::DATE + INTERVAL '3 months' FROM silver.orders),
			INTERVAL '1 day'
		) AS d;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		-- dim_customer
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: gold.dim_customer';
		TRUNCATE TABLE gold.dim_customer RESTART IDENTITY CASCADE;
		RAISE NOTICE '>> Loading Data Into: gold.dim_customer';
		WITH customer_order_counts AS (
    SELECT
        customer_unique_id,
        COUNT(DISTINCT order_id) AS order_count
    FROM silver.customers c
    JOIN silver.orders o ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY customer_unique_id
)
INSERT INTO gold.dim_customer(
    customer_id,
    customer_unique_id,
    customer_city,
    customer_state,
    customer_lat,
    customer_lng,
    customer_type
)
SELECT
    c.customer_id,
    c.customer_unique_id,
    c.customer_city,
    c.customer_state,
    g.geolocation_lat,
    g.geolocation_lng,
    CASE WHEN coc.order_count > 1 THEN 'Repeat' ELSE 'One-Time' END AS customer_type
FROM silver.customers c
LEFT JOIN silver.geolocation g
    ON c.customer_zip_code_prefix = g.geolocation_zip_code_prefix
LEFT JOIN customer_order_counts coc
    ON c.customer_unique_id = coc.customer_unique_id;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		-- dim_seller
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: gold.dim_seller';
		TRUNCATE TABLE gold.dim_seller RESTART IDENTITY CASCADE;
		RAISE NOTICE '>> Loading Data Into: gold.dim_seller';
		INSERT INTO gold.dim_seller(
			seller_id,
			seller_city,
			seller_state,
			seller_lat,
			seller_lng
		)
		SELECT
			s.seller_id,
			s.seller_city,
			s.seller_state,
			g.geolocation_lat,
			g.geolocation_lng
		FROM silver.sellers s
		LEFT JOIN silver.geolocation g
			ON s.seller_zip_code_prefix = g.geolocation_zip_code_prefix;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		-- dim_product
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: gold.dim_product';
		TRUNCATE TABLE gold.dim_product RESTART IDENTITY CASCADE;
		RAISE NOTICE '>> Loading Data Into: gold.dim_product';
		INSERT INTO gold.dim_product (
			product_id,
			product_category_english,
			product_weight_g,
			product_length_cm,
			product_height_cm,
			product_width_cm,
			product_volume_cm3,
			product_size_category
		)
		SELECT
			p.product_id,
			t.product_category_name_english,
			p.product_weight_g,
			p.product_length_cm,
			p.product_height_cm,
			p.product_width_cm,
			p.product_length_cm * p.product_height_cm * p.product_width_cm AS product_volume_cm3,
			CASE
				WHEN p.product_weight_g IS NULL THEN NULL
				WHEN p.product_weight_g < 1000 THEN 'Small'
				WHEN p.product_weight_g < 10000 THEN 'Medium'
				ELSE 'Large'
			END AS product_size_category
		FROM silver.products p
		LEFT JOIN silver.product_category_name_translation t
			ON p.product_category_name = t.product_category_name;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		-- fact_order_items (loaded last, using fresh surrogate keys from above)
		start_time := clock_timestamp();
		RAISE NOTICE '>> Loading Data Into: gold.fact_order_items';
		INSERT INTO gold.fact_order_items (
			order_id,
			order_item_id,
			customer_key,
			seller_key,
			product_key,
			order_date_key,
			order_status,
			price,
			freight_value,
			total_item_value,
			total_payment_value,
			installments,
			payment_type,
			review_score,
			order_purchase_timestamp,
			shipping_limit_date,
			order_delivered_carrier_date,
			order_delivered_customer_date,
			order_estimated_delivery_date,
			delivery_days,
			approval_days,
			carrier_to_delivery_days,
			is_late_shipment,
			is_late_delivery,
			is_delivered
		)
		WITH order_payment_summary AS (
			SELECT
				order_id,
				SUM(payment_value) AS total_payment_value,
				MAX(payment_installments) AS installments,
				MAX(payment_type) AS payment_type
			FROM silver.order_payments
			GROUP BY order_id
		),
		order_review_summary AS (
			SELECT
				order_id,
				MAX(review_score) AS review_score
			FROM silver.order_reviews
			GROUP BY order_id
		)
		SELECT
			oi.order_id,
			oi.order_item_id,
			c.customer_key,
			s.seller_key,
			p.product_key,
			TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD')::INT AS order_date_key,
			o.order_status,
			oi.price,
			oi.freight_value,
			oi.price + oi.freight_value AS total_item_value,
			ops.total_payment_value,
			ops.installments,
			ops.payment_type,
			ors.review_score,
			o.order_purchase_timestamp,
			oi.shipping_limit_date,
			o.order_delivered_carrier_date,
			o.order_delivered_customer_date,
			o.order_estimated_delivery_date,

			CASE WHEN o.order_delivered_customer_date IS NOT NULL
				THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400
				ELSE NULL
			END AS delivery_days,

			CASE WHEN o.order_approved_at IS NOT NULL
				THEN EXTRACT(EPOCH FROM (o.order_approved_at - o.order_purchase_timestamp)) / 86400
				ELSE NULL
			END AS approval_days,

			CASE WHEN o.order_delivered_carrier_date IS NOT NULL AND o.order_delivered_customer_date IS NOT NULL
				THEN EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_delivered_carrier_date)) / 86400
				ELSE NULL
			END AS carrier_to_delivery_days,

			CASE WHEN o.order_delivered_carrier_date IS NOT NULL
				THEN o.order_delivered_carrier_date > oi.shipping_limit_date
				ELSE NULL
			END AS is_late_shipment,

			CASE WHEN o.order_delivered_customer_date IS NOT NULL
				THEN o.order_delivered_customer_date > o.order_estimated_delivery_date
				ELSE NULL
			END AS is_late_delivery,

			(o.order_status = 'delivered') AS is_delivered

		FROM silver.order_items oi
		JOIN silver.orders o ON oi.order_id = o.order_id
		JOIN gold.dim_customer c ON o.customer_id = c.customer_id
		JOIN gold.dim_seller s ON oi.seller_id = s.seller_id
		JOIN gold.dim_product p ON oi.product_id = p.product_id
		LEFT JOIN order_payment_summary ops ON oi.order_id = ops.order_id
		LEFT JOIN order_review_summary ors ON oi.order_id = ors.order_id;
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));
		RAISE NOTICE ' ';

		batch_end_time := clock_timestamp();
		RAISE NOTICE '=========================================';
		RAISE NOTICE 'Gold Layer Load Completed Successfully';
		RAISE NOTICE '   Total Load Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
		RAISE NOTICE '=========================================';

	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE '=========================================';
		RAISE NOTICE 'ERROR OCCURRED DURING LOADING GOLD LAYER';
		RAISE NOTICE 'Error Message: %', SQLERRM;
		RAISE NOTICE '=========================================';
	END;
END;
$$;

-- To run:
CALL gold.load_gold();
