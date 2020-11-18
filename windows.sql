Select * from bowlers
Select * from bowler_scores

--Let's do a quick refresher on aggregates
--I can take the average of everyone's score
Select avg(rawscore)
from bowler_scores

--I can take the average of each bowlers score
SELECT bowlerfirstname ||' '|| bowlerlastname, AVG(rawscore)
from bowlers
inner join bowler_scores
using (bowlerid)
group by 1, bowlerid
order by bowlerid

--I can also take the average of each bowlers score per match (several games in a match)
Select bowlerfirstname ||' '|| bowlerlastname, matchid, avg(rawscore)
from bowler_scores
join bowlers
using (bowlerid)
group by 1,2, bowlerid
order by bowlerid

--These examples tell the query to take a different average each time, via the group by clause

--We can also use a window function. A window function is another way of performing an aggregation
--without a group by needed. A window function performs an aggregation on a subset of rows that are related
--to the current row. It allows you to see an average but without losing the granularity that you 
--do when you group data up. Below for instance, I can see Barbara's average score, while also 
--continuing to see her score in each match and game as well.

--The average next to each bowler is their personal average, across all matches because that's what we
--specified in the partition by predicate:
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
avg(rawscore) over (partition by bowlerid)
from bowler_scores
inner join bowlers
using (bowlerid)



--You can specify multiple things in the partition by predicate: In this case, we're telling SQL that
--we want to calculate an average for each person for each match, and show that along side all the original
--records. Window functions always return the same number of rows as the underlying tables, unlike groupby
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
avg(rawscore) over (partition by bowlerid, matchid)
from bowler_scores
inner join bowlers
using (bowlerid)

--We can also use a count, for instance, how many games did each bowler play in each match
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
count(*) over (partition by bowlerid, matchid)
from bowler_scores
inner join bowlers
using (bowlerid)


--Compare this to counting with a group by
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, count(*)
from bowler_scores
inner join bowlers
using (bowlerid)
group by 1,2,3
order by bowlerid, matchid

--We're able to aggregate a certain way, but while keeping the underlying data visible by using WF. In the syntax, we
--are telling sql to take the count/average over or across a set of rows, and those rows are decided by partition by aka
--how to split them up.


--If we don't specify anything in the partition by clause, it will treat all the rows as the partition
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
count(*) over (partition by bowlerid), count(*) over ()
from bowler_scores
inner join bowlers
using (bowlerid)

--ORDER BY, tells sql to order by column specified
Select bowlerfirstname, bowlerlastname, bowlercity, 
COUNT(*) OVER (partition by bowlercity) as city_total
from bowlers

--Sort of like saying order data by city, and count how many are either in a group before me, or in my group, and
--return that number next to me
Select bowlerfirstname, bowlerlastname, bowlercity, 
COUNT(*) OVER (ORDER BY bowlercity) as running_total
from bowlers


--This shows two columns next to each other so we can see how they compare
Select bowlerfirstname, bowlerlastname, bowlercity, COUNT(*) OVER (partition by bowlercity ) as city_total,
COUNT(*) OVER (ORDER BY bowlercity) as running_total
from bowlers



--Check this out, a running total for each bowlers average score. This shows us how barbara's average changes across
--each game, in the order they were played
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
avg(rawscore) over (partition by bowlerid order by matchid, gamenumber)
from bowler_scores
inner join bowlers
using (bowlerid)


--We can also write window functions similar to CTEs

SELECT bowlerid, matchid, gamenumber,
   avg(rawscore) OVER w,
   count(*) OVER w
FROM bowler_scores
WINDOW w AS (PARTITION BY bowlerid);



--RANK and DENSERANK
--We can use rank to determine where each row lies within its window
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
rank() over (partition by matchid order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)

--when people are tied, they get the same rank and the next non-tied rank skips some values
--To avoid that we can use denserank
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
dense_rank() over (partition by matchid order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)

--Row number assigns a sequential number to each row
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
row_number() over (order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)


--First Value will show us the first in order for each group (depending on how we order this can be best or worst)
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
FIRST_VALUE(rawscore) over (partition by matchid, gamenumber order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)

--Last Value does the same thing but opposite, and we need to change the frame to Range unbounded
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
LAST_VALUE(rawscore) over (partition by matchid order by rawscore desc RANGE BETWEEN UNBOUNDED PRECEDING
		AND UNBOUNDED FOLLOWING)
from bowler_scores
inner join bowlers
using (bowlerid)


--This is the default and misinterprets what we want - it can only look at itself and what comes before, and thinks higher
--is better based on how we have it sorted
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
LAST_VALUE(rawscore) over (partition by matchid order by rawscore desc RANGE BETWEEN UNBOUNDED PRECEDING
		AND CURRENT ROW)
from bowler_scores
inner join bowlers
using (bowlerid)


---LAG and LEAD functions. Lag shows from previous offset. IN our example 1
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
LAG(rawscore, 1) over (partition by matchid order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)


--LEAD looks ahead to compare.
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
LEAD(rawscore, 5) over (partition by matchid order by rawscore desc)
from bowler_scores
inner join bowlers
using (bowlerid)


--NTILE - labels partitioned data with Ntiles
Select bowlerid, bowlerfirstname ||' '|| bowlerlastname, matchid, gamenumber, rawscore, 
NTILE(4) over (partition by bowlerid order by rawscore)
from bowler_scores
inner join bowlers
using (bowlerid)



Select * from bowlers
Select * from bowler_scores

