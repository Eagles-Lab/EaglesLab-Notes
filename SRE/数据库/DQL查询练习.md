# 查询练习

建表，插入数据
新建一个查询用的数据库:selectTest
CREATE DATABASE selectTest;
选择该数据库:
USE selectTest;

学生表:
student
学号
姓名
性别
出生日期
所在班级

```sql
CREATE TABLE student(
    s_no VARCHAR(20) PRIMARY KEY COMMENT'学生学号',
    s_name VARCHAR(20) NOT NULL COMMENT'学生姓名 不能为空',
    s_sex VARCHAR(10) NOT NULL COMMENT'学生性别',
    s_birthday DATETIME COMMENT'学生生日',
    s_class VARCHAR(20) COMMENT'学生所在的班级'
)ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```



教师表
teacher
教师编号
教师名字
教师性别
出生日期
职称
所在部门

```sql
CREATE TABLE teacher(
    t_no VARCHAR(20) PRIMARY KEY COMMENT'教师编号',
    t_name VARCHAR(20) NOT NULL COMMENT'教师姓名',
    t_sex VARCHAR(20) NOT NULL COMMENT'教师性别',
    t_birthday DATETIME COMMENT'教师生日',
    t_rof VARCHAR(20) NOT NULL COMMENT'教师职称',
    t_depart VARCHAR(20) NOT NULL COMMENT'教师所在的部门'
)ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```



课程表:
course
课程号
课程课程名称
教师编号

```sql
CREATE TABLE course(
    c_no VARCHAR(20) PRIMARY KEY COMMENT'课程号',
    c_name VARCHAR(20) NOT NULL COMMENT'课程名称',
    t_no VARCHAR(20) NOT NULL COMMENT'教师编号 外键关联teacher表',
    FOREIGN KEY(t_no) references teacher(t_no)
)ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```



成绩表
srore
学号
课程号
成绩
注意:视频中原先只有一个主键s_no ,后来修改了

```sql
CREATE TABLE score (
    s_no VARCHAR(20) NOT NULL COMMENT'成绩表的编号 依赖学生学号',
        c_no VARCHAR(20)  NOT NULL COMMENT'课程号 依赖于课程表中的c_id',
    sc_degree decimal,
    foreign key(s_no) references student(s_no),
    foreign key(c_no) references course(c_no),
    PRIMARY KEY(s_no,c_no)
)ENGINE=InnoDB CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
```



查看创建的表以及架构

```sql
SHOW TABLES;
+----------------------+
| Tables_in_selecttest |
+----------------------+
| course               |
| score                |
| student              |
| teacher              |
+----------------------+
```





查看student表结构    DESCRIBE student;

```sql
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| s_no       | varchar(20) | NO   | PRI | NULL    |       |
| s_name     | varchar(20) | NO   |     | NULL    |       |
| s_sex      | varchar(10) | NO   |     | NULL    |       |
| s_birthday | datetime    | YES  |     | NULL    |       |
| s_class    | varchar(20) | YES  |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+
```



查看teacher表结构    

```sql
DESCRIBE teacher;
+------------+-------------+------+-----+---------+-------+
| Field      | Type        | Null | Key | Default | Extra |
+------------+-------------+------+-----+---------+-------+
| t_no       | varchar(20) | NO   | PRI | NULL    |       |
| t_name     | varchar(20) | NO   |     | NULL    |       |
| t_sex      | varchar(20) | NO   |     | NULL    |       |
| t_birthday | datetime    | YES  |     | NULL    |       |
| t_rof      | varchar(20) | NO   |     | NULL    |       |
| t_depart   | varchar(20) | NO   |     | NULL    |       |
+------------+-------------+------+-----+---------+-------+
```





查看course表结构    

```sql
DESCRIBE course;
+--------+-------------+------+-----+---------+-------+
| Field  | Type        | Null | Key | Default | Extra |
+--------+-------------+------+-----+---------+-------+
| c_no   | varchar(20) | NO   | PRI | NULL    |       |
| c_name | varchar(20) | NO   |     | NULL    |       |
| t_no   | varchar(20) | NO   | MUL | NULL    |       |
+--------+-------------+------+-----+---------+-------+
```





查看score表结构    

```sql
DESCRIBE score;
+-----------+---------------+------+-----+---------+-------+
| Field     | Type          | Null | Key | Default | Extra |
+-----------+---------------+------+-----+---------+-------+
| s_no      | varchar(20)   | NO   | PRI | NULL    |       |
| c_no      | varchar(20)   | NO   | MUL | NULL    |       |
| sc_degree | decimal(10,0) | YES  |     | NULL    |       |
+-----------+---------------+------+-----+---------+-------+
```





向表中添加数据

