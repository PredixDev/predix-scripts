@ECHO OFF

REM This is a .bat script to enable and disable proxies for a Windows OS

SET IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/1.1.0/izon2.sh"
SET ENABLE_XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/common/proxy/enable-proxy.xsl"
SET DISABLE_XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/common/proxy/disable-proxy.xsl"
SET PROXY_HOST=""
SET PROXY_PORT="8080"
SET PROXY_HOST_AND_PORT=""
SET PROXY_USERNAME="proxyuser"
SET PROXY_PASSWORD="proxypass"
SET PROXY_AUTH=""

GOTO START

:USAGE
  ECHO
  ECHO Usage:
  ECHO $0 [--help] [--setup] [--enable] [--disable] [--clean]
  ECHO
  ECHO Where : <host> is the hostname of your proxy
  ECHO         <port:8080> is the port on the proxy server, defaults to 8080
  ECHO
  ECHO When Enabling proxies ... 
  ECHO Please select and enter the proxy server name - HOST:PORT
  ECHO Ensure that there is no http or www in the entered proxy host name as that is handled by the script
  ECHO example - PROXY_NAME:8080
  ECHO
  ECHO Options:
  ECHO     --help      Display this help message
  ECHO     --setup     Set proxy settings for bash environment variables
  ECHO     --enable    Set proxy settings for bash and maven
  ECHO     --disable   Unset proxy settings for bash and maven
  ECHO     --clean     Delete proxy settings
  ECHO
GOTO :eof

:SET_PROXIES
  SET HTTP_PROXY=%PROXY%
  SET HTTPS_PROXY=%PROXY%
GOTO :eof

:UNSET_PROXIES
  Rem Comments
  Rem REG delete HKCU\Environment /F /V http_proxy
  Rem REG delete HKCU\Environment /F /V https_proxy
  Rem REG delete HKCU\Environment /F /V HTTP_PROXY
  Rem REG delete HKCU\Environment /F /V HTTPS_PROXY

  SET HTTP_PROXY=
  SET HTTPS_PROXY=

GOTO :eof

:CLEAN_PROXIES
  SET HTTP_PROXY=
  SET HTTPS_PROXY=
  REM REG delete HKCU\Environment /F /V HTTP_PROXY
  REM REG delete HKCU\Environment /F /V HTTPS_PROXY
GOTO :eof


:START

  ECHO
  ECHO --------------------------------------------------------------------------------
  ECHO This script will enable/disable proxy variables required for Predix development
  ECHO --------------------------------------------------------------------------------
  ECHO 

  IF [%1]==[] (
    CALL :USAGE
  )
  IF [%1]==[--help] (
    CALL :USAGE
  )

  IF [%1]==[--setup] (
    CALL :SET_PROXIES
  )

  IF [%1]==[--enable] (
    ECHO Please choose which proxy you want to use and enter it in the command below
    ECHO You may select one of the proxy servers mentioned above or may choose a different one if you know it
    ECHO You can enter - http://PROXY_HOST_NAME:PORT"
    ECHO
    SET /p PROXY=Which proxy do you want to use?  
    ECHO Your selected proxy value = %PROXY%
    CALL :SET_PROXIES
  )

  IF [%1]==[--disable] (
    CALL :UNSET_PROXIES
  )

  IF [%1]==[--clean] (
    CALL :CLEAN_PROXIES
  )

  :DONE
    ECHO Open a new terminal window for the changes to take effect
    ECHO
