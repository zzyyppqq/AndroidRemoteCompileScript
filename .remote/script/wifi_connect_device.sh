#!/bin/sh

set -e


if [ $# -lt 1 ]; then
  echo "-------------------------- 开始adb连接wifi ----------------------------"
  echo "没有命令行参数"
else
  echo "-------------------------- 断开adb wifi连接 ----------------------------"
  echo "params: $1"
    case $1 in
    (disconnect)
        echo "--- $1 ---"
        adb disconnect
        exit
        ;;
    esac
fi


addr=$(adb shell ifconfig | grep 'addr:192.168')
echo "addr: $addr"
ip='192.169.1.1'
array=(`echo $addr | tr ',' ' '` )
len=${#array[@]}
for var in ${array[@]}
do
   #echo "var: $var"
   if [[ $var =~ 'addr:' ]]; then
       ip=$var
   fi
done

port=5555
ip=${ip:5}
echo "ip: $ip, port: $port"
adb shell setprop service.adb.tcp.port $port
adb tcpip $port
adb connect "${ip}:${port}"