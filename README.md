# Olist E-Commerce Data Warehouse & Analytics Project

Welcome to my **Olist E-Commerce Data Warehouse & Analytics Project** repository! 🚀

This project demonstrates a complete data warehousing and analytics solution built entirely in SQL (PostgreSQL) and Power BI — from raw data ingestion to a business-ready analytics dashboard. Built as a portfolio project, it follows the **Medallion Architecture** (Bronze / Silver / Gold) and industry-standard data engineering and analytics practices.

---

## 🏗️ Data Architecture

This project follows the **Medallion Architecture** with **Bronze**, **Silver**, and **Gold** layers:

1. **Bronze Layer**: Stores raw data exactly as-is from the source CSV files (Olist's 9 relational datasets), loaded into PostgreSQL with no transformations, no constraints.
2. **Silver Layer**: Cleanses, standardizes, and documents data quality decisions — fixing data types, removing invalid values, resolving inconsistent entries — verified through direct exploration of the raw data rather than assumption.
3. **Gold Layer**: A business-ready **star schema** (one fact table + four dimension tables), enriched with derived columns, and connected by enforced foreign key constraints — built specifically for Power BI consumption.

ER diagrams for all three layers are available in `docs/bronze`,`docs/silver`,`docs/gold` showing how the schema evolves from unconstrained raw tables (Bronze) to a fully keyed, relational structure (Silver) to a proper star schema (Gold).

---

## 📖 Project Overview

This project involves:

1. **Data Architecture**: Designing a modern data warehouse using the Medallion Architecture.
2. **Data Ingestion & Cleaning**: Loading Olist's 9 raw relational tables and resolving real data quality issues — found and verified through direct SQL exploration, not guesswork.
3. **Data Modeling**: Building a star schema (fact + dimension tables) optimized for analytical queries, with derived business metrics (delivery timing, late-shipment flags, product size categories) pre-calculated at the warehouse level.
4. **Analytics & Reporting**: Answering 44 real business questions in SQL, then building a 5-page interactive Power BI dashboard on top of the gold layer.

🎯 This repository is intended to demonstrate practical skills in:
- SQL Development (joins, CTEs, window functions, stored procedures)
- Data Warehousing & Dimensional Modeling (star schema, surrogate keys, fact/dimension design)
- Data Cleaning & Transformation (with documented, verified decisions at every step)
- Business Intelligence & Reporting (Power BI, DAX)

---

## 🛠️ Tools Used

- **[Olist Brazilian E-Commerce Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)**: Source dataset (9 CSV files)
- **PostgreSQL**: Data warehouse database engine
- **pgAdmin**: GUI for managing and querying the database
- **Power BI**: Dashboard and visualization layer
- **Git/GitHub**: Version control and project hosting
- **draw.io**: Architecture and ER diagrams

---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

**Objective**
Develop a modern data warehouse using PostgreSQL to consolidate Olist's e-commerce data, enabling analytical reporting and informed business decision-making.

**Specifications**
- **Data Source**: Import data from 9 relational CSV files (customers, orders, order items, payments, reviews, products, sellers, geolocation, category translations).
- **Data Quality**: Cleanse and resolve real data quality issues (invalid coordinates, duplicate keys, impossible date sequences, orphaned references) — each one discovered and confirmed through direct SQL exploration before deciding how to handle it.
- **Integration**: Combine all 9 sources into a single, well-modeled star schema designed for analytical queries.
- **Documentation**: Every cleaning decision, every derived column, and every schema choice is documented in `docs/`.

### BI: Analytics & Reporting (Data Analysis)

**Objective**
Answer 44 real business questions across Sales, Customers, Sellers, Products, Delivery, Payments, Reviews, and Geography — then translate the findings into an interactive Power BI dashboard.

For the full list of business questions, see [`docs/Analysis_docs/business_questions.md`](docs/Analysis_docs/business_questions.md).
For the narrative summary of what the data actually shows, see [`docs/Analysis_docs/key_insights_Q&A_report.md`](docs/Analysis_docs/key_insights_Q&A_report.md).

---

## 📊 Power BI Dashboard

A 5-page interactive dashboard built on top of the Gold layer, covering Sales, Customers, Products, Sellers, and Delivery & Logistics. Every KPI and chart was cross-verified against the SQL analysis findings in `docs/Analysis_docs/olist data report Q&A.pdf` before finalizing.

### Sales Overview
Revenue trend across 2016–2018 (with year-over-year seasonality comparison), day-of-week and weekday/weekend ordering patterns, and top revenue-generating categories.

![Sales Overview](docs/dashboard/Sales)

### Customers
Customer geography (mapped via lat/lng), the one-time vs. repeat customer revenue split, and top cities/states by customer volume and revenue per customer.

![Customers](docs/dashboard/Customers)

### Products
Top categories by revenue and quantity sold, price range analysis, and a revenue-vs-review-score scatter plot that surfaces categories with high revenue but low customer satisfaction.

![Products](docs/dashboard/Products)

### Sellers
Seller concentration by state, top sellers by revenue, and a volume-vs-rating scatter plot identifying high-volume sellers with below-average review scores.

![Sellers](docs/dashboard/Sellers)

### Delivery & Logistics
Delivery time by state, same-state vs. cross-state delivery comparison, and the relationship between delivery speed and review score — one of the strongest findings in the whole analysis.

![Delivery & Logistics](docs/dashboard/Delivery&logistics)

*Note: this dashboard was built as a first hands-on Power BI project, prioritizing accurate, verified data over advanced visual polish (custom navigation, full theming). A more refined version is planned as a follow-up project after deeper Power BI study.*

---

## 📂 Repository Structure

```
sql-olist-data-project/
│
├── datasets/                           # Instructions for downloading 
│   ├── .gitignore
│   └── Readme_dataset.md
├── docs/                               # Documentation and diagrams
│   ├── Analysis_docs/
│   │   ├── buisness_question.md
│   │   ├── key_insights_Q&A_report.md
│   │   └── olist data report Q&A.pdf
│   ├── bronze/
│   │   ├── bronze_data_schema.md
│   │   └── data_architecture_bronze.png
│   ├── dashboard/
│   │   ├── Customers
│   │   ├── Delivery&logistics
│   │   ├── Products
│   │   ├── Sales
│   │   └── Sellers
│   ├── gold/ 
│   │   ├── data_architecture_gold.png
│   │   └── gold_data_schema.md
│   ├── silver/
│   │   ├── data_architecture_silver.png
│   │   └── silver_data_scheme.md
├── scripts/
│   ├── Analysis/
│   │   └── Analysis_Q&A_report_script.sql
│   ├── Gold/
│   │   ├── ddl_gold.sql
│   │   ├── load_gold.sql
│   ├── bronze/
│   │   ├── ddl_bronze.sql
│   │   └── load_bronze.sql
│   ├── silver/
│   │   ├── ddl_silver.sql
│   │   └── load_silver.sql
│   │
│   └── init_database.sql
│       
│
├── README.md
└── LICENSE
```
---

## 📊 Key Business Questions Answered

- What is the monthly revenue trend and growth rate?
- Which product categories and sellers generate the most revenue?
- Who are the repeat customers, and what does retention look like by cohort?
- How does delivery performance vary by state, and does it affect review scores?
- Which payment methods are most common, and how do they relate to order value?

*(Full list in [`docs/business_questions.md`](docs/business_questions.md))*

---

## 🌟 About Me

Hi, I'm **Varun** — a data analysis student building hands-on SQL and Power BI skills through real end-to-end projects, working toward a junior data analyst role. This project reflects independent, from-scratch SQL practice (no AI-assisted query writing) as part of a structured job-readiness plan.

Connect with me on [LinkedIn](https://www.linkedin.com/in/varundadhwal/) or check out my other project: [Instacart Market Basket Analysis](https://github.com/VARUNDADHWAL/Instacart_market_analysis).

---

## 🛡️ License

This project is open for viewing and reference. Dataset credit: [Olist Store, via Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
