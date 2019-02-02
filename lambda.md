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


## 1.1.	Bug 54055 

描述：从TP910通过蓝牙发送的安装包只有1.6M，接收机无法安装换机助手，提示安装文件错误。

原因：TP910系统对预置应用apk默认进行了系统优化（odex优化，odex优化会将java文件和资源文件分开），使得分享的apk为优化过的apk（只分享了资源文件，java文件未分享），该apk不是完整的apk，无法直接安装。
解决方案：因为需要分享apk，所有换机助手不能使用odex优化，去除系统对换机助手的优化，使得分享的apk为完整apk。

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/114234/ 

## 1.2.	Bug 52598、54371
描述：发送机已插入SIM卡且开启移动数据，扫描连接二维码后，WiFi已连接上接收机热点，但提示连接超时。

原因：在同时开启wifi和移动网络时，如果wifi无法上网，系统会自动将默认网络切换为移动流量，导致Socket在连接时失败。（目前和驱动同事沟通，此为原生Android系统策略，后面自研项目进行了修改，不管wifi是否可以上网，都不进行切换，该问题就不存在了，但是为了兼容三方手机，还是需要此提交修改。）
解决方案：当wifi连接成功后，在应用层指定一定将已连接wifi作为默认网络，确认Socket可以正常连接。

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/113976/ 
http://mobilegit.rd.tp-link.net/gerrit/#/c/114434/ 

## 1.3.	Bug 52497
描述：传输过程中，发送方或接收方退到后台，开启省电模式后，连接立刻断开。

原因：省电模式下，应用切换到后台后，系统会禁止Socket传输数据，导致连接断开。

解决方案：将换机助手模块加入到自研ROM电池优化白名单，使得在省电模式下，切换到后台后可继续通过Socket传输数据。（该问题目前是驱动同事负责解决的，在此记录）

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/114133/ 
http://mobilegit.rd.tp-link.net/gerrit/#/c/114132/ 

## 1.4.	通过蓝牙分享安装换机助手apk后第一次打开进入选择数据界面。Home键退出，再次点击桌面lanucher进入主页界面而非之前退出的界面。
### 1.4.1.	问题分析

如果发出的Intent和某个后台task栈的启动Intent相同(不包括flag)，才会直接把这个后台task拿到前台。

从桌面打开的Intent和安装界面点击完成的Intent有不一致。所以不会将之前启动的activity直接调到前台。

### 1.4.2.	解决方案（未提交代码）
如果启动的MainActivity将被放在后台已经存在的应用task栈上并将这个task栈带到前台，
Intent中就会带有Intent.FLAG_ACTIVITY_BROUGHT_TO_FRONT，这时不要再启动acitivity了。

## 1.5.	换机助手权限适配
### 1.5.1.	权限适配策略
换机助手在首页即申请所有权限。每次启动换机助手首页在onStart()生命周期回调中检查相应权限。
1.	权限已经全部授予，正常流程进行
2.	若存在未授予的权限，弹出权限申请框供用户继续选择
 
### 1.5.2.	实现原理
换机助手的权限申请使用了三方框架RxPermission，顾名思义是采用Rxjava使用流式调用接口。
```java
RxPermissions rxPermissions = new RxPermissions(this);
final String[] permissions = getPermissions();
       if (permissions != null && permissions.length > 0) {
           rxPermissions.requestEach(getPermissions())
                   .subscribe(new Consumer<Permission>() {
                       @Override
                       public void accept(Permission permission) throws Exception {
                           if (permission.granted) {
                               // 用户已经同意该权限
                           } 
else if (permission.shouldShowRequestPermissionRationale) {
                  // 用户拒绝了该权限，没有选中『不再询问』,
那么下次再次启动时，还会提示请求权限的对话框
                               mShouldRequestPermissions.add(permission.name);
                           } else {
                               // 用户拒绝了该权限，并且选中『不再询问』
                               mDenyPermissions.add(permission.name);
                           }
                           mRequestPermissionCount++;

                           if (mRequestPermissionCount == permissions.length) {
                               onPermissionComplete();
                           }
                       }
                   });

```

### 1.5.3.	遇到的问题
在国产rom的手机上，权限适配是一个相当复杂的工作。这里记录遇到的问题。

1.	MIUI Android M之前的手机上的问题。总所周知在6.0上Google才提出动态申请权限。但是MIUI在Android6.0的手机上自己实现了一套类似的动态权限申请机制，对于读取短信，联系人等权限，MIUI认为是危险权限，当应用第一次试图去访问短信数据库时，系统会弹出权限确认框。用户点击同意后才能访问到短信数据；如果用户点击拒绝那么将无法获得数据并且下次进入仍然是拒绝状态且不再弹出权限申请框。
换机助手在数据选择界面需要统计短信、联系人、通话记录的数量，需要访问对应的数据库得到。如果正常情况，在MIUI上应该每次弹出相对应的权限申请弹框。但是为了效率换机助手统计数据时是并行执行。很明显手机系统不可能同时弹出多个权限申请框。导致每次只能弹出一个权限申请框。使得其他权限被拒绝。
根本原因就是通过系统api去查询是否拥有权限，返回的结果是true但是实际上并没有该权限。

## 1.6.	Bug 52454 
描述：接收端接收过程中，点击back键，确认停止接收后偶现换机助手停止运行。

原因：对外公开的连接管理类TcpAgent依靠几个全局变量来做判断，断开连接情况下，偶现某个线程将全局变量置空，而主线程读取使用的情况。

解决方案：为该类的各个公开方法增加同步锁，防止多线程冲突。

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/111389/
## 1.7.	Bug 53522 
描述：建立连接后，发送端进入数据选择页面，到设置->权限，关闭换机助手相机权限后，接收方断开连接，发送方始终不中断

原因：在设置中关闭权限，进程会被杀死，因此接收方会断开此时重新进入数据选择页，进程和页面都被重建，无法获取到连接断开标志

解决方案：修改判断条件，只要TcpClient为空，也即没有初始化过或已被清除，我们就认为连接已经断开

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/112801/

1.8.	Bug 54533 

描述：设置30S息屏后，在数据选择界面，等待手机息屏，息屏后很快就会中断连接

原因：为了准确感知socket连接时的对端断开，我们使用了双向心跳包机制，15s内接受不到心跳包，则认为对面断开。而息屏时，cpu休眠，导致对面的心跳包无法发出，因此连接会断开。

解决方案：在数据选择页面和等待接收页面onCreate时，持有WakeLock,阻止cpu进入休眠，在其onDestroy时释放该锁。 

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/115049/

## 1.9.	Bug 52381 

描述：发送端重复发送通话记录数据，接收端还原时进行合并而不会去重

原因：去重时使用了CallLog的is_read字段，该字段为未读，而电话app退到后台时，该字段会被置为已读，因此下次重发时，无法去重。

解决方案：去重时不进行is_read字段的判断。

提交见：http://mobilegit.rd.tp-link.net/gerrit/#/c/112232/
