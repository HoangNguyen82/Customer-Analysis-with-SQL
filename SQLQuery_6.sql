                       -PART 1: PRACTICE SKILLS

TASK 1

SELECT MONTH(transaction_time),
COUNT(transaction_id) AS number_success_trans
FROM fact_transaction_2019 AS fact_19 
LEFT JOIN dim_scenario AS dsc 
ON fact_19.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact_19.status_id = dst.status_id
WHERE fact_19.status_id = 1
GROUP BY MONTH(transaction_time)
ORDER BY MONTH(transaction_time)

--TASK 2.1:

WITH table_year AS (
SELECT YEAR(transaction_time) [year],
       MONTH(transaction_time) [month],
       COUNT(transaction_id) AS number_success_trans
FROM(SELECT * FROM fact_transaction_2019 UNION SELECT * FROM fact_transaction_2020) AS fact
LEFT JOIN dim_scenario AS dsc 
ON fact.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact.status_id = dst.status_id
WHERE fact.status_id = 1
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
)
SELECT *,
       SUM(number_success_trans) OVER (PARTITION BY [year]) AS total_trans_year,
       FORMAT(CAST(number_success_trans AS decimal)/SUM(number_success_trans) OVER (PARTITION BY [year]),'p') AS pct 
FROM table_year
ORDER BY [year], [month]

-- TASK 2.2

-- WITH table_year AS (
-- SELECT YEAR(transaction_time) [year],
--        MONTH(transaction_time) [month],
--        COUNT(transaction_id) AS number_failed_trans
-- FROM(SELECT * FROM fact_transaction_2019 UNION SELECT * FROM fact_transaction_2020) AS fact
-- LEFT JOIN dim_scenario AS dsc 
-- ON fact.scenario_id = dsc.scenario_id
-- LEFT JOIN dim_status AS dst 
-- ON fact.status_id = dst.status_id
-- WHERE fact.status_id != 1
-- GROUP BY YEAR(transaction_time), MONTH(transaction_time)
-- ),
-- table_rank AS (
-- SELECT *,
-- RANK() OVER (PARTITION BY [year] ORDER BY number_failed_trans DESC) total_rank
-- FROM table_year
-- )
-- SELECT *
-- FROM table_rank
-- WHERE total_rank < 4

WITH table_rank AS (
SELECT *,
RANK() OVER (PARTITION BY [year] ORDER BY number_failed_trans DESC) total_rank
FROM (
SELECT YEAR(transaction_time) [year],
       MONTH(transaction_time) [month],
       COUNT(transaction_id) AS number_failed_trans
FROM(SELECT * FROM fact_transaction_2019 UNION SELECT * FROM fact_transaction_2020) AS fact
LEFT JOIN dim_scenario AS dsc 
ON fact.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact.status_id = dst.status_id
WHERE fact.status_id != 1
GROUP BY YEAR(transaction_time), MONTH(transaction_time)
) [table_year] 
)
SELECT *
FROM table_rank
WHERE total_rank <4

-- TASK 2.3
WITH table_day AS (
SELECT customer_id,
AVG(gap_day) OVER (PARTITION BY customer_id) AS avg_gap_day
FROM(
SELECT customer_id,
transaction_id,
transaction_time,
DATEDIFF(day,LAG(transaction_time) OVER (partition BY customer_id ORDER BY transaction_time),transaction_time) AS gap_day
FROM fact_transaction_2019 AS fact_19 
LEFT JOIN dim_scenario AS dsc 
ON fact_19.scenario_id = dsc.scenario_id
LEFT JOIN dim_status AS dst 
ON fact_19.status_id = dst.status_id
WHERE fact_19.status_id = 1 AND category = 'Telco' 
) table_time
),
table_col AS (
SELECT *,
ROW_NUMBER() OVER (partition BY customer_id ORDER BY avg_gap_day) AS num_col
FROM table_day
)
SELECT customer_id,
       avg_gap_day
FROM table_col
WHERE num_col = 1

                         -- PART 2: SQL APPLIED TO REAL PROBLEMS
-- 1.1

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

-- 1.2

-- TASK A
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
SELECT DISTINCT [year],
                [month],
                sub_category,
                COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
FROM table_trans
ORDER BY [year], [month], sub_category

-- TASK B
-- WITH table_trans AS (
-- SELECT transaction_id, sub_category,
--        YEAR(transaction_time) [year],
--        MONTH(transaction_time) [month]
-- FROM (
--     SELECT *
--     FROM fact_transaction_2019
--     UNION
--     SELECT *
--     FROM fact_transaction_2020) AS fact 
-- LEFT JOIN dim_scenario AS dsc 
-- ON fact.scenario_id = dsc.scenario_id
-- LEFT JOIN dim_status AS dst 
-- ON fact.status_id = dst.status_id
-- WHERE fact.status_id = 1 AND category = 'Billing'
-- ),
-- table_rank AS (
-- SELECT DISTINCT [year],
--                 [month],
--                 sub_category,
--                 COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
-- FROM table_trans
-- )
-- SELECT [year],
--        [month],
--        [Electricity],
--        [Internet],
--        [Water]
-- FROM table_rank
-- PIVOT (SUM(number_trans) FOR sub_category IN ([Electricity],[Internet],[Water])) AS Pivot_table     
-- ORDER BY [year], [month]


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

