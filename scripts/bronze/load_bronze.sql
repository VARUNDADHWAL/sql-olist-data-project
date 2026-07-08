/*
About: This procedure loads data from raw CSV files into the bronze schema.

Notes:
- Only loads raw data — no transformations applied here.
- Truncates each table before loading (full reload every run).
- Update the file paths below to match your local data folder before running.

*/

CREATE OR REPLACE PROCEDURE bronze.load_bronze()
LANGUAGE plpgsql
AS $$
DECLARE
	start_time TIMESTAMP;
	end_time TIMESTAMP;
	batch_start_time TIMESTAMP;
	batch_end_time TIMESTAMP;
BEGIN
	batch_start_time := clock_timestamp();
	RAISE NOTICE '================================================';
	RAISE NOTICE 'Loading Bronze Layer';
	RAISE NOTICE '================================================';

	BEGIN
		-- customers
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.customers';
		TRUNCATE TABLE bronze.customers;
		RAISE NOTICE '>> Loading Data Into: bronze.customers';
		COPY bronze.customers
		FROM 'D:\olist\data\olist_customers_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- geolocation
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.geolocation';
		TRUNCATE TABLE bronze.geolocation;
		RAISE NOTICE '>> Loading Data Into: bronze.geolocation';
		COPY bronze.geolocation
		FROM 'D:\olist\data\olist_geolocation_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- order_items
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.order_items';
		TRUNCATE TABLE bronze.order_items;
		RAISE NOTICE '>> Loading Data Into: bronze.order_items';
		COPY bronze.order_items
		FROM 'D:\olist\data\olist_order_items_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- order_payments
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.order_payments';
		TRUNCATE TABLE bronze.order_payments;
		RAISE NOTICE '>> Loading Data Into: bronze.order_payments';
		COPY bronze.order_payments
		FROM 'D:\olist\data\olist_order_payments_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- order_reviews
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.order_reviews';
		TRUNCATE TABLE bronze.order_reviews;
		RAISE NOTICE '>> Loading Data Into: bronze.order_reviews';
		COPY bronze.order_reviews
		FROM 'D:\olist\data\olist_order_reviews_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- orders
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.orders';
		TRUNCATE TABLE bronze.orders;
		RAISE NOTICE '>> Loading Data Into: bronze.orders';
		COPY bronze.orders
		FROM 'D:\olist\data\olist_orders_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- products
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.products';
		TRUNCATE TABLE bronze.products;
		RAISE NOTICE '>> Loading Data Into: bronze.products';
		COPY bronze.products
		FROM 'D:\olist\data\olist_products_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- sellers
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.sellers';
		TRUNCATE TABLE bronze.sellers;
		RAISE NOTICE '>> Loading Data Into: bronze.sellers';
		COPY bronze.sellers
		FROM 'D:\olist\data\olist_sellers_dataset.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		-- product_category_name_translation
		start_time := clock_timestamp();
		RAISE NOTICE '>> Truncating Table: bronze.product_category_name_translation';
		TRUNCATE TABLE bronze.product_category_name_translation;
		RAISE NOTICE '>> Loading Data Into: bronze.product_category_name_translation';
		COPY bronze.product_category_name_translation
		FROM 'D:\olist\data\product_category_name_translation.csv'
		WITH (FORMAT csv, HEADER TRUE, DELIMITER ',');
		end_time := clock_timestamp();
		RAISE NOTICE '>> Load Duration: % seconds', EXTRACT(EPOCH FROM (end_time - start_time));

		batch_end_time := clock_timestamp();
		RAISE NOTICE '================================================';
		RAISE NOTICE 'Bronze Layer Load Completed Successfully';
		RAISE NOTICE '   Total Load Duration: % seconds', EXTRACT(EPOCH FROM (batch_end_time - batch_start_time));
		RAISE NOTICE '================================================';

	EXCEPTION WHEN OTHERS THEN
		RAISE NOTICE '================================================';
		RAISE NOTICE 'ERROR OCCURRED DURING LOADING BRONZE LAYER';
		RAISE NOTICE 'Error Message: %', SQLERRM;
		RAISE NOTICE '================================================';
	END;
END;
$$;




-- Quick verification queries (row counts, not full SELECT * — geolocation has ~1M rows)
--SELECT COUNT(*) FROM bronze.customers;
--SELECT COUNT(*) FROM bronze.geolocation;
--SELECT COUNT(*) FROM bronze.order_items;
--SELECT COUNT(*) FROM bronze.order_payments;
--SELECT COUNT(*) FROM bronze.order_reviews;
--SELECT COUNT(*) FROM bronze.orders;
--SELECT COUNT(*) FROM bronze.products;
--SELECT COUNT(*) FROM bronze.sellers;
--SELECT COUNT(*) FROM bronze.product_category_name_translation;


call bronze.load_bronze();
