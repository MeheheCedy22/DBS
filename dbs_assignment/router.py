from fastapi import APIRouter

from dbs_assignment.endpoints import hello
from dbs_assignment.endpoints import status
from dbs_assignment.endpoints import zadanie2_endp1
from dbs_assignment.endpoints import zadanie2_endp2
from dbs_assignment.endpoints import zadanie2_endp3
from dbs_assignment.endpoints import zadanie2_endp4a5
from dbs_assignment.endpoints import zadanie3_endp1
from dbs_assignment.endpoints import zadanie3_endp2
from dbs_assignment.endpoints import zadanie3_endp3
from dbs_assignment.endpoints import zadanie3_endp4

router = APIRouter()

router.include_router(hello.router, tags=["hello"])
router.include_router(status.router, tags=["status"])
router.include_router(zadanie2_endp1.router, tags=["zadanie2_endp1"])
router.include_router(zadanie2_endp2.router, tags=["zadanie2_endp2"])
router.include_router(zadanie2_endp3.router, tags=["zadanie2_endp3"])
router.include_router(zadanie2_endp4a5.router, tags=["zadanie2_endp4a5"])
router.include_router(zadanie3_endp1.router, tags=["zadanie3_endp1"])
router.include_router(zadanie3_endp2.router, tags=["zadanie3_endp2"])
router.include_router(zadanie3_endp3.router, tags=["zadanie3_endp3"])
router.include_router(zadanie3_endp4.router, tags=["zadanie3_endp4"])