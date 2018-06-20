### 1.sql语法
* sql对大小写不敏感
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
    > UPDATE Person SET FirstName = 'zhangsan' WHERE LastName = 'Carter'
  - INSERT INTO
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
  
### 2.sql高级语法
