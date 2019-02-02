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

## 1.	传输模块model层总结
换机助手应用中，我们需要将备份方手机的数据写入到文件，将该文件传输到还原方，以便能够进行还原。
我们采用的传输方案为，基于tcp/ip协议，使用java的阻塞io(BIO)库socket和serverSocket来创建客户端和服务器，
使用自定义协议来完成文件的传输。

+ 为何选择tcp/ip协议，而不是udp协议

  答：tcp/ip是面向链接的可靠协议。采用了自动分块，超时重传，数据包编号，校验和等多种措施，保证数据可以按照正确顺序完整的从发送方传输到接收方。而udp协议不保证传输的可靠性，需要应用层自己实现。文件传输需要保证可靠性，所以选择tcp/ip。
+ 为何使用BIO，而不是非阻塞io(NIO)

  答：BIO的读写操作都是阻塞的，每多一个客户端连接，服务器就需要多开启一个线程，不适用与高并发场景，优点为编程简单。NIO的读写操作都是非阻塞的，一个线程可以处理多个客户端连接，适用于高并发场景，但是编程复杂。我们的换机助手只有一个客户端，因此我们采用了简单的BIO。

### 1.1. 整体设计
 
TcpClient使用了装饰模式，代表tcp客户端，可以使用它连接，发送数据，注册监听。

TcpServer代表tcp服务器，使用它开启服务器，连接成功后，服务端也使用TcpClient进行操作。

ReadTask,writeTask，读写线程,socket的读写操作将在其中进行，外部无需关心线程管理。

PacketWrite,PacketRead,从socket读写数据包。

Packet,数据包对象，分为发送文件的数据包和发送指令的数据包。

TcpClientDispatch,客户端事件分发器，负责将事件分发到监听器中。

TcpClientListener,TcpServerListener,客户端事件监听器，可以监听连接，发送，接收数据等事件。
```java
public interface TcpClentListener {
    boolean onSocketConnect(TcpClient client, ConnectInfo info);
    boolean onSocketDisconnect(TcpClient client, String msg, Exception e);
    boolean onSocketConnectFail(TcpClient client, String msg, Exception e);
    boolean onSendBegin(TcpClient client, Packet packet);
    boolean onSendProcess(TcpClient client, Packet packet, TcpProcess process);
    boolean onSendEnd(TcpClient client, Packet packet, long totalTime);
    boolean onReceiveBegin(TcpClient client, Packet packet);
    boolean onReceiveEnd(TcpClient client, Packet packet, long totalTime);
    boolean onReceiveProcess(TcpClient client, Packet packet, TcpProcess process);
    boolean onIoThreadStart(TcpClient client, boolean read);
    boolean onIoThreadShutdown(TcpClient client, boolean read, Exception e);
    boolean onExceptionOccur(TcpClient client, String msg, Exception e);
    int priority();
}
```

PacketWrite,PacketRead,从socket读写数据包。

Packet,数据包对象，分为发送文件的数据包和发送指令的数据包。

TcpClientDispatch,客户端事件分发器，负责将事件分发到监听器中。

TcpClientListener,TcpServerListener,客户端事件监听器，可以监听连接，发送，接收数据等事件。

```java
public interface TcpClentListener {
    boolean onSocketConnect(TcpClient client, ConnectInfo info);
    boolean onSocketDisconnect(TcpClient client, String msg, Exception e);
    boolean onSocketConnectFail(TcpClient client, String msg, Exception e);
    boolean onSendBegin(TcpClient client, Packet packet);
    boolean onSendProcess(TcpClient client, Packet packet, TcpProcess process);
    boolean onSendEnd(TcpClient client, Packet packet, long totalTime);
    boolean onReceiveBegin(TcpClient client, Packet packet);
    boolean onReceiveEnd(TcpClient client, Packet packet, long totalTime);
    boolean onReceiveProcess(TcpClient client, Packet packet, TcpProcess process);
    boolean onIoThreadStart(TcpClient client, boolean read);
    boolean onIoThreadShutdown(TcpClient client, boolean read, Exception e);
    boolean onExceptionOccur(TcpClient client, String msg, Exception e);
    int priority();
}
```

### 2.2.	自定义协议
 
+ 数据传输协议没有看到对数据的校验，是否可以保证数据正确传输？

  答：数据传输的正确性，由tcp/ip协议的底层保证，它是面向链接的可靠协议。
  tcp/ip协议采用了自动分块，超时重传，数据包编号，校验和等多种措施，
  保证数据可以按照正确顺序完整的从发送方传输到接收方，因此应用层协议无需对数据进行校验。
  
