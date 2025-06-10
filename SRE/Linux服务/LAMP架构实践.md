# LAMP架构概述

## 什么是LAMP

LAMP就是由Linux+Apache+MySQL+PHP组合起来的架构

并且Apache默认情况下就内置了PHP解析模块，所以无需CGI即可解析PHP代码



**请求示意图：**

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719225827428.png" alt="image-20240719225827428" style="zoom:80%;" />

# LAMP架构部署

## 安装Apache

```bash
yum install -y httpd

# 启动httpd
systemctl start httpd

# 关闭防火墙和SElinux
systemctl stop filewalld
setenforce 0
```

**访问测试：**`http://IP`

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719230216883.png" alt="image-20240719230216883" style="zoom: 80%;" />

## 安装php环境

1. 由于php源在国外，下载较慢，所以可以使用英格提供的php源

```bash
# 添加英格php的yum源
vim /etc/yum.repos.d/eagle.repo
[eagle]
name=Eagle's lab
baseurl=http://file.eagleslab.com:8889/%E8%AF%BE%E7%A8%8B%E7%9B%B8%E5%85%B3%E8%BD%AF%E4%BB%B6/%E4%BA%91%E8%AE%A1%E7%AE%97%E8%AF%BE%E7%A8%8B/Centos7%E6%BA%90/
gpgcheck=0
enabled=1
```

2. **安装php71w全家桶**

```bash
yum -y install php71w php71w-cli php71w-common php71w-devel php71w-embedded php71w-gd php71w-mcrypt php71w-mbstring php71w-pdo php71w-xml php71w-fpm php71w-mysqlnd php71w-opcache php71w-pecl-memcached php71w-pecl-redis php71w-pecl-mongodb
```

3. 重启httpd.service

```bash
systemctl restart httpd.service
```

## 安装Mysql数据库

```bash
# 安装mariadb数据库软件
yum install mariadb-server mariadb -y

# 启动数据库并且设置开机自启动
systemctl start mariadb
systemctl enable mariadb

# 设置mariadb的密码
mysqladmin password '123456'

# 验证数据库是否工作正常
mysql -uroot -p123456 -e "show databases;"
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| test               |
+--------------------+
```

## PHP探针测试

在默认的网站根目录下创建`info.php`

```bash
vim /var/www/html/info.php
<?php
	phpinfo();
?>
```

写一个简单的php代码，可以使用phpinfo函数查看php的信息，从而检测是否成功解析php代码

编写好以后，我们访问：`http://IP/info.php`测试

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719231005306.png" alt="image-20240719231005306" style="zoom:80%;" />

这里如果可以看到上述页面，说明我们的php代码成功被解析了

## 数据库连接测试

编写php代码，用php来连接数据库测试

```bash
vim /var/www/html/mysql.php
<?php
    $servername = "localhost";
    $username = "root";
    $password = "123456";

    // 创建连接
    $conn = mysqli_connect($servername, $username, $password);

    // 检测连接
    if (!$conn) {
         die("Connection failed: " . mysqli_connect_error());
    }
    echo "连接MySQL...成功！";
?>
```

编写好以后，我们访问：`http://IP/mysql.php`测试:

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719231237537.png" alt="image-20240719231237537" style="zoom:80%;" />

## 安装phpmyadmin

由于我们还没有学习mysql如何管理，我们可以部署phpmyadmin工具，该工具可以让我们可视化管理我们的数据库

```bash
# 移动到网站根目录
cd /var/www/html

# 下载phpmyadmin源码
wget https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.zip

# 解压软件包，并且重命名
unzip phpMyAdmin-5.1.1-all-languages.zip
mv phpMyAdmin-5.1.1-all-languages phpmyadmin
```

访问`http://IP/phpmyadmin`进行测试

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719231636758.png" alt="image-20240719231636758" style="zoom:80%;" />

用户名和密码为我们刚才初始化数据库时设置的root和123456，登陆后，会进入图形化管理界面

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719231744450.png" alt="image-20240719231744450" style="zoom:80%;" />

# 部署typecho个人博客

## 源码获取

下载typecho博客系统源码到`/var/www/html/typecho`

```bash
cd /var/www/html

# 创建typecho目录
mkdir typecho
cd typecho

wget http://file.eagleslab.com:8889/%E8%AF%BE%E7%A8%8B%E7%9B%B8%E5%85%B3%E8%BD%AF%E4%BB%B6/%E4%BA%91%E8%AE%A1%E7%AE%97%E8%AF%BE%E7%A8%8B/%E8%AF%BE%E7%A8%8B%E7%9B%B8%E5%85%B3%E6%96%87%E4%BB%B6/typecho.zip

# 解压源码
unzip typecho.zip
```

## 创建数据库

点击数据库

<img src="LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20240719232259490.png" alt="image-20240719232259490" style="zoom:80%;" />

输入数据库名之后，就可以点击创建

![image-20211106110832539](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106110832539.png)

## 安装博客系统

下面就可以开始进入网站安装的部分了，访问博客系统页面

![image-20211106110937420](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106110937420.png)

填写数据库密码和网站后台管理员密码

![image-20211106111051847](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106111051847.png)

点击开始安装之后，会出现了如下页面

![image-20211106111537070](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106111537070.png)

我们手动在typecho目录中创建这个文件，并且把内容复制进去

```bash
vim config.inc.php
```

配置文件创建完成之后，可以点击`创建完毕，继续安装>>`

下面是安装成功的页面

![image-20211106111631222](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106111631222.png)

## 切换主题

默认的主题如下，界面比较的简洁，我们可以给这个网站替换主题，也可以借此加深熟悉我们对Linux命令行的熟练程度

![image-20211106112000231](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112000231.png)

打开官方主题站：https://typecho.me/

第三方主题商店：https://www.typechx.com/

这边以这个主题为例

![image-20211106112120529](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112120529.png)

点击模板下载

![image-20211106112150188](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112150188.png)

点击下载压缩包

![image-20211106112228058](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112228058.png)

将主题上传到博客主题的目录`/var/www/html/typecho/usr/themes`

![image-20211106112349552](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112349552.png)

```bash
# 解压压缩包，并且将主题文件夹重命名
unzip typecho-theme-sagiri-master.zip
mv typecho-theme-sagiri-master sagiri

# 可以删除旧的压缩包文件
rm -rf typecho-theme-sagiri-master.zip
```

进入网站后台切换主题，在地址后面加上`/admin`就可以进入后台登录页面了

![image-20211106112629934](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106112629934.png)

启用我们刚刚安装的主题

![image-20211106113531819](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106113531819.png)

访问网页前端，查看最终的效果

![image-20211106113600091](LAMP%E6%9E%B6%E6%9E%84%E5%AE%9E%E8%B7%B5/image-20211106113600091.png)