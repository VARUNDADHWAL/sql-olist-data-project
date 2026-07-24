/* ============================================================
   Olist E-Commerce Data Warehouse — Business Analysis Queries
   Answers all 44 business questions from the project plan.
   Source: silver layer (cleaned, standardized data)

   Notes on conventions used throughout this script:
   - Unless noted otherwise, "revenue" = order_items.price + freight_value
     (matches total money the customer paid, consistent with payment totals).
     Seller-level revenue questions use price only (excludes freight,
     since freight is a pass-through logistics cost, not seller earnings)
     — this is called out explicitly where it applies.
   - order_reviews can have 2-3 rows per order_id (Olist resends the
     review survey if a customer doesn't respond). Any query joining
     order_reviews to other tables first collapses reviews to ONE row
     per order_id using MAX(review_score)
============================================================ */


-- ============================================================
-- SALES & REVENUE
-- ============================================================

-- 1. Total revenue and total number of orders overall

-- all order status 
select sum(payment_value) as total_revenue_all_orders from silver.order_payments
-- delivered orders only 
SELECT SUM(p.payment_value) AS total_revenue_delivered_only
FROM silver.order_payments p
JOIN silver.orders o ON p.order_id = o.order_id
WHERE o.order_status = 'delivered';
-- total orders count
select count(order_id) as total_orders from silver.orders;


-- 2. Month-over-month revenue trend
select
    to_char(o.order_purchase_timestamp,'yyyy-mm') as year_month,
    to_char(o.order_purchase_timestamp,'FMMONTH YYYY') as month_label,
    round(sum(op.payment_value)::numeric,2) as total_revenue
from silver.order_payments op
join silver.orders o on op.order_id = o.order_id
where o.order_status = 'delivered'
  and o.order_purchase_timestamp >= '2017-01-01'
  and o.order_purchase_timestamp < '2018-09-01'
group by 1,2
order by year_month;


-- 3. Month-over-month revenue growth rate (%)
with monthly_revenue as (
    select
        to_char(o.order_purchase_timestamp,'yyyy-mm') as year_month,
        to_char(o.order_purchase_timestamp,'FMMONTH YYYY') as month_label,
        sum(op.payment_value) as total_revenue
    from silver.order_payments op
    join silver.orders o on op.order_id = o.order_id
    where o.order_status = 'delivered'
      and o.order_purchase_timestamp >= '2017-01-01'
      and o.order_purchase_timestamp < '2018-09-01'
    group by 1,2
)
select
    year_month,
    month_label,
    round(total_revenue::numeric,2) as current_total_revenue,
    round(lag(total_revenue) over(order by year_month)::numeric,2) as previous_month_revenue,
    round(((total_revenue - lag(total_revenue) over(order by year_month))
        / lag(total_revenue) over(order by year_month) * 100)::numeric,2) as month_over_month_growth_pct
from monthly_revenue
order by year_month;


-- 4. Product category with the highest total revenue (price + freight_value)
select
    p.product_category_name as product_category,
    round(sum(o.price + o.freight_value)::numeric,2) as total_revenue
from silver.order_items o
join silver.products p on o.product_id = p.product_id
join silver.orders oo on o.order_id = oo.order_id
where oo.order_status = 'delivered'
group by product_category
order by total_revenue desc
limit 1;


-- 5. Product category with the highest order volume (most items sold)
select
    p.product_category_name as product_category,
    count(oo.order_id) as items_sold
from silver.order_items o
join silver.products p on o.product_id = p.product_id
join silver.orders oo on o.order_id = oo.order_id
where oo.order_status = 'delivered'
group by product_category
order by items_sold desc
limit 1;


-- 6a. Average order value (AOV) overall
select
    round((sum(op.payment_value) / count(distinct op.order_id))::numeric,2) as avg_order_value
from silver.order_payments op
join silver.orders o on op.order_id = o.order_id
where o.order_status = 'delivered';

-- 6b. AOV by state
select
    c.customer_state as state,
    count(distinct o.order_id) as total_orders,
    round((sum(op.payment_value) / count(distinct o.order_id))::numeric,2) as avg_order_value
