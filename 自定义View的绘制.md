## 自定义View的绘制

### 1.Canvas的drawXXX()方法和Paint常见的使用
  * 一切的开始onDraw()
  复写View的onDraw方法
  ```java
  Paint paint = new Paint();

  @Override
  protected void onDraw(Canvas canvas) {  
      super.onDraw(canvas);
      // 绘制一个圆
     canvas.drawCircle(300, 300, 200, paint);
}
 ```
 * drawXXX() 系列方法和 Paint 的基础
 
  1.canvas.drawXXX()，不详细介绍
  
  2.Paint 类的几个最常用的方法。具体是： 
  
  - Paint.setStyle(Style style) 设置绘制模式
  - Paint.setColor(int color) 设置颜色
  - Paint.setStrokeWidth(float width) 设置线条宽度
  - Paint.setTextSize(float textSize) 设置文字大小
  - Paint.setAntiAlias(boolean aa) 设置抗锯齿开关
  
  3.canvas.drawPath(Path，Paint),用于绘制自定义的图形（嘿嘿）
  
 **Path方法第一类，直接描述路径（添加子图形或者划线）**
 
 1. addXxx() ——添加子图形
 
    addCircle(float x, float y, float radius, Direction dir) 添加圆
  
 2. xxxTo() ——画线（直线或曲线）
  
 + lineTo()画一条直线
 + quadTo() 二阶贝塞尔曲线  cubicTo() 三阶贝塞尔曲线
 + moveTo(float x, float y) / rMoveTo(float x, float y) 移动到目标位置
 
 不论是直线还是贝塞尔曲线，都是以当前位置作为起点，而不能指定起点。但你可以通过 moveTo(x, y) 或  rMoveTo() 来改变当前位置，从而间接地设置这些方法的   起点。
    
### 2.Paint的完全攻略
 - 颜色
 - 效果
 - drawText相关
 - 初始化
 
 #### 2.1 颜色
 Paint 设置颜色的方法有两种：一种是直接用 Paint.setColor/ARGB() 来设置颜色，另一种是使用 Shader 来指定着色方案
 ##### 2.1.1 基本颜色
 ##### 2.1.1.1 直接设置颜色
 Paint.setColor或者是setARGB
 #####  2.1.1.2 通过设置shader来设置颜色
 特殊的paint可以使用bitmap作为shader：使用canvas.drawCircle + paint.setShader(new BitmapShader)可以画出圆形图片
 
 #### 2.1.2 setColorFilter(ColorFilter colorFilter)
 paint对颜色的第二层处理，用来对颜色进行过滤
 
 #### 2.1.3 setXfermode(Xfermode xfermode)
  ```java
  Xfermode xfermode = new PorterDuffXfermode(PorterDuff.Mode.DST_IN);
  canvas.drawBitmap(rectBitmap, 0, 0, paint); // 画方  
  paint.setXfermode(xfermode); // 设置 Xfermode  
  canvas.drawBitmap(circleBitmap, 0, 0, paint); // 画圆  
  paint.setXfermode(null); // 用完及时清除 Xfermode  
  ```
  #### 2.2 效果
  ##### 2.2.1 线条形状
  + setStrokeWidth(float width)
  + setStrokeCap(Paint.Cap cap) 线头形状 butt（平头） ROUND 圆头、SQUARE 方头，默认是butt
  + etStrokeJoin(Paint.Join join) 设置拐角的形状 MITER 尖角、 BEVEL 平角和 ROUND 圆角。默认为 MITER。
  
  #### 2.2.2 色彩优化
  + setDither(boolean dither) 设置抖动
  + setFilterBitmap(boolean filter) 是否开启双线性抖动
  #### 2.2.3 setPathEffect
  使用 PathEffect 来给图形的轮廓设置效果。对 Canvas 所有的图形绘制有效，也就是 drawLine() drawCircle() drawPath() 这些方法：
  
  ### 2.3 drawText相关
  _先不看，太繁琐_
  
### 3.Canvas对绘制的辅助（范围裁剪和几何变化）
#### 3.1 范围裁剪 
范围裁切有两个方法： clipRect() 和 clipPath()。裁切方法之后的绘制代码，都会被限制在裁切范围内。
#### 3.2 几何变换
 1. 使用canvas进行常见的二维变换 （平移，旋转，缩放等），使用每次需要save和restore
 2. 使用matrix进行不常见的二维变换  使用matrix需要reset
 3. 使用camera进行三维变换  // 不懂如何使用

### 4.使用不同的绘制方法来控制绘制顺序
- 绘制背景
- onDraw()
- disPatchDraw()
- 滑动边缘和滑动条
- 前景

