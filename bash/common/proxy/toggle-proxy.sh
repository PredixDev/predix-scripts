#!/bin/bash

#This script toggles all the proxy settings in a MAC environment
#The proxy value may be passed in from the command line while execting the scripts
#If no proxy value is passed in then the script guesses a proxy value
#If the user wants to enable to proxies then the script sets the proxies
#for env vars (bash_profile) and MAVEN_SETTINGS_FILE
#If the user wants to disable proxies then the script disables all the proxies

#This is the list of files updated:
# ~/.bash_profile
# ~/.m2/settings.xml

ScriptDir="$( pwd )"

usage() {
  echo
  echo Usage:
  echo $0 [--help] [--setup] [--enable] [--disable] [--clean]
  echo
  echo "Where : <host> is the hostname of your proxy"
  echo "        <port:8080> is the port on the proxy server, defaults to 8080"
  echo
  echo "When Enabling proxies ... "
  echo "Please select and enter the proxy server name - HOST:PORT"
  echo "Ensure that there is no http or www in the entered proxy host name as that is handled by the script"
  echo "example - PROXY_NAME:8080"
  echo
  echo "Options:"
  echo "    --help      Display this help message"
  echo "    --setup     Set proxy settings for bash environment variables"
  echo "    --enable    Set proxy settings for bash and maven"
  echo "    --disable   Unset proxy settings for bash and maven"
  echo "    --clean     Delete proxy settings"
  echo
}

function guessProxy() {
  export GUESSED_PROXY_HOST=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f1`
  export GUESSED_PROXY_PORT=`wget -O - http://corp.setpac.ge.com/pac.pac --no-proxy 2>/dev/null | grep -i "^var\w* main_proxy" | sed "s/.*\"PROXY\s* \([^\";]*\)\"*;.*/\1/" | cut -d: -f2`
}

function commentProxy() {
  if [ -e ~/.bash_profile ] ; then
    echo "Commenting out old proxies in bash_profile"
    sed -i -e '/export http_proxy=/s/^/#/g' ~/.bash_profile
    sed -i -e '/export https_proxy=/s/^/#/g' ~/.bash_profile
    sed -i -e '/export HTTP_PROXY=/s/^/#/g' ~/.bash_profile
    sed -i -e '/export HTTPS_PROXY=/s/^/#/g' ~/.bash_profile
    sed -i -e '/export no_proxy=/s/^/#/g' ~/.bash_profile

    # -----------------------------------------------------
    sed -i -e "/unset http_proxy/s/^/#/g" ~/.bash_profile
    sed -i -e "/unset https_proxy/s/^/#/g" ~/.bash_profile
    sed -i -e "/unset HTTP_PROXY/s/^/#/g" ~/.bash_profile
    sed -i -e "/unset HTTPS_PROXY/s/^/#/g" ~/.bash_profile
    sed -i -e "/unset no_proxy/s/^/#/g" ~/.bash_profile
  fi
}

function cleanupBashProfile() {
  if [ -e ~/.bash_profile ] ; then
    #echo Cleaning Up bash_profile
    sed -i -e "/export http_proxy=/d" ~/.bash_profile
    sed -i -e "/export https_proxy=/d" ~/.bash_profile
    sed -i -e "/export HTTP_PROXY=/d" ~/.bash_profile
    sed -i -e "/export HTTPS_PROXY=/d" ~/.bash_profile
    sed -i -e "/export no_proxy=/d" ~/.bash_profile

    # ----------------------------------------------------
    sed -i -e "/unset http_proxy/d" ~/.bash_profile
    sed -i -e "/unset https_proxy/d" ~/.bash_profile
    sed -i -e "/unset HTTP_PROXY/d" ~/.bash_profile
    sed -i -e "/unset HTTPS_PROXY/d" ~/.bash_profile
    sed -i -e "/unset no_proxy/d" ~/.bash_profile
  fi
}

function disableBashProfileProxy() {
  if [ -e ~/.bash_profile ] ; then
    printf "unset http_proxy\nunset https_proxy\nunset HTTP_PROXY\nunset HTTPS_PROXY\nunset no_proxy\n" | tee -a ~/.bash_profile > /dev/null
    echo
    echo "Done. Successfully unset environment proxies"
  else
    echo "bash_profile file does not exist. If you want to set environment variables please create a bash_profile file in your root directory."
    echo "Failed: Enviornment Proxies are still set. Proxies could not be unset or disabled"
  fi
}

function enableBashProfileProxy() {
  if [ -e ~/.bash_profile ] ; then
    printf "export http_proxy=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/\nexport https_proxy=\$http_proxy\nexport HTTP_PROXY=\$http_proxy\nexport HTTPS_PROXY=\$http_proxy\nexport no_proxy=\"127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com,*ge.com\"\n" | tee -a ~/.bash_profile > /dev/null
    source ~/.bash_profile
    echo
    echo "Done. Successfully set environment proxies"
  else
    echo bash_profile file does not exist. If you want to set environment variables please create a bash_profile file in your root directory.
    echo "Failed: Enviornment Proxies not set. Proxies could not be set or enabled"
  fi
}