from silver.order_payments op
join silver.orders o on op.order_id = o.order_id
join silver.customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by state
order by avg_order_value desc;


-- 7. Average number of items per order
select round(count(oi.order_id)::numeric / count(distinct oi.order_id),2) as avg_items_per_order
from silver.order_items oi
join silver.orders o on oi.order_id = o.order_id
where o.order_status = 'delivered';


-- 8. Busiest month/season for orders
-- Note: groups by month NAME only (not year), so 2017 and 2018 occurrences
-- of the same month are combined. Interpret alongside a year-month breakdown (Q2) for full context.
select
    to_char(order_purchase_timestamp, 'FMMonth') as month_name,
    count(order_id) as total_orders
from silver.orders
where order_status = 'delivered'
group by month_name
order by total_orders desc;


-- 9. Day of week with the most orders
select
    to_char(order_purchase_timestamp,'FMday') as day_name,
    count(order_id) as orders
from silver.orders
where order_status = 'delivered'
group by day_name
order by orders desc;


-- ============================================================
-- CUSTOMERS
-- ============================================================

-- 10. Unique customers vs. total orders placed
select count(distinct customer_unique_id) as unique_customers from silver.customers;
select count(distinct order_id) as total_orders from silver.orders;


-- 11. Repeat customers (more than one order)
with customer_order_counts as (
    select
        customer_unique_id,
        count(customer_id) as total_orders
    from silver.customers
    group by customer_unique_id
    having count(customer_id) > 1
)
select count(customer_unique_id) as repeat_customers from customer_order_counts;


-- 12. Revenue share: repeat customers vs. one-time customers
with customer_status as (
    select
        c.customer_unique_id,
        count(distinct o.order_id) as total_orders,
        sum(p.payment_value) as total_spend
    from silver.customers c
    join silver.orders o on c.customer_id = o.customer_id
    join silver.order_payments p on o.order_id = p.order_id
    where o.order_status = 'delivered'
    group by customer_unique_id
),
type_summary as (
    select
        case when total_orders > 1 then 'repeat_customers' else 'one_time_customers' end as customer_type,
        sum(total_spend) as category_revenue
    from customer_status
    group by 1
)
select
    customer_type,
    round(category_revenue::numeric,2) as total_revenue,
    round((category_revenue / sum(category_revenue) over() * 100)::numeric,2) as pct_of_revenue
from type_summary
order by total_revenue desc;


-- 13. Average time gap between a customer's first and second order
with order_sequence as (
    select
        c.customer_unique_id,
        o.order_purchase_timestamp as first_order_date,
        row_number() over(partition by c.customer_unique_id order by o.order_purchase_timestamp) as order_rank,
        lead(o.order_purchase_timestamp) over(partition by c.customer_unique_id order by o.order_purchase_timestamp) as second_order_date
    from silver.customers c
    join silver.orders o on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
)
select round(avg(second_order_date::date - first_order_date::date)::numeric,2) as avg_days_between_first_second_order
from order_sequence
where order_rank = 1 and second_order_date is not null;


-- 14. Customer retention by monthly cohort
with first_purchases as (
    select
        c.customer_unique_id,
        date_trunc('month', min(o.order_purchase_timestamp)) as cohort_month
    from silver.customers c
    join silver.orders o on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
    group by c.customer_unique_id
),
monthly_gaps as (
    select
        fp.cohort_month,
        date_trunc('month', o.order_purchase_timestamp) as order_month,
        (extract(year from o.order_purchase_timestamp) - extract(year from fp.cohort_month)) * 12 +
        (extract(month from o.order_purchase_timestamp) - extract(month from fp.cohort_month)) as month_gap,
        fp.customer_unique_id
    from first_purchases fp
    join silver.customers c on fp.customer_unique_id = c.customer_unique_id
    join silver.orders o on c.customer_id = o.customer_id
    where o.order_status = 'delivered'
)
select
    cohort_month::date as cohort,
    month_gap,
    count(distinct customer_unique_id) as retained_customers
from monthly_gaps
group by cohort_month, month_gap
order by cohort_month, month_gap;


-- 15a. Most customers by state
select
    customer_state,
    count(customer_unique_id) as total_customers
