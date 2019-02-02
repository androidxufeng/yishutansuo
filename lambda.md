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