function disableGnomeProxy() {
  gsettings --version >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    gsettings set org.gnome.system.proxy.http host ''
    gsettings set org.gnome.system.proxy.http port 0
    gsettings set org.gnome.system.proxy.http enabled false
    gsettings set org.gnome.system.proxy.https host ''
    gsettings set org.gnome.system.proxy.https port 0
    gsettings set org.gnome.system.proxy.https enabled false
    gsettings set org.gnome.system.proxy mode 'none'
    gsettings list-recursively org.gnome.system.proxy
  fi
}

function enableGnomeProxy() {
  gsettings --version >/dev/null 2>&1
  if [ $? -eq 0 ]; then
    gsettings set org.gnome.system.proxy.http host $PROXY_HOST
    gsettings set org.gnome.system.proxy.http port $PROXY_PORT
    gsettings set org.gnome.system.proxy.http enabled true
    gsettings set org.gnome.system.proxy.https host $PROXY_HOST
    gsettings set org.gnome.system.proxy.https port $PROXY_PORT
    gsettings set org.gnome.system.proxy ignore-hosts "['localhost', '127.0.0.1/8', '::1', '.ge.com', '*ge.com']"
    gsettings set org.gnome.system.proxy.https enabled true
    gsettings set org.gnome.system.proxy mode 'manual'
    gsettings list-recursively org.gnome.system.proxy
  fi
}

function disableMavenProxy() {
  if [ ! -e $ScriptDir/disable-proxy.xsl ] ; then
    curl -s -O $DISABLE_XSL_URL
  fi

  if [ -e ~/.m2/settings.xml ] ; then
    cp ~/.m2/settings.xml ~/.m2/settings.xml.orig
    xsltproc $ScriptDir/disable-proxy.xsl ~/.m2/settings.xml.orig > ~/.m2/settings.xml.new
    mv -f ~/.m2/settings.xml.new ~/.m2/settings.xml
    echo
    echo "Done. Successfully unset maven proxies"
  else
    echo
    echo "Could not find settings.xml in directory ./m2"
    echo "Failed: Maven Proxies could not be disabled"
  fi
}

function enableMavenProxy() {
  if [ ! -e $ScriptDir/enable-proxy.xsl ] ; then
    curl -s -O $ENABLE_XSL_URL
  fi

  if [ -e ~/.m2/settings.xml ] ; then
    cp ~/.m2/settings.xml ~/.m2/settings.xml.orig
    xsltproc --stringparam proxy-host $PROXY_HOST \
         --stringparam proxy-port $PROXY_PORT \
         --stringparam proxy-username $PROXY_USERNAME \
         --stringparam proxy-password $PROXY_PASSWORD \
         --stringparam noproxy-hosts "127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com, *ge.com" \
         $ScriptDir/enable-proxy.xsl ~/.m2/settings.xml.orig > ~/.m2/settings.xml.new
    mv -f ~/.m2/settings.xml.new ~/.m2/settings.xml
    echo
    echo "Done. Successfully set maven proxies"
  else
    echo
    echo "Could not find settings.xml in directory ./m2"
    echo "Failed: Maven Proxies could not be set"
  fi
}

function fixMavenSettingsFile() {
  chmod 666 ~/.m2/settings.xml.orig
  chmod 666 ~/.m2/settings.xml
  #chown root ~/.m2/settings.xml.orig
  #chown root ~/.m2/settings.xml
}

function enableDockerProxy() {
  mkdir -p /etc/systemd/system/docker.service.d
  touch /etc/systemd/system/docker.service.d/http-proxy.conf
  chmod 777 /etc/systemd/system/docker.service.d/http-proxy.conf
  cat << EOF > /etc/systemd/system/docker.service.d/http-proxy.conf
[Service]
Environment="HTTP_PROXY=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/"
Environment="HTTPS_PROXY=http://$PROXY_AUTH$PROXY_HOST:$PROXY_PORT/"
Environment="NO_PROXY=127.0.0.1,localhost,localhost.localdomain,.ge.com,*.ge.com,*ge.com"
EOF

  cat /etc/systemd/system/docker.service.d/http-proxy.conf
  systemctl daemon-reload
  systemctl restart docker
}

function disableDockerProxy() {
  rm -rf /etc/systemd/system/docker.service.d/http-proxy.conf
  systemctl daemon-reload
  systemctl restart docker
}

function check_internet() {
  set +e
  echo ""
  echo "Checking internet connection..."
  curl "http://github.com" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "Unable to connect to internet, make sure you are connected to a network and check your proxy settings if behind a corporate proxy.  Please read this tutorial for detailed info about setting your proxy https://www.predix.io/resources/tutorials/tutorial-details.html?tutorial_id=1565"
    exit 1
  fi
  echo "OK"
  echo ""
  set -e
}

#fixMavenSettingsFile
for arg in $@ ; do
  if [ "$arg" = "--help" ] ; then
    usage
    exit 0
  fi
done

