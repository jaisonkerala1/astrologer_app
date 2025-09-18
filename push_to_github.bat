@echo off
echo ========================================
echo    Pushing Astrologer App to GitHub
echo ========================================

echo.
echo 1. Initializing Git repository...
git init

echo.
echo 2. Adding all files...
git add .

echo.
echo 3. Making initial commit...
git commit -m "Initial commit: Complete astrologer app with Flutter frontend and Node.js backend"

echo.
echo 4. Adding GitHub remote...
git remote add origin https://github.com/jaisonkerala1/astrologer_app.git

echo.
echo 5. Pushing to GitHub...
git push -u origin main

echo.
echo ========================================
echo    SUCCESS! Code pushed to GitHub
echo ========================================
echo.
echo Next steps:
echo 1. Go to https://railway.com
echo 2. Sign up with GitHub
echo 3. Deploy from your repository
echo 4. Set root directory to /backend
echo 5. Add environment variables
echo.
pause
