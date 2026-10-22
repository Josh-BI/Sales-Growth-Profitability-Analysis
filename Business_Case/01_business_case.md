# Business Case: Growing Fast, Earning Less per Sale

Company: TrailForge Outdoor Co. (fictional) | Analysis period: 1 Jan 2023 – 31 Dec 2025 | Data extract date: 5 Jan 2026
Reporting currency: USD for all monetary values | Time zone: all timestamps in UTC
> All companies, customers and figures in this project are synthetic. No real individuals' data is used.

---

## 1. Company profile

| Item | Detail |
|---|---|
| Business | Designs and sells outdoor and adventure gear under its own *TrailForge* label, plus a small range of third-party electronics *Voltrek*. Headquartered in Denver, USA. |
| Products | 60 SKUs in six categories: Apparel, Footwear, Packs & Bags, Camping & Shelter, Hydration & Drinkware, Electronics & Lighting. |
| Customers | Individual outdoor enthusiasts (consumers) and business accounts (specialty retailers, corporate/organisation buyers). |
| Markets (10 countries, 4 regions) | North America (US, Canada), Europe (UK, Germany, France), Asia-Pacific (Australia, Singapore), Middle East & Africa (UAE, South Africa, Ghana). Markets were opened progressively (France Jul-2023, Singapore Apr-2023, South Africa Oct-2023, UAE Feb-2024, Ghana Jun-2024). |
| Sales channels | Website and Mobile App (launched Jul-2023) – direct to consumer; Marketplace – third-party online marketplace; Wholesale – invoiced B2B orders. |
| Fulfilment | Three hubs: Reno, USA (US and Canada); Rotterdam, Netherlands (UK, Germany, France, UAE, South Africa, Ghana); Singapore (Australia and Singapore). Carrier costs rise with distance and weight. |
| Revenue model | Merchandise sales at list price less discounts, plus shipping charged to customers. |
| Cost structure | Product cost (landed COGS); outbound shipping; return shipping; channel fees (Marketplace 15% of merchandise revenue; Website/App payment processing 2.9% + $0.30; Wholesale none); refunds on returns; monthly marketing spend (Website, App, Marketplace advertising). |
| Data-generating processes | E-commerce platform and marketplace feeds (orders, order lines), warehouse management/returns system, CRM (customers), finance (marketing spend, product costs), merchandising (product catalogue, promotions calendar). |

## 2. The business problem

For two years TrailForge has been proud of its top line. In FY2025 the Finance team's preliminary close showed that net revenue grew roughly 40%+ over FY2024 but profit after marketing grew only about half as fast. The Board's reaction was that the company is "buying growth". Nobody can say where the profit is going.

Several things changed at once during 2024–2025, and any of them could be responsible:

* Promotional activity expanded (more events, more channels, deeper discounts).
* The Marketplace and the new Mobile App changed the channel mix.
* New international markets were opened and carrier rates rose.
* Supplier costs increased for some categories, while list-price rises were smaller or skipped.
* Return volumes grew alongside sales.
* Marketing spend grew faster than revenue.

> *These are hypotheses to test, not findings. The data may confirm some, reject others, and show effects that interact.*

Why this matters. If margins keep eroding at the current pace while volume grows, the company funds its growth with cash it does not have. The Board has asked for a plan before the FY2026 budget is locked.

### Project brief (from the stakeholder)

> *From: Maya Okafor, Chief Financial Officer  *To: Analytics team  *Subject: Profit is not keeping up with growth: need answers before the Feb budget round.
> Our net revenue is up strongly but profit isn't. Before we decide on FY2026 pricing, promotions, channel and market plans I need to understand, with evidence: (1) where the margin went, (2) which levers are responsible and how big each is, (3) which products, channels and markets earn their keep, and (4) what we can do about it, with the money it is worth. Please be explicit about what is solid and what is uncertain. I will take your findings to the Board in a 10-minute slot, so lead with what matters. Our data comes from several systems and is not perfectly clean. Tell me what you had to assume.

## 3. Stakeholders and decisions

| Stakeholder | Decisions they must make | What they need from the analysis |
|---|---|---|
| CFO (sponsor) | FY2026 profit target, budget envelope | Profit bridge FY2024→FY2025; sized levers |
| Head of E-commerce | Promotion calendar, discount policy, free-shipping thresholds, Marketplace participation | Discount depth vs. profitability; shipping economics |
| Head of Merchandising | Pricing, supplier negotiations, range decisions | Product/category margin after all costs; cost-vs-price gap |
| Head of Operations | Carrier contracts, hub allocation, returns policy | Shipping and returns cost by country, category, reason |
| Head of Marketing | Channel/region budget | Spend efficiency and customer value by acquisition route |
| Head of Wholesale | Discount tiers and minimum order values | Wholesale profitability after freight |

Consequence of inaction: continued volume growth at declining margin; promotions and free shipping that destroy value become embedded customer expectations that are hard to reverse.

## 4. Business questions and analytical plan

Primary tables: `fact_orders`, `fact_order_items`, `fact_returns`, `fact_marketing_spend`, with `dim_date`, `dim_customer`, `dim_product`, `dim_channel`, `dim_geography`, `dim_promotion`. Type: = descriptive, G = diagnostic, F = forward-looking.

