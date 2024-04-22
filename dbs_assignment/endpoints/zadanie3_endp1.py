import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v3/users/{user_id}/badge_history")
async def zadanie3_endp1(user_id: int):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute(f"""
SELECT
	final_table.id,
	final_table.title,
	final_table.type,
	TO_CHAR(final_table.created_at, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at,
	CEILING(ROW_NUMBER() OVER () / 2.0) AS position
FROM
(
	SELECT
		prev_next.*,
		CASE
			WHEN prev_next.type = 'post' AND prev_next.next_type = 'badge' THEN 'THIS'
			WHEN prev_next.type = 'badge' AND prev_next.prev_type = 'post' THEN 'THIS' 
		END marked
	FROM
	(
		SELECT
			p_and_b.*,
			LAG(p_and_b.type) OVER (ORDER BY p_and_b.created_at, p_and_b.id) AS prev_type,
			LEAD(p_and_b.type) OVER (ORDER BY p_and_b.created_at,  p_and_b.id) AS next_type
		FROM
		(
			(
				SELECT
					p.id,
					p.title,
					'post' AS type,
					p.creationdate AS created_at
				FROM users AS u
				JOIN posts AS p ON p.owneruserid = u.id
				WHERE u.id = {user_id}
			)
			UNION
			--to iste len s badges
			(
				SELECT
					b.id,
					b.name AS title,
					'badge' AS type,
					b.date AS created_at
				FROM users AS u
				JOIN badges AS b ON b.userid = u.id
				WHERE u.id = {user_id}
			)
		) AS p_and_b --posts and badges
	) AS prev_next --previous and next posts types
) AS final_table
WHERE final_table.marked = 'THIS'
ORDER BY final_table.created_at, final_table.id;
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    items = []
    for record in output:
        items.append({
            'id': record[0],
            'title': record[1],
            'type': record[2],
            'created_at': record[3],
            'position': record[4]
        })
    return {'items': items}
