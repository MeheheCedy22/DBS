import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v2/users/{user_id}/friends")
async def zadanie2_endp2(user_id: int):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    # selectujem este raz u.creationdate aby som mohol podla toho zoradit ale nepouzivam v outpute
    executor.execute(f"""
SELECT DISTINCT
	u.id,
	u.reputation,
	TO_CHAR(u.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.displayname,
	TO_CHAR(u.lastaccessdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
	u.websiteurl,
	u.location,
	u.aboutme,
	u.views,
	u.upvotes,
	u.downvotes,
	u.profileimageurl,
	u.age,
	u.accountid,
	u.creationdate
FROM users AS u
JOIN comments c ON u.id = c.userid
JOIN
(
	SELECT c.postid AS in_post_id
	FROM posts AS p
	JOIN comments AS c ON p.id=c.postid
	WHERE c.userid = {user_id}
	
	UNION
	
	SELECT p.id AS in_post_id
	FROM posts AS p
	WHERE p.owneruserid = {user_id}
) AS created_plus_commented ON c.postid=created_plus_commented.in_post_id
ORDER BY u.creationdate ASC;
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    items = []
    for record in output:
        items.append({
            'id': record[0],
            'reputation': record[1],
            'creationdate': str(record[2]) if record[2] is not None else None,
            'displayname': record[3],
            'lastaccessdate': str(record[4]) if record[4] is not None else None,
            'websiteurl': record[5],
            'location': record[6],
            'aboutme': record[7],
            'views': record[8],
            'upvotes': record[9],
            'downvotes': record[10],
            'profileimageurl': record[11],
            'age': record[12],
            'accountid': record[13]
        })
    
    return {'items': items}