```sql
--学生表数据

INSERT INTO student VALUES('101','曾华','男','1977-09-01','95033');
INSERT INTO student VALUES('102','匡明','男','1975-10-02','95031');
INSERT INTO student VALUES('103','王丽','女','1976-01-23','95033');
INSERT INTO student VALUES('104','李军','男','1976-02-20','95033');
INSERT INTO student VALUES('105','王芳','女','1975-02-10','95031');
INSERT INTO student VALUES('106','陆军','男','1974-06-03','95031');
INSERT INTO student VALUES('107','王尼玛','男','1976-02-20','95033');
INSERT INTO student VALUES('108','张全蛋','男','1975-02-10','95031');
INSERT INTO student VALUES('109','赵铁柱','男','1974-06-03','95031');

--教师表数据
INSERT INTO teacher VALUES('804','李诚','男','1958-12-02','副教授','计算机系');
INSERT INTO teacher VALUES('856','张旭','男','1969-03-12','讲师','电子工程系');
INSERT INTO teacher VALUES('825','王萍','女','1972-05-05','助教','计算机系');
INSERT INTO teacher VALUES('831','刘冰','女','1977-08-14','助教','电子工程系');

--添加课程表
INSERT INTO course VALUES('3-105','计算机导论','825');
INSERT INTO course VALUES('3-245','操作系统','804');
INSERT INTO course VALUES('6-166','数字电路','856');
INSERT INTO course VALUES('9-888','高等数学','831');

--添加成绩表
INSERT INTO score VALUES('103','3-245','86');
INSERT INTO score VALUES('105','3-245','75');
INSERT INTO score VALUES('109','3-245','68');
INSERT INTO score VALUES('103','3-105','92');

INSERT INTO score VALUES('105','3-105','88');
INSERT INTO score VALUES('109','3-105','76');
INSERT INTO score VALUES('103','6-166','85');

INSERT INTO score VALUES('105','6-166','79');
INSERT INTO score VALUES('109','6-166','81');
```





几张表的数据展现

```sql
SELECT * FROM student;
+------+--------+-------+---------------------+---------+
| s_no | s_name | s_sex | s_birthday          | s_class |
+------+--------+-------+---------------------+---------+
| 101  | 曾华   | 男    | 1977-09-01 00:00:00 | 95033   |
| 102  | 匡明   | 男    | 1975-10-02 00:00:00 | 95031   |
| 103  | 王丽   | 女    | 1976-01-23 00:00:00 | 95033   |
| 104  | 李军   | 男    | 1976-02-20 00:00:00 | 95033   |
| 105  | 王芳   | 女    | 1975-02-10 00:00:00 | 95031   |
| 106  | 陆军   | 男    | 1974-06-03 00:00:00 | 95031   |
| 107  | 王尼玛 | 男    | 1976-02-20 00:00:00 | 95033   |
| 108  | 张全蛋 | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱 | 男    | 1974-06-03 00:00:00 | 95031   |
+------+--------+-------+---------------------+---------+





teacher  SELECT * FROM teacher;
+------+--------+-------+---------------------+--------+------------+
| t_no | t_name | t_sex | t_birthday          | t_rof  | t_depart   |
+------+--------+-------+---------------------+--------+------------+
| 804  | 李诚   | 男    | 1958-12-02 00:00:00 | 副教授 | 计算机系   |
| 825  | 王萍   | 女    | 1972-05-05 00:00:00 | 助教   | 计算机机系 |
| 831  | 刘冰   | 女    | 1977-08-14 00:00:00 | 助教   | 电子工程系 |
| 856  | 张旭   | 男    | 1969-03-12 00:00:00 | 讲师   | 电子工程系 |
+------+--------+-------+---------------------+--------+------------+

score  SELECT * FROM score;
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-105 |        92 |
| 103  | 3-245 |        86 |
| 103  | 6-166 |        85 |
| 105  | 3-105 |        88 |
| 105  | 3-245 |        75 |
| 105  | 6-166 |        79 |
| 109  | 3-105 |        76 |
| 109  | 3-245 |        68 |
| 109  | 6-166 |        81 |
+------+-------+-----------+

course    SELECT * FROM course;
+-------+------------+------+
| c_no  | c_name     | t_no |
+-------+------------+------+
| 3-105 | 计算机导论 | 825  |
| 3-245 | 操作系统   | 804  |
| 6-166 | 数字电路   | 856  |
| 9-888 | 高等数学   | 831  |
+-------+------------+------+
```