+ 什么是粘包，如何避免粘包？

  答：tcp/ip协议是流式协议，没有数据包的概念，而我们应用层需要有数据包的概念来方便接收方解析协议。
  对于aaa  bbb这样分成2次写入的信息，接收方可能接收的信息为aaabbb, aa ab bb 等，这样我们就没法解析了。
  因此我们采用了在信息前加入length长度的方法来分包。还可以采用定长包，分割符号等方法来分割包。

+	为何不直接使用http或者webSocket协议，而是要自定义协议？

  答：Http协议采用的是客户端发送一次请求，之后等待服务端响应的通信方式，而服务端无法主动向客户端发起请求。
  而我们需要双向通信，无法使用单向的协议
  webSocket可以实现双向通信，但是建立服务器较为复杂，需要引入三方库，因此我们采用了自定义协议的方式，方便订制。

+	如何将请求报文和响应报文关联起来？

  我们进行如下3个约定。
  有一个请求，就有且只有一个响应。
  请求报文的type为单数，对应的响应报文的type为请求报文加1。
  响应报文的serial字段和请求报文一致。
  
+ 自定义协议的类图如下：

自定义协议的基类为抽象类Packet。包含了我们之前说的各个变量。读，写操作均使用了模板方法模式，
需要子类实现读写长度和内容的方法。子类CmdPacket用于传输指令，FilePacket用于传输文件。
IPacketFactory接口则是工厂方法模式，提供了创建各个协议的工厂。
```java
public abstract class Packet {
	 public final void write(BufferedSink sink, TcpClientDispatch dispatch) throws Exception {
		beforeWrite();
		sink.writeShort(mType);
		sink.writeShort(mVersion);
		sink.writeInt(mSerial);
		writeLength(sink);
		writeContent(sink, dispatch);
		sink.flush();
	}

    protected final void read(BufferedSource src, TcpClientDispatch dispatch) throws Exception {
        mVersion = src.readShort();
        mSerial = src.readInt();
        mLength = src.readLong();
        readContent(src, dispatch);
    }
	
	protected abstract void writeLength(BufferedSink sink) throws Exception;

    protected abstract void writeContent(BufferedSink sink
            , TcpClientDispatch dispatch) throws Exception;

    protected abstract void readContent(BufferedSource src
            , TcpClientDispatch dispatch) throws Exception;
}
```

### 1.3.	心跳机制

我们使用心跳包的目的是检测到对端断开连接，其步骤如下：
1. 设置某一端的读超时时间为15s
```java
mSocket.setSoTimeout(mConfig.getReadTimeout());
```
2. 让另一端每隔10s发送一个空包
```java
private Runnable mHeartbeatRun = new Runnable() {
        @Override
        public void run() {
            if (mWriter != null) {
                mWriter.cancel(ProtocolEnum.HEART_BEAT.getCmd());
            }
            sendCmd(ProtocolEnum.HEART_BEAT.getCmd(), null);
        }
    };
```
3. 只要某一端15s内没有收到数据，则底层会抛出超时异常，我们捕获该异常，就知道了连接已经断开。

### 1.4.	整体设计
 
从整体上看，传输模块的应用层也采用了mvp的架构方式，不过由于传输模块的特殊性，
因此其mvp和常规的mvp有一些不同之处，下面我们分别解释。
Model层，即我们上一章说的以TcpClient为核心的一系列类，
存放在modellibrary下的source/transfer包下，该模块以及一些java bean组成了传输模块的model层，
没有使用一般model层的数据仓库形式。
Present层，即上图中SendPresent和ReceivePresent的一系列类，传输模块中的Present和一般的Present有以下几点不同。
-	Present的生命周期比相应View的生命周期要长，Present的生命周期开始于Socket连接建立，结束于Socket连接断开。Present开始工作，收发数据包时，View可能尚未启动。
-	Present需要控制文件和信息的收发，因此我们需要实现TcpClientListener接口，也就是说，这里的Present实际是监听器和我们平时使用的Present这2个角色的结合。
-	由于我们的Present需要处理接收数据包，而数据包的接收时间是完全不确定的，相比于一般的Present中都是我们主动请求事件触发数据源的变化，我们这里的数据源变化是被动的，因此就带来了新的挑战。

View层，和普通的View基本一致，我们定义了ITransferView这个接口，其中定义了传输过程中所有需要的方法，SendFragment和ReceiveFragment就是其实现类。

