#!/bin/sh

echo "-------------------------- 开始远程编译 ----------------------------"
set -e

remoteDir=$(cd $(dirname $0); cd ..; pwd)
projectDir=$(cd $(dirname $0);cd ..; cd ..; pwd)
echo "remoteDir: $remoteDir"
echo "projectDir: $projectDir"
configPath=$remoteDir/config.json
echo "configPath: $configPath"
# 通过config.json获取应用build参数，从而按照指定应用
echo "----- config info ----"
cat $configPath

remoteUser=$(cat $configPath | jq '.username' | sed 's/\"//g')
remoteHost=$(cat $configPath | jq '.host' | sed 's/\"//g')
remoteUserPassword=$(cat $configPath | jq '.password' | sed 's/\"//g')
remoteCodeDir=$(cat $configPath | jq '.code' | sed 's/\"//g')
sdkDir=$(cat $configPath | jq '.sdk' | sed 's/\"//g' | sed 's/\\\\/\\/g')
remoteUserHost=${remoteUser}@${remoteHost}

echo "remoteUserHost: $remoteUserHost"
echo "sdkDir: $sdkDir"

echo "remoteCodeDir start: $remoteCodeDir"
remoteCodeDir=$(echo $remoteCodeDir | sed 's/~//g' | sed 's/\///g')
echo "remoteCodeDir end: $remoteCodeDir"

command=$1
moduleName=$2
buildType=$3

echo "shell params command: $command, moduleName: $moduleName, buildType: $buildType"

if [ buildType = "debug" ]; then
  buildCommand="gradlew assembleDebug -p $moduleName"
else
  buildCommand="gradlew assembleRelease -p $moduleName"
fi
echo "buildCommand: $buildCommand"

projectName=""
function project_name() {
    if [[ $projectDir =~ '/' ]]; then
        array=(`echo $projectDir | tr '/' ' '` )
        len=${#array[@]}
        for var in ${array[@]}
        do
           projectName=$var
        done
    else
        echo "无'/'参数"
    fi
}
project_name

echo "projectName: $projectName"

remoteProjectPath=''${remoteCodeDir}'\'${projectName}''
echo "remoteProjectPath: $remoteProjectPath"

remoteProjectDir=${remoteUserHost}:${remoteProjectPath}
echo "remoteProjectDir: $remoteProjectDir"

remote_include=$projectDir/.remote/rsync/remote_include
remote_ignore=$projectDir/.remote/rsync/remote_ignore
local_ignore=$projectDir/.remote/rsync/local_ignore

function remoteCreateProjectDir() {
  sshpass -p $remoteUserPassword ssh $remoteUserHost 'if not exist '$remoteProjectPath' (mkdir -p '$remoteProjectPath') else (echo '${projectName} created')'
}

function remoteConfigSDK() {
  sshpass -p $remoteUserPassword ssh $remoteUserHost 'cd '$remoteProjectPath' && (echo sdk.dir='$sdkDir') > local.properties && type local.properties && CACLS local.properties /e /p '$remoteUser':F'
}

function remoteBuild() {
  sshpass -p $remoteUserPassword ssh -p 22  -o StrictHostKeyChecking=no $remoteUserHost 'cd '$remoteProjectPath'  && '$buildCommand''
}

function installApk() {
  chmod 777 $projectDir/.remote/script/install-apk.sh && bash $projectDir/.remote/script/install-apk.sh $moduleName $buildType
}

function clean() {
  sshpass -p $remoteUserPassword ssh -p 22  -o StrictHostKeyChecking=no $remoteUserHost 'cd '$remoteProjectPath'  && gradlew clean'
}

function syncLocalFileToRemote() {
  sshpass -p $remoteUserPassword rsync -e 'ssh -p 22  -o StrictHostKeyChecking=no' --archive --delete --progress --exclude-from=$local_ignore  $projectDir/  $remoteProjectDir
}

function syncRemoteFileToLocal() {
  sshpass -p $remoteUserPassword rsync -e 'ssh -p 22 -o StrictHostKeyChecking=no' --archive --progress --include-from=$remote_include  --exclude-from=$remote_ignore  $remoteProjectDir/ $projectDir
}

function runApk() {
  echo "1.创建工程目录"
  remoteCreateProjectDir
  echo "2.远程工程写入local.properties文件"
  remoteConfigSDK
  echo "3.同步本地文件到远程"
  syncLocalFileToRemote
  echo "4.远程编译"
  remoteBuild
  echo "5.同步远程apk文件到本地"
  syncRemoteFileToLocal
  echo "6.安装apk文件"
  installApk
}

echo "--- $command ---"
case $command in
  (clean)
  clean
  exit
  ;;
  (sync)
  syncLocalFileToRemote
  exit
  ;;
  (install)
  installApk
  exit
  ;;
  (run)
  runApk
  exit
  ;;
esac
