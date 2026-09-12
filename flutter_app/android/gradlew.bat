@echo off
setlocal
set "GRADLE_VERSION=9.1.0"
set "CACHE_DIR=%USERPROFILE%\.gradle\ong-adocao-wrapper"
set "GRADLE_HOME=%CACHE_DIR%\gradle-%GRADLE_VERSION%"
set "ZIP_FILE=%CACHE_DIR%\gradle-%GRADLE_VERSION%-all.zip"

if not exist "%GRADLE_HOME%\bin\gradle.bat" (
  echo Preparando Gradle %GRADLE_VERSION% na primeira execucao...
  if not exist "%CACHE_DIR%" mkdir "%CACHE_DIR%"
  powershell -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; Invoke-WebRequest -Uri 'https://services.gradle.org/distributions/gradle-%GRADLE_VERSION%-all.zip' -OutFile '%ZIP_FILE%'"
  if errorlevel 1 goto download_error
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%CACHE_DIR%' -Force"
  if errorlevel 1 goto download_error
)

call "%GRADLE_HOME%\bin\gradle.bat" %*
exit /b %ERRORLEVEL%

:download_error
echo Nao foi possivel baixar o Gradle. Verifique sua conexao e a instalacao do Flutter SDK.
exit /b 1
