import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v2/posts")
async def zadanie2_endp4a5(duration: int = None, limit: int = None, query: str = None):
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    
    # PRE 4 ENDPOINT
    if limit is not None and duration is not None and query is None: 
        executor.execute(f"""
SELECT 
    p.id,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.viewcount,
    p.lasteditdate,
    TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.title,
	TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    ROUND(EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0, 2) AS duration
FROM posts AS p
WHERE p.closeddate IS NOT null AND EXTRACT(EPOCH FROM (p.closeddate - p.creationdate)) / 60.0 <= {duration}
ORDER BY p.closeddate DESC
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
                'creationdate': str(record[1]) if record[1] is not None else None,
                'viewcount': record[2],
                'lasteditdate': str(record[3]) if record[3] is not None else None,
                'lastactivitydate': str(record[4]) if record[4] is not None else None,
                'title': record[5],
                'closeddate': str(record[6]) if record[6] is not None else None,
                'duration': record[7]
            })
            
    # PRE 5 ENDPOINT
    elif limit is not None and query is not None and duration is None:
        
        executor.execute(f"""
SELECT
    p.id,
    TO_CHAR(p.creationdate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.viewcount,
    p.lasteditdate,
    TO_CHAR(p.lastactivitydate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    p.title,
	p.body,
	p.answercount,
    TO_CHAR(p.closeddate, 'YYYY-MM-DD"T"HH24:MI:SS.MSTZH:TZM'),
    (
        SELECT STRING_AGG(t.tagname, ', ') 
        FROM tags AS t 
        JOIN post_tags AS pt ON pt.tag_id = t.id 
        WHERE pt.post_id = p.id
    ) AS tags
FROM posts AS p
WHERE p.title ILIKE '%{query}%' OR p.body ILIKE '%{query}%'
ORDER BY p.creationdate DESC
LIMIT {limit};
""")
        output = executor.fetchall()
        con.commit()
        executor.close()
        con.close()
                
        items = []
        for record in output:
            tags_list = [tag.strip() for tag in record[9].split(',')]
            items.append({
                'id': record[0],
                'creationdate': str(record[1]) if record[1] is not None else None,
                'viewcount': record[2],
                'lasteditdate': str(record[3]) if record[3] is not None else None,
                'lastactivitydate': str(record[4]) if record[4] is not None else None,
                'title': record[5],
                'body': record[6],
                'answercount': record[7],
                'closeddate': str(record[8]) if record[8] is not None else None,
                'tags': tags_list
            })
    else:
        executor.close()
        con.close()
        return {'error': 'Invalid query'}
    
    return {'items': items}