### 1.5.	Present设计
由于我们之前说过Present的生命周期开始于Socket连接建立，结束于Socket连接断开。
比View的生命周期长，因此我们平时使用的在View onCreate时创建Present是无法使用了。

-	Present生命周期管理
为了应对这种情况以及方便外界使用，我们将SendPresent和ReceivePresent设计成了全局的单例模式，
其生命周期开始和结束对应于init和clear方法

```java
static class Instance {
	private Instance() {
  static SendPresent sInstance = new SendPresent();
}

public static SendPresent getInstance() {
	return Instance.sInstance;
}
 
 public void init(TcpClient client) {
	clearWaitingTasks();
	//保存TcpClient
	this.mClient = client;
	//...初始化其他变量
}

protected void clear() {
	mClient = null;
	//...将所有局部变量清空
}
```

这样由于Present是全局单例的，我们就可以随时随地的使用，而不用管它的对象是否创建或者销毁。同时如果Present的生命周期真正结束了，也就是Socket连接断开后，会清除其内部所有的局部变量，这样就避免了内存泄漏。

此外，由于Present是全局的，其内部数据在Present生命周期结束前并不会被销毁，这样就带来了一个额外的好处，即切换语言或旋转屏幕，导致配置变化时，不会影响连接和文件的传输，也不会影响数据的显示，View重建时，会将当前数据显示在其上。

-	View生命周期管理
由于我们的Present对象是常驻的，而View的生命周期是有限的，所以我们也需要管理View的生命周期。
一方面，View创建时，Present需要保存其引用，已方便ui显示。另一方面，View销毁时
，Present需要销毁其引用以及相关对象，防止内存泄漏。我们使用下面2个方法来处理View创建和销毁。

```java
public void transferUiCreate(ITransferView view) {
	//保存View的引用
	this.mTransferView = view;
	//如果Present还没有初始化而View已经创建了，则我们关闭View。
	if (mClient == null) {
		closeTransferView(new QuitBean(Constants.UNKNOWN_ERROR), QUIT_WITH_DIALOG);
		return;
	}
	//将当前的待传输列表和进度等信息显示到View上
	restoreUiIfNeed();
	//恢复ui任务
	restoreUiTasks();
}

public void transferUiDestory() {
	if (mWaitingTransferViewTasks != null) {
		mWaitingTransferViewTasks.clear();
	}
	//移除所有显示ui的handler的信息
	if (mUiHandler != null) {
		mUiHandler.removeCallbacksAndMessages(null);
	}
	//清空View的引用，防止内存泄漏
	this.mTransferView = null;
}
```
### 1.6.	Present和View生命周期不同步的处理

我们已经知道，传输模块中，Present的生命周期长于View的生命周期，这样就会导致一些问题。
举个例子，建立连接后，发送方选择少量通话记录发送，由于通话记录文件很小，瞬间就发送完成，
而此时接收方还处在等待传输页面，接收页面还没有启动，因此也就无法跳转到还原页面，导致无法还原。

从上述例子我们可以看到，由于Present收发数据时，View可能尚未建立，所以我们更新ui的操作可能得不到执行，我们需要一种机制，在ui界面没有起来时，记录下Present的更新ui请求，并在ui建立时，执行记录下来的请求。
我们首先使用一个id和runnable对象来表示一个等待ui创建完成才会执行的任务，并使用一个列表存储所有等待的任务。

```java
static class UITask {
	public final Runnable run;
	public int id;
}

private List<UITask> mWaitingTransferViewTasks;
```

其次，我们使用一个统一的方法，来执行所有的更新ui操作。如果ui已经创建，则直接执行该任务，
否则我们根据需要将该任务加入等待列表中。
```java
protected synchronized void runInTransferUi(Runnable run,
	@UITask.Id int id, boolean wait) {
	//如果View已经建立，则直接执行请求
	if (mTransferView != null) {
		if (isMainThread()) {
			run.run();
		} else {
			mUiHandler.post(run);
		}
	} else if (wait && mWaitingTransferViewTasks != null) {
		//如果View尚未建立，且我们的等待标志为真，我们将请求加入列表中
		mWaitingTransferViewTasks.add(new UITask(run, id));
	}
}
```
最后，我们在ui创建的transferUiCreate方法中，执行所有的存储在等待列表中的任务，
这样我们的更新ui请求就不会因为ui还未启动而得不到执行了。
```java
private void restoreUiTasks() {
	//等待列表为空，直接返回
	if (mWaitingTransferViewTasks == null) {
		return;
	}
	//省略部分代码
	for (UITask task : maps.values()) {
		//执行runnable中的操作。
		runInTransferUi(task.run);
	}
	//由于我们已经执行完了所有等待的操作，现在清空等待列表
	clearWaitingTasks();
}
```
### 1.7.	外部如何处理TcpClient接收到的数据包
一般的文件和指令数据包，我们都已经在Present中进行了处理，其他的界面无需关心。但是有2种特殊的数据包，需要其他ui的参与。一个是断开连接信息，所有的备份页面和等待传输页面都需要该信息，以便弹出断开连接的弹框；另一个是等待传输页面，需要知道接收传输列表信息，以便跳转到接收页面，开始接收。

