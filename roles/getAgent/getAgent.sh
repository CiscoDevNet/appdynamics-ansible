#!/bin/bash

# Usage
if [ $# -lt 1 ]; then
    echo "$(basename $0) - Download AppDynamics binaries"
    echo
    echo "Usage: component [-listonly]"
    echo
    echo "	ie: $0 ma-linux "
    echo ""
    echo ""
    echo "Valid Components names:"
    echo "			machineagent-linux or ma-linux or machineagent or ma"
    echo "			machineagent-windows or ma-windows"
    echo "			java6agent # Agent to monitor Java applications (for Sun and JRockit JVM) running on legacy JRE versions (1.6 and 1.7)"
    echo "			java8agent  or javaagent or agent # Agent to monitor Java applications (All Vendors) running on JRE version 1.8 and above"
    echo "			javaagent-ibm  # Agent to monitor Java applications (for IBM JVM) running on legacy JRE versions (1.6 and 1.7)"
    echo "			enterpriseconsole or ec"
    echo "			dbagent-linux or db-linux or db"
    echo "			dbagent-windows or db-win"
    echo "			eum"
    echo "			events-service or es"
    echo "			webserver"
    echo "			netvis"
    echo "          php"
    echo "          go"
    echo "          synthetics"
    echo "          nodejs"
    exit 1
fi

APPAGENT=""
PLATFORM=""
EUM=""
EVENTS=""
RENAME_TO=""
LISTONLY=""
ANSIBLE=""

if [ ! -z "$2" ] && [ "$2" != *"-listonly"* ] && [ "$2" != *"-ansible"* ]; then
    echo "agent version is $2"
    VERSION="${2}"
else
    echo "agent version is empty, grabbing the latest copy..."
    VERSION=""
fi

# List the file to be downloaded only
if [[ "$@" = *"-listonly"* ]]; then
    LISTONLY=true
fi

if [[ "$@" = *"-ansible"* ]]; then
    ANSIBLE=true
fi

#
# Download options
#
if [ "$1" = "enterpriseconsole" -o "$1" = "ec" ]; then
    PLATFORM="linux"
    matchString="enterprise-console"

elif [ "$1" = "db" -o "$1" = "db-linux" -o "$1" = "dbagent" -o "$1" = "dbagent-linux" ]; then
    APPAGENT="db"
    matchString="dbagent"
    RENAME_TO="dbagent-linux-${VERSION}"

elif [ "$1" = "db-win" -o "$1" = "db-windows" -o "$1" = "dbagent-windows" -o "$1" = "dbagent-win" ]; then
    APPAGENT="db"
    matchString="db-agent-winx64"
    RENAME_TO="dbagent-windows-${VERSION}"

elif [ "$1" = "eum" ]; then
    EUM="linux"
    matchString="euem-64bit-linux\\\S{10,20}.sh"

elif [ "$1" = "events-service" -o "$1" = "es" ]; then
    EVENTS="linuxwindows"
    matchString="events-service"

elif [ "$1" = "machineagent-linux" -o "$1" = "ma-linux" ]; then
    APPAGENT="machine"
    PLATFORM="linux"
    matchString="machineagent-bundle-64bit-linux"
    RENAME_TO="machineagent-bundle-64bit-linux"

elif [ "$1" = "machineagent-windows" -o "$1" = "ma-windows" -o "$1" = "machineagent-win" -o "$1" = "ma-win" ]; then
    APPAGENT="machine"
    PLATFORM="windows"
    matchString="machineagent-bundle-64bit-windows"
    RENAME_TO="machineagent-bundle-64bit-windows-${VERSION}"

elif [ "$1" = "agent" -o "$1" = "javaagent" -o "$1" = "java8agent" ]; then
    APPAGENT="jvm%2Cjava-jdk8" #APPAGENT="jvm"
    matchString="java-jdk8"
    RENAME_TO="javaagent-${VERSION}"

elif [ "$1" = "java6agent" ]; then
    APPAGENT="jvm%2Cjava-jdk8" #APPAGENT="jvm"
    matchString="sun-jvm"
    RENAME_TO="javaagent-${VERSION}"

elif [ "$1" = "javaagent-ibm" ]; then
    APPAGENT="jvm%2Cjava-jdk8" #APPAGENT="jvm"
    matchString="ibm-jvm"
    RENAME_TO="javaagent-${VERSION}"

elif [ "$1" = "dotnet" ]; then
    APPAGENT="dotnet"
    matchString="dotnet"

elif [ "$1" = "dotnet-linux" ]; then
    APPAGENT="dotnet,dotnet-core"
    matchString="AppDynamics-DotNetCore-linux-x64"

elif [ "$1" = "webserver" ]; then
    APPAGENT="webserver"
    matchString="appdynamics-sdk-native-nativeWebServer-64bit-linux"

elif [ "$1" = "netviz" ]; then
    APPAGENT="netviz"
    matchString="netviz-linux"

elif [ "$1" = "ua" ]; then
    APPAGENT="universal-agent"
    matchString="universal-agent-x64-linux"

elif [ "$1" = "php" ]; then
    APPAGENT="php"
    matchString="appdynamics-php-agent-x64-linux"

elif [ "$1" = "go" ]; then
    APPAGENT="golang-sdk"
    matchString="golang-sdk-x64-linux"

elif [ "$1" = "synthetics" ]; then
    EUM="synthetic-server"
    matchString="appdynamics-synthetic-server"

elif [ "$1" = "nodejs" ]; then
    APPAGENT="nodejs"
    matchString="golang-sdk-x64-linux"

else
    echo
    echo "ERROR: >$1< is invalid\n"
    echo
    echo "Valid Components names:"
    echo "			machineagent-linux or ma-linux or machineagent or ma"
    echo "			machineagent-windows or ma-windows"
    echo "			java6agent # Agent to monitor Java applications (for Sun and JRockit JVM) running on legacy JRE versions (1.6 and 1.7)"
    echo "			java8agent  or javaagent or agent # Agent to monitor Java applications (All Vendors) running on JRE version 1.8 and above"
    echo "			javaagent-ibm  # Agent to monitor Java applications (for IBM JVM) running on legacy JRE versions (1.6 and 1.7)"
    echo "			enterpriseconsole or ec"
    echo "			dbagent-linux or db-linux or db"
    echo "			dbagent-windows or db-win"
    echo "			eum"
    echo "			events-service or es"
    echo "			webserver"
    echo "			netvis"
    echo "          php"
    echo "          go"
    echo "          synthetics"
    echo "          nodejs"
    exit 1
fi

# Look for the latest file for the component to download (querying Download API)
#/download/downloadfile/?apm=machine&os=&platform_admin_os=&appdynamics_cluster_os=&events=&eum=&page=1&apm_os=windows%2Clinux%2Calpine-linux%2Cosx%2Csolaris%2Csolaris-sparc%2Caix
curl -s -L -o tmpout.json "https://download.appdynamics.com/download/downloadfile/?version=${VERSION}&apm=${APPAGENT}&os=${PLATFORM}&platform_admin_os=${PLATFORM}&events=${EVENTS}&eum=${EUM}&apm_os=windows%2Clinux%2Calpine-linux%2Cosx%2Csolaris%2Csolaris-sparc%2Caix"

fileJson="$(cat tmpout.json | jq "first(.results[]  | select(.s3_path | test(\"${matchString}\"))) | .")"
#echo ${fileJson}
#echo ${fileJson} > test.json
# Grab the file path from the json output from previous command
fileToDownload=$(echo ${fileJson} | jq -r .s3_path)

echo $fileToDownload

fileVersion=$(echo ${fileJson} | jq -r .version)

if [ -z "$fileToDownload" ]; then
    echo ERROR: Could not download your request "$1"
    exit 1
fi

echo "Is Ansible enabled : $ANSIBLE "

if [ "$ANSIBLE" = "true" ]; then
    echo ${fileJson} | jq -r '.download_path' > ./files/"${RENAME_TO}".txt
    exit 0
fi

if [ "$LISTONLY" != "" ]; then
    echo
    echo "Downloading file : ${fileToDownload}"
    echo
    curl -L -O https://download-files.appdynamics.com/${fileToDownload}
fi

downloadedFile=$(basename ${fileToDownload})
echo
echo "FILENAME: $downloadedFile"
echo "RENAMED Value: ${RENAME_TO}.zip"

if [ "${downloadedFile##*.}" == "sh" ]; then
    chmod 755 *.sh
fi

if [ "${RENAME_TO}" != "" ] && [ "${LISTONLY}" != "" ]; then
    mv $downloadedFile $RENAME_TO.zip
   # echo "${RENAME_TO}.zip file is version: ${fileVersion}" >>file-version.log
fi

# cleanup
rm -f tmpout.json 
