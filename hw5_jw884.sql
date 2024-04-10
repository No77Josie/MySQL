USE airline_ontime;

SELECT *
FROM airports;

SELECT *
FROM ontime;

EXPLAIN ontime;

#1
SELECT 	UniqueCarrier,
	SUM(CASE WHEN ArrDelay<60 THEN 1 ELSE 0 END)/COUNT(*) + COUNT(*)/SUM(COUNT(*)) OVER() AS score
FROM 	ontime
WHERE 	Cancelled = 0 AND
	Diverted = 0 AND
	(Origin = 'SFO' AND Dest = 'LAX' AND DayOfWeek = 5 AND DepTime > 1700 AND DepTime < 2000) OR 
        (Origin = 'LAX' AND Dest = 'SFO' AND DayOfWeek = 7 AND DepTime > 1700 AND DepTime < 2000)
GROUP BY UniqueCarrier
ORDER BY score DESC;

#2
USE pir;

SELECT *
FROM five_ep;

WITH A AS(
SELECT date, name, SUM(price) AS tot_winnings,
				MAX(SUM(price)) OVER(PARTITION BY date) AS max_tot
FROM 	five_ep
WHERE 	win = 1.0
GROUP BY date, name)

SELECT 	date, name, tot_winnings
FROM 	A
WHERE 	tot_winnings = max_tot
ORDER BY date;

#3
WITH A
AS(
SELECT 	date, name, eventAmount, eventOrder, 
	SUM(eventAmount) OVER(PARTITION BY date, name ORDER BY eventOrder) AS tot,
	SUM(eventAmount) OVER(PARTITION BY date, name ORDER BY eventOrder ROWS BETWEEN 1 PRECEDING AND 1 PRECEDING) AS pre_tot,
        rank() OVER(PARTITION BY date, name ORDER BY eventOrder) AS rank
FROM 	five_ep
WHERE 	eventType = 'Big Wheel')

SELECT 	MAX(pre_tot) AS highest_first_spin
FROM 	A
WHERE 	rank = 2 AND tot < 1;

#4
WITH A AS(
SELECT 	*,
	ABS(eventAmount-price) AS diff,
        COUNT(*) OVER(PARTITION BY date, name) AS count,
        rank() OVER(PARTITION BY date, name ORDER BY eventTypeCounter) AS rank
FROM 	five_ep
WHERE 	eventType = 'Bidders Row'
ORDER BY date, name
),
B AS(
SELECT 	*,
	LAG(diff) OVER(PARTITION BY date, name ORDER BY rank) AS pre_diff
FROM 	A
WHERE 	count > 1)

SELECT 	SUM(CASE WHEN diff < pre_diff THEN 1 ELSE 0 END)/COUNT(*) AS percentage
FROM 	B
WHERE 	rank = 2;

#5
WITH A AS(
SELECT 	*,
	ABS(eventAmount-Price) AS accuracy,
        COUNT(*) OVER(PARTITION BY date, name) AS count,
        rank() OVER(PARTITION BY date, name ORDER BY eventTypeCounter) AS rank
FROM 	five_ep
WHERE 	eventType = 'Bidders Row'
),
B AS(
SELECT 	*,
	accuracy - LAG(accuracy) OVER(PARTITION BY date, name ORDER BY rank) AS diff
FROM 	A
WHERE 	count>1),
C AS
(SELECT *,
	SUM(CASE WHEN diff<=0 THEN 1 ELSE 0 END) OVER(PARTITION BY date, name) AS if_less_accurate
FROM 	B),
D AS(
SELECT 	date, name, count
FROM 	C
WHERE 	if_less_accurate = count-1
GROUP BY date, name)

SELECT COUNT(*) AS num_less_accurate,
		AVG(count) AS avg_bids,
                (SELECT COUNT(*)
FROM 	C
WHERE 	count = rank AND win = 1.0 AND if_less_accurate = count-1)/COUNT(*) AS win_perc
FROM 	D;

#6
USE airline_ontime;

SELECT 	A.UniqueCarrier, COUNT(*), AVG(Tot_Dist)
FROM
(
SELECT 	TailNum, 
        DATE(CONCAT(Year,'-',Month,'-',DayofMonth)) AS DateField, 
        UniqueCarrier,
        SUM(Distance) AS Tot_Dist
FROM 	ontime
WHERE 	TailNum LIKE 'N%' AND
        Cancelled = 0 AND
        Diverted = 0
GROUP BY TailNum, DateField, UniqueCarrier
) AS A

INNER JOIN