```sql
select * from student;

select s_name,s_sex,s_class from student;

1.筛选出老师属于哪些专业，不能重复
select distinct t_depart from teacher;
mysql> select distinct t_depart from teacher;
+-----------------+
| t_depart        |
+-----------------+
| 计算机系        |
| 电子工程系      |
+-----------------+

4.筛选出score表中60分到80分的学生
select * from score where sc_degree between 60 and 80;
或者
select * from score where sc_degree > 60 and sc_degree <80;

mysql> select * from score where sc_degree between 60 and 80;
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 105  | 3-245 |        75 |
| 105  | 6-166 |        79 |
| 109  | 3-105 |        76 |
| 109  | 3-245 |        68 |
+------+-------+-----------+
4 rows in set (0.00 sec)

5.筛选得到85或86或87分的同学
select * from score where sc_degree = 85 or sc_degree = 86 or sc_degree = 87;
select * from score where sc_degree in(85,86,87);

mysql> select * from score where sc_degree = 85 or sc_degree = 86 or sc_degree = 87;
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-245 |        86 |
| 103  | 6-166 |        85 |
+------+-------+-----------+
2 rows in set (0.00 sec)

6.找到学生，要求班级为95031号或者女生
select * from student where s_class = 95031 or s_sex = '女';
mysql> select * from student where s_class = 95031 or s_sex = '女';
+------+-----------+-------+---------------------+---------+
| s_no | s_name    | s_sex | s_birthday          | s_class |
+------+-----------+-------+---------------------+---------+
| 102  | 匡明      | 男    | 1975-10-02 00:00:00 | 95031   |
| 103  | 王丽      | 女    | 1976-01-23 00:00:00 | 95033   |
| 105  | 王芳      | 女    | 1975-02-10 00:00:00 | 95031   |
| 106  | 陆军      | 男    | 1974-06-03 00:00:00 | 95031   |
| 108  | 张全蛋    | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱    | 男    | 1974-06-03 00:00:00 | 95031   |
+------+-----------+-------+---------------------+---------+
6 rows in set (0.00 sec)

```

## 升降序练习（order by,asc升序 desc）

```sql
7.以班级号码倒叙排列所有学生
select * from student order by s_class desc;
mysql> select * from student order by s_class desc;
+------+-----------+-------+---------------------+---------+
| s_no | s_name    | s_sex | s_birthday          | s_class |
+------+-----------+-------+---------------------+---------+
| 101  | 曾华      | 男    | 1977-09-01 00:00:00 | 95033   |
| 103  | 王丽      | 女    | 1976-01-23 00:00:00 | 95033   |
| 104  | 李军      | 男    | 1976-02-20 00:00:00 | 95033   |
| 107  | 王尼玛    | 男    | 1976-02-20 00:00:00 | 95033   |
| 102  | 匡明      | 男    | 1975-10-02 00:00:00 | 95031   |
| 105  | 王芳      | 女    | 1975-02-10 00:00:00 | 95031   |
| 106  | 陆军      | 男    | 1974-06-03 00:00:00 | 95031   |
| 108  | 张全蛋    | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱    | 男    | 1974-06-03 00:00:00 | 95031   |
+------+-----------+-------+---------------------+---------+
9 rows in set (0.00 sec)

8.对于成绩，以升序排列班级号码，倒叙排列成绩
select * from score order by c_no asc,sc_degree desc;
mysql> select * from score order by c_no asc,sc_degree desc;
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-105 |        92 |
| 105  | 3-105 |        88 |
| 109  | 3-105 |        76 |
| 103  | 3-245 |        86 |
| 105  | 3-245 |        75 |
| 109  | 3-245 |        68 |
| 103  | 6-166 |        85 |
| 109  | 6-166 |        81 |
| 105  | 6-166 |        79 |
+------+-------+-----------+
9 rows in set (0.00 sec)

```



## 统计数量（count）

```sql
9.统计班级号为95033的同学总共有多少
select count(*) from student where s_class='95033';
mysql> select count(*) from student where s_class='95033';
+----------+
| count(*) |
+----------+
|        4 |
+----------+
1 row in set (0.00 sec)
```

## 子查询

10.求最高分学生的学号和课程编号，max()

```sql
select s_no,c_no from score where sc_degree = (select max(sc_degree) from score); 	

mysql> select s_no,c_no from score where sc_degree = (select max(sc_degree) from score);
+------+-------+
| s_no | c_no  |
+------+-------+
| 103  | 3-105 |
+------+-------+
1 row in set (0.00 sec)
```



## 切片（limit）

```sql
# 展示成绩表中，倒叙排列成绩，只显示学号和班级号，最后切片，只显示第一个
select s_no,c_no from score where sc_degree order by sc_degree desc limit 0,1;
mysql> select s_no,c_no from score where sc_degree order by sc_degree desc limit 0,1;
+------+-------+
| s_no | c_no  |
+------+-------+
| 103  | 3-105 |
+------+-------+
1 row in set (0.00 sec)
```

## 计算平均成绩（avg,group by）

```sql
11.查询每门课的平均成绩
select c_no,avg(sc_degree) from score group by c_no;
mysql> select c_no,avg(sc_degree) from score group by c_no;
+-------+----------------+
| c_no  | avg(sc_degree) |
+-------+----------------+
| 3-105 |        85.3333 |
| 3-245 |        76.3333 |
| 6-166 |        81.6667 |
+-------+----------------+
3 rows in set (0.00 sec)
```



## 分组条件及模糊查询（group by having,like）

