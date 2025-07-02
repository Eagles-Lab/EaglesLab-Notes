# 资源限制
默认情况下，容器没有资源限制，可以使用主机内核调度程序允许的尽可能多的给定资源，docker提供了控制容器可以限制容器使用多少内存或者cpu的方法，设置docker run命令的运行时配置标志。

其中一些功能要求宿主机的内核支持Linux功能，要检查支持，可以使用docker info命令，如果内核中禁用了某项功能，可能会在输出结尾处看到警告。

## cgroup介绍
在一个容器内部，如果不对其做任何资源限制，则宿主机会允许其占用无限大的内存空间，有时候会因为代码bug程序会一直申请内存，直到把宿主机内存占完，为了避免此类的问题出现，宿主机有必要对容器进行资源分配限制，比如cpu、内存等，Linux Cgroups的全称是Linux control Groups，它最重要的作用就是限制一个进程组能够使用的资源上线，包括cpu、内存、磁盘、网络等等。

## 开启cgroup功能
- 验证系统内核层已经默认开启cgroup功能
```bash
[root@docker-server ~]# cat /boot/config-3.10.0-957.el7.x86_64| grep cgroup -i
CONFIG_CGROUPS=y
# CONFIG_CGROUP_DEBUG is not set
CONFIG_CGROUP_FREEZER=y
CONFIG_CGROUP_PIDS=y
CONFIG_CGROUP_DEVICE=y
CONFIG_CGROUP_CPUACCT=y
CONFIG_CGROUP_HUGETLB=y
CONFIG_CGROUP_PERF=y
CONFIG_CGROUP_SCHED=y
CONFIG_BLK_CGROUP=y
# CONFIG_DEBUG_BLK_CGROUP is not set
CONFIG_NETFILTER_XT_MATCH_CGROUP=m
CONFIG_NET_CLS_CGROUP=y
CONFIG_NETPRIO_CGROUP=y
```

- 关于内存的模块
```bash
[root@docker-server ~]#  cat /boot/config-3.10.0-957.el7.x86_64 | grep mem -i | grep cg -i
CONFIG_MEMCG=y
CONFIG_MEMCG_SWAP=y
CONFIG_MEMCG_SWAP_ENABLED=y
CONFIG_MEMCG_KMEM=y
```

# 容器CPU限制
一个宿主机，有几十个核心的cpu，但是宿主机上可以同时运行成百上千个不同的进程用以处理不同的任务，多进程共用一个cpu的核心依赖计数就是为可压缩资源，即一个核心cpu可以通过调度而运行多个进程，但是在同一个单位时间内只能由一个进程在cpu上运行，那么这么多的进程怎么在cpu上执行和调度的呢？（进程优先级）

默认情况下，每个容器对主机cpu周期的访问权限是不受限制的，但是我们可以人为干扰。

## 相关参数说明

| 参数名 | 默认值 | 说明 | 使用建议 |
|--------|---------|------|----------|
| --cpus | 无限制 | 指定容器可使用的CPU核心数量。例如设置为1.5表示容器最多可使用1.5个CPU核心的计算能力。 | • 推荐使用此参数控制CPU使用<br>• 设置范围建议为0.1-核心总数<br>• 生产环境必须设置 |
| --cpu-period | 100000 | 设置CPU CFS调度周期(单位:微秒)。必须与--cpu-quota一起使用。 | • 不建议单独使用<br>• 建议使用--cpus替代<br>• 默认周期100ms适用大多数场景 |
| --cpu-quota | -1 | 设置CPU CFS配额(单位:微秒)。与--cpu-period配合使用,quota/period的值等效于--cpus的值。 | • 不建议单独使用<br>• 建议使用--cpus替代<br>• 仅在需要精细调度时使用 |
| --cpuset-cpus | 无限制 | 指定容器可以使用的CPU核心编号,如"0,2"表示只能使用0号和2号CPU核心。 | • 适用于CPU绑核场景<br>• 可提高缓存命中率<br>• 注意预留系统CPU资源 |
| --cpuset-mems | 无限制 | 指定容器使用的NUMA节点。仅在NUMA架构服务器中有效。 | • 仅用于NUMA架构<br>• 需了解硬件架构再使用<br>• 一般场景不建议使用 |
| --cpu-shares | 1024 | 设置CPU资源分配的权重值。在CPU竞争时,权重值越大获得更多CPU时间片。 | • 设置范围2-262144<br>• 仅在CPU竞争时有效<br>• 适合差异化CPU分配 |