(
SELECT 	TailNum, 
        DATE(CONCAT(Year,'-',Month,'-',DayofMonth)) AS DateField,
        COUNT(DISTINCT(UniqueCarrier)) AS Num_Car
FROM 	ontime
WHERE 	TailNum LIKE 'N%' AND
        Cancelled = 0 AND
        Diverted = 0
GROUP BY TailNum, DateField
HAVING 	Num_Car = 1
) AS B

ON A.TailNum = B.TailNum AND A.DateField = B.DateField
GROUP BY A.UniqueCarrier;

# new method:
WITH A AS (
  SELECT
    TailNum,
    DATE(CONCAT(Year, '-', Month, '-', DayofMonth)) AS DateField,
    UniqueCarrier,
    SUM(Distance) AS Tot_Dist
  FROM ontime
  WHERE
    TailNum LIKE 'N%'
    AND Cancelled = 0
    AND Diverted = 0
)

SELECT UniqueCarrier, COUNT(*) AS count, AVG(Tot_Dist) AS avg_dist
FROM (
  SELECT	A.*, COUNT(DISTINCT UniqueCarrier) AS carrier_count
  FROM 		A
  GROUP BY 	TailNum, DateField
) AS B
WHERE carrier_count = 1
GROUP BY UniqueCarrier;





USE airline_ontime;
WITH A AS
(SELECT	STR_TO_DATE(concat(Year,'-',Month,'-',DayofMonth), '%Y-%m-%d') AS date, 
	UniqueCarrier, 
        TailNum, 
        Distance, 
	row_number() OVER(PARTITION BY date, TailNum, UniqueCarrier) AS row_num, 
        COUNT(*) OVER(PARTITION BY date, TailNum) AS day_count
FROM	ontime
WHERE	TailNum like 'N%' AND Cancelled=0 AND Diverted=0),
B AS
(SELECT	A.*, 
	MAX(A.row_num) OVER(PARTITION BY A.date, A.TailNum, A.UniqueCarrier) AS max_num
FROM	A),
C AS
(SELECT	B.date, B.UniqueCarrier, COUNT(B.UniqueCarrier) AS Carr_cnt, SUM(B.Distance)/COUNT(DISTINCT B.TailNum) AS avg_day_cnt
FROM	B
WHERE	B.max_num=B.day_count
GROUP BY B.date, B.UniqueCarrier)

SELECT	C.UniqueCarrier, SUM(C.Carr_cnt) AS Car_sum, AVG(C.avg_day_cnt) AS avg_fly_day
FROM	C
GROUP BY C.UniqueCarrier;


WITH A AS
(SELECT	STR_TO_DATE(concat(Year,'-',Month,'-',DayofMonth), '%Y-%m-%d') AS date, 
	UniqueCarrier, 
	TailNum, 
        Distance, 
	row_number() OVER(PARTITION BY date, TailNum, UniqueCarrier) AS row_num, 
        COUNT(*) OVER(PARTITION BY date, TailNum) AS day_count
FROM	ontime
WHERE	TailNum like 'N%' AND Cancelled=0 AND Diverted=0),
B AS
(SELECT	A.*, 
	MAX(A.row_num) OVER(PARTITION BY A.date, A.TailNum, A.UniqueCarrier) AS max_num
FROM	A),
C AS
(SELECT	B.date, B.UniqueCarrier, B.TailNum, SUM(Distance) AS tot_dist
FROM	B
WHERE	B.max_num=B.day_count
GROUP BY B.date, B.UniqueCarrier, B.TailNum)

SELECT UniqueCarrier, COUNT(*) AS count, AVG(tot_dist) AS avg_tot_dist
FROM C
GROUP BY UniqueCarrier;


#7
WITH A AS(
SELECT CASE WHEN Month = 1 THEN 'January'
		WHEN Month = 2 THEN 'February'
                WHEN Month = 3 THEN 'March'
                WHEN Month = 4 THEN 'April'
                WHEN Month = 5 THEN 'May'
                WHEN Month = 6 THEN 'June'
                WHEN Month = 7 THEN 'July'
                WHEN Month = 8 THEN 'August'
                WHEN Month = 9 THEN 'September'
                WHEN Month = 10 THEN 'October'
                WHEN Month = 11 THEN 'November'
                WHEN Month = 12 THEN 'December'
                ELSE NULL END AS Month_String,
                Origin,
		Month,
		AVG(DepDelay) AS avg_depdelay,
                COUNT(*) AS count,
                MIN(COUNT(*)) OVER(PARTITION BY Month_String, Origin) AS min_count
FROM 	ontime
WHERE 	Cancelled = 0 AND Diverted = 0
GROUP BY Month_String, Origin),
B AS(
SELECT 	*, rank() OVER(PARTITION BY Month_String ORDER BY avg_depdelay DESC) AS rank
FROM 	A
WHERE 	min_count >= 1000)

