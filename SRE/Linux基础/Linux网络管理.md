# 数据通信基础

- 数据从产生到传递到目的地的过程中会经历好几个过程，每个过程都负责加工自己这部分的内容，类似于工厂流水线
- 目前我们只需要有个最基本的概念：
  - IP地址是用来标识网络中位置的，比如你在江苏省xxx市xxx路xxx号
  - MAC地址是每个网络设备的唯一ID，比如你的身份证号码 
  - 如果想要发送数据，必须(暂且认为必须)同时拥有IP和MAC地址
  - Linux的网络管理基础部分就是需要大家掌握IP地址的配置

![img-数据通信基础](Linux网络管理/数据通信基础.png)

## IP地址

- 在IP网络中，通信节点需要有一个唯一的IP地址
- IP地址用于IP报文的寻址以及标识一个节点
- IPv4地址一共32bits，使用点分十进制的形式表示

<img src="Linux网络管理/IP地址.png" alt="img-IP地址" style="zoom:67%;" />

- IPv4地址由网络位和主机位组成
  - 网络位一致表示在同一个广播域中，可以直接通信
  - 主机位用于在同一个局域网中标识唯一节点

### 早期IP地址的划分

<img src="Linux网络管理/IP地址划分.png" alt="img-IP地址划分" style="zoom:67%;" />

- 早期参与互联网的设备不多，所以仅仅使用ABC类地址分配给用户即可
- 随着网络用户的增多，ABC类分配地址过于浪费，于是出现子网掩码方式划分网络位和主机位

### IP网络通信类型

- 单播(Unicast)
- 广播(Broadcast)
- 组播(Multicast)

### 子网掩码(Netmask)

- 网络掩码与IP地址搭配使用，用于描述一个IP地址中的网络部分及主机部分
- 网络掩码32bits，与32bits的IP地址一一对应，掩码中为1的位对应IP地址中的网络位，掩码中为0的位对应IP地址中的主机位

<img src="Linux网络管理/子网掩码.png" alt="img-子网掩码" style="zoom:67%;" />

- 减少一个局域网中的设备数量可以有效降低广播报文消耗资源

- 可变长子网掩码可以将一个局域网中的主机地址分配的更加小

<img src="Linux网络管理/可变长子网掩码.png" alt="img-可变长子网掩码" style="zoom:67%;" />

### 广播地址与网络号

- 在局域网中经常会有广播的需要(比如，mac地址查询，地址冲突检测等等)，所以将主机位全为1的地址做为本局域网的广播地址(注意！广播并不能跨越不同的局域网)
- 在网络中需要表示整个局域网，就像邮政编码表示一个大的区域一样，所以将主机位全为0的地址作为本局域网的网络号，用来代指整个网段
- 综上所述，计算产生的子网及每个子网的主机数量公式如下：

<img src="Linux网络管理/子网和主机IP数.png" alt="img-子网和主机IP数" style="zoom:50%;" />

### 私有IP地址

- 如果要取得互联网合法地址用于通信，必须要找 iana.org 组织分配
- 很多企业内部都有大量的网络设备，大多数时候这些设备只需要内部通信即可
- 企业的网络管理员可以从如下网段中自行分配地址

<img src="Linux网络管理/私有IP地址.png" alt="img-私有IP地址" style="zoom:50%;" />

- 私有IP地址空间中的地址不需要申请，随意使用，但是不能在互联网上与合法地址通信(因为对方没法回复你这个地址，因为世界上私有IP地址段无数个重复的，怎么知道回到谁那里呢)
- 而我们明明用的私有IP地址，也可以上网，因为我们需要先把自己的上网请求提交给网络中的网关(就是你家的出口路由器)，再由网关代替我们去获取内容转交给我们的电脑手机，而网关往往能从运营商那里得到一个合法的公有IP地址

# DHCP

DHCP（动态主机配置协议），主要用于给设备自动的分配IP地址以及网络信息，以便网络设备能够连接到网络并进行通信

DHCP给设备提供的信息如下：

- IP地址
- 子网掩码
- 网关地址
- DNS服务器地址
- 租约时间



## DHCP工作过程

