/*DATA CLEANING*/
SELECT * FROM web_events
WHERE id IS NULL OR
	 account_id IS NULL OR
	 channel IS NULL 

SELECT * FROM accounts
WHERE id IS NULL OR
	  name IS NULL OR
	  website IS NULL OR
	  lat IS NULL OR
	  long IS NULL OR
	  primary_poc IS NULL OR
	  sales_rep_id IS NULL

SELECT * FROM orders
WHERE id IS NULL OR
	  account_id IS NULL OR
	  occurred_at IS NULL OR
	  standard_qty IS NULL OR
	  gloss_qty IS NULL OR
	  poster_qty IS NULL OR
	  total IS NULL OR
	  standard_amt_usd IS NULL OR
	  gloss_amt_usd IS NULL OR
	  poster_amt_usd IS NULL OR
	  total_amt_usd IS NULL OR
	  total IS NULL 

SELECT * FROM sales_reps
WHERE id IS NULL OR
	 name IS NULL OR
	 region_id IS NULL
	 
SELECT * FROM region
WHERE id IS NULL OR
	 name IS NULL

ALTER TABLE web_events
ADD occurred_date  DATE
UPDATE web_events
SET occurred_date = LEFT(occurred_at,10)
ALTER TABLE web_events
ADD occurred_time TIME
UPDATE web_events
SET occurred_time = RIGHT(occurred_at,8)
UPDATE web_events
SET occurred_at = CONCAT(occurred_date,' ', occurred_time)
SELECT * FROM web_events


ALTER TABLE orders ADD occurred_date  DATE 
UPDATE orders SET occurred_date = LEFT(occurred_at,10) 
ALTER TABLE orders ADD occurred_time TIME 
UPDATE orders SET occurred_time = RIGHT(occurred_at,8) 
UPDATE orders SET occurred_at = CONCAT(occurred_date,' ', occurred_time) 
SELECT id, occurred_at, occurred_date, occurred_time FROM orders

CREATE TABLE sales_reps2 (
id int,
name NVARCHAR(50),
region_id  int,
first_name NVARCHAR(50),
last_name NVARCHAR(50)
)

INSERT INTO sales_reps2 (sales_reps.id,sales_reps.name,sales_reps.region_id,name_split.first_name, name_split.last_name)
SELECT sales_reps.id,sales_reps.name,sales_reps.region_id,name_split.first_name, name_split.last_name
FROM
(SELECT sales_reps.id AS id,sales_reps.name,LEN(sales_reps.name) AS str_len,t2.split,SUBSTRING(t2.name, 1, t2.split) AS first_name, SUBSTRING(t2.name, t2.split+1, LEN(sales_reps.name)) AS last_name
FROM (
SELECT sales_reps.id,sales_reps.name,t1.new_name,PATINDEX('%[ABCDEFGHIJKLMNOPQRSTUVWXYZ]%'
, t1.new_name COLLATE SQL_Latin1_General_Cp1_CS_AS) AS split
FROM (
SELECT  sales_reps.id,SUBSTRING(sales_reps.name, 2, LEN(sales_reps.name)) AS new_name FROM sales_reps)t1 JOIN sales_reps ON t1.id = sales_reps.id)t2 JOIN sales_reps ON t2.id = sales_reps.id
)name_split JOIN sales_reps  ON name_split.id=sales_reps.id 

DROP TABLE sales_reps
EXEC sp_rename 'sales_reps2', 'sales_reps'
SELECT * FROM sales_reps
/********************************************************/

/*Getting to know the data*/

SELECT MIN(occurred_date) as StartDate, MAX(occurred_date) as LatestDate 
FROM web_events

SELECT MIN(occurred_date) as StartDate, MAX(occurred_date) as LatestDate 
FROM orders

SELECT COUNT(id) AS NumberOfSalesRep 
FROM sales_reps

SELECT COUNT(id) AS NumberOfCompanies 
FROM accounts

SELECT name 
FROM region

SELECT DISTINCT channel 
FROM web_events

SELECT COUNT(id) 
FROM orders

SELECT COUNT(id) 
FROM web_events

SELECT ROUND(SUM(total_amt_usd),2) AS Total_Revenue 
FROM orders
/********************************************************/

/*Product Pricing and Sales Analysis*/

/*Unit price of each paper type */
SELECT ROUND(SUM(orders.standard_amt_usd)/SUM(orders.standard_qty),2) AS standard_unit_price, ROUND(SUM(orders.gloss_amt_usd)/SUM(orders.gloss_qty),2) AS gloss_unit_price,ROUND(SUM(orders.poster_amt_usd)/SUM(orders.poster_qty),2) AS poster_unit_price
FROM orders

/*Top-Selling Products*/
SELECT SUM(standard_qty) AS standard_paper, SUM(gloss_qty) AS gloss_paper, SUM(poster_qty) AS poster_paper
FROM orders
UNION
SELECT ROUND(CAST(CAST(SUM(standard_qty) AS FLOAT)/CAST(SUM(total) AS FLOAT)*100.0 AS FLOAT),1) AS standard_paper_perc, 
ROUND(CAST(CAST(SUM(gloss_qty) AS FLOAT)/CAST(SUM(total) AS FLOAT)*100.0 AS FLOAT),1) AS gloss_paper_perc, 
ROUND(CAST(CAST(SUM(poster_qty) AS FLOAT)/CAST(SUM(total) AS FLOAT)*100.0 AS FLOAT),1)  AS poster_paper_perc
FROM orders
ORDER BY 1 DESC

