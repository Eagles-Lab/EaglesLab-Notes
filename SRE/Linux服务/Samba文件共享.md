# Samba文件共享

## 什么是Samba

Samba 是一个开源软件套件，允许 Linux/Unix 系统与 Windows 系统之间实现文件共享和打印服务。Samba 使用 SMB（Server Message Block）/CIFS（Common Internet File System）协议，这些协议是 Windows 系统共享资源的基础。

## 发展历程

**1992 年**：Samba 项目由 Andrew Tridgell 发起，最初作为一个简单工具来查看 DOS 文件共享。

**1994 年**：Samba 正式命名，支持 SMB 协议。

**1996 年**：开始支持 Windows NT 域。

**2003 年**：引入 LDAP 集成，支持 Active Directory。

**2012 年**：Samba 4 发布，完全实现了 Active Directory 的功能。

**现在**：Samba 成为企业级跨平台文件共享的核心工具之一。

## Samba用途

**文件共享**：允许用户在不同操作系统之间共享文件。

**打印服务**：提供跨平台的打印服务和在线编辑。

**域控制器**：Samba 可以用作 Windows 网络的域控制器。

**认证与授权**：支持用户认证、访问控制和权限管理。

**跨平台互操作性**：让 Linux/Unix 系统与 Windows 系统无缝协作。

Windows计算机网络管理模式：

* 工作组WORKGROUP：计算机对等关系，帐号信息各自管理
* 域DOMAIN：C/S结构，帐号信息集中管理，DC,AD

## Samba相关软件包介绍

在 Rocky Linux 中，Samba 的核心组件包含以下软件包：

- **samba**：Samba 的主包，包括核心服务和工具。
- **samba-client**：提供客户端工具，用于访问远程的 SMB/CIFS 共享。
- **samba-common**：共享的配置文件和库。
- **samba-libs**：Samba 运行所需的库。
- **samba-common-tools**：包含测试和管理工具，例如 `smbstatus`。
- **smbclient**：命令行工具，用于访问 SMB/CIFS 共享。
- **cifs-utils**：提供挂载 SMB 文件系统的工具（如 `mount.cifs`）。

## 相关服务进程

**smbd**：提供文件共享和打印服务，TCP：139、445。

**nmbd**：负责 NetBIOS 名称解析和浏览功能，UDP：137、138。

**winbindd**：用于与 Windows 域集成，支持用户和组的认证。

**samba-ad-dc**：Samba 4 中的域控制器服务。

## Samba主配置文件

主配置文件：/etc/samba/smb.conf 帮助参看：man smb.conf

语法检查： testparm [-v] [/etc/samba/smb.conf]

```bash
[global]
   workgroup = WORKGROUP        # 工作组名称
   server string = Samba Server # 服务器描述
   security = user              # 认证模式
   log file = /var/log/samba/log.%m # 日志文件路径
   max log size = 50            # 最大日志文件大小（KB）
   dns proxy = no               # 禁用 DNS 代理

[shared]
   path = /srv/samba/shared      # 共享路径
   browseable = yes              # 是否可浏览
   writable = yes                # 是否可写
   valid users = @smbgroup       # 允许访问的用户/组
```

### 全局设置（[global]）

- `workgroup`：指定工作组名称，默认是 `WORKGROUP`。
- security：
  - `user`：用户级认证（常用）。
  - `share`：共享级认证（不推荐）。
  - `domain`：域级认证。
  - `ads`：Active Directory 服务。
- `log file`：日志文件路径。
- `max log size`：限制日志文件大小。

### 共享设置（[共享名]）

- `path`：共享目录的路径。
- `browseable`：决定共享是否可被浏览。
- `writable`：是否允许写入。
- `valid users`：指定允许访问的用户或组。

# 快速开始

## 安装Samba服务

