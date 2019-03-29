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
### 1. 项目介绍
录音机是一款基于Android 7.0及以上平台开发的录音App主要内容如下。

+ 录音内容包括：标准录音，短信调用录音（目前入口已经取消），锁屏快捷启动录音；
+ 录音格式包括：AMR格式和MP3格式（需要驱动提供支持）；
+ 存储路径包括：内置存储或者外置SD卡；
+ 过程记录和播放包括：对录制的内容进行打点标记、回放打点标记；
+ 录音列表：文件展示，录音播放和文件操作（删除、分享、重命名）。

### 2. 项目结构
#### 2.1.录音部分
##### 2.1.1 录音界面的继承关系
录音部分的界面类图如下：

![](activity继承关系.png)

1.BasePermissionActivity处理权限申请和sd权限相应的逻辑，其中用到了Permissionsdispatcher三方库

2.BaseRecordActivity封装了与录音相关的公共逻辑，主要代码都在其中

3.SoundRecorder是luancher启动正常录音，MessageRecorder是三方调用录音，之前自研短信会有相应的需求。

4.SecureSoundRecorder是锁屏下调用的录音界面。

##### 2.1.2 录音流程

![](录音流程.png)

具体实现由开启SoundRecordService服务在后台录音，录音的操作由MediaRecorder实现，封装在Recorder类中。

#### 2.2 录音动效
录音动效的具体实现类是SoundWaveView,动画原理是通过handler发送定时消息到SoundWaveView去调用invalidate，
在onDraw（）中刷新UI。

绘制的数据来源于Recorder中的成员变量mAmplitudes：List<Integer>,转化为对应的声音波纹的高度。

##### 2.2.1 实现细节
主要的绘制部分有三块上方时间轴刻度，竖直的线，声音波纹。根据录制时长分为两部分，第一段时长是中间竖直的线移动，上方时间轴刻度保持不动。第二段是到达某个时间点以后，竖直的线保持不动，移动上方的时间轴。

* 时间轴刻度

      第一段时长：drawStaticTimeMark() 原理就是drawline和drawtext

      第二段时长：drawDynamicTimeMark() 主要难点是根据当前录制的时间值判断各个时间刻度的位置以及当前位置所显示的时刻值

* 竖直的线

      第一段时长：根据当前录制时间判断所在的位置

      第二段时长：保持在固定地方不变

      绘制原理是drawLine和上下方个绘制一个圆角三角形drawTopTriangle() 和 drawBottomTriangle()

* 声音波纹

      根据传入的声音的振幅的List转化成对应的高度，具体细节在onDraw()。

#### 2.3 录音删除动效

  [见录音机Rom2.2总结文档。](http://mobileprj.rd.tp-link.net/redmine/projects/rom_soundrecorder/wiki)

#### 3.注意事项

##### 3.1 录音格式
录音格式分为AMR和MP3两种，在自研Rom下正常录音是MP3格式，在非自研Rom和三方调用录音是录制amr。
新加入一种芯片需要在PlatformBuildHelper判断是否需要加入相应的判断逻辑。


##### 3.2 听筒模式
听筒模式的切换的api是AudioUtil.setPlayingMode();为了防止用户快速点击听筒图标导致频繁切换的问题，在没有音乐播放的时候点击仅仅只是会记录状态，在真正播放时去设置听筒模式。在播放音乐时点击则立即切换状态。

听筒状态的恢复正常：
* 音乐播放完成
* 失去音频焦点
* 界面不可见并且没有音乐播放


和蓝牙以及耳机插入事件的交互（通过系统广播事件）：
```java
private BroadcastReceiver mHeadsetPlugReceiver = new BroadcastReceiver() {

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent.getAction();
        if (BluetoothA2dp.ACTION_CONNECTION_STATE_CHANGED.equals(action)) {
            final int state = intent.getIntExtra(BluetoothA2dp.EXTRA_STATE, BluetoothDevice.ERROR);
            if (state == BluetoothA2dp.STATE_CONNECTED) {
                // bluetooth connected
                mInBluetoothPlug = true;
                setRecevierModeButtonBackGround();
            } else if (state == BluetoothA2dp.STATE_DISCONNECTED) {
                // blueooth disconnect
                mInBluetoothPlug = false;
                setRecevierModeButtonBackGround();
            }
        } else if (BluetoothAdapter.ACTION_STATE_CHANGED.equals(action)) {
            int state = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
            if (state == BluetoothAdapter.STATE_OFF) {
              // 蓝牙关闭
                mInBluetoothPlug = false;
                setRecevierModeButtonBackGround();
            }

                  // 耳机插拔事件
        } else if (Intent.ACTION_HEADSET_PLUG.equals(action)) {
            if (!intent.hasExtra("state")) {
                return;
            }

            if (intent.getIntExtra("state", 0) == 0) {
                mIbReceiverMode.setEnabled(true);
                if (mIsReceiverMode && mPlayer != null && PlayerUtils.getIsPlaying()) {
                    AudioUtils.setPlayingMode(RecordListActivity.this, true);
                }
            } else {
                mIbReceiverMode.setEnabled(false);
                //此处退出听筒模式,ui状态不改变
                if (mIsReceiverMode) {
                    mAudioManager.setMode(AudioManager.MODE_NORMAL);
                }
            }
        }

    }
};
```
##### 3.3 录音文件的时间戳
录音文件显示的时间之前是读取的File.lastModified()，这样文件移动后会导致时间并非是录制时间。为了解决这个问题，驱动同事在录音文件头部内容中加入了文件的生成时间，现在录音文件的显示时间是从这里读取的。
```java
/**
     * 格式如下，可以通过第11~14 字节（从1开始计数）的“NFUI”来识别时间标签，
     * 时间记录在21 – 30字节，为epoch到现在的秒数
     *
     * @param file
     * @return
     */
    public static long recordOriginCreateTime(File file) {
        long timeStamp = 0;
        try (FileInputStream fis = new FileInputStream(file)) {
            byte[] bytes = new byte[32];
            int read = fis.read(bytes);
            if (read == 32) {
                String tag = new String(bytes, 10, 4);
                if (NFUI_TAG.equals(tag)) {
                    // 转换成毫秒值
                    timeStamp = Long.parseLong(new String(bytes, 20, 10)) * 1000;
                }
            }
        } catch (IOException e) {
            Log.e(TAG, "recordOriginCreateTime: ", e);
        }
        return timeStamp;
    }
```

##### 3.4 shortCut启动录音
![流程](shortcut.png)

控制文件在xml/shortcuts.xml 文件中。