/*Revenue Distribution*/
SELECT ROUND(SUM(standard_amt_usd),2) AS standard_paper, ROUND(SUM(gloss_amt_usd),2) AS gloss_paper, ROUND(SUM(poster_amt_usd),2) AS poster_paper
FROM orders
UNION
SELECT ROUND(CAST(CAST(SUM(standard_amt_usd) AS FLOAT)/CAST(SUM(total_amt_usd) AS FLOAT)*100.0 AS FLOAT),1) AS standard_paper_perc, 
ROUND(CAST(CAST(SUM(gloss_amt_usd) AS FLOAT)/CAST(SUM(total_amt_usd) AS FLOAT)*100.0 AS FLOAT),1) AS gloss_paper_perc, 
ROUND(CAST(CAST(SUM(poster_amt_usd) AS FLOAT)/CAST(SUM(total_amt_usd) AS FLOAT)*100.0 AS FLOAT),1)  AS poster_paper_perc
FROM orders
ORDER BY 1 DESC

/*Statistics Summary*/

/*Orders Stat summary*/
WITH std AS (SELECT AVG(t1.qty) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.standard_qty) AS row_num, orders.standard_qty AS qty
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
gloss AS (SELECT AVG(t1.qty) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.gloss_qty) AS row_num, orders.gloss_qty AS qty
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
poster AS (SELECT AVG(t1.qty) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.poster_qty) AS row_num, orders.poster_qty AS qty
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
total AS (SELECT AVG(t1.qty) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.total) AS row_num, orders.total AS qty
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457)

SELECT '1. Average' AS Stat,AVG(orders.standard_qty) AS Standard_Paper,AVG(orders.gloss_qty) AS Gloss_Paper,AVG(orders.poster_qty) AS Poster_Paper, AVG(orders.total) AS Total_Orders
FROM orders
UNION 
SELECT '2. Median' AS stat, std.median AS Standard_Paper, gloss.median AS  Gloss_Paper, poster.median AS Poster_Paper, total.median AS Total_Orders
FROM std, gloss, poster, total
UNION
SELECT '3. Minimum' AS stat ,MIN(orders.standard_qty) AS Standard_Paper,MIN(orders.gloss_qty) AS Gloss_Paper,MIN(orders.poster_qty) AS Poster_Paper, MIN(orders.total) AS Total_Orders
FROM orders
UNION
SELECT '4. Maximum' AS stat ,MAX(orders.standard_qty) AS Standard_Paper,MAX(orders.gloss_qty) AS Gloss_Paper,MAX(orders.poster_qty) AS Poster_Paper, MAX(orders.total) AS Total_Orders
FROM orders

/*Revenue Stat Summary*/
WITH std AS (SELECT AVG(t1.amt) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.standard_amt_usd) AS row_num, orders.standard_amt_usd AS amt
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
gloss AS (SELECT AVG(t1.amt) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.gloss_amt_usd) AS row_num, orders.gloss_amt_usd AS amt
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
poster AS (SELECT AVG(t1.amt) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.poster_amt_usd) AS row_num, orders.poster_amt_usd AS amt
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457),
total AS (SELECT AVG(t1.amt) AS median
FROM
(SELECT ROW_NUMBER() OVER (ORDER BY orders.total_amt_usd) AS row_num, orders.total_amt_usd AS amt
FROM orders)t1
WHERE t1.row_num=3456 OR t1.row_num=3457)

SELECT '1. Average' AS Stat,ROUND(AVG(orders.standard_amt_usd),2) AS Standard_Paper,ROUND(AVG(orders.gloss_amt_usd),2) AS Gloss_Paper,ROUND(AVG(orders.poster_amt_usd),2) AS Poster_Paper, ROUND(AVG(orders.total_amt_usd),2) AS Total_Orders
FROM orders
UNION 
SELECT '2. Median' AS stat, ROUND(std.median,2) AS Standard_Paper, ROUND(gloss.median,2) AS  Gloss_Paper, ROUND(poster.median,2) AS Poster_Paper, ROUND(total.median,2) AS Total_Orders
FROM std, gloss, poster, total
UNION
SELECT '3. Minimum' AS stat ,ROUND(MIN(orders.standard_amt_usd),2) AS Standard_Paper,ROUND(MIN(orders.gloss_amt_usd),2) AS Gloss_Paper,ROUND(MIN(orders.poster_amt_usd),2) AS Poster_Paper, ROUND(MIN(orders.total_amt_usd),2) AS Total_Orders
FROM orders
UNION
SELECT '4. Maximum' AS stat ,ROUND(MAX(orders.standard_amt_usd),2) AS Standard_Paper,ROUND(MAX(orders.gloss_amt_usd),2) AS Gloss_Paper,ROUND(MAX(orders.poster_amt_usd),2) AS Poster_Paper, ROUND(MAX(orders.total_amt_usd),2) AS Total_Orders
FROM orders

/*Year-wise orders and revenue analysis*/
SELECT DATEPART(Year,orders.occurred_date) AS Year, COUNT(DISTINCT orders.id) AS numb_orders, COUNT(DISTINCT orders.account_id)  AS numb_companies, COUNT(DISTINCT accounts.sales_rep_id) AS numb_employees
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY DATEPART(Year,orders.occurred_date) 
ORDER BY 1

/*Looking into the sales quantity and revenue generated by each paper type*/
SELECT DATEPART(Year,occurred_date) AS Year,ROUND(SUM(total),2) AS Total_Qty, ROUND(SUM(total_amt_usd),2) AS Total_Amt, SUM(standard_qty) AS Std_Qty, ROUND(SUM(standard_amt_usd),2) AS Std_Amt, SUM(gloss_qty) AS Gloss_Qty, ROUND(SUM(gloss_amt_usd),2) AS Gloss_Amt, SUM(poster_qty) AS Poster_Qty, ROUND(SUM(poster_amt_usd),2) AS Poster_Amt
FROM orders
GROUP BY DATEPART(Year,occurred_date)
ORDER BY 1

