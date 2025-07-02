# 容器
## 使用场景
开发一个杀手级的 Web 应用，它包含三个主要组件：React 前端、Python API 和 MySQL 数据库。如果你想开发这个项目，你必须安装 Node、Python 和 MySQL。

- **如何确保团队中开发人员使用的Python版本一致？**
- **如何确保应用运行所需的版本不和现有生产环境版本冲突？**

什么是容器？独立进程。React 前端、Python API、MySQL 都在独立的环境中运行，并与其他组件完全隔离。

## 容器和虚拟机
![img](01.docker介绍与安装/容器与虚拟机对比.png)

| **虚拟化**                                       | **容器**                                                |
| ------------------------------------------------ | ------------------------------------------------------- |
| 隔离性强，有独立的GUEST  OS                      | 共享内核和OS，隔离性弱!                                 |
| 虚拟化性能差(>15%)                               | 计算/存储无损耗，无Guest  OS内存开销(~200M)             |
| 虚拟机镜像庞大(十几G~几十G),  且实例化时不能共享 | Docker容器镜象200~300M，且公共基础镜象实例化时可以共享  |
| 虚拟机镜象缺乏统一标准                           | Docker提供了容器应用镜象事实标准，OCI推动进一  步标准化 |
| 虚拟机创建慢(>2分钟)                             | 秒级创建(<10s)相当于建立索引                            |
| 虚拟机启动慢(>30s)  读文件逐个加载               | 秒级(<1s,不含应用本身启动)                              |
| 资源虚拟化粒度低，单机10~100虚拟机               | 单机支持1000+容器密度很高，适合大规模的部署             |

**对比总结**
- **资源利用率更高**：一台物理机可以运行数百个容器，但一般只能运行数十个虚拟机。
- **开销更小**：不需要启动单独的虚拟机占用硬件资源。
- **启动速度更快**：可以在数秒内完成启动。

# 容器管理
## 创建容器
`Usage:  docker create [OPTIONS] IMAGE [COMMAND] [ARG...]`
```shell
[root@docker-server ~]# docker create -it --name nginx-test nginx bash
```

## 启动容器
`Usage:  docker start [OPTIONS] CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker start nginx
```

## 重启容器
`Usage:  docker restart [OPTIONS] CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker restart nginx
```

## 停止容器
`Usage:  docker stop [OPTIONS] CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker stop nginx
```

## 列出容器
`Usage:  docker ps [OPTIONS]`
```shell
[root@docker-server ~]# docker ps -a
```

## 运行容器
`Usage:  docker run [OPTIONS] IMAGE [COMMAND] [ARG...]`
```shell
# 等同于 create + start
[root@docker-server ~]# docker run -it centos:latest bash

# 指定DNS
[root@docker-server ~]# docker run -it --rm --dns 8.8.8.8 centos bash

# 端口映射
## 前台启动随机映射端口
[root@docker-server ~]# docker run -P nginx
## 方式1，本地端口80映射到容器80端口
[root@docker-server ~]# docker run -p 80:80 --name nginx-1 nginx:latest 
## 方式2，本地ip：本地端口：容器端口
[root@docker-server ~]# docker run -p 192.168.204.135:80:80 --name nginx-1 nginx:latest 
## 方式3，本地ip：本地随机端口：容器端口
[root@docker-server ~]# docker run -p 192.168.175.10::80 --name nginx-1 nginx:latest 
## 方式4，本地ip：本地端口：容器端口/协议默认为tcp协议
[root@docker-server ~]# docker run -p 192.168.175.10:80:80/tcp --name nginx-1 nginx:latest 
## 查看容器已经映射的端口
[root@docker-server ~]# docker port nginx-1

# 传递运行命令
[root@docker-server ~]# docker run -it centos:latest /bin/bash
[root@docker-server ~]# docker run -it centos:latest cat /etc/hosts

# 单次运行，容器退出后自动删除
[root@docker-server ~]# docker run --name hello_world_test --rm hello-world

# 后台运行
[root@docker-server ~]# docker run -d -P --name nginx-2 nginx
```

**参数说明：**

| 选项 | 说明 |
|:---|:---|
| -d | 以守护进程方式在后台运行容器。默认为否，适用于运行需要持续在线的服务 |
| -i | 保持标准输入打开，即使未连接也保持STDIN打开，常与-t一起使用 |
| -P | 通过NAT机制将容器标记暴露的端口自动映射到主机的随机临时端口 |
| -p | 手动指定容器端口映射，格式：主机(宿主)端口:容器端口 |
| -t | 分配一个伪终端（pseudo-TTY），通常与-i配合使用，以提供交互式shell |
| -v | 挂载主机上的文件卷到容器内，格式：主机目录:容器目录[:权限] |
| --rm | 容器退出后自动删除容器（不能与-d同时使用），适用于临时测试场景 |
| -e | 设置容器内的环境变量，格式：-e 变量名=变量值 |
| -h | 指定容器的主机名，便于容器间通过主机名访问 |
| --name | 指定容器的别名，方便管理和访问容器 |
| --cpu-shares | 设置容器使用CPU的相对权重（默认1024），数值越高优先级越高 |
| --cpuset-cpus | 限制容器使用特定的CPU核心，如：0-3（使用前4个核心）或0,2（使用第1、3核心） |
| -m | 限制容器可使用的最大内存量，支持的单位：b、k、m、g，如：-m 512m


## 挂起/恢复容器
`Usage:  docker pause CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker pause nginx-2
```
`Usage:  docker unpause CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker unpause nginx-2
```

## 进入容器
`Usage:  docker exec [OPTIONS] CONTAINER`
```shell
[root@docker-server ~]# docker exec -it nginx-2 bash
# attach不推荐: 所有使用此方式进入容器的操作都是同步显示的且exit容器将被关闭，且使用exit退出后容器关闭
[root@docker-server ~]# docker attach nginx-2
# nsenter: 通过pid进入到容器内部，不过可以使用docker inspect获取到容器的pid
[root@docker-server ~]# nsenter -t $(docker inspect -f "[.State.Pid]" nginx-2) -m -u -i -n -p
```

## 导入/导出容器
`Usage:  docker export [OPTIONS] CONTAINER`
```shell
[root@docker-server ~]# docker export -o /opt/nginx.tar nginx-2
```
`Usage:  docker import [OPTIONS] file|URL|- [REPOSITORY[:TAG]]`
```shell
[root@docker-server ~]# docker import /opt/nginx.tar nginx:v50
```

**适用场景：** 主要用来制作基础镜像，比如从一个ubuntu镜像启动一个容器，然后安装一些软件和进行一些设置后，使用docker export保存为一个基础镜像。然后把这个镜像分发给其他人使用，作为基础的开发环境。(因为export导出的镜像只会保留从镜像运行到export之间对文件系统的修改，所以只适合做基础镜像)

## 查看容器日志
`Usage:  docker logs [OPTIONS] CONTAINER`
```shell
[root@docker-server ~]# docker logs nginx-2
```

## 删除容器
`Usage:  docker rm [OPTIONS] CONTAINER [CONTAINER...]`
```shell
[root@docker-server ~]# docker rm -f nginx-2 
```