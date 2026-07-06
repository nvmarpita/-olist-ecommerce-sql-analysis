# From Orders to Insights: SQL Analysis of 100K+ Olist Transactions

 
## Project Overview:
The Brazilian E-commerce (Olist) dataset is a real-world transactional dataset published by Olist, one of Brazil’s largest online marketplaces. It contains over 100,000 orders from 2016–2018 across nine interconnected tables, including customers, orders, products, sellers, payments, reviews, and geolocation. This project uses the dataset to perform business analysis using advanced SQL techniques including window functions, CTEs, and conditional aggregation, and data analysis on a real-world    
e-commerce dataset.

## Dataset Source:
https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce


## Tools Used:

- MySQL
- MySQL Workbench


##    Entity Relationship Diagram (ERD)
<img width="1380" height="1160" alt="schema" src="https://github.com/user-attachments/assets/05c379b9-b357-4fcc-a31b-4423572815a4" />
                                                

## Business Questions(CATEGORISED BY THEMES):
### Sales Performance
- Q1. What is the total revenue per month, and how does it trend over time?
- Q2. Which product categories generate the highest revenue?
- Q3. What is the month-over-month revenue growth rate?
### Customer Behaviour
- Q4. What percentage of customers are repeat buyers vs one-time buyers?
- Q5. What payment methods do customers prefer, and does paying in installments correlate with higher order values?
- Q6. At what hour of the day do customers place the most orders?
- Q7. Which product category has the most inconsistent review scores (highest variability), and how does it compare to the overall average rating?
### Delivery & Operations
- Q8. Rank sellers by delivery consistency using STDDEV and DENSE_RANK together.
- Q9. For each month, what percentage of orders were delivered late, and how does that late delivery rate trend over time?
- Q10. For each product category, identify whether it is Rising, Declining, or Stable — based on comparing first half vs second half revenue performance.

## Key Findings:
**-Revenue peaked during Brazil's Black Friday season**
Revenue grew consistently throughout 2017, peaking in November 2017 reaching R$1,153,528. 
This peak likely reflects Brazil's Black Friday shopping season, which drives a significant 
surge in consumer spending across e-commerce platforms.

 |revenue	|months |
 |------  |---|
 |46567	 | 2016-10 |
  |20 | 2016-12|
|127546	 | 2017-01|
|271299 | 2017-02|
|414369 | 2017-03|
|390952	| 2017-04|
|567067	| 2017-05|
|490226 |	2017-06|
|566404|	2017-07|
|646001 |	2017-08|
|701170	|2017-09|
|751140	|2017-10|
|1153528	| 2017-11|
|843199 | 	2017-12|
|1078607| 	2018-01|
|966511	| 2018-02|
|1120678	| 2018-03|
|1132934	| 2018-04|
|1128837	| 2018-05|
|1012091	| 2018-06|
|1027904 | 2018-07|
|985414	|2018-08|

**Note:** 2016-10 and 2016-12 show unusually low revenue (R$46,567 and R$20) likely reflecting Olist's early platform launch period with minimal seller/order activity. Growth trends are more representative from 2017 onward.

 **-Retention rate in Olist e-commerce is critically low**
In Olist e-commerce, one-time customers account for 96.88% of all buyers, while repeat customers make up only 3.12%.

|customer_type| customer_count|percentage|
 |------     |   ----------  |---|
|one-time	    |   93099	      |96.88|
|repeat       |	2997	         |3.12|



 **-Olist experienced near-universal category growth during 2016–2018**
69 out of 71 product categories showed Rising revenue in the second half of 2016-2018, 
with bed_bath_table leading among Rising categories. Only 1 category Declined and 1 remained Stable ,suggesting strong platform-wide revenue growth during this period.

|product_category_name_english |first_half| second_half| revenue_change| classification|rank_within_class|
|------------------------------|----------|------------|---------------|---------------|-----------------|
|security_and_services| 209| 115| -94| Declining| 1|
|bed_bath_table| 156080| 1536634| 1380554| Rising| 1|
|health_beauty| 165555| 1455129| 1289574| Rising| 2|
|computers_accessories| 167489| 1381883| 1214394| Rising| 3|
tablets_printing_image|	5214|	4829|	-385	|Stable	|1|

**-Higher-value orders correlate with more payment installments** Orders with more installments tend to have higher average values — single-installment orders averaged R$ 112 while 10-installment orders averaged R$415.

|payment_installments| avg_order_value|
|--------------------|---------------|
|24	|610.05|
|23|	236.48|
|22	|228.71|
|21	|243.7|
|20	|615.8|
|18	|486.48|

## Data Schema

| Table | Why I used it |
|-------|---------------|
| customers | To find unique and repeat customers |
| orders_dataset | To get order status and delivery timestamps |
| order_items | To get product price and freight per order |
| order_payments | To get payment type and installment count |
| order_reviews | To get customer review scores |
| products_dataset | To get product category and size/weight |
| product_category_name_translation | To translate category names to English |
| sellers_dataset | To get seller delivery performance |


## SQL Techniques Used:
- Advanced CTEs
- Complex Joins
- Window functions(LAG(),DENSE_RANK())
- String/date manipulation for time-series grouping
- CASE WHEN statements
- Aggregate & statistical functions(STDDEV())
- Date functions (DATEDIFF(), SUBSTRING() for timestamp extraction)




