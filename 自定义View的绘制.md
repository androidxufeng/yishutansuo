### 自定义View的绘制

#### 1.Canvas的drawXXX()方法和Paint常见的使用
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
    
#### 2.Paint的完全攻略
#### 3.Canvas对绘制的辅助（范围裁剪和几何变化）
#### 4.使用不同的绘制方法来控制绘制顺序
