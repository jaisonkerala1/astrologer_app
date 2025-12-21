@echo off
echo ================================================
echo   Fixing PATH and Starting Servers
echo ================================================
echo.

REM Add Node.js to PATH for this session
set "PATH=C:\Program Files\nodejs;%PATH%"

REM Verify npm is now accessible
echo Checking npm...
where npm >nul 2>&1
if errorlevel 1 (
    echo ✗ npm still not found. Using full path...
    set "NPM_CMD=C:\Program Files\nodejs\npm.cmd"
    set "NODE_CMD=C:\Program Files\nodejs\node.exe"
) else (
    echo ✓ npm found!
    set "NPM_CMD=npm"
    set "NODE_CMD=node"
)

echo.
echo Node.js location: C:\Program Files\nodejs
echo npm command: %NPM_CMD%
echo.

REM Start Backend in a new window
echo Starting Backend Server...
start "Backend Server" cmd /k "set PATH=C:\Program Files\nodejs;%%PATH%% && cd /d "%~dp0backend" && npm start"
timeout /t 3 > nul

REM Start Frontend in a new window
echo Starting Admin Dashboard...
start "Admin Dashboard" cmd /k "set PATH=C:\Program Files\nodejs;%%PATH%% && cd /d "%~dp0admin_dashboard" && npm install && npm run dev"

echo.
echo ================================================
echo   Both servers are starting...
echo ================================================
echo.
echo   Backend:  http://localhost:5000
echo   Frontend: http://localhost:3001
echo.
echo   Two terminal windows have opened
echo   Wait for both to finish loading...
echo.
echo   Then open: http://localhost:3001
echo.
echo   Press any key to close this window...
echo ================================================
pause > nul


