from silver.customers
group by customer_state
order by total_customers desc;

-- 15b. Most customers by city
select
    customer_state,
    customer_city,
    count(customer_unique_id) as total_customers
from silver.customers
group by customer_city, customer_state
order by total_customers desc;


-- 16a. Highest revenue per customer by state
select
    c.customer_state,
    round((sum(op.payment_value) / count(distinct c.customer_unique_id))::numeric,2) as revenue_per_customer,
    count(distinct c.customer_unique_id) as total_customers
from silver.customers c
join silver.orders o on c.customer_id = o.customer_id
join silver.order_payments op on o.order_id = op.order_id
where o.order_status = 'delivered'
group by c.customer_state
order by revenue_per_customer desc;

-- 16b. Highest revenue per customer by city
select
    c.customer_state,
    c.customer_city,
    round((sum(op.payment_value) / count(distinct c.customer_unique_id))::numeric,2) as revenue_per_customer,
    count(distinct c.customer_unique_id) as total_customers
from silver.customers c
join silver.orders o on c.customer_id = o.customer_id
join silver.order_payments op on o.order_id = op.order_id
where o.order_status = 'delivered'
group by c.customer_state, c.customer_city
order by revenue_per_customer desc;


-- ============================================================
-- SELLERS
-- Note: seller revenue = price only (excludes freight_value)
-- ============================================================

-- 17. Top sellers by total revenue
select
    oi.seller_id,
    round(sum(oi.price)::numeric,2) as revenue
from silver.order_items oi
join silver.orders o on oi.order_id = o.order_id
where o.order_status = 'delivered'
group by oi.seller_id
order by revenue desc;


-- 18. Revenue concentration among top 10% of sellers
with seller_revenue as (
    select
        oi.seller_id,
        sum(oi.price) as total_revenue
    from silver.orde r_items oi
    join silver.orders o on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.seller_id
),
ranked_sellers as (
    select
        seller_id,
        total_revenue,
        ntile(10) over(order by total_revenue desc) as seller_decile
    from seller_revenue
)
select
    round(sum(case when seller_decile = 1 then total_revenue else 0 end)::numeric,2) as top_10pct_revenue,
    round(sum(total_revenue)::numeric,2) as total_revenue,
    round((sum(case when seller_decile = 1 then total_revenue else 0 end) / sum(total_revenue) * 100)::numeric,2) as top_10pct_concentration_pct
from ranked_sellers;


-- 19. Seller count and performance by state
with order_level_metrics as (
    select
        s.seller_state,
        oi.seller_id,
        o.order_id,
        o.order_status,
        sum(oi.price) as order_revenue,
        max(o.order_estimated_delivery_date) as estimated_delivery,
        max(o.order_delivered_customer_date) as actual_delivery,
        max(r.review_score) as review_score
    from silver.order_items oi
    join silver.sellers s on oi.seller_id = s.seller_id
    join silver.orders o on oi.order_id = o.order_id
    left join silver.order_reviews r on o.order_id = r.order_id
    group by s.seller_state, oi.seller_id, o.order_id, o.order_status
)
select
    seller_state,
    count(distinct seller_id) as total_sellers,
    round(sum(case when order_status = 'delivered' then order_revenue else 0 end)::numeric,2) as total_revenue,
    round((sum(case when order_status = 'delivered' then order_revenue else 0 end) / count(distinct seller_id))::numeric,2) as avg_revenue_per_seller,
    round(avg(review_score)::numeric,2) as avg_rating,
    round((sum(case when actual_delivery <= estimated_delivery then 1 else 0 end) /
           nullif(sum(case when order_status = 'delivered' then 1 else 0 end),0)::numeric) * 100,2) as on_time_delivery_pct
from order_level_metrics
group by seller_state
order by total_revenue desc;


-- 20. Average revenue per seller
with seller_totals as (
    select
        oi.seller_id,
        sum(oi.price) as total_revenue
    from silver.order_items oi
    join silver.orders o on oi.order_id = o.order_id
    where o.order_status = 'delivered'
    group by oi.seller_id
)
select round(avg(total_revenue)::numeric,2) as avg_revenue_per_seller
from seller_totals;


