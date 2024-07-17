/*
Paytm Customer Analysis 

Skills used: Joins, CTE, Windows Functions, Aggregate Functions, Pivot Table, Converting Data Types

*/

-- USING Joins, Group By, CTE, Converting Data Types.
 
-- Top 10% of failed 'Payment' transactions with the highest transaction value (charged_amount) in February 2019

SELECT TOP 10 PERCENT transaction_id,
transaction_type,
charged_amount
FROM fact_transaction_2019 AS fact_19
LEFT JOIN dim_scenario AS dsc 
ON fact_19.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact_19.status_id = dst.status_id
WHERE MONTH(transaction_time) = 2 AND transaction_type = 'Payment'
    AND status_description != 'Success'
ORDER BY charged_amount DESC

-- Top 10 highest customers by the total of charged amount in first 3 months of 2020

SELECT TOP 10 customer_id,
     COUNT(transaction_id) AS number_trans,
     COUNT(DISTINCT fact_20.scenario_id) AS number_scenarios,
     COUNT(DISTINCT dsc.category) AS number_categories,
     SUM(CAST(charged_amount AS BIGINT )) AS total_amount
FROM fact_transaction_2020 AS fact_20
LEFT JOIN dim_scenario AS dsc 
ON fact_20.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact_20.status_id = dst.status_id
WHERE MONTH(transaction_time) <= 3 AND status_description = 'Success' AND transaction_type = 'Payment'
GROUP BY customer_id
ORDER BY SUM(CAST(charged_amount AS BIGINT )) DESC

-- Segment customers into 2 groups: Greater than average value and Below the average value

WITH table_amount AS (
SELECT customer_id,
     SUM(CAST(charged_amount AS BIGINT )) AS total_amount
FROM fact_transaction_2020 AS fact_20
LEFT JOIN dim_scenario AS dsc 
ON fact_20.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact_20.status_id = dst.status_id
WHERE MONTH(transaction_time) <= 3 AND status_description = 'Success' AND transaction_type = 'Payment'
GROUP BY customer_id
),
table_avg AS (
SELECT *,
(SELECT AVG(CAST(total_amount AS decimal)) FROM table_amount) AS avg_amount
FROM table_amount
)
SELECT *,
      CASE WHEN total_amount > avg_amount THEN 'greater_than_average'
           ELSE 'lower_than_average'
           END AS group_customer
FROM table_avg

-- TIME SERIES ANALYSIS

-- Analyze the trend of 'Payment' transactions of the Billing category from 2019 to 2020

WITH table_trans AS (
SELECT transaction_id, transaction_time,
       YEAR(transaction_time) [year],
       MONTH(transaction_time) [month]
FROM (
    SELECT *
    FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020) AS fact 
LEFT JOIN dim_scenario AS dsc 
ON fact.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact.status_id = dst.status_id
WHERE fact.status_id = 1 AND category = 'Billing'
)
SELECT DISTINCT [year],
                [month],
                FORMAT(transaction_time,'yyyyMM') AS time_calendar,
                COUNT(transaction_id) OVER (PARTITION BY [year], [month] ) AS number_trans 
FROM table_trans
ORDER BY [year], [month]

-- PIVOT TABLE

-- Break down the trend into each sub-categories and show the trend of 3 sub-categories:
-- Electricity, Internet and Water from 2019 to 2020


WITH table_trans AS (
SELECT transaction_id, sub_category,
       YEAR(transaction_time) [year],
       MONTH(transaction_time) [month]
FROM (
    SELECT *
    FROM fact_transaction_2019
    UNION
    SELECT *
    FROM fact_transaction_2020) AS fact 
LEFT JOIN dim_scenario AS dsc 
ON fact.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact.status_id = dst.status_id
WHERE fact.status_id = 1 AND category = 'Billing'
)

