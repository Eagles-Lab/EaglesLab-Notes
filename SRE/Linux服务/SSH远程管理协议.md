# SSH协议/OpenSSH服务

SSH（Secure Shell）协议是一种网络协议，用于加密方式远程登录到服务器。它提供了一种安全的方法来传输数据，防止数据在传输过程中被窃听或篡改。SSH协议不仅用于远程登录，还可用于远程执行命令、文件传输（SFTP）、端口转发等。

OpenSSH是SSH协议的一个开源实现工具，由OpenBSD项目开发和维护。它是大多数Unix和类Unix操作系统中默认的SSH实现，包括Linux、macOS和FreeBSD等。

OpenSSH提供了服务端程序(openssh-server)和客户端工具(openssh-client)

* Mac和Linux中默认已安装ssh客户端，可直接在终端中使用ssh命令
* Windows需手动安装ssh客户端，较常用的Windows SSH客户端有PuTTY和XShell

**SSH能够提供两种安全验证的方法：**

* 基于**口令**的验证—用账户和密码来验证登录
* 基于**密钥**的验证—需要在本地生成密钥对，然后把密钥对中的公钥上传至服务器，并与服务器中的公钥进行比较；该方式相较来说更安全

# SSH客户端使用

OpenSSH服务提供我们SSH工具，该工具采用SSH协议来连接到远程主机上。

## SSH常用操作

1. 通过SSH协议登录远程主机

```bash
[root@localhost ~]# ssh root@192.168.88.20		# root@表示登录到root用户
root@192.168.88.20's password:		# 输入远程主机的密码
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Tue Dec 24 15:42:36 2024 from 192.168.88.1
```

2. 指定连接远程主机的端口号(SSH默认连接的端口号为22，如果修改过端口号，可以通过以下方式连接)

```bash
[root@localhost ~]# ssh root@192.168.88.20 -P22
root@192.168.88.20's password:
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Tue Dec 24 15:43:18 2024 from 192.168.88.10
```

3. 不登陆到远程主机中，仅仅执行某个命令并返回结果

```bash
[root@localhost ~]# ssh root@192.168.88.20 ls -lah /etc
root@192.168.88.20's password:
total 1.2M
drwxr-xr-x. 95 root root   8.0K Dec 24 15:41 .
dr-xr-xr-x. 18 root root    235 Nov  9 10:51 ..
-rw-------.  1 root root      0 Nov  9 10:51 .pwd.lock
-rw-r--r--.  1 root root    208 Nov  9 10:51 .updated
-rw-r--r--.  1 root root   4.6K Apr 21  2024 DIR_COLORS
-rw-r--r--.  1 root root   4.7K Apr 21  2024 DIR_COLORS.lightbgcolor
-rw-r--r--.  1 root root     94 May 16  2022 GREP_COLORS
drwxr-xr-x.  7 root root    134 Nov  9 10:52 NetworkManager
drwxr-xr-x.  2 root root     48 Nov  9 10:52 PackageKit
drwxr-xr-x.  6 root root     70 Nov  9 10:56 X11
......
```

4. 查看已经连接过主机的记录(会看到ssh客户端产生的公钥信息)

```bash
[root@localhost ~]# cat .ssh/known_hosts
192.168.88.20 ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOThT7fdh7wxANOIlTBGdcF+m2sVH/N56HKSJGANz19u
192.168.88.20 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCmVQz5ziwIu9Ue3tUT2BGSr81+t7E3dpJBGuydoBnVeD6S7PVVkyf8RxsbYd1D0PhxlIb5qJzxybla8ua47J1RqKEZjNA0CITV4oFCcdTt38hqZzE1JxNqcV3TyqPt0uFetB09bYckk2T/HascnKAm2G7Sl+BIbs27oeFPhkSph/wfOLxh9nn6Yk3NwqPXrpUmn7w4A8P8UdeSXD4YvK/TNjPz9/eI0a2joxNpzyS0glcBhWfEb2UiplDGJlKoVl0NPxYhhYcwDLtzNhfgmre2wcgA9v3phdTUvsH1QWExE4qhpIisNa7jUhrB8Gg6ki3sI143MJnvdD56BILbv2U7UPOjIR5bTRx2yuDp2Z3d5lK+8gowyXAjmp59gVfUO8vaLVZ5oBiuzPBBntWqBrfYfWmd2CqoYFHXjCf+6quPNx2hVASIfHvUWXQuYzo8NOgaR0niMzzanADam3B87Tqlvo9psUQ1TQ1zdJlvo8FL+TkYyn6+Bc5lGJ3/un4Ip6s=
192.168.88.20 ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBGHvrjmizdqObHoyK1gJ59yIDGBfTNbLec0KzXZyAWrPwCdeQkaNRfmS9nb8W2jJCbZvciH1z3OPU8tMD5CdN3c=
```