-- 21. Sellers with the most orders but lowest average review score
with order_reviews_per_seller as (
    select
        o.order_id,
        oi.seller_id,
        max(r.review_score) as review_score          
    from silver.orders o
    join silver.order_items oi on o.order_id = oi.order_id
    join silver.order_reviews r on o.order_id = r.order_id
    where o.order_status = 'delivered'
    group by oi.seller_id, o.order_id
)
select
    seller_id,
    count(order_id) as total_orders,
    round(avg(review_score)::numeric,2) as avg_review
from order_reviews_per_seller
group by seller_id
having count(order_id) >= 30
order by avg_review asc, total_orders desc
limit 10;


-- ============================================================
-- PRODUCTS
-- ============================================================

-- 22. Top 10 best-selling products (categories) by revenue (price only)
select
    t.product_category_name_english as category_name,
    round(sum(o.price)::numeric,2) as revenue
from silver.order_items o
join silver.products p on o.product_id = p.product_id
join silver.orders oo on o.order_id = oo.order_id
join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
where oo.order_status = 'delivered'
group by category_name
order by revenue desc
limit 10;


-- 23. Top 10 best-selling categories by quantity sold
select
    t.product_category_name_english as category_name,
    count(oi.order_id) as total_quantity_sold
from silver.orders o
join silver.order_items oi on o.order_id = oi.order_id
join silver.products p on oi.product_id = p.product_id
join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
where o.order_status = 'delivered'
group by t.product_category_name_english
order by total_quantity_sold desc
limit 10;


-- 24. Highest and lowest rated product categories
with one_review_per_order as (
    select order_id, max(review_score) as review_score
    from silver.order_reviews
    group by order_id
),
category_rating as (
    select
        t.product_category_name_english as category_name,
        count(r.review_score) as total_reviews,
        round(avg(r.review_score)::numeric,2) as avg_rating
    from silver.order_items oi
    join silver.orders o on oi.order_id = o.order_id
    join one_review_per_order r on o.order_id = r.order_id
    join silver.products p on oi.product_id = p.product_id
    join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
    where o.order_status = 'delivered'
    group by t.product_category_name_english
    having count(r.review_score) >= 30
),
top_5 as (
    select 'highest rated' as performance_tier, category_name, total_reviews, avg_rating
    from category_rating order by avg_rating desc limit 5
),
bottom_5 as (
    select 'lowest rated' as performance_tier, category_name, total_reviews, avg_rating
    from category_rating order by avg_rating asc limit 5
)
select * from top_5
union all
select * from bottom_5
order by performance_tier asc, avg_rating desc;


-- 25. Categories with high revenue but low review score
with category_item_data as (
    select
        t.product_category_name_english as category_name,
        oi.price,
        max(r.review_score) as review_score
    from silver.order_items oi
    join silver.orders o on oi.order_id = o.order_id
    join silver.products p on oi.product_id = p.product_id
    join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
    left join silver.order_reviews r on o.order_id = r.order_id
    where o.order_status = 'delivered'
    group by t.product_category_name_english, oi.order_id, oi.order_item_id, oi.price
)
select
    category_name,
    count(*) as total_items_sold,
    round(sum(price)::numeric,2) as total_revenue,
    round(avg(review_score)::numeric,2) as avg_rating
from category_item_data
group by category_name
having sum(price) > 100000
order by avg_rating asc, total_revenue desc;


-- 26. Average price per product category
select
    t.product_category_name_english as category_name,
    round(avg(oi.price)::numeric,2) as avg_item_price,
    count(oi.order_id) as total_items_sold
from silver.order_items oi
join silver.products p on oi.product_id = p.product_id
join silver.orders o on oi.order_id = o.order_id
join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
where o.order_status = 'delivered'
group by t.product_category_name_english
order by avg_item_price desc;


-- 27. Categories with the widest price range
select
    t.product_category_name_english as category_name,
    round((max(oi.price) - min(oi.price))::numeric,2) as price_range
from silver.order_items oi
join silver.products p on oi.product_id = p.product_id
join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
group by category_name
order by price_range desc;


-- ============================================================
-- DELIVERY & LOGISTICS
-- ============================================================

