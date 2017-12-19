###1.Activity的生命周期全面分析
onCreate()->onStart()->onResume()
onPause()->onStop()->onDestory()

   *启动其他acitivity ： onPause->onStop，然后back键回来 onRestart->onStart->onResume
   *特殊情况：启动一个透明主题的activity 不会走onStop
   
 question:当前activity为A，如果用户这时打开一个新的activity B，那么B的onResume和A的onPause哪个会先被执行?
    * we need to start pausing the current activity so the top one can be resumed ..
    启动的逻辑顺序：A.onPause->B.onCreate->B.onStart->B.onResume->A.onStop，不要在onPause中做过多操作影响打开下个界面
    

