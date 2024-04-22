import psycopg2
from fastapi import APIRouter

from dbs_assignment.config import settings


router = APIRouter()


@router.get("/v1/status")
async def status():
    
    # connection setup
    con = psycopg2.connect(host=settings.DATABASE_HOST, database=settings.DATABASE_NAME, user=settings.DATABASE_USER, port=settings.DATABASE_PORT, password=settings.DATABASE_PASSWORD)
    # cursor, ten co executuje query
    executor = con.cursor()
    executor.execute("SELECT version();")
    version = executor.fetchone()
    con.commit()
    executor.close()
    con.close()
    
    return {
        # zoberie prvy zaznam lebo su tam nejake header blbosti ?
        'version': version[0]
    }
