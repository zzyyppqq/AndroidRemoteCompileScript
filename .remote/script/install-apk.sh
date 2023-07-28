#!/bin/sh

projectDir=$(cd $(dirname $0); cd ..;cd ..; pwd)
echo "projectDir: $projectDir"

appName=$1
buildType=$2

echo "appName: $appName"
echo "buildType: $buildType"

apkFindPath=""
if [ "$appName" ]; then
  apkFindPath=${projectDir}/${appName}/build/outputs/apk/${buildType}
else
  apkFindPath=.
fi

echo "apkFindPath: $apkFindPath"
echo "======= file list start ========"
ls -al $apkFindPath
echo "======= file list end ========"

find  $apkFindPath -name "*.apk" | while read fname; do
  echo "apk path: $fname"
  echo "======= file info start ========"
  stat -x $fnameTC
  echo "======= file info end ========"
#  -r : 覆盖原来安装的 APK 并保留数据
  aapt dump badging $fname | sed -n '1,3p'
  aapt dump badging $fname | grep 'launchable-activity'

  package=$(aapt dump badging $fname | grep 'package')
  package=${package:15}
  package=${package%%\'*}
  echo "package: $package"

  launchableActivity=$(aapt dump badging $fname | grep 'launchable-activity')
  launchableActivity=${launchableActivity:27}
  launchableActivity=${launchableActivity%%\'*}
  echo "launchableActivity: $launchableActivity"

  launchActivity=${package}/${launchableActivity}
  echo "apk parse launchActivity: $launchActivity"
  adb install -r -t $fname
  if [ "$launchActivity" ]; then
    adb shell am start $launchActivity
  fi
  break
done
