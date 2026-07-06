-- Q1. What is the total revenue per month, and how does it trend over time?
SELECT 
    ROUND(SUM(payment_value), 0) AS revenue,
    SUBSTRING(od.order_purchase_timestamp,
        1,
        7) AS months
FROM
    orders_dataset od
        JOIN
    order_payments op ON od.order_id = op.order_id
WHERE
    od.order_status = "delivered"
GROUP BY months
ORDER BY months ASC;
-- Conclusions:---- Trend: Revenue grew steadily throughout 2017, peaking in Nov 2017,
-- 2018 maintained similarly high levels.

-- Q2. Which product categories generate the highest revenue?
WITH order_revenue AS (
    SELECT 
        ot.product_id,
        SUM(op.payment_value) AS revenue
    FROM order_payments op
    JOIN orders_dataset od ON op.order_id = od.order_id
    JOIN order_items ot ON od.order_id = ot.order_id
    WHERE od.order_status = 'delivered'
    GROUP BY ot.product_id
)
SELECT 
    pct.product_category_name_english,
    ROUND(SUM(r.revenue), 0) AS highest_revenue
FROM order_revenue r
JOIN products_dataset pd ON r.product_id = pd.product_id
JOIN product_category_name_translation pct 
    ON pd.product_category_name = pct.product_category_name
GROUP BY pct.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;
-- Q3- What is the month-over-month revenue growth rate?
WITH cte AS(
SELECT
SUBSTRING(order_purchase_timestamp,1,7) AS MONTHS,
ROUND(SUM(ot.price),0)AS sales
FROM  orders_dataset od
JOIN order_items ot
ON od.order_id = ot.order_id
WHERE od.order_status = "delivered"
GROUP BY  MONTHS)
SELECT
 MONTHS,
 sales,
LAG(sales) OVER(ORDER BY MONTHS) AS prev_month_sales,
ROUND((sales - LAG(sales) OVER (ORDER BY MONTHS)) / LAG(sales) OVER (ORDER BY MONTHS) * 100, 0) AS MoM
FROM cte
ORDER BY MONTHS;
-- Conclusions: MoM growth was high and volatile in early 2017.

-- Q4- What percentage of customers are repeat buyers vs one-time buyers?
WITH CTE AS(
SELECT 
c.customer_unique_id,
COUNT(od.order_id) AS total
FROM orders_dataset od
JOIN customers c
ON od.customer_id = c.customer_id
GROUP BY customer_unique_id)
SELECT
    CASE WHEN total > 1 THEN 'repeat' ELSE 'one-time' END AS customer_type,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100 / (SELECT COUNT(*) FROM cte), 2) AS percentage
FROM cte
GROUP BY customer_type;
-- Conclusions: one time buyer are significantly higher than repeat buyers.

-- Q5. What payment methods do customers prefer, and does paying in installments correlate with 
-- higher order values?
SELECT payment_type,
 COUNT(order_id) AS order_count
FROM order_payments
GROUP BY payment_type
ORDER BY order_count DESC;
SELECT payment_installments, ROUND(AVG(payment_value),2) AS avg_order_value
FROM order_payments
WHERE payment_installments > 0
GROUP BY payment_installments
ORDER BY payment_installments ASC;
-- Conclusions:Credit card is the dominant payment method (73% of orders). Higher installment counts correlate with higher average order values,
-- suggesting customers use installments for expensive purchases.

-- Q6. At what hour of the day do customers place the most orders?
SELECT 
HOUR (order_purchase_timestamp) AS hour_of_most_orders,
COUNT(*) AS order_count
FROM orders_dataset
WHERE order_status = "delivered"
GROUP BY  hour_of_most_orders
ORDER BY order_count DESC;
-- Conclusion: Order volume is shaped by average human daily routine most orders occur during day 
-- hours, while night hours see significantly fewer orders.

-- Q7. Which product category has the most inconsistent review scores?
SELECT
    pct.product_category_name_english,
    ROUND(AVG(ors.review_score), 2) AS avg_review,
    ROUND(STDDEV(ors.review_score), 2) AS review_stddev
FROM products_dataset pd
JOIN product_category_name_translation pct
    ON pct.product_category_name = pd.product_category_name
JOIN order_items ot ON ot.product_id = pd.product_id
JOIN order_reviews ors
    ON ot.order_id = ors.order_id COLLATE utf8mb4_0900_ai_ci
WHERE ors.review_score IS NOT NULL
GROUP BY pct.product_category_name_english
ORDER BY review_stddev DESC
LIMIT 10;
--   Conclusion: High STDDEV = customers strongly disagree on quality,
-- Low STDDEV = consistent customer experience across the category.

-- Q8. For each seller, calculate their average delivery time and delivery time variability (STDDEV).
-- Then rank them from most consistent to least consistent. Only include sellers with more than 50 orders.

