import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v3/posts/{post_id}")
async def zadanie3_endp4(post_id: int, limit: int = None):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute(f"""
SELECT
    u.displayname,
    p.body,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH') AS created_at
FROM posts AS p
JOIN users AS u ON u.id = p.owneruserid
WHERE p.id = {post_id} OR p.parentid = {post_id}
ORDER BY created_at ASC
LIMIT {limit};
""")
    output = executor.fetchall()
    con.commit()
    executor.close()
    con.close()
    
    items = []
    for record in output:
        items.append({
            'displayname': record[0],
            'body': record[1],
            'created_at': str(record[2]) if record[2] is not None else None
        })
    return {'items': items}
