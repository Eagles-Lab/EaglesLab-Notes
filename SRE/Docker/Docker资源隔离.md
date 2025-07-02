# Linux namespace技术
如果一个宿主机运行了N个容器，多个容器带来的以下问题怎么解决：
1. 怎么样保证每个容器都有不同的文件系统并且能互不影响？
2. 一个docker主进程内的各个容器都是其子进程，那么如何实现同一个主进程下不同类型的子进程？各个子进程间通信能相互访问吗？
3. 每个容器怎么解决IP以及端口分配的问题？
4. 多个容器的主机名能一样吗？
5. 每个容器都要不要有root用户？怎么解决账户重名问题呢？

**解决方案**：
namespace 是 Linux 系统的底层概念，在内核层实现，即有一些不同类型的命名空间都部署在核内，各个容器运行在同一个docker主进程并且共用同一个宿主机系统内核，各个docker容器运行在宿主机的用户空间，每个容器都要有类似于虚拟机一样的相互隔离的运行空间，但是容器技术是在一个进程内实现运行指定服务的运行环境，并且还可以保护宿主机内核不受其他进程的干扰和影响，如文件系统、网络空间、进程空间等。


| 隔离类型 | 功能说明 | 系统调用参数 | 内核版本 | 应用场景 |
| :--- | :--- | :--- | :--- | :--- |
| MNT Namespace（mount） | 提供磁盘挂载点和文件系统的隔离能力，使容器拥有独立的文件系统层次结构 | CLONE_NEWNS | 2.4.19 | 容器镜像管理、数据卷挂载、持久化存储 |
| IPC Namespace（Inter-Process Communication） | 提供进程间通信的隔离能力，确保容器内进程通信安全 | CLONE_NEWIPC | 2.6.19 | 容器内消息队列、共享内存、信号量隔离 |
| UTS Namespace（UNIX Timesharing System） | 提供主机名和域名的隔离能力，使容器拥有独立的主机标识 | CLONE_NEWUTS | 2.6.19 | 容器主机名管理、集群服务发现 |
| PID Namespace（Process Identification） | 提供进程隔离能力，实现容器内进程树独立管理 | CLONE_NEWPID | 2.6.24 | 容器进程管理、应用程序运行时隔离 |
| Net Namespace（network） | 提供网络栈的隔离能力，包括网络设备、IP地址、路由表等 | CLONE_NEWNET | 2.6.29 | 容器网络配置、跨主机通信、服务端口映射 |
| User Namespace（user） | 提供用户和用户组的隔离能力，增强容器安全性 | CLONE_NEWUSER | 3.8 | 容器权限控制、用户映射、安全策略管理 |

# MNT Namespace
提供磁盘挂载点和文件系统的隔离能力，使容器拥有独立的文件系统层次结构。
```bash
# 在容器内挂载 tmpfs 文件系统
docker run -it --rm ubuntu bash
mkdir /mnt/tmpfs
mount -t tmpfs -o size=100M tmpfs /mnt/tmpfs
# 宿主机上无法看到此挂载点
df -h
```

# IPC Namespace
提供进程间通信的隔离能力，确保容器内进程通信安全。
```shell
# 容器A创建共享内存段
docker run -it --name shm1 --rm ubuntu bash
ipcmk -M 64M  # 返回共享内存 ID（如 0）

# 容器B无法访问
docker run -it --name shm2 --rm ubuntu bash
ipcs -m  
```

# UTS Namespace
提供主机名和域名的隔离能力，使容器拥有独立的主机标识。
```shell
# 启动容器并设置主机名
docker run -it --hostname=myapp --rm ubuntu bash
hostname
```

# PID Namespace
提供进程隔离能力，实现容器内进程树独立管理。
```shell
# 查看当前宿主机所有进程
# 查看当前容器内所有进程
```

**那么宿主机的PID与容器内的PID是什么关系？**
1. **独立的 PID 命名空间**:
   - 每个 Docker 容器都有自己独立的 PID 命名空间。
   - 容器内的进程 PID 从 1 开始编号,与宿主机上的 PID 是相互独立的。
2. **PID 映射**:
   - 容器内的进程 PID 与宿主机上的进程 PID 之间是有映射关系的。
   - 通过 `docker inspect <container_id>` 命令,可以查看容器内进程的 PID 与宿主机上进程 PID 的对应关系。
3. **PID 可见性**:
   - 容器内的进程只能看到容器内部的 PID。
   - 宿主机上的进程可以看到容器内部的 PID,但容器内的进程无法看到宿主机上的 PID。
4. **PID 隔离**:
   - 容器内的进程无法访问或影响宿主机上的其他进程。
   - 宿主机上的进程可以访问和管理容器内的进程。

# Net Namespace
提供网络栈的隔离能力，包括网络设备、IP地址、路由表等。参考`08.Docker网络管理`

# User Namespace
提供用户和用户组的隔离能力，增强容器安全性。
```shell
# A容器创建用户在B容器里不可见
```