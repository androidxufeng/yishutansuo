### Measure

1. MeasureSpec  View测量大小的依据

![img](https://upload-images.jianshu.io/upload_images/3985563-d3bf0905aeb8719b.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/470/format/webp)

specMode 分为三种
* UNSPECIFIED  未知大小
* AT_MOST  对应的是wrap_content
* EXACTLY  具体数值和match_parent

View：measure() -> onMeasure(int widthMeasureSpec, int heightMeasureSpec) -> setMeasureDimension(int,int参数是具体算出的最红结果)

#### 整个Mearsure的流程如下
![measure](https://upload-images.jianshu.io/upload_images/944365-bf6b3dc2261012dc.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/970/format/webp)

那么决定整个measure过程的 MeasureSpec怎么来的

![决定view的尺寸](https://upload-images.jianshu.io/upload_images/944365-d059b1afdeae0256.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/470/format/webp)

ViewGroup: 先遍历测量所有子view的宽高，然后测量出自己的宽高

#### ViewGroup的measure过程

![ViewGroup](https://upload-images.jianshu.io/upload_images/944365-c9ea47e8b5e325bf.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1000/format/webp)


### onLayout
View：onLayout是空实现
ViewGroup：抽象方法，子类的Group必须实现。*必须在方法中给每个子LayoutChildren*