WITH cte AS (
SELECT
sd.seller_id,
ROUND(AVG(DATEDIFF( od.order_delivered_customer_date, od.order_purchase_timestamp)),2) AS average_time,
ROUND(STDDEV(DATEDIFF(od.order_delivered_customer_date,od.order_purchase_timestamp)),2) AS stdv
FROM sellers_dataset sd
JOIN order_items ot
ON sd.seller_id = ot.seller_id
JOIN orders_dataset od
ON ot.order_id = od.order_id
GROUP BY sd.seller_id
 HAVING COUNT(ot.order_id) > 50) 
SELECT
seller_id,
average_time,
stdv,
DENSE_RANK() OVER(ORDER BY stdv ASC) AS consistency_rank
FROM cte;
-- Conclusion:-
-- Sellers ranked by delivery consistency.
-- Only sellers with 50+ orders included for statistical reliability.
-- Rank 1 = most consistent delivery time (lowest variability).
-- High STDDEV sellers indicate unpredictable delivery — a risk to customer experience.

-- Q9. For each month, what percentage of orders were delivered late, and how does that late delivery
-- rate trend over time?

WITH cte AS
 (SELECT
 order_id,
 order_estimated_delivery_date,
 order_delivered_customer_date,
SUBSTRING(order_delivered_customer_date,1,7) AS MONTHS
FROM orders_dataset
WHERE order_status = "delivered"
AND  order_delivered_customer_date IS NOT NULL),
monthly_late AS 
(SELECT
MONTHS,
ROUND(SUM(CASE WHEN order_delivered_customer_date > order_estimated_delivery_date
THEN 1
ELSE
0
END)/COUNT(*)*100,2) AS late_delivery_pct 
FROM cte
GROUP BY MONTHS
)
SELECT
    MONTHS,
    late_delivery_pct,
    LAG(late_delivery_pct) OVER (ORDER BY MONTHS) AS prev_month_pct,
    ROUND(late_delivery_pct - LAG(late_delivery_pct) OVER (ORDER BY MONTHS), 2) AS mom_change
FROM monthly_late
ORDER BY MONTHS ASC;
-- Conclusion:
--  Monthly late delivery rate with month-over-month change.
-- Late = order_delivered_customer_date > order_estimated_delivery_date.
-- Late delivery rates were generally below 15% through 2017-2018.

-- Q10. For each product category, identify whether it is a 'Rising', 'Declining', or 'Stable'
--  revenue category — based on comparing its first half vs second half performance across the 
-- dataset's time period. Also show total revenue and rank categories within each classification.

-- SET SESSION wait_timeout = 300;
-- SET SESSION interactive_timeout = 300;
WITH product_revenue AS (
 SELECT 
 ot.product_id,
SUM(CASE WHEN SUBSTRING(od.order_purchase_timestamp,1,7) < '2017-06' 
THEN op.payment_value ELSE 0 END) AS first_half,
 SUM(CASE WHEN SUBSTRING(od.order_purchase_timestamp,1,7) >= '2017-06' 
THEN op.payment_value ELSE 0 END) AS second_half
 FROM order_payments op
 JOIN orders_dataset od ON op.order_id = od.order_id
JOIN order_items ot ON od.order_id = ot.order_id
 WHERE od.order_status = "delivered"
GROUP BY ot.product_id
),
category_revenue AS (
    SELECT 
        pct.product_category_name_english,
        SUM(pr.first_half) AS first_half,
        SUM(pr.second_half) AS second_half
    FROM product_revenue pr
    JOIN products_dataset pd ON pr.product_id = pd.product_id
    JOIN product_category_name_translation pct 
        ON pd.product_category_name = pct.product_category_name
    GROUP BY pct.product_category_name_english)
SELECT
    product_category_name_english,
    ROUND(first_half, 0) AS first_half,
    ROUND(second_half, 0) AS second_half,
    ROUND(second_half - first_half, 0) AS revenue_change,
    CASE WHEN second_half > first_half * 1.1 THEN 'Rising'
WHEN second_half < first_half * 0.9 THEN 'Declining'
ELSE 'Stable'
    END AS classification,
    DENSE_RANK() OVER (
        PARTITION BY 
  CASE WHEN second_half > first_half * 1.1 THEN 'Rising'
   WHEN second_half < first_half * 0.9 THEN 'Declining'
 ELSE 'Stable'
END 
 ORDER BY second_half + first_half DESC) AS rank_within_class
FROM category_revenue
ORDER BY classification, rank_within_class;

-- Conclusion: Categories classified as Rising, Declining, or Stable based on  first half vs second half revenue comparison (split at 2017-06).
-- 10% threshold used: >10% growth = Rising, >10% decline = Declining, else Stable.
