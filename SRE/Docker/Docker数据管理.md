# 存储
## 介绍
默认情况下，容器内创建的所有文件都存储在可写的容器层上，该层位于只读、不可变的图像层之上。

写入容器层的数据在容器销毁后不会保留。这意味着，如果其他进程需要这些数据，则很难将其从容器中取出。

每个容器的可写层都是唯一的。无法将数据从可写层提取到主机或其他容器。

## 存储挂载选项

| 挂载类型 | 说明 | 使用场景 | 特点 |
|:---------|:-----|:---------|:-----|
| Volume Mounts | Docker管理的持久化数据卷，存储在/var/lib/docker/volumes/目录下 | 数据库存储、应用数据持久化 | 独立于容器生命周期、可在容器间共享、支持数据备份和迁移 |
| Bind Mounts | 将宿主机目录或文件直接挂载到容器内 | 开发环境代码热更新、配置文件挂载 | 方便直接操作文件、依赖宿主机文件系统、适合开发调试 |
| Tmpfs Mounts | 将数据临时存储在宿主机内存中 | 敏感数据存储、临时文件存储 | 高性能、数据易失性、增加内存占用 |
| Named Pipes | 在容器间建立命名管道进行通信 | 容器间进程通信、数据流传输 | 低延迟、进程间通信、适合流式数据传输 |

# Volume mounts
## 管理操作
`Usage:  docker volume create [OPTIONS] [VOLUME]`
`Usage:  docker volume ls [OPTIONS]`
`Usage:  docker volume inspect [OPTIONS] VOLUME [VOLUME...]`
`Usage:  docker volume rm [OPTIONS] VOLUME [VOLUME...]`
`Usage:  docker volume prune [OPTIONS]`
```shell

```

## 使用卷启动容器
如果使用不存在的卷启动容器，Docker 会为创建该卷。

`Usage:  docker run --mount type=volume[,src=<volume-name>],dst=<mount-path>[,<key>=<value>...]`

| 参数 | 说明 | 使用示例 | 最佳实践 |
|:---------|:-----|:---------|:---------|
| source, src | 卷的名称，用于指定要挂载的数据卷 | `src=myvolume` | 使用有意义的名称便于识别和管理 |
| target, dst | 容器内的挂载路径，指定数据卷挂载到容器内的位置 | `dst=/data/app` | 遵循容器内标准目录结构 |
| type | 卷的类型，可选值：volume、bind、tmpfs，默认为volume | `type=volume` | 根据数据持久化需求选择合适类型 |
| readonly, ro | 只读挂载标志，设置后容器内无法修改挂载内容 | `ro=true` | 对配置文件等静态内容建议只读挂载 |
| volume-subpath | 卷的子路径，只挂载数据卷中的指定子目录 | `volume-subpath=/config` | 用于精确控制挂载范围，提高安全性 |
| volume-opt | 卷的额外选项，用于指定卷的特定行为 | `volume-opt=size=10G` | 根据实际需求配置，避免过度使用 |
| volume-nocopy | 创建卷时不从容器复制数据 | `volume-nocopy=true` | 用于避免不必要的数据复制，提高性能 |

```shell
docker run -d --name devtest --mount source=myvol2,target=/app nginx:latest
```

`Usage:  docker run -v [<volume-name>:]<mount-path>[:opts]`
```shell
docker run -d --name devtest -v myvol2:/app nginx:latest
```

## 实践案例
**需求**：运行MySQL容器并支持久化存储，进行一次数据备份，数据恢复测试验证。

```shell

```

# Bind mounts
使用绑定挂载时，主机上的文件或目录将从主机挂载到容器中。

如果将目录绑定挂载到容器上的非空目录中，则目录的现有内容被绑定挂载隐藏。

## 使用绑定挂载启动容器
```shell
Usage: 
docker run --mount type=bind,src=<host-path>,dst=<container-path>[,<key>=<value>...]
docker run -v <host-path>:<container-path>[:opts]
```

| 参数 | 说明 | 使用场景 | 最佳实践 |
|:---------|:-----|:---------|:---------|
| readonly, ro | 将挂载点设置为只读模式，容器内无法修改挂载的内容 | 配置文件、静态资源文件挂载 | 对于不需要容器内修改的内容，建议使用只读模式增加安全性 |
| rprivate | 使挂载点的挂载事件不会传播到其他挂载点 | 默认的挂载传播模式 | 适用于大多数场景，确保挂载隔离性 |
| rshared | 使挂载点的挂载事件双向传播 | 需要在多个挂载点间共享挂载事件的场景 | 谨慎使用，可能影响容器隔离性 |
| rslave | 使挂载点的挂载事件单向传播（从主机到容器） | 需要容器感知主机挂载变化的场景 | 在特定场景下使用，如动态存储管理 |
| rbind | 递归绑定挂载，包含所有子目录 | 需要完整复制目录结构的场景 | 确保目录结构完整性，但注意性能开销 |


## 实践案例
**需求**：启动Nginx容器并挂载宿主机nginx配置文件和主页目录，容器内无权限修改相关内容，测试验证。

```shell

```

# 扩展阅读
tmpfs mounts: https://docs.docker.com/engine/storage/tmpfs/

volumes plugins: https://docs.docker.com/engine/extend/legacy_plugins/