# Silver Layer — Data Schema

## Overview

The **Silver Layer** contains cleansed, standardized data transformed from the Bronze layer. Every table below was explored using verification queries against the raw bronze data before any cleaning decision was made — nulls, duplicates, orphaned keys, and outliers were checked and confirmed (not assumed) before deciding whether to filter, default, or leave a value as-is.

- **Schema:** `silver`
- **Source:** `bronze.*` tables (not re-loaded from CSV)
- **Load method:** `TRUNCATE` + `INSERT INTO ... SELECT`, via `silver.load_silver()` / `load_silver.sql`
- **Audit column:** `silver_insert_time` (auto-populated via `DEFAULT CURRENT_TIMESTAMP`)

---

## Table: `silver.customers`

| Column | Data Type | Constraint |
|---|---|---|
| customer_id | Text | PRIMARY KEY |
| customer_unique_id | Text | NOT NULL |
| customer_zip_code_prefix | Text | NOT NULL |
| customer_city | varchar(100) | NOT NULL |
| customer_state | char(2) | NOT NULL |

**Transformations applied:**
- Trimmed whitespace on all ID and text fields
- `customer_city` cleaned with `unaccent()` + `INITCAP()` for consistent casing/accents, defaulted to `'Unknown'` if null
- `customer_state` uppercased

**Findings & decisions:**
- `customer_unique_id` repeats across multiple `customer_id` values by design — represents repeat customers placing multiple orders, not duplicate/dirty data. Not deduplicated; each `customer_id` row kept as-is since `orders.customer_id` depends on it.

---

## Table: `silver.geolocation`

| Column | Data Type | Constraint |
|---|---|---|
| geolocation_zip_code_prefix | Text | NOT NULL |
| geolocation_lat | double precision | NOT NULL |
| geolocation_lng | double precision | NOT NULL |
| geolocation_city | Text | NOT NULL |
| geolocation_state | char(2) | NOT NULL |

*(No primary key — see notes below)*

**Transformations applied:**
- Filtered out rows with coordinates outside Brazil's geographic bounding box (lat: -33.75 to 5.27, lng: -73.99 to -34.79) — removes geocoding errors
- Deduplicated ~1 million raw coordinate points down to ~19–20K unique zip code prefixes using `GROUP BY`
- `geolocation_lat` / `geolocation_lng` averaged (`AVG`, rounded to 6 decimal places) across all points sharing a zip prefix
- `geolocation_city` / `geolocation_state` resolved using `MODE()` (most frequently occurring value per zip prefix), cleaned with `unaccent()` + `INITCAP()` / uppercase

**Findings & decisions:**
- Bronze data has ~1M rows for only ~19K unique zip prefixes because a zip prefix covers an area with many individual buildings, each geocoded separately. Since neither `customers` nor `sellers` store anything more precise than a zip prefix, house-level coordinate precision is unusable in this data model — aggregating to one row per zip prefix loses no accessible information.
- Invalid/out-of-bounds coordinates filtered rather than defaulted, since there is no meaningful fallback value for a geographic point.

---

## Table: `silver.order_items`

| Column | Data Type | Constraint |
|---|---|---|
| order_id | Text | NOT NULL |
| order_item_id | int | NOT NULL |
| product_id | Text | NOT NULL |
| seller_id | Text | NOT NULL |
| shipping_limit_date | Timestamp | |
| price | double precision | NOT NULL |
| freight_value | double precision | NOT NULL |
| — | | PRIMARY KEY (order_id, order_item_id) |

**Transformations applied:**
- Trimmed whitespace on ID fields
- No filtering applied to `price` / `freight_value`

**Findings & decisions:**
- `order_item_id` is only unique within an order, not across the table — confirmed composite key `(order_id, order_item_id)` is required.
- `freight_value = 0` (383 rows) verified as legitimate — sellers offering free shipping, not an error.
- Max price (₹6,735) and max freight (₹409) verified against product categories (computers, household appliances, baby products, arts) — confirmed legitimate high-value/bulky items, not data entry errors. No capping or filtering applied.

