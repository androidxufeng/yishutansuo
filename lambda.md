### 函数式接口
只拥有一个方法的接口。java8 专门的java.util.functin包包含了常用的函数式接口。

### 示例
```java
(int x, int y) -> x + y  // 代表参数是两个int值，返回int型的结果

() -> 42                 // 没有参数，返回值是int

(String s) -> { System.out.println(s); }  // 参数是string，无返回值

new Thread(() -> {
  connectToService();
  sendNotification();
}).start();
```

### 目标类型
由于lambda表达式省略了接口和函数名，例如
```java
FileFilter java = f -> f.getName().endsWith(".java");

Comparator<String> c = (s1, s2) -> s1.compareToIgnoreCase(s2);
```

## 1.	热点相关总结
### 1.1.	不同Android版本创建和关闭热点的方式
#### 1.1.1.	系统应用如何创建和关闭热点
系统应用因为一般具有系统级别的签名，所以相对于三方应用来说，会有较高的权限，在创建热点时相对选择会更多一些。
换机助手因为是具有系统签名的应用，所以采用的就是如下这种方式创建。

+ Android 7.1以前

Android7.1以前，虽然Google官方没有开放给外部直接调用开启热点的API，但是可以通过反射的方式来开启和关闭热点，
具体如下：
```java
WifiManager wifimanager = (WifiManager) context.getSystemService(context.WIFI_SERVICE);
WifiConfiguration wifiConfiguration = buildApConfig(SSID, password);
//使用反射开启Wi-Fi热点
Method method = wifimanager.getClass().getMethod("setWifiApEnabled",
        WifiConfiguration.class, boolean.class);
method.invoke(wifimanager, wifiConfiguration, true);
```
	其中wifiConfiguration为热点的信息，包括ssid、密码、加密方式等等，可以任意指定。
	关闭热点方法和开启调用方法一样，只不过是传入参数稍有区别。
  
+ Android7.1及以后

Android7.1及以后，上述通过反射调用的方法不再被允许，该方法被标记为废弃方法，并且内部实现已经为空实现，官方注释也说明后续不再允许通过该种方式创建热点。并且因为在Android P开始，反射调用的方式也将不再允许，只能通过其他非反射调用方式去创建热点。
在Android7.1及以后，官方给出的创建热点的方式有两种：

1 . 通过ConnectivityManager的startTethering方法来创建。

通过这种方式创建的热点需要系统级别的权限，即只有系统签名的应用才可以，并且可以指定SSID和密码等，
目前换机助手使用的就是这种方式。具体创建方式如下：
```java
WifiManager wifimanager = (WifiManager) context.getSystemService(context.WIFI_SERVICE);
ConnectivityManager connectivityManager = (ConnectivityManager) context
        .getSystemService(Context.CONNECTIVITY_SERVICE);

OnStartTetheringCallback startTetheringCallback = new OnStartTetheringCallback();

WifiConfiguration wifiConfiguration = buildApConfig(SSID, password);
wifimanager.setWifiApConfiguration(wifiConfiguration);

connectivityManager.startTethering(ConnectivityManager.TETHERING_WIFI, true, startTetheringCallback, mHandler);
```
其中OnStartTetheringCallback为热点开启与关闭后的监听回调，返回速度依赖于系统。
关闭热点方式直接调用ConnectivityManager的stopTethering方法即可。

2.	通过WifiManager的startLocalOnlyHotspot。

通过这种方式可以创建固定格式SSID和密码的热点，并且无法人为指定这些配置。虽然这种方式也可以创建热点，
但是因为其无法修改热点配置的局限性，所以比较适合于一些三方应用创建热点，如果需求设计中需要制定热点配置信息，
该方式无法达到要求。经过调研和验证，目前三方的app比如腾讯闪电换机等即使用该方式。

#### 1.1.2.	三方应用如何创建和关闭热点

三方应用时相对于系统应用来说的，因为三方应用没有系统签名，所有无法获取到一些特殊权限来创建热点，
必须遵循Google官方文档中开放的API去创建。三方应用创建热点如前面所述，在Android7.1之前可以通过反射的方式创建；
在Android7.1之后，只能通过WifiManager的startLocalOnlyHotspot方式来创建。

### 1.2.	监听热点状态变化
在一些情况下，创建或者关闭热点后，需要监听到热点创建和关闭成功消息后，再进行其他后续操作，
比如换机助手需要在监听到热点创建成功后再进行根据热点信息生成二维码信息；再比如在关闭热点时，
需要监听到热点关闭成功消息后，才能让用户进行后续操作，否则会有一些复杂的场景问题。

Android系统在热点状态改变时，会发出一个广播供应用来监听，广播对于的action为：

> android.net.wifi.WIFI_AP_STATE_CHANGED

监听到该广播后，应用通过广播传入的intent获取其携带的wifi_state对应的值，即为当前热点的状态，具体如下：
```java
//热点的状态为：正在关闭:10；已关闭:11；正在开启:12；已开启:13;
int state = intent.getIntExtra("wifi_state", 0);
```

### 1.3.	保存热点信息和恢复热点信息

换机助手UE需求中要求在应用开启热点前保存之前手机中热点信息的配置，并且在使用结束后，
恢复之前用户热点信息，提高用户体验。因为恢复热点信息需要在一定的时机进行，所以如果在使用应用时，
用户强行杀掉应用或者系统将应用清理，这种情况是无法监听到的，也就无法恢复。

#### 1.3.1.	热点信息保存
热点信息保存，需要先获取到当前热点信息，信息对应的即为WifiConfiguration，具体获取该WifiConfiguration方式如下：
```java
WifiManager wifimanager = (WifiManager) context.getSystemService(context.WIFI_SERVICE);
WifiConfiguration wifiConfiguration = wifimanager.getWifiApConfiguration();
```

  获取到该wifiConfiguration后，即可临时保存起来用于恢复。
  