echo
echo "--------------------------------------------------------------------------------"
echo "This script will enable/disable proxy variables required for Predix development"
echo "--------------------------------------------------------------------------------"
echo ""

IZON_SH="https://raw.githubusercontent.com/PredixDev/izon/1.1.0/izon2.sh"
ENABLE_XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/common/proxy/enable-proxy.xsl"
DISABLE_XSL_URL="https://raw.githubusercontent.com/PredixDev/predix-scripts/master/bash/common/proxy/disable-proxy.xsl"
PROXY_HOST=""
PROXY_PORT="8080"
PROXY_HOST_AND_PORT=""
PROXY_USERNAME="proxyuser"
PROXY_PASSWORD="proxypass"
PROXY_AUTH=""

#Switches
SETUP=0
ENABLE=0
DISABLE=0
CLEAN=0

if [ -z "$1" ]; then
  usage
  exit 0
else
  while [ ! -z "$1" ]; do
    [ "$1" == "--setup" ] && SETUP=1
    [ "$1" == "--enable" ] && ENABLE=1
    [ "$1" == "--disable" ] && DISABLE=1
    [ "$1" == "--clean" ] && CLEAN=1
    shift
  done
fi

if [ $SETUP -eq 1 ]; then
  # Findig the PAC file and printing out the proxy servers for the user
  echo "Printing configured browser proxies from your pac.pac file"
  AUTOCONFIG="$(scutil --proxy | grep ProxyAutoConfigURL)"
  echo $AUTOCONFIG | cut -d' ' -f 3
  PAC="$(echo $AUTOCONFIG | cut -d' ' -f 3)"
  echo
  curl -s $PAC | grep PROXY
  echo
  echo "Please choose which proxy you want to use and enter it in the command below"
  echo "You may select one of the proxy servers mentioned above or may choose a different one if you know it"
  echo "Please note - Do not enter the initial http prefix for the proxy. The script handles that internally"
  echo "You can enter - PROXY_HOST_NAME:PORT"
  echo
  read -p "Which proxy do you want to use?  " READ_PROXY
  echo
  PROXY_HOST="$(echo $READ_PROXY | cut -d':' -f 1)"
  PROXY_PORT="$(echo $READ_PROXY | cut -d':' -f 2)"
  echo "Your selected proxy value = http://$PROXY_HOST:$PROXY_PORT"

  # Enabling or Setting the proxies for bash only
  echo
  echo "--------------------------------------------------------------------------------"
  echo "Setting proxy environment variables..."
  commentProxy
  enableBashProfileProxy
  echo
  echo "--------------------------------------------------------------------------------"
  echo "Open a new terminal window for the changes to take effect"
fi

if [ $ENABLE -eq 1 ]; then
  # Findig the PAC file and printing out the proxy servers for the user
  echo "Printing configured browser proxies from your pac.pac file"
  AUTOCONFIG="$(scutil --proxy | grep ProxyAutoConfigURL)"
  echo $AUTOCONFIG | cut -d' ' -f 3
  PAC="$(echo $AUTOCONFIG | cut -d' ' -f 3)"
  echo
  curl -s $PAC | grep PROXY
  echo
  echo "Please choose which proxy you want to use and enter it in the command below"
  echo "You may select one of the proxy servers mentioned above or may choose a different one if you know it"
  echo "Please note - Do not enter the initial http prefix for the proxy. The script handles that internally"
  echo "You can enter - PROXY_HOST_NAME:PORT"
  echo
  read -p "Which proxy do you want to use?  " READ_PROXY
  echo
  PROXY_HOST="$(echo $READ_PROXY | cut -d':' -f 1)"
  PROXY_PORT="$(echo $READ_PROXY | cut -d':' -f 2)"
  echo "Your selected proxy value = http://$PROXY_HOST:$PROXY_PORT"

  # Enabling or Setting the proxies
  echo
  echo "--------------------------------------------------------------------------------"
  echo "Setting proxy environment variables..."
  commentProxy
  enableBashProfileProxy
  echo
  echo "--------------------------------------------------------------------------------"
  echo "Setting Apache Maven proxy..."
  enableMavenProxy
  fixMavenSettingsFile
  echo
  echo "--------------------------------------------------------------------------------"
fi

if [ $DISABLE -eq 1 ]; then
  echo "Unsetting proxy environment variables..."
  #cleanupBashrc
  disableBashProfileProxy
  echo
  echo "--------------------------------------------------------------------------------"
  echo "Unsetting Apache Maven proxy..."
  disableMavenProxy
  fixMavenSettingsFile
  echo
  echo "--------------------------------------------------------------------------------"
fi

if [ $CLEAN -eq 1 ]; then
  echo "Deleting proxy settings for bash and Maven"
  cleanupBashProfile
  #disableGnomeProxy
  disableMavenProxy
  fixMavenSettingsFile
  #disableDockerProxy
  echo
  echo "--------------------------------------------------------------------------------"
fi

echo "Open a new terminal window for the changes to take effect"
echo "OR"
echo "Run this command to reload the environment variables : source ~/.bash_profile"
echo
exit 0
