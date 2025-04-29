# 计算机组成：硬件+软件

## CPU、内存和硬盘

### CPU（中央处理器）

大脑，电脑靠CPU来运算、控制。

### 硬盘

   - 计算机最主要的存储设备，容量大，断电数据不丢失。
   - 正常分类：机械硬盘（HDD）、固态硬盘（SSD）以及混合硬盘（SSHD）
   - 固态硬盘在开机速度和程序加载速度远远高于机械硬盘，缺点就是贵，所有无法完全取代机械硬盘。

### 内存（Memory）

   - 负责硬盘上的数据与CPU之间数据交换处理
   - 具体的：保存从硬盘读取的数据，提供给CPU使用；保存CPU的一些临时执行结果，以便CPU下次使用或保存到硬盘。
   - 断电后数据丢失。

# DOS命令

DOS（Disk Operating System，磁盘操作系统）是Microsoft公司在Windows之前推出的一个操作系统，是单用户、单任务（即只能执行一个任务）的操作系统。现在被Windows系统取代。
对于Java初学者，学习一些DOS命令，会非常有帮助。
![](Java%E5%9F%BA%E7%A1%80/1687931286297-240f7218-423b-4eee-bb39-8a02bec69df5.png)
**常用指令：**

- 操作1：进入和回退

| **操作**             | **说明**                             |
| -------------------- | ------------------------------------ |
| 盘符名称:            | 盘符切换。E:回车，表示切换到E盘。    |
| dir                  | 列出当前目录下的文件以及文件夹       |
| cd 目录              | 进入指定单级目录。                   |
| cd 目录1\\目录2\\... | 进入指定多级目录。cd atguigu\\JavaSE |
| cd ..                | 回退到上一级目录。                   |
| cd \\ 或 cd /        | 回退到盘符目录。                     |

- 操作2：增、删

| **操作**      | **说明**                                           |
| ------------- | -------------------------------------------------- |
| md 文件目录名 | 创建指定的文件目录。                               |
| rd 文件目录名 | 删除指定的文件目录（如文件目录内有数据，删除失败） |

- 操作3：其它

| **操作**          | **说明**             |
| ----------------- | -------------------- |
| cls               | 清屏。               |
| exit              | 退出命令提示符窗口。 |
| ← →               | 移动光标             |
| ↑ ↓               | 调阅历史操作命令     |
| Delete和Backspace | 删除字符             |

```shell
# 盘符切换 E:
# 查看当前目录下所有文件 dir
# 切换目录 cd /d E:\idea
# 返回上一级目录 cd ..
# 进入同级目录下的下一级目录 cd tmp(该目录下的文件名)
# 清屏 cls (clear screen)
# 退出终端 exit
# 查看电脑当前IP地址 ipconfig

# 打开计算器 calc
# 打开画图 mspaint
# 新建记事本 notepad

# 在当前目录新建文件夹 md test(文件夹名)
# 新建文件 cd> a.txt(文件名)
# 删除文件 del a.txt(文件名)
# 删除目录 rd test(目录名)

# ping命令(复制链接进入Dos直接单击鼠标右键粘贴)
	ping www.baidu.com
```

# 计算机语言简史

- **第一代：机器语言**
  - 1946年2月14日，世界上第一台计算机ENAC诞生，使用的是最原始的穿孔卡片。这种卡片上使用的是用二进制代码表示的语言，与人类语言差别极大，这种语言就称为机器语言。比如一段典型的机器码：

```java
1.  0000,0000,000000010000 代表 LOAD A, 16
2.  0000,0001,000000000001 代表 LOAD B, 1
3.  0001,0001,000000010000 代表 STORE B, 16
```

- **第二代：汇编语言**
  - 使用英文缩写的助记符来表示基本的操作，这些助记符构成了汇编语言的基础。比如：LOAD、MOVE等，使人更容易使用。因此，汇编语言也称为符号语言。
  - 优点：能编写高效率的程序
  - 缺点：汇编语言是面向机器的，不同计算机机型特点不同，因此会有不同的汇编语言，彼此之间不能通用。程序不易移植，较难调试。

![](Java%E5%9F%BA%E7%A1%80/1687931427793-bc1901f4-527f-4f19-a2a8-764a76097e36.png)

   - 比起机器语言，汇编大大进步了，是机器语言向更高级的语言进化的桥梁。目前仍然应用于工业电子编程领域、软件的加密解密、计算机病毒分析等。
- **第三代：高级语言**
- 高级语言发展于20世纪50年代中叶到70年代，是一种接近于人们使用习惯的程序设计语言。它允许程序员使用接近日常英语的指令来编写程序，程序中的符号和算式也与日常用的数学式子差不多，接近于自然语言和数学语言，容易为人们掌握。比如：

![](Java%E5%9F%BA%E7%A1%80/1687931450605-49faf332-5862-4b6c-a7c8-e4fce7d52786.png)

   - 高级语言独立于机器，有一定的通用性；计算机不能直接识别和执行用高级语言编写的程序，需要使用编译器或者解释器，转换为机器语言才能被识别和执行。

![](Java%E5%9F%BA%E7%A1%80/1687931458459-025b754c-2f78-4cc1-b4d5-b55a2465f205.png)





# 兴趣是学习编程最好的老师

- **不积跬步，无以至千里**

- **这辈子没办法做太多事情，所以每一件都要做到精彩绝伦**

  

# Java发展史

- 詹姆斯·高斯林（James Gosling）

  <img src="Java%E5%9F%BA%E7%A1%80/image-20241126101828983.png" alt="image-20241126101828983" style="zoom:50%;" align="left"/>

- **1977年获得了加拿大卡尔加里大学计算机科学学士学位，1983年 获得了美国卡内基梅隆大学计算机科学博士学位，毕业后到IBM工作，设计     IBM第一代工作站NeWS系统，但不受重视。后来 转至Sun公司，1990年，与Patrick，Naughton和Mike Sheridan等人合作“绿色计划”，后来发展一套语言叫做“Oak”，后改名为Java。**

# Java的特性与优势

- **简单性**
- **面对对象**
- **可移植性**
- **高性能**
- **分布式**
- **多态性**
- **多线程**
- **安全性**
- **健壮性**

## 什么是JDK、JRE

- **JDK** (Java Development Kit)：是Java程序开发工具包，包含JRE 和开发人员使用的工具。
- **JRE ** (Java Runtime Environment) ：是Java程序的运行时环境，包含JVM 和运行时所需要的核心类库。

![](Java%E5%9F%BA%E7%A1%80/1687931569935-fe39b63f-1c85-401a-bf7d-630cbe2dca98.png)
**三者的关系**

JDK = JRE + 其他 
JRE = JVM + 其他

**总结：使用JDK开发完成的java程序，交给JRE去运行**

## Java特点

1. **面向对象（oop）**
2. **健壮性：强类型机制，异常处理，垃圾的自动收集**
3. **跨平台性的 （一个编译好的.class可以在多个系统下运行）**

​	TEST.java -> TEST.class （java虚拟机机制） 在windows上和在Linux以及mac系统上都可以运行

<img src="Java%E5%9F%BA%E7%A1%80/image-20241125112221370.png" alt="image-20241125112221370" style="zoom:50%;" />

