import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v2/tags/{tagname}/stats")
async def zadanie2_endp3(tagname: str):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute(f"""
SELECT 
	CASE all_p.day_of_week
	   WHEN 1 THEN 'monday'
	   WHEN 2 THEN 'tuesday'
	   WHEN 3 THEN 'wednesday'
	   WHEN 4 THEN 'thursday'
	   WHEN 5 THEN 'friday'
	   WHEN 6 THEN 'saturday'
	   ELSE 'sunday'
	END AS day_of_week,
	ROUND(CAST(tagged.tagged_posts::float / all_p.all_posts * 100 AS NUMERIC), 2) AS percentage
FROM 
(
	SELECT DISTINCT
		COUNT(p.id) AS tagged_posts,
		EXTRACT(ISODOW FROM p.creationdate) AS day_of_week
	FROM tags as t
	JOIN post_tags as pt ON pt.tag_id = t.id
	JOIN posts as p ON p.id = pt.post_id
	WHERE t.tagname = '{tagname}'
	GROUP BY day_of_week
	ORDER BY day_of_week
) AS tagged
JOIN
(
	SELECT DISTINCT
		COUNT(p.id) AS all_posts,
		EXTRACT(ISODOW FROM p.creationdate) AS day_of_week
	FROM posts as p 
	GROUP BY day_of_week
	ORDER BY day_of_week
) AS all_p
ON tagged.day_of_week = all_p.day_of_week;
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()

    result = {}
    for row in output:
        day_of_week, percentage = row
        result[day_of_week] = percentage
        
    return {"result": result}