```sql
12.查询score表中至少有两名学生选修并以3开头的课程的平均分数

select c_no,avg(sc_degree),count(c_no) from score group by c_no 
having count(c_no) >2 and c_no like '3%';
mysql> select c_no,avg(sc_degree),count(c_no) from score group by c_no 
having count(c_no) >2 and c_no like '3%';
+-------+----------------+-------------+
| c_no  | avg(sc_degree) | count(c_no) |
+-------+----------------+-------------+
| 3-105 |        85.3333 |           3 |
| 3-245 |        76.3333 |           3 |
+-------+----------------+-------------+
2 rows in set (0.00 sec)
```



## 范围查询（between and）

```sql
13.查询分数大于70，小于90的s_no列
select s_no,sc_degree from score where sc_degree >70 and sc_degree <90;
select s_no,sc_degree from score where sc_degree between 70 and 90;

mysql> select s_no,sc_degree from score where sc_degree between 70 and 90;
+------+-----------+
| s_no | sc_degree |
+------+-----------+
| 103  |        86 |
| 103  |        85 |
| 105  |        88 |
| 105  |        75 |
| 105  |        79 |
| 109  |        76 |
| 109  |        81 |
+------+-----------+
7 rows in set (0.00 sec)
```



## 多表查询(寻找相同条件)

```sql
14. 查询所有学生的s_name\c_no\sc_degree 
select s_name,c_no,sc_degree from student,score where student.s_no=score.s_no;
```



```sql
15.查询所有学生的s_no, c_name, sc_degree列
select s_no,c_name,sc_degree from score,course where score.c_no=course.c_no;
mysql> select s_no,c_name,sc_degree from score,course where score.c_no=course.c_no;
+------+------------+-----------+
| s_no | c_name     | sc_degree |
+------+------------+-----------+
| 103  | 计算机导论 |        92 |
| 103  | 操作系统   |        86 |
| 103  | 数字电路   |        85 |
| 105  | 计算机导论 |        88 |
| 105  | 操作系统   |        75 |
| 105  | 数字电路   |        79 |
| 109  | 计算机导论 |        76 |
| 109  | 操作系统   |        68 |
| 109  | 数字电路   |        81 |
+------+------------+-----------+
9 rows in set (0.03 sec)
```





## 子查询加分组求平均分(in )

```sql
17. 查询班级是'95031'班学生每门课的平均分
select avg(sc_degree) from score 
where s_no in (select s_no from student where s_class='95031') group by c_no;
```

## 子查询深入

```sql
18. 查询选修"3-105"课程的成绩高于'109'分同学'3-105'成绩 的所有同学的记录
(在大家都在选修3-105的背景下 查询 所有 分数 比 学号为"109"还要高的学生信息)
select * from score where c_no='3-105' and sc_degree > 
(select sc_degree from score where c_no='3-105' and s_no='109'); 

mysql> select * from score where c_no='3-105' and sc_degree >
    -> (select sc_degree from score where c_no='3-105' and s_no='109');
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-105 |        92 |
| 105  | 3-105 |        88 |
+------+-------+-----------+
2 rows in set (0.00 sec)
19.查询成绩高于学号为'109',课程号为'3-105'的成绩的所有记录
(不管哪门课，只要比那个分数高就行)
select * from score where sc_degree > 
(select sc_degree from score where c_no='3-105' and s_no='109');

mysql> select * from score where sc_degree > (select sc_degree from score where c_no='3-105' and s_no='109');
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-105 |        92 |
| 103  | 3-245 |        86 |
| 103  | 6-166 |        85 |
| 105  | 3-105 |        88 |
| 105  | 6-166 |        79 |
| 109  | 6-166 |        81 |
+------+-------+-----------+
6 rows in set (0.00 sec)
```

## 年份函数(year)

```sql
20.查询所有学号为108.101的同学同年出生的所有学生的s_no,s_name和s_birthday
select s_no,s_name,s_birthday from student
where year(s_birthday) in (select year(s_birthday) from student where s_no in (101,108));

mysql> select s_no,s_name,s_birthday from student
    -> where year(s_birthday) in (select year(s_birthday) from student where s_no in (101,108));
+------+--------+---------------------+
| s_no | s_name | s_birthday          |
+------+--------+---------------------+
| 101  | 曾华   | 1977-09-01 00:00:00 |
| 102  | 匡明   | 1975-10-02 00:00:00 |
| 105  | 王芳   | 1975-02-10 00:00:00 |
| 108  | 张全蛋 | 1975-02-10 00:00:00 |
+------+--------+---------------------+
```

## 嵌套子查询

```sql
21. 查询张旭老师上的课的学生的成绩
select t_no from teacher where t_name = '张旭';
select c_no from class where t_no = (select t_no from teacher where t_name = '张旭');
select * from score where c_no =(select c_no from course where t_no = (select t_no from teacher where t_name = '张旭'));
```



## in的使用

