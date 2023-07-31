#!/bin/sh

echo "-------------------------- 开始远程编译 ----------------------------"
set -e

remoteDir=$(cd $(dirname $0); cd ..; pwd)
projectDir=$(cd $(dirname $0);cd ..; cd ..; pwd)
echo "remoteDir: $remoteDir"
echo "projectDir: $projectDir"
configPath=$remoteDir/remote.properties
echo "configPath: $configPath"
# 通过config.json获取应用build参数，从而按照指定应用
echo "-------- config info --------"
cat $configPath
echo ""
echo "----- properties parse ----------"

host=$(awk -F= '/host/{print $2}' $configPath)
port=$(awk -F= '/port/{print $2}' $configPath)
username=$(awk -F= '/username/{print $2}' $configPath)
password=$(awk -F= '/password/{print $2}' $configPath)
code=$(awk -F= '/code/{print $2}' $configPath)
sdk=$(awk -F= '/sdk.dir/{print $2}' $configPath)
ndk=$(awk -F= '/ndk.dir/{print $2}' $configPath)

echo "host: $host"
echo "port: $port"
echo "username: $username"
echo "password: $password"
echo "code: $code"
echo "sdk: $sdk"
echo "ndk: $ndk"

usernameHost=${username}@${host}

command=$1
moduleName=$2
buildType=$3

echo "shell params command: $command, moduleName: $moduleName, buildType: $buildType"

buildCommand=""
if [[ $buildType == "debug" ]]; then
  buildCommand="./gradlew assembleDebug -p $moduleName"
else
  buildCommand="./gradlew assembleRelease -p $moduleName"
fi
echo "---- buildCommand ---- "
echo "$buildCommand"

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

remoteProjectPath=${code}/${projectName}
echo "remoteProjectPath: $remoteProjectPath"

remoteProjectDir=${usernameHost}:${remoteProjectPath}
echo "remoteProjectDir: $remoteProjectDir"

remote_include=$projectDir/.remote/rsync/remote_include
remote_ignore=$projectDir/.remote/rsync/remote_ignore
local_ignore=$projectDir/.remote/rsync/local_ignore

function remoteCreateProjectDir() {
  sshpass -p $password ssh $usernameHost 'mkdir -p '$remoteProjectPath''
}

function remoteConfigSDK() {
  sshpass -p $password ssh $usernameHost 'cd '$remoteProjectPath' && rm -rf local.properties && (echo sdk.dir='$sdk') > local.properties'
}

function remoteBuild() {
  sshpass -p $password ssh -p 22  -o StrictHostKeyChecking=no $usernameHost 'cd '$remoteProjectPath' && '$buildCommand''
}

function installApk() {
  chmod 777 $projectDir/.remote/script/install-apk.sh && bash $projectDir/.remote/script/install-apk.sh $moduleName $buildType
}

function clean() {
  sshpass -p $password ssh -p 22  -o StrictHostKeyChecking=no $usernameHost 'cd '$remoteProjectPath' && ./gradlew clean'
}

function syncLocalFileToRemote() {
  sshpass -p $password rsync -e 'ssh -p 22  -o StrictHostKeyChecking=no' --archive --delete --progress --exclude-from=$local_ignore  $projectDir/  $remoteProjectDir
}

function syncRemoteFileToLocal() {
  sshpass -p $password rsync -e 'ssh -p 22 -o StrictHostKeyChecking=no' --archive --progress --include-from=$remote_include  --exclude-from=$remote_ignore  $remoteProjectDir/ $projectDir
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
