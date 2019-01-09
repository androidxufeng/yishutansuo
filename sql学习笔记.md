### 1.sql语法
* sql对大小写不敏感，一般关键词大写，
* sql语句一般以关键字开始，以'；'结束

#### 0.1 sql存储的数据类型
|存储类 | 描述 |
|------- |-------|
|NULL |  值是一个NULL值|
|INTEGER	|整型	|
|	REAL	|浮点型	|
|	TEXT	|文本字符串|	

#### 0.2 创建表
CREATE TABLE Person(
  ID INT PRIMARY KEY      NOT NULL,
   DEPT           CHAR(50) NOT NULL,
   EMP_ID         INT      NOT NULL);
   
   
#### 0.3 删除表
  DROP TABLE Person;

#### 1.1 sql （数据操作语言）DML和（数据定义语言）DDL
Person 表

|LastName | FirstName | Address | City|
|------- |-------|----------------|----|
|Carter |  Thomas|Changan Street|Beijing|
|Bush	|George	|Fifth Avenue	|New York|
|	Carter	|Thomas	|Changan Street|	Beijing|
|	Obama	|Barack	|Pennsylvania Avenue	|Washington|

1. 查询和更新指令构成了 SQL 的 DML 部分：
  - SELECT  
      > SELECT -id,_data FROM 表名
      <br> SELECT * FROM 表名
      <br> SELECT  ***DISTINCT*** display_name FROM 表名
      <br> SELECT display_name FROM 表名 ***WHERE size > 1000***
      <br> SQL 使用单引号来环绕文本值（大部分数据库系统也接受双引号）。如果是数值，请不要使用引号。
      <br> SELECT * FROM 表名 ***WHERE FirstName = 'bush' AND LastName = 'Geogy' OR (LastNamen = 'Carter')***
      <br> SELECT Company，OrderName FROM 表名 ***ORDER BY Company DESC , OrderName ASC***
      
  - DELETE
    > DELETE FROM Person WHERE FirstName = 'Carter'
    > DELETE * FROM Person
  - UPDATE
    基本语法
    
    UPDATE table_name
    SET column1 = value1, column2 = value2...., columnN = valueN
    WHERE [condition];
   
    
    > UPDATE Person SET FirstName = 'zhangsan' WHERE LastName = 'Carter'
  - INSERT INTO
        有两种基本用法
        
        1.全部列插入数据
        
        INSERT INTO Person VALUES(value1,value2,...valueN);
        
        2. 指定的列插入数据
        
        INSERT INTO Person (column1,columnN) VALUES(value1,valueN);
        
    > INSERT INTO Person VALUES ('Gates', 'Bill', 'Xuanwumen 10', 'Beijing')
    
    > INSERT INTO Person (LastName ,FirstName) VALUES ('Gates', 'Bill')
    
2. SQL 中最重要的 DDL 语句:
  - CREATE DATABASE 创建新数据库
  - ALTER DATABASE  修改数据库
  - CREATE TABLE 创建新表
  - ALTER TABLE  变更数据表
  - DROP TABLE  删除数据表
  - CREATE INDEX 创建索引
  - DROP INDEX  删除索引
  
  
  #### 1.2 Like 语句
  类似于正则表达式。匹配指定模式的文本值
  *  '_' 代表是单一的一个数字或字符
  *  '%' 代表任意数量的数字或字符
  
  #### 1.3 GLOB 
  类似于LIKE，对大小写敏感，'?'相当于LIKE中的'_'; '*'相当于LIKE中的'%'
  
  #### 1.4 LIMIT
  从查询的数据的第二条开始，显示三条数据(LIMIT  和  OFFSET)
  SELECT * FROM Person LIMIT 3 OFFSET 1
  
  
  #### 1.5 GROUP BY 
  必须放在SELECT语句后面，ORDER BY语句的前面
  
### 2.sql高级语法