/*Drilling down one more level - monthly analysis*/
SELECT DATEPART(Year,occurred_date) AS Year,DATEPART(Month,occurred_date) AS Month,ROUND(SUM(orders.total),2) AS Total, ROUND(SUM(orders.standard_qty),2) AS Std,ROUND(SUM(orders.gloss_qty),2) AS Gloss ,ROUND(SUM(orders.poster_qty),2) AS Poster, 
ROUND((SUM(orders.standard_qty)/SUM(orders.total))*100,2) AS Std_Perc,ROUND((SUM(orders.gloss_qty)/SUM(orders.total))*100,2) AS Gloss_Perc,ROUND((SUM(orders.poster_qty)/SUM(orders.total))*100,2) AS Poster_Perc
FROM orders 
GROUP BY DATEPART(Year,occurred_date),DATEPART(Month,occurred_date)
ORDER BY 1,2

SELECT DATEPART(Year,occurred_date) AS Year,DATEPART(Month,occurred_date) AS Month,ROUND(SUM(orders.total_amt_usd),2) AS Total, ROUND(SUM(orders.standard_amt_usd),2) AS Std,ROUND(SUM(orders.gloss_amt_usd),2) AS Gloss ,ROUND(SUM(orders.poster_amt_usd),2) AS Poster
FROM orders 
GROUP BY DATEPART(Year,occurred_date),DATEPART(Month,occurred_date)
ORDER BY 1,2

/*Region Wise Sales trends*/
SELECT t1.region, COUNT(t1.Company) AS Company_Count,ROUND(AVG(t1.Avg_Total_Qty),2) AS Avg_Total_Qty, ROUND(AVG(t1.Avg_Total_Amt),2) AS Avg_Total_Amt
FROM
(SELECT accounts.name AS Company, sales_reps.name AS Employee, region.name AS region, AVG(orders.total) AS Avg_Total_Qty, ROUND(AVG(orders.total_amt_usd),2) AS Avg_Total_Amt
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id = region.id
GROUP BY accounts.name,sales_reps.name, region.name)t1
GROUP BY t1.region
ORDER BY 4 DESC
/********************************************************/

/*Customer Analysis*/
/*Top 10 customers of all time in terms of total quantity of orders placed and  total amount spent*/
SELECT TOP 10 accounts.name , SUM(orders.total) AS Total_Orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY SUM(total) DESC

SELECT TOP 10 accounts.name ,ROUND(SUM(orders.total_amt_usd),2) AS Total_Amt_Usd
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY SUM(total_amt_usd) DESC

/*Top 10 customers of all time in terms of  total order quantity and most spent on a single order*/
SELECT TOP 10 accounts.name , orders.total AS Total_Orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
ORDER BY total DESC

SELECT TOP 10 accounts.name , ROUND(orders.total_amt_usd,2) AS Total_Amt_Usd
FROM orders JOIN accounts ON orders.account_id=accounts.id
ORDER BY total_amt_usd DESC

/*Quantity and Revenue Distribution */
SELECT accounts.name,  MIN(orders.total) AS Min_Total,MAX(orders.total) AS Max_Total,  MIN(orders.standard_qty) AS Min_Std,MAX(orders.standard_qty) AS Max_Std,
MIN(orders.gloss_qty) AS Min_Gloss ,MAX(orders.gloss_qty) AS Max_Gloss ,MIN(orders.poster_qty) AS Min_Poster, MAX(orders.poster_qty) AS Max_Poster
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name

SELECT accounts.name, ROUND(MIN(orders.total_amt_usd),2) AS Min_Total,ROUND(MAX(orders.total_amt_usd),2) AS Max_Total,  ROUND(MIN(orders.standard_amt_usd),2) AS Min_Std,ROUND(MAX(orders.standard_amt_usd),2) AS Max_Std,
ROUND(MIN(orders.gloss_amt_usd),2) AS Min_Gloss ,ROUND(MAX(orders.gloss_amt_usd),2) AS Max_Gloss ,ROUND(MIN(orders.poster_amt_usd),2) AS Min_Poster, ROUND(MAX(orders.poster_amt_usd),2) AS Max_Poster
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name

/*No orders company - Goldman Sachs Group */
WITH rev AS (SELECT accounts.name, ROUND(MIN(orders.total_amt_usd),2) AS Min_Total,ROUND(MAX(orders.total_amt_usd),2) AS Max_Total,  ROUND(MIN(orders.standard_amt_usd),2) AS Min_Std,ROUND(MAX(orders.standard_amt_usd),2) AS Max_Std,
ROUND(MIN(orders.gloss_amt_usd),2) AS Min_Gloss ,ROUND(MAX(orders.gloss_amt_usd),2) AS Max_Gloss ,ROUND(MIN(orders.poster_amt_usd),2) AS Min_Poster, ROUND(MAX(orders.poster_amt_usd),2) AS Max_Poster
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name),
acc AS (SELECT DISTINCT accounts.name FROM accounts GROUP BY accounts.name)

SELECT acc.name 
FROM acc
WHERE acc.name NOT IN (SELECT rev.name FROM rev)

SELECT web_events.id,occurred_at,channel,accounts.id FROM web_events JOIN accounts ON web_events.account_id=accounts.id
WHERE accounts.name='GoldmanSachsGroup'

/*Top 10 most frequent customers of all time - Loyal customers*/
SELECT TOP 10 accounts.name , COUNT(orders.account_id) AS Num_orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY COUNT(orders.account_id) DESC

