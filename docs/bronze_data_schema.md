# Bronze Layer — Data Schema

## Overview

The **Bronze Layer** stores raw, unprocessed data exactly as received from the source CSV files (Olist Brazilian E-Commerce dataset, via Kaggle). No transformations, cleaning, or constraints are applied at this stage — it serves as a mirror of the original source data.

- **Schema:** `bronze`
- **Source:** [Olist Brazilian E-Commerce Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- **Load method:** `COPY` (PostgreSQL), full truncate & reload per run
- **Constraints:** None — no primary keys, foreign keys, or NOT NULL constraints are enforced in this layer. Data quality issues are identified and resolved in the Silver layer.

---

## Table: `bronze.customers`

Stores customer identity and location information.

| Column Name | Data Type | Description |
|---|---|---|
| customer_id | Text | Unique identifier for a customer per order (changes per order) |
| customer_unique_id | Text | Unique identifier for a customer across all their orders |
| customer_zip_code_prefix | Text | First 5 digits of customer's zip code |
| customer_city | varchar(50) | Customer's city |
| customer_state | char(2) | Customer's state (2-letter Brazilian state code) |

---

## Table: `bronze.geolocation`

Stores latitude/longitude coordinates mapped to zip code prefixes. Note: contains many repeated zip code prefixes (multiple coordinate points per zip area) — no unique key.

| Column Name | Data Type | Description |
|---|---|---|
| geolocation_zip_code_prefix | Text | First 5 digits of zip code |
| geolocation_lat | double precision | Latitude coordinate |
| geolocation_lng | double precision | Longitude coordinate |
| geolocation_city | Text | City name |
| geolocation_state | char(2) | State (2-letter Brazilian state code) |

---

## Table: `bronze.order_items`

Stores individual line items within each order (one row per product per order).

| Column Name | Data Type | Description |
|---|---|---|
| order_id | Text | Order identifier (FK to orders, not enforced in bronze) |
| order_item_id | int | Sequential item number within the order (not unique across table) |
| product_id | Text | Product identifier (FK to products) |
| seller_id | Text | Seller identifier (FK to sellers) |
| shipping_limit_date | Timestamp | Seller's shipping deadline for this item |
| price | double precision | Item price |
| freight_value | double precision | Freight/shipping cost for this item |

---

## Table: `bronze.order_payments`

Stores payment details for each order. An order can have multiple payment rows (e.g., split payments, installments).

| Column Name | Data Type | Description |
|---|---|---|
| order_id | Text | Order identifier (FK to orders, not enforced in bronze) |
| payment_sequential | int | Sequence number of the payment for orders with multiple payment methods |
| payment_type | Text | Payment method (e.g., credit_card, boleto, voucher) |
| payment_installments | int | Number of installments chosen |
| payment_value | double precision | Value of the payment |

---

## Table: `bronze.order_reviews`

Stores customer review data submitted after order delivery.

| Column Name | Data Type | Description |
|---|---|---|
| review_id | Text | Unique review identifier |
| order_id | Text | Order identifier (FK to orders, not enforced in bronze) |
| review_score | int | Rating score (1–5) |
| review_comment_title | Text | Review title text (often null) |
| review_comment_message | Text | Review body text (often null) |
| review_creation_date | Timestamp | Date the review survey was sent |
| review_answer_timestamp | Timestamp | Date the customer submitted the review |

---

## Table: `bronze.orders`

Core orders table — one row per order, with status and timestamp milestones.

| Column Name | Data Type | Description |
|---|---|---|
| order_id | Text | Unique order identifier |
| customer_id | Text | Customer identifier (FK to customers) |
| order_status | Text | Order status (e.g., delivered, shipped, canceled) |
| order_purchase_timestamp | Timestamp | When the order was placed |
| order_approved_at | Timestamp | When payment was approved |
| order_delivered_carrier_date | Timestamp | When the order was handed to the logistics carrier |
| order_delivered_customer_date | Timestamp | When the order was delivered to the customer |
| order_estimated_delivery_date | Timestamp | Estimated delivery date shown to the customer at purchase |

---

## Table: `bronze.products`

Stores product catalog and physical attribute data.

| Column Name | Data Type | Description |
|---|---|---|
| product_id | Text | Unique product identifier |
| product_category_name | varchar(50) | Product category (in Portuguese; see translation table) |
| product_name_length | int | Character length of the product name |
| product_description_length | int | Character length of the product description |
| product_photos_qty | int | Number of photos listed for the product |
| product_weight_g | int | Product weight in grams |
| product_length_cm | int | Product length in centimeters |
| product_height_cm | int | Product height in centimeters |
| product_width_cm | int | Product width in centimeters |

---

## Table: `bronze.sellers`

Stores seller identity and location information.

| Column Name | Data Type | Description |
|---|---|---|
| seller_id | Text | Unique seller identifier |
| seller_zip_code_prefix | Text | First 5 digits of seller's zip code |
| seller_city | varchar(50) | Seller's city |
| seller_state | char(2) | Seller's state (2-letter Brazilian state code) |

---

## Table: `bronze.product_category_name_translation`

Lookup/reference table translating Portuguese category names to English.

| Column Name | Data Type | Description |
|---|---|---|
| product_category_name | Text | Category name in Portuguese |
| product_category_name_english | Text | Category name translated to English |

---

## Notes

- Column names in this layer are kept as close as possible to the original source CSV headers to preserve traceability back to the raw data.
- The source CSVs use the misspelling `_lenght` instead of `_length` for `product_name_length` and `product_description_length`; this has been corrected in this layer's column names for clarity, but the load script maps columns positionally, so this does not affect data loading.
- No data cleaning, deduplication, or type correction happens here — see `silver_data_schema.md` for those details.