```bash
[root@localhost ~]# yum -y install samba
[root@localhost ~]# systemctl enable --now smb
[root@localhost ~]# systemctl enable --now nmb
[root@localhost ~]# ss -nlt
State    Recv-Q   Send-Q     Local Address:Port       Peer Address:Port   Process
LISTEN   0        50               0.0.0.0:445             0.0.0.0:*
LISTEN   0        50               0.0.0.0:139             0.0.0.0:*
LISTEN   0        128              0.0.0.0:22              0.0.0.0:*
LISTEN   0        50                  [::]:445                [::]:*
LISTEN   0        50                  [::]:139                [::]:*
LISTEN   0        128                 [::]:22                 [::]:*
```

在`ss`命令的输出中，`Recv-Q`和`Send-Q`是与TCP连接相关的两个队列的大小。

- `Recv-Q`表示接收队列的大小。它指示了尚未被应用程序（进程）接收的来自网络的数据的数量。当接收队列的大小超过一定限制时，可能会发生数据丢失。
- `Send-Q`表示发送队列的大小。它指示了应用程序（进程）等待发送到网络的数据的数量。当发送队列的大小超过一定限制时，可能会导致发送缓冲区已满，从而阻塞应用程序发送更多的数据。

## 配置Samba用户

* 包：samba-common-tools
* 工具：smbpasswd pdbedit
* 用户数据库：/var/lib/samba/private/passdb.tdb

说明：samba用户须是Linux用户，建议使用/sbin/nologin

一、创建系统用户

```bash
[root@localhost ~]# useradd -s /sbin/nologin smbuser
[root@localhost ~]# echo 123 | passwd --stdin smbuser
Changing password for user smbuser.
passwd: all authentication tokens updated successfully.
```

二、创建Samba用户

```bash
[root@localhost ~]# smbpasswd -a smbuser
New SMB password:
Retype new SMB password:
Added user smbuser.
[root@localhost ~]# smbpasswd -e smbuser		# 启用用户
Enabled user smbuser.
```

三、其他操作(视具体情况而使用)

* 如果已经存在，想修改密码

```shell
[root@localhost ~]# smbpasswd smb1
```

* 想要删除用户和密码

```shell
[root@localhost ~]# smbpasswd -x smb1
[root@localhost ~]# pdbedit -x -u smb1
```

* 查看samba用户列表

```shell
[root@localhost ~]# pdbedit -L -v
```

* 查看samba服务器状态

```shell
[root@localhost ~]# yum install -y samba
[root@localhost ~]# smbstatus
```

## 基于特定用户或组的共享

### 服务端操作

一、创建共享目录

共享目录为：`/data/samba`

```bash
[root@localhost ~]# mkdir -p /data/samba
[root@localhost ~]# chown -R smbuser:smbuser /data/samba
[root@localhost ~]# chmod -R 2770 /data/samba
```

二、添加配置文件

```bash
[root@localhost ~]# vim /etc/samba/smb.conf
......
[shared]
   path = /data/samba
   browseable = yes
   writable = yes
   valid users = @smbuser
   create mask = 0660
   directory mask = 2770
```

三、关闭防火墙与SELinux

```bash
[root@localhost ~]# systemctl stop firewalld
[root@localhost ~]# setenforce 0
```

四、重启smb服务

```bash
[root@localhost ~]# systemctl restart smb
[root@localhost ~]# systemctl restart nmb
```

### 客户端操作

#### Windows连接