1. 客户端启动时发送 DHCP 发现(DHCPDISCOVER)广播消息,寻找 DHCP 服务器。
2. DHCP 服务器收到广播消息后,会提供一个未被使用的 IP 地址以及其他网络配置信息(如子网掩码、默认网关、DNS 服务器等),并发送 DHCP 提供(DHCPOFFER)消息给客户端。
3. 客户端收到一个或多个 DHCP 提供消息后,会选择其中一个 DHCP 服务器提供的 IP 地址,并发送 DHCP 请求(DHCPREQUEST)消息确认。
4. DHCP 服务器收到客户端的 DHCP 请求消息后,会将该 IP 地址分配给客户端,并发送 DHCP 确认(DHCPACK)消息给客户端。
5. 客户端收到 DHCP 确认消息后,就可以使用分配到的 IP 地址和其他网络配置参数连接到网络了。

`dhclient`

我们可以通过抓包软件，捕捉到主机通过DHCP方式获取ip的过程，一共有4个数据包：

![img-DHCP数据包](Linux网络管理/DHCP数据包.png)

其中每个数据包的作用如下：

1. `Discover`消息是用于客户端向整个内网发送广播，期待DHCP服务器进行回应
   1. 这个数据包中的重要内容就是：消息类型，客户端ID，主机名，请求获得的信息
2. `Offer`消息是DHCP服务器对客户的回应
   1. 这个消息中会回复对方所需要的所有信息
3. `Request`这个是客户端确认DHCP服务器的消息
   1. 这个消息和第一个消息差不多，但是消息类别变为`Request`，并且会携带请求的IP地址
4. `ACK`DHCP服务器给客户端的最终确认
   1. 这个消息和第二个消息差不多，但是消息类型变为`ACK`

## DHCP续租

DHCP分配的信息是有有效期的，再租约时间快到的时候，如果我们想要继续使用这个地址信息，就需要向DHCP服务器续租

这也是大家虚拟机上IP地址经常发生变化的原因，这是因为虚拟机上默认就是以DHCP的方式获得IP地址的

我们可以查看Linux上的网络配置信息，该信息位于`/etc/NetworkManager/system-connections/ens160.nmconnection`

```bash
[root@localhost ~]# cat /etc/NetworkManager/system-connections/ens160.nmconnection
[connection]
id=ens160
uuid=dfea55d8-6ddc-3229-8152-cb9e261de181
type=ethernet
autoconnect-priority=-999
interface-name=ens160
timestamp=1731149277

[ethernet]

[ipv4]
method=auto

[ipv6]
addr-gen-mode=eui64
method=auto

[proxy]


# 可以看到配置中的method字段是以dhcp来获得IP地址的。
```

同样从VMware的虚拟网络设置中，也可以看到租约时间相关的内容

<img src="Linux网络管理/虚拟网络编辑器.png" alt="img-虚拟网络编辑器" style="zoom: 80%;" />



# DNS（域名解析）

DNS(Domain Name System) 是一套从域名到IP的映射的协议

在网络世界中，如果我们想要给某个机器，或者是某个网站去发送一个数据，都需要通过IP地址来找到对方，比如我们想要使用百度来搜索东西，就需要知道百度的IP地址，换句话说只要知道了百度的IP地址，我们就可以访问到百度

但是IP地址不易记忆，不可能记住每一个网站的IP地址是什么，于是早期的搞IT的那帮人研发出一个叫做主机名的东西。

最开始人们把IP和主机名的的对应关系记录在本地，这个文件目前在windows系统的`C:\Windows\System32\drivers\etc\hosts`中。但是后面发现并不好用，而且需要经常手动更新这个文件。类似于黄历



随着主机名越来越多，hosts文件不易维护，所以后来改用**域名解析系统DNS**：

- 一个组织的系统管理机构，维护系统内的每个主机的`IP和主机名`的对应关系
- 如果新计算机接入网络，将这个信息注册到`数据库`中
- 用户输入域名的时候，会自动查询`DNS`服务器，由`DNS服务器`检索数据库, 得到对应的IP地址。

## 域名

主域名是用来识别主机名称和主机所属的组织机构的一种分层结构的名称。
例如：http://www.baidu.com(域名使用.连接)

- com： 一级域名，表示这是一个企业域名。同级的还有 "net"(网络提供商)，"org"(非盈利组织) 等。
- baidu: 二级域名, 公司名。
- www: 只是一种习惯用法，并不是每个域名都支持。
- http:// :  要使用什么协议来连接这个主机名。

## 常见的域名解析服务器

- 114dns

​	114.114.114.114 

​	114.114.115.115

​	这是国内用户量数一数二的 dns 服务器，该 dns 一直标榜高速、稳定、无劫持、防钓鱼。

- Google DNS

​	8.8.8.8

​	8.8.4.4

​	......

