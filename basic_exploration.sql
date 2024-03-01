-- USE magist;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 1. How many order are in the dataset?
#    The table has 98922 rows (useing the "table inspector")
#    Tha table has 99441 rows (using COUNT)

SELECT
	COUNT(order_id)
FROM
	orders;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----     
# 2. Are orders actually delivered?
# There are 8 order states:
# Delivered, Unavailable, Shipped, Canceled, Invoiced, Processing, Approved, Created
# 97% Of orders are delivered

SELECT
	order_status,COUNT(order_id)
FROM
	orders
GROUP BY
	order_status;
    
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 3. Is Magist having user growth?
# No, the purchase-count is declining over the analyzed time.
# The decline is ca. -192 purchases per month.

SELECT
	COUNT(order_id), YEAR(order_purchase_timestamp) AS YY, MONTH(order_purchase_timestamp) AS MM
FROM
	orders
GROUP BY
	MM, YY
ORDER BY
	YY DESC, MM DESC;

# Alternative (bulky) solution with subqueries
-- SELECT
-- 	tstamp,COUNT(tstamp)
-- FROM(
-- 	SELECT
-- 		# order_id, CONCAT(YEAR(order_purchase_timestamp), "_", MONTH(order_purchase_timestamp)) AS tstamp
--         order_id, CONVERT(order_purchase_timestamp,DATE) AS tstamp
-- 	FROM
-- 		orders
-- ) AS test
-- GROUP BY
-- 	tstamp
-- ORDER BY
-- 	tstamp DESC;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 4. How many products are there on the products table?
# 32951

SELECT
	COUNT(product_id)
FROM
	products;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 5. Which are the categories with the most products?
# 1. "cama_Mesa_Banho", 2. "esporte_lazer", 3. "moveis_decoracao", 4. "beleza_saude", 5. "utilidades_domesticas"

SELECT
	product_category_name, COUNT(product_category_name) AS CNT
FROM
	products
GROUP BY
	product_category_name
ORDER BY
	CNT DESC
LIMIT
	5;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 6. How many of those products were present in actual transactions?
# TOTAL: 112.650
# 1. "cama_mesa_banho", 2. "beleza_saude", 3. "esporte_lazer", 4. "moveis_decoracao", 5. "informatica_acessorios"

SELECT
	product_category_name AS PCN, COUNT(product_category_name) AS CNT
--     COUNT(product_category_name)
FROM
	order_items
LEFT JOIN
	products
ON
	order_items.product_id = products.product_id
GROUP BY
	PCN
ORDER BY
	CNT DESC;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 7. What's the price for the most expensive and cheapest products?
# MAX: 6735,00 | utilidades_domesticas
# AVG:  120,02 
# MIN:    0,85 | construcao_ferramentas_construcao

SELECT
	*
FROM(
	SELECT
		price, product_category_name
	FROM
		order_items AS OI
	LEFT JOIN
		products AS PR
	ON
		OI.product_id = PR.product_id
	)AS test
ORDER BY
	price DESC;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# 8. What are the highest and lowest payment values?
# MAX: 13.664,10 | order_id: 03caa2c082116e1d31e67e9ae3700499
# MIN:      0,01 | order_id: ca4b9f3ce6fc19e8533501cf8c6b832e
# There are 6 orders with 0 pricing?!

SELECT
	payment_value AS PV, order_id
FROM
	order_payments
ORDER BY
	PV ASC;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X1: Time to delivery
# MAX: 209
# AVG: 12
# MIN: 0

SELECT
	AVG(delta)
FROM(
	SELECT
		TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delta, order_delivered_customer_date, order_purchase_timestamp
	FROM
		orders
	WHERE
		(order_status = "delivered") AND (order_delivered_customer_date IS NOT NULL)
	ORDER BY
		delta ASC
	) AS test;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X1b Delivery times and delays

SELECT
	TIMESTAMPDIFF(DAY, order_delivered_carrier_date, order_delivered_customer_date) AS delta, order_delivered_carrier_date, order_delivered_customer_date
FROM
	orders
ORDER BY
	delta DESC;

WITH ord AS
	(
	SELECT
		-- TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delta, order_delivered_customer_date, order_purchase_timestamp
        TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_carrier_date) AS delta, order_purchase_timestamp, order_delivered_carrier_date
	FROM
		orders
	WHERE
			(order_status = "delivered") AND (order_delivered_customer_date IS NOT NULL)
	ORDER BY
		delta ASC
	)
SELECT
	COUNT(delta) AS cnt, 100*COUNT(delta)/(SELECT COUNT(DELTA) FROM ord) AS percentage,
	CASE
		WHEN (delta <= 1) THEN "Express (<=1)"
		WHEN (delta > 1) AND(delta <= 3) THEN "Regular (<=3)"
		ELSE "Delayed (>3)"
    END AS delivery_time
FROM
	ord