/*Comparing the top 10 customers with all-time highest order quantity, highest spend and most frequent customers*/
WITH top_ten_orders AS (SELECT TOP 10 accounts.name , SUM(orders.total) AS Total_Orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY SUM(total) DESC),
top_ten_amt AS (SELECT TOP 10 accounts.name ,ROUND(SUM(orders.total_amt_usd),2) AS Total_Amt_Usd
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY SUM(total_amt_usd) DESC),
top_frequent AS (SELECT TOP 10 accounts.name , COUNT(orders.account_id) AS Num_orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY COUNT(orders.account_id) DESC)

SELECT top_frequent.name
FROM top_frequent, top_ten_orders
WHERE top_frequent.name = top_ten_orders.name

SELECT top_frequent.name
FROM top_frequent, top_ten_amt
WHERE top_frequent.name = top_ten_amt.name

/*Diving into the buying trends of the top 10 most frequent customers*/
SELECT TOP 10 accounts.name , COUNT(orders.account_id) AS Num_orders, SUM(orders.total) AS Total_orders, SUM(orders.standard_qty) AS Std, SUM(orders.gloss_qty) AS Gloss,SUM(orders.poster_qty) AS Poster,ROUND(SUM(orders.total_amt_usd),2) AS Total_Amt
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY COUNT(orders.account_id) DESC

/*How many years have these frequent customers ordered from Parch and Posey? */
SELECT TOP 10 accounts.name AS Company , COUNT(orders.account_id) AS Num_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
ORDER BY COUNT(orders.account_id) DESC

/*Looking at the data in more general terms - in terms of average - below, above or average and number of years. */
CREATE TABLE #temp_averages (
Year_range  varchar(100),
Count_Companies int,
Avg_Orders int,
Avg_Qty int,
Avg_Spend int
)

INSERT INTO #temp_averages
SELECT t2.year_range AS year_range, COUNT(t2.Num_orders) AS count_companies,AVG(t2.Num_orders) AS Avg_Orders, AVG(t2.Total_orders) AS Avg_Qty, CAST(AVG(t2.Amt) AS INT) AS AvgSpend
FROM
(SELECT t1.*,
CASE WHEN t1.Num_of_Years >=2 THEN 'More than 2 years' 
	 WHEN t1.Num_of_Years <2 AND t1.Num_of_Years >=1 THEN 'Between 1 and 2 years' 
	 WHEN t1.Num_of_Years <1 THEN 'Under 1 year' END AS year_range
FROM
(SELECT accounts.name AS Company , COUNT(orders.account_id) AS Num_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years, ROUND(SUM(orders.total_amt_usd),2) AS Amt, SUM(orders.total) AS Total_orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name)t1
GROUP BY t1.Company, t1.Num_orders, t1.First_order, t1.Latest_order, t1.Num_of_Years,t1.Amt,t1.Total_orders)t2
GROUP BY year_range

SELECT * FROM #temp_averages

