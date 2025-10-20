# 资源测试容器

使用`stress`程序可以对主机进行压力测试，在本课程中可以用来研究容器的资源限制带来的影响

```

FROM centos:7
RUN yum -y install epel-release \
&& yum -y install stress \
&& yum -y remove epel-release \
&& yum clean all
ENTRYPOINT ["stress"]
```

- 测试命令

```
docker build -t stress .
docker run -it --rm --cpuset-cpus=0-1 stress --cpu 2
docker run -it --rm --cpu-shares=4096 --cpuset-cpus=0-1 stress --cpu 2
docker run -it --rm -m 128m stress --vm 1 --vm-bytes 130m --vm-hang 0
```

- Linux资源查看命令

```


top -d 1
# 按q退出
```

 

# kod网盘搭建

- 一定要提前将kodbox.tar下载到Dockerfile所在的目录

```
mkdir kodtemp
cd kodtemp
wget https://static.kodcloud.com/update/download/kodbox.1.21.zip
unzip kodbox.1.21.zip
tar czvf kodbox.tar .
```

- 然后创建Dockerfile

```
vim Dockerfile

FROM php:apache

RUN apt-get update && apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd
ADD kodbox.tar /var/www/html
RUN chmod -R 777 /var/www/html
EXPOSE 80
CMD ["apache2-foreground"]
```

- 构建镜像

```


docker build -t mykod:v1 .
```

- 启动容器

```


docker run -d -p 80:80 mykod:v1
```

# 网页小游戏

- 下载[源代码](http://23126342.s21d-23.faiusrd.com/0/ABUIABAAGAAg1M3F9wUoxOzFiwY?f=BrowserQuest.tar.gz&v=1592878804)

## 在Linux上手动搭建

- 安装php运行环境

```
yum install php-cli php-process php-devel php-pear libevent-devel -y
```

- 解压

```
[root@localhost ~]# tar xzvf BrowserQuest.tar.gz
```

- 进入游戏目录

```


cd BrowserQuest
```

- 修改配置文件中的关键字段为本地的IP地址

```
[root@localhost BrowserQuest]# sed -i "s/hostip/192.168.175.88/g" Web/config/config_local.json
[root@localhost BrowserQuest]# cat Web/config/config_local.json                        {
    "host": "192.168.175.88",
    "port": 8000,
    "dispatcher": false
```

- 防火墙放行对应端口

```
[root@localhost BrowserQuest]# firewall-cmd --add-port=8787/tcp --permanent
success
[root@localhost BrowserQuest]# firewall-cmd --add-port=8000/tcp --permanent
success
[root@localhost BrowserQuest]# firewall-cmd --reload
success
```

 

- 运行该游戏服务端

```
[root@localhost BrowserQuest]# php start.php start
```

## 搬运到docker中

- 开启宿主机的IPv4流量转发保障容器上网

```


echo "net.ipv4.ip_forward=1" >> /usr/lib/sysctl.d/50-default.conf
sysctl -w net.ipv4.ip_forward=1
sysctl -p
```

 

- 创建Dockerfile

```

vim Dockerfile

FROM centos:7
ADD BrowserQuest.tar.gz /
RUN yum install php-cli php-process php-devel php-pear libevent-devel -y \
&& yum clean all
RUN echo 'sed -i "s/hostip/$HOST_IP/g" Web/config/config_local.json && php start.php start' > /BrowserQuest/run.sh
WORKDIR /BrowserQuest
EXPOSE 8000
EXPOSE 8787
CMD ["bash","run.sh"]
```

- 开始构建镜像

```
docker build -t webgame:v1 .
```

- 运行这个容器

```
docker run --rm -d -p 8000:8000 -p 8787:8787 -e "HOST_IP=10.3.32.84" webgame:v1
```