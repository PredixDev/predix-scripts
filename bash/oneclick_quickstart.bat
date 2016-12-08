@ECHO OFF
SETLOCAL ENABLEEXTENSIONS ENABLEDELAYEDEXPANSION
SET BRANCH=master
SET SHELL_SCRIPT_NAME=oneclick_quickstart
SET SHELL_SCRIPT=https://raw.githubusercontent.com/PredixDev/predix-scripts/!BRANCH!/bash/%SHELL_SCRIPT_NAME%.sh
SET RESETVARS=https://raw.githubusercontent.com/PredixDev/local-setup/!BRANCH!/resetvars.vbs
SET SETUP_WINDOWS=https://raw.githubusercontent.com/PredixDev/local-setup/!BRANCH!/setup-windows.bat
GOTO START

:CHECK_FAIL
  IF NOT !errorlevel! EQU 0 (
    CALL :MANUAL
  )
GOTO :eof

:GET_DEPENDENCIES
ECHO Getting Dependencies
  ECHO !RESETVARS!
  @powershell -Command "(new-object net.webclient).DownloadFile('!RESETVARS!','%TEMP%\resetvars.vbs')"
  ECHO !SETUP_WINDOWS!
  @powershell -Command "(new-object net.webclient).DownloadFile('!SETUP_WINDOWS!','%TEMP%\setup-windows.bat')"
  ECHO !SHELL_SCRIPT!
  @powershell -Command "(new-object net.webclient).DownloadFile('!SHELL_SCRIPT!','%TEMP%\%SHELL_SCRIPT_NAME%.sh')"
GOTO :eof

:START
PUSHD "%TEMP%"
ECHO.
ECHO Welcome to the Predix QuickStart.
ECHO --------------------------------------------------------------
ECHO.
ECHO This is an automated script which will guide you through the tutorial.
ECHO.

CALL :GET_DEPENDENCIES
ECHO Calling %TEMP%\setup-windows.bat
CALL "%TEMP%\setup-windows.bat" /git /cf /nodejs /maven
CALL :CHECK_FAIL
IF NOT !errorlevel! EQU 0 EXIT /b !errorlevel!

PUSHD "%USERPROFILE%"
ECHO Cloning predix-Script repo using Git-Bash
ECHO Running the quickstart.sh script using Git-Bash
ECHO %*
ECHO "%PROGRAMFILES%\Git\bin\bash" --login -i -- "%TEMP%\%SHELL_SCRIPT_NAME%.sh %* --skip-setup
"%PROGRAMFILES%\Git\bin\bash" --login -i -- "%TEMP%\%SHELL_SCRIPT_NAME%.sh" %* --skip-setup
POPD
