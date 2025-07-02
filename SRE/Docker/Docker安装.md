# Docker服务端软件选择
Docker CE（Community Edition，社区版）和 Docker EE（Enterprise Edition，企业版）是 Docker 产品的两个主要版本，它们之间的主要区别在于目标用户、功能集、支持和维护等方面：

| 对比项 | Docker CE | Docker EE |
|--------|-----------|------------|
| **目标用户** | 面向个人开发者、小团队以及技术爱好者，主要用于开发和测试环境 | 面向大型企业和组织，提供企业级的功能和支持 |
| **功能集** | 提供基本的容器化功能，包括构建、运行和共享容器 | 除了包含 CE 版本的所有功能外，还提供了额外的企业级特性，如增强的安全、管理、可扩展性和集成性 |
| **支持和维护** | 社区支持，适合自我解决问题的开发者 | 提供商业支持和专业服务，适合需要稳定运行环境的企业 |
| **安全性** | 安全性相对较低，适合非生产环境 | 提供更高级的安全特性，如镜像扫描、安全策略和合规性报告 |
| **管理** | 通常不需要复杂的管理工具 | 提供 Docker Universal Control Plane (UCP) 和 Docker Trusted Registry (DTR) 等管理工具，帮助企业更有效地管理容器环境 |
| **成本** | 免费 | 需要购买许可证 |
| **更新和生命周期** | 更新频繁，可能包含实验性功能，生命周期较短 | 更新周期更稳定，更注重稳定性和兼容性，生命周期较长 |

# Docker快速安装
```shell
[root@docker-server ~]# chmod +x install_docker_ce.sh
[root@docker-server ~]# ./install_docker_ce.sh
```

# Docker快速使用
```shell
# 拉取镜像
[root@docker-server ~]# docker pull nginx
# 启动容器
[root@docker-server ~]# docker run --name nginx_container_test -d -p 8080:80 nginx
# 进入容器
[root@docker-server ~]# docker exec -it nginx_container_test bash
echo 'docker nginx test' > /usr/share/nginx/html/index.html
curl 192.168.88.10:8080
# 查看容器
[root@docker-server ~]# docker ps
# 停止容器
[root@docker-server ~]# docker stop nginx_container_test
```

# Docker信息
```bash
[root@docker-server ~]# docker info 
```

| 配置项 | 说明 |
|--|--|
| **容器状态信息** ||
| Containers | 系统中所有容器的总数。包括运行中、已暂停和已停止的容器，用于整体容器资源评估 |
| Running | 当前正在运行的容器数量。这些容器正常运行并提供服务，是系统负载的主要来源 |
| Paused | 已暂停运行的容器数量。这些容器状态被临时冻结，通常用于调试或资源回收 |
| Stopped | 已停止运行的容器数量。这些容器可能是任务完成或异常停止，需要定期清理 |
| **系统基础信息** ||
| Images | 本地已下载的Docker镜像总数。包括基础镜像、中间镜像和应用镜像，影响存储空间使用 |
| Server Version | Docker引擎版本号。决定了可用特性和兼容性，建议在生产环境保持版本统一 |
| **存储相关配置** ||
| Storage Driver | 容器存储驱动类型（如overlay2、devicemapper）。影响容器I/O性能，推荐使用overlay2 |
| Backing Filesystem | 底层文件系统类型（如ext4、xfs）。影响存储性能和可靠性，生产环境推荐使用xfs |
| Supports d_type | 文件系统d_type支持状态。对overlay2驱动至关重要，确保启用以获得最佳性能 |
| Native Overlay Diff | 原生Overlay差异存储支持。优化镜像层存储效率，减少磁盘空间占用 |
| **日志与资源管理** ||
| Logging Driver | 容器日志收集驱动（如json-file、syslog）。影响日志管理和问题排查能力 |
| Cgroup Driver | 容器资源限制驱动（systemd/cgroupfs）。建议与系统init保持一致，避免资源管理冲突 |
| **功能组件信息** ||
| Plugins | Docker插件列表。包括存储、网络等扩展功能，按需启用以增强系统能力 |
| Volume | 数据卷插件配置。用于持久化存储和容器间数据共享，确保数据可靠性 |
| Network | 网络驱动类型。支持bridge、host、overlay等模式，根据应用场景选择 |
| **运行时与安全** ||
| Default Runtime | 默认容器运行时（通常为runc）。可选择其他OCI兼容运行时以满足特定需求 |
| Security Options | 安全特性配置。包括AppArmor、SELinux等，建议在生产环境中启用以增强安全性 |
| **系统资源信息** ||
| Kernel Version | 内核版本信息。影响Docker功能和性能，建议使用推荐的内核版本 |
| Operating System | 操作系统信息。包括发行版和版本号，影响兼容性和可用特性 |
| Architecture | CPU架构类型。如x86_64、arm64，决定可用的容器镜像类型 |
| CPUs | 可用CPU核心数。影响容器并发能力，建议预留部分资源给系统使用 |
| Total Memory | 系统总内存。决定可分配给容器的最大内存，建议合理规划以避免资源竞争 |
| **其他配置** ||
| Docker Root Dir | Docker运行时根目录。存储容器和镜像数据，建议使用单独分区 |
| Registry | 默认镜像仓库地址。用于拉取和推送镜像，可配置私有仓库加速访问 |
| Experimental | 实验特性状态。包含未稳定功能，生产环境谨慎启用 |
| Live Restore Enabled | 是否启用容器存活恢复功能，允许在Docker守护进程重启时保持容器运行|