一、在运行窗口中输入：`\\192.168.88.10\`进行连接

<img src="Samba%E6%96%87%E4%BB%B6%E5%85%B1%E4%BA%AB/image-20250111104202425.png" alt="image-20250111104202425" style="zoom:80%;" />

二、用户验证：smbuser/123

三、文件创建写入测试

<img src="Samba%E6%96%87%E4%BB%B6%E5%85%B1%E4%BA%AB/image-20250111105213658.png" alt="image-20250111105213658" style="zoom:80%;" />

四、Samba服务端中查看

```bash
[root@localhost ~]# cat /data/samba/file.txt
The file is Created by windows...
```

#### Linux连接

一、客户端工具下载

```bash
[root@localhost ~]# yum -y install samba-client
```

二、创建上传测试文件

```bash
[root@localhost ~]# echo "In server2..." > server2.txt
```

三、使用smbclient连接服务器测试

```bash
[root@localhost ~]# smbclient -L 192.168.88.10 -U smbuser
Password for [SAMBA\smbuser]:

        Sharename       Type      Comment
        ---------       ----      -------
        print$          Disk      Printer Drivers
        shared          Disk
        IPC$            IPC       IPC Service (Samba 4.20.2)
        smbuser         Disk      Home Directories
SMB1 disabled -- no workgroup available
[root@localhost ~]# smbclient //192.168.88.10/shared -U smbuser
Password for [SAMBA\smbuser]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sat Jan 11 11:06:08 2025
  ..                                  D        0  Sat Jan 11 11:06:08 2025
  file.txt                            A       33  Sat Jan 11 10:51:54 2025

                17756160 blocks of size 1024. 16032064 blocks available
smb: \> get file.txt		# 下载文件
getting file \file.txt of size 33 as file.txt (16.1 KiloBytes/sec) (average 16.1 KiloBytes/sec)
smb: \> put /server2.txt	# 上传文件
putting file /server2.txt as \server2.txt (4.6 kb/s) (average 4.6 kb/s)
```

### 挂载CIFS文件系统

手动挂载：

```bash
[root@localhost ~]# yum install -y cifs-utils
[root@localhost ~]# mkdir /mnt/smb
[root@localhost ~]# mount -t cifs //192.168.88.10/shared /mnt/smb -o username=smbuser,password=123
[root@localhost ~]# df -h
Filesystem              Size  Used Avail Use% Mounted on
devtmpfs                4.0M     0  4.0M   0% /dev
tmpfs                   872M     0  872M   0% /dev/shm
tmpfs                   349M  5.2M  344M   2% /run
/dev/mapper/rl-root      17G  1.7G   16G  10% /
/dev/nvme0n1p1          960M  261M  700M  28% /boot
tmpfs                   175M     0  175M   0% /run/user/0
//192.168.88.10/shared   17G  1.7G   16G  10% /mnt/smb
[root@localhost ~]# cd /mnt/smb/
[root@localhost smb]# ls
file.txt  server2.txt
```

开机自动挂载：

```bash
[root@localhost ~]# vim /etc/fstab
//192.168.88.10/shared  /mnt/smb        cifs    defaults,username=smbuser,password=123 0 0
[root@localhost ~]# systemctl daemon-reload
[root@localhost ~]# mount -a
[root@localhost ~]# df -h
Filesystem              Size  Used Avail Use% Mounted on
devtmpfs                4.0M     0  4.0M   0% /dev
tmpfs                   872M     0  872M   0% /dev/shm
tmpfs                   349M  5.2M  344M   2% /run
/dev/mapper/rl-root      17G  1.7G   16G  10% /
/dev/nvme0n1p1          960M  261M  700M  28% /boot
//192.168.88.10/shared   17G  1.7G   16G  10% /mnt/smb
tmpfs                   175M     0  175M   0% /run/user/0
```

# 实战：不同账户访问不同目录

## 服务端

一、创建并启用用户

创建三个samba用户，分别为smb1、smb2、smb3。密码均为：123

```bash
[root@localhost ~]# useradd -s /sbin/nologin -r smb1		# -r 不创建家目录
[root@localhost ~]# useradd -s /sbin/nologin -r smb2
[root@localhost ~]# useradd -s /sbin/nologin -r smb3
[root@localhost ~]#
[root@localhost ~]# smbpasswd -a smb1
New SMB password:
Retype new SMB password:
Added user smb1.
[root@localhost ~]# smbpasswd -a smb2
New SMB password:
Retype new SMB password:
Added user smb2.
[root@localhost ~]# smbpasswd -a smb3
New SMB password:
Retype new SMB password:
Added user smb3.
[root@localhost ~]# smbpasswd -e smb1
Enabled user smb1.
[root@localhost ~]# smbpasswd -e smb2
Enabled user smb2.
[root@localhost ~]# smbpasswd -e smb3
Enabled user smb3.

