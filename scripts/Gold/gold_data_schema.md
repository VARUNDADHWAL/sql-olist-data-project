# Gold Layer — Data Schema

## Overview

The **Gold Layer** is the business-ready layer of the warehouse — a star schema built from the Silver layer, designed for direct consumption by Power BI and analytical queries. It consists of one central fact table surrounded by four dimension tables, connected by foreign key constraints.

- **Schema:** `gold`
- **Source:** `silver.*` tables (not re-loaded from bronze or CSV)
- **Load method:** stored procedure `gold.load_gold()`, called via `CALL gold.load_gold();`
- **Naming convention:** `dim_*` for dimension tables, `fact_*` for fact tables
- **Constraints:** Primary keys on all tables; `FOREIGN KEY` constraints on `fact_order_items` referencing every dimension — standard star schema integrity

---

## Table: `gold.dim_date`

A fully generated calendar dimension — unlike the other gold tables, this has no direct source table in silver. It's built using `generate_series()` to produce one row per calendar day, spanning 3 months before the earliest order and 3 months after the latest estimated delivery date in `silver.orders`.

| Column Name | Data Type | Description |
|---|---|---|
| date_key | INT (PK) | Surrogate key in `YYYYMMDD` integer format (e.g., 20170615) — sortable and human-readable |
| full_date | DATE | The calendar date |
| year | INT | Calendar year |
| quarter | INT | Calendar quarter (1–4) |
| month | INT | Calendar month (1–12) |
| month_name | TEXT | Full month name (e.g., "June") |
| day | INT | Day of month |
| day_name | TEXT | Full weekday name (e.g., "Thursday") |
| week_of_year | INT | ISO week number |
| is_weekend | BOOLEAN | True if Saturday or Sunday |

**Purpose:** Enables year/month/quarter/weekday slicing and filtering directly in Power BI without needing DAX date functions.

---

## Table: `gold.dim_customer`

Built from `silver.customers`, enriched with location coordinates.

| Column Name | Data Type | Description |
|---|---|---|
| customer_key | SERIAL (PK) | Surrogate key |
| customer_id | Text | Per-order customer identifier (from silver) |
| customer_unique_id | Text | Real-world customer identifier, consistent across orders |
| customer_city | Text | Customer's city |
| customer_state | char(2) | Customer's state |
| customer_lat | double precision | Latitude, joined in from `silver.geolocation` |
| customer_lng | double precision | Longitude, joined in from `silver.geolocation` |

**Notes:**
- `customer_lat`/`customer_lng` are `NULL` for the small number of customers whose zip prefix has no match in `silver.geolocation` (a known, documented gap — see `silver_data_schema.md`). This is expected, not a load error.
- Bringing coordinates into the dimension itself (rather than requiring a join to geolocation at query time) simplifies building location-based visuals in Power BI.

---

## Table: `gold.dim_seller`

Built from `silver.sellers`, same enrichment pattern as `dim_customer`.

| Column Name | Data Type | Description |
|---|---|---|
| seller_key | SERIAL (PK) | Surrogate key |
| seller_id | Text | Seller identifier |
| seller_city | Text | Seller's city |
| seller_state | char(2) | Seller's state |
| seller_lat | double precision | Latitude, joined in from `silver.geolocation` |
| seller_lng | double precision | Longitude, joined in from `silver.geolocation` |

**Notes:**
- Same expected null pattern as `dim_customer` for the 7 known unmatched seller zip codes.

---

## Table: `gold.dim_product`

Built from `silver.products`, with the category translation resolved at load time and two new derived columns.

| Column Name | Data Type | Description |
|---|---|---|
| product_key | SERIAL (PK) | Surrogate key |
| product_id | Text | Product identifier |
| product_category_english | Text | English category name — resolved once here via join to `silver.product_category_name_translation`, so gold never needs the translation table again |
| product_weight_g | int | Product weight in grams |
| product_length_cm | int | Product length in centimeters |
| product_height_cm | int | Product height in centimeters |
| product_width_cm | int | Product width in centimeters |
| product_volume_cm3 | int | **Derived:** `length_cm * height_cm * width_cm` |
| product_size_category | Text | **Derived:** `'Small'` (<1000g), `'Medium'` (<10000g), `'Large'` (≥10000g), based on `product_weight_g` |

**Notes:**
- `product_volume_cm3` and `product_size_category` are both `NULL` where the underlying dimension/weight data is missing in silver — not fabricated, consistent with the "don't invent data" principle applied throughout the pipeline.