/*Below-average order quantity*/
SELECT t3.year_range, COUNT(t3.Num_orders) AS Count_Companies_lower, AVG(t3.Num_orders) AS Average_Orders_lower,AVG(t3.Total_orders) AS Average_qty_lower, AVG(#temp_averages.Count_Companies) AS Count_Companies_overall, AVG(#temp_averages.Avg_Orders) AS Average_Orders_overall, AVG(#temp_averages.Avg_Qty) AS Average_Qty
FROM
(SELECT t2.Company, t2.Num_orders, t2.year_range,t2.Total_orders
FROM
(SELECT t1.Company, t1.Num_orders,t1.Total_orders,
CASE WHEN t1.Num_of_Years >=2 THEN 'More than 2 years' 
	 WHEN t1.Num_of_Years <2 AND t1.Num_of_Years >=1 THEN 'Between 1 and 2 years' 
	 WHEN t1.Num_of_Years <1 THEN 'Under 1 year' END AS year_range
FROM
(SELECT accounts.name AS Company , COUNT(orders.account_id) AS Num_orders,SUM(orders.total) AS Total_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name)t1)t2,#temp_averages
WHERE t2.year_range=#temp_averages.year_range AND t2.Total_orders<#temp_averages.Avg_Qty)t3,#temp_averages
WHERE t3.year_range=#temp_averages.year_range 
GROUP BY t3.year_range

/*Below average Revenue*/
SELECT t3.year_range, COUNT(t3.Num_orders) AS Count_Companies_lower,CAST(AVG(t3.Amt) AS INT) AS Average_Spend_lower,AVG(#temp_averages.Count_Companies) AS Count_Companies_overall, AVG(#temp_averages.Avg_Spend) AS Average_Spend_overall
FROM
(SELECT t2.Company, t2.Amt, t2.year_range,t2.Num_orders
FROM
(SELECT t1.Company,t1.Amt, t1.Num_orders,
CASE WHEN t1.Num_of_Years >=2 THEN 'More than 2 years' 
	 WHEN t1.Num_of_Years <2 AND t1.Num_of_Years >=1 THEN 'Between 1 and 2 years' 
	 WHEN t1.Num_of_Years <1 THEN 'Under 1 year' END AS year_range
FROM
(SELECT accounts.name AS Company ,SUM(orders.total_amt_usd) AS Amt, COUNT(orders.account_id) AS Num_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name)t1)t2,#temp_averages
WHERE t2.year_range=#temp_averages.year_range AND t2.Amt<#temp_averages.Avg_Spend)t3,#temp_averages
WHERE t3.year_range=#temp_averages.year_range 
GROUP BY t3.year_range

/*Above-average orders quantity*/
SELECT t3.year_range, COUNT(t3.Num_orders) AS Count_Companies_higher, AVG(t3.Num_orders) AS Average_Orders_higher,AVG(t3.Total_orders) AS Average_qty_higher, AVG(#temp_averages.Count_Companies) AS Count_Companies_overall, AVG(#temp_averages.Avg_Orders) AS Average_Orders_overall, AVG(#temp_averages.Avg_Qty) AS Average_Qty
FROM
(SELECT t2.Company, t2.Num_orders, t2.year_range,t2.Total_orders
FROM
(SELECT t1.Company, t1.Num_orders,t1.Total_orders,
CASE WHEN t1.Num_of_Years >=2 THEN 'More than 2 years' 
	 WHEN t1.Num_of_Years <2 AND t1.Num_of_Years >=1 THEN 'Between 1 and 2 years' 
	 WHEN t1.Num_of_Years <1 THEN 'Under 1 year' END AS year_range
FROM
(SELECT accounts.name AS Company , COUNT(orders.account_id) AS Num_orders,SUM(orders.total) AS Total_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name)t1)t2,#temp_averages
WHERE t2.year_range=#temp_averages.year_range AND t2.Total_orders>#temp_averages.Avg_Qty)t3,#temp_averages
WHERE t3.year_range=#temp_averages.year_range 
GROUP BY t3.year_range

/*Above average spend*/
SELECT t3.year_range, COUNT(t3.Num_orders) AS Count_Companies_higher,CAST(AVG(t3.Amt) AS INT) AS Average_Spend_higher,AVG(#temp_averages.Count_Companies) AS Count_Companies_overall, AVG(#temp_averages.Avg_Spend) AS Average_Spend_overall
FROM
(SELECT t2.Company, t2.Amt, t2.year_range,t2.Num_orders
FROM
(SELECT t1.Company,t1.Amt, t1.Num_orders,
CASE WHEN t1.Num_of_Years >=2 THEN 'More than 2 years' 
	 WHEN t1.Num_of_Years <2 AND t1.Num_of_Years >=1 THEN 'Between 1 and 2 years' 
	 WHEN t1.Num_of_Years <1 THEN 'Under 1 year' END AS year_range
FROM
(SELECT accounts.name AS Company ,SUM(orders.total_amt_usd) AS Amt, COUNT(orders.account_id) AS Num_orders, MIN(orders.occurred_date) AS First_order,MAX(orders.occurred_date) AS Latest_order,ROUND(CAST(CAST(DATEDIFF(Day,MIN(orders.occurred_date),MAX(orders.occurred_date)) AS FLOAT)/365.00 AS FLOAT),1) AS Num_of_Years
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name)t1)t2,#temp_averages
WHERE t2.year_range=#temp_averages.year_range AND t2.Amt>#temp_averages.Avg_Spend)t3,#temp_averages
WHERE t3.year_range=#temp_averages.year_range 
GROUP BY t3.year_range

/*Customer behaviour before purchase*/
SELECT t1.Distinct_channel, COUNT(t1.Distinct_channel) AS Count_Companies
FROM 
(SELECT accounts.name, COUNT(DISTINCT web_events.channel) AS Distinct_channel
FROM accounts JOIN web_events ON accounts.id=web_events.account_id
GROUP BY accounts.name)t1
GROUP BY t1.Distinct_channel
ORDER BY 2 DESC

/*Most popular channel for each company top order and spend ranking*/
SELECT t2.name, COUNT(t2.channel) Count_channel
FROM 
(SELECT t1.name, t1.channel,t1.total_Amt, t1.Order_id
FROM
(SELECT DENSE_RANK() OVER (PARTITION BY orders.account_id ORDER BY total_amt_usd DESC) AS total_rank, accounts.name, orders.id AS Order_id,web_events.id AS web_id,web_events.channel,ROUND(total_amt_usd,2) AS total_Amt
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN web_events ON accounts.id=web_events.account_id
WHERE orders.occurred_date=web_events.occurred_date)t1
WHERE t1.total_rank=1)t2
GROUP BY t2.name
ORDER BY 2 DESC

SELECT t2.name, COUNT(t2.channel) Count_channel
FROM 
(SELECT t1.name, t1.channel,t1.total, t1.Order_id
FROM
(SELECT DENSE_RANK() OVER (PARTITION BY orders.account_id ORDER BY total DESC) AS total_rank, accounts.name, orders.id AS Order_id,web_events.id AS web_id,web_events.channel,total 
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN web_events ON accounts.id=web_events.account_id
WHERE orders.occurred_date=web_events.occurred_date)t1
WHERE t1.total_rank=1)t2
GROUP BY t2.name
ORDER BY 2 DESC
/********************************************************/

/*Employee Analysis*/
/*Overview of ranking employees based on number of orders, total orders and total revenue generated. */
SELECT sales_reps.name,  RANK() OVER (ORDER BY COUNT(orders.id) DESC) AS Numb_orders_rank, COUNT(orders.id) AS Numb_orders, RANK() OVER (ORDER BY SUM(orders.total) DESC) AS Total_orders_rank,SUM(orders.total) AS Total_orders,RANK() OVER (ORDER BY SUM(orders.total_amt_usd) DESC) AS Total_amt_rank, ROUND(SUM(orders.total_amt_usd),2) AS Total_sales
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
GROUP BY sales_reps.name
ORDER BY 3 DESC

/*Employee workload based on the number of accounts handled*/
SELECT sales_reps.name AS name, COUNT(DISTINCT accounts.id) AS Numb_accounts
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
GROUP BY sales_reps.name
ORDER BY 2 DESC

/*Diving one level further to analyse workload location-wise*/
SELECT t1.region, COUNT(DISTINCT t1.Employee) AS Employee_count, COUNT(t1.Company) AS Company
FROM
(SELECT accounts.name AS Company, sales_reps.name AS Employee, region.name AS region
FROM accounts JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id = region.id
GROUP BY accounts.name,sales_reps.name, region.name
)t1
GROUP BY t1.region
ORDER BY 2 DESC

/*Percentage of orders, quantity and revenue generated or completed by each employee*/
SELECT sales_reps.name AS name, COUNT(orders.id) AS Numb_orders,ROUND((CAST(COUNT(orders.id) AS FLOAT)/6912.0)*100,1) AS Perc_orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
GROUP BY sales_reps.name
ORDER BY 3 DESC

SELECT sales_reps.name AS name, SUM(orders.total) AS Total_orders,ROUND((CAST( SUM(orders.total) AS FLOAT)/3675765.0)*100,1) AS Perc_Total_orders
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
GROUP BY sales_reps.name
ORDER BY 3 DESC

SELECT sales_reps.name AS name, ROUND(SUM(orders.total_amt_usd),2) AS Total_Revenue,ROUND((CAST( SUM(orders.total_amt_usd) AS FLOAT)/23141511.8192616)*100,1) AS Perc_Total_revenue
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
GROUP BY sales_reps.name
ORDER BY 3 DESC

/*Employee performance over the years*/
CREATE TABLE #temp_emp_growth  (
Sales_Rep varchar(100),
Join_Date DATE,
Numb_Orders_2013 int,
Numb_Orders_2014 int,
Numb_Orders_2015 int,
Numb_Orders_2016 int,
Numb_Orders_2017 int,
)


INSERT INTO #temp_emp_growth
SELECT t1.name, MIN(t1.Join_Year) AS Join_Date, SUM(t1.Num_orders_2013) AS Num_orders_2013,SUM(t1.Num_orders_2014) AS Num_orders_2014, SUM(t1.Num_orders_2015) AS Num_orders_2015, SUM(t1.Num_orders_2016) AS Num_orders_2016, SUM(t1.Num_orders_2017) AS Num_orders_2017
FROM 
(
SELECT sales_reps.name, MIN(orders.occurred_date) AS Join_Year,
CASE WHEN DATEPART(Year,orders.occurred_date)=2013 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2013,
CASE WHEN DATEPART(Year,orders.occurred_date)=2014 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2014,
CASE WHEN DATEPART(Year,orders.occurred_date)=2015 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2015,
CASE WHEN DATEPART(Year,orders.occurred_date)=2016 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2016,
CASE WHEN DATEPART(Year,orders.occurred_date)=2017 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2017
FROM orders JOIN accounts ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
GROUP BY sales_reps.name, DATEPART(Year, orders.occurred_date)
) t1
GROUP BY t1.name

/*dip in 2015*/
SELECT * FROM #temp_emp_growth

SELECT Sales_Rep,Numb_Orders_2014,Numb_Orders_2015,Numb_Orders_2016
FROM #temp_emp_growth
WHERE Numb_Orders_2015 < Numb_Orders_2016/2 AND Numb_Orders_2015 < Numb_Orders_2014/2

/*Next the companies these employees handle are identified*/
SELECT accounts.name
FROM accounts
WHERE sales_rep_id IN 
(SELECT sales_reps.id
FROM sales_reps
WHERE sales_reps.name IN (
SELECT Sales_Rep
FROM #temp_emp_growth
WHERE Numb_Orders_2015 < Numb_Orders_2016/2 AND Numb_Orders_2015 < Numb_Orders_2014/2))
ORDER BY 1

/*The employees handle 29 accounts. Now filtering the accounts that have placed an order in 2015: */
SELECT accounts.name, COUNT(orders.account_id) AS order_count
FROM orders JOIN accounts ON orders.account_id=accounts.id 
WHERE DATEPART(Year,occurred_date)='2015' AND sales_rep_id IN 
(SELECT sales_reps.id
FROM sales_reps
WHERE sales_reps.name IN (
SELECT Sales_Rep
FROM #temp_emp_growth
WHERE Numb_Orders_2015 < Numb_Orders_2016/2 AND Numb_Orders_2015 < Numb_Orders_2014/2))
GROUP BY accounts.name
ORDER BY 2 DESC

/*Who handled the orders of the customers that had the top 10 order quantity of all time, top 10 highest spend and top 10 most frequent customers? */
SELECT TOP 10 accounts.name AS Company , SUM(orders.total) AS Total_Orders,sales_reps.name AS Employee
FROM sales_reps JOIN accounts ON  sales_reps.id=accounts.sales_rep_id
JOIN orders ON accounts.id= orders.account_id
GROUP BY accounts.name, sales_reps.name
ORDER BY SUM(orders.total) DESC

SELECT TOP 10 accounts.name AS Company , ROUND(SUM(orders.total_amt_usd),2) AS Total_Amt_Usd,sales_reps.name AS Employee
FROM sales_reps JOIN accounts ON  sales_reps.id=accounts.sales_rep_id
JOIN orders ON accounts.id= orders.account_id
GROUP BY accounts.name, sales_reps.name
ORDER BY SUM(Total_Amt_Usd) DESC

SELECT TOP 10 accounts.name AS Company , COUNT(orders.account_id) AS Num_orders,sales_reps.name AS Employee
FROM sales_reps JOIN accounts ON  sales_reps.id=accounts.sales_rep_id
JOIN orders ON accounts.id= orders.account_id
GROUP BY accounts.name, sales_reps.name
ORDER BY COUNT(orders.account_id) DESC
/********************************************************/

/*Customer Satisfaction*/
CREATE TABLE #temp_order_growth  (
Company varchar(100),
Join_Date DATE,
Latest_Date DATE,
Total_Orders_2013 int,
Total_Orders_2014 int,
Total_Orders_2015 int,
Total_Orders_2016 int,
Total_Orders_2017 int
)


INSERT INTO #temp_order_growth
SELECT t1.name, MIN(t1.Join_Year) AS Join_Date,  MAX(t1.Join_Year) AS Latest_Date,SUM(t1.Num_orders_2013) AS Num_orders_2013,SUM(t1.Num_orders_2014) AS Num_orders_2014, SUM(t1.Num_orders_2015) AS Num_orders_2015, SUM(t1.Num_orders_2016) AS Num_orders_2016, SUM(t1.Num_orders_2017) AS Num_orders_2017
FROM 
(
SELECT accounts.name, MIN(orders.occurred_date) AS Join_Year,MAX(orders.occurred_date) AS Latest_Year,
CASE WHEN DATEPART(Year,orders.occurred_date)=2013 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2013,
CASE WHEN DATEPART(Year,orders.occurred_date)=2014 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2014,
CASE WHEN DATEPART(Year,orders.occurred_date)=2015 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2015,
CASE WHEN DATEPART(Year,orders.occurred_date)=2016 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2016,
CASE WHEN DATEPART(Year,orders.occurred_date)=2017 THEN COUNT(orders.occurred_date) ELSE 0 END AS Num_orders_2017
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name, DATEPART(Year, orders.occurred_date)
) t1
GROUP BY t1.name

SELECT * FROM #temp_order_growth

/*Average time between consecutive orders (for companies that have more than 1 order)*/
/*Average time between consecutive orders - only for companies that have more than one order*/
SELECT t2.name, COUNT(t2.next_order_date)+2 AS count_of_orders,AVG(t2.number_of_days) AS Avergae_number_of_days_between_orders
FROM 
(
SELECT accounts.name,LEAD(orders.occurred_date) OVER (ORDER BY accounts.name) AS next_order_date, 
DATEDIFF(Day,orders.occurred_date,LEAD(orders.occurred_date) OVER (ORDER BY accounts.name)) AS number_of_days
FROM accounts JOIN orders ON accounts.id = orders.account_id
WHERE accounts.name IN (
SELECT t1.name
FROM
(SELECT accounts.name,  orders.id
FROM accounts JOIN orders ON accounts.id = orders.account_id
GROUP BY accounts.name,  orders.id)t1
GROUP BY t1.name
HAVING COUNT(t1.name) > 1))t2 
WHERE t2.number_of_days>=0
GROUP BY t2.name
ORDER BY 3

/*Are there companies that have placed only a single order? */
SELECT t1.name, orders.occurred_date,sales_reps.name, region.name
FROM
(SELECT accounts.name, COUNT(orders.account_id) AS cnt
FROM orders JOIN accounts ON orders.account_id=accounts.id
GROUP BY accounts.name
HAVING COUNT(orders.account_id)=1)t1 JOIN accounts ON t1.name=accounts.name
JOIN orders ON accounts.id=orders.account_id
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id = region.id
ORDER BY 2,1

/*Retention Rates*/
SELECT (CAST(COUNT(DISTINCT t1.acc_2014) AS FLOAT)/CAST(COUNT(DISTINCT accounts.name) AS FLOAT))*100 AS Retention_rate_2014
FROM
(SELECT DISTINCT accounts.name AS acc_2014 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014' AND  accounts.name IN (SELECT DISTINCT accounts.name AS acc_2015 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015'))t1,
accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014' 


SELECT ROUND((CAST(COUNT(DISTINCT t1.acc_2015) AS FLOAT)/CAST(COUNT(DISTINCT accounts.name) AS FLOAT))*100,2) AS Retention_rate_2015
FROM
(SELECT DISTINCT accounts.name AS acc_2015
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015' AND  accounts.name IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016'))t1,
accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015' 

SELECT ROUND((CAST(COUNT(DISTINCT t1.acc_2014) AS FLOAT)/CAST(COUNT(DISTINCT accounts.name) AS FLOAT))*100,2) AS Retention_rate_2016
FROM
(SELECT DISTINCT accounts.name AS acc_2014
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014' AND  accounts.name IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016'))t1,
accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014' 

/*Identifying companies that were not retained in 2015 and 2016 and analysing what the reason might be: */
WITH summary_2014 AS (SELECT DISTINCT accounts.name AS Company, sales_reps.name AS Employee, region.name AS Region
FROM orders JOIN  accounts  ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id =region.id
WHERE DATEPART(Year,orders.occurred_date) = '2014' AND  accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2015 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015') AND accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016')),
summary_2015 AS (SELECT DISTINCT accounts.name AS Company, sales_reps.name AS Employee, region.name AS Region
FROM orders JOIN  accounts  ON orders.account_id=accounts.id
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id =region.id
WHERE DATEPART(Year,orders.occurred_date) = '2015' AND  accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2014 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014') AND accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016'))

SELECT summary_2014.Company, '2014-2015' AS Year_Range
FROM summary_2014
UNION 
SELECT summary_2015.Company AS Company_2015_2016, '2015-2016' AS Year_Range
FROM summary_2015
ORDER BY Year_Range

SELECT summary_2014.Employee,COUNT(summary_2014.Employee) AS Employee_Count, '2014-2015' AS Year_Range
FROM summary_2014
GROUP BY summary_2014.Employee
UNION 
SELECT summary_2015.Employee,COUNT(summary_2015.Employee) AS Employee_Count, '2015-2016' AS Year_Range
FROM summary_2015
GROUP BY summary_2015.Employee
ORDER BY Year_Range

SELECT summary_2014.Region,COUNT(summary_2014.Region) AS Region_Count, '2014-2015' AS Year_Range
FROM summary_2014
GROUP BY summary_2014.Region
UNION 
SELECT summary_2015.Region,COUNT(summary_2015.Region) AS Region_Count, '2015-2016' AS Year_Range
FROM summary_2015
GROUP BY summary_2015.Region
ORDER BY Year_Range

/*Web channels used by these companies*/
/*Most famous channels in cases when customer does not return*/
SELECT t2.channel, COUNT(t2.channel) AS count
FROM
(SELECT t1.acc_2015,web_events.channel
FROM 
(SELECT DISTINCT accounts.name AS acc_2015
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015' AND  accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2014 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014') AND accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016'))t1 JOIN accounts ON t1.acc_2015=accounts.name
JOIN web_events ON web_events.account_id =accounts.id
WHERE DATEPART(Year,web_events.occurred_date)='2015' AND accounts.name= t1.acc_2015
GROUP BY t1.acc_2015,web_events.channel)t2
GROUP BY t2.channel
ORDER BY 2 DESC

SELECT t2.channel, COUNT(t2.channel) AS count
FROM
(SELECT t1.acc_2014,web_events.channel
FROM 
(SELECT DISTINCT accounts.name AS acc_2014
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2014' AND  accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2015 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2015') AND accounts.name NOT IN (SELECT DISTINCT accounts.name AS acc_2016 
FROM accounts JOIN orders ON accounts.id=orders.account_id
WHERE DATEPART(Year,orders.occurred_date) = '2016'))t1 JOIN accounts ON t1.acc_2014=accounts.name
JOIN web_events ON web_events.account_id =accounts.id
WHERE DATEPART(Year,web_events.occurred_date)='2014' AND accounts.name= t1.acc_2014
GROUP BY t1.acc_2014,web_events.channel)t2
GROUP BY t2.channel
ORDER BY 2 DESC

