USE lahman2021;



SELECT *
FROM Fielding
WHERE teamID = 'BAL';

SELECT teamID, POS, MAX(G)
FROM Fielding
WHERE yearID = 2021 AND
	POS != 'P' 
GROUP BY teamID, POS;

# task 1
WITH B
AS(
SELECT *
FROM(
SELECT playerID, teamID, POS, G, rank() OVER(PARTITION BY teamID, POS ORDER BY G DESC, playerID) AS rank
FROM Fielding
WHERE yearID = 2021 AND
	POS != 'P') AS A
WHERE rank <= 3
)

SELECT F.nameLast, F.nameFirst, E.POS, E.rank, E.base_diff
FROM(
SELECT C.*, D.total_bases-AVG(D.total_bases) OVER(PARTITION BY POS ORDER BY G DESC ROWS BETWEEN 4 PRECEDING AND 4 FOLLOWING) AS base_diff
FROM
(
SELECT *
FROM B
WHERE POS = 'OF' OR (POS != 'OF' AND rank = 1)
ORDER BY POS, G DESC) AS C
INNER JOIN (
SELECT  *, ((H-2B-3B-HR)+(2*2B)+(3*3B)+(4*HR)) AS total_bases
FROM Batting
WHERE yearID = 2021) AS D
ON C.playerID = D.playerID AND
		C.teamID = D.teamID
ORDER BY POS, G DESC) AS E
LEFT JOIN People AS F
ON E.playerID = F.playerID
WHERE teamID = 'BAL'
ORDER BY POS, rank;


# task 3

SELECT *
FROM Teams
WHERE yearID >= 1980 AND yearID <= 2019;

Explain Teams;

WITH RankedTeams AS (
    SELECT BPF,
		W/G AS winning_percentage,
		RANK() OVER (ORDER BY W/G DESC, R DESC) AS WG_Ranking,
		(CASE WHEN WCWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN DivWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN LgWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN WSWin = 'Y' THEN 1 ELSE 0 END) AS playoff_points
    FROM  Teams
	WHERE yearID>=1980 AND yearID<=2019
), 
CalculatedCorrelations AS (
    SELECT 
        (COUNT(*) * SUM(winning_percentage * BPF) - SUM(winning_percentage) * SUM(BPF))/ (SQRT(COUNT(*) * SUM(winning_percentage * winning_percentage) - POW(SUM(winning_percentage), 2)) *SQRT(COUNT(*) * SUM(BPF * BPF) - POW(SUM(BPF), 2))) AS corr1,
        (COUNT(*) * SUM(BPF * WG_Ranking) - SUM(BPF) * SUM(WG_Ranking))
    / 
        (
            SQRT(
                COUNT(*) * SUM(BPF * BPF) 
                - POW(SUM(BPF), 2)
            ) 
            *
            SQRT(
                COUNT(*) * SUM(WG_Ranking * WG_Ranking) 
                - POW(SUM(WG_Ranking), 2)
            )
        ) AS corr2,
 (COUNT(*) * SUM(BPF * playoff_points) - SUM(BPF) * SUM(playoff_points))
    / 
        (
            SQRT(
                COUNT(*) * SUM(BPF * BPF) 
                - POW(SUM(BPF), 2)
            ) 
            *
            SQRT(
                COUNT(*) * SUM(playoff_points * playoff_points) 
                - POW(SUM(playoff_points), 2)
            )
        ) AS corr3
    FROM
        RankedTeams
)
SELECT * 
FROM CalculatedCorrelations;


    SELECT BPF,
		W/G AS winning_percentage,
		RANK() OVER (ORDER BY W/G DESC, R DESC) AS WG_Ranking,
		CASE WHEN WCWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN DivWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN LgWin = 'Y' THEN 1 ELSE 0 END+
		CASE WHEN WSWin = 'Y' THEN 1 ELSE 0 END AS playoff_points
    	FROM  Teams
	WHERE yearID>=1980 AND yearID<=2019;

WITH RankedTeams AS (
    SELECT BPF,
		W/G AS winning_percentage,
		RANK() OVER (ORDER BY W/G DESC, R DESC) AS WG_Ranking,
		SUM(CASE WHEN WCWin = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN DivWin = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN LgWin = 'Y' THEN 1 ELSE 0 END,
			CASE WHEN WSWin = 'Y' THEN 1 ELSE 0 END) AS playoff_points
    FROM  Teams
	WHERE yearID>=1980 AND yearID<=2019
)
    SELECT 
        (COUNT(*) * SUM(winning_percentage * BPF) - SUM(winning_percentage) * SUM(BPF))/ (SQRT(COUNT(*) * SUM(winning_percentage * winning_percentage) - POW(SUM(winning_percentage), 2)) *SQRT(COUNT(*) * SUM(BPF * BPF) - POW(SUM(BPF), 2))) AS corr1,
        (COUNT(*) * SUM(BPF * WG_Ranking) - SUM(BPF) * SUM(WG_Ranking))
    / 
        (
            SQRT(
                COUNT(*) * SUM(BPF * BPF) 
                - POW(SUM(BPF), 2)
            ) 
            *
            SQRT(
                COUNT(*) * SUM(WG_Ranking * WG_Ranking) 
                - POW(SUM(WG_Ranking), 2)
            )
        ) AS corr2,
 (COUNT(*) * SUM(BPF * playoff_points) - SUM(BPF) * SUM(playoff_points))
    / 
        (
            SQRT(
                COUNT(*) * SUM(BPF * BPF) 
                - POW(SUM(BPF), 2)
            ) 
            *
            SQRT(
                COUNT(*) * SUM(playoff_points * playoff_points) 
                - POW(SUM(playoff_points), 2)
            )
        ) AS corr3
    FROM RankedTeams;




WITH 
AS(
SELECT teamID, POS, MAX(G)
FROM Fielding
WHERE yearID = 2021 AND
	POS != 'P' 
GROUP BY teamID, POS
)

SELECT A.teamID, A.POS, B.G, B.playerID
FROM A
INNER JOIN Fielding AS B
ON A.teamID = B.teamID AND
	A.POS = B.POS AND
        A.MAX(G) = B.G;