```sql
23.查询班级号为95033,95031的学生，并且倒叙排序
select * from student where s_class in (95033,95031) order by s_class;

mysql> select * from student where s_class in (95033,95031) order by s_class;
+------+--------+-------+---------------------+---------+
| s_no | s_name | s_sex | s_birthday          | s_class |
+------+--------+-------+---------------------+---------+
| 102  | 匡明   | 男    | 1975-10-02 00:00:00 | 95031   |
| 105  | 王芳   | 女    | 1975-02-10 00:00:00 | 95031   |
| 106  | 陆军   | 男    | 1974-06-03 00:00:00 | 95031   |
| 108  | 张全蛋 | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱 | 男    | 1974-06-03 00:00:00 | 95031   |
| 101  | 曾华   | 男    | 1977-09-01 00:00:00 | 95033   |
| 103  | 王丽   | 女    | 1976-01-23 00:00:00 | 95033   |
| 104  | 李军   | 男    | 1976-02-20 00:00:00 | 95033   |
| 107  | 王尼玛 | 男    | 1976-02-20 00:00:00 | 95033   |
+------+--------+-------+---------------------+---------+
9 rows in set (0.00 sec)
```



```sql
24. 查询存在85分以上成绩的课程c_no
select c_no from score where sc_degree >85;

mysql> select c_no from score where sc_degree >85;
+-------+
| c_no  |
+-------+
| 3-105 |
| 3-105 |
| 3-105 |
| 3-245 |
| 3-105 |
| 3-105 |
+-------+
6 rows in set (0.00 sec)
```

## 综合使用

```sql
25.查出所有'计算机系' 教师所教课程的成绩表
select t_no from teacher where t_depart='计算机系';
select c_no from course where t_no in (select t_no from teacher where t_depart='计算机系');
select * from score where c_no in(select c_no from course where t_no in (select t_no from teacher where t_depart='计算机系'));

mysql> select * from score where c_no in(select c_no from course where t_no in (select t_no from teacher where t_depart='计算机系'));
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-245 |        86 |
| 105  | 3-245 |        75 |
| 109  | 3-245 |        68 |
| 101  | 3-105 |        90 |
| 102  | 3-105 |        91 |
| 103  | 3-105 |        92 |
| 104  | 3-105 |        89 |
| 105  | 3-105 |        88 |
| 109  | 3-105 |        76 |
+------+-------+-----------+
9 rows in set (0.00 sec)
```

## 求并集操作(union)

```sql
26.查询'计算机系'与'电子工程系' 不同职称的教师的t_name和rof
select * from teacher where t_depart='计算机系' 
and t_rof not in (select t_rof from teacher where t_depart='电子工程系')
union
select * from teacher where t_depart='电子工程系' 
and t_rof not in (select t_rof from teacher where t_depart='计算机系');

mysql> select * from teacher where t_depart='计算机系' and t_rof not in (select t_rof from teacher where t_depart='电子 工程系')
    -> union
    -> select * from teacher where t_depart='电子工程系' and t_rof not in (select t_rof from teacher where t_depart='计 算机系');
+------+--------+-------+---------------------+--------+------------+
| t_no | t_name | t_sex | t_birthday          | t_rof  | t_depart   |
+------+--------+-------+---------------------+--------+------------+
| 804  | 李诚   | 男    | 1958-12-02 00:00:00 | 副教授 | 计算机系   |
| 856  | 张旭   | 男    | 1969-03-12 00:00:00 | 讲师   | 电子工程系 |
+------+--------+-------+---------------------+--------+------------+
2 rows in set (0.00 sec)

严格正确版：
select t_name,t_rof from teacher where t_depart='计算机系' 
and t_rof not in (select t_rof from teacher where t_depart='电子工程系')
union
select t_name,t_rof from teacher where t_depart='电子工程系' 
and t_rof not in (select t_rof from teacher where t_depart='计算机系');

+--------+--------+
| t_name | t_rof  |
+--------+--------+
| 李诚   | 副教授 |
| 张旭   | 讲师   |
+--------+--------+
2 rows in set (0.00 sec)
```



## 多个值比较多个值：至少（any）

```sql
27, 查询选修编号为"3-105"课程且成绩至少高于选修编号为'3-245'同学的c_no,s_no和sc_degree,并且按照sc_degree从高到地次序排序

select c_no,s_no,sc_degree from score where c_no='3-105' and sc_degree > any(select sc_degree from score where c_no='3-245') order by sc_degree desc;

+-------+------+-----------+
| c_no  | s_no | sc_degree |
+-------+------+-----------+
| 3-105 | 103  |        92 |
| 3-105 | 102  |        91 |
| 3-105 | 101  |        90 |
| 3-105 | 104  |        89 |
| 3-105 | 105  |        88 |
| 3-105 | 109  |        76 |
+-------+------+-----------+
6 rows in set (0.00 sec)
```



## 多个值比较多个值：所有（all）

