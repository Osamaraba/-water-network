from typing import Any, Optional, Dict
from pydantic import BaseModel

class APIResponse(BaseModel):
    success: bool = True
    message: str = ""
    data: Optional[Any] = None
    errors: Optional[list] = None
    request_id: Optional[str] = None

    class Config:
        arbitrary_types_allowed = True

def success_response(data: Any = None, message: str = "", request_id: str = None) -> Dict:
    return {
        "success": True,
        "message": message,
        "data": data,
        "request_id": request_id
    }

def error_response(message: str, errors: list = None, request_id: str = None, status_code: int = 400) -> Dict:
    return {
        "success": False,
        "message": message,
        "errors": errors or [],
        "request_id": request_id
    }