4. **java语言是解释型的语言 ： js php java 解释型语言（代码不能在编译器直接运行，需要用到解释器） c/c++ 编译型语言 （二进制代码，可以直接在编译器里面运行）**



# 开发步骤

1. 编写

将JAVA 代码编写到项目扩展名为`.java`的源文件中

2. 编译

通过`javac.exe`命令对这个`java`文件进行编译，生成一个或多个字节码文件

3. 运行

通过`java.exe`命令对生成的`class`文件进行运行
![image.png](Java%E5%9F%BA%E7%A1%80/1696591177954-a52ffc30-921a-43bd-8dc4-53734620b2a4.png)

## 编写

创建文件改名为.java后缀

```java
class HelloWorld {
	public static void main(String[] args) {
		System.out.println("HelloWorld");
	}
}
```

## 编译

```bash
javac java文件
javac HelloWorld.java
```

![image.png](Java%E5%9F%BA%E7%A1%80/1696591647162-d5e13b13-1158-4031-99eb-aa9353ed2e97.png)

## 运行

```bash
java 主类名字
java HelloWorld
```

![image.png](Java%E5%9F%BA%E7%A1%80/1696591699014-30d1a555-e3b6-41f0-81d3-8b33dce8da3f.png)

# 常见的错误

## 拼写问题

- 单词拼写问题
  - 正确 ： class	  	错误： Class
  - 正确： String		错误：string
  - 正确：System		错误：system
- Java语言是一门严格区分大小写的语言
- 标点符号使用问题
  - 不能用中文符号，英文半角的标点符号（正确）
  - 括号问题，成对出现

# 注释

- 什么是注释？
  - 源文件中用于解释、说明程序的文字就是注释。
- 注释是一个程序员必须要具有的良好编程习惯。实际开发中，程序员可以先将自己的思想通过注释整理出来，再用代码去体现。

程序员最讨厌两件事：
一件是自己写代码被要求加注释
另一件是接手别人代码，发现没有注释

Java中的注释类型：

- 单行注释

```java
//注释文字
```

- 多行注释

```java
/* 
注释文字1 
注释文字2
注释文字3
*/
```

- 文档注释

```java
/**
  @author  指定java程序的作者
  @version  指定源文件的版本
*/ 
```

# 注释的作用


- 它提升了程序的可阅读性。
- 调试程序的重要方法。

# 关键字与保留字