由于我们的Present对应了传输页的ui，而接收数据又在Present中进行，因此我们需要把这些信息从Present中传递到其他ui，不适合采用定义View接口的形式。

可以采用的方式有以下几种，EventBus，考虑到需要另外引入包，没有采用；全局广播，效率较低，其他应用还可以监听到，也未采用；最终我们采用的是局部广播的方式，来发出信息。 

```java
public class TcpMsgUtil {

    private TcpMsgUtil() {
    }
	
    public static final String ACTION_QUIT = "action_quit";
    public static final String EXTRA_QUIT_REASON = "extra_quit_reason";
    public static final String ACTION_RECEIVE_WAITING_LIST = "action_receive_waiting_list";
    public static final String ACTION_NAV_HOME = "action_nav_home";

    public static void sendQuitMsg(Exception e) {
        if (e == null || !(e instanceof QuitException)) {
            return;
        }
        QuitException ex = (QuitException) e;
        QuitBean quit = ex.mQuit;
        LocalBroadcastManager lm = LocalBroadcastManager.getInstance(
                BackupAndRestoreApplication.getsInstance());
        Intent i = new Intent(ACTION_QUIT);
        i.putExtra(EXTRA_QUIT_REASON, quit);
        lm.sendBroadcast(i);
    }

    public static void sendWaitingListMsg() {
        LocalBroadcastManager lm = LocalBroadcastManager.getInstance(
                BackupAndRestoreApplication.getsInstance());
        Intent i = new Intent(ACTION_RECEIVE_WAITING_LIST);
        lm.sendBroadcast(i);
    }
}

```
而对于接收这些事件的ui界面，我们固然可以选择在每一个Activity进行注册广播，监听事件并处理等操作。
但是由于对于事件的处理，基本都是一致的，所以为了减少重复代码量，我们抽象了一个基类BaseAppActivity，
该类提供了对这几种事件的默认处理，以及是否需要接受某种类型事件的控制，其他Activity只要继承该基类，
就拥有了对于断开连接等事件的处理能力。
```java
public abstract class BaseAppActivity extends BaseActivity {

    protected BroadcastReceiver mReceive;

    @Override
    protected void onCreate(@Nullable Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
		//省略部分代码...
        if (canRecNavMsg() || canRecQuitMsg() || canRecWaitingListMsg()) {
            mReceive = new BroadcastReceiver() {
                @Override
                public void onReceive(Context context, Intent intent) {
                    String action = intent.getAction();
                    if (TcpMsgUtil.ACTION_NAV_HOME.equals(action)) {
                        receiveNavHome();
                    } else if (TcpMsgUtil.ACTION_QUIT.equals(action)) {
                        QuitBean bean = (QuitBean) intent.getSerializableExtra(TcpMsgUtil.EXTRA_QUIT_REASON);
                        receiveQuitMsg(bean);
                    } else if (TcpMsgUtil.ACTION_RECEIVE_WAITING_LIST.equals(action)) {
                        receiveWaitingListMsg();
                    }
                }
            };
            IntentFilter filter = new IntentFilter();
                   if (canRecNavMsg()) {
                       filter.addAction(TcpMsgUtil.ACTION_NAV_HOME);
                   }
                   if (canRecQuitMsg()) {
                       filter.addAction(TcpMsgUtil.ACTION_QUIT);
                   }
                   if (canRecWaitingListMsg()) {
                       filter.addAction(TcpMsgUtil.ACTION_RECEIVE_WAITING_LIST);
                   }
       
                   LocalBroadcastManager lm = LocalBroadcastManager.getInstance(
                           getApplicationContext());
                   lm.registerReceiver(mReceive, filter);
               }
           }
       
           @Override
           protected void onDestroy() {
               super.onDestroy();
               if (mReceive != null) {
                   LocalBroadcastManager lm = LocalBroadcastManager.getInstance(
                           getApplicationContext());
                   lm.unregisterReceiver(mReceive);
               }
           }
       
           protected boolean canRecNavMsg() {
               return false;
           }
       
           protected boolean canRecQuitMsg() {
               return false;
           }
           protected boolean canRecWaitingListMsg() {
               return false;
           }
       
           protected boolean isSend() {
               return true;
           }
       
           protected void receiveQuitMsg(QuitBean bean) {
               //if we are not in transfer ui,we only give a disconnnet display
               QuitBean quit = new QuitBean(Constants.TRANSFER_ERROR);
               QuitDialog dialog = QuitDialog.newInstance(quit, isSend());
               DialogUtil.show(getSupportFragmentManager(), dialog, QuitDialog.TAG);
               NotificationMgr.getInstance().notifyQuit(bean, getClass(), true);
           }
       
           protected void receiveWaitingListMsg() {
               Intent i = new Intent(this, ReceiveActivity.class);
               startActivity(i);
               finish();
           }
       }

```