> **最佳实践建议**：
> 1. 生产环境建议使用--cpus参数限制CPU使用
> 2. 按实际需求合理设置CPU限制,预留足够系统资源
> 3. 特殊场景(如CPU密集型)可考虑使用cpuset-cpus绑核
> 4. 避免过度限制导致容器性能问题

## 实践案例

### 案例1: CPU无限制

启动1个进程，占用4核cpu，未限制容器会把cpu全部占完

```bash
# 查看我们宿主机的cup数量
[root@localhost ~]# top
top - 21:32:49 up 43 min,  2 users,  load average: 3.54, 1.82, 0.80
Tasks: 186 total,   1 running, 185 sleeping,   0 stopped,   0 zombie
%Cpu0  :  0.0 us,  0.0 sy,  0.0 ni, 99.5 id,  0.0 wa,  0.5 hi,  0.0 si,  0.0 st
%Cpu1  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu2  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu3  :  0.0 us,  0.0 sy,  0.0 ni,100.0 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st

[root@localhost ~]# docker run -it --rm --name test1 tylersmith22/docker-stress-ng --vm 1 --cpu 4
stress-ng: info: [1] defaulting to a 86400 second run per stressor
stress-ng: info: [1] dispatching hogs: 4 cpu, 1 vm

# 新建窗口查看
[root@localhost ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O   PIDS
c6a795e4c09f   test1     396.78%   282.6MiB / 1.703GiB   16.21%    876B / 126B   0B / 0B     7

# 可以看出CPU的使用率大概是400% 因为我们是4个核心，单个核心跑满是100%
```

### 案例2: CPU限制

```bash
[root@localhost ~]# docker run -it --rm --cpus 2 --name test1 tylersmith22/docker-stress-ng --vm 1 --cpu 4
stress-ng: info: [1] defaulting to a 86400 second run per stressor
stress-ng: info: [1] dispatching hogs: 4 cpu, 1 vm

[root@localhost ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O       BLOCK I/O   PIDS
5b7dcb36d738   test1     200.65%   279.7MiB / 1.703GiB   16.04%    876B / 126B   0B / 0B     7

[root@localhost ~]# top
top - 21:36:15 up 47 min,  3 users,  load average: 1.38, 1.92, 1.05
Tasks: 198 total,   8 running, 190 sleeping,   0 stopped,   0 zombie
%Cpu0  : 50.7 us,  1.4 sy,  0.0 ni, 47.2 id,  0.0 wa,  0.7 hi,  0.0 si,  0.0 st
%Cpu1  : 52.9 us,  0.0 sy,  0.0 ni, 47.1 id,  0.0 wa,  0.0 hi,  0.0 si,  0.0 st
%Cpu2  : 50.7 us,  0.0 sy,  0.0 ni, 48.6 id,  0.0 wa,  0.7 hi,  0.0 si,  0.0 st
%Cpu3  : 50.4 us,  0.0 sy,  0.0 ni, 48.9 id,  0.0 wa,  0.7 hi,  0.0 si,  0.0 st

# 并且是平均使用所有的cup核心
```

### 案例3: CPU绑定

