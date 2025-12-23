@echo off
echo ================================================
echo   Building Debug APK and Installing
echo ================================================
echo.

REM Set Flutter path (common location)
set "FLUTTER_PATH=C:\src\flutter\bin"
set "PATH=%FLUTTER_PATH%;%PATH%"

echo Checking Flutter...
where flutter >nul 2>&1
if errorlevel 1 (
    echo.
    echo ✗ Flutter not found in PATH.
    echo.
    echo Please run this command manually in your terminal:
    echo   cd C:\Users\jaiso\Desktop\astrologer_app
    echo   flutter build apk --debug
    echo   adb install build/app/outputs/flutter-apk/app-debug.apk
    echo.
    pause
    exit /b 1
)

echo ✓ Flutter found!
echo.

REM Build debug APK
echo Building debug APK...
flutter build apk --debug

if errorlevel 1 (
    echo.
    echo ✗ Build failed!
    echo.
    pause
    exit /b 1
)

echo.
echo ✓ Build successful!
echo.

REM Install APK
echo Installing APK to connected device...
set "ADB_PATH=C:\Users\jaiso\AppData\Local\Android\Sdk\platform-tools\adb.exe"

if exist "%ADB_PATH%" (
    "%ADB_PATH%" install -r build\app\outputs\flutter-apk\app-debug.apk
) else (
    adb install -r build\app\outputs\flutter-apk\app-debug.apk
)

if errorlevel 1 (
    echo.
    echo ✗ Installation failed!
    echo   Make sure USB debugging is enabled and device is connected.
    echo.
) else (
    echo.
    echo ================================================
    echo   ✓ APK installed successfully!
    echo ================================================
    echo.
    echo   Test the new dark slate notification background
    echo   by making an incoming call.
    echo.
)

pause