```sql
28.查询选修编号为"3-105"且成绩高于选修编号为"3-245"课程的同学c_no.s_no和sc_degree
select c_no,s_no,sc_degree from score where c_no='3-105' and sc_degree > all(select sc_degree from score where c_no='3-245');
+-------+------+-----------+
| c_no  | s_no | sc_degree |
+-------+------+-----------+
| 3-105 | 101  |        90 |
| 3-105 | 102  |        91 |
| 3-105 | 103  |        92 |
| 3-105 | 104  |        89 |
| 3-105 | 105  |        88 |
+-------+------+-----------+
5 rows in set (0.00 sec)
```

## 使用别名(as)

```sql
29.查询所有教师和同学的 name ,sex, birthday
select s_name as name,s_sex as sex,s_birthday as birthday from student 
union 
select t_name as name,t_sex as sex,t_birthday as birthday from teacher;

mysql> select s_name as name,s_sex as sex,s_birthday as birthday from student
    -> union
    -> select t_name as name,t_sex as sex,t_birthday as birthday from teacher;
+--------+-----+---------------------+
| name   | sex | birthday            |
+--------+-----+---------------------+
| 曾华   | 男  | 1977-09-01 00:00:00 |
| 匡明   | 男  | 1975-10-02 00:00:00 |
| 王丽   | 女  | 1976-01-23 00:00:00 |
| 李军   | 男  | 1976-02-20 00:00:00 |
| 王芳   | 女  | 1975-02-10 00:00:00 |
| 陆军   | 男  | 1974-06-03 00:00:00 |
| 王尼玛 | 男  | 1976-02-20 00:00:00 |
| 张全蛋 | 男  | 1975-02-10 00:00:00 |
| 赵铁柱 | 男  | 1974-06-03 00:00:00 |
| 李诚   | 男  | 1958-12-02 00:00:00 |
| 王萍   | 女  | 1972-05-05 00:00:00 |
| 刘冰   | 女  | 1977-08-14 00:00:00 |
| 张旭   | 男  | 1969-03-12 00:00:00 |
+--------+-----+---------------------+
30.查询所有'女'教师和'女'学生的name,sex,birthday
select s_name as name,s_sex as sex,s_birthday as birthday from student where s_sex='女'
union 
select t_name as name,t_sex as sex,t_birthday as birthday from teacher where t_sex='女';

+------+-----+---------------------+
| name | sex | birthday            |
+------+-----+---------------------+
| 王丽 | 女  | 1976-01-23 00:00:00 |
| 王芳 | 女  | 1975-02-10 00:00:00 |
| 王萍 | 女  | 1972-05-05 00:00:00 |
| 刘冰 | 女  | 1977-08-14 00:00:00 |
+------+-----+---------------------+
4 rows in set (0.00 sec)
```

## 复制表数据作条件查询(别名的使用)

```sql
31. 查询成绩比该课程平均成绩低的同学的成绩表

 select * from score a where sc_degree < (select avg(sc_degree) from score b where a.c_no=b.c_no);
 
 +------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 105  | 3-245 |        75 |
| 105  | 6-166 |        79 |
| 109  | 3-105 |        76 |
| 109  | 3-245 |        68 |
| 109  | 6-166 |        81 |
+------+-------+-----------+
5 rows in set (0.01 sec)
```



```sql
32.查询所有任课教师的t_name 和 t_depart(要在分数表中可以查得到)
select t_name,t_depart from teacher where t_no in (select t_no from course);

+--------+------------+
| t_name | t_depart   |
+--------+------------+
| 李诚   | 计算机系   |
| 王萍   | 计算机系   |
| 刘冰   | 电子工程系 |
| 张旭   | 电子工程系 |
+--------+------------+
4 rows in set (0.02 sec)
```

## 条件加分组查询

```sql
33.查出至少有2名男生的班号
select s_class from student group by s_class having count(s_sex='男')>1;
select s_class from student where s_sex='男' group by s_class having count(s_no)>1;

mysql> select s_class from student where s_sex='男' group by s_class having count(s_no)>1;
+---------+
| s_class |
+---------+
| 95033   |
| 95031   |
+---------+
2 rows in set (0.00 sec)
```

## 模糊查询取反(not like,%)

```sql
34. 查询student 表中不姓"王"的同学的记录
select * from student where s_name not like '王%';

+------+--------+-------+---------------------+---------+
| s_no | s_name | s_sex | s_birthday          | s_class |
+------+--------+-------+---------------------+---------+
| 101  | 曾华   | 男    | 1977-09-01 00:00:00 | 95033   |
| 102  | 匡明   | 男    | 1975-10-02 00:00:00 | 95031   |
| 104  | 李军   | 男    | 1976-02-20 00:00:00 | 95033   |
| 106  | 陆军   | 男    | 1974-06-03 00:00:00 | 95031   |
| 108  | 张全蛋 | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱 | 男    | 1974-06-03 00:00:00 | 95031   |
+------+--------+-------+---------------------+---------+
6 rows in set (0.00 sec)
```



## 计算年龄大小(year(now()))