/*Most channel used*/
SELECT channel, COUNT(channel) AS count
FROM web_events
GROUP BY channel
ORDER BY 2 DESC

/*Companies that have ordered in all consecutive years since the beginning*/
WITH summary AS (SELECT Company, SUM(Total_Orders_2014)+SUM(Total_Orders_2015)+SUM(Total_Orders_2016) AS total_orders, sales_reps.name AS Employee, region.name AS Region
FROM #temp_order_growth JOIN accounts ON #temp_order_growth.Company=accounts.name
JOIN sales_reps ON accounts.sales_rep_id=sales_reps.id
JOIN region ON sales_reps.region_id = region.id
WHERE Total_Orders_2014 > 0 AND Total_Orders_2015 > 0 AND Total_Orders_2016 > 0 AND DATEPART(Year,Join_Date) = '2013' AND DATEPART(Year,Latest_Date) >= '2016'
GROUP BY Company, sales_reps.name, region.name)

SELECT summary.Company, summary.total_orders
FROM summary

SELECT summary.Employee, COUNT(summary.Employee) AS Count_Employee
FROM summary
GROUP BY summary.Employee
ORDER BY 2 DESC

SELECT summary.Region, COUNT(summary.Region) AS Count_Region
FROM summary
GROUP BY summary.Region
ORDER BY 2 DESC

