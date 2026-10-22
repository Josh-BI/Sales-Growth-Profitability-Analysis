# KPI Definitions

# Global filters and rules
* Revenue-generating order = `order_status <> 'Cancelled'` (Delivered, Shipped, Processing). Cancelled orders are excluded from every financial KPI.
* Attribution: returns, refunds, restocked cost and return freight are attributed to the original order date.
* Maturity: an order is mature when `order_date <= 2025-11-30` (≥ 35 days before the 2026-01-05 extract). Return-based KPIs for periods that include immature orders are provisional.
* Period comparisons: compare only complete periods (full years/quarters/months). Never compare a partial period to a full one.
* Aggregation level: order-level amounts (shipping, fees) live in `fact_orders` and are never summed from line level without allocation.
* Zero denominators: every ratio returns NULL/BLANK, not 0 or an error, when the denominator is 0.

| KPI | Definition | Numerator / formula | Denominator | SQL source | Notes |
|---|---|---|---|---|---|
| Gross Merchandise Revenue | Sales at list price before discounts | Σ `quantity × unit_list_price_usd` | – | `vw_order_pnl.gross_merch_revenue` | |
| Discount Amount | Value given away | Gross − Net Merchandise Revenue | – | `discount_amount` | |
| Discount Rate | Depth of discounting | Discount Amount | Gross Merchandise Revenue | | |
| Net Merchandise Revenue | Product sales after discounts, before returns | Σ `line_net_revenue_usd` | – | `net_merch_revenue` | |
| Shipping Revenue | Shipping paid by customers | Σ `shipping_charged_usd` | – | `shipping_revenue` | |
| Refunds | Money returned to customers | Σ `refund_amount_usd` | – | `refunds` | Order-date attribution |
| Net Revenue | Revenue retained | Net Merch Revenue + Shipping Revenue − Refunds | – | `net_revenue` | Denominator for all margin % |
| COGS | Product cost of items sold | Σ `quantity × unit_cost_usd` | – | `cogs` | Cost at date of sale |
| COGS Recovered | Cost of returned items put back into stock | Σ `return_quantity × unit_cost × restocked_flag` | – | `cogs_recovered` | |
| Net COGS | COGS − COGS Recovered | | | `net_cogs` | |
| Shipping Cost | Outbound carrier cost | Σ `shipping_cost_usd` | – | `shipping_cost` | |
| Net Shipping Burden % | Shipping cost not recovered from customers | Shipping Cost − Shipping Revenue | Net Merchandise Revenue | | Positive = TrailForge subsidises shipping |
| Return Shipping Cost | Return freight paid by TrailForge | Σ `return_shipping_cost_usd` | – | `return_shipping_cost` | |
| Channel Fees | Marketplace commission / payment processing | Σ `channel_fee_usd` | – | `channel_fees` | |
| Contribution Profit | Profit after all order-driven costs, before marketing and overhead | Gross Profit − Shipping Cost − Return Shipping − Channel Fees | – | `contribution_profit` | Not net income |
| Contribution Margin % | | Contribution Profit | Net Revenue | | |
| Marketing Spend | | Σ `spend_usd` | – | `fact_marketing_spend` | Not attributable to orders |
| Profit After Marketing | | Contribution Profit − Marketing Spend | – | `vw_monthly_channel_region_pnl` | Wholesale carries no marketing spend |
| Profit After Marketing % | | Profit After Marketing | Net Revenue | | |
| Orders | Distinct revenue-generating orders | COUNT DISTINCT `order_id` | – | | |
| Average Order Value (AOV) | | Net Merchandise Revenue | Orders | | Report consumer and wholesale separately: wholesale baskets are far larger |
| Units Sold / Returned | | Σ `quantity` / Σ `return_quantity` | – | | |
| Unit Return Rate | | Units Returned | Units Sold (mature orders) | | |
| Promo Order Share | | Orders with `promo_id` not NULL | Orders (non-Wholesale) | | |
| Free Shipping Share | | Orders with `shipping_charged_usd = 0` | Orders (non-Wholesale) | | |
| Active Customers | Distinct customers with ≥ 1 revenue-generating order in the period | | | | Merge duplicate customers first |
| Repeat Rate (90/180-day) | Share of a first-order cohort ordering again within N days | Customers with 2nd order ≤ N days after 1st | Cohort customers | | Only cohorts with a full N-day window; consumers who registered in 2023 or later |
| 12-month Customer Contribution | Contribution profit from a customer's first 12 months | Σ contribution (first 12 months) | Customers | | First order ≤ 2024-12-31 only |