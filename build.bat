@ECHO OFF

call npm install
if %errorlevel% neq 0 exit /b %errorlevel%

call powershell -NoProfile -NonInteractive -NoLogo -ExecutionPolicy unrestricted -file moveFiles.ps1
if %errorlevel% neq 0 exit /b %errorlevel%

call .\node_modules\.bin\vset.cmd package -m extension-manifest.json -o .\Packages
if %errorlevel% neq 0 exit /b %errorlevel%