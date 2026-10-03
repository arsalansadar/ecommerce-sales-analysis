# E-commerce Sales Analysis
### A Data Analytics Case Study on the Olist Brazilian Marketplace

**Period covered:** September 2016 – October 2018
**Tools:** SQL Server (T-SQL), Python (SciPy), Power BI (DAX)
**Author:** Arsalan Sadar

---

## 1. Executive Summary

This analysis examined 99,441 orders from 94,983 customers on a Brazilian e-commerce marketplace, using a SQL Server star schema and a Power BI dashboard for reporting.

- **Late delivery sharply reduces customer satisfaction.** Orders delivered after the estimated date average a 2.27★ review, compared to 4.29★ for on-time orders — a gap confirmed statistically significant (Mann-Whitney U test, p < 0.001) and consistent across every major product category. Even a 1–3 day delay nearly triples the rate of 1–2★ reviews (9.3% → 32.1%).

- **The business is acquisition-driven, not retention-driven.** 97% of customers purchase exactly once. Repeat buyers make up only 3.04% of the customer base and contribute just 5.56% of revenue. Month-on-month cohort tracking shows only 0.48% of any given month's customers return within the next month — what repeat purchasing does happen is spread thinly over a year or more, not concentrated early.

- **Revenue is concentrated in a narrow, partly-cooling customer segment.** Two RFM segments — New High-Value and Win-Back Priority — represent 30% of customers but 58% of total revenue. Half of this value (Win-Back Priority) has not purchased in 400+ days on average, making timely re-engagement a priority before this revenue is lost entirely.

- **Category revenue is moderately concentrated.** 18 of 74 product categories (24%) account for just over 80% of total revenue — a moderate rather than extreme concentration. The top 5 categories alone (health & beauty, watches/gifts, bed/bath/table, sports/leisure, computer accessories) already make up roughly 40% of revenue.

---

## 2. Business Context & Objective

Olist is a Brazilian e-commerce marketplace: independent sellers list products, and the platform connects them to customers, handling orders, payments, and logistics coordination between the two sides.

**Business questions this analysis set out to answer:**
- Is delivery performance affecting customer satisfaction, and by how much?
- How often do customers return, and how quickly does that drop off?
- Which customers drive the most revenue, and which are at risk of being lost?
- How concentrated is revenue across product categories?

**What this data can answer, and what it can't.** The dataset covers orders, items, payments, reviews, products, sellers, and customers. It does not include website traffic, advertising spend, product cost, or discount data. This means the analysis can measure revenue, repeat behavior, delivery performance, and customer value — but not conversion rate, customer acquisition cost, or true profit margin. Any recommendation that would require those figures is flagged as such rather than assumed.

**Revenue definition used throughout:** Revenue = SUM(item price), excluding freight and excluding canceled/unavailable orders, unless otherwise stated. Where a different scope was used for a specific analysis (e.g., including freight, or including all order statuses), this is called out explicitly next to the relevant number.

---

## 3. Data & Methodology

**Source:** Olist's public e-commerce dataset — 9 related tables (orders, order items, payments, reviews, products, sellers, customers, geolocation, category translations), roughly 100,000 orders.

**Process followed:**
1. **Profiling** — every table was checked for grain, primary keys, nulls, orphaned foreign keys, and date-logic consistency before any analysis began.
2. **Cleaning layer** — a SQL `clean` schema converted types, fixed naming issues, and flagged (never silently deleted) data anomalies.
3. **Star schema** — two fact tables (`fact_orders` at order grain, `fact_order_items` at order-item grain) and four dimensions (customer, product, seller, date), built with surrogate keys and validated by reconciling totals back to source data at every step.
4. **Analysis** — four analyses (delivery vs. review, cohort retention, RFM segmentation, category concentration) run in SQL, with one statistical significance test run in Python.
5. **Reporting** — a four-page Power BI dashboard, with DAX measures cross-checked against the SQL results.

