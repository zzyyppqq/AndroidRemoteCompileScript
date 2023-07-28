#读取属性文件指定键的值
getPropertiesValue() {
  result=""
  proFilePath="$1"
  key="$2"
    if [ "WJA${key}" = "WJA" ]; then
    echo "参数错误，未能指定有效Key。"
    echo "" >&2
    exit 1
  fi
  if [ ! -f ${proFilePath} ]; then
    echo "属性文件（${proFilePath}）不存在。"
    echo "" >&2
    exit 1
  fi
  if [ ! -r ${proFilePath} ]; then
    echo "当前用户不具有对属性文件（${proFilePath}）的可读权限。"
    echo "" >&2
    exit 1
  fi
  keyLength=$(echo ${key}|wc -L)
  lineNumStr=$(cat ${proFilePath} | wc -l)
  lineNum=$((${lineNumStr}))
  for ((i = 1; i <= ${lineNum}; i++)); do
    oneLine=$(sed -n ${i}p ${proFilePath})
    if [ "${oneLine:0:((keyLength))}" = "${key}" ] && [ "${oneLine:$((keyLength)):1}" = "=" ]; then
      result=${oneLine#*=}
      break
    fi
  done
  return ${result}
}