## SCP远程文件传输

除了连接到远程主机之外，我们也可以用附带的小工具**SCP**来进行远程文件传输和下载

1. 将本地文件复制给远程主机，-r递归复制整个目录，-p保留源文件的时间和权限属性

```bash
[root@localhost ~]# touch file
[root@localhost ~]# echo "I am server1" > file
[root@localhost ~]# scp -P22 -r -p /root/file root@192.168.88.20:/tmp
root@192.168.88.20's password:
file                                                                 100%   13    12.2KB/s   00:00
```

2. 将远程主机上的文件下载到本地

```bash
[root@localhost ~]# scp -P22 -r -p root@192.168.88.20:/tmp/file /root/
```

3. SSH客户端自带SFTP功能，可以直接通过FTP协议进行文件传递

```bash
[root@localhost ~]# sftp -oPort=22 root@192.168.88.20
root@192.168.88.20's password:
Connected to 192.168.88.20.
sftp> ls
anaconda-ks.cfg
sftp> get /tmp/file
Fetching /tmp/file to file
file                                                                 100%   13     6.8KB/s   00:00
sftp> exit
[root@localhost ~]# ls
anaconda-ks.cfg  file
[root@localhost ~]# cat file
I am server1
```

# SSH配置文件

* sshd服务的配置信息保存在`/etc/ssh/sshd_config`文件中。运维人员一般会把保存着最主要配置信息的文件称为主配置文件，而配置文件中有许多以井号开头的注释行，要想让这些配置参数生效，需要在修改参数后再去掉前面的井号
* sshd服务配置文件中包含的参数以及作用

| 参数                              | 作用                                |
| :-------------------------------- | :---------------------------------- |
| Port 22                           | 默认的sshd服务端口                  |
| ListenAddress 0.0.0.0             | 设定sshd服务器监听的IP地址          |
| Protocol 2                        | SSH协议的版本号                     |
| HostKey /etc/ssh/ssh_host_key     | SSH协议版本为1时，DES私钥存放的位置 |
| HostKey /etc/ssh/ssh_host_rsa_key | SSH协议版本为2时，RSA私钥存放的位置 |
| HostKey /etc/ssh/ssh_host_dsa_key | SSH协议版本为2时，DSA私钥存放的位置 |
| PermitRootLogin yes               | 设定是否允许root管理员直接登录      |
| StrictModes yes                   | 当远程用户的私钥改变时直接拒绝连接  |
| MaxAuthTries 6                    | 最大密码尝试次数                    |
| MaxSessions 10                    | 最大终端数                          |
| PasswordAuthentication yes        | 是否允许密码验证                    |
| PubkeyAuthentication yes          | 是否允许使用公钥进行身份验证        |

# 安全密钥验证

上面讲到，ssh远程连接，除了使用密码的方式登录，还可以使用密钥对(公钥和私钥)进行登录。相比于密码等于而言，密钥登录会更加的安全

如果使用公钥和私钥进行加密，那么我们称之为是一种非堆成加密的方式进行加密，那同样的还有对称加密，不过对称加密我们到后面HTTPS协议中再详细讲解。

非对称加密是一种加密方式，它涉及到两个密钥：一个公钥和一个私钥。公钥可以公开给任何人，而私钥则必须保密，只有密钥的拥有者才知道。这种加密方式的特点是使用公钥加密的数据只能通过对应的私钥来解密，反之亦然，使用私钥加密的数据只能通过对应的公钥来解密。

## 非对称加密

1. **密钥生成**：首先生成一对密钥，一个公钥和一个私钥。这两个密钥是数学上相关的，但即使知道其中一个，也很难计算出另一个。
2. **加密**：发送方使用接收方的公钥来加密信息。这个过程是可逆的，但只有拥有正确私钥的人才能解密。
3. **解密**：接收方使用自己的私钥来解密信息。这个过程确保了只有拥有私钥的接收方才能阅读信息。