SELECT [year], [month], [Electricity], [Internet], [Water]
FROM (
      SELECT DISTINCT [year],
                [month],
                sub_category,
                COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
      FROM table_trans) table_rank
PIVOT (SUM(number_trans) FOR sub_category IN ([Electricity],[Internet],[Water])) AS Pivot_table     
ORDER BY [year], [month]

-- CUSTOMER RETENTION RATE

-- Analyze retention rate of the "Telco Card" customer group after each month since 
-- that customer first used the service in January 2019

WITH table_first_month AS (
SELECT customer_id, transaction_time,MONTH(transaction_time) AS [month],
       MIN(MONTH(transaction_time)) OVER (PARTITION BY customer_id) AS first_month
FROM fact_transaction_2019 AS fact
LEFT JOIN dim_scenario AS DSC
ON fact.scenario_id = DSC.scenario_id
LEFT JOIN dim_status AS DST
ON fact.status_id = DST.status_id
WHERE fact.status_id = 1 AND sub_category = 'Telco Card'
),
table_month AS (
SELECT *,
       DATEDIFF(MONTH,first_month, transaction_time) AS subsequent_month
FROM table_first_month
),
table_retained AS (
SELECT first_month,
       subsequent_month - MIN(subsequent_month) OVER (PARTITION BY first_month) AS subsequent_month,
       COUNT (DISTINCT customer_id) AS retained_user 
FROM table_month
GROUP BY first_month, subsequent_month
)
,
table_pct AS (
SELECT *,
       MAX(retained_user) OVER (PARTITION BY first_month ORDER BY subsequent_month) AS original_user,
       CAST(retained_user*1.0000/MAX(retained_user) OVER (PARTITION BY first_month ORDER BY subsequent_month) AS decimal (10,4)) AS pct_retained
FROM table_retained
)
-- table_pct AS (
-- SELECT *,
--        FIRST_VALUE(retained_user) OVER (PARTITION BY first_month ORDER BY subsequent_month) AS original_user,
--        CAST(CAST(retained_user AS float)/FIRST_VALUE(retained_user) OVER (PARTITION BY first_month ORDER BY subsequent_month) AS decimal(10,2)) AS pct_retained
-- FROM table_retained
-- )
SELECT first_month ,[0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11]
FROM (
SELECT first_month, subsequent_month, pct_retained
FROM table_pct
) AS source_table
PIVOT(
    SUM(pct_retained)
    FOR subsequent_month IN ([0],[1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11])
) AS pivot_table
ORDER BY first_month

-- CUSTOMER SEGMENTATION
-- Using RFM Analysis to segment all successful paying customer in 2019 and 2020

With RFM_table AS (
SELECT DISTINCT customer_id,
       MIN(DATEDIFF(DAY, transaction_time,'2020-12-31' )) AS RECENCY,
       COUNT(DISTINCT transaction_id) AS FREQUENCY,
       SUM(charged_amount*1) AS MONETARY
FROM (SELECT * FROM fact_transaction_2019
      UNION
      SELECT * FROM fact_transaction_2020) AS fact
LEFT JOIN dim_scenario AS DSC
ON fact.scenario_id = DSC.scenario_id
LEFT JOIN dim_status AS DST
ON fact.status_id = DST.status_id
WHERE fact.status_id = 1 
GROUP BY customer_id
),
RFM_score AS (
SELECT *,
      NTILE(5) OVER (ORDER BY RECENCY DESC) AS R_Score,
      NTILE(5) OVER (ORDER BY FREQUENCY ASC) AS F_Score,
      NTILE(5) OVER (ORDER BY MONETARY ASC) AS M_Score
FROM RFM_table
),
RFM_final AS (
SELECT *,
       CONCAT(R_Score, F_Score, M_Score) AS RFM_Overall
FROM RFM_score
)
SELECT FN.*, SS.Segment
FROM RFM_final AS FN
LEFT JOIN [segment scores] AS SS
ON SS.Scores = FN.RFM_Overall 
