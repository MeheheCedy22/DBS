import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v3/tags/{tag}/comments")
async def zadanie3_endp2(tag: str, count: int = None):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute(f"""
SELECT
	final_tab.id,
	final_tab.title,
	final_tab.displayname,
	final_tab.text,
	TO_CHAR(final_tab.post_created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS post_created_at,
	TO_CHAR(final_tab.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at,
	COALESCE(final_tab.diff, final_tab.avg) AS diff,
	final_tab.avg
FROM
(
	SELECT
		out_tab.id,
		out_tab.title,
		out_tab.displayname,
		out_tab.text,
		out_tab.post_created_at,
		out_tab.created_at,
		out_tab.diff,
		((out_tab.created_at - out_tab.post_created_at) / out_tab.comment_seq_num) AS avg
	FROM
	(
		SELECT
			count_tab.id,
			count_tab.title,
			count_tab.displayname,
			count_tab.text,
			count_tab.post_created_at,
			count_tab.created_at,
			count_tab.previous_comment_date,
			(count_tab.created_at - count_tab.previous_comment_date) AS diff,
			ROW_NUMBER() OVER (PARTITION BY count_tab.id) AS comment_seq_num
		FROM
		(
			SELECT
				in_tab.id,
				in_tab.title,
				u.displayname,
				c.text,
				in_tab.creationdate AS post_created_at,
				c.creationdate AS created_at,
				LAG(c.creationdate) OVER (PARTITION BY c.postid ORDER BY c.creationdate) AS previous_comment_date,
				COUNT(*) OVER (PARTITION BY in_tab.id) AS comment_count
			FROM
			(
				SELECT DISTINCT
					posts.id,
					posts.title,
					posts.creationdate
				FROM posts
				JOIN post_tags AS pt ON posts.id = pt.post_id
				JOIN tags AS t ON pt.tag_id = t.id
				WHERE t.tagname = '{tag}'
			) AS in_tab
			JOIN comments AS c ON c.postid = in_tab.id
			LEFT JOIN users AS u ON u.id = c.userid --LEFT JOIN lebo inak mi jeden zaznam zmizol
		) AS count_tab
		WHERE count_tab.comment_count > {count}
	) AS out_tab
) AS final_tab
GROUP BY
	final_tab.id,
	final_tab.title,
	final_tab.displayname,
	final_tab.text,
	final_tab.post_created_at,
	final_tab.created_at,
	final_tab.diff,
	final_tab.avg
ORDER BY final_tab.id, final_tab.created_at ASC;
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    items = []
    for record in output:
        items.append({
            'post_id': record[0],
            'title': record[1],
            'displayname': record[2],
            'text': record[3],
            'post_created_at': str(record[4]) if record[4] is not None else None,
            'created_at': str(record[5]) if record[5] is not None else None,
            'diff': str(record[6]) if record[6] is not None else None, # castujem do stringu lebo mi v testery davalo miesto intervalu desatinne cislo
            'avg': str(record[7]) if record[7] is not None else None # castujem do stringu lebo mi v testery davalo miesto intervalu desatinne cislo
        })
    return {'items': items}