**Key data-quality issues found and how they were handled** (full detail in the project's decision log):
- 31 orders had logically inconsistent delivery dates (e.g., delivered before being handed to the carrier) — flagged and excluded from delivery-time calculations, not deleted.
- 789 `review_id`s were shared across 2–3 orders — confirmed as a known Olist system behavior (survey links reused across a customer's orders in close succession), not a data error. Reviews were deduplicated to one row per order using the most recent review.
- 610 products had no category and no photos — treated as incomplete listings, categorized as "Unknown" rather than dropped, since 17 of them still appear in real, revenue-generating orders.
- 3 orders had a payment record with type "not defined" and value zero, with no other payment row to explain it — a genuine data gap, excluded from payment-value analysis only.
- The geolocation table had roughly 1 million rows for only 19,015 unique postal-code prefixes (GPS noise); it was aggregated to one row per prefix before any use.

**Customer identity note:** the dataset issues a new `customer_id` for every order, so repeat-customer analysis uses `customer_unique_id` throughout — the field that actually identifies a returning person.

---

## 4. Key Findings

### Finding 1: Delivery Delay Is the Strongest Driver of Dissatisfaction Found in This Data

**What we found:** Among delivered, reviewed orders, review scores decline step by step as delay increases:

| Delivery status | Orders | Avg. review score | % rated 1–2★ |
|---|---|---|---|
| On-time / early | 89,428 | 4.29 | 9.3% |
| Late 1–3 days | 1,852 | 3.29 | 32.1% |
| Late 4–7 days | 1,748 | 2.10 | 67.6% |
| Late 8+ days | 2,781 | 1.70 | 79.3% |

The gap between on-time and late orders overall (4.29 vs. 2.27) was tested with a Mann-Whitney U test (chosen because review scores are a discrete, non-normally distributed scale) and came back with p < 0.001 — the difference is not due to chance.

This pattern held inside every product category with a sufficient sample size: the gap ranged from 1.33 points (office furniture) to 2.54 points (musical instruments), but a late order scored lower than an on-time order in every single category checked. This rules out the possibility that one high-volume category was driving the overall result.

**Caveat:** at very long delays (30+ days), reactions became more mixed — 68% of these orders were rated 1–2★, but 23% were still rated 4–5★. This dataset does not include refund or compensation data, so it's not possible to confirm whether proactive compensation explains the more forgiving minority, but it's a reasonable hypothesis for follow-up.

**Why it matters:** customers react to *any* lateness, not just severe lateness — the sharpest drop in satisfaction happens in the first 1–3 days past the estimate, not at the extreme end.

**Recommendation:** treat delivery-date accuracy as an operational priority above delay severity alone. Consider more conservative estimated-delivery dates (reducing how often an order is classified "late" at all) and proactive delay notifications for orders at risk.

---

### Finding 2: The Business Runs on New Customers, Not Repeat Ones

**What we found:** 97% of customers placed exactly one order. Of the 94,983 customers with at least one valid order, only 2,887 (3.04%) made two or more purchases, and this group contributed just 5.56% of total revenue.

Cohort tracking confirms this at the order-timing level: across 24 monthly cohorts with enough history to measure, only 0.48% of customers who ordered in a given month placed another order in the very next month. What little repeat purchasing does occur is spread out over many months rather than happening quickly.

**Why it matters:** this is a structural trait of the business, not a short-term dip. A campaign aimed at "increasing repeat rate" without understanding *why* repeat purchases are this rare (product category mix, one-off gift purchases, marketplace dynamics) risks spending on an unlikely win.

**Recommendation:** before investing in retention campaigns, investigate root cause — is this expected for the product mix (e.g., infrequently-repurchased categories like furniture), or is there a controllable friction point (e.g., no reason given to come back)? This requires data this project does not have (e.g., category-level purchase-cycle norms) and is flagged as a follow-up question rather than answered here.

---

### Finding 3: A Small, Partly-Cooling Segment Holds More Than Half of Revenue

**What we found:** RFM segmentation (Recency, Frequency, Monetary scoring) split the 94,983 customers into 8 segments:

| Segment | Customers | % of customers | Revenue | % of revenue | Avg. recency (days) |
|---|---|---|---|---|---|
| New High-Value | 14,724 | 15.50% | ₹3,944,379.84 | 29.23% | 97.8 |
| Win-Back Priority | 14,014 | 14.75% | ₹3,896,061.29 | 28.87% | 401.4 |
| Needs Attention | 18,375 | 19.35% | ₹2,396,871.04 | 17.76% | 226.2 |
| Lost / Hibernating | 22,951 | 24.16% | ₹1,281,159.50 | 9.49% | 401.8 |
| New Customers | 22,032 | 23.20% | ₹1,225,460.64 | 9.08% | 95.6 |
| Champions | 1,236 | 1.30% | ₹333,514.18 | 2.47% | 94.5 |
| Loyal Repeat | 1,195 | 1.26% | ₹307,486.95 | 2.28% | 271.7 |
| At-Risk Repeat | 456 | 0.48% | ₹109,467.30 | 0.81% | 471.8 |

New High-Value and Win-Back Priority together are 30.25% of customers but 58.10% of revenue. Both are one-time, high-spend buyers — the difference is entirely in recency. New High-Value customers ordered roughly 3 months ago on average and are still realistically reachable for a second purchase; Win-Back Priority customers ordered over a year ago on average and are at serious risk of being permanently lost.

**Why it matters:** this is the single highest-leverage segment distinction in the data. Treating these two groups the same way (or not treating them differently at all) risks losing the Win-Back revenue entirely while under-investing in converting New High-Value customers into repeat buyers while they're still active.

**Recommendation:** run a second-purchase campaign targeted specifically at New High-Value customers before they age into Win-Back territory, and a separate, dedicated win-back offer for the Win-Back Priority segment given the revenue at stake. Avoid generic, one-size-fits-all retention messaging across both.

---

### Finding 4: Revenue Concentration Across Categories Is Moderate, Not Extreme

**What we found:** 18 of 74 product categories account for a little over 80% of total revenue. The top 5 — health & beauty, watches & gifts, bed/bath/table, sports & leisure, and computer accessories — alone make up roughly 40% of revenue.

**Why it matters:** this is a moderate concentration, not the "a handful of categories carry everything" pattern sometimes assumed. It suggests the business is reasonably diversified across categories, though the top 5 still represent meaningful concentration risk if any one of them is disrupted (e.g., a major seller leaving, a supply issue).

**Recommendation:** monitor the top 5 categories specifically for seller concentration and supply reliability, since a disruption there would have an outsized effect on total revenue. Treat the long tail of categories below the 80% line as lower-priority for operational investment.

---

## 5. Recommendations Summary (Prioritized)

1. **Investigate delivery-date estimation accuracy.** This is the finding with the clearest statistical backing and the clearest lever (promise dates, not just logistics speed).
2. **Launch a second-purchase campaign for the New High-Value segment** before this group drifts into Win-Back territory — proactive, time-sensitive.
3. **Launch a separate win-back campaign for the Win-Back Priority segment**, given the revenue still at stake despite the long inactivity.
4. **Investigate the root cause of the low repeat-purchase rate** before committing budget to broad retention campaigns.
5. **Monitor seller and supply concentration in the top 5 categories.**

---

## 6. Limitations

- The dataset has no advertising spend, website traffic, or product cost data, so conversion rate, customer acquisition cost, and true profit margin could not be calculated.
- No refund, compensation, or customer-service contact data was available, which limits the ability to explain why some heavily delayed orders still received high reviews.
- Data at both edges of the collection period (Sept–Dec 2016 and Sept–Oct 2018) is sparse or incomplete; trend analysis relies primarily on January 2017 – August 2018, where data is consistently populated.
- Cohort retention figures are based on all order activity regardless of order status (including canceled/unavailable orders), while revenue-based figures (RFM, Pareto) exclude canceled/unavailable orders. This is an intentional scope difference, not an inconsistency, and is noted wherever the two are compared.
- RFM and revenue totals exclude 8 valid-status orders that have no line items (and therefore no calculable revenue); these orders are still counted in order-level metrics.

---

## 7. Appendix

**Tech stack:** SQL Server (T-SQL) for data modeling and all four analyses; Python (pandas, SciPy) for the single statistical significance test (Mann-Whitney U); Power BI and DAX for the four-page interactive dashboard (Executive Overview, Delivery & Satisfaction, Customer Insights, Product & Category).

**Data model:** star schema with two fact tables (`fact_orders` — order grain; `fact_order_items` — order-item grain) and four dimensions (`dim_customer`, `dim_product`, `dim_seller`, `dim_date`), plus supporting analysis views (`vw_rfm_base`, `vw_rfm_scored`, `vw_rfm_segments`, `vw_cohort_retention`).

**Supporting project files:** data dictionary, entity-relationship diagram, full decision log, and all SQL scripts are included in the project repository alongside this report.