#### 1.3.2.	热点信息恢复
在上面保存了wifiConfiguration后，恢复热点信息时只需调用系统提供的setWifiApConfiguration方法，
传入已保存配置即可恢复。具体实现如下：
```java
WifiManager wifimanager = (WifiManager) context.getSystemService(context.WIFI_SERVICE);
return wifimanager.setWifiApConfiguration(wifiConfiguration);
```
## 2.	Wifi相关总结
wifi相关处理基本都是通过WifiManager类，相对于热点来说处理起来不会涉及到太多权限等问题，
主要需要了解wifi安全类型和连接到指定wifi流程即可。

### 2.1.	Wifi安全类型
Wifi安全类型较多，每种类型对应的是不同的加密算法，具体可见源码WifiConfiguration.KeyMgmt类中，
每种类型的详细说明可参考源码注释，下面是常见的几种方式：
```java
public static final int NONE = 0;
public static final int WPA_PSK = 1;
public static final int WPA_EAP = 2;
public static final int IEEE8021X = 3;
public static final int WPA2_PSK = 4;
```
换机助手目前使用的是WPA_PSK方式，该种方式和WPA2_PSK比起来虽然安全等级差一些，
但是因为是系统级别的权限，因为需要兼容三方手机，所以不选择。

### 2.2.	连接到指定wifi流程

连接到某一指定wifi流程如下：
+ 判断wifi开关是否开启（wifiManager.isWifiEnabled()），如果未开启，则打开wifi开关
（wifiManager.setWifiEnabled）（因为wifi开启需要一定的时间，
所以此时需要循环判断wifi是否打开（wifiManager.isWifiEnabled()），
目前换机助手等待时间为10s，如果10s内还未打开，则提示超时）；
+ 根据传入需要连接的wifi信息准备WifiConfiguration；
+ 根据需要连接的ssid判断当前手机中是否已经保存与该ssid相同名称的wifi
（通过wifiManager.getConfiguredNetworks()获取到所有已保存wifi后进行判断）；
如果之前已经有保存相同ssid的wifi，则移除该已保存wifi（wifiManager.removeNetwork）；
加入需要连接的wifi（wifiManager.addNetwork），并开启（wifiManager.enableNetwork）。

## 3.	二维码相关总结
换机助手涉及到的二维码功能为：根据热点信息生成二维码、扫描二维码、二维码信息保存换机助手apk下载地址。
二维码相关功能Google官方有自己的相关库ZXing：https://github.com/zxing/zxing，使用ZXing无需将源码导入，
直接使用jar包即可。官方ZXing库的界面是一个很简陋的样式，但是其生成二维码、扫描二维码功能是比较完善的，
所以我们只需要基于ZXing定制自己的UI就可以达到目的。
换机助手二维码相关功能是基于了Github项目：xxxx进行，该项目也是基于ZXing完成，暂时未对其具体实现进行深入研究，
后续考虑重构时再进行研究总结.

## 4.	蓝牙分享已安装apk总结
已安装apk在手机系统的/data/app/xxxx/目录下会保留一个apk（其中xxx为系统自动生成和应用包名相关的字符串），
应用可以通过系统提供接口获取到其路径，生成Uri后，即可调用系统的分享功能分享该apk。具体实现如下：
```java
String apkPath = getPackageResourcePath();
File apkFile = new File(apkPath);

Uri uri;
if (VersionUtils.isNougat()) {
    uri = FileProvider.getUriForFile(this, Constants.AUTHORITY, apkFile);
   } else {
    uri = Uri.fromFile(apkFile);
}

Intent intent = new Intent(Intent.ACTION_SEND);
intent.setPackage("com.android.bluetooth");
intent.putExtra(Intent.EXTRA_STREAM, uri);
intent.setType("*/*");
startActivity(intent);
```

遗留未解决：目前通过上述方式获取到的apk名称均为base.apk，之前UE要求看是否可以修改其名称，
但是如果修改文件名称后，会使得Uri无法找到对应文件，导致无法传输。目前还未找到解决办法，
后续需要继续研究，看是否有其他方案分享。

## 5.	预置换机助手到ROM总结
换机助手需要以可卸载的方式预制到ROM中。经过查找资料和参考之前预制在ROM中可卸载的应用，
在mtk平台中，在系统编译生成镜像时，只需要将apk打包到out/vendor/operator/app目录下，
即以可卸载的方式编到系统中，所以只需要修改换机助手打包到系统中的Android.mk文件即可，
详细如下，标红处是和其他预制到系统不可卸载应用的区别：

    # TPBackupAndRestore
      LOCAL_PATH := $(call my-dir)
      include $(CLEAR_VARS)
      LOCAL_MODULE := TPBackupAndRestore
      LOCAL_MODULE_CLASS := APPS
      LOCAL_MODULE_TAGS := optional
      LOCAL_BUILT_MODULE_STEM := package.apk
      LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
      #LOCAL_PRIVILEGED_MODULE := LOCAL_CERTIFICATE := platform
      ifneq (,$(filter user ,$(TARGET_BUILD_VARIANT)))
        LOCAL_DPI_VARIANTS := xxhdpi xhdpi hdpi
        LOCAL_DPI_FILE_STEM := $(LOCAL_MODULE)_%.apk
        LOCAL_SRC_FILES := $(LOCAL_MODULE).apk
      else
        LOCAL_SRC_FILES := $(LOCAL_MODULE)_debug.apk
      endif
        LOCAL_MODULE_PATH := $(TARGET_OUT_VENDOR)/operator/app
        LOCAL_DEX_PREOPT := false





