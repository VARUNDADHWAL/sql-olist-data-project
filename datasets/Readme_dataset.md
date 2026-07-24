# Dataset

This project uses the **Olist Brazilian E-Commerce Public Dataset**, available on Kaggle:

🔗 https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce

## Setup Instructions
1. Download the dataset from the link above (9 CSV files, ~140MB total)
2. Place the CSVs in this folder before running the bronze layer load scripts
3. Update the file paths in `scripts/bronze/load_bronze.sql` to match your local path

## Files expected
- olist_customers_dataset.csv
- olist_geolocation_dataset.csv
- olist_order_items_dataset.csv
- olist_order_payments_dataset.csv
- olist_order_reviews_dataset.csv
- olist_orders_dataset.csv
- olist_products_dataset.csv
- olist_sellers_dataset.csv
- product_category_name_translation.csv
