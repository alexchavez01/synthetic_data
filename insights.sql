WITH cat AS (
  SELECT category,
         COUNT(*) AS orders, 
         ROUND(SUM(total_price), 2) as revenue,
         ROUND(AVG(total_price), 2)  as avg_price
  FROM `upheld-terminus-471904-k3.sql_practice.cleaned_data_merge` 
  GROUP BY category
)
SELECT category, orders, revenue, avg_price, 
       ROUND(100 * revenue / SUM(revenue) OVER (), 2) AS revenue_share_pct
 FROM cat
 ORDER BY revenue DESC




