
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