-- 1.3

-- WITH table_trans AS (
-- SELECT transaction_id, sub_category,
--        YEAR(transaction_time) [year],
--        MONTH(transaction_time) [month]
-- FROM (
--     SELECT *
--     FROM fact_transaction_2019
--     UNION
--     SELECT *
--     FROM fact_transaction_2020) AS fact 
-- LEFT JOIN dim_scenario AS dsc 
-- ON fact.scenario_id = dsc.scenario_id
-- LEFT JOIN dim_status AS dst 
-- ON fact.status_id = dst.status_id
-- WHERE fact.status_id = 1 AND category = 'Billing'
-- ),
-- table_rank AS (
-- SELECT DISTINCT [year],
--                 [month],
--                 sub_category,
--                 COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
-- FROM table_trans
-- ),
-- table_sub AS (
-- SELECT [year],
--        [month],
--        [Electricity],
--        [Internet],
--        [Water]
-- FROM table_rank
-- PIVOT (SUM(number_trans) FOR sub_category IN ([Electricity],[Internet],[Water])) AS Pivot_table     
-- )
-- SELECT *,
-- FORMAT(CAST([Electricity] AS decimal)/total_trans_month,'p') AS elec_pct, 
-- FORMAT(CAST([Internet] AS decimal)/total_trans_month,'p') AS internet_pct, 
-- FORMAT(CAST([Water] AS decimal)/total_trans_month,'p') AS water_pct
--  FROM (SELECT *,
--               SUM([Electricity]+[Internet]+[Water]) OVER (PARTITION BY [year],[month]) AS total_trans_month
--        FROM table_sub) table_total
       


-- WITH table_trans AS (
-- SELECT transaction_id, sub_category,
--        YEAR(transaction_time) [year],
--        MONTH(transaction_time) [month]
-- FROM (
--     SELECT *
--     FROM fact_transaction_2019
--     UNION
--     SELECT *
--     FROM fact_transaction_2020) AS fact 
-- LEFT JOIN dim_scenario AS dsc 
-- ON fact.scenario_id = dsc.scenario_id
-- LEFT JOIN dim_status AS dst 
-- ON fact.status_id = dst.status_id
-- WHERE fact.status_id = 1 AND category = 'Billing'
-- ),

-- table_sub AS (
-- SELECT [year],
--        [month],
--        [Electricity],
--        [Internet],
--        [Water]
-- FROM (
--     SELECT DISTINCT [year],
--                     [month],
--                     sub_category,
--                     COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
-- FROM table_trans) table_rank
-- PIVOT (SUM(number_trans) FOR sub_category IN ([Electricity],[Internet],[Water])) AS Pivot_table     
-- )

-- SELECT *,
-- FORMAT(CAST([Electricity] AS decimal)/total_trans_month,'p') AS elec_pct, 
-- FORMAT(CAST([Internet] AS decimal)/total_trans_month,'p') AS internet_pct, 
-- FORMAT(CAST([Water] AS decimal)/total_trans_month,'p') AS water_pct
--  FROM (SELECT *,
--               SUM([Electricity]+[Internet]+[Water]) OVER (PARTITION BY [year],[month]) AS total_trans_month
--        FROM table_sub) table_total



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
),

table_sub AS (
SELECT [year], [month], [Electricity], [Internet], [Water]
FROM (
    SELECT DISTINCT [year],
                    [month],
                    sub_category,
                    COUNT(transaction_id) OVER (PARTITION BY [year], [month], sub_category ) AS number_trans 
    FROM table_trans) table_rank
PIVOT (SUM(number_trans) FOR sub_category IN ([Electricity],[Internet],[Water])) AS Pivot_table )    

SELECT [year],[month],[Electricity],[Internet],[Water], total_trans_month,
FORMAT(CAST([Electricity] AS decimal)/total_trans_month,'p') AS elec_pct, 
FORMAT(CAST([Internet] AS decimal)/total_trans_month,'p') AS internet_pct, 
FORMAT(CAST([Water] AS decimal)/total_trans_month,'p') AS water_pct
 FROM (SELECT *,
              SUM([Electricity1]+[Internet1]+[Water1]) OVER (PARTITION BY [year],[month]) AS total_trans_month
       FROM (SELECT *,
                    ISNULL([Electricity],0) AS [Electricity1],
                    ISNULL([Internet],0) AS [Internet1],
                    ISNULL([Water],0) AS [Water1]
             FROM table_sub) table_null) table_total




























