可以理解为由这些服务器帮我们记录的域名和IP的对应关系，我们访问域名的时候去找这些dns服务器询问该域名对应的IP地址，当然，除了上述提到的这些dns服务器，三大运营商也提供了dns解析服务

## 域名解析的过程

1. 浏览器发起域名解析，首先查询浏览器缓存，如果没有，就查询hosts文件，如果没有就提出域名解析请求
2. 客户机提出域名解析请求，并将该请求发送给本地的域名服务器。
3. 当本地的域名服务器收到请求后,就先查询本地的缓存,如果有该纪录项,则本地的域名服务器就直接把查询的结果返回。
4. 如果本地的缓存中没有该纪录,则本地域名服务器就直接把请求发给根域名服务器,然后根域名服务器再返回给本地域名服务器一个所查询域(根的子域)的主域名服务器的地址。
5. 本地服务器再向上一步返回的域名服务器发送请求,然后接受请求的服务器查询自己的缓存,如果没有该纪录,则返回相关的下级的域名服务器的地址。
6. 重复第四步,直到找到正确的纪录。
7. 本地域名服务器把返回的结果保存到缓存,以备下一次使用,同时还将结果返回给客户机



# 配置网络服务
## 修改网卡配置文件
```bash
# 修改网卡配置文件
[root@localhost ~]# cat /etc/NetworkManager/system-connections/ens160.nmconnection 
[connection]
id=ens160
uuid=dfea55d8-6ddc-3229-8152-cb9e261de181
type=ethernet
autoconnect-priority=-999
interface-name=ens160
timestamp=1732264040

[ethernet]

[ipv4]
address1=192.168.88.110/24,192.168.88.2
dns=114.114.114.114;114.114.115.115;
method=manual

[ipv6]
addr-gen-mode=eui64
method=auto

[proxy]
```

当修改完Linux系统中的服务配置文件后，并不会对服务程序立即产生效果。要想让服务程序获取到最新的配置文件，需要手动重启相应的服务，之后就可以看到网络畅通了

```bash
[root@localhost ~]# systemctl restart NetworkManager
[root@localhost ~]# ping -c 4 www.baidu.com
PING www.a.shifen.com (180.101.50.242) 56(84) bytes of data.
64 bytes from 180.101.50.242 (180.101.50.242): icmp_seq=1 ttl=128 time=11.3 ms
...
```

## 网卡配置文件参数

| **节**         | **参数**               | **描述**                                                     |
| -------------- | ---------------------- | ------------------------------------------------------------ |
| `[connection]` | `id`                   | 连接的名称，这里是 `ens160`。                                |
|                | `uuid`                 | 连接的唯一标识符（UUID），用于唯一识别此连接。               |
|                | `type`                 | 连接的类型，`ethernet` 表示这是一个以太网连接。              |
|                | `autoconnect-priority` | 自动连接优先级，数值越小优先级越低。这里设置为 `-999`，表示极低的优先级。 |
|                | `interface-name`       | 连接对应的网络接口名称，这里是 `ens160`。                    |
|                | `timestamp`            | 连接的时间戳，表示最后修改的时间。                           |
| `[ethernet]`   | -                      | 此节用于配置以太网特定的设置，当前没有额外参数。             |
| `[ipv4]`       | `address1`             | 静态 IPv4 地址及其子网掩码，格式为 `IP地址/子网掩码` 和网关，例：`192.168.88.110/24,192.168.88.2`。 |
|                | `dns`                  | DNS 服务器地址，多个地址用分号分隔，这里是 `114.114.114.114;114.114.115.115;`。 |
|                | `method`               | IPv4 地址配置方法，这里设置为 `manual`，表示使用手动配置。   |
| `[ipv6]`       | `addr-gen-mode`        | 地址生成模式，`eui64` 表示使用 EUI-64 地址生成方式。         |
|                | `method`               | IPv6 地址配置方法，这里设置为 `auto`，表示自动获取 IPv6 地址。 |
| `[proxy]`      | -                      | 此节用于配置代理设置，当前没有额外参数。                     |

## nmcli 工具

nmcli命令是redhat7或者centos7之后的命令，该命令可以完成网卡上所有的配置工作，并且可以写入 配置文件，永久生效

- 查看接口状态

```bash
[root@localhost ~]# nmcli device status
DEVICE  TYPE      STATE                   CONNECTION
ens160  ethernet  connected               ens160
lo      loopback  connected (externally)  lo
```
- 查看链接信息

