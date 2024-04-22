import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v2/posts/{post_id}/users")
async def zadanie2_endp1(post_id: int):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
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
	c.creationdate
FROM users AS u
JOIN comments c ON u.id = c.userid
JOIN posts p ON c.postid = p.id
WHERE p.id = {post_id}
ORDER BY c.creationdate DESC;
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    # output[14] je c.creationdate, mam to iba v query aby som mohol podla toho zoradit len to nevraciam v response    
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