- 定义：被 Java 语言赋予了特殊含义，用做专门用途的字符串（单词）
- 特点：关键字中所有字母都为小写
- 官网：[https://docs.oracle.com/javase/tutorial/java/nutsandbolts/_keywords.html](https://docs.oracle.com/javase/tutorial/java/nutsandbolts/_keywords.html)

用于定义数据类型的关键字

| class | interface | enum   |
| ----- | --------- | ------ |
| byte  | short     | int    |
| long  | float     | double |
| char  | boolean   | void   |

用于定义流程控制的关键字

| if       | else    | switch |
| -------- | ------- | ------ |
| case     | default | while  |
| do       | for     | break  |
| continue | return  |        |

 |

用于定义访问权限修饰符的关键字

| public | private | protected |
| ------ | ------- | --------- |

用于定义类,函数，变量修饰符的关键字

| abstract | final | static | synchronized |
| -------- | ----- | ------ | ------------ |

用于定义类与类之间关系的关键字

| extends | implements |
| ------- | ---------- |

用于定义建立实例及引用实例,判断实例的关键字

| new  | this | super | instanceof |
| ---- | ---- | ----- | ---------- |

用于异常处理的关键字

| try  | catch | finally | throw | throws |
| ---- | ----- | ------- | ----- | ------ |

用于包的关键字

| package | import |
| ------- | ------ |

其他修饰符关键字

| native | strictfp | transient | volatile | assert |
| ------ | -------- | --------- | -------- | ------ |

用于定义数据类型值的字面值

| true | false | null |
| ---- | ----- | ---- |

# 标识符

- 所有标识符都应该以 字母、$(美元符)、_(下划线) 开头，首字母之后可以是 字母、$、_ 或数字任何字符组合
- **关键字不能作为变量名或方法名**
- **严格区分大小写，长度无限制**
- **可以用中文命名，但不建议使用**

# 变量的概念

- 内存中的一个存储区域，该区域的数据可以在同一类型范围内不断变化
- 变量的构成包含三个要素：数据类型、变量名、存储的值
- Java中变量声明的格式：数据类型 变量名 = 变量值

# 变量的作用

- 用于在内存中保存数据。

# 注意：

- 使用变量注意：
  - Java中每个变量必须先声明，后使用。
  - 使用变量名来访问这块区域的数据。
  - 变量的作用域：其定义所在的一对{ }内。
  - 变量只有在其作用域内才有效。出了作用域，变量不可以再被调用。
  - 同一个作用域内，不能定义重名的变量。
    - 在Java中，变量分为两种：基本类型的变量 和 引用类型的变量。

# 基本使用

在Java中，变量必须先定义后使用，在定义变量的时候，可以给它一个初始值。例如：

```java
 int i = 10;
```

不写初始值，就相当于给它指定了默认值。默认值总是0。
变量的一个重要特点是可以重新赋值。

```java
public class Variable02 {
    public static void main(String[] args) {
        //定义 int 类型变量
        int x = 100;
        System.out.println(x);
        x = 200;
        System.out.println(x);
    }
}
```

变量不但可以重新赋值，还可以赋值给其他变量。

```java
public class Variable02 {
    public static void main(String[] args) {
        //定义 int 类型变量
        int x = 100;
        System.out.println(x); //100

        x = 200;
        System.out.println(x); //200

        int y = x;
        System.out.println(y); //200

        x = x + 100;
        System.out.println(x); //300
    }
}
```

# 数据类型

- **基本数据类型**：包括 整数类型、浮点数类型、字符类型、布尔类型。 
- **引用数据类型**：包括数组、 类、接口、枚举、注解、记录。 

## 基本数据类型

- 整数类型：`byte`(1个)、`short`（2个）、`int`（4ge） 、 `long`（8个）
- 浮点数类型：`float`（4个）、`double`（8个）
- 字符类型：`char`（2个）
- 布尔： `boolean`

计算机内存的最小存储单元是字节（byte），一个字节就是一个8位二进制数，即8个bit。
一个字节是1byte，1024字节是1K，1024K是1M，1024M是1G，1024G是1T。一个拥有4T内存的计算机的字节数量就是：

```bash
4T =  4 * 1024G
	 = 4 * 1024 * 1024M
   = 4 * 1024 * 1024 * 1024K
   = 4 * 1024 * 1024 * 1024 * 1024
```

### 整型（4个）

- byte：-128 ~ 127
- short: -32768 ~ 32767
- int: -2147483648 ~ 2147483647
- long: -9223372036854775808 ~ 9223372036854775807

布尔类型`boolean`只有`true`和`false`两个值。
字符类型`char`表示一个字符。Java的`char`类型除了可表示标准的`ASCII`外，还可以表示一个`Unicode`字符：

```java
public class BaseType {
    public static void main(String[] args) {

        //整形
        int a = 1237;

        //浮点
        float f = 3.14f;
        double d = 1.73;

        //布尔类型
        boolean b1 = true;
        boolean b2 = false;

        // true
        boolean flag = 5 > 3;
        System.out.println(flag);

        int age = 15;

        //false
        boolean isAdult = age >= 18;
        System.out.println(isAdult);

        //字符类型
        char c = 'A';
        char zh = '中';
        System.out.println(c);
        System.out.println(zh);

    }
}
```

## 引用数据类型

### 字符串

```java
String str = "今晚去洗脚"
```

## 常量

定义变量的时候，如果加上`final`修饰符，这个变量就变成了常量：

```java
public class Constant {
    public static void main(String[] args) {
        final double PI = 3.14;
        double r = 5.0;
        double area = PI * r * r;
        System.out.println(area);

        // TODO 对常量进行再次赋值
        PI = 20;
    }
}
```

常量在定义时进行初始化后就不可再次赋值，再次赋值会导致编译错误。

# 算术运算符

<img src="Java%E5%9F%BA%E7%A1%80/image-20241202165306113.png" alt="image-20241202165306113" style="zoom:80%" align="left"/>

# 逻辑运算符

| &      | &#124; | ！     | &&     | &#124;&#124; | ^        |
| ------ | ------ | ------ | ------ | ------------ | -------- |
| 逻辑与 | 逻辑或 | 逻辑非 | 短路与 | 短路或       | 逻辑异或 |

逻辑运算符用于连接布尔型表达式，在Java中不可以写成`3<x<6`，应该写成` x>3 & x<6 `。
“&”和“&&”的区别：
单&时，左边无论真假，右边都进行运算；
&&时，如果左边为真，右边参与运算，如果左边为假，那么右边不参与运算。
“|”和“||”的区别同理，||表示：当左边为真，右边不参与运算。
异或(^)与或( | )的不同之处是：当左右都为true时，结果为false。理解：异或，追求的是“异”!

| a     | b     | a&b   | a&&b  | a&#124;b | a&#124;&#124;b | !a    |  a^b  |
| ----- | ----- | ----- | ----- | -------- | -------------- | ----- | :---: |
| true  | true  | true  | true  | true     | true           | false | false |
| true  | false | false | false | true     | true           | false | true  |
| false | true  | false | false | true     | true           | true  | true  |
| false | false | false | false | false    | false          | true  | false |

# 整数运算

整数运算永远是精确的，即使是除法也是精确的，因为两个整数相除只能得到结果的整数部分：

```java
public class 运算 {
    public static void main(String[] args) {
        int x  = 100 / 20;
        System.out.println(x);
        System.out.println(100 / 30);

        //求余 %
        int y = 12345 % 67;
        System.out.println(y);
    }
}
```

## 溢出

要特别注意，整数由于存在范围限制，如果计算结果超出了范围，就会产生溢出，而溢出_不会出错_，却会得到一个奇怪的结果：

```java
int a = 2147483640;
int b = 15;
int sum = a + b;
System.out.println(sum);
```

把整数2147483640和15换成二进制做加法，由于最高位计算结果为1，因此，加法结果变成了一个负数。
要解决上面的问题，可以把`int`换成`long`类型，由于long可表示的整型范围更大，所以结果就不会溢出。

## 自增

```java
int c = 33;
c++; //34
c--; //33
int d = 100 + (++c); //134
System.out.println(d);
```

`++`写在 后面是先运算后自增， 写在前面是先自增再运算。

## 移位运算

在计算机中，整数总是以二进制的形式表示。
00000000 00000000 00000000 00000111 = 7

```java
System.out.println("======移位运算======");
int n = 7; //00000000 00000000 00000000 00000111 = 7
//TODO 左位移
int n2 = n << 1; //00000000 00000000 00000000 00001110 = 14
int n3 = n << 2;//00000000 00000000 00000000 00011100 = 28

//TODO 右位移
int n4 = n >> 1; //00000000 00000000 00000000 00000011 = 3
int n5 = n >> 2; //00000000 00000000 00000000 00000001 = 1

int n6 = -536870912;
//TODO 无符号右位移
int n7 = n6 >>> 1;
System.out.println(n7);
```

## 位运算

位运算是按位进行与、或、非和异或的运算。
与运算的规则是，必须两个数同时为1，结果才为1：

```java
System.out.println("======位运算======");

//TODO 与运算 有假必假
System.out.println(0 & 0); //0
System.out.println(0 & 1); //0
System.out.println(1 & 0); //0
System.out.println(1 & 1); //1

//TODO 或运算 有真必真
System.out.println(0 | 0); //0
System.out.println(0 | 1); //1
System.out.println(1 | 0); //1
System.out.println(1 | 1); //1

//TODO 非运算 如果位为0，结果是1，如果位为1，结果是0.
System.out.println(!true);//1
System.out.println(!false);//0

//TODO 异或运算的规则是，如果两个数不同，结果为1，否则为0
System.out.println(0 ^ 0); //0
System.out.println(0 ^ 1);//1
System.out.println(1 ^ 0);//1
System.out.println(1 ^ 1);//0
```

## 运算符的优先级

- ()
- !  ~  ++  --
- *  /   %
- +   -
- <<   >>    >>>
- &
- |
- += -= *= /=

记不住也没关系  只需要加括号就可以保证运算的优先级正确。

## 类型自动提升和强制转型

在运算过程中，如果参与运算的两个数类型不一致，那么计算结果为较大类型的整型。short和int计算，结果总是int，原因是short首先自动被转型为int：
 两个变量相加，先对类型进行提升，然后运算，再将运算结果赋值。
两个常量相加，先计算常量数值，然后判断是否满足类型范围，再赋值。  

```java
System.out.println("======类型自动提升======");

short s = 12345;
int n = 12345;
//short result = n + s;
int result = n + s;

double d = 3.14;
double result02 = s + n + d;

int n2 = 45678;
int result03 = n + n2;

//TODO byte 变量进行相加的时候
byte b1 = 1;
byte b2 = 2;
//byte result04 = b1 + b2;//编译报错，byte变量相加，自动升级为 int
```

将范围大的类型强制转换为范围小的类型。强制转型使用(类型)：

```java
//TODO 将范围大的类型强制转换为范围小的类型
short s = 12345;
int n = 12345;
short result = (short) (n + s);

double d = 3.14;
short result02 = (short) (s + n + d);

//TODO byte 变量进行相加的时候
byte b1 = 1;
byte b2 = 2;

byte result03 = (byte) (b1 + b2);
```

要注意，超出范围的强制转型会得到错误的结果，原因是转型时，`int`的两个高位字节直接被扔掉，仅保留了低位的两个字节。

## 练习

![](Java%E5%9F%BA%E7%A1%80/1668577641346-3e95aab4-0694-47bd-82cc-9c44f644e06a.png)

# 浮点数的运算

浮点数运算和整数运算相比，只能进行加减乘除这些数值计算，不能做位运算和移位运算。
浮点数有个非常重要的特点，就是浮点数常常无法精确表示。

```java
double x = 1.0 / 10; //0.1
double y = 1 - 9.0 / 10; //0.09999999999999998
System.out.println(x);
System.out.println(y);
```

由于浮点数存在运算误差，所以比较两个浮点数是否相等常常会出现错误的结果。正确的比较方法是判断两个浮点数之差的绝对值是否小于一个很小的数：

```java
double r = Math.abs(x -y);
if (r < 0.00001) {
    //相等
}else {
    //不相等
}
```

## 类型提升

如果参与运算的两个数其中一个是整型，那么整型可以自动提升到浮点型：

```java
int n = 5;
double d = 1.2 + 24.0 / n; //6.0
System.out.println(d);
```

## 溢出

整数运算在除数为0时会报错，而浮点数运算在除数为0时，不会报错，但会返回几个特殊值：

- `NaN`表示`Not a Number`
- `Infinity`表示无穷大
- `-Infinity`表示负无穷大

```java
System.out.println("===========");

double d1 = 0.0 / 0; //NAN
double d2 = 1.0 / 0; //Infinity
double d3 = -1.0 / 0; //-Infinity

System.out.println(d1);
System.out.println(d2);
System.out.println(d3);
```

## 强制转换

可以将浮点数强制转型为整数。在转型时，浮点数的小数部分会被丢掉。如果转型后超过了整型能表示的最大范围，将返回整型的最大值。

```java
System.out.println("===========");

int n1 = (int) 12.3; //12
int n2 = (int) -12.3; // -12
int n3 = (int) (12.7 + 0.5); // 13

//四舍五入
double d5 = 2.6;
int n4 = (int) (d5 + 0.5);
System.out.println(n4);
```

# 布尔运算

```java
boolean isGreater = 5 > 3; //true
int age = 12;
boolean isZero = age == 0; //false
boolean isNonZero = !isZero; //true
boolean flag = age > 6 && age < 18; //true
```

## 短路运算

如果一个布尔运算的表达式能提前确定结果，则后续的计算不再执行，直接返回结果。
因为 `false && x` 的 结果只能是`false`，所以与运算在确定第一个值是false的时候，不再继续计算，而是直接返回`false`。

```java
System.out.println("============");

boolean b = 5 < 3; //false
boolean result = b && (10 / 0 > 0); //false (10 / 0 > 0)没有运算    
System.out.println(result); //
```

如果没有短路运算，&&后面的表达式会由于除数为0而报错，但实际上该语句并未报错，原因在于与运算是短路运算符，提前计算出了结果`false`。

## 三元运算符

```java
int o = -100;
//TODO o >= 0 ? o : -o
//TODO 如果 o >= 0 为true 返回o
// TOOO 否则 返回-o
int b1 = o >= 0 ? o : -o;
System.out.println(b1);
```

注意到三元运算`b ? x : y`会首先计算b，如果b为true，则只计算x，否则，只计算y。此外，x和y的类型必须相同，因为返回值不是boolean，而是x和y之一。

# 字符类型

字符类型char是基本数据类型，它是`character`的缩写。一个`char`保存一个`Unicode`字符：

```java
char c1 = 'A'
char c2 = '中'
```

因为Java在内存中总是使用`Unicode`表示字符，所以，一个英文字符和一个中文字符都用一个`char`类型表示，它们都占用两个字节。要显示一个字符的Unicode编码，只需将char类型直接赋值给int类型即可：

```java
int n1 = 'A';
int n2 = '中';
System.out.println(n1);
System.out.println(n2);

char c3 = '\u0041';
char c4 = '\u4e2d';
System.out.println(c3);
System.out.println(c4);
```

# 字符串

和char类型不同，字符串类型String是引用类型，我们用双引号"..."表示字符串。一个字符串可以存储0个到任意个字符：

```java
System.out.println("===========字符串==========");
String s = ""; //空字符串
String s1 = "李老师 yyds";
```

因为字符串使用双引号"..."表示开始和结束，那如果字符串本身恰好包含一个"字符怎么表示？这个时候，我们需要借助转义字符\：

```java
String s2 = "李老师\" yyds"; //李老师" yyds
```

因为\是转义字符，所以，两个\\表示一个\字符：

```java
String s3 = "李老师\\ yyds"; //李老师\ yyds
```

常见的转义字符包括：

- \" 表示字符"
- \' 表示字符'
- \\ 表示字符\
- \n 表示换行符
- \r 表示回车符
- \t 表示Tab
- \u#### 表示一个Unicode编码的字符

# 字符串连接

```java
String s4 = "Hello";
String s5 = "Herb";
String name = s4 + " " + s5;
System.out.println(name);
```

如果用+连接字符串和其他数据类型，会将其他数据类型先自动转型为字符串，再连接：

```java
int age = 18;
String name1 = "age is " + age;
```

# 不可变性

```java
String myName = "herb";
System.out.println(myName); //herb
myName = "Li";
System.out.println(myName); //Li
```

![image.png](Java%E5%9F%BA%E7%A1%80/1693984747587-dc5303e2-1c14-4b70-ac71-8802901cd0e6.png)
紧接着，执行s = "Li";时，JVM虚拟机先创建字符串"Li"，然后，把字符串变量s指向它：
原来的字符串`herb`还在，只是我们无法通过变量s访问它而已。因此，字符串的不可变是指字符串内容不可变。至于变量，可以一会指向字符串"herb"，一会指向字符串"Li"。

```java
String s = "herb";
String t = s;
s = "Li";
System.out.println(t);// herb
```

# 空值

引用类型的变量可以指向一个空值null，它表示不存在，即该变量不指向任何对象。

```java
String p = null;//null
String p1 = p ;//null
String p3 = ""; //空字符串，不是null
```

注意要区分空值`null`和空字符串""，空字符串是一个有效的字符串对象，它不等于`null`。



# 方法的定义

- 方法是解决一类问题的步骤的有序结合
- 方法包含于类或对象中
- 方法在程序中被创建，在其他地方被引用

设计方法的原则：就是实现某个功能的语句块。设计方法的时候，最好保持**一个方法只完成1个功能，这样利于后期的扩展。**

定义一个方法包含以下语法：

- 方法包含一个方法头和一个方法体。
- 修饰符：修饰符，这是可选的，告诉编译器如何调用该方法，定义了该方法的询问类型
- 返回值类型：方法可能会返回值
- 方法名：是方法的实际名称、方法名和参数共同构成方法签名
- 参数类型：参数像是一个占位符，当方法被调用时，传递值给参数，这个值被称为实参或者变量，参数列表是指方法的参数类型、顺序和参数的个数，参数是可选的，方法可以不包含任何参数。

```java
public class _01方法 {
    public static void main(String[] args) {
        double add = add(1, 2);

        System.out.println(add);

        print();
    }


    public static double add(double a, double b) {
        return a + b;
    }

    public static void print() {
        System.out.println("想成功先发疯");
    }
}
```

# 基本案例

eg: 父类是动物， 子类是狗

```java
public class Animal {
    public void call() {
        System.out.println("动物叫声");
    }

    public void show() {
        System.out.println("显示");
    }
}
```

```java
public class Dog extends Animal{
    @Override
    public void call() {
        System.out.println("狗叫");
    }

}

```

```java
public class Test {
    public static void main(String[] args) {
        Dog dog = new Dog();
        dog.call();

        dog.show();
    }
}
```

重写以后，通过子类对象去调用子父类中同名同参数方法时，执行的是子类重写父类的方法。 即在程序执行时，子类的方法将覆盖父类的方法。
重写的意义在于：优化父类的功能。

# 重写要求

- 需要有继承关系，子类重写父类的方法！方法名必须相同
- 参数列表必须相同。
- 修饰符不能拥有更严格的控制权限
  - public>protected>default>private
- 返回值类型: 
  - **父类被重写的方法的返回值类型是void,则子类重写的方法的返回值类型只能是void; **
  - **父类被重写的方法的返回值类型是A类型，则子类重写的方法的返回值类型可以是A类或A类的子类; **
  - **父类被重写的方法的返回值类型如果是基本数据类型(比如:double)，则子类重写的方法的返回值类型必须是相同的基本数据类型(必须是:double)。**
- 重写方法只与非静态方法有关，与静态方法无关（静态方法不能被重写）
- 被**static（属于类，不属于实例），final（常量方法），private（私有）**修饰的方法不能重写

```java
public class A {
    
}
```

```java
public class B extends A{
    
}
```

```java
public class Animal {
    public A call() {
        System.out.println("动物叫声");
        A a = new A();
        return a;
    }

    public void show() {
        System.out.println("显示");
    }
}
```

```java
public class Dog extends Animal {

    //TODO 返回类型 必须是A类 或者 A类的子类
    @Override
    public B call() {
        System.out.println("狗叫");
        //业务逻辑
        B b = new B();
        return b;
    }
}
```

```java
public class Test {
    public static void main(String[] args) {
        Dog dog = new Dog();
        dog.call();
        dog.show();
    }
}

```

## 方法重载

在同一个类中，允许存在一个以上的同名方法，只要它们的参数个数或者参数类型不同即可。

“两同一不同”:  
同一个类、相同方法名 			 
参数列表不同：参数个数不同，参数类型不同

```java
public class Demo {
    public static void main(String[] args) {

    }

    public void getSum(int i, int j){
        System.out.println("1");
    }

    public void getSum(double i, double j){
        System.out.println("2");
    }

    public void getSum(double i, int j){
        System.out.println("3");
    }

    public void getSum(int i, double j){
        System.out.println("4");
    }
}
```

1.判断：与`void show(int a,char b,double c){}`构成重载的有：
a)`void show(int x,char y,double z){} `
b)`int show(int a,double c,char b){} `
c)` void show(int a,double c,char b){} `
d) `boolean show(int c,char b){} `
e) `void show(double c){}  `
f) `double show(int x,char y,double z){`
g) `void shows(){double c} `

