#1
USE pir;

SELECT *
FROM five_ep;

WITH 
A AS(
SELECT date, name, SUM(price) AS tot_winnings
FROM five_ep
WHERE win = 1.0
GROUP BY date, name),
B AS(
SELECT date, MAX(tot_winnings) AS tot_winnings
FROM A
GROUP BY date)
SELECT A.*
FROM A
INNER JOIN B
ON A.date = B.date AND A.tot_winnings = B.tot_winnings;

#2
SELECT * , 
	CASE WHEN eventAmount
FROM five_ep
WHERE eventType = 'Big Wheel'
ORDER BY date, name;

WITH
A AS (
SELECT *
FROM five_ep
WHERE eventType = 'Big Wheel' ),
B AS (
SELECT date, name, MIN(eventOrder) AS min_order
FROM five_ep
WHERE eventType = 'Big Wheel'
GROUP BY date, name)

SELECT MAX(eventAmount) AS highest_first_spin
FROM A
INNER JOIN(
SELECT A.date, A.name, B.min_order
FROM A
INNER JOIN B
ON A.date = B.date AND
	A.name = B.name AND
        A.eventOrder <= B.min_order + 1
GROUP BY A.date, A.name
HAVING SUM(eventAmount) <= 1 AND COUNT(*) > 1) AS C
ON A.date = C.date AND
	A.name = C.name AND
        A.eventOrder = C.min_order;

#3
SELECT CASE win
		WHEN 1.0 THEN 'bidder4_wins'
                ELSE 'bidder4_loses'
                END AS outcome_group,
                COUNT(*) AS n_times,
                COUNT(*)/SUM(COUNT(*)) OVER() AS percent_total
FROM
(
SELECT date, name, eventAmount, eventOrder, eventTypeCounter, win
FROM five_ep
WHERE eventType = 'Bidders Row' AND eventOrder = 4
) AS A
INNER JOIN
(
SELECT date, eventTypeCounter, MAX(eventAmount) AS max_three
FROM five_ep
WHERE eventType = 'Bidders Row' AND eventOrder != 4
GROUP BY date, eventTypeCounter
) AS B
ON A.date = B.date AND
	A.eventTypeCounter = B.eventTypeCounter AND
        A.eventAmount = B.max_three + 1
GROUP BY outcome_group;

#4
WITH
A AS(
SELECT date, name, eventType, MIN(eventTypeCounter) AS min_order
FROM five_ep
WHERE eventType = 'Bidders Row'
GROUP BY date, name
HAVING COUNT(*)>1),
B AS(
SELECT D.date, D.name, ABS(D.eventAmount - D.price) AS diff1
FROM five_ep AS D
INNER JOIN A
ON A.date = D.date AND
		A.name = D.name AND
        A.eventType = D.eventType AND
        A.min_order = D.eventTypeCounter),
C AS(
SELECT D.date, D.name, ABS(D.eventAmount - D.price) AS diff2
FROM five_ep AS D
INNER JOIN A
ON A.date = D.date AND
	A.name = D.name AND
        A.eventType = D.eventType AND
        A.min_order + 1 = D.eventTypeCounter),
E AS (
SELECT B.date, B.name, B.diff1, C.diff2
FROM B
LEFT JOIN C
ON B.date = C.date AND
	B.name = C.name)

SELECT
(SELECT COUNT(*)
FROM E
WHERE diff2 < diff1)/COUNT(*) AS percentage
FROM E;

#5
USE airline_ontime;

SELECT *
FROM ontime;

SELECT *
FROM airports;

SELECT COUNT(*)
FROM ontime;

SELECT COUNT(*)
FROM ontime AS A
INNER JOIN airports AS B
ON A.Origin = B.IATA;

SELECT COUNT(*)
FROM ontime AS A
INNER JOIN airports AS B
ON A.Dest = B.IATA;

#6
SELECT Country, name, COUNT(*) AS Total_Rec
FROM(
SELECT *
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0) AS A
LEFT JOIN(
SELECT *
FROM airports) AS B
ON A.Origin = B.IATA
WHERE Country != 'United States'
GROUP BY Country, name
ORDER BY Total_Rec DESC;

