# Business Questions

This document lists all business questions answered in this project's analysis phase. See `scripts/analysis/Analysis_Q&A_report_script.sql` for the SQL used to answer each question, `docs/olist data report Q&A.pdf` for the full results, and `docs/key_insights_Q&A_report.md` for the narrative summary of what the data shows.

---

## 📊 Sales & Revenue
1. What is the total revenue and total number of orders overall?
2. What is the month-over-month revenue trend across the full dataset?
3. What is the month-over-month revenue growth rate (%)?
4. Which product categories generate the highest total revenue?
5. Which product categories have the highest order volume (most items sold)?
6. What is the average order value (AOV) overall, and how does it vary by state?
7. What is the average number of items per order?
8. What is the busiest month/season for orders (seasonality check)?
9. What day of the week sees the most orders placed?

## 👤 Customers
10. How many unique customers are there vs. total orders placed?
11. Who are the repeat customers (customers with more than one order)?
12. What percentage of total revenue comes from repeat customers vs. one-time customers?
13. What is the average time gap between a customer's first and second order?
14. What does customer retention look like by monthly cohort (grouped by first purchase month)?
15. Which states/cities have the most customers?
16. Which states/cities generate the highest revenue per customer?

## 🏪 Sellers
17. Who are the top sellers by total revenue?
18. How concentrated is revenue among the top sellers (what % of revenue comes from top 10%)?
19. How does seller count and performance vary by state?
20. What is the average revenue per seller?
21. Which sellers have the most orders but the lowest average review score (potential quality concern)?

## 📦 Products
22. Which are the top best-selling products by revenue?
23. Which are the top best-selling products by quantity sold?
24. Which product categories have the highest and lowest average review scores?
25. Are there categories with high revenue but low review scores (possible quality/expectation mismatch)?
26. What is the average price per product category?
27. Which categories have the widest price range (cheapest to most expensive item)?

## 🚚 Delivery & Logistics
28. What is the average delivery time (purchase to delivery) overall?
29. How does average delivery time vary by state?
30. What percentage of orders are delivered late (after the estimated delivery date)?
31. Which states experience the most delivery delays?
32. Is there a relationship between delivery delay and review score (do late deliveries get worse reviews)?
33. What is the average time between order approval and handoff to the carrier?
34. What is the average time between carrier handoff and customer delivery?

## 💳 Payments
35. What are the most common payment methods used?
36. Does payment type affect average order value (e.g., do credit card orders tend to be larger)?
37. How often are orders paid in installments, and what's the average number of installments?
38. Is there a relationship between number of installments and order value?

## ⭐ Reviews & Satisfaction
39. What is the overall distribution of review scores (1–5)?
40. What percentage of orders receive a review at all?
41. Is there a correlation between delivery speed and review score?
42. Which product categories receive the most negative reviews (score 1–2)?

## 🌍 Geography
43. Which states have the highest concentration of both customers and sellers?
44. Is there a pattern between customer-seller distance (same state vs. cross-state) and delivery time?
