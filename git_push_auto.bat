@echo off
set /p msg="commit message : ": 
git add .
git commit -m "%msg%"
git push
pause