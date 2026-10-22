/*===========================================================
                  KPIs And Reporting Views
============================================================*/

/*------------------------------------------------------------
                    rpt.vw_order_pnl 
------------------------------------------------------------*/
USE TrailForgeAnalytics
GO
CREATE OR ALTER VIEW rpt.vw_order_pnl AS
WITH li AS (
  SELECT i.order_id,
         SUM(i.quantity * i.unit_list_price_usd) AS gross_merch_revenue,
         SUM(i.line_net_revenue_usd) AS net_merch_revenue,
         SUM(i.quantity * i.unit_cost_usd) AS cogs,
         SUM(i.quantity) AS units_sold,
         COUNT(*) AS line_count
  FROM clean.fact_order_items i GROUP BY i.order_id),

rt AS (
  
  SELECT i.order_id,
         SUM(r.refund_amount_usd) AS refunds,
         SUM(r.return_quantity * i.unit_cost_usd * CAST(r.restocked_flag AS int)) AS cogs_recovered,
         SUM(r.return_shipping_cost_usd) AS return_shipping_cost,
         SUM(r.return_quantity) AS units_returned
  FROM clean.fact_returns r JOIN clean.fact_order_items i ON i.order_item_id = r.order_item_id GROUP BY i.order_id
  )

SELECT o.order_id, o.customer_id, o.order_date, YEAR(o.order_date) AS order_year, 
       DATEFROMPARTS(YEAR(o.order_date), MONTH(o.order_date), 1) AS order_month,
       o.channel_id, ch.channel_name, o.ship_geography_id, g.country AS ship_country, g.region AS ship_region, g.fulfilment_hub, o.promo_id,
       CASE WHEN o.promo_id IS NOT NULL THEN 1 ELSE 0 END AS is_promo_order,
       o.order_status,
       CASE WHEN o.order_date <= '2025-11-30' THEN 1 ELSE 0 END AS is_mature_order,
       li.units_sold, li.line_count,
       li.gross_merch_revenue, li.net_merch_revenue,
       li.gross_merch_revenue - li.net_merch_revenue AS discount_amount,
       o.shipping_charged_usd  AS shipping_revenue,
       COALESCE(rt.refunds, 0) AS refunds,
       li.net_merch_revenue + o.shipping_charged_usd - COALESCE(rt.refunds, 0) AS net_revenue,
       li.cogs, COALESCE(rt.cogs_recovered, 0) AS cogs_recovered, li.cogs - COALESCE(rt.cogs_recovered, 0) AS net_cogs,
       li.net_merch_revenue + o.shipping_charged_usd - COALESCE(rt.refunds, 0) - (li.cogs - COALESCE(rt.cogs_recovered, 0)) AS gross_profit,
       o.shipping_cost_usd AS shipping_cost,
       COALESCE(rt.return_shipping_cost, 0) AS return_shipping_cost,
       o.channel_fee_usd AS channel_fees,
       li.net_merch_revenue + o.shipping_charged_usd - COALESCE(rt.refunds, 0) - (li.cogs - COALESCE(rt.cogs_recovered, 0))
         - o.shipping_cost_usd - COALESCE(rt.return_shipping_cost, 0) - o.channel_fee_usd AS contribution_profit,
       COALESCE(rt.units_returned, 0) AS units_returned
FROM clean.fact_orders o
JOIN li ON li.order_id = o.order_id
LEFT JOIN rt ON rt.order_id = o.order_id
JOIN clean.dim_channel ch ON ch.channel_id = o.channel_id
JOIN dbo.dim_geography g ON g.geography_id = o.ship_geography_id
WHERE o.order_status <> 'Cancelled' AND order_date < '2026-01-01'


/*-------------------------------------------------------
               rpt.vw_line_pnl
-------------------------------------------------------*/
GO
CREATE OR ALTER VIEW rpt.vw_line_pnl AS
WITH w AS (
  SELECT i.order_item_id, i.order_id, i.product_id, i.quantity, i.unit_list_price_usd,
         i.discount_pct, i.unit_cost_usd, i.line_net_revenue_usd,
         i.quantity * COALESCE(p.weight_kg, 0.5) AS line_weight,   
         SUM(i.quantity * COALESCE(p.weight_kg, 0.5)) OVER (PARTITION BY i.order_id) AS order_weight,
         SUM(i.line_net_revenue_usd) OVER (PARTITION BY i.order_id) AS order_merch
  FROM clean.fact_order_items i
  JOIN clean.dim_product p ON p.product_id = i.product_id),

