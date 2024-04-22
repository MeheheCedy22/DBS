import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v3/tags/{tagname}/comments/{position}")
async def zadanie3_endp3(tagname: str, position: int, limit: int = None):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute(f"""
SELECT
	final_table.id,
	final_table.displayname,
	final_table.body,
	final_table.text,
	final_table.score,
	final_table.position
FROM
(
	/* zaobalenie kvoli where clause aby som moohl pouzit s position */
	SELECT
		c.id,
		u.displayname,
		p.body,
		c.text,
		c.score,
		p.post_tag_rank,
		ROW_NUMBER() OVER (PARTITION BY p.post_tag_rank ORDER BY p.creationdate, c.creationdate ASC) AS position
	FROM comments AS c
	JOIN users AS u ON u.id = c.userid
	JOIN
	(
		/* tato habadura je pretoze row number ignoruje distinct ak to je v tej istej "urovni" */
		SELECT
			ranked_posts.id,
			ranked_posts.body,
			ranked_posts.creationdate, /* iba kvoli order by */
			ROW_NUMBER() OVER (ORDER BY ranked_posts.creationdate ASC) AS post_tag_rank
		FROM
		(
			SELECT DISTINCT
				posts.id,
				posts.body,
				posts.creationdate /* iba kvoli order by */
			FROM posts
			JOIN post_tags AS pt ON posts.id = pt.post_id
			JOIN tags AS t ON pt.tag_id = t.id
			WHERE t.tagname = '{tagname}'
			ORDER BY posts.creationdate ASC
		) AS ranked_posts
		ORDER BY ranked_posts.creationdate
	) AS p ON p.id = c.postid
	ORDER BY p.creationdate, c.creationdate ASC
) AS final_table
WHERE position={position}
LIMIT {limit};
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    items = []
    for record in output:
        items.append({
            'id': record[0],
            'displayname': record[1],
            'body': record[2],
            'text': record[3],
            'score': record[4],
            'position': record[5]
        })
    return {'items': items}
