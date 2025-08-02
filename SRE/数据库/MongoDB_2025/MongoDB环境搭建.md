# 环境搭建

本章将详细介绍如何在 Rocky Linux 操作系统上安装和配置 MongoDB，以及如何管理 MongoDB 服务。正确的环境搭建是后续学习的基础。

---

## 安装部署

基于 Rocky Linux 9 系统上，推荐使用 `yum` 或 `dnf` 包管理器通过官方源进行安装，这样可以确保安装的是最新稳定版本，并且便于后续更新。

**步骤 1: 配置 MongoDB 的 YUM/DNF 仓库**

创建一个 `/etc/yum.repos.d/mongodb-org-7.0.repo` 文件，并添加以下内容：

```ini
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
```

**步骤 2: 安装 MongoDB**

执行以下命令安装 MongoDB 数据库及其相关工具：

```shell
# 清理缓存并安装
yum install -y mongodb-org
```

这个命令会安装以下几个包：
- `mongodb-org-server`: `mongod` 守护进程、配置文件和初始化脚本。
- `mongodb-org-mongos`: `mongos` 守护进程。
- `mongodb-mongosh`: MongoDB Shell (`mongosh`)。
- `mongodb-org-tools`: MongoDB 的命令行工具，如 `mongodump`, `mongorestore`, `mongoimport`, `mongoexport` 等。

---

## 相关配置

MongoDB 的主配置文件位于 `/etc/mongod.conf`，默认的配置文件采用 YAML 格式。以下是一些核心配置项的说明：

```yaml
# mongod.conf

# 存储设置
storage:
  dbPath: /var/lib/mongo  # 数据文件存放目录
  journal:
    enabled: true      # 是否启用 journal 日志，建议始终开启

# 系统日志设置
systemLog:
  destination: file      # 日志输出到文件
  logAppend: true        # 日志以追加方式写入
  path: /var/log/mongodb/mongod.log  # 日志文件路径

# 网络设置
net:
  port: 27017            # 监听端口
  bindIp: 127.0.0.1      # 绑定的 IP 地址，默认为本地回环地址。如需远程访问，可设置为 0.0.0.0

# 进程管理
processManagement:
  timeZoneInfo: /usr/share/zoneinfo # 时区信息

# 安全设置 (默认禁用)
#security:
#  authorization: enabled # 启用访问控制
```

- **`storage.dbPath`**: MongoDB 数据文件的存储路径，需要确保 `mongod` 用户对此目录有读写权限。
- **`systemLog.path`**: 日志文件路径，用于记录数据库的操作和错误信息。
- **`net.bindIp`**: 这是非常重要的安全配置。默认 `127.0.0.1` 只允许本机连接。如果需要从其他服务器连接，应谨慎地将其设置为服务器的内网 IP 或 `0.0.0.0`（监听所有网络接口），并配合防火墙和安全组规则使用。

---

## 服务管理

在现代 Linux 系统中，我们使用 `systemd` 来管理 `mongod` 服务。

```shell
# 启动 MongoDB 服务
systemctl start mongod
# 查看服务状态
systemctl status mongod
# 停止 MongoDB 服务
systemctl stop mongod
# 重启 MongoDB 服务
systemctl restart mongod
# 启用开机自启动
systemctl enable mongod
# 禁用开机自启动
systemctl disable mongod
```

## 生产配置

这是一个更贴近生产环境的配置文件示例，增加了安全和性能相关的配置。

```yaml
# /etc/mongod.conf - Production Example

storage:
  dbPath: /var/lib/mongo
  journal:
    enabled: true
  engine: wiredTiger
  wiredTiger:
    engineConfig:
      cacheSizeGB: 1  # 根据服务器内存调整，建议为物理内存的 50% - 60%

systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log

net:
  port: 27017
  bindIp: 127.0.0.1,192.168.1.100 # 绑定本地和内网 IP
  maxIncomingConnections: 1000 # 最大连接数

processManagement:
  fork: true # 后台运行
  pidFilePath: /var/run/mongodb/mongod.pid
  timeZoneInfo: /usr/share/zoneinfo

security:
  authorization: enabled # 开启认证

replication:
  replSetName: rs0 # 副本集名称
```

## 实践操作

### 需求描述

1.  使用 `root` 用户安装并正常运行
2.  更改数据目录 `dbPath` 为 `/data/mongodb`
3.  更改监听地址 `bindIp` 为 `0.0.0.0`

### 实践细节和结果验证

```shell
# 关闭防火墙和 SELINUX

# 安装 Mongodb 并正常启动
tee /etc/yum.repos.d/mongodb-org-7.0.repo << EOF
[mongodb-org-7.0]
name=MongoDB Repository
baseurl=https://repo.mongodb.org/yum/redhat/9/mongodb-org/7.0/x86_64/
gpgcheck=1
enabled=1
gpgkey=https://www.mongodb.org/static/pgp/server-7.0.asc
EOF
yum install -y mongodb-org
mkdir -p /data/mongodb
sed -i 's|dbPath: /var/lib/mongo|dbPath: /data/mongodb|' /etc/mongod.conf
sed -i 's|bindIp: 127.0.0.1|bindIp: 0.0.0.0|' /etc/mongod.conf
cp /lib/systemd/system/mongod.service /etc/systemd/system/mongod.service
sed -i 's/User=mongod/User=root/' /etc/systemd/system/mongod.service
sed -i 's/Group=mongod/Group=root/' /etc/systemd/system/mongod.service
systemctl start mongod && systemctl enable mongod

# 测试验证
mongod --version
```