使用了该设计之后，我们在自测中发现，某些时候，发送端发送了备份数据，而接收端竟然停止在等待接收页面，而不会进入接收页面，但是此时实际接收已经完成了，这是为什么呢？

经过分析我们发现，还是TcpClient接收的数据时机完全随机的问题，此情况下，连接建立后，接收方的TcpClient已经接收到了传输列表，并发出了广播，但是此时等待接收页面还未启动，因此也就没有注册广播，无法接受到该信息，导致无法跳转。

那这个问题如何解决了，这个时候，全局的Present又派上了用场，虽然广播没有接受，但是我们的Present中记录了实际的数据和状态啊。因此我们在BaseAppActivity启动时，先判断是否接受到了传输列表或者连接中断信息，如果接受到，则直接处理即可。

```java
protected void onCreate(@Nullable Bundle savedInstanceState) {
	super.onCreate(savedInstanceState);
	boolean recWaitingList = canRecWaitingListMsg() &&
			!ReceivePresent.getInstance().isQuitOrNotInit()
			&& ReceivePresent.getInstance().isSendOrRecWaitinglist();
	boolean recQuit = canRecQuitMsg() &&
			(isSend() ? (SendPresent.getInstance().isQuitOrNotInit())
					: (ReceivePresent.getInstance().isQuitOrNotInit()));
	//if we has receive waiting list,we will
	if (recWaitingList) {
		receiveWaitingListMsg();
	} else if (recQuit) {
		receiveQuitMsg(new QuitBean(Constants.TRANSFER_ERROR));
	}
	//...省略后面的注册广播接收器的代码
}
```
### 1.8.	外部如何方便的通过TcpClient建立连接和获取数据

TcpClient的使用虽然不算复杂，但是毕竟也需要一些步骤，有一些连接状态和回调方法需要处理。
其他模块如果对传输模块不熟悉,但是又想建立连接或者获取数据，直接使用TcpClient是不方便的，
因此我们封装了一个TcpAgent的代理类。

该类通过大家熟悉的RxJava的方式对外部提供接口，调用方无需熟悉TcpClient类的使用即可完成需要的操作，目前外部需要的操作，我们都封装在这个类中。

其实现方式，最终还是通过TcpClient和TcpClientListener这些回调接口，只不过是外部封装了一层rxjava，让外部方便使用。例如获取对端信息的getDeviceInfo方法。

```java
public synchronized Flowable<DeviceInfo> getDeviceInfo() {
	return Flowable.create(new FlowableOnSubscribe<DeviceInfo>() {
		@Override
		public void subscribe(final FlowableEmitter<DeviceInfo> emitter) throws Exception {
			if (mSendClient != null && mSendClient.isConnect()) {
				mSendClient.sendCmd(ProtocolEnum.SEND_DEVICE_INFO.getCmd(), null, false, new TcpCmdCallback() {
					@Override
					public void onSucceed(TcpClient client, CmdPacket response) {
						DeviceInfo info = (DeviceInfo) response.getmContent();
						emitter.onNext(info);
						emitter.onComplete();
					}

					@Override
					public void onError(TcpClient client, Packet sendPacket, Exception e) {
						emitter.onError(e);
					}
				});
        } else {
				emitter.onError(new UnconnectException(" getReceveSpaceSize socket not connect "));
			}
		}
	}, BackpressureStrategy.LATEST);
}

```