-- 28. Average delivery time overall
select
    round(avg(extract(epoch from (order_delivered_customer_date - order_purchase_timestamp)) / 86400)::numeric,2) as avg_delivery_time_days
from silver.orders
where order_status = 'delivered' and order_delivered_customer_date is not null;


-- 29. Average delivery time by state
select
    c.customer_state,
    round(avg(extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400)::numeric,2) as avg_delivery_time_days
from silver.orders o
join silver.customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered' and o.order_delivered_customer_date is not null
group by c.customer_state
order by avg_delivery_time_days desc;


-- 30. Percentage of orders delivered late
with order_late as (
    select
        count(order_id) as total_orders,
        sum(case when order_estimated_delivery_date < order_delivered_customer_date then 1 else 0 end) as late_orders
    from silver.orders
    where order_status = 'delivered' and order_delivered_customer_date is not null
)
select round((late_orders::numeric / total_orders) * 100,2) as late_delivery_pct
from order_late;


-- 31. States with the most delivery delays
select
    c.customer_state,
    count(o.order_id) as total_orders,
    sum(case when o.order_estimated_delivery_date < o.order_delivered_customer_date then 1 else 0 end) as late_orders
from silver.orders o
join silver.customers c on o.customer_id = c.customer_id
where o.order_status = 'delivered' and o.order_delivered_customer_date is not null
group by c.customer_state
having count(o.order_id) > 100
order by late_orders desc;


-- 32. Delivery delay vs. review score
with one_review_per_order as (
    select order_id, max(review_score) as review_score
    from silver.order_reviews
    group by order_id
),
delivery_status as (
    select
        o.order_id,
        case
            when o.order_delivered_customer_date > o.order_estimated_delivery_date then 'Late'
            else 'On Time or Early'
        end as delivery_performance,
        r.review_score
    from silver.orders o
    join one_review_per_order r on o.order_id = r.order_id
    where o.order_status = 'delivered'
      and o.order_delivered_customer_date is not null
      and o.order_estimated_delivery_date is not null
)
select
    delivery_performance,
    count(order_id) as total_orders,
    round(avg(review_score)::numeric,2) as avg_review_score
from delivery_status
group by delivery_performance
order by avg_review_score desc;


-- 33. Average time between order approval and carrier handoff
select round(avg(extract(epoch from (order_delivered_carrier_date - order_approved_at)) / 86400)::numeric,2) as avg_days_approval_to_carrier
from silver.orders
where order_status = 'delivered';


-- 34. Average time between carrier handoff and customer delivery
select round(avg(extract(epoch from (order_delivered_customer_date - order_delivered_carrier_date)) / 86400)::numeric,2) as avg_days_carrier_to_delivery
from silver.orders
where order_status = 'delivered';


-- ============================================================
-- PAYMENTS
-- ============================================================

-- 35. Most common payment methods
select
    payment_type,
    count(order_id) as total_payments
from silver.order_payments
group by payment_type
order by total_payments desc;


-- 36. Payment type vs. average order value
select
    payment_type,
    payment_installments,
    count(order_id) as total_transactions,
    round(avg(payment_value)::numeric,2) as avg_order_value,
    round(sum(payment_value)::numeric,2) as total_revenue
from silver.order_payments
where payment_type != 'not_defined'
group by payment_type, payment_installments
order by payment_type asc, payment_installments asc;


-- 37. Installment usage frequency
with order_installments as (
    select
        order_id,
        max(case when payment_installments > 1 then 1 else 0 end) as used_installments,
        max(payment_installments) as max_installments
    from silver.order_payments
    group by order_id
)
select
    count(order_id) as total_orders,
    sum(used_installments) as installment_orders,
    round((sum(used_installments)::numeric / count(order_id)) * 100,2) as pct_using_installments,
    round(avg(max_installments)::numeric,2) as avg_installments_all,
    round(avg(case when used_installments = 1 then max_installments else null end)::numeric,2) as avg_installments_when_split
from order_installments;


-- 38. Installment count vs. order value
select
    payment_installments,
    round(sum(payment_value)::numeric,2) as order_value
from silver.order_payments
group by payment_installments
order by order_value desc;


