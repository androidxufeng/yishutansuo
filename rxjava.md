## 部分概念：

### Observable & Flowable
2.0 将 Backpressure 的情况做了分离，仅 Flowable 支持 Backpressure。

### Single & Maybe & Completable
- Single 发射单个数据或错误事件 onSuccess / onError
- Maybe 发射 0 (onComplete) 或者 1 个数据，要么成功(onNext)，要么失败(onError)
- Completable onComplete / onError

相关知识可参考博文：[RxJava的Single、Completable以及Maybe](http://www.jianshu.com/p/45309538ad94)

### Cold Observable & Hot Observable
Think of a hot Observable as a radio station. All of the listeners that are listening to it at this moment listen to the same song.
A cold Observable is a music CD. Many people can buy it and listen to it independently. by Nickolay Tsvetinov

相关知识可参考博文：[Cold Observable 和 Hot Observable](http://www.jianshu.com/p/12fb42bcf9fd)

理解了 Hot Observable 和 Cold Observable 的区别才能够写出更好 Rx 代码。

## Schedulers

| 名称 | 说明 |
| :-- | :-- |
| Schedulers.computation() | 用于 CPU 密集型计算任务，即不会被 I/O 等操作限制性能的耗时操作，例如 xml, json文件的解析，Bitmap 图片的压缩取样等，具有固定的线程池，大小为 CPU 的核数。不可以用于 I/O 操作，因为 I/O 操作的等待时间会浪费 CPU。|
| Schedulers.io() | 用于 I/O 密集型的操作，例如读写 SD 卡文件，查询数据库，访问网络等，具有线程缓存机制，在此调度器接收到任务后，先检查线程缓存池中，是否有空闲的线程，如果有，则复用，如果没有则创建新的线程，并加入到线程池中，如果每次都没有空闲线程使用，可以无上限的创建新线程。这可能导致系统变慢或 OutOfMemoryError， 因此允许的情况下要使用 Disposable.dispose() 进行取消。 |
| Schedulers.trampoline() | 在当前线程立即执行任务，如果当前线程有任务在执行，则会将其暂停，等插入进来的任务执行完之后，再将未完成的任务接着执行。该调度器不保证可靠地将任务结果返回给主线程。 |
| Schedulers.newThread() | 在每执行一个任务时创建一个新的线程，不具有线程缓存机制，因为创建一个新的线程比复用一个线程更耗时耗力，虽然使用 Schedulers.io() 的地方，都可以使用 Schedulers.newThread()，但是，Schedulers.newThread() 的效率没有 Schedulers.io() 高。同样可以无上限的创建新线程。 |
| Schedulers.single() | 拥有一个线程单例，所有的任务都在这一个线程中执行，当此线程中有任务执行时，其他任务将会按照先进先出的顺序依次执行。 |
| Scheduler.from(@NonNull Executor executor) | 指定一个线程调度器，由此调度器来控制任务的执行策略。 |

RxJava 的线程切换结合链式调用非常方便，比起 Java 使用线程操作实在是简单太多了。

相关知识可参考博文：[RxJava 线程模型分析](http://www.jianshu.com/p/c1cab5621df7)

## Observable

以下内容的图片说明出自：[RxJava JavaDoc](http://reactivex.io/RxJava/2.x/javadoc/)

### [Creating Observables](https://github.com/ReactiveX/RxJava/wiki/Creating-Observables)

#### Create
— 创建一个全新的 Observable
- create(ObservableOnSubscribe<T> source)

#### From
— 将其它的对象或数据结构转换为 Observable
- fromArray(T... items)

![fromArray](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/from.png)

- fromCallable(java.util.concurrent.Callable<? extends T> supplier)

![fromCallable](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/fromCallable.png)

- fromIterable(java.lang.Iterable<? extends T> source)

![fromIterable](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/fromIterable.png)

- fromFuture(java.util.concurrent.Future<? extends T> future)
- fromPublisher(Publisher<? extends T> publisher)

后面这两个有点复杂……暂时没学习

#### Just
— 将传入的对象发射出去，可以传入同一类型的 1 ~ 10 个对象

- just(T item1, T item2, T item3, T item4)

![just](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/just.4.png)

#### Repeat
— 创建重复发射特定的数据或数据序列的 Observable

不是静态方法

- repeat

![repeat](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/repeat.o.png)

- repeatWhen

![repeatWhen](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/repeatWhen.f.png)

#### Defer
— 在观察者订阅之前不创建这个Observable，为每一个观察者创建一个新的Observable

- defer(java.util.concurrent.Callable<? extends ObservableSource<? extends T>> supplier)

![defer](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/defer.png)

#### Range
— 创建发射指定范围的整数序列的Observable

- range(int start, int count)

![range](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/range.png)

#### Interval
— 创建一个定时发射整数序列的Observable

- interval(long initialDelay, long period, java.util.concurrent.TimeUnit unit, Scheduler scheduler)

![interval](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/timer.ps.png)

默认的 Schedules 为 computation Scheduler

#### Timer
— 创建在一个指定的延迟之后发射单个数据 0 的 Observable

- timer(long delay, java.util.concurrent.TimeUnit unit)

![timer](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/timer.png)

默认的 Schedules 为 computation Scheduler

#### Empty/Never/Error
— 创建行为受限的特殊Observable
- empty
- error
- never

![empty](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/empty.png)

![error](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/error.item.png)

![never](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/never.png)


============================================================

以下是 RxJava Wiki 页面有的方法，但是 RxJava Essentials 里没有提到，这里补充进行说明。

// 找不到这个方法 1.x 和 2.x 都没有

fromEmitter() — create safe, backpressure-enabled, unsubscription-supporting Observable via a function and push events.


### [Filtering Observables](https://github.com/ReactiveX/RxJava/wiki/Filtering-Observables)

#### filter
— 过滤，发射符合条件的对象

- filter(Predicate<? super T> predicate)

![filter](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/filter.png)

#### take / takeLast

- take(long time, java.util.concurrent.TimeUnit unit)

![take](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/take.t.png)

![takeLast](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/takeLast.tn.png)

默认的 Schedules 为 computation Scheduler

#### distinct / distinctUntilsChanged

- distinct()
- distinctUntilChanged()

![distinct](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/distinct.png)

![distinctUntilChanged](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/distinctUntilChanged.png)


#### first / last

- public final Single<T> first(T defaultItem)
- public final Maybe<T> firstElement()

![first](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/first.s.png)

![firstElement](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/firstElement.m.png)

- public final Single<T> last(T defaultItem)
- public final Maybe<T> lastElement()

![last](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/last.2.png)

![lastElement](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/lastElement.png)

#### skip / skipLast

- skip(long count)
- skip(long time, java.util.concurrent.TimeUnit unit)

![skip](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/skip.png)

![skip](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/skip.t.png)

- skipLast(long count)
- skipLast(long time, java.util.concurrent.TimeUnit unit)

![skipLast](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/skipLast.png)

![skipLast](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/skipLast.t.png)



#### elementAt

- elementAt(long index, T defaultItem)

![elementAt](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/elementAt.2s.png)


#### sample / throttleFirst

sample 挑一个最简单的来说明：

- sample(long period, java.util.concurrent.TimeUnit unit)

![sample](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/sample.png)

- throttleFirst(long period, java.util.concurrent.TimeUnit unit)

![throttleFirst](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/throttleFirst.png)

相应的，就有 throttleLast，但是实际上它是调用 sample。

#### timeout

- timeout(Function<? super T,? extends ObservableSource<V>> itemTimeoutIndicator)

![timeout](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/timeout3.png)

#### debounce

- debounce(long timeout, java.util.concurrent.TimeUnit unit)

![debounce](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/debounce.png)

============================================================

以下是 RxJava Wiki 页面有的几个方法，但是 RxJava Essentials 里没有提到，这里补充进行说明。

// 2.0 没有这个方法了 last 方法里带的参数就是 default

lastOrDefault( ) — emit only the last item emitted by an Observable, or a default value if the source Observable is empty

// 改名直接叫 takeLast 了

takeLastBuffer( ) — emit the last n items emitted by an Observable, as a single list item

// 实际上调用 debounce，debounce 是 Rx 标准叫法

throttleWithTimeout( )


#### ofType
— 只发射某一类元素
- ofType(java.lang.Class<U> clazz)

![ofType](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/ofClass.png)

#### ignoreElements()
— 只通过了 结束与错误

ignoreElements( ) — discard the items emitted by the source Observable and only pass through the error or completed notification

![ignoreElements](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/ignoreElements.2.png)


### [Transforming Observables](https://github.com/ReactiveX/RxJava/wiki/Transforming-Observables)

#### map家族

- map(Function<? super T,? extends R> mapper)

![map](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/map.png)

- flatMap(Function<? super T,? extends ObservableSource<? extends R>> mapper, boolean delayErrors)

![flatMap](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/flatMap.png)

- concatMap(Function<? super T,? extends ObservableSource<? extends R>> mapper)

![concatMap](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/concatMap.png)

- flatMapIterable(Function<? super T,? extends java.lang.Iterable<? extends U>> mapper)

![flatMapIterable](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/flatMapIterable.o.png)

- switchMap(Function<? super T,? extends ObservableSource<? extends R>> mapper)

![switchMap](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/switchMap.png)


#### scan

这个比较不好理解，看例子，然后我画一个图给大家看。

- scan(R initialValue, BiFunction<R,? super T,R> accumulator)

![scan](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/scanSeed.png)

#### groupBy

- groupBy(Function<? super T,? extends K> keySelector, boolean delayError)

![groupBy](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/groupBy.png)

#### buffer
- buffer(int count)

![buffer](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/buffer3.png)

#### window

- window(long count)

![window](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/window3.png)

#### cast

- cast(java.lang.Class<U> clazz)

![cast](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/cast.png)


### [Combining Observables](https://github.com/ReactiveX/RxJava/wiki/Combining-Observables)

#### merge / mergeDelayError

- merge(ObservableSource<? extends T> source1, ObservableSource<? extends T> source2)

![merge](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/merge.png)

#### zip

- zip(ObservableSource<? extends T1> source1, ObservableSource<? extends T2> source2, BiFunction<? super T1,? super T2,? extends R> zipper)

![zip](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/zip.png)

#### join

- join(ObservableSource<? extends TRight> other, Function<? super T,? extends ObservableSource<TLeftEnd>> leftEnd, Function<? super TRight,? extends ObservableSource<TRightEnd>> rightEnd, BiFunction<? super T,? super TRight,? extends R> resultSelector)

![join](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/join_.png)

这个看起来不好理解，一个比较好的解释可以看该链接：[Join](http://www.introtorx.com/uat/content/v1.0.10621.0/17_SequencesOfCoincidence.html#Join)

#### combineLatest

- combineLatest(ObservableSource<? extends T1> source1, ObservableSource<? extends T2> source2, BiFunction<? super T1,? super T2,? extends R> combiner)

![combineLatest](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/combineLatest.png)

#### switchOnNext

- switchOnNext(ObservableSource<? extends ObservableSource<? extends T>> sources)

![switchOnNext](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/switchDo.png)

#### startWith

- startWith(ObservableSource<? extends T> other)

![startWith](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/startWith.o.png)


============================================================

以下是 RxJava Wiki 页面有的几个方法，但是 RxJava Essentials 里没有提到，这里补充进行说明。

and then when

// 这个在书里有提到，它是 rxjava-joins 包里的，而且也看不太懂，这个就不讲了


// groupJoin 书里没有提到，未学习

join( ) and groupJoin( ) — combine the items emitted by two Observables whenever one item from one Observable falls within a window of duration specified by an item emitted by the other Observable

============================================================

以下是为了实用补充介绍一些内容。

### concat

- concat(ObservableSource<? extends T> source1, ObservableSource<? extends T> source2)

![concat](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/concat.png)

### concatEager

- concatEager(java.lang.Iterable<? extends ObservableSource<? extends T>> sources)

![concatEager](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/concatEager.png)

### takeUntil

- takeUntil(ObservableSource<U> other)

![takeUntil](https://raw.github.com/wiki/ReactiveX/RxJava/images/rx-operators/takeUntil.png)


## Subject = Observable + Observer

参见：[RxJava 第二篇 - Subject使用及示例](http://www.jianshu.com/p/1257c8ba7c0c)


## 应用场景

### 场景一：实时搜索框

应用在 EditText 中通过监听输入框的内容的变化，当内容改变之后回调 `afterTextChanged()` 方法，应用在此将发起请求搜索内容，服务器返回结果后将结果展示在界面上。

- 问题一：内容改变较快时，将发起不必要的搜索。例如，在用户删除内容时，每删除一个字符都发起搜索，实际上是没有必要的。

- 问题二：内容改变较快时，返回的结果可能不匹配。例如，依次输入了 ab 和 abc，那么首先会发起关键词为 ab 请求，之后再发起 abc 的请求，但是 abc 的请求如果先于 ab 的请求返回，那么就会造成展现的结果和用户期望不匹配。


### 场景二：定时请求更新

正常情况下定时向服务器发起一次请求，更新定位信息、城市信息。如果请求更新失败，则改变下一次请求的间隔。


### 场景三：天气显示页面

我们进入天气页面，会先读取缓存中的数据，再去请求网络。

- 问题：发起请求网络时间延后了


### 场景四：城市的多个天气信息

一个城市请求天气需要多个天气信息：当天天气、24 小时天气、7天天气、预警信息等。

其中预警信息可以单独请求，而其他三个天气信息需要同时进行展示才可以构成完整的界面。