```bash
[root@localhost ~]# nmcli connection show
NAME    UUID                                  TYPE      DEVICE
ens160  dfea55d8-6ddc-3229-8152-cb9e261de181  ethernet  ens160
lo      529b2eed-2755-4cce-af3c-999beb49882d  loopback  lo
```

- 配置IP等网络信息

```bash
[root@localhost ~]# nmcli con mod "ens160" ipv4.addresses 192.168.88.140/24 ipv4.gateway 192.168.88.2 ipv4.dns "8.8.8.8,8.8.4.4" ipv4.method manual
```

- 启动/停止接口

```bash
[root@localhost ~]# nmcli connection down ens160
[root@localhost ~]# nmcli connection up ens160
```

- 创建链接

```bash
[root@localhost ~]# nmcli connection add type ethernet ifname ens160 con-name dhcp_ens160
# 激活链接
[root@localhost ~]# nmcli connection up dhcp_ens160
```

- 删除链接

```bash
[root@localhost ~]# nmcli connection delete dhcp_ens160
成功删除连接 'dhcp_ens160'（37adadf4-419d-47f0-a0f6-af849160a4f7）。
```



# ifconfig

- ifconfig 命令用于显示或设置网络设备。

**安装：**`yum install -y net-tools`

## 语法

```bash
ifconfig [network_interface]
         [down|up]
         [add <address>]
         [del <address>]
         [hw <type> <hw_address>]
         [io_addr <I/O_address>]
         [irq <IRQ>]
         [media <media_type>]
         [mem_start <memory_address>]
         [metric <number>]
         [mtu <bytes>]
         [netmask <netmask>]
         [tunnel <address>]
         [-broadcast <address>]
         [-pointopoint <address>]
         [<IP_address>]
```

## 选项说明

- `down`/`up`: 禁用/启用网络接口
- `add <address>`/`del <address>`: 添加或删除 IP 地址
- `hw <type> <hw_address>`: 设置硬件地址 (MAC 地址)
- `io_addr <I/O_address>`: 设置 I/O 地址
- `irq <IRQ>`: 设置中断请求
- `media <media_type>`: 设置网络媒体类型
- `mem_start <memory_address>`: 设置内存起始地址
- `metric <number>`: 设置路由度量值
- `mtu <bytes>`: 设置 MTU 值
- `netmask <netmask>`: 设置子网掩码
- `tunnel <address>`: 设置隧道地址
- `-broadcast <address>`: 设置广播地址
- `-pointopoint <address>`: 设置点对点地址
- `<IP_address>`: 设置 IP 地址

## 实例

- 显示网络设备信息

```bash
[root@localhost cmatrix-1.2a]# ifconfig
ens33: flags=4163<UP,BROADCAST,RUNNING,MULTICAST>  mtu 1500
        inet 192.168.88.136  netmask 255.255.255.0  broadcast 192.168.88.255
        inet6 fe80::a49c:12c9:1ebd:8fb2  prefixlen 64  scopeid 0x20<link>
        ether 00:0c:29:cb:d5:1a  txqueuelen 1000  (Ethernet)
        RX packets 122441  bytes 178564616 (170.2 MiB)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 13762  bytes 1315614 (1.2 MiB)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0

lo: flags=73<UP,LOOPBACK,RUNNING>  mtu 65536
        inet 127.0.0.1  netmask 255.0.0.0
        inet6 ::1  prefixlen 128  scopeid 0x10<host>
        loop  txqueuelen 1000  (Local Loopback)
        RX packets 0  bytes 0 (0.0 B)
        RX errors 0  dropped 0  overruns 0  frame 0
        TX packets 0  bytes 0 (0.0 B)
        TX errors 0  dropped 0 overruns 0  carrier 0  collisions 0
```

- 启动关闭指定网卡

```bash
[root@localhost ~]# ifconfig ens33 down
[root@localhost ~]# ifconfig ens33 up
```

- 配置IP地址

```bash
[root@localhost ~]# ifconfig eth0 192.168.1.56 
//给eth0网卡配置IP地址
[root@localhost ~]# ifconfig eth0 192.168.1.56 netmask 255.255.255.0 
// 给eth0网卡配置IP地址,并加上子掩码
[root@localhost ~]# ifconfig eth0 192.168.1.56 netmask 255.255.255.0 broadcast 192.168.1.255
// 给eth0网卡配置IP地址,加上子掩码,加上个广播地址
```

- 设置最大传输单元

```bash
[root@localhost ~]# ifconfig eth0 mtu 1500 
//设置能通过的最大数据包大小为 1500 bytes
```

