# Android远程编译（Mac控制Windows远程编译）

## 准备

### 安装jq（json解析库，主要为解析config.json）
```shell
brew install jq
```

### 安装sshpass （使用账号、密码登陆远程服务器）

解压.remote/file中的 sshpass-1.08.tar.gz 文件，并进入sshpass-1.08目录，执行以下命令，编译安装sshpass

```shell
./configure
make
make install
```

## 使用步骤

### 将.remote文件夹拷贝至任意Android项目的根目录

编辑config.json，配置远程服务器信息
```json
{
  "host": "192.168.2.100",
  "port": "22",
  "username": "zyp",
  "password": "123456",
  "code": "~/code",
  "sdk": "C\\:\\\\Users\\\\zyp\\\\AppData\\\\Local\\\\Android\\\\Sdk",
  "ndk": ""
}
```

### 为Android项目的所有android类型的build.gradle添加最后一行添加以下脚本
```build.gradle
android {
    ...
}

apply from: '../.remote/gradle/android_remote_compile.gradle'
```

### 点击Android Studio的同步按钮, 即可生成gradle task，如下图：
- remoteClean （清理远程服务器上的build文件）
- remoteRunDebugApk/remoteRunReleaseApk （同步本地最新代码到远程服务器上，并在远程服务器上编译生成apk，同步apk到本机，最后运行到设备上并打开apk）
- remoteInstallDebugAPK/remoteInstallReleaseAPK （安装已存在在build目录下的apk）
- remoteSyncFile   （同步本地最新代码到远程服务器上）

[](./imgs/gradle.png)

