# 存储引擎
Docker 存储引擎是 Docker 容器管理文件系统的核心组件，负责镜像层与容器层的组织、读写操作及资源隔离。其核心在于通过​​联合文件系统（UnionFS）​​和​​写时复制（Copy-on-Write, CoW）​​机制实现高效存储管理。

## 分层存储与联合挂载
Docker镜像由多个只读层（Layer）叠加而成，容器运行时会在镜像层之上创建可写层。所有层通过 UnionFS 联合挂载到同一视图，上层文件覆盖下层同名文件，但底层数据保持不变。

UnionFS（联合文件系统）是一种分层、轻量级且高性能的文件系统技术，通过将多个目录（分支）联合挂载到同一目标目录，形成统一的文件系统视图。核心机制如下:
- **分层存储**：UnionFS 通过分层结构管理文件，每个层（分支）可以是只读或可写。不同层中相同路径的文件会被上层覆盖，但底层内容保持不变。
- **只读层和可写层**：只读层​​通常为基础镜像或依赖文件，不可修改；可写层​​：容器运行时新增的层，所有修改均在此层记录。

## 写时复制（CoW）机制
当容器需要修改文件时，存储引擎将文件从底层只读层复制到可写层进行修改，而非直接修改原始数据。这种机制减少冗余存储，允许多容器共享同一镜像层，显著降低磁盘占用。

## 工作原理
- **联合挂载（Unio Mount）**：将多个物理目录（如目录A和B）挂载到同一虚拟目录（如目录C），合并后的视图包含所有分支目录的内容。若存在同名文件，优先显示上层文件。
- **访问优先级**：用户访问文件时，UnionFS按层从上至下搜索，返回第一个匹配的文件。例如，可写层优先级高于只读层。
- **数据隔离与共享**：不同容器共享同一基础镜像层，但各自的可写层独立，实现资源复用与运行时隔离。

# 主流存储引擎
Docker支持多种存储驱动，不同驱动在性能、稳定性、适用场景上存在差异：

| 存储驱动 | 特点 | 优势 | 局限性 | 适用场景 |
|---------|------|------|--------|----------|
| OverlayFS | • Linux内核原生支持（≥3.18）<br>• 使用overlay2驱动<br>• 仅需一个只读层和一个可写层<br>• 结构简单且性能优异 | • 启动速度快<br>• 适合生产环境<br>• 支持高效的文件系统层叠<br>• 节省存储空间 | • 层数限制（通常≤127层）<br>• 频繁小文件写入可能增加I/O开销 | • 通用容器环境<br>• 需要高性能的生产系统<br>• 对存储空间敏感的场景 |
| AUFS | • 通过多层联合挂载实现CoW<br>• 稳定性较好<br>• 未集成到内核，需额外安装 | • 内存利用率高<br>• 适合旧版Linux系统 | • 高并发写入性能较差<br>• 逐渐被OverlayFS替代 | • 旧版Linux系统<br>• 对内存资源敏感的环境<br>• 低并发写入场景 |
| Device Mapper | • 基于块设备映射<br>• 使用"thin pool"技术<br>• 支持动态扩容 | • 支持精细的存储控制<br>• 适合块级存储需求<br>• 动态扩容能力强 | • 配置复杂<br>• 需预分配存储池<br>• 可能导致空间浪费 | • 数据库容器<br>• 需要精细存储控制的场景<br>• 大规模存储系统 |
| Btrfs/ZFS | • 支持高级功能（快照/去重/压缩）<br>• 文件系统级别的功能丰富 | • Btrfs写入密集型场景表现优异<br>• ZFS提供数据完整性校验<br>• 支持高效压缩 | • 对系统内核版本依赖性强<br>• 稳定性与兼容性需验证 | • 需要数据快照功能<br>• 写入密集型应用<br>• 对数据完整性要求高的场景 |

# Overlay2
## 工作原理
Docker 默认存储驱动。通过以下三个主要目录来管理文件系统：
- **`LowerDir`**：只读层，包含基础镜像的文件系统。可以有多个只读层，每层都是独立的。
- **`UpperDir`**：读写层，用于存储容器运行时的文件系统变更（即 diff 层）。
- **`MergedDir`**：联合挂载后的视图，容器看到的完整文件系统。它将 `LowerDir` 和 `UpperDir` 合并为一个统一的文件系统视图。
- **`WorkDir`**：是系统内部使用的临时目录，用于处理​写时复制（CoW）​​和元数据操作。其内容在挂载时会被清空，且运行时不可见，一般不要动。

当启动一个容器时，Overlay2 会将镜像层（`LowerDir`）和容器层（`UpperDir`）联合挂载到 `MergedDir`，容器通过这个目录看到完整的文件系统。

## 实践案例1
通过 Overlay2 挂载目录，理解镜像层与容器层的交互逻辑。
```shell
# 1.目录结构 & 文件
mkdir -p /mnt/overlay2/{lower,upper,work,merged}
echo "基础文件内容" > /mnt/overlay2/lower/base.txt
echo "初始配置" > /mnt/overlay2/lower/config.yaml
# 2.挂载Overlay2
mount -t overlay overlay \
  -o lowerdir=/mnt/overlay2/lower,upperdir=/mnt/overlay2/upper,workdir=/mnt/overlay2/work \
  /mnt/overlay2/merged
# 3.模拟容器操作
echo "容器修改内容" > /mnt/overlay2/merged/base.txt
## CoW机制生效
[root@master01 ~]# cat /mnt/overlay2/upper/base.txt
容器修改内容
[root@master01 ~]# cat /mnt/overlay2/lower/base.txt
基础文件内容
## 文件名 #40b 是 OverlayFS 在处理文件操作时生成的临时标识符，用于跟踪操作状态
rm /mnt/overlay2/merged/config.yaml

# 卸载并清理
umount /mnt/overlay2/merged
rm -rf /mnt/overlay2/*
```

## 实践案例2
验证运行容器的存储结构，并能快速定位。
```shell
# LowerDir、MergedDir、UpperDir、WorkDir
[root@master01 ~]# docker inspect 379c14648fbb
[root@master01 ~]# docker exec -it 3eb8f9c95ab4 touch /root/1.txt
[root@master01 ~]# ls /var/lib/docker/overlay2/869a09f00704dbbb396d8be90d52b73870073c0a294deceac24a69afbe1a4310/diff/root/
1.txt
```

# 扩展阅读
存储引擎文档：
https://docs.docker.com/storage/storagedriver/select-storage-driver/

存储引擎血案：
https://www.cnblogs.com/youruncloud/p/5736718.html