USE sanford;

SELECT *
FROM health;

#1
SELECT COUNT(*)
FROM health;

#2
SELECT COUNT(DISTINCT(id))
FROM health;

#3
SELECT sex,
	COUNT(*)
FROM health
GROUP BY sex
ORDER BY COUNT(*);

#4
SELECT sex,
	AVG(hypertension),
        AVG(vasc_disease),
        AVG(diabetes)
FROM health
GROUP BY sex
HAVING sex = 'Male' or sex = 'Female';

#5
SHOW FULL COLUMNS
FROM health;

SELECT DISTINCT(age)
FROM health;

#6
SELECT 10 + '90+';

#7
SELECT sex, hypertension,
	ROUND(0+AVG(age),2), COUNT(*)
FROM health
WHERE status = 'Alive' and sex != 'Unknown'
GROUP BY sex, hypertension
HAVING SUM(diabetes) >= 10000
ORDER BY sex, hypertension;

#8
SELECT COUNT(*)
FROM health
WHERE a1c IS NULL;

#9
SELECT a1c, COUNT(*)
FROM health
GROUP BY a1c
ORDER BY COUNT(*) DESC
LIMIT 4;

#10
SELECT visits_sched, COUNT(*)
FROM health
GROUP BY visits_sched
ORDER BY COUNT(*) DESC
LIMIT 20;

#11
SELECT COUNT(*)
FROM health
WHERE visits_sched IS NULL;

SELECT COUNT(*)
FROM health
WHERE visits_sched = 'NULL';

#12
SELECT COUNT(*)
FROM health
WHERE bmi IS NOT NULL AND
	visits_sched != 'NULL' AND
        visits_miss != '';
            
SELECT COUNT(*)
FROM health
WHERE visits_miss = '';

#13
SELECT payor, COUNT(*)
FROM health
WHERE visits_sched >= 10 AND
	visits_miss >= 0.5 * visits_sched AND
        status = 'Alive'
GROUP BY payor
ORDER BY COUNT(*) DESC;

#14
SELECT payor, ROUND(AVG(visits_miss/visits_sched),3)
FROM health
GROUP BY payor
ORDER BY ROUND(AVG(visits_miss/visits_sched),3) DESC;

#15
SELECT DISTINCT(payor)
FROM health;


SELECT CASE payor
		WHEN 'Medicaid' THEN 'Medicaid'
                ELSE 'nonMedicaid'
                END AS MedorNot,
                AVG(visits_miss/visits_sched) AS mean,
                VAR_SAMP(visits_miss/visits_sched) AS var,
                COUNT(*) AS count
FROM health
GROUP BY MedorNot;

SELECT 
    ROUND(
        ((AVG(CASE WHEN payor = 'Medicaid' THEN visits_miss / visits_sched END) 
            - AVG(CASE WHEN payor != 'Medicaid' THEN visits_miss / visits_sched END)) /
            SQRT((VAR_SAMP(CASE WHEN payor = 'Medicaid' THEN visits_miss / visits_sched END) / 
                    COUNT(CASE WHEN payor = 'Medicaid' THEN 1 END)) +
                (VAR_SAMP(CASE WHEN payor != 'Medicaid' THEN visits_miss / visits_sched END) / 
                    COUNT(CASE WHEN payor != 'Medicaid' THEN 1 END)))
        ), 2) AS Welch_t
FROM health;







#16
SELECT  CASE
                WHEN age >= 65 OR
			hypertension = 1 OR
                        vasc_disease = 1 OR
                        diabetes = 1 OR
                        bmi >= 30 THEN 'high_risk'
			ELSE 'low_risk'
                END AS risk_group,
                COUNT(*),
                SUM(CASE
			WHEN smoke = 1 THEN 1
                        ELSE 0
                        END) AS current_smoke
FROM health
GROUP BY risk_group
ORDER BY risk_group DESC;

#17
USE pir;

SHOW FULL COLUMNS FROM five_ep;

SELECT *
FROM five_ep;

SELECT price - eventAmount AS diff
FROM five_ep
WHERE eventType = 'Bidders Row' AND
	win != 1.0 AND
        eventAmount < price
ORDER BY diff
LIMIT 1;

#18
SELECT date, name,
	COUNT(*),
        AVG(ABS(price - eventAmount)) AS avg_diff,
        SUM(win) AS if_win
FROM five_ep
WHERE eventType = 'Bidders Row'
GROUP BY date, name
HAVING if_win = 0.0
ORDER BY avg_diff
LIMIT 1;

#19
SELECT date, eventTypeCounter,
	MIN(eventAmount-price) AS min_diff,
	SUM(CASE
		WHEN eventAmount < price THEN 1
                ELSE 0
                END) AS num_less
FROM five_ep
WHERE eventType = 'Bidders Row' AND
	eventOrder != 4
GROUP BY date, eventTypeCounter
HAVING num_less = 0;



