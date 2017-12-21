### 1.Activity的生命周期全面分析
onCreate()->onStart()->onResume()
onPause()->onStop()->onDestory()

   * 启动其他acitivity ： onPause->onStop，然后back键回来 onRestart->onStart->onResume
   * 特殊情况：启动一个透明主题的activity 不会走onStop
   
 question:当前activity为A，如果用户这时打开一个新的activity B，那么B的onResume和A的onPause哪个会先被执行?
    * we need to start pausing the current activity so the top one can be resumed ..
    启动的逻辑顺序：A.onPause->B.onCreate->B.onStart->B.onResume->A.onStop，不要在onPause中做过多操作影响打开下个界面
    
 ### 2.异常情况下的生命周期分析
 * 场景：1.资源相关的系统配置发生改变导致activity被杀死并重新创建（字体，横竖屏，语言）
 </br>意外被杀死  在onStop之前会调用onSaveInstanceState保存状态，恢复时在onStart之前会调用onRestoreInstanceState恢复数据，具体保存的数据要看view的对应方法所恢复的值（委托思想：Activity->Window->DecorView->子view保存）
 #### 以TextView为例
```java
     public Parcelable onSaveInstanceState() {
        Parcelable superState = super.onSaveInstanceState();
        // Save state if we are forced to
        final boolean freezesText = getFreezesText();
        if (mText != null) {
            start = getSelectionStart();
            end = getSelectionEnd();
            if (start >= 0 || end >= 0) {
                // Or save state if there is a selection
                hasSelection = true;
            }
        }
        if (freezesText || hasSelection) {
            SavedState ss = new SavedState(superState);
        if (hasSelection) {
                // XXX Should also save the current scroll position!
                ss.selStart = start;
                ss.selEnd = end;
            }
            return ss;
        }
        return superState;
    }
```
* 资源不足被杀死
</br> 根据进程优先级来结束Activity

### 3.Activity的启动模式
* standard 非Activity的context.startActivity，需要加上FLAG_ACTIVITY_NEW_TASK.
* singleTop 复用时会调用onNewIntent，不会走onCreate和onStart
* singleTask 任务栈S1中有ABC， D需要S2那么新建S2加入D ， D如果在S1,直接入栈S1， 如果加入B且在S1，singleTask默认clearTop，调用onNewIntent，C被弹出栈
* singleInstance

### 4.Activity的flag：有兴趣去研究

### 5.intent_filter的匹配规则
* 1.一个activity可以有多个intent_filter，只要匹配一个即可
* 2.aciton（只要匹配一个即可） category(布局文件中的必须完全被匹配)  data(mimetype&uri)

