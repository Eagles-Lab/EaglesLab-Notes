# 常用的网站服务软件

[https://w3techs.com/technologies/overview/web_server](https://w3techs.com/technologies/overview/web_server)

![img-web_server_top](Apache/web_server_top.png)

**Apache是什么**

Apache HTTP Server简称为 Apache，是 Apache 软件基金会的一个高性能、功能强大、见状可靠、又灵活的开放源代码的web服务软件，它可以运行在广泛的计算机平台上如 Linux、Windows。因其平台型和很好的安全性而被广泛使用，是互联网最流行的 web 服务软件之一。

**特点**

- 功能强大
- 高度模块化
- 采用MPM多路处理模块
- 配置简单
- 速度快
- 应用广泛
- 性能稳定可靠
- 可做代理服务器或负载均衡来使用
- 双向认证
- 支持第三方模块

**应用场景**

- 使用Apache运行静态HTML网页、图片
- 使用Apache结合PHP、Linux、MySQL可以组成LAMP经典架构
- 使用Apache作代理、负载均衡等

**MPM工作模式**

- prefork：多进程I/O模型，一个主进程，管理多个子进程，一个子进程处理一个请求。
- worker：复用的多进程I/O模型，多进程多线程，一个主进程，管理多个子进程，一个子进程管理多个线程，每个线程处理一个请求。
- event：事件驱动模型，一个主进程，管理多个子进程，一个进程处理多个请求。

# Apache 基础

RockyLinux 软件仓库中存在此软件包，可以直接通过 yum 进行安装

```shell
[root@localhost ~]# yum -y install httpd
[root@localhost ~]# systemctl start httpd && systemctl enable httpd
[root@localhost ~]# httpd -v
Server version: Apache/2.4.62 (Rocky Linux)
Server built:   Jan 29 2025 00:00:00

# 使用 curl 或者浏览器测试网页是否正常
[root@localhost ~]# echo "Hello World!" > /var/www/html/index.html
[root@localhost ~]# curl -I 127.0.0.1
HTTP/1.1 200 OK
```

## httpd 命令

httpd 为Apache HTTP服务器程序。

```shell
[root@localhost ~]# httpd -h
Usage: httpd [-D name] [-d Directory] [-f file]
             [-C "directive"] [-c "directive"]
             [-k start|restart|graceful|graceful-stop|stop]
             [-v] [-V] [-h] [-l] [-L] [-t] [-T] [-S] [-X]
```

**常用选项**

| 选项 | 说明 |
| :--- | :--- |
| -c <httpd指令> | 在读取配置文件前，先执行选项中的指令 |
| -C <httpd指令> | 在读取配置文件后，再执行选项中的指令 |
| -d <服务器根目录> | 指定服务器的根目录 |
| -D <设定文件参数> | 指定要传入配置文件的参数 |
| -f <配置文件>| 指定配置文件 |
| -h | 显示帮助 |
| -l | 显示服务器编译时所包含的模块 |
| -L | 显示httpd指令的说明 |
| -S | 显示配置文件中的设定 |
| -t | 测试配置文件的语法是否正确 |
| -v | 显示版本信息 |
| -V | 显示办吧信息和运行环境 |
| -X | 以单一程序的方式来启动服务器 |

## 相关文件

| 文件 | 说明 |
| :--- | :--- |
| /etc/httpd/conf/httpd.conf | Apache主配置文件 |
| /etc/httpd/conf.d/ | 存放虚拟主机配置文件 |
| /etc/httpd/conf.modules.d/ | 存放模块配置文件 |
| /etc/httpd/modules/ | 存放模块文件 |
| /var/log/httpd/ | 存放日志文件 |
| /var/www/html/ | 存放默认的网页文件 |

## 主配置文件

**主配置文件说明**

```shell
[root@localhost ~]# grep -Ev '^$|^#|\s*#' /etc/httpd/conf/httpd.conf
ServerRoot "/etc/httpd"
Listen 80
Include conf.modules.d/*.conf
User apache
Group apache
ServerAdmin root@localhost
<Directory />
    AllowOverride none
    Require all denied
</Directory>
Documentroot "/var/www/html"
<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>
<Directory "/var/www/html">
    Options Indexes FollowSymLinks
    AllowOverride None
    Require all granted
</Directory>
<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>
<Files ".ht*">
    Require all denied
</Files>
ErrorLog "logs/error_log"
LogLevel warn
<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common
    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>
    CustomLog "logs/access_log" combined
</IfModule>
<IfModule alias_module>
    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"
</IfModule>
<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>
<IfModule mime_module>
    TypesConfig /etc/mime.types
    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz
    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>
AddDefaultCharset UTF-8
<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>
EnableSendfile on
IncludeOptional conf.d/*.conf
```

**主配置项**

| 主配置项 | 说明|
| :--- | :--- |
| ServerRoot | 配置文件所在目录|
| Listen | 监听端口|
| ServerName | 服务器主机名|
| Include | 包含其他配置文件|
| User | 运行用户|
| Group | 运行用户组|
| ServerAdmin | 管理员邮箱|
| Documentroot | 默认网站根目录|
| Directory | 虚拟主机配置|
| IfModule | 模块配置 |
| ErrorLog | 错误日志|
| LogLevel | 日志级别|
| CustomLog | 自定义日志|
| StartServers | 初始子进程数|
| EnableSendfile | 开启sendfile|
| AddDefaultCharset | 默认字符集|

## 虚拟主机配置文件

```shell
[root@localhost ~]# ls -l /etc/httpd/conf.d/
total 16
-rw-r--r--. 1 root root  400 Apr 29 03:43 README
-rw-r--r--. 1 root root 2916 Apr 29 03:43 autoindex.conf
-rw-r--r--. 1 root root 1252 Apr 29 03:41 userdir.conf
-rw-r--r--. 1 root root  653 Apr 29 03:41 welcome.conf

```

## 模块配置文件

- httpd 有静态功能模块和动态功能模块组成，分别使用 httpd -l 和 httpd -M 查看
- Dynamic Shared Object 加载动态模块配置，不需重启即生效
- 动态模块所在路径：`/usr/lib64/httpd/modules/`
- 模块功能介绍：[http://httpd.apache.org/docs/2.4/zh-cn/mod/](http://httpd.apache.org/docs/2.4/zh-cn/mod/)


```shell
# 模块配置相关说明
[root@localhost ~]# grep -A 11 'Dynamic' /etc/httpd/conf/httpd.conf
# Dynamic Shared Object (DSO) Support
#
# To be able to use the functionality of a module which was built as a DSO you
# have to place corresponding `LoadModule' lines at this location so the
# directives contained in it are actually available _before_ they are used.
# Statically compiled modules (those listed by `httpd -l') do not need
# to be loaded here.
#
# Example:
# LoadModule foo_module modules/mod_foo.so
#
Include conf.modules.d/*.conf

# 动态模块存储位置
[root@localhost ~]# ls -l /etc/httpd/modules
lrwxrwxrwx. 1 root root 29 Apr 29 03:43 /etc/httpd/modules -> ../../usr/lib64/httpd/modules
[root@localhost ~]# ls  -l /etc/httpd/modules/
total 3508
-rwxr-xr-x. 1 root root  15488 Apr 29 03:43 mod_access_compat.so
......

# 动态模块加载相关配置
[root@localhost ~]# ls -l /etc/httpd/conf.modules.d/
total 48
-rw-r--r--. 1 root root 3325 Apr 29 03:41 00-base.conf
......

[root@localhost ~]# grep LoadModule /etc/httpd/conf.modules.d/00-base.conf  | head -n 1
LoadModule access_compat_module modules/mod_access_compat.so

```

## 案例分析1

修改默认网址目录为：`/data/www/html`

## 案例分析2

修改 ServerName 为：`test.mysite.com`；修改 Listen 为：`8090`


# 持久连接

Persistent Connection：连接建立，每个资源获取完成后不会断开连接，而是继续等待其它的请求完成，默认是开启持久连接。当开启持久连接后的断开条件是以超时时间为限制，默认为5s。
- 优势：可以显著提高包含许多图像的 HTML 文档的延迟时间，几乎加快了 50%
- 缺点：对并发访问量大的服务器，持久连接会使部分请求得不到响应而终止

## 案例分析

开启/关闭 Keepalive 进行测试验证
- 观察客户端TCP连接是否复用？
- [扩展] 使用压测工具进行测试观察响应延时？

```shell
# 默认开启进行测试验证
[root@localhost ~]# curl -v http://127.0.0.1  http://127.0.0.1 http://127.0.0.1
[root@localhost ~]# ss -tan | grep 80
TIME-WAIT 0      0               127.0.0.1:39486          127.0.0.1:80

# 关闭后进行测试验证
[root@localhost ~]# echo "Keepalive Off" > /etc/httpd/conf.d/kp.conf
[root@localhost ~]#  ss -tan | grep 80
TIME-WAIT 0      0      [::ffff:127.0.0.1]:80   [::ffff:127.0.0.1]:33352
TIME-WAIT 0      0      [::ffff:127.0.0.1]:80   [::ffff:127.0.0.1]:33342
TIME-WAIT 0      0      [::ffff:127.0.0.1]:80   [::ffff:127.0.0.1]:33330

```

# 虚拟主机

Httpd 支持在一台物理主机上实现多个网站，即多虚拟主机
- 网站的唯一标识，多虚拟主机有三种实现方案
  - IP 相同 + Port 不同
  - IP 不同 + Port 相同
  - FQDN 不同

## 案例分析1

基于 Port 虚拟主机

```shell
# 准备根目录和主页文件
[root@localhost ~]# mkdir -pv /data/website{1,2,3}
[root@localhost ~]# echo "This is NO.1 website!" > /data/website1/index.html
[root@localhost ~]# echo "This is NO.2 website!" > /data/website2/index.html
[root@localhost ~]# echo "This is NO.3 website!" > /data/website3/index.html
# 基于 Port 虚拟主机配置文件
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site.conf
listen 8001
listen 8002
listen 8003

# vhost01
<Virtualhost *:8001>
   Documentroot /data/website1/
   <Directory /data/website1>
      Require all granted
   </Directory>
</Virtualhost>

# vhost02
<Virtualhost *:8002>
   Documentroot /data/website2/
   <Directory /data/website2>
      Require all granted
   </Directory>
</Virtualhost>

# vhost03
<Virtualhost *:8003>
   Documentroot /data/website3/
   <Directory /data/website3>
      Require all granted
   </Directory>
</Virtualhost>
EOF

# 重启服务并进行测试验证
[root@localhost ~]# systemctl restart httpd
[root@localhost ~]# curl 192.168.88.10:8001
This is NO.1 website!
[root@localhost ~]# curl 192.168.88.10:8002
This is NO.2 website!
[root@localhost ~]# curl 192.168.88.10:8003
This is NO.3 website!

```

## 案例分析2

基于 IP 虚拟主机

```shell
# 配置临时IP
[root@localhost ~]# ip addr add 172.16.175.111/24 dev ens33 label ens33:1
[root@localhost ~]# ip addr add 172.16.175.112/24 dev ens33 label ens33:2
[root@localhost ~]# ip addr add 172.16.175.113/24 dev ens33 label ens33:3
# 基于 IP 虚拟主机配置文件
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site.conf
# vhost01
<Virtualhost 172.16.175.111>
   Documentroot /data/website1/
   <Directory /data/website1>
      Require all granted
   </Directory>
</Virtualhost>

# vhost02
<Virtualhost 172.16.175.112>
   Documentroot /data/website2/
   <Directory /data/website2>
      Require all granted
   </Directory>
</Virtualhost>

# vhost03
<Virtualhost 172.16.175.113>
   Documentroot /data/website3/
   <Directory /data/website3>
      Require all granted
   </Directory>
</Virtualhost>
EOF
# 重启服务并进行测试验证
[root@localhost ~]# curl 172.16.175.111
This is NO.1 website!
[root@localhost ~]# curl 172.16.175.112
This is NO.2 website!
[root@localhost ~]# curl 172.16.175.113
This is NO.3 website!

```

## 案例分析3

基于 FQDN 虚拟主机

```shell
# 基于 FQDN 虚拟主机
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site.conf
# vhost01
<Virtualhost 172.16.175.129>
   ServerName website1.eagleslab.org
   Documentroot /data/website1/
   <Directory /data/website1>
      Require all granted
   </Directory>
</Virtualhost>

# vhost02
<Virtualhost 172.16.175.129>
   ServerName website2.eagleslab.org
   Documentroot /data/website2/
   <Directory /data/website2>
      Require all granted
   </Directory>
</Virtualhost>

# vhost03
<Virtualhost 172.16.175.129>
   ServerName website3.eagleslab.org
   Documentroot /data/website3/
   <Directory /data/website3>
      Require all granted
   </Directory>
</Virtualhost>
EOF

# 本地添加解析
[root@localhost ~]# cat <<EOF >> /etc/hosts
172.16.175.129 website1.eagleslab.org
172.16.175.129 website2.eagleslab.org
172.16.175.129 website3.eagleslab.org
EOF

# 重启服务并进行测试验证
[root@localhost ~]# curl website1.eagleslab.org
This is NO.1 website!
[root@localhost ~]# curl website2.eagleslab.org
This is NO.2 website!
[root@localhost ~]# curl website3.eagleslab.org
This is NO.3 website!

```

# 服务日志

httpd 有两种常见日志类型：访问日志和错误日志，错误日志使用标准 syslog 级别，按严重性递增排序。

https://httpd.apache.org/docs/current/mod/core.html#loglevel

## 日志配置

主配置文件日志配置相关定义块

```shell
[root@localhost ~]# grep -A27 '<IfModule log_config_module>' /etc/httpd/conf/httpd.conf
# ErrorLog: The location of the error log file.
# If you do not specify an ErrorLog directive within a <VirtualHost>
# container, error messages relating to that virtual host will be
# logged here.  If you *do* define an error logfile for a <VirtualHost>
# container, that host's errors will be logged there and not here.
#
ErrorLog "logs/error_log"

#
# LogLevel: Control the number of messages logged to the error_log.
# Possible values include: debug, info, notice, warn, error, crit,
# alert, emerg.
#
LogLevel warn

<IfModule log_config_module>
    #
    # The following directives define some format nicknames for use with
    # a CustomLog directive (see below).
    #
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      # You need to enable mod_logio.c to use %I and %O
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>

    #
    # The location and format of the access logfile (Common Logfile Format).
    # If you do not define any access logfiles within a <VirtualHost>
    # container, they will be logged here.  Contrariwise, if you *do*
    # define per-<VirtualHost> access logfiles, transactions will be
    # logged therein and *not* in this file.
    #
    #CustomLog "logs/access_log" common

    #
    # If you prefer a logfile with access, agent, and referer information
    # (Combined Logfile Format) you can use the following directive.
    #
    CustomLog "logs/access_log" combined
</IfModule>

```

ErrorLog：目标文件名
LogLevel：调整记录在错误日志中的消息的详细程度
ErrorLogFormat：错误日志条目的格式规范
LogFormat：设定自定义格式
CustomLog：定义日志文件和格式

**常见自定义格式的变量参考**

https://httpd.apache.org/docs/current/mod/mod_log_config.html#logformat

- %h 客户端IP地址
- %l 远程用户,启用mod_ident才有效，通常为减号“-”
- %u 验证（basic，digest）远程用户,非登录访问时，为一个减号“-”
- %t 服务器收到请求时的时间
- %r First line of request，即表示请求报文的首行；记录了此次请求的“方法”，“URL”以及协议版本
- %>s 对于已在内部重定向的请求，这是原始请求的状态。使用%>s 的最终状态。类型脚本中的exit 数字
- %b 响应报文的大小，单位是字节；不包括响应报文http首部
- %{Referer}i 请求报文中首部“referer”的值；即从哪个页面中的超链接跳转至当前页面。 { }里面内容就是报文中的一个键值对
- %{User-Agent}i 请求报文中首部“User-Agent”的值；即发出请求的应用程序，多数为浏览器型号


## 案例分析

新增自定义 LogFormat 并在 CustomLog 中引用


# URI 匹配规则

Apache httpd的URL匹配规则主要包括以下几种指令:

1. `<Location>`: 基于URL路径进行匹配。
2. `<LocationMatch>`: 使用正则表达式进行URL路径匹配。
3. `<Directory>`: 基于服务器文件系统的目录路径进行匹配。
4. `<DirectoryMatch>`: 使用正则表达式进行目录路径匹配。
5. `<Files>`: 基于文件名进行匹配。
6. `<FilesMatch>`: 使用正则表达式进行文件名匹配。

**优先级：**

这些指令的优先级从高到低为:

1. `<Files>` 和 `<FilesMatch>`
2. `<Directory>` 和 `<DirectoryMatch>`
3. `<Location>` 和 `<LocationMatch>`

**指令常用选项：**

1. `<Location>` 指令:
   - `path`: 指定需要匹配的 URL 路径。可以使用通配符。
   - `Order`: 控制允许和拒绝操作的顺序。可以是 `Allow,Deny` 或 `Deny,Allow`。
   - `Allow`: 指定允许访问的主机或 IP 地址。
   - `Deny`: 指定拒绝访问的主机或 IP 地址。
   - `Require`: 指定需要通过身份验证才能访问的用户或组。
2. `<LocationMatch>` 指令:
   - `regex`: 指定一个正则表达式来匹配 URL。
   - 其他选项同 `<Location>` 指令。
3. `<Directory>` 指令:
   - `path`: 指定需要匹配的目录路径。可以使用通配符。
   - `Options`: 设置目录的访问选项,如 `FollowSymLinks`、`Indexes` 等。
   - `AllowOverride`: 控制 .htaccess 文件的覆盖范围。
   - 其他选项同 `<Location>` 指令。
4. `<Files>` 指令:
   - `filename`: 指定需要匹配的文件名。可以使用通配符。
   - 其他选项同 `<Location>` 指令。
5. `<FilesMatch>` 指令:
   - `regex`: 指定一个正则表达式来匹配文件名。
   - 其他选项同 `<Files>` 指令

## 配置方法

```shell
#基于目录
<Directory “/path">
...
</Directory>
#基于文件
<File “/path/file”>
...
</File>
#基于文件通配符
<File “/path/*file*”>
...
</File>
#基于正则表达式
<FileMatch “regex”>
...
</FileMatch>
```

## 案例分析

1. **精确匹配**:

```shell
<Location "/admin">
   AuthType Basic
   AuthName "Admin Area"
   AuthUserFile "/path/to/htpasswd"
   Require valid-user
</Location>
```

在这个例子中,任何访问 `/admin` URL 的请求都会被要求进行基本认证(Basic Authentication)。只有通过验证的用户才能访问这个 URL。

2. **前缀匹配**:

```shell
<Location "/documents">
   Options Indexes FollowSymLinks
   AllowOverride None
   Require all granted
</Location>
```

   在这个例子中,任何访问 `/documents` 的 URL 的请求都会被允许执行目录索引和跟踪符号链接。所有用户都被允许访问这些 URL。

3. **正则表达式匹配**:

```shell
<LocationMatch "\.php$">
   SetHandler application/x-httpd-php
</LocationMatch>
```

   在这个例子中,任何访问以 `.php` 结尾的 URL 的请求都会被 Apache 识别为 PHP 脚本,并使用 PHP 处理器来执行它们。

4. **通配符匹配**:

```shell
<Directory "/var/www/*/images">
   Options Indexes FollowSymLinks
   AllowOverride None
   Require all granted
</Directory>
```

在这个例子中,任何位于 `/var/www/*/images` 目录下的文件都会被允许通过目录索引和符号链接访问,所有用户都被允许访问这些文件

5. **特定文件类型匹配**:

```shell
<Files "*.html">
   SetOutputFilter INCLUDES
   # SetOutputFilter INCLUDES 是 Apache httpd 中一个非常有用的配置指令,它可以启用 Server-Side Includes (SSI) 功能。
</Files>
```

在这个例子中,任何以 `.html` 结尾的文件都会被 Apache 处理为包含服务器端包含指令(Server-Side Includes)的文件。

6. **主机名匹配**:

```bash
<Virtualhost www.example.com:80>
   Documentroot "/var/www/example"
   ServerName www.example.com
</Virtualhost>
```

在这个例子中,任何发送到 `www.example.com:80` 的请求都会被映射到 `/var/www/example` 目录,并由 Apache 配置为 `www.example.com` 的虚拟主机。


# Options 指令

## 相关介绍

用于控制特定目录下启用的服务器功能特性（如目录列表、符号链接等）

语法：`Options [+|-]option [[+|-]option] ...`
作用域：`<Directory>, <Location>, <Files>, .htaccess`
特性：
- **+/- 前缀**​​：动态添加或移除选项，支持配置继承与合并（无前缀时直接覆盖）
- **优先级**：子目录配置优先于父目录，正则表达式匹配的配置最后生效

**常用选项**

| 选项 | 功能说明  | 适用场景                   |
| :--- | :--- | :--- |
| Indexes | 当目录无默认文件（如 index.html）时，自动生成文件列表 | 开发环境调试，生产慎用 |
| FollowSymLinks | 允许通过符号链接访问目录外资源（在 `<Location>` 中无效）  | 跨目录资源整合 |
| MultiViews            | 内容协商：根据请求头（如语言）自动匹配文件（需 mod_negotiation） | 多语言站点适配             |
| ExecCGI               | 允许执行 CGI 脚本（需 mod_cgi）     | 动态脚本处理（如 Perl/Python）|
| Includes              | 启用服务端包含（SSI）（需 mod_include）                          | 动态页面片段嵌入           |
| IncludesNOEXEC        | 允许 SSI 但禁用 `#exec` 执行命令/CGI                              | 安全限制下的 SSI 功能      |
| SymLinksIfOwnerMatch  | 仅当符号链接与目标文件所有者相同时允许访问（在 `<Location>` 中无效）| 高安全要求的共享环境       |
| All     | 启用除 `MultiViews` 外的所有特性（默认值）                         | 快速启用常用功能           |
| None    | 禁用所有额外特性      | 严格安全策略      |

## 案例分析

使用 `Index` 和 `FollowSymLinks`，当访问无索引文件的目录时显示文件列表，允许符号链接跳转；依次去掉 `FollowSymLinks` 和 `Index` 观察现象。

```shell
# 准备实验环境
[root@localhost ~]# mkdir -pv /data/site04/public
[root@localhost ~]# touch /data/site04/public/{1,2,3}.html
[root@localhost ~]# ln -s /etc/passwd /data/site04/public/passwd.tx
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site01.conf
Listen 8001
<Virtualhost 172.16.175.129:8001>
   Documentroot /data/site04
   <Directory /data/site04/public>
      Options Indexes FollowSymLinks
      Require all granted
   </Directory>
</Virtualhost>
EOF
[root@localhost ~]# systemctl restart httpd
# 通过浏览器访问测试验证
```


# AllowOverride 指令

## 相关介绍

用于控制是否允许在 .htaccess 文件中覆盖主配置文件的设定，通常用于目录级的动态配置，无需重启服务即可生效。作用域限制​为：仅能在 `​​<Directory>` 块​​中生效，在 `<Location>`、`<Files>` 等配置段中无效。


**常用参数**

| 参数值         | 说明  |
| :--- | :--- |
| None          | 完全忽略 .htaccess 文件，服务器不读取其内容（默认推荐，提升性能与安全性）。             |
| All           | 允许 .htaccess 覆盖所有支持的指令（需谨慎启用，可能引发安全风险）。                     |
| AuthConfig    | 允许覆盖认证相关指令（如 AuthName, Require）。                                         |
| FileInfo      | 允许覆盖文件处理指令（如 ErrorDocument, RewriteRule, Header）。                        |
| Indexes       | 允许覆盖目录索引控制指令（如 DirectoryIndex, IndexIgnore）。                           |
| Limit         | 允许覆盖访问控制指令（如 Allow, Deny, Order）。                                        |
| Options[=...] | 允许覆盖目录特性控制指令（如 Options FollowSymLinks，可指定具体允许的选项）。           |

## 案例分析

通过 `AllowOverride` 指令和 `.htaccess` 文件，动态为指定目录设定特性控制指令

```shell
# 准备实验环境
[root@localhost ~]# mkdir -pv /data/site05/public
[root@localhost ~]# touch /data/site05/public/{1,2,3}.html
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site02.conf
Listen 8002
<Virtualhost 172.16.175.129:8002>
   Documentroot /data/site05
   <Directory /data/site05/public>
      AllowOverride Options=Indexes
      Require all granted
   </Directory>
</Virtualhost>
EOF
[root@localhost ~]# systemctl restart httpd
# 通过浏览器访问：禁止访问
# 通过 .htaccess 文件覆盖设定
[root@localhost ~]# echo "Options Indexes" > /data/site05/public/.htaccess
# 通过浏览器访问测试验证
```

# 访问控制

针对各种资源，通常基于两种方式：客户端来源地址和用户账号来进行访问控制。

## 基于IP地址

基于客户端IP地址的访问控制：
   - Apache 2.4 默认 **​​拒绝所有未显式授权**​ ​的访问，需明确配置 `Require all granted` 开放全局访问
   - `Require host` 可基于域名控制（如 Require host example.com），但需注意 DNS 解析延迟可能影响性能
   - 不带 `not` 的多个 `Require` 是“或”关系（任一满足即可）
   - 带 `not` 和不带 `not` 的语句混合时是“与”关系（需同时满足）

常见语法：
   - 允许所有主机访问：`Require all granted`
   - 拒绝所有主机访问：`Require all denied`
   - 授权/拒绝指定来源的IP/host访问：`Require [not] <ip|host>  <ipaddress|hostname>`

组合策略配置：
   - `​​<RequireAll>` 内部所有条件必须​​同时满足​​（逻辑与）
   - `<RequireAny>` 内部任一条件满足即可（逻辑或）

## 基于用户

基于用户的访问控制主要通过身份验证（Authentication）和授权（Authorization）机制实现：

**认证类型**：
- Basic 认证​​：用户名密码以 Base64 编码传输（明文，需配合 HTTPS 保证安全）
- ​​Digest 认证​​：密码哈希传输（更安全，但配置复杂）

**核心配置指令**：
- AuthName​​：定义认证区域名称（浏览器弹窗提示文本）
- AuthUserFile​​：指定存储用户名密码的文本文件路径（如 .htpasswd）
- ​​Require​​：授权规则（如 valid-user 允许所有认证用户，或指定用户/组）

**密码文件**

```shell
[root@localhost ~]# htpasswd  --help
Usage:
	htpasswd [-cimB25dpsDv] [-C cost] [-r rounds] passwordfile username
   ...
# 创建文件并追加用户
[root@localhost ~]# htpasswd -c /etc/httpd/.htpasswd user1
# 追加用户
[root@localhost ~]# htpasswd /etc/httpd/.htpasswd user2
```

## 基于用户组

可以对 htpasswd 产生的多用户进行分组管理

组文件：`echo "admins: user1 user2" >  /etc/httpd/.htgroup `
配置授权组：

```shell
AuthGroupFile /etc/apache2/.htgroup
Require group admins  # 仅允许 admins 组成员
```

## 案例分析

混合IP和用户认证：仅允许本地x.x.x.x地址可以通过eagleslab01用户访问

```shell
[root@localhost ~]# mkdir -pv /data/site06/admin
[root@localhost ~]# echo "This is NO.6 website!" > /data/site06/admin/index.html
[root@localhost ~]# htpasswd -c /etc/httpd/.htpasswd eagleslab01
[root@localhost ~]# htpasswd /etc/httpd/.htpasswd eagleslab02
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site06.conf
Listen 8006
<Virtualhost 172.16.175.129:8006>
   Documentroot /data/site06
   <Directory /data/site06/admin>
      AuthType Basic
      AuthName "FBI warning"
      AuthUserFile "/etc/httpd/.htpasswd"
      <RequireAll>
         Require user eagleslab01
         # 客户端主机地址
         Require ip 172.16.175.1
         # 同时满足IP和用户认证
      </RequireAll>
   </Directory>
</Virtualhost>
EOF
[root@localhost ~]# systemctl restart httpd
# 测试验证
# 本地主机访问 403
[root@localhost ~]# curl -u eagleslab01:123456 http://172.16.175.129:8006/admin
# 客户端主机访问 301/200
client ~ % curl -u eagleslab01:123456 http://172.16.175.129:8006/admin
# 客户端主机访问 401
client ~ % curl -u eagleslab02:123456 http://172.16.175.129:8006/admin

```

# URL 处理机制

​​**别名（Alias）​​ 和 ​​重定向（Redirect）**​​ 是两种不同的 URL 处理机制，核心区别在于​**​是否改变客户端浏览器地址栏的 URL​​** 以及​**​是否触发新的 HTTP 请求​​**

## 别名 Alias

用于将 URL 路径映射到文件系统的不同位置，实现灵活的资源管理和访问控制。

### 相关介绍

**路径资源解耦**：将 URL 路径（如 `/images`）映射到物理目录（如 `/var/www/media`），无需修改实际文件位置，示例如下：
```shell
Alias "/images" "/var/www/html/media"
访问 http://domain.com/images/photo.jpg 实际返回 /var/www/html/media/photo.jpg
```
**简化URL结构**：隐藏复杂路径，提升用户体验和 SEO 友好性
**多域名/路径管理**：同一服务器托管多个站点，示例如下：
```shell
<VirtualHost *:80>
    ServerName blog.example.com
    Alias "/" "/var/www/blog"
</VirtualHost>
<VirtualHost *:80>
    ServerName notes.example.com
    Alias "/" "/var/www/notes"
</VirtualHost>
...
```

**相关指令**
```shell
# 将 URL 映射到文件系统位置
Alias [URL-path] file-path|directory-path

# 使用正则表达式将 URL 映射到文件系统位置
AliasMatch regex file-path|directory-path

# 将 URL 映射到文件系统位置，并将目标指定为 CGI 脚本
ScriptAlias [URL-path] file-path|directory-path
```


### 案例分析

将 `/usr/share/httpd/icons` 独立资源通过 `/icons` 别名暴露简洁路径

```shell
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site07.conf
Listen 8007
<Virtualhost 172.16.175.129:8007>
   Alias /icons /usr/share/httpd/icons
   <Directory /usr/share/httpd/icons>
      Options Indexes FollowSymLinks
      AllowOverride none
      Require all granted
   </Directory>
</Virtualhost>
EOF
# 通过浏览器访问 http://172.16.175.129:8007/icons/
# [root@localhost ~]# curl -I http://172.16.175.129:8007/icons/ 返回 200

```

## 重定向 Redirect

强制客户端跳转到另一个 URL，通常用于路径迁移或权限控制

### 相关介绍

**网站改版迁移**​​：旧路径 `http://old.com` 永久跳转到 `http://new.com`（301）
​**​权限控制**​​：未登录用户访问 `/admin` 时跳转到登录页（302）
**临时维护**​​：将流量临时导向通知页面（302）

**相关指令**：

```shell
Redirect [status] [URL-path] URL
   permanent  永久，返回301
   temp  临时，返回302
   seeother 资源替换 返回303
   gone  永久移除，返回410

RedirectMatch [status] regex URL
   使用正则表达式代替简单的路径前缀匹配

RedirectPermanent URL-path URL
   等效 Redirect permanent

RedirectTemp URL-path URL
   等效 Redirect temp

# https://httpd.apache.org/docs/2.4/mod/mod_rewrite.html
RewriteEngine on|off
   启用或禁用运行时重写引擎

RewriteCond TestString CondPattern [flags]
   定义了重写发生的条件

RewriteRule Pattern Substitution [flags]
   定义重写引擎的规则

```


### 案例分析1

网站改版迁移：旧域名访问新网站

```shell
[root@localhost ~]# mkdir -pv /data/new_site08/ 
[root@localhost ~]# echo "This is New NO.8 website!" > /data/new_site08/index.html
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site08.conf
# old site 
<Virtualhost 172.16.175.129>
   ServerName cloud.eagleslabtest.com
   Redirect 301 / http://ncloud.eagleslabtest.com/
</Virtualhost>

# new site
<Virtualhost 172.16.175.129>
   ServerName ncloud.eagleslabtest.com
   Documentroot /data/new_site08
   <Directory /data/new_site08>
      Require all granted
   </Directory>
</Virtualhost>
EOF
[root@localhost ~]# echo "172.16.175.129 ncloud.eagleslabtest.com" >> /etc/hosts
[root@localhost ~]# echo "172.16.175.129 cloud.eagleslabtest.com" >> /etc/hosts
[root@localhost ~]# systemctl restart httpd
# 测试验证
[root@localhost ~]# curl -L http://cloud.eagleslabtest.com/index.html
This is New NO.8 website!
[root@localhost ~]# curl -I http://cloud.eagleslabtest.com/index.html
HTTP/1.1 301 Moved Permanently
Date: Mon, 07 Jul 2025 19:20:27 GMT
Server: Apache/2.4.62 (Rocky Linux)
Location: http://ncloud.eagleslabtest.com/index.html
Connection: close
Content-Type: text/html; charset=iso-8859-1

```

### 案例分析2

用户访问需登录的资源（如个人中心、订单页），系统通过302重定向到登录页，并在登录成功后携带return_url参数跳回原页面

```shell
RewriteEngine On
RewriteCond %{REQUEST_URI} ^/profile
RewriteCond %{HTTP_COOKIE} !session_token
RewriteRule ^(.*)$ /login?return_url=$1 [R=302,L]
```

### 案例分析3

根据User-Agent将移动端用户临时重定向至移动版站点

```shell
RewriteCond %{HTTP_USER_AGENT} "android|iphone|ipad" [NC]
RewriteCond %{HTTP_HOST} ^www\.example\.com$
RewriteRule ^(.*)$ http://m.example.com/$1 [R=302,L]
```

# 网页压缩技术

网页压缩技术主要通过 ​​mod_deflate 模块​​实现，它能显著减少传输数据量，提升网站加载速度和用户体验

## 相关介绍

- 使用 mod_deflate 模块压缩页面优化传输速度
- 适用场景
   - 节约带宽，额外消耗CPU；同时，可能有些较老浏览器不支持
   - 压缩适于压缩的资源，例如文本文件


**压缩相关指令**

```shell
# 可选项
SetOutputFilter DEFLATE
# 指定对哪种 MIME 类型进行压缩，必须指定项
AddOutputFilterByType DEFLATE text/plain
AddOutputFilterByType DEFLATE text/html
AddOutputFilterByType DEFLATE application/xhtml+xml
AddOutputFilterByType DEFLATE text/xml
AddOutputFilterByType DEFLATE application/xml
AddOutputFilterByType DEFLATE application/x-javascript
AddOutputFilterByType DEFLATE text/javascript
AddOutputFilterByType DEFLATE text/css

# 也可以同时写多个
AddOutputFilterByType DEFLATE text/html text/plain text/xml text/css application/javascript

# 压缩级别 (Highest 9 - Lowest 1) ，默认gzip  默认级别是由库决定
DeflateCompressionLevel 9
# 排除特定旧版本的浏览器，不支持压缩
# Netscape 4.x 只压缩text/html
BrowserMatch ^Mozilla/4 gzip-only-text/html
# Netscape 4.06-08 三个版本 不压缩
BrowserMatch ^Mozilla/4\.0[678] no-gzip
# Internet Explorer标识本身为“Mozilla / 4”，但实际上是能够处理请求的压缩。如果用户代理首部
# 匹配字符串“MSIE”（“B”为单词边界”），就关闭之前定义的限制
BrowserMatch \bMSI[E] !no-gzip !gzip-only-text/html

SetOutputFilter DEFLATE		# 启用Gzip压缩
```

## 案例分析

```shell

# 准备实验环境
[root@localhost ~]# mkdir -pv /data/site0901/ /data/site0902/
[root@localhost ~]# tree /etc > /data/site0901/blog.html
[root@localhost ~]# tree /etc > /data/site0902/blog.html
# 配置对比vhost
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site09.conf
Listen 8009
Listen 8010
<Virtualhost *:8009>
   Documentroot /data/site0901/
   <Directory /data/site0901/>
      Require all granted
   </Directory>
   AddOutputFilterByType DEFLATE text/plain
   AddOutputFilterByType DEFLATE text/html     
   SetOutputFilter DEFLATE
</Virtualhost>

<Virtualhost *:8010>
   Documentroot /data/site0902/
   <Directory /data/site0902/>
      Require all granted
   </Directory>
</Virtualhost>
EOF
[root@localhost ~]# systemctl restart httpd
# 默认curl没有压缩，需要加参数 --compressed，输出结果关注 Content-Encoding: gzip & Content-Length 
[root@localhost ~]# curl -I --compressed 127.0.0.1:8009/blog.html
[root@localhost ~]# curl -I --compressed 127.0.0.1:8010/blog.html

```

# HTTPS

- SSL是基于IP地址实现,单IP的httpd主机，仅可以使用一个https虚拟主机
- 实现多个虚拟主机站点，apache不能支持，nginx支持
- SSL实现过程
   - 客户端发送可供选择的加密方式，并向服务器请求证书
   - 服务器端发送证书以及选定的加密方式给客户端
   - 客户端取得证书并进行证书验证，如果信任给其发证书的CA
   - 验证证书来源的合法性；用CA的公钥解密证书上数字签名
   - 验证证书内容的合法性：完整性验证
   - 检查证书的有效期限
   - 检查证书是否被吊销
   - 证书中拥有者的名字，与访问的目标主机要一致
- 客户端生成临时会话密钥（对称密钥），并使用服务器端的公钥加密此数据发送给服务器，完成密钥交换
- 服务用此密钥加密用户请求的资源，响应给客户端

## HTTPS请求过程

Web网站的登录页面都是使用https加密传输的，加密数据以保障数据的安全，HTTPS能够加密信息，以免敏感信息被第三方获取,所以很多银行网站或电子邮箱等等安全级别较高的服务都会采用HTTPS协议，HTTPS其实是有两部分组成: HTTP + SSL/ TLS,也就是在HTTP上又加了一层处理加密信息的模块。服务端和客户端的信息传输都会通过TLS进行加密，所以传输的数据都是加密后的数据。

![img-HTTPS请求过程](Apache/HTTPS请求过程.png)

https 实现过程如下：

1. **客户端发起HTTPS请求**

   客户端访问某个web端的https地址，一般都是443端口

2. **服务端的配置**

   采用https协议的服务器必须要有一套证书，可以通过**权威机构**申请，也可以自己制作，目前国内很多⽹站都⾃⼰做的，当你访问⼀个⽹站的时候提示证书不可信任就表示证书是⾃⼰做的，证书就是⼀个公钥和私钥匙，就像⼀把锁和钥匙，正常情况下只有你的钥匙可以打开你的锁，你可以把这个送给别⼈让他锁住⼀个箱⼦，⾥⾯放满了钱或秘密，别⼈不知道⾥⾯放了什么⽽且别⼈也打不开，只有你的钥匙是可以打开的。

   ```
   对称加密与非对称加密区别
   对称加密只有密钥
   非对称加密有公私钥，公钥加密，私钥解密
   ```

3. **传送证书**

   服务端给客户端传递证书，其实就是公钥，⾥⾯包含了很多信息，例如证书得到颁发机构、过期时间等等。

4. **客户端解析证书**

   这部分⼯作是有客户端完成的，⾸先回验证公钥的有效性，⽐如颁发机构、过期时间等等，如果发现异常则会弹出⼀个警告框提示证书可能存在问题，如果证书没有问题就⽣成⼀个随机值，然后⽤证书对该随机值进⾏加密，就像2步骤所说把随机值锁起来，不让别⼈看到。

5. **传送4步骤的加密数据**

   就是将⽤证书加密后的随机值传递给服务器，⽬的就是为了让服务器得到这个随机值，以后客户端和服务端的通信就可以通过这个随机值进⾏加密解密了。

6. **服务端解密信息**

   服务端用私钥解密5步骤加密后的随机值之后，得到了客户端传过来的随机值(私钥)，然后把内容通过该值进⾏对称加密，对称加密就是将信息和私钥通过算法混合在⼀起，这样除非你知道私钥，不然是⽆法获取其内部的内容，而正好客户端和服务端都知道这个私钥，所以只要机密算法够复杂就可以保证数据的安全性。

7. **传输加密后的信息**

   服务端将⽤私钥加密后的数据传递给客户端，在客户端可以被还原出原数据内容

8. **客户端解密信息**

   客户端⽤之前⽣成的私钥获解密服务端传递过来的数据，由于数据⼀直是加密的，因此即使第三⽅获取到数据也⽆法知道其详细内容。

## HTTPS加解密过程

**HTTPS 中使用的加密技术主要包括以下几个步骤:**

1. **密钥协商**:
   - 在 SSL/TLS 握手过程中,客户端和服务器协商出一个对称加密密钥。
   - 这个对称密钥是用于后续数据加密和解密的临时密钥。
2. **对称加密**:
   - 客户端和服务器使用协商好的对称密钥对 HTTP 请求和响应数据进行加密和解密。
   - 对称加密算法通常包括 AES、DES、3DES 等,速度快且计算开销小。
3. **非对称加密**:
   - 在握手过程中,服务器使用自己的私钥对称密钥进行加密,发送给客户端。
   - 客户端使用服务器的公钥解密获得对称密钥。
   - 非对称加密算法通常包括 RSA、ECC 等,安全性高但计算开销大。
4. **摘要算法**:
   - 客户端和服务器使用摘要算法(如 SHA-256)计算数据的数字签名。
   - 数字签名用于验证数据的完整性,确保数据在传输过程中未被篡改。
5. **证书验证**:
   - 客户端使用预先内置的受信任根证书颁发机构(CA)公钥,验证服务器证书的合法性。
   - 这确保连接的服务器是真实的,而不是中间人攻击者伪造的。

## 案例分析

自建 HTTPS 服务器：自签名证书生成、Apache 配置、​强制 HTTP 跳转 HTTPS及测试验证

```shell
[root@localhost ~]# mkdir -pv /data/site10/
[root@localhost ~]# echo "This is NO.10 website!" > /data/site10/index.html
# 安装 mod_ssl 模块和 openssl 工具
[root@localhost ~]# yum install mod_ssl openssl -y
# 确认 httpd 已经加载 ssl_module 模块
[root@localhost ~]# httpd -M | grep ssl
ssl_module (shared)
# 备份默认 ssl.conf 文件避免互相影响
[root@localhost ~]# mv /etc/httpd/conf.d/ssl.conf{,.bak}
[root@localhost ~]# grep -nr 'ssl' /etc/httpd/conf.modules.d/*
/etc/httpd/conf.modules.d/00-ssl.conf:1:LoadModule ssl_module modules/mod_ssl.so
# 创建 X509 自签名证书
[root@localhost ~]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
   -keyout /etc/httpd/ssl/server.key \
   -out /etc/httpd/ssl/server.crt \
   -subj "/C=XX/ST=Test/O=DevEnv/CN=ssl.eagleslabtest.com" \
   -addext "subjectAltName=DNS:ssl.eagleslabtest.com,IP:172.16.175.129"

# HTTPS 相关虚拟主机配置
[root@localhost ~]# cat << EOF > /etc/httpd/conf.d/site10.conf
# ​​强制 HTTP 跳转 HTTPS
<VirtualHost 172.16.175.129:80>
   ServerName ssl.eagleslabtest.com
   RewriteEngine On
   RewriteCond %{HTTPS} off
   RewriteRule (.*) https://%{HTTP_HOST}%{REQUEST_URI} [R=301,L]
</VirtualHost>

Listen 443 https
<VirtualHost 172.16.175.129:443>
   ServerName ssl.eagleslabtest.com
   DocumentRoot /data/site10/
   <Directory /data/site10/>
      Require all granted
   </Directory>
   SSLEngine on
   SSLCertificateFile /etc/httpd/ssl/server.crt
   SSLCertificateKeyFile /etc/httpd/ssl/server.key

   # 安全增强配置（可选但推荐）
   # 禁用旧协议
   SSLProtocol all -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
   # 强加密套件
   SSLCipherSuite HIGH:!aNULL:!MD5:!3DES
</VirtualHost>
EOF

[root@localhost ~]# systemctl restart httpd
[root@localhost ~]# echo "172.16.175.129 ssl.eagleslabtest.com" >> /etc/hosts
# 测试验证: -k 忽略证书警告测试
[root@localhost ~]# curl -k https://ssl.eagleslabtest.com/index.html
This is NO.10 website!
# 测试验证: 强制跳转
[root@localhost ~]#  curl -k -L http://ssl.eagleslabtest.com/index.html
This is NO.10 website!
```

一、通过openssl工具来自己生成一个证书，然后颁发给自己

```shell
# 1. 安装mod_ssl和openssl
[root@localhost ~]# yum install mod_ssl openssl -y

# 2.生成2048位的加密私钥
[root@localhost ~]# openssl genrsa -out server.key 2048

# 3.生成证书签名请求（CSR）
[root@localhost ~]# openssl req -new -key server.key -out server.csr
# 一路回车到底，过程暂时不需要管

# 4.生成类型为X509的自签名证书。有效期设置3650天，即有效期为10年
[root@localhost ~]# openssl x509 -req -days 3650 -in server.csr -signkey server.key -out server.crt

# 5.复制文件到相应的位置
[root@localhost ~]# cp server.crt /etc/pki/tls/certs/
[root@localhost ~]# cp server.key /etc/pki/tls/private/     
[root@localhost ~]# cp server.csr /etc/pki/tls/private/

# 6.修改配置文件，指定我们自己的证书文件路径
[root@localhost ~]# vim /etc/httpd/conf.d/ssl.conf
SSLCertificateFile /etc/pki/tls/certs/server.crt
SSLCertificateKeyFile /etc/pki/tls/private/server.key

# 7.重启httpd
[root@node1 ~]# systemctl restart httpd   
```

二、检查443端口是否开放

```bash
[root@localhost ~]# ss -nlt
State   Recv-Q  Send-Q   Local Address:Port   Peer Address:Port Process
LISTEN  0       128            0.0.0.0:22          0.0.0.0:*
LISTEN  0       511                  *:443               *:*
LISTEN  0       511                  *:80                *:*
LISTEN  0       128               [::]:22             [::]:*
```

三、https访问测试

可以使用curl命令查看证书，可以看到我们的证书是一个自签名证书

```bash
[root@localhost ~]# curl -kv https://127.0.0.1
#k表示支持https
#v表示显示详细的信息
.....
SSL certificate verify result: self-signed certificate (18), continuing anyway.
.....
```

Windows访问测试

![image-20250118224232388](Apache/image-20250118224232388.png)


# MPM 多路处理模块

httpd 支持三种 MPM 工作模式：prefork, worker, event

**相关配置文件**

```shell
[root@localhost ~]# cat /etc/httpd/conf.modules.d/00-mpm.conf |grep mpm
# LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
# LoadModule mpm_worker_module modules/mod_mpm_worker.so
LoadModule mpm_event_module modules/mod_mpm_event.so
```

## prefork 模式

Prefork MPM，这种模式采用的是预派生子进程方式，用单独的子进程来处理请求，子进程间互相独立，互不影响，大大的提高了稳定性，但每个进程都会占用内存，所以消耗系统资源过高。

![img](Apache/prefork模式.png)

## worker 模式

Worker MPM 是Apche 2.0 版本中全新的支持多进程多线程混合模型的 MPM，由于使用线程来处理 HTTP 请求，所以效率非常高，而对系统的开销也相对较低，Worker MPM 也是基于多进程的，但是每个进程会生成多个线程，由线程来处理请求，这样可以保证多线程可以获得进程的稳定性。

![img](Apache/worker工作模式.png)

## event 模式

这个是 Apache 中最新的模式，在现在版本里的已经是稳定可用的模式。它和 worker 模式很像，最大的区别在于，它解决了 keepalive 场景下 ，长期被占用的线程的资源浪费问题（某些线程因为被keep-alive，挂在那里等待，中间几乎没有请求过来，一直等到超时）。

event MPM 中，会有一个专门的线程来管理这些 keepalive 类型的线程，当有真实请求过来的时候，将请求传递给服务线程，执行完毕后，又允许它释放。这样，一个线程就能处理多个请求，实现了异步非阻塞。

event MPM 在遇到某些不兼容的模块时会失效，将会回退到 worker 模式，一个工作线程处理一个请求。官方自带的模块，全部是支持event MPM的。

![img](Apache/event工作模式.png)

# LAMP架构

LAMP就是由Linux+Apache+MySQL+PHP组合起来的架构

并且Apache默认情况下就内置了PHP解析模块，所以无需CGI即可解析PHP代码

**请求示意图：**

<img src="Apache/LAMP架构.png" alt="image-LAMP架构" style="zoom:80%;" />

## 安装Apache

```bash
[root@localhost ~]# yum install -y httpd

# 启动httpd
[root@localhost ~]# systemctl enable --now httpd

# 关闭防火墙和SElinux
[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# setenforce 0
```

**访问测试：**`http://IP`

<img src="Apache/image-20240719230216883.png" alt="image-20240719230216883" style="zoom: 80%;" />

## 安装php环境

1. 安装php8.0全家桶

```bash
[root@localhost ~]# yum install -y php*

# 启动php-fpm
[root@localhost ~]# systemctl enable --now php-fpm
[root@localhost ~]# systemctl status php-fpm
● php-fpm.service - The PHP FastCGI Process Manager
     Loaded: loaded (/usr/lib/systemd/system/php-fpm.service; enabled; preset: disabled)
     Active: active (running) since Sat 2025-01-18 21:54:09 CST; 7s ago
   Main PID: 34564 (php-fpm)
     Status: "Ready to handle connections"
      Tasks: 6 (limit: 10888)
     Memory: 22.6M
        CPU: 119ms
     CGroup: /system.slice/php-fpm.service
             ├─34564 "php-fpm: master process (/etc/php-fpm.conf)"
             ├─34565 "php-fpm: pool www"
             ├─34566 "php-fpm: pool www"
             ├─34567 "php-fpm: pool www"
             ├─34568 "php-fpm: pool www"
             └─34569 "php-fpm: pool www"

Jan 18 21:54:09 localhost.localdomain systemd[1]: Starting The PHP FastCGI Process Manage>
Jan 18 21:54:09 localhost.localdomain systemd[1]: Started The PHP FastCGI Process Manager.
```

2. 重启httpd服务以加载php相关模块

```bash
[root@localhost ~]# systemctl restart httpd
```

## 安装Mysql数据库

```bash
# 安装mariadb数据库软件
[root@localhost ~]# yum install -y mariadb-server mariadb

# 启动数据库并且设置开机自启动
[root@localhost ~]# systemctl enable --now mariadb

# 设置mariadb的密码
[root@localhost ~]# mysqladmin password '123456'

# 验证数据库是否工作正常
[root@localhost ~]# mysql -uroot -p123456 -e "show databases;"
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
+--------------------+
```

## PHP探针测试

在默认的网站根目录下创建`info.php`

```bash
[root@localhost ~]# vim /var/www/html/info.php
<?php
	phpinfo();
?>
```

写一个简单的php代码，可以使用phpinfo函数查看php的信息，从而检测是否成功解析php代码

编写好以后，我们访问：`http://IP/info.php`测试

<img src="Apache/image-20250118215910240.png" alt="image-20250118215910240" style="zoom:80%;" />

这里如果可以看到上述页面，说明我们的php代码成功被解析了

## 数据库连接测试

编写php代码，用php来连接数据库测试

```bash
[root@localhost ~]# vim /var/www/html/mysql.php
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

<img src="Apache/image-20240719231237537.png" alt="image-20240719231237537" style="zoom:80%;" />

## 安装phpmyadmin

由于我们还没有学习mysql如何管理，我们可以部署phpmyadmin工具，该工具可以让我们可视化管理我们的数据库

```bash
# 移动到网站根目录
[root@localhost ~]# cd /var/www/html

# 下载phpmyadmin源码
[root@localhost ~]# wget https://files.phpmyadmin.net/phpMyAdmin/5.1.1/phpMyAdmin-5.1.1-all-languages.zip

# 解压软件包，并且重命名
[root@localhost ~]# unzip phpMyAdmin-5.1.1-all-languages.zip
[root@localhost ~]# mv phpMyAdmin-5.1.1-all-languages phpmyadmin
```

访问`http://IP/phpmyadmin`进行测试

<img src="Apache/image-20240719231636758.png" alt="image-20240719231636758" style="zoom:80%;" />

用户名和密码为我们刚才初始化数据库时设置的root和123456，登陆后，会进入图形化管理界面

<img src="Apache/image-20240719231744450.png" alt="image-20240719231744450" style="zoom:80%;" />

# 个人博客

## 源码获取

下载typecho博客系统源码到`/var/www/html/typecho`

```bash
[root@localhost ~]# cd /var/www/html

# 创建typecho目录
[root@localhost ~]# mkdir typecho
[root@localhost ~]# cd typecho

[root@localhost ~]# wget https://github.com/typecho/typecho/releases/latest/download/typecho.zip

# 解压源码
[root@localhost ~]# unzip typecho.zip
```

## 创建数据库

点击数据库

<img src="Apache/image-20240719232259490.png" alt="image-20240719232259490" style="zoom:80%;" />

输入数据库名之后，就可以点击创建

![image-20211106110832539](Apache/image-20211106110832539.png)

## 安装博客系统

下面就可以开始进入网站安装的部分了，访问博客系统页面

`http://IP/typecho`

<img src="Apache/image-20250118220523743.png" alt="image-20250118220523743" style="zoom:80%;" />

提示安装目录下面的/usr/uploads没有权限，那么我们手动赋予该目录w权限

```bash
[root@localhost typecho]# chmod a+w usr/uploads/
```

填写数据库信息，密码为部署mariadb时设置的123456

<img src="Apache/image-20250118220724260.png" alt="image-20250118220724260" style="zoom:80%;" />

遇到提示无法自动创建配置文件config.inc.php。我们手动在网站的根目录下创建该文件，并且将内容复制进去

```bash
[root@localhost typecho]# vim config.inc.php
```

之后完善如下网站信息后，点击继续安装

<img src="Apache/image-20250118221026614.png" alt="image-20250118221026614" style="zoom:80%;" />

到此，我们的typecho个人博客系统就部署完成了

<img src="Apache/image-20250118221109186.png" alt="image-20250118221109186" style="zoom:80%;" />

## 切换主题

默认的主题如下，界面比较的简洁，我们可以给这个网站替换主题，也可以借此加深熟悉我们对Linux命令行的熟练程度

<img src="Apache/image-20250118221202018.png" alt="image-20250118221202018" style="zoom:80%;" />

第三方主题商店：https://www.typechx.com/

我们尝试更换这个主题

<img src="Apache/image-20250118221344667.png" alt="image-20250118221344667" style="zoom:80%;" />

选择模板下载

<img src="Apache/image-20250118221414487.png" alt="image-20250118221414487" style="zoom:80%;" />

然后在打开的github仓库中下载ZIP压缩包

<img src="Apache/image-20250118221502963.png" alt="image-20250118221502963" style="zoom:80%;" />

将下载好的主题压缩包上传到博客主题的目录`/var/www/html/typecho/usr/themes`

<img src="Apache/image-20250118221634385.png" alt="image-20250118221634385" style="zoom:80%;" />

然后解压主题包，并且将名称改为简单一点的

```bash
[root@localhost themes]# unzip Typecho-Butterfly-main.zip
[root@localhost themes]# ls
Typecho-Butterfly-main  Typecho-Butterfly-main.zip  default
[root@localhost themes]# mv Typecho-Butterfly-main butterfly
[root@localhost themes]# rm -rf Typecho-Butterfly-main.zip
```

然后登录到博客后台，在设置里更换主题

<img src="Apache/image-20250118221843976.png" alt="image-20250118221843976" style="zoom:80%;" />

然后回到博客首页刷新一下，就可以看到新的主题已经应用了~

![image-20250118221920089](Apache/image-20250118221920089.png)

会有一些图片资源的丢失，稍微了解一点前端知识，就可以将其完善好了。不懂前端的同学，可以去找一些简单一点的主题。

<img src="Apache/image-20250118221958932.png" alt="image-20250118221958932" style="zoom:80%;" />