# 查看smb用户
[root@localhost ~]# pdbedit -L
smbuser:1000:
smb2:986:
smb1:987:
smb3:985:
```

二、修改Samba配置文件如下

```bash
[root@localhost ~]# vim /etc/samba/smb.conf
# 在global中添加该字段
[global]
config file = /etc/samba/conf.d/%U		# 变量%U表示匹配用户名

# 新建共享配置
[share]
        path = /data/samba/share
        browseable = yes
        writable = yes
        Guest ok = yes
        create mask = 0660
        directory mask = 2770
```

三、配置共享目录和文件

```bash
[root@localhost ~]# mkdir -p /data/samba/share
[root@localhost ~]# mkdir -p /data/samba/smb1
[root@localhost ~]# mkdir -p /data/samba/smb2
[root@localhost ~]# touch /data/samba/share/share.txt		# 共享目录及文件
[root@localhost ~]# touch /data/samba/smb1/smb1.txt			# smb1目录及文件
[root@localhost ~]# touch /data/samba/smb2/smb2.txt			# smb2目录及文件
[root@localhost ~]# tree /data/samba/
/data/samba/
├── file.txt
├── server2.txt
├── share
│   └── share.txt
├── smb1
│   └── smb1.txt
└── smb2
    └── smb2.txt

# 将/data/samba目录权限放开
[root@localhost ~]# chmod 777 -R /data/samba
```

四、针对smb1用户和smb2用户单独编辑配置文件

```bash
[root@localhost ~]# vim /etc/samba/conf.d/smb1
[share]
        path = /data/samba/smb1
        writable = yes
        create mask = 0660
        browseable = yes
[root@localhost ~]# vim /etc/samba/conf.d/smb2
[share]
        path = /data/samba/smb2
        writable = yes
        create mask = 0660
        browseable = yes
```

五、重启相关服务

```bash
[root@localhost ~]# systemctl restart smb
[root@localhost ~]# systemctl restart nmb
```

## 客户端

客户端访问测试

```bash
[root@localhost ~]# smbclient //192.168.88.10/share -U smb1
Password for [SAMBA\smb1]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sat Jan 11 15:00:58 2025
  ..                                  D        0  Sat Jan 11 15:00:58 2025
  smb1.txt                            N        0  Sat Jan 11 15:00:58 2025

                17756160 blocks of size 1024. 16030864 blocks available
smb: \> exit
[root@localhost ~]# smbclient //192.168.88.10/share -U smb2
Password for [SAMBA\smb2]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sat Jan 11 15:00:03 2025
  ..                                  D        0  Sat Jan 11 15:00:03 2025
  smb2.txt                            N        0  Sat Jan 11 15:00:03 2025

                17756160 blocks of size 1024. 16030864 blocks available
smb: \> exit
[root@localhost ~]# smbclient //192.168.88.10/share -U smb3
Password for [SAMBA\smb3]:
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Sat Jan 11 14:59:44 2025
  ..                                  D        0  Sat Jan 11 14:59:44 2025
  share.txt                           N        0  Sat Jan 11 14:59:44 2025

                17756160 blocks of size 1024. 16030884 blocks available
```

## **结论**

由此可以看出，我们通过针对不同用户编写子配置文件的方式来覆盖主配置文件中相同的共享。可以实现对于没有子配置的用户，访问主配置文件中的定义的目录。对于具备子配置的用户，访问子配置所定义的目录。实现控制不用用户登录访问不同目录。