```sql
35. 查询student 中每个学生的姓名和年龄(当前时间 - 出生年份)

select s_name,year(now())-year(s_birthday) as age from student;
+--------+------+
| s_name | age  |
+--------+------+
| 曾华   |   43 |
| 匡明   |   45 |
| 王丽   |   44 |
| 李军   |   44 |
| 王芳   |   45 |
| 陆军   |   46 |
| 王尼玛 |   44 |
| 张全蛋 |   45 |
| 赵铁柱 |   46 |
+--------+------+
```

## 最大值最小值（min,max）

```sql
36. 查询student中最大和最小的 s_birthday的值
select min(s_birthday),max(s_birthday) from student;
+---------------------+---------------------+
| min(s_birthday)     | max(s_birthday)     |
+---------------------+---------------------+
| 1974-06-03 00:00:00 | 1977-09-01 00:00:00 |
+---------------------+---------------------+
1 row in set (0.00 sec)
```

## 多字段排序

```sql
37. 以班级号和年龄从大到小的顺序查询student表中的全部记录
select * from student order by s_class desc and s_birthday;
+------+--------+-------+---------------------+---------+
| s_no | s_name | s_sex | s_birthday          | s_class |
+------+--------+-------+---------------------+---------+
| 101  | 曾华   | 男    | 1977-09-01 00:00:00 | 95033   |
| 102  | 匡明   | 男    | 1975-10-02 00:00:00 | 95031   |
| 103  | 王丽   | 女    | 1976-01-23 00:00:00 | 95033   |
| 104  | 李军   | 男    | 1976-02-20 00:00:00 | 95033   |
| 105  | 王芳   | 女    | 1975-02-10 00:00:00 | 95031   |
| 106  | 陆军   | 男    | 1974-06-03 00:00:00 | 95031   |
| 107  | 王尼玛 | 男    | 1976-02-20 00:00:00 | 95033   |
| 108  | 张全蛋 | 男    | 1975-02-10 00:00:00 | 95031   |
| 109  | 赵铁柱 | 男    | 1974-06-03 00:00:00 | 95031   |
+------+--------+-------+---------------------+---------+
9 rows in set (0.00 sec)
```

## 子查询练习

```sql
38. 查询"男"教师 及其所上的课
select t_no from teacher where t_sex='男';
select * from course where t_no in (select t_no from teacher where t_sex='男');

mysql> select * from course where t_no in (select t_no from teacher where t_sex='男');
+-------+----------+------+
| c_no  | c_name   | t_no |
+-------+----------+------+
| 3-245 | 操作系统 | 804  |
| 6-166 | 数字电路 | 856  |
+-------+----------+------+
2 rows in set (0.00 sec)
39.查询最高分同学的s_no c_no 和 sc_degree;
select max(sc_degree) from score;
select * from score where sc_degree =(select max(sc_degree) from score);
+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 103  | 3-105 |        92 |
+------+-------+-----------+
1 row in set (0.00 sec)
```



```sql
40. 查询和"李军"同性别的所有同学的s_name
select s_name from student where s_sex = (select s_sex from student where s_name='李军');

mysql> select s_name from student where s_sex = (select s_sex from student where s_name='李军');
+--------+
| s_name |
+--------+
| 曾华   |
| 匡明   |
| 李军   |
| 陆军   |
| 王尼玛 |
| 张全蛋 |
| 赵铁柱 |
+--------+
7 rows in set (0.00 sec)
41.查询和"李军"同性别并且同班的所有同学的s_name
SELECT s_name, s_sex FROM student WHERE s_sex = (SELECT s_sex FROM student WHERE s_name = '李军') AND s_class = (SELECT s_class FROM student WHERE s_name = '李军');
+--------+
| s_name |
+--------+
| 曾华   |
| 李军   |
| 王尼玛 |
+--------+
3 rows in set (0.00 sec)
```



```sql
42. 查询所有选修'计算机导论'课程的'男'同学的成绩表
select c_no from course where c_name='计算机导论';
select s_no from student where s_sex='男'；
select * from score where s_no in (select s_no from student where s_sex='男') and 
c_no in (select c_no from course where c_name='计算机导论');

+------+-------+-----------+
| s_no | c_no  | sc_degree |
+------+-------+-----------+
| 101  | 3-105 |        90 |
| 102  | 3-105 |        91 |
| 104  | 3-105 |        89 |
| 109  | 3-105 |        76 |
+------+-------+-----------+
4 rows in set (0.00 sec)
```

# 连接查询

![img](DQL查询练习/sql_joins.png)

左外连接

左连接

全连接

**两张表都没有出现交集的数据集**

右连接

右外连接

内连接

## 连接查询案例

## 内连接（inner join …… on）

```sql
mysql> create table card(
    -> id int,
    -> name varchar(20)
    -> );

insert into card values(1,'饭卡');
insert into card values(2,'建行卡');
insert into card values(3,'农行卡');
insert into card values(4,'工商卡');
insert into card values(5,'邮政卡');
```