#7
WITH
A AS(
SELECT Origin, Dest, COUNT(*) AS Total_Flights
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0 AND
	Origin IN (SELECT IATA
			FROM airports
                        WHERE Country = 'United States')
GROUP BY Origin, Dest
ORDER BY Total_Flights DESC
LIMIT 10),
B AS (
SELECT IATA, REPLACE(Name,' Airport', '') AS Name
FROM airports)

SELECT Depart_Name, B.Name AS Arrive_Name, Total_Flights
FROM
(
SELECT B.Name AS Depart_Name, A.Dest, A.Total_Flights
FROM A
LEFT JOIN B
ON A.Origin = B.IATA) AS C
LEFT JOIN B
ON C.Dest = B.IATA;

#8
WITH
A AS(
SELECT IATA, Altitude
FROM airports
WHERE Country = 'United States'),
B AS(
SELECT *
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0)
        
SELECT COUNT(*)
FROM B
WHERE CONCAT(TRIM(Origin),TRIM(Dest)) IN (
					SELECT CONCAT(TRIM(A.IATA),TRIM(C.IATA))
					FROM A
					INNER JOIN A AS C
					ON A.IATA != C.IATA AND
						ABS(A.Altitude - C.Altitude) >= 3000);

#9
WITH
A AS(
SELECT IATA, Altitude
FROM airports
WHERE Country = 'United States'),
B AS(
SELECT Origin, Dest
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0)

SELECT 
(SELECT COUNT(*)
FROM B
WHERE CONCAT(TRIM(Origin),TRIM(Dest)) IN (
					SELECT CONCAT(TRIM(A.IATA),TRIM(C.IATA))
					FROM A
					INNER JOIN A AS C
					ON A.IATA != C.IATA AND
						ABS(A.Altitude - C.Altitude) >= 3000))/COUNT(*) AS percentage
FROM B
WHERE Origin IN (
SELECT IATA
FROM airports
WHERE Country = 'United States') AND
Dest IN (
SELECT IATA
FROM airports
WHERE Country = 'United States');



	
SELECT  
(
SELECT COUNT(*)
FROM B
WHERE CONCAT(TRIM(Origin),TRIM(Dest)) IN (
SELECT CONCAT(TRIM(A.IATA),TRIM(C.IATA))
FROM A
INNER JOIN A AS C
ON A.IATA != C.IATA AND
		ABS(A.Altitude - C.Altitude) >= 3000) OR 
		CONCAT(TRIM(Dest),TRIM(Origin)) IN (
SELECT CONCAT(TRIM(A.IATA),TRIM(C.IATA))
FROM A
INNER JOIN A AS C
ON A.IATA != C.IATA AND
	ABS(A.Altitude - C.Altitude) >= 3000))/COUNT(*)
FROM B
INNER JOIN A
ON B.Origin = A.IATA
INNER JOIN A AS D
ON B.Dest = D.IATA;

#10
SELECT *
FROM airports;
#11
SELECT A.*,
		CASE
				WHEN B.Timezone = 'America/New_York' THEN 1
				WHEN B.Timezone = 'America/Chicago' THEN 2
				WHEN (B.Timezone = 'America/Denver' OR B.Timezone = 'America/Phoenix') THEN 3
				WHEN B.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num1,
                CASE
				WHEN C.Timezone = 'America/New_York' THEN 1
				WHEN C.Timezone = 'America/Chicago' THEN 2
				WHEN (C.Timezone = 'America/Denver' OR C.Timezone = 'America/Phoenix') THEN 3
				WHEN C.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num2
FROM ontime AS A
LEFT JOIN airports AS B
ON A.Origin = B.IATA
LEFT JOIN airports AS C
ON A.Dest = C.IATA
WHERE A.Cancelled = 0 AND
		A.Diverted = 0 AND
                B.Country = 'United States' AND
                C.Country = 'United States';



#12
SELECT CASE 
                WHEN ABS(TZ_Num1 - TZ_Num2) >= 2 THEN 'Yes'
                WHEN ABS(TZ_Num1 - TZ_Num2) < 2 THEN 'No'
                ELSE 'NULL'
                END AS Three_TZ_Flight, COUNT(*)