-- ============================================================
-- REVIEWS & SATISFACTION
-- ============================================================

-- 39. Distribution of review scores
select
    review_score,
    count(review_id) as total_reviews,
    round((count(review_id)::numeric / sum(count(review_id)) over()) * 100,2) as pct_of_total
from silver.order_reviews
where review_score is not null
group by review_score
order by review_score desc;


-- 40. Percentage of orders that receive a review
select
    count(distinct r.order_id) as orders_with_reviews,
    count(distinct o.order_id) as total_delivered_orders,
    round((count(distinct r.order_id)::numeric / count(distinct o.order_id)) * 100,2) as review_response_rate_pct
from silver.orders o
left join silver.order_reviews r on o.order_id = r.order_id
where o.order_status = 'delivered';


-- 41. Delivery speed vs. review score
with one_review_per_order as (
    select order_id, max(review_score) as review_score
    from silver.order_reviews
    group by order_id
),
delivery_calc as (
    select
        o.order_id,
        extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400 as delivery_days,
        r.review_score
    from silver.orders o
    join one_review_per_order r on o.order_id = r.order_id
    where o.order_status = 'delivered'
      and o.order_delivered_customer_date is not null
      and o.order_purchase_timestamp is not null
),
delivery_buckets as (
    select
        order_id,
        review_score,
        case
            when delivery_days <= 5 then '1. 0-5 Days (Fast)'
            when delivery_days <= 10 then '2. 6-10 Days (Acceptable)'
            when delivery_days <= 15 then '3. 11-15 Days (Slow)'
            when delivery_days <= 20 then '4. 16-20 Days (Very Slow)'
            else '5. 20+ Days (Critical)'
        end as speed_bucket
    from delivery_calc
)
select
    speed_bucket,
    count(order_id) as total_orders,
    round(avg(review_score)::numeric,2) as avg_rating
from delivery_buckets
group by speed_bucket
order by speed_bucket asc;


-- 42. Product categories with the most negative reviews (score 1-2)
with one_review_per_order as (
    select order_id, max(review_score) as review_score
    from silver.order_reviews
    group by order_id
)
select
    coalesce(t.product_category_name_english, p.product_category_name) as category_name,
    count(r.order_id) as negative_review_count
from one_review_per_order r
join silver.order_items oi on r.order_id = oi.order_id
join silver.products p on oi.product_id = p.product_id
left join silver.product_category_name_translation t on p.product_category_name = t.product_category_name
where r.review_score in (1,2)
group by category_name
order by negative_review_count desc
limit 10;


-- ============================================================
-- GEOGRAPHY
-- ============================================================

-- 43. States with highest concentration of customers and sellers
with customer_counts as (
    select customer_state as state, count(distinct customer_id) as total_customers
    from silver.customers
    group by customer_state
),
seller_counts as (
    select seller_state as state, count(distinct seller_id) as total_sellers
    from silver.sellers
    group by seller_state
)
select
    coalesce(c.state, s.state) as state,
    coalesce(c.total_customers,0) as total_customers,
    coalesce(s.total_sellers,0) as total_sellers
from customer_counts c
full outer join seller_counts s on c.state = s.state
order by total_customers desc, total_sellers desc
limit 10;


-- 44. Same-state vs. cross-state delivery time comparison
with delivery_data as (
    select
        o.order_id,
        c.customer_state,
        s.seller_state,
        case when c.customer_state = s.seller_state then '1. Same State (Intrastate)' else '2. Cross-State (Interstate)' end as delivery_route,
        extract(epoch from (o.order_delivered_customer_date - o.order_purchase_timestamp)) / 86400 as delivery_days
    from silver.orders o
    join silver.customers c on o.customer_id = c.customer_id
    join silver.order_items oi on o.order_id = oi.order_id
    join silver.sellers s on oi.seller_id = s.seller_id
    where o.order_status = 'delivered' and o.order_delivered_customer_date is not null
)
select
    delivery_route,
    count(distinct order_id) as total_orders,
    round(avg(delivery_days)::numeric,2) as avg_delivery_time_days
from delivery_data
group by delivery_route
order by delivery_route asc;
