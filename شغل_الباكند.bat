@echo off
cd /d "C:\Users\Administrator\Downloads\الخميس مساء\backend"
python -m uvicorn app.main:app --host 0.0.0.0 --port 8002
pause