FROM
(SELECT A.*,
		CASE
				WHEN B.Timezone = 'America/New_York' THEN 1
				WHEN B.Timezone = 'America/Chicago' THEN 2
				WHEN (B.Timezone = 'America/Denver' OR B.Timezone = 'America/Phoenix') THEN 3
				WHEN B.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num1,
                CASE
				WHEN C.Timezone = 'America/New_York' THEN 1
				WHEN C.Timezone = 'America/Chicago' THEN 2
				WHEN (C.Timezone = 'America/Denver' OR C.Timezone = 'America/Phoenix') THEN 3
				WHEN C.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num2
FROM ontime AS A
LEFT JOIN airports AS B
ON A.Origin = B.IATA
LEFT JOIN airports AS C
ON A.Dest = C.IATA
WHERE A.Cancelled = 0 AND
		A.Diverted = 0 AND
                B.Country = 'United States' AND
                C.Country = 'United States') AS C
GROUP BY Three_TZ_Flight;


SELECT
    CASE
        WHEN ABS(Origin_TZ_Num - Dest_TZ_Num) >= 3 THEN 'Yes'
        WHEN ABS(Origin_TZ_Num - Dest_TZ_Num) < 3 THEN 'No'
        ELSE 'NULL'
    END AS Three_TZ_Flight,
    COUNT(*) 
FROM (
    SELECT 
        ot.*,
        CASE 
            WHEN apd.timezone = 'America/New_York' THEN 1
            WHEN apd.timezone = 'America/Chicago' THEN 2
            WHEN (apd.timezone = 'America/Denver' OR apd.timezone = 'America/Phoenix') THEN 3
            WHEN apd.timezone = 'America/Los_Angeles' THEN 4
            ELSE NULL
        END AS Origin_TZ_Num,
        CASE 
            WHEN apa.timezone = 'America/New_York' THEN 1
            WHEN apa.timezone = 'America/Chicago' THEN 2
            WHEN (apa.timezone = 'America/Denver' OR apa.timezone = 'America/Phoenix') THEN 3
            WHEN apa.timezone = 'America/Los_Angeles' THEN 4
            ELSE NULL
        END AS Dest_TZ_Num
    FROM ontime ot
    JOIN airports apd ON ot.Origin = apd.IATA
    JOIN airports apa ON ot.Dest = apa.IATA
    WHERE ot.Cancelled = 0 
        AND ot.Diverted = 0
        AND apd.Country = 'United States'
        AND apa.Country = 'United States'
) AS FlightData
GROUP BY Three_TZ_Flight
ORDER BY Three_TZ_Flight DESC;





SELECT A.*,
		CASE
				WHEN B.Timezone = 'America/New_York' THEN 1
				WHEN B.Timezone = 'America/Chicago' THEN 2
				WHEN (B.Timezone = 'America/Denver' OR B.Timezone = 'America/Phoenix') THEN 3
				WHEN B.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num1,
                CASE
				WHEN C.Timezone = 'America/New_York' THEN 1
				WHEN C.Timezone = 'America/Chicago' THEN 2
				WHEN (C.Timezone = 'America/Denver' OR C.Timezone = 'America/Phoenix') THEN 3
				WHEN C.Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num2
FROM ontime AS A
LEFT JOIN airports AS B
ON A.Origin = B.IATA
LEFT JOIN airports AS C
ON A.Dest = C.IATA
WHERE A.Cancelled = 0 AND
		A.Diverted = 0 AND
                B.Country = 'United States' AND
                C.Country = 'United States';


WITH
A AS(
SELECT CASE
				WHEN Timezone = 'America/New_York' THEN 1
				WHEN Timezone = 'America/Chicago' THEN 2
				WHEN (Timezone = 'America/Denver' OR Timezone = 'America/Phoenix') THEN 3
				WHEN Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num, IATA
FROM airports
WHERE Country = 'United States'),
B AS
(SELECT *
FROM ontime
WHERE Cancelled = 0 AND Diverted = 0 AND
				Origin IN (SELECT IATA
						FROM airports
                                		WHERE Country = 'United States') AND
				Dest IN (SELECT IATA
						FROM airports
                                		WHERE Country = 'United States'))