---

## Table: `gold.fact_order_items`

**Grain:** one row per order item — matches `silver.order_items` exactly (1:1).

Order-level data (payments, reviews) is order-grain in silver, not item-grain, so it's denormalized down to item-level here. This trades strict normalization for a single, Power BI–friendly "one big table" that avoids requiring multiple fact-to-fact relationships.

| Column Name | Data Type | Description |
|---|---|---|
| order_item_key | SERIAL (PK) | Surrogate key |
| order_id | Text | Order identifier |
| order_item_id | int | Item sequence number within the order |
| customer_key | int (FK → dim_customer) | Resolved customer dimension key |
| seller_key | int (FK → dim_seller) | Resolved seller dimension key |
| product_key | int (FK → dim_product) | Resolved product dimension key |
| order_date_key | int (FK → dim_date) | Resolved date dimension key, from `order_purchase_timestamp` |
| order_status | Text | Order lifecycle status |
| price | numeric | Item price |
| freight_value | numeric | Item freight/shipping cost |
| total_item_value | numeric | **Derived:** `price + freight_value` |
| total_payment_value | numeric | **Derived:** total payment value for the order (summed across all payment rows, from `silver.order_payments`) |
| installments | int | **Derived:** max installment count for the order |
| payment_type | Text | **Derived:** payment method used for the order |
| review_score | int | **Derived:** review score for the order (deduplicated to one score per order using `MAX`, avoiding the review-resend fan-out issue) |
| order_purchase_timestamp | Timestamp | When the order was placed |
| shipping_limit_date | Timestamp | Seller's shipping deadline for this item |
| order_delivered_carrier_date | Timestamp | When the order was handed to the carrier |
| order_delivered_customer_date | Timestamp | When the order was delivered to the customer |
| order_estimated_delivery_date | Timestamp | Estimated delivery date shown at purchase |
| delivery_days | numeric | **Derived:** days between purchase and customer delivery (`NULL` if not yet delivered) |
| approval_days | numeric | **Derived:** days between purchase and payment approval |
| carrier_to_delivery_days | numeric | **Derived:** days between carrier handoff and customer delivery |
| is_late_shipment | boolean | **Derived:** `TRUE` if the seller handed off to the carrier after their own shipping deadline |
| is_late_delivery | boolean | **Derived:** `TRUE` if delivered after the estimated delivery date |
| is_delivered | boolean | **Derived:** `TRUE` if `order_status = 'delivered'` |

**Notes:**
- All timing/boolean derived columns return `NULL` rather than `FALSE`/`0` when the relevant date doesn't exist yet (e.g., an order not yet delivered), so undelivered orders are never misreported as "on time."
- `total_payment_value` and `review_score` are calculated from pre-aggregated CTEs (`order_payment_summary`, `order_review_summary`) that collapse to one row per `order_id` *before* joining — this avoids the fan-out double-counting issue identified and fixed during the analysis phase (see `key_insights.md` and `analysis_script_final.sql`).
- Dimension joins (`customer_key`, `seller_key`, `product_key`) use `JOIN` (not `LEFT JOIN`), since verification confirmed no orphaned foreign keys exist between `order_items` and the `customers`/`sellers`/`products` tables at gold load time.

---

## Load Order

`fact_order_items` must be truncated **before** any dimension table (Postgres blocks truncating a table referenced by an active foreign key), and reloaded **after** all dimensions — since it depends on their freshly generated surrogate keys. The full sequence, handled by `gold.load_gold()`:

1. Truncate `fact_order_items`
2. Truncate + reload `dim_date`
3. Truncate + reload `dim_customer` (surrogate keys restart at 1)
4. Truncate + reload `dim_seller` (surrogate keys restart at 1)
5. Truncate + reload `dim_product` (surrogate keys restart at 1)
6. Reload `fact_order_items`, using the new surrogate keys

**Important:** never reload a single dimension table on its own outside of this full sequence — doing so would leave `fact_order_items`'s foreign keys pointing to the wrong dimension rows.

---

## General Notes

- Every derived column in this layer traces back to a documented decision made during silver-layer cleaning or the business analysis phase — nothing here is calculated arbitrarily.
- The star schema design intentionally denormalizes order-level payment and review data into the item-grain fact table, prioritizing ease of use in Power BI over strict third-normal-form modeling — a deliberate tradeoff, not an oversight.
- No slowly-changing-dimension (SCD Type 2) tracking is implemented, since the Olist dataset is a static historical snapshot rather than a live, continuously updating source.