rt AS (SELECT order_item_id,
              SUM(refund_amount_usd) AS refunds,
              SUM(return_quantity) AS units_returned,
              SUM(return_shipping_cost_usd) AS return_shipping_cost 
        FROM clean.fact_returns 
        GROUP BY order_item_id),

rc AS (SELECT r.order_item_id, 
       SUM(r.return_quantity * i.unit_cost_usd * CAST(r.restocked_flag AS int)) AS cogs_recovered
       FROM clean.fact_returns r
       JOIN clean.fact_order_items i ON i.order_item_id = r.order_item_id 
       GROUP BY r.order_item_id)

SELECT w.order_item_id, w.order_id, op.order_date, op.order_year, op.order_month, op.channel_id, op.channel_name, op.ship_country, op.ship_region, op.is_promo_order,
       p.product_id, p.product_name, p.category, p.subcategory, p.brand,
       w.quantity, w.discount_pct, w.quantity * w.unit_list_price_usd AS gross_revenue, w.line_net_revenue_usd AS net_merch_revenue,
       w.quantity * w.unit_cost_usd AS cogs, 
       COALESCE(rt.refunds, 0) AS refunds, COALESCE(rc.cogs_recovered, 0) AS cogs_recovered,
       CAST(op.shipping_cost  * w.line_weight / NULLIF(w.order_weight, 0) AS decimal(12,4)) AS allocated_shipping_cost,
       CAST(op.channel_fees   * w.line_net_revenue_usd / NULLIF(w.order_merch, 0) AS decimal(12,4)) AS allocated_channel_fees,
       CAST(op.shipping_revenue * w.line_net_revenue_usd / NULLIF(w.order_merch, 0) AS decimal(12,4)) AS allocated_shipping_revenue,
       COALESCE(rt.return_shipping_cost, 0) AS return_shipping_cost, COALESCE(rt.units_returned, 0) AS units_returned,
        w.line_net_revenue_usd
         + CAST(op.shipping_revenue * w.line_net_revenue_usd / NULLIF(w.order_merch, 0) AS decimal(12,4))
         - COALESCE(rt.refunds, 0) - (w.quantity * w.unit_cost_usd - COALESCE(rc.cogs_recovered, 0))
         - CAST(op.shipping_cost * w.line_weight / NULLIF(w.order_weight, 0) AS decimal(12,4))
         - CAST(op.channel_fees * w.line_net_revenue_usd / NULLIF(w.order_merch, 0) AS decimal(12,4))
         - COALESCE(rt.return_shipping_cost, 0) AS line_contribution
FROM w
JOIN rpt.vw_order_pnl op ON op.order_id = w.order_id
JOIN clean.dim_product p ON p.product_id = w.product_id
LEFT JOIN rt ON rt.order_item_id = w.order_item_id
LEFT JOIN rc ON rc.order_item_id = w.order_item_id
WHERE order_date < '2026-01-01'


/*-------------------------------------------------------
            rpt.vw_monthly_channel_region_pnl
-------------------------------------------------------*/
GO
CREATE OR ALTER VIEW rpt.vw_monthly_channel_region_pnl AS
WITH s AS (SELECT order_month AS month_start, channel_id, ship_region AS region,
                  COUNT(*) AS orders, SUM(net_merch_revenue) AS net_merch_revenue,
                  SUM(net_revenue) AS net_revenue, SUM(gross_profit) AS gross_profit,
                  SUM(contribution_profit) AS contribution_profit
           FROM rpt.vw_order_pnl 
           GROUP BY order_month, channel_id, ship_region),

m AS (SELECT month_start_date AS month_start, channel_id, region, SUM(spend_usd) AS marketing_spend
      FROM clean.fact_marketing_spend GROUP BY month_start_date, channel_id, region)

SELECT COALESCE(s.month_start, m.month_start) AS month_start,
       COALESCE(s.channel_id, m.channel_id) AS channel_id,
       COALESCE(s.region, m.region) AS region,
       COALESCE(s.orders, 0) AS orders,
       COALESCE(s.net_merch_revenue, 0) AS net_merch_revenue, 
       COALESCE(s.net_revenue, 0) AS net_revenue,
       COALESCE(s.gross_profit, 0) AS gross_profit,
       COALESCE(s.contribution_profit, 0) AS contribution_profit,
       COALESCE(m.marketing_spend, 0) AS marketing_spend,
       COALESCE(s.contribution_profit, 0) - COALESCE(m.marketing_spend, 0) AS profit_after_marketing
FROM s 
FULL JOIN m
ON m.month_start = s.month_start AND m.channel_id = s.channel_id AND m.region = s.region