# 标准化组织OCI
容器技术是一种轻量级的虚拟化技术，用于隔离应用程序及其依赖项，使其能够在不同的环境中一致地运行。除了 Docker 之外，还有其他多种容器运行时和工具，例如 CoreOS 的 rkt、阿里的 Pouch 和红帽的 Podman。为了确保容器生态系统的标准性和可持续发展，Linux 基金会、Docker、微软、红帽、谷歌和 IBM 等公司在 2015 年 6 月共同成立了 **Open Container Initiative (OCI)** 组织。

## OCI目标

OCI 的主要目标是制定开放的容器规范，以确保不同容器技术之间的可移植性和互操作性。目前，OCI 已经发布了两个核心规范：

1. **Runtime Spec**：定义了容器运行时的规范，包括容器的生命周期管理、资源隔离和安全等。
2. **Image Format Spec**：定义了容器镜像的格式和元数据，确保镜像可以在不同的容器运行时之间共享和运行。

通过遵循这些规范，不同的容器运行时和工具可以实现互操作性，从而推动容器技术的标准化和健康发展。

## 容器运行时

容器运行时是真正运行容器的地方，它需要与操作系统的内核紧密合作，为容器提供隔离的运行环境。以下是目前主流的三种容器运行时：

**1. LXC (Linux Containers)**

- **简介**：LXC 是 Linux 上早期的容器运行时，它利用 Linux 内核的 Namespace 和 Cgroups 技术来实现进程隔离和资源管理。
- **特点**：
  - 提供了完整的 Linux 系统环境，支持多种 Linux 发行版。
  - 早期 Docker 也曾使用 LXC 作为其默认的运行时。
- **适用场景**：适用于需要完整 Linux 系统环境的容器化应用。

**2. Runc**

- **简介**：Runc 是目前 Docker 默认的容器运行时，它是一个轻量级的命令行工具，用于运行和管理容器。
- **特点**：
  - 完全遵循 OCI 的 Runtime Spec 规范，确保与 OCI 标准的兼容性。
  - 由于其轻量级和高性能的特点，Runc 已经成为许多容器运行时的底层实现。
- **适用场景**：适用于需要高性能和轻量级容器运行环境的场景。

**3. Rkt (Rocket)**

- **简介**：Rkt 是由 CoreOS 开发的容器运行时，旨在提供一个安全、可靠且符合 OCI 规范的容器运行环境。
- **特点**：
  - 与 Docker 不同，Rkt 本身是一个独立的容器运行时，不依赖 Docker 的守护进程。
  - 提供了更好的安全性和隔离性，例如通过 AppArmor 和 SELinux 等安全机制。
- **适用场景**：适用于对安全性要求较高的容器化应用。

容器技术的发展离不开标准化的推动。OCI 通过制定 Runtime Spec 和 Image Format Spec，为容器运行时和工具提供了统一的标准，确保了不同容器技术之间的互操作性和可移植性。目前主流的容器运行时（如 LXC、Runc 和 Rkt）都遵循这些规范，从而推动了容器技术的广泛应用和发展。