我们可以想象一下，你有一个非常特别的邮箱，这个邮箱有一个特点：它有两个锁。一个锁是公开的，任何人都可以往里投信，但只有你知道如何打开它（私钥）。另一个锁是私有的，只有你知道它在哪里，而且只有你拥有打开它的钥匙（公钥）。

- **公钥（锁）**：你把这个特别的锁（公钥）放在一个公共的地方，比如你的家门口。任何人都可以给你写信，他们只需要用这个锁把你的信锁起来，然后投进你的邮箱。因为只有你知道如何打开这个锁，所以你的信件在运输过程中是安全的。
- **私钥（钥匙）**：你把打开这个锁的钥匙（私钥）藏在家里一个安全的地方。当信件到达时，你可以用你的私钥打开锁，取出信件阅读。
- **安全性**：即使有人试图复制这个锁（公钥），他们也无法制造出能打开它的钥匙（私钥），因为这两个是数学上相关的，但计算其中一个从另一个是几乎不可能的。

## SSH密钥对口令验证

1. 在客户端主机中生成`密钥对`

```shell
[root@localhost ~]# ssh-keygen
Generating public/private rsa key pair.
Enter file in which to save the key (/root/.ssh/id_rsa):	# 选择密钥存放的位置，默认是/root/.ssh/目录
Enter passphrase (empty for no passphrase):					# 是否给密钥设置密码
Enter same passphrase again:								# 重复密码
Your identification has been saved in /root/.ssh/id_rsa
Your public key has been saved in /root/.ssh/id_rsa.pub
The key fingerprint is:
SHA256:+LY6jvJ6Azxw9avB5eMKOMBrzvryMVG1nHjszJI22lk root@localhost.localdomain
The key's randomart image is:
+---[RSA 3072]----+
|      .          |
|    .= o         |
|   .o.*          |
|o .. *o.         |
|.=..=oE.S        |
|..==o=+.         |
|oo=oo+ .o        |
|=..++.o. .       |
|o*+=++oo.        |
+----[SHA256]-----+

# 查看/root/.ssh目录中，是否存在id_rsa(私钥)和id_rsa.pub(公钥)
[root@localhost ~]# ls -al /root/.ssh/
total 16
drwx------. 2 root root   80 Dec 25 09:24 .
dr-xr-x---. 3 root root  159 Dec 24 15:58 ..
-rw-------. 1 root root 2610 Dec 25 09:24 id_rsa
-rw-r--r--. 1 root root  580 Dec 25 09:24 id_rsa.pub
-rw-------. 1 root root  837 Dec 24 15:43 known_hosts
-rw-r--r--. 1 root root   95 Dec 24 15:43 known_hosts.old
```

2. 把客户端主机中生成的公钥文件传送至远程主机

```shell
# 使用ssh-copy-id这个工具，可以自动的将公钥发送给目标主机的/root/.ssh/目录下面
[root@localhost ~]# ssh-copy-id 192.168.88.20
/usr/bin/ssh-copy-id: INFO: Source of key(s) to be installed: "/root/.ssh/id_rsa.pub"
/usr/bin/ssh-copy-id: INFO: attempting to log in with the new key(s), to filter out any that are already installed
/usr/bin/ssh-copy-id: INFO: 1 key(s) remain to be installed -- if you are prompted now it is to install the new keys
root@192.168.88.20's password:

Number of key(s) added: 1

Now try logging into the machine, with:   "ssh '192.168.88.20'"
and check to make sure that only the key(s) you wanted were added.

# 检查server2中，是否成功接收到公钥
# server2中查看
[root@localhost ~]# ls -al /root/.ssh/
total 12
drwx------. 2 root root  71 Dec 25 09:29 .
dr-xr-x---. 3 root root 163 Nov 24 11:04 ..
-rw-------. 1 root root 580 Dec 25 09:29 authorized_keys
-rw-------. 1 root root 837 Dec 24 15:54 known_hosts
-rw-r--r--. 1 root root  95 Dec 24 15:54 known_hosts.old

# 公钥发送过来以后，名称会默认的改变为authorized_keys。我们可以查看这个文件中的内容，就是我们的公钥，与id_rsa.pub一致
[root@localhost ~]# cat /root/.ssh/authorized_keys
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDpPlj0cTuje/LHClQ+InIzTSdC2AViBWD3hb77ZcFpC1rfem7A9fuOJEZlNNALeHyAVjVvlVujhWDO8e7mbSJ0k/ECUVvq82r5bf9g8nJKuyWmKQ8DWHXhe4+WnMKHRDPsDM7blr/tnaUb86FPql0MUW1VOEQkP3ZN+NDomfH2DAuMzX5EKhYkcvVuekELeevXlEwWHA/mmizkxBqFKuoBdSpiQ7xjVC+FxAjAnrQwD1jmdrf+25x8DYm9J2S+led6fy3s6QPYRlawAR91M2Xf8+W1RHndcnZGhReCtZBJsIs6OCC3NqxCeZIVgwZzeAtPClWDyh1YhuvEL5mM1hjHICWhHCLqo15R7A0e/zCqhf3wxfelnQ21aNAbzALDYAjkquxm7nLbmRq07Na0XdASfJHpiuDG/aYzNTWaiQzcgZQmz13FUNfI+dikRupwL3XW57eNfo3qHNhZn9TxIQOueJ6N7vbSoYdiN34xvc8g1ZRPRFONftMg1HYBcZAYgMk= root@localhost.localdomain
```