---

## Table: `silver.order_payments`

| Column | Data Type | Constraint |
|---|---|---|
| order_id | Text | NOT NULL |
| payment_sequential | int | NOT NULL |
| payment_type | Text | NOT NULL |
| payment_installments | int | NOT NULL |
| payment_value | double precision | NOT NULL |
| — | | PRIMARY KEY (order_id, payment_sequential) |

**Transformations applied:**
- Trimmed whitespace on `order_id` / `payment_type`
- `payment_installments = 0` corrected to `1` where `payment_type = 'credit_card'` (2 rows) — a single credit card payment should have at least 1 installment; treated as a data entry anomaly

**Findings & decisions:**
- `order_id` is not unique in this table — an order can have multiple payment rows (split/voucher payments). Composite key `(order_id, payment_sequential)` confirmed correct.
- `not_defined` payment type and `payment_value = 0` / `0.01` rows verified as legitimate — occur on orders with multiple payment rows (vouchers, partial/split payments), not errors.
- 830 `order_id` values exist in `order_payments` but not in `order_items` — this is **not** an orphaned-data issue, since `order_items` is not the authoritative parent table. Re-checked against `orders` directly: 0 orphaned rows found. No filtering applied.

---

## Table: `silver.order_reviews`

| Column | Data Type | Constraint |
|---|---|---|
| review_id | Text | NOT NULL |
| order_id | Text | NOT NULL |
| review_score | int | |
| review_comment_title | Text | |
| review_comment_message | Text | |
| review_creation_date | Timestamp | |
| review_answer_timestamp | Timestamp | |

*(No primary key — see notes below)*

**Transformations applied:**
- Trimmed whitespace on all text fields
- No deduplication applied

**Findings & decisions:**
- Comment fields (`title`, `message`) are mostly null — expected, since customers usually only submit a star rating without written feedback. Not treated as an error.
- Some `order_id` values have 2–3 review rows, and some `review_id` values repeat — consistent with Olist's known review-resend behavior (a second survey is sent if the customer doesn't respond to the first). All rows kept in silver at full grain.
- Deduplication to "most recent review per order" is deferred to the **Gold layer** as a business logic decision (e.g., `ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY review_answer_timestamp DESC)`), not treated as a silver-layer cleaning task.

---

## Table: `silver.orders`

| Column | Data Type | Constraint |
|---|---|---|
| order_id | Text | PRIMARY KEY |
| customer_id | Text | NOT NULL |
| order_status | Text | NOT NULL |
| order_purchase_timestamp | Timestamp | |
| order_approved_at | Timestamp | |
| order_delivered_carrier_date | Timestamp | |
| order_delivered_customer_date | Timestamp | |
| order_estimated_delivery_date | Timestamp | |

**Transformations applied:**
- Trimmed whitespace; `order_status` lowercased for consistency
- `order_approved_at` nulled out where it was logically before `order_purchase_timestamp` (impossible sequence)
- `order_delivered_customer_date` nulled out where it was before `order_purchase_timestamp` or before `order_delivered_carrier_date` (impossible sequence) — affected 24 + 8 rows respectively

**Findings & decisions:**
- `order_status` values: `created`, `approved`, `invoiced`, `processing`, `shipped`, `delivered`, `canceled`, `unavailable`. Verified null patterns across all 8 statuses match the expected order lifecycle (e.g., `shipped` orders have `approved_at` + `carrier_date` filled but not `customer_date`).
- `order_purchase_timestamp` and `order_estimated_delivery_date` are 100% populated across every status — confirmed no missing values in either column.
- 6 `canceled` orders have fully populated delivery timestamps — interpreted as legitimate post-delivery cancellations/returns, not a data error. Left unmodified.
- 14 `delivered` orders have null `order_approved_at`; 8 `delivered` orders have null `order_delivered_customer_date` (1 of which is also missing `order_delivered_carrier_date`) — interpreted as logging gaps between the status update and timestamp write, not fabricated. Left as `NULL`. **Note for analysis:** exclude these via `WHERE order_delivered_customer_date IS NOT NULL` when calculating average delivery time, to avoid skewing results.

