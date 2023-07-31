# Android远程编译（Mac控制Windows远程编译）

## 准备

### 安装sshpass （使用账号、密码登陆远程服务器）

解压.remote/file中的 sshpass-1.08.tar.gz 文件，并进入sshpass-1.08目录，执行以下命令，编译安装sshpass

```shell
./configure
make
make install
```

## 使用步骤

### 将.remote文件夹拷贝至任意Android项目的根目录

编辑remote.properties，配置远程服务器信息
```properties
host=192.168.9.65
port=22
username=zyp
password=123456
code=~/code
sdk.dir=/Users/zyp/Library/Android/sdk
ndk.dir=/Users/zyp/Library/Android/sdk/ndk-bundle
```

### 为Android项目的所有android类型的build.gradle添加最后一行添加以下脚本
```build.gradle
android {
    ...
}
# 远程服务器为Windows
apply from: '../.remote/gradle/android_remote_windows_compile.gradle'
# 远程服务器为Linux
apply from: '../.remote/gradle/android_remote_linux_compile.gradle'
```

### 点击Android Studio的同步按钮, 即可生成gradle task，如下图：
- android_remote
  - remoteClean （清理远程服务器上的build文件）
  - remoteRunDebugApk/remoteRunReleaseApk （同步本地最新代码到远程服务器上，并在远程服务器上编译生成apk，同步apk到本机，最后运行到设备上并打开apk）
  - remoteInstallDebugAPK/remoteInstallReleaseAPK （安装已存在在build目录下的apk）
  - remoteSyncFile   （同步本地最新代码到远程服务器上）

[](imgs/gradle.png)