/*Companies in 2013*/
SELECT accounts.name
FROM accounts JOIN orders ON accounts.id = orders.account_id
WHERE DATEPART(Year,orders.occurred_date)='2013'
GROUP BY accounts.name

SELECT t1.Region , COUNT(t1.Region) AS Region_Count
FROM
(SELECT accounts.name, region.name AS Region
FROM accounts JOIN orders ON accounts.id = orders.account_id
JOIN sales_reps ON accounts.sales_rep_id =sales_reps.id
JOIN region ON sales_reps.region_id = region.id
GROUP BY region.name,accounts.name)t1
GROUP BY t1.Region
ORDER BY 2 DESC

/*Channels used*/
SELECT t2.channel, COUNT(t2.channel) AS Channel_count
FROM
(SELECT DISTINCT web_events.channel,  t1.Company
FROM
(SELECT  Company, SUM(Total_Orders_2014)+SUM(Total_Orders_2015)+SUM(Total_Orders_2016) AS total_orders
FROM #temp_order_growth
WHERE Total_Orders_2014 > 0 AND Total_Orders_2015 > 0 AND Total_Orders_2016 > 0 AND DATEPART(Year,Join_Date) = '2013' AND DATEPART(Year,Latest_Date) >= '2016'
GROUP BY Company)t1 JOIN accounts ON t1.Company=accounts.name 
JOIN web_events ON accounts.id=web_events.account_id)t2
GROUP BY t2.channel
ORDER BY 2 DESC