# 概念

多个相同类型数据按照一定顺序排列的集合，使用一个名字命名。

- 数组名
- 下标（索引）
- 元素
- 数组长度

# 特点


- 数组本身是引用数据类型，但是数组中的元素可以是任何类型
- 创建数组对象会在内存中开辟一整块连续的空间。占用的空间大小取决于数组的长度和数组中的元素类型
- 数组一旦初始化完成，长度就是确定的，不能修改的
- 通过下标的方式调用指定位置的元素。速度很快（下标从0开始）
- 数组所有元素初始化为默认值，整型都是0，浮点型是0.0，布尔型是`false`；
- 数组的下标范围，【0，数组长度-1】

# 数组的分类

## 按照元素类型分类


- 基本数据类型元素的数组：存的是基本数据类型的值
- 引用数据类型元素的数组：存储对象

## 按照维度分类

一维数组
二维数组

# 数组的基本使用

## 数组的声明

格式

```java
元素的数据类型[] 数组名称

元素的数据类型 数组名称[]
```

创建的什么类型的数组，就只能存放什么类型的元素

eg

```java
int[] scores;
char[] letters;
double[] prices;
```

## 初始化

```java
public static void main(String[] args) {

    //TODO 方式一：
    //创建一个长度为 5 的  int类型的数组
    int[] scores = new int[5];
    scores[0] = 18;
    scores[1] = 28;
    scores[2] = 38;
    scores[3] = 48;
    scores[4] = 58;

    //修改元素
    scores[4] = 99;
    System.out.println(scores[4]);

    //数组的长度
    System.out.println(scores.length);

    //TODO 方式二：
    int[] arr = new int[] {18,28,38,48,58};
    int[] arr02 = {18,28,38,48,58};

    //TODO 先声明，再初始化要用 new
    int arr03[];
    arr03 = new int[]{18,28,38,48,58};
}
```