3. 对远程主机(server2)进行设置，使其只允许密钥验证，拒绝传统的口令验证方式。记得在修改配置文件后保存并重启sshd服务程序

```shell
[root@localhost ~]# vim /etc/ssh/sshd_config
..................
65 PasswordAuthentication no
PubkeyAuthentication yes
...................
[root@localhost ~]# systemctl restart sshd
```

4. 在客户端尝试登录到服务器，此时无须输入密码也可成功登录

```shell
[root@localhost ~]# ssh root@192.168.88.20
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Wed Dec 25 09:11:48 2024 from 192.168.88.1


# 并且检查server2中的secure日志中，也可以看到我们是通过公钥登录到server2中
[root@localhost ~]# cat /var/log/secure |grep publickey
Dec 25 09:40:27 localhost sshd[2392]: Accepted publickey for root from 192.168.88.10 port 40652 ssh2: RSA SHA256:+LY6jvJ6Azxw9avB5eMKOMBrzvryMVG1nHjszJI22lk
```

# mobaxterm生成密钥登录

通过mobaxterm我们也可以生成密钥对，从而通过密钥对进行登录

1. 在工具选项中找到ssh密钥生成器

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20241225095837131-17364951629947.png" alt="image-20241225095837131" style="zoom: 67%;" />

2. 选择生成的密钥对类型以及点击Generator生成

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20241225100003857-17364951629948.png" alt="image-20241225100003857" style="zoom:80%;" />

3. 生成密钥对并且保存公钥和私钥

生成的时候，要鼠标不断移动，该工具会根据鼠标移动的坐标，来生成随机的密钥

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20241225100209895-17364951629949.png" alt="image-20241225100209895" style="zoom:80%;" />



三、linux .ssh目录下新建文件`authorized_keys`,将上面生成的密钥粘进去

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20241225104817789-17364951629926.png" alt="image-20241225104817789" style="zoom: 50%;" />

四、但是大概率会连接失败，原因是由于我们通过mobaxterm生成的密钥文件权限不满足要求，并且在windows上修改权限的话非常麻烦。所以我们可以考虑通过在cmd命令行中使用ssh-keygen工具来生成密钥文件

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20250114105202083.png" alt="image-20250114105202083" style="zoom:80%;" />

可以看到生成的公钥和私钥

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20250114105137753.png" alt="image-20250114105137753" style="zoom:80%;" />

打开公钥文件，复制其中的内容，在Linux中的/root.ssh/authorized_keys文件中粘贴

然后继续通过cmd连接测试：

<img src="SSH%E8%BF%9C%E7%A8%8B%E7%AE%A1%E7%90%86%E5%8D%8F%E8%AE%AE/image-20250114105438117.png" alt="image-20250114105438117" style="zoom:80%;" />

也可以尝试使用Mobaxterm工具，选择私钥进行连接。但是Mobaxterm连接的时候也可能会遇到报错的问题。这个是受不同工具的影响。如果通过cmd能够连接成功的话。就说明我们的密钥和配置是正常的。