```sql
mysql> create table person(
    -> id int,
    -> name varchar(20),
    -> cardId int);
    
insert into person values(1,'张三',1);
insert into person values(2,'李四',3);
insert into person values(3,'王五',6);
```

**person表:**

```sql
mysql> select * from person;
+------+--------+--------+
| id   | name   | cardId |
+------+--------+--------+
|    1 | 张三   |      1 |
|    2 | 李四   |      3 |
|    3 | 王五   |      6 |
+------+--------+--------+
3 rows in set (0.00 sec)
```

**card表:**

```sql
mysql> select * from card;
+------+-----------+
| id   | name      |
+------+-----------+
|    1 | 饭卡      |
|    2 | 建行卡    |
|    3 | 农行卡    |
|    4 | 工商卡    |
|    5 | 邮政卡    |
+------+-----------+
5 rows in set (0.00 sec)
```

### 内连接查询

```sql
select * from person inner join card on person.cardId=card.id;
+------+------+--------+------+--------+
| id   | name | cardId | id   | name   |
+------+------+--------+------+--------+
|    1 | 张三 |      1 |    1 | 饭卡   |
|    2 | 李四 |      3 |    3 | 农行卡 |
+------+------+--------+------+--------+
2 rows in set (0.00 sec)
```

整个查询的执行过程如下:

1. 从 `person` 表中选取所有记录
2. 对于每个 `person` 记录,查找 `card` 表中 `id` 字段与 `person.cardId` 相匹配的记录
3. 将匹配的 `person` 和 `card` 记录组合成一条结果记录返回

## 外连接

### 左外连接(left join ...... on)

左外连接会把左边的表的数据全部取出来  ，右边表如果没有就用NULL补上

```sql
mysql> select * from person left join card on person.cardId=card.id;
+------+------+--------+------+--------+
| id   | name | cardId | id   | name   |
+------+------+--------+------+--------+
|    1 | 张三 |      1 |    1 | 饭卡   |
|    2 | 李四 |      3 |    3 | 农行卡 |
|    3 | 王五 |      6 | NULL | NULL   |
+------+------+--------+------+--------+
3 rows in set (0.00 sec)
```

整个查询的执行过程如下:

1. 从 `person` 表中选取所有记录
2. 对于每个 `person` 记录,查找 `card` 表中 `id` 字段与 `person.cardId` 相匹配的记录
3. 将匹配的 `person` 和 `card` 记录组合成一条结果记录返回
4. 对于无法匹配的 `person` 记录,用 `NULL` 填充 `card` 表的字段

### 右外连接(right join ...... on)

右外连接会把左边的表的数据全部取出来，左边表如果没有就用NULL补上

```sql
mysql> select * from person right join card on person.cardId=card.id;
+------+------+--------+------+--------+
| id   | name | cardId | id   | name   |
+------+------+--------+------+--------+
|    1 | 张三 |      1 |    1 | 饭卡   |
| NULL | NULL |   NULL |    2 | 建行卡 |
|    2 | 李四 |      3 |    3 | 农行卡 |
| NULL | NULL |   NULL |    4 | 工商卡 |
| NULL | NULL |   NULL |    5 | 邮政卡 |
+------+------+--------+------+--------+
5 rows in set (0.00 sec)
```

整个查询的执行过程如下:

1. 从 `card` 表中选取所有记录
2. 对于每个 `card` 记录,查找 `person` 表中 `cardId` 字段与 `card.id` 相匹配的记录
3. 将匹配的 `person` 和 `card` 记录组合成一条结果记录返回
4. 对于无法匹配的 `card` 记录,用 `NULL` 填充 `person` 表的字段

### 全连接（full join）

```sql
select * from person full join card on person.cardId=card.id;

mysql不支持全连接，换一种方式表达

select * from person left join card on person.cardId=card.id union select * from person right join card on person.cardId=card.id;
+------+------+--------+------+--------+
| id   | name | cardId | id   | name   |
+------+------+--------+------+--------+
|    1 | 张三 |      1 |    1 | 饭卡   |
|    2 | 李四 |      3 |    3 | 农行卡 |
|    3 | 王五 |      6 | NULL | NULL   |
| NULL | NULL |   NULL |    2 | 建行卡 |
| NULL | NULL |   NULL |    4 | 工商卡 |
| NULL | NULL |   NULL |    5 | 邮政卡 |
+------+------+--------+------+--------+
6 rows in set (0.00 sec)
```

整个查询的执行过程如下:

1. 从 `person` 表和 `card` 表中选取所有记录
2. 对于每个 `person` 记录,查找 `card` 表中 `id` 字段与 `person.cardId` 相匹配的记录
3. 对于每个 `card` 记录,查找 `person` 表中 `cardId` 字段与 `card.id` 相匹配的记录
4. 将匹配的 `person` 和 `card` 记录组合成一条结果记录返回
5. 对于无法匹配的记录,用 `NULL` 填充相应的字段