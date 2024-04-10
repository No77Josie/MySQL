USE pir;

SELECT *
FROM five_ep;

#1
SELECT date,
				CASE 
                WHEN eventTypeCounter<=3 THEN 'first_half'
                WHEN eventTypeCounter>3 THEN 'second_half'
                ELSE NULL
                END AS show_half,
                SUM(CASE
						WHEN prize LIKE '%car%' THEN 1
                        ELSE 0
                        END) AS count_car
FROM five_ep
WHERE eventType = 'Pricing Game'
GROUP BY date, show_half;

#2
SELECT date, name,
				SUM(price) AS total_values,
                AVG(price) AS avg_values
FROM five_ep
WHERE win = 1.0
GROUP BY date, name
HAVING name IN (SELECT name
								FROM five_ep
                                WHERE win = 1.0 AND eventType = 'Showcase Showdown');

#3
USE sanford;

SELECT * 
FROM health;

SELECT CASE
				WHEN sbp > 180 OR dbp > 120 THEN 'Hypertensive Crisis'
                WHEN (sbp >= 140 AND sbp <= 180) OR (dbp >= 90 AND dbp <= 120) THEN 'Hypertension Stage 2'
                WHEN (sbp >= 130 AND sbp <= 139) OR (dbp >= 80 AND dbp <= 89) THEN 'Hypertension Stage 1'
                WHEN (sbp >= 120 AND sbp <= 129) AND (dbp >= 0 AND dbp < 80) THEN 'Elevated'
                WHEN (sbp >= 0 AND sbp < 120) AND (dbp >= 0 AND dbp < 80) THEN 'Normal'
                ELSE NULL
                END AS BP_Group,
                COUNT(*) AS Total_Patients,
                ROUND(AVG(bmi),2) AS Avg_BMI
FROM health
WHERE status = 'Alive'
GROUP BY BP_Group
ORDER BY Avg_BMI DESC;

#4
USE yelp;

SELECT *
FROM business;

SELECT (SELECT COUNT(*)
				FROM business
				WHERE categories LIKE '%Pizza%' AND
								LENGTH(categories) - LENGTH(REPLACE(categories, ',', ''))<=2)
                /COUNT(*) AS percentage
FROM business
WHERE categories LIKE '%Pizza%';

SELECT 
  (filtered.count / total.count) * 100 AS percentage
FROM 
  (SELECT COUNT(*) as count FROM business WHERE categories LIKE '%Pizza%') AS total
INNER JOIN 
  (SELECT COUNT(*) as count FROM business WHERE categories LIKE '%Pizza%' AND 
    LENGTH(categories) - LENGTH(REPLACE(categories, ', ', '')) <= 2) AS filtered ON 1=1;

#5
SELECT COUNT(DISTINCT(categories))
FROM business
WHERE categories LIKE '%Pizza%' AND
				categories LIKE '%Restaurants%' AND
                categories LIKE '%Italian%';
                
#6
SELECT COUNT(*)
FROM(
SELECT categories, AVG(review_count)
FROM business
WHERE categories LIKE '%Pizza%' AND
				categories LIKE '%Restaurants%' AND
                categories LIKE '%Italian%'
GROUP BY categories
HAVING AVG(review_count) > 
				(SELECT AVG(review_count)
					FROM business)) AS a;

#7
SELECT *
FROM user;

EXPLAIN user;

SELECT CASE
				WHEN elite IS NOT NULL THEN 'yes_elite'
                ELSE 'no_elite'
                END AS elite_group,
                CASE
                WHEN DATEDIFF('2022-01-01', yelping_since) <= 1000 THEN 'group1'
                WHEN DATEDIFF('2022-01-01', yelping_since) < 3000  AND 
							DATEDIFF('2022-01-01', yelping_since) > 1000 THEN 'group2'
				WHEN DATEDIFF('2022-01-01', yelping_since) >= 3000 THEN 'group3'
                ELSE NULL
                END AS tenure,
                COUNT(*)
FROM user
GROUP BY elite_group, tenure
ORDER BY tenure, elite_group;

#8
SELECT COUNT(*)
FROM business
WHERE LENGTH(name) - LENGTH(REPLACE(name, ' ', ''))=1 AND
				LENGTH(SUBSTRING_INDEX(name,' ',-1))>LENGTH(SUBSTRING_INDEX(name,' ',1));

#9
USE airline_ontime;

