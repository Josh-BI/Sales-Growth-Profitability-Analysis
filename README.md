# TrailForge Outdoor Co.: Sales Growth vs. Profitability

# Project Overview
This project analyzes sales performance and profitability to identify revenue trends, profitable product categories,
and to improve business margins.
 
---

## 1. Business problem
TrailForge, a growing multichannel outdoor-gear retailer selling in 10 countries, saw net revenue grow strongly in FY2025 while profit after marketing grew at roughly half that pace (the CFO's preliminary, unverified view). The CFO needs to know where the margin went, which levers are responsible, and what to do about it before the FY2026 budget is locked.

## 2. Objectives and key questions
1. Where did the margin go between FY2024 and FY2025? (profit bridge)
2. Is discounting still paying for itself?
3. Which channels, categories and products earn their keep after all costs?
4. Is shipping eroding margin, and where?
5. How costly are returns and what drives them?
6. Which customers are worth acquiring and do they come back?
7. Is marketing spend becoming less efficient?
8. What is the sized FY2026 opportunity from the main levers? (scenario analysis, not a forecast)

## 3. Dataset
Ten CSV files. The files are imperfect: they contain documented data-quality issues to be profiled and cleaned.

| File | Rows | Columns | Grain |
|---|---:|---:|---|
| `fact_orders.csv` | 4,471 | 14 | order |
| `fact_order_items.csv` | 8,519 | 8 | order line |
| `fact_returns.csv` | 681 | 8 | return |
| `fact_marketing_spend.csv` | 388 | 5 | month × channel × region |
| `dim_customer.csv` | 2,182 | 8 | customer record |
| `dim_product.csv` | 60 | 11 | SKU |
| `dim_promotion.csv` | 79 | 10 | promotion |
| `dim_channel.csv` | 4 | 7 | channel |
| `dim_geography.csv` | 10 | 7 | country |
| `dim_date.csv` | 2,191 | 13 | day (2021-01-01 to 2026-12-31) |

##  Repository Structure

```text
Sales-Growth-Profitability-Analysis/
│
├── Business_Case/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Business_Case\01_business_case.md"]
│
├── Cleaned Data/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean dim_channel.csv"]
        ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean dim_customers.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean dim_product.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean dim_promotion.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean fact_marketing_spend.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean fact_order_items.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean fact_orders.csv"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Cleaned Data\Clean fact_returns.csv"]
│
├── Dashboard Screenshot/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Dashboard Screenshot\Profile View.png.png"]
        [""C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Dashboard Screenshot\Margin Drivers.png.png"]
│
├── Data Raw/
│   ├── fact_orders.csv
│   ├── fact_order_items.csv
│   ├── fact_returns.csv
│   ├── fact_marketing_spend.csv
│   ├── dim_customer.csv
│   ├── dim_product.csv
│   ├── dim_promotion.csv
│   ├── dim_channel.csv
│   ├── dim_geography.csv
│   └── dim_date.csv
│
├── Documentation/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Documentation\02_data_architecture.md"]
        ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Documentation\03_kpi_definitions.md"]
│
├── Power BI/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\Power BI\Trail Forge Outdoor Co..pbix"]
│
├── SQL/
│   └── ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\SQL\TrailForge Data Cleaning.sql"]
        ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\SQL\Views And KPIs.sql"]
        ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\SQL\TrailForge Outdoor EDA.sql"]
        ["C:\Users\DELL\Documents\GitHub\Sales-Growth-Profitability-Analysis\SQL\06_eda_findings_summary.md"]
│
└── README.md
```


## 4. Data model
Star-style model with two sales facts (order header and order line) plus returns and marketing spend, sharing date, customer, product, channel, geography and promotion dimensions. Diagram, data dictionary, relationships and business rules.

## 5. Tools and technologies
* SQL Server (SQL: staging, cleaning, CTEs, window functions, date logic, KPI views)
* Power BI Desktop (star schema, Power Query, DAX, interactive report)

## 6. Methodology
Setup and load: Create database, schemas, import CSVs unchanged.

  A. Profiling data:  Row counts, duplicates, nulls, label variants, date formats, orphans, rule violations. 
  
  B. Cleaning: Raw tables are reserved and new tables are created for the cleaned and relevant columns.
  
  D. KPIs: Order and line-level P&L views at safe grain; reconciliation checks. 
  
  C. Exploration Simple queries, one block per business question, each with findings.
  
Power BI:  Data modelling, DAX, two report pages.

## 7. KPI definitions
Contribution Profit = Net Revenue − Net COGS − Shipping Cost − Return Shipping − Channel Fees; margins are % of Net Revenue (= net merchandise + shipping charged − refunds).

## 8. Dashboard preview
<img width="1320" height="744" alt="Profile View png" src="https://github.com/user-attachments/assets/fbcffd5e-7810-4c4c-bff2-290b6bd49d44" />
<img width="1321" height="744" alt="Margin Drivers png" src="https://github.com/user-attachments/assets/30c54a6e-5e10-4432-a9d4-3eef7eeb2583" />


## 9. Key findings
Revenue grew 44% in 2025 but contribution profit grew only 29%, because margin slipped from 29.6% to 26.4%. About three-quarters of the slip is product cost rising relative to list prices, concentrated in Electronics, Footwear and Camping. Deeper consumer discounting, unrecovered shipping to far markets, more Marketplace sales and faster-growing marketing spend added to the pressure, but each is smaller.

## 10. Limitations
* Synthetic data: patterns are plausible, not real; conclusions describe this fictional company only.
* Marketing spend cannot be attributed to orders; efficiency is measured in aggregate.
* Contribution profit excludes overhead; it is not net income.
* Return metrics for orders in the last 35 days are immature.
* Scenario results are sizing exercises; customer response is not observable.
* Imputed values (shipping cost, unit cost, marketing months) are approximations and are flagged in the clean layer.
