# E-commerce Sales Analysis

End-to-end data analytics project on the Olist Brazilian e-commerce 
dataset — from raw data profiling to a validated star schema, four 
SQL-driven analyses, and an interactive Power BI dashboard.

## What this project answers
- Does late delivery actually hurt customer satisfaction? (Yes — 
  statistically confirmed, p<0.001)
- How often do customers come back? (Rarely — 97% are one-time buyers)
- Which customers drive the most revenue? (RFM segmentation)
- How concentrated is revenue across categories? (Pareto analysis)

## Key technical decisions
- Grain of every fact table decided before writing any SQL
- customer_unique_id used throughout, not the per-order customer_id
- Every data anomaly flagged, never silently deleted (see docs/decision_log.md)
- Fact/dimension model validated by reconciling totals at every stage

## Full documentation
- [Business findings & recommendations](report.md)
- [Complete project journey & reasoning](project_journey.md)
- [Data dictionary](docs/data_dictionary.md)

## Tech stack
SQL Server (T-SQL) · Python (Pandas) · Power BI (DAX)