# 数组长度不可变

观察下面的代码

```java
int[] arr;
arr = new int[] {18, 28, 28, 48, 58};
System.out.println(arr.length);//5
arr = new int[] {18, 28, 28};
System.out.println(arr.length); //3
```

数组长度变了吗？看上去好像是变了，但其实根本没变。
对于数组arr来说，执行`arr = new int[] { 18, 28, 28, 48, 58 };`时，它指向一个5个元素的数组：
![image.png](Java%E5%9F%BA%E7%A1%80/1693986887744-78f24a19-d1fb-4bff-abdf-0427d8e6524f.png)
执行`arr = new int[] {18, 28, 28};`指向3个元素的数组：
![image.png](../%25E8%25AF%25BE%25E4%25BB%25B6/images/2023/1693986950363-2665cbb0-74fe-4cf5-807a-c551359889a0.png)
但是，原有的5个元素的数组并没有改变，只是无法通过变量arr引用到它们而已。

# 字符串数组在内存中的存储

```java
String[] names = {
                "inmind",
                "aaa",
                "bbb"
        };
```

字符串数组和基本数据类型数组在内存中是不一样的，基本数据类型的数组存放的是它的值，但是字符串本身就是引用数据类型，所以字符串数组 在内存中 存放的实际上是字符串对应的的地址。

![image.png](Java%E5%9F%BA%E7%A1%80/1695731657693-d0de50a9-7bac-4ba0-b668-2f99cdafd902.png)

# 数组的遍历

```java
public static void main(String[] args) {
    int[] arr = new int[] {1,2,3,4,5};
    System.out.println("数组长度：" + arr.length);

    System.out.println("===for循环====");
    for (int i = 0; i < arr.length; i++) {
        //通过下标取值
        System.out.println(arr[i]);
    }

    System.out.println("===while循环====");
    int i = 0;
    while (i < arr.length) {
        //通过下标取值
        System.out.println(arr[i]);
        i++;
    }
}
```

for each（增强for循环）循环格式

```java
for (类型 接收的值 : 要遍历的数组) {
    
}
```

```java
System.out.println("===for each循环====");
for (int num : arr) {
    System.out.println(num);
}
```

# 数组的四个基本特点

- 其长度是确定的。数组一旦被创建，它的大小就是不可改变的
- 其元素必须是相同类型，不允许出现混合类型
- 数组中的元素可以是任何数据类型，包括基本类型和引用类型
- 数组变量引用类型，数组也可以看成是对象，数组中的每个元素相当于该对象的成员变量。数组本身就是对象，Java中对象是在堆中的，因此数组无论原始类型还是其他对象类型，数组对象本身是在堆中。
- **ArrayIndexOutOfBoundsException：数组下标越界异常**