```bash
[root@localhost ~]# docker run -it --rm  --cpus 2 --cpuset-cpus 0,2 --name test1 tylersmith22/docker-stress-ng --vm 1 --cpu 4

[root@localhost ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O     BLOCK I/O         PIDS
ee11d834dde5   test1     186.68%   1.488GiB / 1.781GiB   83.60%    648B / 0B   44.8GB / 95.7MB   25

[root@localhost ~]# top
top - 21:38:25 up 49 min,  3 users,  load average: 0.92, 1.40, 0.96
Tasks: 197 total,   6 running, 191 sleeping,   0 stopped,   0 zombie
%Cpu0  : 97.3 us,  2.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.7 hi,  0.0 si,  0.0 st
%Cpu1  :  0.3 us,  0.0 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.0 hi,  0.3 si,  0.0 st
%Cpu2  : 98.3 us,  1.0 sy,  0.0 ni,  0.0 id,  0.0 wa,  0.7 hi,  0.0 si,  0.0 st
%Cpu3  :  0.0 us,  0.3 sy,  0.0 ni, 99.3 id,  0.0 wa,  0.3 hi,  0.0 si,  0.0 st
MiB Mem :   1743.4 total,    457.2 free,    924.2 used,    531.4 buff/cache
MiB Swap:   2048.0 total,   2047.2 free,      0.8 used.    819.2 avail Mem
```

- 基于cpu-shares对cpu进行切分

```bash
[root@localhost ~]# docker run -it --rm  -d --cpu-shares 1000 --name test1 tylersmith22/docker-stress-ng --vm 1 --cpu 4
[root@localhost ~]# docker run -it --rm  -d --cpu-shares 500 --name test2 tylersmith22/docker-stress-ng --vm 1 --cpu 4

[root@localhost ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O     BLOCK I/O       PIDS
d6dd34edb722   test1     543.41%   819.6MiB / 1.781GiB   44.95%    648B / 0B   102MB / 154MB   13
154b07a94e2f   test2     241.15%   711.1MiB / 1.781GiB   39.00%    648B / 0B   406MB / 145MB
```


# 容器MEM限制
## OOM异常
对于Linux主机，如果没有足够的内存来执行其他重要的系统任务，将会抛出OOM异常（内存溢出、内存泄漏、内存异常），随后系统会开始杀死进程以释放内存，凡是运行在宿主机的进程都有可能被kill，包括dockerd和其他的应用程序，如果重要的系统进程被kill，会导致和该进程相关的服务全部宕机。

产生OOM异常时，Dockerd尝试通过调整docker守护程序上的OOM优先级来减轻这些风险，以便它比系统上的其他进程更不可能被杀死，但是容器的OOM优先级未调整时单个容器被杀死的可能性更大（不推荐调整容器的优先级这种方式）。

## OOM评分机制
Linux会为每个进程计算一个分数，最终会将分数最高的进程kill掉。相关参数说明如下:

| 参数名 | 取值范围 | 说明 | 使用建议 |
|--------|----------|------|----------|
| oom_score_adj | -1000 到 1000 | 用于调整进程的OOM评分。值越高，进程在内存不足时越容易被kill。设置为-1000时进程永远不会被kernel kill。 | • 关键系统进程建议设置较低值<br>• 非关键应用可保持默认值<br>• 谨慎使用-1000，可能导致系统不稳定 |
| oom_adj | -17 到 +15 | 旧版本参数，用于调整进程被kill的优先级。值越高越容易被kill，-17表示不能被kill。 | • 建议使用oom_score_adj替代<br>• 仅为了兼容旧版本内核<br>• 不推荐在新系统中使用 |
| oom_score | 系统计算得出 | 系统根据进程的内存使用量、CPU时间、运行时长和oom_adj综合计算的得分。得分越高越容易被kill。 | • 用于监控进程的OOM风险<br>• 定期检查高内存占用进程<br>• 发现异常及时优化或限制 |

> **最佳实践建议**：
> 1. 为关键进程适当降低OOM评分，避免被意外kill
> 2. 定期监控高内存进程的oom_score
> 3. 合理规划内存使用，避免触发OOM
> 4. 使用容器时建议设置内存限制

## 相关参数说明