---

## Table: `silver.products`

| Column | Data Type | Constraint |
|---|---|---|
| product_id | Text | PRIMARY KEY |
| product_category_name | varchar(50) | |
| product_name_length | int | |
| product_description_length | int | |
| product_photos_qty | int | |
| product_weight_g | int | |
| product_length_cm | int | |
| product_height_cm | int | |
| product_width_cm | int | |

**Transformations applied:**
- Trimmed whitespace on `product_id`
- `product_category_name` defaulted to `'unknown'` where null
- `product_name_length`, `product_description_length`, `product_photos_qty` defaulted to `0` where null
- `product_weight_g`, `product_length_cm`, `product_height_cm`, `product_width_cm` left as `NULL` where missing — **not** defaulted to `0`, since a 0g/0cm product is physically meaningless and would corrupt freight/weight-based analysis

**Findings & decisions:**
- 610 rows missing `category_name`, `description_length`, `name_length`, and `photos_qty` together — consistent pattern suggesting incomplete seller-submitted catalog listings, not corruption. Defaulted as above.
- 1 row has every column null except `product_id` — kept in silver with defaults applied for consistency (documented as an "empty shell" record with no real catalog data).
- 1 row has catalog info (category/name/description/photos) but null physical dimensions — dimensions left `NULL` rather than defaulted, per the reasoning above.
- 17 `order_items` rows reference a `product_id` with little/no catalog data — these will simply show `'unknown'` category and `NULL` dimensions when joined; not fixable at the `products` table level, documented as a known limitation for category/weight-based analysis.

---

## Table: `silver.sellers`

| Column | Data Type | Constraint |
|---|---|---|
| seller_id | Text | PRIMARY KEY |
| seller_zip_code_prefix | Text | NOT NULL |
| seller_city | varchar(100) | NOT NULL |
| seller_state | char(2) | NOT NULL |

**Transformations applied:**
- Trimmed whitespace on ID fields
- `seller_city` cleaned with `unaccent()` + `INITCAP()`
- `seller_state` uppercased

**Findings & decisions:**
- 7 `seller_zip_code_prefix` values have no match in `silver.geolocation` — a coverage gap in the geolocation source data (or filtered during geolocation's coordinate validation), not a `sellers` data quality issue. These sellers will appear unmapped in any location-based visualization.
- 68 `seller_city` values don't exactly match `geolocation_city` for the same zip prefix — likely spelling/formatting inconsistencies between the two source files. Both fields are cleaned consistently (`unaccent` + `INITCAP`), which resolves most casing/accent mismatches, though some may remain genuinely different city name entries.

---

## Table: `silver.product_category_name_translation`

| Column | Data Type | Constraint |
|---|---|---|
| product_category_name | Text | PRIMARY KEY |
| product_category_name_english | Text | |

**Transformations applied:**
- Trimmed whitespace on both columns

**Findings & decisions:**
- Small reference/lookup table (~70 rows) — checked for null and duplicate `product_category_name` values before applying the primary key constraint.

---

## General Notes

- No foreign key constraints are enforced across silver tables (matches the bronze layer's approach) — this keeps reloads flexible and avoids FK violation errors during iterative development. Referential relationships are documented via the ER/data flow diagram instead.
- Every cleaning decision in this document was made only after running a verification query against the actual bronze data — no assumptions were made about "obvious" errors without confirming them first (e.g., high price/freight outliers were checked against product category before being accepted as legitimate).
- Business-logic-driven deduplication (e.g., picking one review per order) is deliberately deferred to the Gold layer, since it depends on the specific analysis use case rather than being a universal data quality fix.