**动态演示：**[**https://visualgo.net/zh/sorting**](https://visualgo.net/zh/sorting)

# 选择排序

![image.png](Java%E5%9F%BA%E7%A1%80/1694053521525-3f9101b8-9555-46b2-8052-83bedc8efa9d.png)

1. 从0  ~  n-1位置 找到最小的数放到第0位
2. 从 1~ n- 1位置 找最小的数放到第1位
3. 从 2~ n- 1位置 找最小的数放到第2位
4. 。。。

重复（元素个数-1）次

1. 把第一个没有排序过的元素设置为最小值
2. 遍历每个没有排序过的元素
   1. 如果元素 < 现在的最小值小 ，就将此元素设置成为新的最小值

将最小值和第一个没有排序过的位置交换

```java
public class SelectSort {
    public static void main(String[] args) {
        int[] arr = {1, 6, 2, 3, 8, 9, 5, 4, 7};
        selectSort(arr);
        for (int cur : arr) {
            System.out.println(cur);
        }
    }

    public static void selectSort(int[] arr) {

        for (int i = 0; i < arr.length; i++) {//i =0
            int min = i;
            for (int j = i + 1; j < arr.length; j++) { //j =1
                min = arr[j] < arr[min] ? j : min;
            }
            swap(arr, i, min);
        }
    }

    public static void swap(int[] arr, int i, int j) {
        int temp = arr[i];
        arr[i] = arr[j];
        arr[j] = temp;
    }
}
```

# 冒泡排序


1. 比较相邻的元素，如果第一个必第二个大，就交换
2. 对每一对相邻元素做同样的工作。

两个数比较，谁大谁往右移动

```java
public static void main(String[] args) {
        int[] arr = {3, 2, 5, 4, 3, 6};

        for (int i = 1; i < arr.length; i++) {
            for (int j = 0; j < arr.length - i; j++) {
                if (arr[j] > arr[j + 1]) {
                    int temp = arr[j];
                    arr[j] = arr[j + 1];
                    arr[j + 1] = temp;
                }
            }
        }

        for (int num : arr) {
            System.out.println(num);
        }
    }
```

数组的反转

```java
public static void main(String[] args) {
    int[] arr = {18, 28, 38, 48, 58,68};

    for (int i = 0; i < arr.length/2; i++) {
        int temp = arr[i];
        arr[i] = arr[arr.length - 1 - i];
        arr[arr.length - 1 - i] = temp;
    }
    System.out.println("反转后的值");
    for (int num : arr) {
        System.out.println(num);
    }
}
```

查找value值第一次出现在数组中的下标值（index）

方式一：顺序查找

```java
public static void main(String[] args) {
        //TODO 查找value值第一次出现在数组中的下标值（index）
        int[] arr = {4, 5, 6, 7, 1, 9, 1};
        int value = 1;
        int index = -1;

        for (int i = 0; i < arr.length; i++) {
            if (arr[i] == value) {
                index = i;
                break;
            }
        }

        if (index == -1) {
            System.out.println("不存在");
        }else {
            System.out.println("下标为：" + index);
        }
    }
```

方式二： 二分查找法（数组必须有序）
![image.png](Java%E5%9F%BA%E7%A1%80/1696837463680-ae6c4d5e-aec4-47de-ba23-c4fb68122460.png)

```java
public static void main(String[] args) {
    int[] arr = {-99, -54, -2, 0, 2, 33, 46, 255, 999};
    int value = 33;

    int left = 0;
    int right = arr.length - 1;

    while (left <= right) {
        int mid = (left + right) / 2;
        if (arr[mid] == value) {
            System.out.println("找到了，索引为：" + mid);
            break;
        }else if (arr[mid] > value){
            right = mid - 1;
        }else {
            left = mid + 1;
        }
    }
}
```

定义一个数组，调用`add(int[] arr, int index, int num)`，将obj插入到数组的index的下标处。

```java
public class Demo {
    public static void main(String[] args) {
        int[] arr = {1, 2, 3, 4, 5};

        arr = add(arr, 2, 6);

        for (int num : arr) {
            System.out.println(num);
        }
    }


    public static int[] add(int[] arr, int index, int num) {
        int[] newArry = new int[arr.length + 1];

        for (int i = 0; i < index; i++) {
            newArry[i] = arr[i];
        }

        newArry[index] = num;

        for (int i = index; i < arr.length; i++) {
            newArry[i + 1] = arr[i];
        }

        return newArry;
    }
}
```



2. 定义一个数组，调用`remove(int[] arr, int index)`，将指定下标的元素删除

定义一个数组，调用`add(int[] arr, int index, int num)`，将obj插入到数组的index的下标处。

```java
public class Demo {
    public static void main(String[] args) {
        int[] arr = {1, 2, 3, 4, 5};

        arr = add(arr, 2, 6);

        for (int num : arr) {
            System.out.println(num);
        }
    }


    public static int[] add(int[] arr, int index, int num) {
        int[] newArry = new int[arr.length + 1];

        for (int i = 0; i < index; i++) {
            newArry[i] = arr[i];
        }

        newArry[index] = num;

        for (int i = index; i < arr.length; i++) {
            newArry[i + 1] = arr[i];
        }

        return newArry;
    }
}
```



2. 定义一个数组，调用`remove(int[] arr, int index)`，将指定下标的元素删除



# 面向对象和面向过程的区别

**面向过程**： 

是分析解决问题的步骤，然后用函数把这些步骤一步一步的实现，然后在使用的使用一一调用， 性能比较高。

**面向对象**：

把构成问题的事务进行分解成一个个对象，而建立对象的目的不是为了完成一个个步骤，而是为了描述某个事物在解决整个问题的过程中所发生的行为。面向对象有封装、继承、多态的特性，所以易维护、易复用、易扩展。可以设计出低耦合的系统。 但是性能上来说，比面向过程要低。(模块化设计)

- 类  = 属性 + 方法
- 面向对象本质就是：以类的方式组织代码，以对象的组织（封装）数据。
- 三大特性：封装，继承，多态。 

# 类和对象

![image.png](Java%E5%9F%BA%E7%A1%80/1694066444199-bd0f23c7-f36b-4bb1-b26d-082365a16bbb.png)
类：某一类事物整体描述/定义，但是并不能代表某一个具体的事物
对象：万事万物皆对象。每个对象都是类模板下的具体的产品。

步骤：

1. 定义类
2. 对象创建（使用 `new`）
   1. 方式一：`类名 对象名 = new 类名（）`
   2. 方式二：`new 类名（）` （匿名对象）

```java
public class Person {
    //TODO 属性 ==》 成员变量
    // 名字
    String name;
    //年龄
    int age;
    //身高
    double height;
    //体重
    double weight;
    //性别
    char sex;

    //TODO 方法
    public void eat() {
        System.out.println("吃");
    }

    //喝
    public void drink(String drink) {
        System.out.println("喝 " + drink);
    }

    //玩
    public void play() {
        System.out.println("看视频");
    }
}
```

```java
public class TestPerson {
    public static void main(String[] args) {

        Person person = new Person();

        //对属性进行操作
        person.name = "强哥";
        person.age = 25;
        person.height = 180;
        person.weight = 100;
        person.sex = '男';

        System.out.println(person.name);
        System.out.println(person.sex);
        System.out.println(person.age);

        //对方法进行操作
        person.play();
        person.drink("小麦果汁");
    }
}

```

# 为什么要有继承?

继承性的主要特点在于：可以扩充已有类的功能。
比如：
学生的属性：名字、学号、性别、年龄、专业、身高、体重、成绩
人的属性： 名字、性别、年龄、身高、体重、学历
学生应该包含有人的所有特点。
如果想要进行代码的重用，必须要要使用继承的概念，
继承的本质：在已有类的功能上继续进行功能扩充。

**子类和父类的关系：**

- `extends`的意思是“扩展”。子类是父类的扩展，使用`extends`来表示
- **Java中只有单继承，**没有多继承！一个类只能继承一个父类
- 子类继承了父类，就会拥有父类的全部方法，ps：`private`私有属性及方法无法继承
- 在Java中，所有类，都默认直接或间接继承Object类（Ctrl+H可以查看类关系）
- **被**`**final**`**修饰的类**，无法继承（断子绝孙）

**继承的优点：**

1. **提高代码的复用性**
2. **减少代码的冗余**

```java
public class Person {
    private String name;
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

```java
public class Student extends Person{ // Student 是一个子类
     private int grade;
    public int getGrade() {
        return grade;
    }

    public void setGrade(int grade) {
        this.grade = grade;
    }
}
```

```java
public class Test {
    public static void main(String[] args) {
        Student student = new Student();
        student.setName("周");
        student.setAge(50);
        student.setGrade(88);
        System.out.println(student.getAge());
        System.out.println(student.getName());
        System.out.println(student.getGrade());
    }
}
```

# super和this

`super`注意点：

1. `super`调用父类的构造方法，必须在构造方法的第一行（默认调用）
2. `super`必须只能出现在子类的方法或者构造方法中
3. `super`和`this`不能同时调用构造方法

- 代表的对象不同：
  - `this`：本身调用者这个对象
  - `super`：代表父类对象的应用
- 前提
  - `this`：没有继承也可以使用
  - `super`：只能在继承条件下可以使用
- 构造方法
  - `this()`：本类的构造
  - `super()`：父类的构造
- `**super**`**与**`**this**`**的区别**：`super`代表**父类对象的引用，只能在继承条件下使用；**`this`调用自身对象，没有继承也可以使用

```java
public class Person {
    private String name;
    private int age;

    public Person() {
        System.out.println("父类的无参");
    }

    public Person(String name, int age) {
        System.out.println("父类的有参");
        this.name = name;
        this.age = age;
    }

    public void eat() {
        System.out.println("民以食为天");
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

```java
public class Student extends Person{
    private int grade;

    public Student() {
        super();
        System.out.println("子类的无参");
    }

    public Student(String name, int age, int grade) {
        super(name, age);
        this.grade = grade;
    }

    public int getGrade() {
        return grade;
    }

    public void setGrade(int grade) {
        this.grade = grade;
    }

    public void eat() {
        System.out.println("学生吃饭");
    }

    public void study() {
        System.out.println("学习");
        //TODO 调用 当前类的 eat() 方法
        this.eat();

        //TODO 调用 父类的 eat() 方法
        super.eat();
    }
}
```

```java
public class Test {
    public static void main(String[] args) {
        Student student = new Student();
        student.setAge(25);
        student.setName("herb");
        student.setGrade(88);
        System.out.println(student.getAge());
        System.out.println(student.getName());
        System.out.println(student.getGrade());

        student.eat();
        System.out.println("==============");

        Student student1 = new Student("herb", 22, 100);
        student1.study();
    }
}
```

# 概念

多态是同一个行为具有多个不同表现形式或形态的能力。


1. 什么是多态性：父类的引用指向子类的对象(或子类的对象赋值给父类的引用)

- 一个对象的实际类型是确定的，但可以指向对象的引用可以有很多。
- 多态是方法的多态，没有属性的多态
- 多态存在条件
  - 有继承关系
  - 子类重写父类的方法
  - 父类引用指向子类对象

2. 多态的使用：虚拟方法调用 

有了对象多态性以后，我们在编译期，只能调用父类声明的方法，但在执行期实际执行的是子类重写父类的方法 
简称：编译时，看左边；运行时，看右边。 
若编译时类型和运行时类型不一致，就出现了对象的多态性(Polymorphism)
多态情况下：

      1. 看左边”：看的是父类的引用（父类中不具备子类特有的方法）
      2. “看右边”：看的是子类的对象（实际运行的是子类重写父类的方法）

   3. 作用：

提高了代码的扩展性，增加代码对其它类的影响降到最低。

4. 优点：

- 1. 消除类型之间的耦合关系
- 2. 可替换性
- 3. 可扩充性
- 4. 接口性
- 5. 灵活性
- 6. 简化性

# 基本使用

```java
public class Person {
    String name;
    int age;

    public Person() {
    }

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }


    public void play() {
        System.out.println("玩游戏");
    }

    public void eat() {
        System.out.println("民以食为天");
    }
}
```

```java
public class Student extends Person{
    double grade;

    public Student() {
    }

    public Student(String name, int age, double grade) {
        super(name, age);
        this.grade = grade;
    }

    public double getGrade() {
        return grade;
    }

    public void setGrade(double grade) {
        this.grade = grade;
    }

    public void love() {
        System.out.println("我要贪恋爱");
    }

    @Override
    public void play() {
        System.out.println("玩元神");
    }

    @Override
    public void eat() {
        System.out.println("一万隆江猪脚饭，吃出男人的浪漫");
    }
}

```

```java
public class Girl extends Person{
    int weight;

    public Girl() {
    }

    public Girl(String name, int age, int weight) {
        super(name, age);
        this.weight = weight;
    }

    public int getWeight() {
        return weight;
    }

    public void setWeight(int weight) {
        this.weight = weight;
    }

    public void goShopping() {
        System.out.println("购物");
    }

    @Override
    public void eat() {
        System.out.println("仙女不需要吃饭");
    }

}
```

```java
public class Test {
    public static void main(String[] args) {

        System.out.println("=======多态==========");

        //TODO 对象的多要性：父类的引用指向子类的对象
        Person person = new Student();

        //TODO 调用父类同名的方法时，实际上调用的是子类重写父类的方法
        person.eat();
        person.play();
        //TODO 此时无法调用子类中自己的方法 ==》 在编译期，只能调用父类声明的方法，
        // 执行期实际执行的是子类重写父类的方法
        //person.love();
    }
}
```

# 为什么需要多态

```java
public class Animal {
    public void call() {
        System.out.println("动物的叫声");
    }

    public void eat() {
        System.out.println("吃");
    }
}
```

```java
public class Cat extends Animal{
    @Override
    public void call() {
        System.out.println("猫叫");
    }

    @Override
    public void eat() {
        System.out.println("吃鱼");
    }
}

```

```java
public class Dog extends Animal{
    @Override
    public void call() {
        System.out.println("狗叫");
    }

    @Override
    public void eat() {
        System.out.println("啃骨头");
    }

}

```

```java
public class Test {
    public static void main(String[] args) {

        Test test = new Test();
        test.func(new Dog());
        test.func(new Cat());

    }


    public void func(Animal animal) { //Animal animal = new Dog()
        animal.call();
        animal.eat();
    }


    //TODO 没有多态性，就会写很多这种方法体一样的方法，一一取调用
    /*public void func(Dog dog) {
        dog.call();
        dog.eat();
    }

    public void func(Cat cat) {
        cat.call();
        cat.eat();
    }*/
}

```

# instanceof**引用类型比较，判断一个对象是什么类型**

instanceof关键字的作用是判断左边对象是否是右边类的实例返回的boolean类型，true和false。

![image.png](../%25E8%25AF%25BE%25E4%25BB%25B6/images/2023/1694401458594-53f37742-14ea-4558-a175-55844b6611d3.png)
![image.png](Java%E5%9F%BA%E7%A1%80/1694401471700-fb671676-2ea0-4dfd-8d88-81f0c61d1138.png)

# 类型转换

   - 父类引用指向子类的对象
   - 把子类转换为父类，向上转型，会丢失自己原来的一些方法
   - 把父类转换为子类，向下转型，强制转换，才调用子类方法
   - 方便方法的调用（转型），减少重复的代码，简洁

## 向下转型

```java
public class Person {
    String name;
    int age;

    public Person() {
    }

    public Person(String name, int age) {
        this.name = name;
        this.age = age;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }


    public void play() {
        System.out.println("玩游戏");
    }

    public void eat() {
        System.out.println("民以食为天");
    }
}
```

```java
public class Student extends Person {
    double grade;

    public Student() {
    }

    public Student(String name, int age, double grade) {
        super(name, age);
        this.grade = grade;
    }

    public double getGrade() {
        return grade;
    }

    public void setGrade(double grade) {
        this.grade = grade;
    }

    public void love() {
        System.out.println("我要贪恋爱");
    }

    @Override
    public void play() {
        System.out.println("玩元神");
    }

    @Override
    public void eat() {
        System.out.println("一万隆江猪脚饭，吃出男人的浪漫");
    }
}
```

```java
public class Girl extends Person {
    int weight;

    public Girl() {
    }

    public Girl(String name, int age, int weight) {
        super(name, age);
        this.weight = weight;
    }

    public int getWeight() {
        return weight;
    }

    public void setWeight(int weight) {
        this.weight = weight;
    }

    public void goShopping() {
        System.out.println("购物");
    }

    @Override
    public void eat() {
        System.out.println("仙女不需要吃饭");
    }

}
```

```java
public class Test {
    public static void main(String[] args) {
        Person person = new Student();

        //TODO 调用父类同名的方法时，实际上调用的是子类重写父类的方法
        person.eat();
        person.play();
        person.name = "周周";

        //TODO 不能调用子类所特有的方法、属性，编译时，person 是Person类型，
        // TODO 有了多态以后，内存中实际上是加载的子类特有的属性和方法，
        //  但是由于变量声明为父类，导致编译的时候，只能调用父类中的属性和方法
        //person.grade = 100;
        //person.love();
        
    }
}
```

发现不能调用子类所特有的方法、属性，编译时，person 是Person类型，这是因为
 有了多态以后，内存中实际上是加载的子类特有的属性和方法，
 但是由于变量声明为父类，导致编译的时候，只能调用父类中的属性和方法

**如何才能调用子类所特有的属性和方法？**
使用强制类型转换符，也可称为:向下转型

```java
Student student = (Student) person;
student.grade = 100;
student.love();
```

# 为什么要有继承?

继承性的主要特点在于：可以扩充已有类的功能。
比如：
学生的属性：名字、学号、性别、年龄、专业、身高、体重、成绩
人的属性： 名字、性别、年龄、身高、体重、学历
学生应该包含有人的所有特点。
如果想要进行代码的重用，必须要要使用继承的概念，
继承的本质：在已有类的功能上继续进行功能扩充。

**子类和父类的关系：**

- `extends`的意思是“扩展”。子类是父类的扩展，使用`extends`来表示
- **Java中只有单继承，**没有多继承！一个类只能继承一个父类
- 子类继承了父类，就会拥有父类的全部方法，ps：`private`私有属性及方法无法继承
- 在Java中，所有类，都默认直接或间接继承Object类（Ctrl+H可以查看类关系）
- **被**`**final**`**修饰的类**，无法继承（断子绝孙）

**继承的优点：**

1. **提高代码的复用性**
2. **减少代码的冗余**

```java
public class Person {
    private String name;
    private int age;

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

```java
public class Student extends Person{ // Student 是一个子类
     private int grade;
    public int getGrade() {
        return grade;
    }

    public void setGrade(int grade) {
        this.grade = grade;
    }
}
```

```java
public class Test {
    public static void main(String[] args) {
        Student student = new Student();
        student.setName("周");
        student.setAge(50);
        student.setGrade(88);
        System.out.println(student.getAge());
        System.out.println(student.getName());
        System.out.println(student.getGrade());
    }
}
```

# super和this

`super`注意点：

1. `super`调用父类的构造方法，必须在构造方法的第一行（默认调用）
2. `super`必须只能出现在子类的方法或者构造方法中
3. `super`和`this`不能同时调用构造方法

- 代表的对象不同：
  - `this`：本身调用者这个对象
  - `super`：代表父类对象的应用
- 前提
  - `this`：没有继承也可以使用
  - `super`：只能在继承条件下可以使用
- 构造方法
  - `this()`：本类的构造
  - `super()`：父类的构造
- `**super**`**与**`**this**`**的区别**：`super`代表**父类对象的引用，只能在继承条件下使用；**`this`调用自身对象，没有继承也可以使用

```java
public class Person {
    private String name;
    private int age;

    public Person() {
        System.out.println("父类的无参");
    }

    public Person(String name, int age) {
        System.out.println("父类的有参");
        this.name = name;
        this.age = age;
    }

    public void eat() {
        System.out.println("民以食为天");
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public int getAge() {
        return age;
    }

    public void setAge(int age) {
        this.age = age;
    }
}
```

```java
public class Student extends Person{
    private int grade;

    public Student() {
        super();
        System.out.println("子类的无参");
    }

    public Student(String name, int age, int grade) {
        super(name, age);
        this.grade = grade;
    }

    public int getGrade() {
        return grade;
    }

    public void setGrade(int grade) {
        this.grade = grade;
    }

    public void eat() {
        System.out.println("学生吃饭");
    }

    public void study() {
        System.out.println("学习");
        //TODO 调用 当前类的 eat() 方法
        this.eat();

        //TODO 调用 父类的 eat() 方法
        super.eat();
    }
}
```

```java
public class Test {
    public static void main(String[] args) {
        Student student = new Student();
        student.setAge(25);
        student.setName("herb");
        student.setGrade(88);
        System.out.println(student.getAge());
        System.out.println(student.getName());
        System.out.println(student.getGrade());

        student.eat();
        System.out.println("==============");

        Student student1 = new Student("herb", 22, 100);
        student1.study();
    }
}
```