GROUP BY
	delivery_time;
    

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X1b Delivery times and delays
SELECT
	TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_delivered_customer_date) AS delta, order_delivered_customer_date, order_purchase_timestamp
FROM
	orders
WHERE
		(order_status = "delivered") AND (order_delivered_customer_date IS NOT NULL)
ORDER BY
	delta ASC;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X2: Product categories
# 74 different categories
# 

SELECT
	DISTINCT product_category_name AS PN
FROM
	products;

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X2b: Product categories percentage

SELECT
	product_category_name AS PN, COUNT(DISTINCT product_id) AS cnt, 100*COUNT(DISTINCT product_id)/ (SELECT COUNT(product_category_name) FROM products)
FROM
	products
GROUP BY
	PN
HAVING
	PN IN ("audio", "eletronicos", "tablets_impressao_imagem", "telefonia")
ORDER BY
	cnt DESC;
    
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# X3: Product categories for high-end tech products (OFFERING)
# (Sent all 74 categories to ChatGPT and let it sort by "high-end tech product"
# telefonia					| Telephony					| 1134
# eletronicos				| Electronics				| 517
# consoles_games			| Console games				| 317
# telefonia_fixa			| Landline telephony		| 116
# audio						| Audio						| 58
# pcs						| PCs						| 30
# tablets_impressao_imagem	| Tablets, Printing, Image	| 9
# pc_gamer					| PC Games					| 3

SELECT
	product_category_name AS PN, COUNT(product_id) AS CNT
FROM
	products
GROUP BY
	PN
HAVING
	PN IN ("audio", "consoles_games", "eletronicos", "pcs", "pc_gamer", "tablets_impressao_imagem", "telefonia", "telefonia_fixa")
ORDER BY
	CNT DESC;
    
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- ----- 
# Customer reviews
# Score:
# MAX: 5
# AVG: 4.0757
# MIN: 1

SELECT
	MAX(review_score)
FROM
	order_reviews;
    
SELECT
	COUNT(review_score) AS Score,
    100*COUNT(review_score)/( SELECT COUNT(review_score) FROM order_reviews) AS Percentage,
	CASE
		WHEN review_score >= 4 THEN "Satisfied"
        WHEN review_score = 3 THEN "Neutral"
        ELSE "Not recommended"
	END AS "satisfaction"
FROM
	order_reviews
GROUP BY
	satisfaction;
        

-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----
# How many of these tech catg. have been sold?
# telefonia			4545
# electronicos		2767
# tablets			  83
# audio:			 364
# total:			7759

SELECT
	100*7759/COUNT(*)
FROM
	ORDER_ITEMS;

SELECT
	*
FROM(
	SELECT
		100*COUNT(order_id)/(SELECT COUNT(*) FROM order_items) AS CNT, product_category_name AS PN
	FROM
		order_items AS tabA
	LEFT JOIN
		products AS tabB
	ON
		tabA.product_id = tabB.product_id
	GROUP BY
		PN
	HAVING
		PN IN ("audio", "eletronicos", "tablets_impressao_imagem", "telefonia")
	) AS preselect;
    
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----
# Avg. price of these products

SELECT
	COUNT(price) AS PR, product_category_name AS PN
FROM
	order_items AS tabA
LEFT JOINsellers
	products AS tabB
ON
	tabA.product_id = tabB.product_id
GROUP BY
	PN
HAVING
	PN IN ("audio", "eletronicos", "tablets_impressao_imagem", "telefonia");
-- ORDER BY
-- 	PR DESC;


-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----
# How many months of the data are in the database?

SELECT
	CONVERT(order_purchase_timestamp,DATE) AS t
FROM
	orders
ORDER BY
	t;


-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----
# How many sellers are there?
# There are 3095 sellers total

SELECT
	COUNT(DISTINCT seller_id)
FROM
	sellers;
    
-- ----- ----- ----- ----- ----- ----- ----- ----- ----- ---- ----- ----- ----- ----- -----
# How many TECH sellers are there?

CREATE TEMPORARY TABLE sellers_overview
	SELECT
		tabS.seller_id,
		tabP.product_category_name AS PN,
		COUNT(tabP.product_category_name) AS prodcount
	FROM
		sellers AS tabS
	LEFT JOIN
		order_items AS tabO
	ON
		tabS.seller_id = tabO.seller_id
	LEFT JOIN
		products as tabP
	ON
		tabO.product_id = tabP.product_id
	GROUP BY
		tabS.seller_id,
		tabP.product_category_name
	ORDER BY
		tabS.seller_id,
		tabP.product_category_name;

SELECT
	PN, COUNT(seller_id) AS CNT, 100*COUNT(seller_id)/( SELECT COUNT(seller_id) FROM sellers )
FROM
	sellers_overview
GROUP BY
	PN
ORDER BY
	CNT DESC
LIMIT
	5;