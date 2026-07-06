# Olist E-Commerce Data Warehouse & Analytics Project

Welcome to my **Olist E-Commerce Data Warehouse & Analytics Project** repository! 🚀

This project demonstrates a complete data warehousing and analytics solution built entirely in SQL (PostgreSQL) — from raw data ingestion to business-ready insights. it follows industry-standard data engineering and analytics practices.

---

## 🏗️ Data Architecture

This project follows the **Medallion Architecture** with **Bronze**, **Silver**, and **Gold** layers:

1. **Bronze Layer**: Stores raw data exactly as-is from the source CSV files (Olist's 9 relational datasets), loaded into PostgreSQL with no transformations.
2. **Silver Layer**: Cleanses, standardizes, and normalizes the bronze data — fixing data types, removing duplicates, handling nulls, and resolving inconsistent values — to prepare it for analysis.
3. **Gold Layer**: Houses business-ready data modeled into a star schema (fact and dimension tables) optimized for reporting and analytics.

*(Architecture diagram to be added: `docs/data_architecture.png`)*

---

## 📖 Project Overview

This project involves:

1. **Data Architecture**: Designing a modern data warehouse using the Medallion Architecture .
2. **Data Ingestion & Cleaning**: Loading Olist's 9 raw relational tables and resolving data quality issues.
3. **Data Modeling**: Building fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Writing SQL-based analysis  and building a Power BI dashboard for actionable business insights.

🎯 This repository is intended to demonstrate practical skills in:
- SQL Development
- Data Warehousing
- Data Cleaning & Transformation
- Data Modeling 
- Business Intelligence & Reporting 

---

## 🛠️ Tools Used

- **[Olist Brazilian E-Commerce Dataset (Kaggle)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)**: Source dataset (9 CSV files)
- **PostgreSQL**: Data warehouse database engine
- **pgAdmin**: GUI for managing and querying the database
- **Power BI**: Dashboard and visualization layer
- **Git/GitHub**: Version control and project hosting
- **draw.io **: For architecture and star schema diagrams

---

## 🚀 Project Requirements

### Building the Data Warehouse (Data Engineering)

**Objective**
Develop a modern data warehouse using PostgreSQL to consolidate Olist's e-commerce data, enabling analytical reporting and informed business decision-making.

**Specifications**
- **Data Source**: Import data from 9 relational CSV files .
- **Data Quality**: Cleanse and resolve data quality issues (nulls, duplicates, type mismatches, orphaned keys) before analysis.
- **Integration**: Combine all 9 sources into a single, well-modeled star schema designed for analytical queries.
- **Scope**: Focus on the dataset as provided; historical change tracking is not required.
- **Documentation**: Provide clear documentation of the data model for both technical and non-technical readers.

---

### BI: Analytics & Reporting (Data Analysis)

**Objective**
Develop SQL-based analytics and a Power BI dashboard to deliver insights into:
- **Customer Behavior** (repeat purchases, retention, cohorts)
- **Seller & Product Performance** (top sellers, top categories, review scores)
- **Sales Trends** (monthly revenue, growth rate, average order value)
- **Delivery Performance** (delivery delays, regional logistics patterns)

These insights are framed as answers to real business questions.

For the full list of business questions, see `docs/business_questions.md`.

---

## 📂 Repository Structure

```
olist-data-warehouse-project/
│
├── datasets/                           # Raw Olist CSV files (9 source tables)
│
├── docs/                               # Project documentation and architecture details
│   ├── data_architecture.png           # Medallion architecture diagram
│   ├── data_model.png                  # Star schema diagram (fact + dimensions)
│   ├── data_catalog.md                 # Field descriptions for gold layer tables
│   ├── naming_conventions.md           # Naming rules for tables, columns, schemas
│   ├── business_questions.md           # Business questions answered by this project
│
├── scripts/                            # SQL scripts organized by layer
│   ├── bronze/                         # Raw data ingestion scripts
│   ├── silver/                         # Cleaning & transformation scripts
│   ├── gold/                           # Star schema view/table creation scripts
│   ├── analysis/                       # Business analysis queries (joins, CTEs, window functions)
│
├── power_bi/                           # Power BI dashboard file (.pbix) and screenshots
│
├── tests/                               # Data quality check scripts
│
├── README.md                           # Project overview and instructions
└── LICENSE                             # License information
```

---

## 📊 Key Business Questions Answered

- What is the monthly revenue trend and growth rate?
- Which product categories and sellers generate the most revenue?
- Who are the repeat customers, and what does retention look like by cohort?
- How does delivery performance vary by state, and does it affect review scores?
- Which payment methods are most common, and how do they relate to order value?

*(Full list in `docs/business_questions.md`)*

---

## 🌟 About Me

Hi, I'm **Varun** — a data analysis student building hands-on SQL and Power BI skills through real end-to-end projects, working toward a junior data analyst role. This project reflects independent, from-scratch SQL practice.

Connect with me on [LinkedIn](https://linkedin.com) *(https://www.linkedin.com/in/varundadhwal/)* or check out my other project: [Instacart Market Basket Analysis](https://github.com/VARUNDADHWAL/Instacart_market_analysis).

---

## 🛡️ License

This project is open for viewing and reference. Dataset credit: [Olist Store, via Kaggle](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce).
