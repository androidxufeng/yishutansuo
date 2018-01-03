
## View的事件体系
### 1.1 View的基础知识
#### 1.1.1 View的位置参数
 1.left right top bottom   width = right - left  height = top - bottom <br>
 2.(left top）相对于 view的（x ，y）是有区别的。如果view没有平移，那么相等 <br>
 * X = left + translationX
 * Y = top + translationY
#### 1.1.2 MotinoEvent和TouchSlop
  touchSlop 最小的滑动距离 一般是8dp
  
#### 1.1.3 VelocityTracker、GestureDetector和Scroller
 1.VelocityTracker 计算手指滑动的速度<br>
```java
            VelocityTracker vt = VelocityTracker.obtain();
            vt.addMovement(motionEvent);
            vt.computeCurrentVelocity(1000);
            float xVelocity = vt.getXVelocity();
            float yVelocity = vt.getYVelocity();
 ```
  2.GestureDetector 手势检测用户的单击 长按 滑动 双击等操作
  <br>
  3.Scroll 无法让view滑动 仅仅只是计算位置 配合view的computeScroll 一起使用达到效果
 ```java
    @Override
    public void computeScroll() {
        // 滑动没有结束 computeScrollOffset会返回true
        if(mScroller.computeScrollOffset()){
            //调用view的scrollTo方法
            scrollTo(mScroller.getCurrX(),mScroller.getCurrY());
            // 绘制
            invalidate();
        }
    }
 ```
 
 ### 2.2 View的滑动
 * 1.使用scrollTo/scrollBy
 <br>scrollBy内部调用的是scrollTo
 <br>移动的是view中的内容，并且正值是向左滑和向上滑
 
 * 2.使用动画
 * 3.使用延时策略
 <br>Handler.postDelay发送延迟消息然后通过scrollTo来平移
 
 ### 2.3 View的事件分发机制
* 分发 dispatchTouchEvent
* 拦截 onInterceptTouchEvent
* 消费 onTouchEvent
<br> onTouchListener的优先级很高，如果设置了onTouchListener,返回的值如果是true的话，那么onTouchEvent不会被调用。
<br>**拦截**如果viewgroup拦截了move事件，那么剩下不会再调用onInterceptTouchEvent，之后的事件move和up统一会交由该viewGroup处理，子view只能收到down事件
<br>**消费** 如果不处理down事件，所有事件都不会让view处理，全部丢给父view处理调用父view的onTounchEvent
<br> 如果不处理move或者是up事件，由于当前已经处理down事件，当前view还会接收到后续事件，父view不会接收到事件
