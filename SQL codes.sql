#Q1)
SELECT DISTINCT (market) FROM dim_customer WHERE customer = 'Atliq Exclusive' AND region = 'APAC';

#Q2)
with unique_products_2020 AS
(SELECT count(distinct(product_code)) AS unique_products_2020
FROM fact_sales_monthly WHERE fiscal_year=2020),

unique_products_2021 AS (SELECT count(distinct(product_code)) AS unique_products_2021
FROM fact_sales_monthly WHERE fiscal_year=2021)

SELECT unique_products_2020,
	   unique_products_2021,
       round((((unique_products_2021-unique_products_2020)/unique_products_2020)*100),2) AS percent_chg
FROM unique_products_2020
JOIN unique_products_2021;

#Q3)
SELECT segment, COUNT(DISTINCT(product_code)) AS product_count FROM dim_product
GROUP BY segment
ORDER BY product_count DESC;

#Q4)
WITH unique_2020 AS
(SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count_2020
FROM dim_product as p INNER JOIN fact_sales_monthly AS s
ON p.product_code=s.product_code
WHERE s.fiscal_year=2020
GROUP BY p.segment
ORDER BY product_count_2020 DESC
),

unique_2021 AS(SELECT p.segment, COUNT(DISTINCT(p.product_code)) AS product_count_2021
FROM dim_product AS p INNER JOIN fact_sales_monthly AS s
ON p.product_code=s.product_code
WHERE s.fiscal_year=2021
GROUP BY p.segment
ORDER BY product_count_2021 DESC)
SELECT a.segment, a.product_count_2020, b.product_count_2021, (b.product_count_2021-a.product_count_2020) as difference
FROM unique_2020 a JOIN unique_2021 b
on a.segment = b.segment;


#Q5)
SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m INNER JOIN dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MAX(manufacturing_cost) FROM fact_manufacturing_cost)
UNION
SELECT p.product_code, p.product, m.manufacturing_cost 
FROM fact_manufacturing_cost AS m INNer join dim_product AS p
ON m.product_code = p.product_code
WHERE m.manufacturing_cost = (SELECT MIN(manufacturing_cost) FROM fact_manufacturing_cost);

#Q6)
SELECT c.customer_code, c.customer, p.pre_invoice_discount_pct
FROM dim_customer as c INNER join fact_pre_invoice_deductions AS p
ON c.customer_code = p.customer_code
WHERE p.pre_invoice_discount_pct > (SELECT AVG(pre_invoice_discount_pct) FROM fact_pre_invoice_deductions) AND c.market='India' AND p.fiscal_year = 2021
ORDER BY p.pre_invoice_discount_pct DESC
LIMIT 5;

#Q7)
SELECT MONTH(s.date) AS month,
YEAR(s.date) AS year,
SUM(ROUND((s.sold_quantity*g.gross_price),2)) AS gross_sales_amount
FROM fact_sales_monthly AS s INNER JOIN fact_gross_price AS g
ON s.product_code=g.product_code
INNER JOIN dim_customer AS c
ON s.customer_code=c.customer_code
WHERE c.customer = 'atliq exclusive'
GROUP BY month, year
ORDER BY year;

#Q8)
SELECT
CASE
	WHEN MONTH(date) IN (9, 10, 11) THEN 'Qtr 1'
    WHEN MONTH(date) IN (12, 1, 2) THEN 'Qtr 2'
    WHEN MONTH(date) IN (3, 4, 5) THEN 'Qtr 3'
    WHEN MONTH(date) IN (6, 7, 8) THEN 'Qtr 4'
    END AS Quarter,
SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarter
ORDER BY total_sold_quantity DESC; 

#Q9)
WITH gross_sales_cte AS 
(
	SELECT c.channel,
	ROUND(SUM((s.sold_quantity * g.gross_price)/1000000),2) AS gross_sales_mln
	FROM fact_sales_monthly AS s
	INNER JOIN fact_gross_price AS g
	ON  s.product_code = g.product_code
	INNER JOIN dim_customer AS c
	ON s.customer_code = c.customer_code
	WHERE s.fiscal_year = 2021
	GROUP BY c.channel
	ORDER BY gross_sales_mln DESC
)
SELECT *, gross_sales_mln*100/SUM(gross_sales_mln) OVER() AS percent
FROM gross_sales_cte;

#Q10)
WITH division_sales_cte AS 
	(
    SELECT p.division, s.product_code,p.product, SUM(s.sold_quantity) AS 'total_sold_qty', 
	row_number() OVER (PARTITION BY p.division ORDER BY sum(s.sold_quantity) DESC) AS rank_order
	FROM fact_sales_monthly AS s 
	INNER JOIN dim_product AS p
	ON s.product_code = p.product_code
	WHERE s.fiscal_year = 2021
	GROUP BY p.division, s.product_code, p.product
    )
SELECT division, product_code, product, total_sold_qty, rank_order
FROM division_sales_cte
WHERE rank_order <= 3;