SELECT CASE
		WHEN ABS(TZ_Num1 - A.TZ_Num) >= 2 THEN 'Yes'
                WHEN ABS(TZ_Num1 - A.TZ_Num) < 2 THEN 'No'
                ELSE NULL
                END AS Three_TZ_Flight,
                COUNT(*)
FROM
(
SELECT B.*, A.TZ_Num AS TZ_Num1
FROM B
LEFT JOIN A
ON B.Origin = A.IATA) AS C
LEFT JOIN A
ON C.Dest = A.IATA
GROUP BY Three_TZ_Flight;




WITH
A AS(
SELECT CASE
				WHEN Timezone = 'America/New_York' THEN 1
				WHEN Timezone = 'America/Chicago' THEN 2
				WHEN (Timezone = 'America/Denver' OR Timezone = 'America/Phoenix') THEN 3
				WHEN Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num, IATA
FROM airports
WHERE Country = 'United States'),
B AS(
SELECT C.TZ_Num1, A.TZ_Num AS TZ_Num2
FROM
(
SELECT B.*, A.TZ_Num AS TZ_Num1
FROM ontime AS B
LEFT JOIN A
ON B.Origin = A.IATA) AS C
LEFT JOIN A
ON C.Dest = A.IATA)

SELECT *
FROM B;




WITH
A AS(
SELECT CASE
				WHEN Timezone = 'America/New_York' THEN 1
				WHEN Timezone = 'America/Chicago' THEN 2
				WHEN Timezone = 'America/Denver' OR Timezone = 'America/Phoenix' THEN 3
				WHEN Timezone = 'America/Los_Angeles' THEN 4
				ELSE NULL
				END AS TZ_Num, IATA
FROM airports
WHERE Country = 'United States')

SELECT CASE
		WHEN ABS(TZ_Num1 - A.TZ_Num) >= 2 THEN 'Yes'
                WHEN ABS(TZ_Num1 - A.TZ_Num) < 2 THEN 'No'
                ELSE NULL
                END AS Three_TZ_Flight,
                COUNT(*)
FROM
(
SELECT B.*, A.TZ_Num AS TZ_Num1
FROM ontime AS B
LEFT JOIN A
ON B.Origin = A.IATA) AS C
LEFT JOIN A
ON C.Dest = A.IATA
GROUP BY Three_TZ_Flight;


SELECT CASE
		WHEN ABS(TZ_Num1 - TZ_Num2) >= 2 THEN 'Yes'
                WHEN ABS(TZ_Num1 - TZ_Num2) < 2 THEN 'No'
                ELSE NULL
                END AS Three_TZ_Flight,
                COUNT(*)
FROM B
GROUP BY Three_TZ_Flight;

#13

SELECT *
FROM ontime;

SELECT COUNT(*)
FROM
(SELECT Origin, Dest
FROM ontime
WHERE Cancelled = 0 AND 
		Diverted = 0 AND
                Origin = 'RDU'
GROUP BY Origin, Dest
HAVING COUNT(*) >= 300) AS A
INNER JOIN(
SELECT Origin, Dest
FROM ontime
WHERE Cancelled = 0 AND 
		Diverted = 0 AND
                Dest = 'SFO'
GROUP BY Origin, Dest
HAVING COUNT(*) >= 300) AS B
ON A.Dest = B.Origin;

#14
USE yelp;

SELECT review_groups,
	COUNT(*)/SUM(COUNT(*)) OVER() AS percent_total
FROM
(
SELECT A.business_id,
	CASE
                WHEN count >= 1 THEN 'at_least_one'
                ELSE 'zero'
                END AS review_groups
FROM
(SELECT *
FROM business
WHERE is_open = 1) AS A
LEFT JOIN(
SELECT business_id, COUNT(*) AS count
FROM review
WHERE date >= '2019-10-01'
GROUP BY business_id) AS B
ON A.business_id = B.business_id
GROUP BY A.business_id) AS C
GROUP BY review_groups;



