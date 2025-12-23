@echo off
echo ================================================
echo   Astrologer Platform - Quick Start
echo ================================================
echo.
echo This will start BOTH backend and frontend servers
echo.
echo Press any key to continue or Ctrl+C to cancel...
pause > nul
echo.

REM Start Backend in a new window
echo Starting Backend Server...
start "Backend Server" cmd /k "cd /d "%~dp0backend" && npm start"
timeout /t 3 > nul

REM Start Frontend in a new window
echo Starting Admin Dashboard...
start "Admin Dashboard" cmd /k "cd /d "%~dp0admin_dashboard" && call START_DASHBOARD.bat"

echo.
echo ================================================
echo   Both servers are starting...
echo ================================================
echo.
echo   Backend:  http://localhost:5000
echo   Frontend: http://localhost:3001
echo.
echo   Two terminal windows have opened:
echo   1. Backend Server (port 5000)
echo   2. Admin Dashboard (port 3001)
echo.
echo   Wait for both to finish loading, then open:
echo   http://localhost:3001
echo.
echo   Press any key to close this window...
echo ================================================
pause > nul