SELECT 	C.Month_String, D.name, C.rank
FROM
(
SELECT 	*
FROM 	B
WHERE 	rank <= 2) AS C
INNER JOIN airports AS D
ON 	C.Origin = D.IATA
ORDER BY C.Month, C.rank;


#8
USE yelp;


WITH A AS(
SELECT 	*,
	COUNT(*) OVER(PARTITION BY user_id) AS count,
	dense_rank() OVER(PARTITION BY user_id ORDER BY date) AS rank
FROM 	review),
B AS(
SELECT 	*,
	DATEDIFF(date,LAG(date) OVER(PARTITION BY user_id ORDER BY date)) AS date_diff
FROM 	A
WHERE 	count >= 10 AND (rank = 1 OR rank = 10))

SELECT 	AVG(date_diff) AS avg_time
FROM 	B
WHERE 	rank = 10;


#9
USE yelp;
SELECT 	*
FROM 	business;


WITH C AS(
SELECT 	user_id, date, B.stars,
	COUNT(*) OVER(PARTITION BY A.user_id) AS count,
        dense_rank() OVER(PARTITION BY A.user_id ORDER BY A.date) AS rank
FROM 	review AS A
LEFT JOIN business AS B
ON 	A.business_id = B.business_id),
D AS(
SELECT 	*,
	rank - 1 AS new_rank,
	DATEDIFF(date,LAG(date) OVER(PARTITION BY user_id ORDER BY date)) AS date_diff
FROM 	C
WHERE 	count>=10 AND rank<=10),
E AS(
SELECT 	user_id, CASE WHEN stars > 3 THEN 'High'
										ELSE 'Low' END AS user_group
FROM 	C
WHERE 	count>=10 AND rank = 1)

SELECT 	new_rank,
	SUM(CASE WHEN user_group = 'Low' THEN date_diff ELSE 0 END)/
        SUM(CASE WHEN user_group = 'Low' THEN 1 ELSE 0 END) AS AvgTimeTilNextLow,
        SUM(CASE WHEN user_group = 'High' THEN date_diff ELSE 0 END)/
        SUM(CASE WHEN user_group = 'High' THEN 1 ELSE 0 END) AS AvgTimeTilNextHigh
FROM 	D
LEFT JOIN E
ON 	D.user_id = E.user_id
GROUP BY new_rank
HAVING 	new_rank>0;


#10
USE simpsons;

SELECT *
FROM script_lines;

SELECT *
FROM locations;

SELECT *
FROM episodes;

WITH A AS(
SELECT 	*,
	(CHAR_LENGTH(normalized_text) - CHAR_LENGTH(REPLACE(normalized_text, 'beer', '')))/4 +
        (CHAR_LENGTH(normalized_text) - CHAR_LENGTH(REPLACE(normalized_text, 'duff', '')))/4 AS count
FROM 	script_lines
WHERE 	character_id = 2),
B AS(
SELECT 	*,
	SUM(count) OVER(ORDER BY id) AS beer_sum
FROM 	A
WHERE 	count>0),
C AS(
SELECT 	*
FROM 	B
WHERE 	beer_sum = 50 OR beer_sum = 150 OR beer_sum = 250),
D AS( 
SELECT 	C.*, E.normalized_name AS Location
FROM 	C
LEFT JOIN locations AS E
ON 	C.location_id = E.id)

SELECT 	F.season AS Season, 
	F.number_in_season AS Episode,
        F.title AS Title, 
        D.Location,
        D.raw_text, 
        D.beer_sum
FROM 	D
LEFT JOIN episodes AS F
ON 	D.episode_id = F.id;

#11
EXPLAIN script_lines;

WITH A AS(
SELECT 	*,
	CASE WHEN character_id = 18 THEN 1 ELSE 0 END AS barney_ind,
	CASE WHEN character_id = 2 THEN 1 ELSE 0 END AS homer_ind
FROM 	script_lines
ORDER BY episode_id, number)

SELECT 	*, 
	SUM(barney_ind) OVER(ORDER BY episode_id, number ROWS BETWEEN 3 PRECEDING AND 3 FOLLOWING) AS consider
FROM 	A;