| 参数名 | 说明 | 默认值 | 使用建议 |
|--------|------|--------|----------|
| -m 或 --memory | 容器可使用的最大物理内存量 | 无限制 | • 最小值为4m<br>• 建议根据应用实际需求设置<br>• 生产环境必须设置 |
| --memory-swap | 容器可使用的交换分区和物理内存总和 | -1 (不限制) | • 需要先设置-m参数<br>• 频繁交换会影响性能<br>• 建议生产环境禁用swap |
| --memory-swappiness | 容器使用交换分区的倾向性 | 继承主机设置 | • 范围0-100<br>• 0表示尽量不使用swap<br>• 生产环境建议设为0 |
| --kernel-memory | 容器可使用的最大内核内存量 | 无限制 | • 最小值为4m<br>• **不建议使用**<br>• 可能导致主机资源阻塞 |
| --memory-reservation | 内存软限制(小于--memory) | 无限制 | • 系统内存紧张时激活<br>• 作为内存使用预警<br>• 建议设置为--memory的80% |
| --oom-kill-disable | 禁止OOM时杀死容器进程 | false | • 仅在设置-m时有效<br>• 需谨慎使用<br>• 建议保持默认值 |

> **最佳实践建议**：
> 1. 生产环境必须设置-m参数限制内存使用
> 2. 建议禁用或限制swap使用
> 3. 合理设置memory-reservation作为预警
> 4. 谨慎使用kernel-memory和oom-kill-disable

## 实践案例
如果一个容器未作内存使用限制，则该容器可以利用到系统内存最大空间，默认创建的容器没有做内存资源限制

### 案例1: MEM无限制
- 拉取容器压测工具镜像
```bash
[root@docker-server1 ~]# docker pull lorel/docker-stress-ng
[root@docker-server1 ~]# docker run -it --rm lorel/docker-stress-ng -help
```

- 使用压测工具开启两个工作进程，每个工作进程最大允许使用内存256M，且宿主机不限制当前容器的最大内存

```bash
[root@docker-server1 ~]# docker run -it --rm --name test1 lorel/docker-stress-ng --vm 2 --vm-bytes 256m
stress-ng: info: [1] defaulting to a 86400 second run per stressor
stress-ng: info: [1] dispatching hogs: 2 vm

[root@docker-server1 ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT     MEM %     NET I/O     BLOCK I/O   PIDS
3ca32774fc20   test1     185.16%   514.3MiB / 1.781GiB   28.21%    648B / 0B   0B / 0B     5

```

### 案例2: MEM限制
- 宿主机限制最大内存使用

```bash
[root@docker-server1 ~]# docker run -it --rm -m 256m --name test2 lorel/docker-stress-ng --vm 2 --vm-bytes 256m
[root@docker-server1 ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O         PIDS
bfff488e6185   test1     169.76%   255.8MiB / 256MiB   99.91%    648B / 0B   3.53GB / 10.6GB   5
```

- 可以通过修改cgroup文件值来扩大内存限制，缩小会报错

```bash
[root@docker-server1 ~]# cat /sys/fs/cgroup/memory/docker/bfff488e618580b227b5411c91b35517850e95af2ac2225b45180937c14e70c2/memory.limit_in_bytes 
```

**内存软限制**

软限制不会真正限制到内存的使用

```bash
[root@docker-server1 ~]# docker run -it --rm -m 256m --memory-reservation 128m --name test1 lorel/docker-stress-ng --vm 2 --vm-bytes 256m
[root@docker-server1 ~]# docker stats
CONTAINER ID   NAME      CPU %     MEM USAGE / LIMIT   MEM %     NET I/O     BLOCK I/O         PIDS
0ffb4b8fdbde   test1     174.52%   255.9MiB / 256MiB   99.95%    648B / 0B   5.33GB / 18.1GB   5
```

**交换分区限制**

```bash
[root@docker-server1 ~]# docker run -it --rm -m 256m --memory-swap 512m --name test1 lorel/docker-stress-ng --vm 2 --vm-bytes 256m
```
