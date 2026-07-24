# Key Findings & Insights

This document summarizes the most important takeaways from the full business analysis (see `docs/olist data report Q&A.pdf` for all 44 question-level answers and `scripts/analysis/Analysis_Q&A_report_script.sql` for the underlying SQL). Rather than repeating every number, this focuses on what the data actually *means* for the business.

---

## 1. Revenue is growing, but growth is slowing down

Monthly revenue climbed steadily from **R$127K in January 2017** to a peak above **R$1.15M in November 2017**, driven by a clear seasonal spike (likely Black Friday). Through 2018, revenue plateaued in the **R$1.0M–1.13M/month** range rather than continuing to climb — growth rates in the back half of the dataset are frequently flat or negative month-over-month, compared to the explosive +50–100% swings seen in early 2017.

**Takeaway:** The platform's early hyper-growth phase has matured into a stable, slower-growing business. Future growth likely needs to come from increasing order value or customer retention rather than pure new-customer acquisition, which is the next finding.

---

## 2. Retention is the platform's biggest weakness

- Only **~3,000 of 96,000 customers (about 3%)** ever placed a second order.
- Repeat customers contribute just **5.6% of total revenue** — the business is almost entirely dependent on one-time buyers.
- When customers do return, the average gap before their second order is **81 days** — nearly 3 months, suggesting no strong habit-forming purchase cycle.

**Takeaway:** This is the single most actionable insight in the dataset. A marketplace this reliant on one-time buyers has high acquisition-cost exposure — every dollar of revenue is essentially "new" spend. A loyalty program, post-purchase email flow, or 60–90 day win-back campaign (targeting that 81-day gap) would directly address the platform's largest structural risk.

---

## 3. Revenue is highly concentrated among a small group of sellers

The top 10% of sellers generate **67% of total seller revenue**. Combined with the finding that some high-volume sellers have review scores as low as **2.4–3.3 out of 5**, this points to two separate risks:

- **Concentration risk:** losing even a handful of top sellers would materially impact platform revenue
- **Quality risk:** some of the platform's highest-volume sellers are also among its worst-rated — a churn risk for the customers they serve

**Takeaway:** Worth investigating whether these low-rated, high-volume sellers are seeing declining order counts over time (a signal customers are already reacting) — this would be a natural follow-up analysis for the Gold layer.

---

## 4. Delivery speed is the strongest predictor of customer satisfaction

This is the clearest, most statistically obvious pattern in the entire dataset:

| Delivery Window | Avg Review Score |
|---|---|
| 0–5 days | 4.45 |
| 6–10 days | 4.36 |
| 11–15 days | 4.27 |
| 16–20 days | 4.13 |
| 20+ days | 3.23 |

Orders delivered **late** (past the estimated date) average a **2.57** review score, compared to **4.30** for on-time/early orders — a gap of nearly 2 full stars. Only **8.11%** of orders are delivered late, but that small slice is doing outsized damage to overall satisfaction.

**Takeaway:** Delivery reliability, not delivery speed alone, is what protects review scores. Estimated delivery dates should probably be padded more conservatively for the slowest-performing states (see below), rather than promising fast dates and missing them.

---

## 5. Logistics performance varies dramatically by geography

- Cross-state deliveries take **almost 2x longer** than same-state deliveries (15.05 days vs. 7.93 days)
- The slowest-delivery states (**RR, AP, AM, AL, PA** — all North/Northeast Brazil) average **23–29 days**, compared to the national average of 12.56 days
- **São Paulo (SP)** dominates both the seller base (1,849 sellers) and order volume (40,500+ orders) — most of the country's logistics infrastructure is effectively built around one state

**Takeaway:** Customers in remote states are structurally disadvantaged — they wait 2–3x longer than the national average, which (per finding #4) directly predicts worse reviews. A regional fulfillment hub outside the Southeast, or partnering with region-specific sellers, could meaningfully close this gap.

---

## 6. Category performance splits into two clear groups: quality issues vs. genuine bestsellers

- **office_furniture** stands out as a red flag: a respectable revenue category (R$268K) but the **lowest average review score (3.52)** of any major category — a real quality or expectation-mismatch problem worth investigating at the product level
- In contrast, **health_beauty**, **watches_gifts**, and **bed_bath_table** are both top revenue generators *and* reasonably well-reviewed — these are the categories worth prioritizing for marketing spend
- **books** (general interest and imported) are the platform's highest-rated categories (4.51) despite modest revenue — an underexploited opportunity if the platform wanted to grow a high-satisfaction niche

**Takeaway:** Revenue and satisfaction don't always move together. Category-level strategy shouldn't be revenue-only; office_furniture in particular needs a root-cause review (return rate? shipping damage? product description accuracy?).

---

## 7. Payment behavior signals real price sensitivity

- Over half of all orders (**51.46%**) are paid in installments, with an average of **4.75 installments** when split
- Installment orders have meaningfully higher order values than single-payment orders — customers are financing larger purchases rather than making smaller one-off buys
- **Credit card** dominates (77% of transactions) over boleto (20%) and vouchers (6%)

**Takeaway:** Installment availability isn't a minor payment feature here — it's likely a core driver of order size. Any checkout friction on installment options would directly risk AOV.

---

## Summary: Three priorities if this were a real business

1. **Fix retention** — 5.6% of revenue from repeat customers is the platform's biggest gap; a win-back campaign targeting the 81-day reorder window is the highest-leverage single move available in this data
2. **Protect delivery reliability, especially outside São Paulo** — the review-score gap between on-time and late delivery (4.30 vs. 2.57) is the clearest lever the business has over customer satisfaction
3. **Investigate office_furniture and other high-revenue/low-review categories** — these are quietly generating dissatisfaction at scale and are a clear next-step deep-dive