### Q1 (D/G). Where did the margin go between FY2024 and FY2025?
* Why: The Board's first question; every other analysis is judged against it.
* Metrics / dimensions: Net revenue, gross profit, contribution profit and their % of net revenue; cost lines as % of net revenue; by year (then quarter).
* Tables / fields: orders (shipping, fees, status), order items (price, discount, quantity, cost), returns (refund, restock, return shipping).
* Approach: Build the order-level P&L, reconcile to line level, compute a margin bridge (change in each cost line as % of net revenue), then look at timing (step vs. drift).
* Decision supported: Which of the cost lines to prioritise in FY2026 planning.

### Q2 (G). Is discounting still paying for itself?
* Why: Promotion count and depth grew; was the volume worth the margin?
* Metrics / dimensions: Promo order share, average discount depth, contribution margin by discount band; by channel, category, year; orders per day inside vs. outside promotions.
* Tables / fields: order items (`discount_pct`), orders (`promo_id`), promotions (type, dates, scope), date.
* Approach: Banded margin analysis, promo vs. non-promo comparison matched on month, awareness of seasonality and self-selection (deal-seeking customers).
* Decision supported: Promotion calendar, maximum depth by channel/category, which events to stop.

### Q3 (D/G). Which channels, categories and products earn their keep after all costs?
* Why: Growth came disproportionately from some channels; revenue ranking and profit ranking may differ.
* Metrics / dimensions: Revenue, contribution profit and margin by channel × category × product; share of revenue vs. share of profit.
* Approach: Line-level P&L with transparent allocation of shipping (by weight) and channel fees (by revenue); ranking with window functions; cost-vs-price index over time.
* Decision supported: Pricing action, supplier negotiation, range and channel participation decisions.

### Q4 (G). Is shipping eroding margin, and where?
* Why: Carrier rates rose and the company expanded to distant markets while free-shipping thresholds stayed unchanged.
* Metrics / dimensions: Shipping charged vs. shipping cost, free-shipping share, net shipping burden as % of merchandise revenue; by country, hub, basket-value band, year.
* Approach: Country and basket-band profile; identify where free-shipping orders lose money.
* Decision supported: Country-specific thresholds and flat fees, carrier negotiation priorities, minimum order values for far markets.

### Q5 (G). How costly are returns, and what drives them?
* Why: Refunds, return freight and unsold returned stock are a hidden cost.
* Metrics / dimensions: Unit return rate, refund rate, return shipping, unrecovered COGS; by category, channel, reason, discount level. Mature orders only (≥35 days old at extract).
* Approach: Rates by segment, reason mix, association with discounting; clear separation of correlation from causation.
* Decision supported: Size guides/product information, returns policy by channel, supplier quality escalation.

### Q6 (D/G/F). Which customers are worth acquiring, and do they come back?
* Why: Marketing spend rose faster than revenue; is the customer base getting better or worse?
* Metrics / dimensions: New customers, 90/180-day repeat rate, 12-month revenue and contribution per customer, RFM segments; by acquisition source and first-order channel; cohort month.
* Approach: Cohort and 12-month value analysis (full-window cohorts only), NTILE segmentation, caveats on survivorship and right-censoring.
* Decision supported: Acquisition-channel budgets, retention programmes, which first-purchase offers to keep.

### Q7 (D/G). Is marketing spend getting less efficient?
* Why: CFO sees marketing cost rising faster than revenue.
* Metrics / dimensions: Spend as % of net revenue, contribution per marketing dollar, profit after marketing; by channel × region × year.
* Approach: Aggregate efficiency analysis (spend cannot be tied to individual orders, so no true CAC), rolling windows to remove seasonality.
* Decision supported: Region/channel budget reallocation.

### Q8 (F). What is the FY2026 profit opportunity from the main levers?
* Why: The CFO needs sized, prioritised actions, not just diagnosis.
* Approach: Scenario sizing (e.g., higher free-shipping thresholds, capped Marketplace deal depth, repricing under-priced categories) with explicit assumptions, run as ranges (low / expected / upper bound) because customer response is unknown. Not a forecast.
* Decision supported: Which levers go into the FY2026 budget and in what order.

## 5. Success criteria for the analysis

1. A reconciled profit bridge FY2024→FY2025 that explains the margin movement by driver.
2. A ranked, quantified list of margin levers with stated assumptions and confidence.
3. Dashboards a non-technical executive can use in a 10-minute Board slot.
4. A clear statement of data-quality issues, how each was handled, and the effect on results.

## 6. Scope, assumptions and limitations (set expectations up front)

* Marketing spend is monthly by channel and region and cannot be linked to individual orders or customers.
* Operating overhead (salaries, rent) is not in the dataset; the profit measure is contribution profit, not net income.
* Customer response to price and promotion changes cannot be observed; scenario results are sizing exercises.
* Returns lag sales: late-2025 orders are not yet mature; return metrics must be read on mature orders.
* Customers who registered before 2023 (legacy) have prior purchase history that is not in the data.