SELECT *
FROM ontime;

SELECT AVG(DepDelay), AVG(ArrDelay)
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0;

#10
SELECT	AVG(DepTime - CRSDepTime)
FROM		ontime
WHERE	Cancelled = 0 AND 
				Diverted = 0;

EXPLAIN ontime;

SELECT	DepTime, CRSDepTime, DepTime - CRSDepTime AS delay, DepDelay
FROM		ontime
WHERE	Cancelled = 0 AND 
				Diverted = 0 AND
                DepTime - CRSDepTime != DepDelay;
                
#11
SELECT DepTime, 
			   STR_TO_DATE(CONCAT(SUBSTRING(DepTime, 1,LENGTH(DepTime)-2), ':', RIGHT(DepTime, 2)), '%H:%i') AS NewDT,
				CRSDepTime,
                STR_TO_DATE(CONCAT(SUBSTRING(CRSDepTime, 1,LENGTH(CRSDepTime)-2), ':', RIGHT(CRSDepTime, 2)), '%H:%i') AS NewCRSDT
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0
LIMIT 10;

#12
SELECT AVG(DepDelay),
				AVG(TIMESTAMPDIFF(MINUTE,
                STR_TO_DATE(CONCAT(SUBSTRING(CRSDepTime, 1,LENGTH(CRSDepTime)-2), ':', RIGHT(CRSDepTime, 2)), '%H:%i'),
			   STR_TO_DATE(CONCAT(SUBSTRING(DepTime, 1,LENGTH(DepTime)-2), ':', RIGHT(DepTime, 2)), '%H:%i'))) AS cal_avgDelay
FROM ontime
WHERE Cancelled = 0 AND 
				Diverted = 0 AND
                CRSDepTime >= 800 AND
                CRSDepTime <= 1600 AND
                DepDelay <= 240;

#13
SELECT SUM(Distance)
FROM ontime
WHERE Month = 9 AND
				DayofMonth = 19 AND
                Origin = 'RDU' AND
                Cancelled = 0 AND
                Diverted = 0;

#14
SELECT UniqueCarrier, COUNT(*)
FROM ontime
WHERE Cancelled = 0 AND
				Diverted = 0 AND
                (Origin = 'SFO' AND Dest = 'LAX' AND DayOfWeek = 5 AND DepTime > 1700 AND DepTime < 2000) OR
                (Origin = 'LAX' AND Dest = 'SFO' AND DayOfWeek = 7 AND DepTime > 1700 AND DepTime < 2000) 
GROUP BY UniqueCarrier;

SELECT UniqueCarrier, 
				COUNT(*) / (SELECT COUNT(*)
									FROM ontime
									WHERE Cancelled = 0 AND
													Diverted = 0 AND
													(Origin = 'SFO' AND Dest = 'LAX' AND DayOfWeek = 5 AND DepTime > 1700 AND DepTime < 2000) OR
													(Origin = 'LAX' AND Dest = 'SFO' AND DayOfWeek = 7 AND DepTime > 1700 AND DepTime < 2000) 
									) +
				SUM(CASE
						WHEN ArrDelay < 60 THEN 1
                        ELSE 0 END)/COUNT(*) AS score
FROM ontime
WHERE Cancelled = 0 AND
				Diverted = 0 AND
                (Origin = 'SFO' AND Dest = 'LAX' AND DayOfWeek = 5 AND DepTime > 1700 AND DepTime < 2000) OR
                (Origin = 'LAX' AND Dest = 'SFO' AND DayOfWeek = 7 AND DepTime > 1700 AND DepTime < 2000) 
GROUP BY UniqueCarrier
ORDER BY score DESC;

#15

SELECT *
FROM ontime;

SELECT WEEK(CONCAT(Year,'-',Month,'-',DayofMonth)) AS week_number,
				DATE_ADD(STR_TO_DATE('2006-12-31','%Y-%m-%d'), INTERVAL WEEK(CONCAT(Year,'-',Month,'-',DayofMonth)) WEEK) AS start_date,
                DATE_ADD(STR_TO_DATE('2007-1-6','%Y-%m-%d'), INTERVAL WEEK(CONCAT(Year,'-',Month,'-',DayofMonth)) WEEK) AS end_date,
				COUNT(*) AS count
FROM ontime
WHERE Cancelled = 1
GROUP BY week_number
ORDER BY COUNT(*) DESC
LIMIT 10;