/*Goldman Sachs Group*/

SELECT sales_reps.name
FROM accounts JOIN sales_reps ON accounts.sales_rep_id = sales_reps.id
WHERE accounts.name='GoldmanSachsGroup'

SELECT accounts.name
FROM sales_reps JOIN accounts ON sales_reps.id=accounts.sales_rep_id
WHERE sales_reps.name='GiannaDossey'
GROUP BY accounts.name

SELECT MIN(t1.NumberOfCompanies) AS Minimum, MAX(t1.NumberOfCompanies) AS Maximum, AVG(t1.NumberOfCompanies) AS Average
FROM
(SELECT sales_reps.name, COUNT(DISTINCT accounts.id) AS NumberOfCompanies
FROM sales_reps JOIN accounts ON sales_reps.id=accounts.sales_rep_id
GROUP BY sales_reps.name)t1

SELECT accounts.name,MIN(orders.occurred_date) AS join_date,MAX(orders.occurred_date) AS latest_date, COUNT(orders.id) AS numb_orders,AVG(orders.total) AS total_orders , ROUND(AVG(orders.total_amt_usd),2) AS total_revenue
FROM sales_reps JOIN accounts ON sales_reps.id=accounts.sales_rep_id
JOIN orders ON accounts.id = orders.account_id 
WHERE sales_reps.name='GiannaDossey'
GROUP BY accounts.name