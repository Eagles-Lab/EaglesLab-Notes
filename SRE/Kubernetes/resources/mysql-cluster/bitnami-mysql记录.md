此文档为 bitnami/mysql 配置文件解读，详细 values 等信息见[官方文档](https://artifacthub.io/packages/helm/bitnami/mysql)。

bitnami MySQL 集群中的容器全部均采用 https://hub.docker.com/r/bitnami/mysql，容器中包含初始化脚本，后文会提及，

镜像源码（包含所有脚本）可见 https://github.com/bitnami/containers/tree/main/bitnami/mysql/，

chart 源码可见 https://github.com/bitnami/charts/tree/main/bitnami/mysql。



# 简单部署



```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

```bash
helm install my-mysql ./mysql  \
	--set global.strorageClass=$YOUR_STORAGECLASS  \
	--set architecture=replication  \
	--set secondary.replicaCount=$REPILICA_NUM
```

- `global.strorageClass`：设置存储类，如果不设置默认采用 default StorageClass，如果没有默认 SC 创建的 PVC 将处于 `Pending` 状态。
- `architecture`：设置 MySQL 架构，有 `standalone` 单主机和 `replication` 集群两个选项，默认为单主机。
- `secondary.replicaCount`：设置集群从节点个数，即 Slave 个数。

也可以通过 `values.yaml` 进行高级配置。

> 如遇网络问题可通过 pull 拉取，再上传到所需主机。
>
> ```bash
> helm pull oci://registry-1.docker.io/bitnamicharts/mysql --version 12.3.4
> 
> tar -zxvf mysql mysql-12.3.4.tgz && cd mysql/
> 
> helm install my-mysql mysql/
> ```



# 获取资源清单

由上文设置的 values 获取 helm chart 配置清单。

```bash
$ helm list
NAME            NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
my-mysql        default         1               2025-04-25 19:51:56.787669028 +0800 CST deployed        mysql-12.3.4    8.4.5
```

```bash
helm get manifest my-mysql > my-mysql.yaml
```



# 资源清单解释



资源清单中包含 NetWorkPolicy、PodDisruptionBudget、ServiceAccount、Secret、ConfigMap（primary+secondary）、Service（primary+secondary cluster+headless）、StatefulSet（primary+secondary）。



## <span id="statefulset">StatefulSet</span>



primary 和 secondary 除在标签命名上的区别，在[环境变量声明]()上还有区别。

>[!TIP]
>
>若不在 values.yaml 中设置，部署时 `persistentVolumeClaimRetentionPolicy` 字段中的两个子字段 `whenDeleted`、`whenScaled` 均会默认被设置成 `Retain`，删除 release 时需要手动删除 PVC 和 PV。

```yaml
# Source: mysql/templates/primary/statefulset.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: my-mysql-primary
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
    app.kubernetes.io/component: primary
spec:
  replicas: 1
  # pod 创建、删除和扩展顺序，默认 OrderedReady
  podManagementPolicy: ""
  selector:
    matchLabels:
      app.kubernetes.io/instance: my-mysql
      app.kubernetes.io/name: mysql
      app.kubernetes.io/part-of: mysql
      app.kubernetes.io/component: primary
  serviceName: my-mysql-primary-headless
  updateStrategy:
    type: RollingUpdate
  template:
    metadata:
      annotations:
        checksum/configuration: a581348f7af561e486fad8d76b185ef64f865137e8229ff5d0fa6cdf95694ea1
      labels:
        app.kubernetes.io/instance: my-mysql
        app.kubernetes.io/managed-by: Helm
        app.kubernetes.io/name: mysql
        app.kubernetes.io/version: 8.4.5
        helm.sh/chart: mysql-12.3.4
        app.kubernetes.io/part-of: mysql
        app.kubernetes.io/component: primary
    spec:
      serviceAccountName: my-mysql
      
      automountServiceAccountToken: false
      affinity:
        podAffinity:
          
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
            - podAffinityTerm:
                labelSelector:
                  matchLabels:
                    app.kubernetes.io/instance: my-mysql
                    app.kubernetes.io/name: mysql
                topologyKey: kubernetes.io/hostname
              weight: 1
        nodeAffinity:
          
      securityContext:
        fsGroup: 1001
        fsGroupChangePolicy: Always
        supplementalGroups: []
        sysctls: []
      initContainers:
        - name: preserve-logs-symlinks
          image: docker.io/bitnami/mysql:8.4.5-debian-12-r0
          imagePullPolicy: "IfNotPresent"
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            readOnlyRootFilesystem: true
            runAsGroup: 1001
            runAsNonRoot: true
            runAsUser: 1001
            seLinuxOptions: {}
            seccompProfile:
              type: RuntimeDefault
          resources:
            limits:
              cpu: 750m
              ephemeral-storage: 2Gi
              memory: 768Mi
            requests:
              cpu: 500m
              ephemeral-storage: 50Mi
              memory: 512Mi
          command:
            - /bin/bash
          args:
            - -ec
            - |
              #!/bin/bash

              . /opt/bitnami/scripts/libfs.sh
              # We copy the logs folder because it has symlinks to stdout and stderr
              if ! is_dir_empty /opt/bitnami/mysql/logs; then
                cp -r /opt/bitnami/mysql/logs /emptydir/app-logs-dir
              fi
          volumeMounts:
            - name: empty-dir
              mountPath: /emptydir
      containers:
        - name: mysql
          image: docker.io/bitnami/mysql:8.4.5-debian-12-r0
          imagePullPolicy: "IfNotPresent"
          securityContext:
            allowPrivilegeEscalation: false
            capabilities:
              drop:
              - ALL
            readOnlyRootFilesystem: true
            runAsGroup: 1001
            runAsNonRoot: true
            runAsUser: 1001
            seLinuxOptions: {}
            seccompProfile:
              type: RuntimeDefault
          env:
            - name: BITNAMI_DEBUG
              value: "false"
            - name: MYSQL_ROOT_PASSWORD_FILE
              value: /opt/bitnami/mysql/secrets/mysql-root-password
            - name: MYSQL_ENABLE_SSL
              value: "no"
            - name: MYSQL_PORT
              value: "3306"
            - name: MYSQL_DATABASE
              value: "my_database"
            - name: MYSQL_REPLICATION_MODE
              value: "master"
            - name: MYSQL_REPLICATION_USER
              value: "replicator"
            - name: MYSQL_REPLICATION_PASSWORD_FILE
              value: /opt/bitnami/mysql/secrets/mysql-replication-password
          envFrom:
          ports:
            - name: mysql
              containerPort: 3306
          livenessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
            exec:
              command:
                - /bin/bash
                - -ec
                - |
                  password_aux="${MYSQL_ROOT_PASSWORD:-}"
                  if [[ -f "${MYSQL_ROOT_PASSWORD_FILE:-}" ]]; then
                      password_aux=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
                  fi
                  mysqladmin status -uroot -p"${password_aux}"
          readinessProbe:
            failureThreshold: 3
            initialDelaySeconds: 5
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
            exec:
              command:
                - /bin/bash
                - -ec
                - |
                  password_aux="${MYSQL_ROOT_PASSWORD:-}"
                  if [[ -f "${MYSQL_ROOT_PASSWORD_FILE:-}" ]]; then
                      password_aux=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
                  fi
                  mysqladmin ping -uroot -p"${password_aux}" | grep "mysqld is alive"
          startupProbe:
            failureThreshold: 10
            initialDelaySeconds: 15
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 1
            exec:
              command:
                - /bin/bash
                - -ec
                - |
                  password_aux="${MYSQL_ROOT_PASSWORD:-}"
                  if [[ -f "${MYSQL_ROOT_PASSWORD_FILE:-}" ]]; then
                      password_aux=$(cat "$MYSQL_ROOT_PASSWORD_FILE")
                  fi
                  mysqladmin ping -uroot -p"${password_aux}" | grep "mysqld is alive"
          resources:
            limits:
              cpu: 750m
              ephemeral-storage: 2Gi
              memory: 768Mi
            requests:
              cpu: 500m
              ephemeral-storage: 50Mi
              memory: 512Mi
          volumeMounts:
            - name: data
              mountPath: /bitnami/mysql
            - name: empty-dir
              mountPath: /tmp
              subPath: tmp-dir
            - name: empty-dir
              mountPath: /opt/bitnami/mysql/conf
              subPath: app-conf-dir
            - name: empty-dir
              mountPath: /opt/bitnami/mysql/tmp
              subPath: app-tmp-dir
            - name: empty-dir
              mountPath: /opt/bitnami/mysql/logs
              subPath: app-logs-dir
            - name: config
              mountPath: /opt/bitnami/mysql/conf/my.cnf
              subPath: my.cnf
            - name: mysql-credentials
              mountPath: /opt/bitnami/mysql/secrets/
      volumes:
        - name: config
          configMap:
            name: my-mysql-primary
        - name: mysql-credentials
          secret:
            secretName: my-mysql
            items:
              - key: mysql-root-password
                path: mysql-root-password
              - key: mysql-password
                path: mysql-password
              - key: mysql-replication-password
                path: mysql-replication-password
        - name: empty-dir
          emptyDir: {}
  volumeClaimTemplates:
    - metadata:
        name: data
        labels:
          app.kubernetes.io/instance: my-mysql
          app.kubernetes.io/name: mysql
          app.kubernetes.io/component: primary
      spec:
        accessModes:
          - "ReadWriteOnce"
        resources:
          requests:
            storage: "8Gi"
```



### initContainers



通过 `/opt/bitnami/scripts/libfs.sh`  标准化文件系统管理，内容可见 [libfs.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/prebuildfs/opt/bitnami/scripts/libfs.sh)。

检查 MySQL 日志目录是否为空，如果目录不为空，将整个日志目录（包含符号链接）复制到临时目录，确保日志文件能被挂载到主容器的 `/opt/bitnami/mysql/logs/app-logs-dir` 目录下，便于使用 Kubernetes 的日志收集和管理功能。



### Containers



#### 环境变量

设置环境变量，为之后初始化脚本做准备

**primary**：

```yaml
env:
  - name: BITNAMI_DEBUG
    value: "false"
  - name: MYSQL_ENABLE_SSL
    value: "no"
  - name: MYSQL_PORT
    value: "3306"
  - name: MYSQL_DATABASE
    value: "my_database"
  - name: MYSQL_REPLICATION_MODE
    value: "master"
  - name: MYSQL_REPLICATION_USER
    value: "replicator"
  - name: MYSQL_ROOT_PASSWORD_FILE
    value: /opt/bitnami/mysql/secrets/mysql-root-password
  - name: MYSQL_REPLICATION_PASSWORD_FILE
    value: /opt/bitnami/mysql/secrets/mysql-replication-password
```

环境变量解释

```ini
 # 调试日志开关：禁用
 BITNAMI_DEBUG=false
 # 控制SSL加密连接：禁用
 MYSQL_ENABLE_SSL=no
 # MySQL监听端口
 MYSQL_PORT=3306
 # 初始化时创建的默认数据库
 MYSQL_DATABASE=my_database
 # 定义节点角色：主库
 MYSQL_REPLICATION_MODE=master
 # 复制专用用户名，主库自动创建此用户并授权 REPLICATION SLAVE 权限
 MYSQL_REPLICATION_USER=replicator
 # 指定root密码路径
 MYSQL_ROOT_PASSWOR_FILE=/opt/bitnami/mysql/secrets/mysql-root-password
 # 复制用户密码文件路径
 MYSQL_REPLICATION_PASSWORD_FILE=/opt/bitnami/mysql/secrets/mysql-replication-password
```

[Secret](#secret) 中指定的 3 个密码，通过 Volumes 分别挂载至 `/opt/bitnami/mysql/secrets/` 目录下，再由 `MYSQL_ROOT_PASSWOR_FILE`、`MYSQL_REPLICATION_PASSWORD_FILE` 环境变量指定密码文件位置，通过 shell 脚本实现密码获取。



**secondary**：

```yaml
env:
  - name: BITNAMI_DEBUG
    value: "false"
  - name: MYSQL_ENABLE_SSL
    value: "no"
  - name: MYSQL_PORT
    value: "3306"
  - name: MYSQL_MASTER_PORT_NUMBER
    value: "3306"
  - name: MYSQL_REPLICATION_MODE
    value: "slave"
  - name: MYSQL_MASTER_HOST
    value: my-mysql-primary 
  - name: MYSQL_MASTER_ROOT_USER
    value: "root"
  - name: MYSQL_REPLICATION_USER
    value: "replicator"
  - name: MYSQL_MASTER_ROOT_PASSWORD_FILE
    value: /opt/bitnami/mysql/secrets/mysql-root-password
  - name: MYSQL_REPLICATION_PASSWORD_FILE
    value: /opt/bitnami/mysql/secrets/mysql-replication-password
```

环境变量解释，上面提到过的略

```ini
# 主库端口，需与主库 MYSQL_PORT 一致
MYSQL_MASTER_PORT_NUMBER=3306
# 定义节点角色：从库，自动配置 server-id 和复制参数
MYSQL_REPLICATION_MODE=slave
# 主库主机名/IP，从库通过此值连接主库
MYSQL_MASTER_HOST=my-mysql-primary 
# 主库root用户，用于从库初始化时连接主库（需与主库root用户一致）
MYSQL_MASTER_ROOT_USER=root
# 复制专用用户名，主库需提前创建此用户并授权REPLICATION SLAVE权限
MYSQL_REPLICATION_USER=replicator
```



## <span id="service">Service</span>



Primary 和 Secondary 配置文件中仅有名称的区别，故不赘述。

```yaml
# Source: mysql/templates/primary/svc-headless.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-mysql-primary-headless
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
    app.kubernetes.io/component: primary
spec:
  type: ClusterIP
  clusterIP: None
  publishNotReadyAddresses: true
  ports:
    - name: mysql
      port: 3306
      targetPort: mysql
  selector:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/name: mysql
    app.kubernetes.io/component: primary
---

# Source: mysql/templates/primary/svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-mysql-primary
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
    app.kubernetes.io/component: primary
spec:
  type: ClusterIP
  sessionAffinity: None  
  ports:
    - name: mysql
      port: 3306
      protocol: TCP
      targetPort: mysql
      nodePort: null
  selector:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/name: mysql
    app.kubernetes.io/part-of: mysql
    app.kubernetes.io/component: primary
```





## <span id="configmap">ConfigMap</span>



Primary 和 Secondary 配置文件中仅有名称的区别，故不赘述。

```yaml
# Source: mysql/templates/primary/configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: my-mysql-primary
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
    app.kubernetes.io/component: primary
data:
  my.cnf: |-
    [mysqld]
    # 控制多因素认证策略，* ,, 表示允许所有认证方式（如密码、插件等）
    authentication_policy='* ,,'
    # 禁用DNS反向解析，仅通过IP授权访问
    skip-name-resolve
    # 禁用TIMESTAMP列的自动更新特性，需显式指定默认值
    explicit_defaults_for_timestamp
    # MySQL安装目录
    basedir=/opt/bitnami/mysql
    # 插件存放路径
    plugin_dir=/opt/bitnami/mysql/lib/plugin
    # 监听端口
    port=3306
    # 禁用 MySQL X Protocol（默认 33060 端口）
    mysqlx=0
    mysqlx_port=33060
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    # 数据文件存放目录
    datadir=/bitnami/mysql/data
    # 临时文件目录
    tmpdir=/opt/bitnami/mysql/tmp
    # 单此传输最大数据包大小
    max_allowed_packet=16M
    # 监听所有IP地址
    bind-address=*
    
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
    # 错误日志路径
    log-error=/opt/bitnami/mysql/logs/mysqld.log
    # 默认字符集
    character-set-server=UTF8
    # 关闭慢查询日志
    slow_query_log=0
    # 若启用慢查询，记录超过10秒的查询
    long_query_time=10.0
    
    [client]
    port=3306
    # 本地通信的Unix套接字路径
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    default-character-set=UTF8
    plugin_dir=/opt/bitnami/mysql/lib/plugin
    
    [manager]
    port=3306
    socket=/opt/bitnami/mysql/tmp/mysql.sock
    pid-file=/opt/bitnami/mysql/tmp/mysqld.pid
```



## <span id="secret">Secret</span>



```yaml
# Source: mysql/templates/secrets.yaml
apiVersion: v1
kind: Secret
metadata:
  name: my-mysql
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
type: Opaque
data:
  mysql-root-password: "N0ZveE5ZdXRobg=="
  mysql-password: "TVlvWXZYOFZiZQ=="
  mysql-replication-password: "NzNkc0NtbmtJMQ=="
```

```bash
kubectl get secret --namespace default my-mysql -o jsonpath="{.data.mysql-root-password}" | base64 -d
```

该命令获取的密码即为 `mysql-root-password` base64 decode 值。



## <span id="networdpolicy">NetWorkPolicy</span>



```yaml
# Source: mysql/templates/networkpolicy.yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: my-mysql
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
spec:
  podSelector:
    matchLabels:
      app.kubernetes.io/instance: my-mysql
      app.kubernetes.io/managed-by: Helm
      app.kubernetes.io/name: mysql
      app.kubernetes.io/version: 8.4.5
      helm.sh/chart: mysql-12.3.4
  policyTypes:
    - Ingress
    - Egress
  egress:
    - {}
  ingress:
    # Allow connection from other cluster pods
    - ports:
        - port: 3306
```





## <span id="serviceaccount">ServiceAccount</span>



```yaml
# Source: mysql/templates/serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: my-mysql
  namespace: "default"
  labels:
    app.kubernetes.io/instance: my-mysql
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: mysql
    app.kubernetes.io/version: 8.4.5
    helm.sh/chart: mysql-12.3.4
    app.kubernetes.io/part-of: mysql
automountServiceAccountToken: false
secrets:
  - name: my-mysql
```





# 手动安装示例

常规手动二进制安装 mysql，下文脚本执行的顺序可以参照手动部署 mysql 的顺序。



## 安装 MySQL



```bash
# 准备工作
yum install -y libaio numactl wget
```
```bash
# 下载并解压
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz 
tar -xvf mysql-8.0.28-linux-glibc2.12-x86_64.tar.xz
mv mysql-8.0.28-linux-glibc2.12-x86_64 /usr/local/mysql
```
```bash
# 创建 mysql 用户
groupadd mysql
useradd -r -g mysql -s /bin/false mysql
mkdir -p /usr/local/mysql/data /var/log/mysql
chown -R mysql:mysql /usr/local/mysql /var/log/mysql
```
```bash
# 初始化数据库
/usr/local/mysql/bin/mysqld \
	--initialize \
	--user=mysql \
	--basedir=/usr/local/mysql \
	--datadir=/usr/local/mysql/data
```
```bash
# 配置 mysql
[mysqld]
basedir=/usr/local/mysql
datadir=/usr/local/mysql/data
socket=/var/lib/mysql/mysql.sock
log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid
```
```bash
# 设置环境变量
echo 'export PATH=/usr/local/mysql/bin:$PATH' >> /etc/profile
source /etc/profile
```
```bash
# Systemd 服务配置
mkdir /etc/systemd/system/mysqld.service
```

```ini
[Unit]
Description=MySQL Server
After=network.target

[Service]
User=mysql
Group=mysql
ExecStart=/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf
LimitNOFILE=5000

[Install]
WantedBy=multi-user.target
```

```bash
# 启动服务
systemctl daemon-reload
systemctl start mysqld
systemctl enable mysqld
```



## Master 配置

修改 `/etc/my.cnf`：

```ini
[mysqld]
server-id = 1
log-bin = mysql-bin
binlog-format = ROW
binlog-do-db = test_db  # 需同步的数据库
```

重启MySQL并授权复制用户：

```sql
CREATE USER 'repl'@'%' IDENTIFIED BY 'SecurePass123!';
GRANT REPLICATION SLAVE ON *.* TO 'repl'@'%';
FLUSH PRIVILEGES;
```

记录二进制日志位置：

```sql
SHOW MASTER STATUS;
```



## Slave配置

修改 `/etc/my.cnf`：

```ini
[mysqld]
server-id = 2  # 必须与主服务器不同
relay-log = relay-log
replicate-do-db = test_db
```

配置主从连接：

```sql
CHANGE MASTER TO
MASTER_HOST='192.168.1.100',  # 主服务器IP
MASTER_USER='repl',
MASTER_PASSWORD='SecurePass123!',
MASTER_LOG_FILE='mysql-bin.000003',
MASTER_LOG_POS=785;
START SLAVE;
```

验证复制状态：

```sql
SHOW SLAVE STATUS\G
```



# 镜像



bitnami MySQL 镜像可见 [Dockerfile](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/Dockerfile)。MySQL 二进制包安装目录为 `/opt/bitnami`。

bitnami 提供的 MySQL 镜像可以直接部署集群无需 kubernetes，部署详情可见 [README.md](https://github.com/bitnami/containers/blob/main/bitnami/mysql/README.md)。

bitnami MySQL 集群初始化依赖镜像中的脚本 [scripts](https://github.com/bitnami/containers/tree/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts)、依赖 [lib](https://github.com/bitnami/containers/tree/main/bitnami/mysql/8.4/debian-12/prebuildfs/opt/bitnami/scripts)，容器内位置为 `/opt/bitnami/scripts/mysql`。

镜像内脚本执行顺序为 [entrypoint.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/entrypoint.sh)，[setup.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/entrypoint.sh)，[run.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/run.sh) 。

**以下脚本解读顺序为镜像内 MySQL 初始化顺序。**

> [!WARNING]
>
> [setup.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/entrypoint.sh) 脚本仅为 MySQL 初始化，不负责启动 MySQL，MySQL 集群只能通过 [run.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/run.sh) 脚本启动。



## mysql_validate() 



[libmysql.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/libmysql.sh)

检查环境变量，`()` 内为 [Statefulset](#statefulset) 中的环境变量名：

- `DB_REPLICATION_MODE="master"` 检查 DB_REPLICATION_USER（MYSQL_REPLICATION_USER）、DB_ROOT_PASSWORD（MYSQL_ROOT_PASSWORD_FILE）
- `DB_REPLICATION_MODE="slave"` 检查 DB_MASTER_HOST（MYSQL_MASTER_HOST）
- DB_ROOT_PASSWORD、DB_PASSWORD、DB_REPLICATION_PASSWORD 检查



## mysql_initialize()



[libmysql.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/libmysql.sh)

MySQL 初始化脚本，相当于上文手动安装流程从 **创建 mysql 用户** 至 **配置 mysql** 以及所有 **主从配置操作**。

```bash
debug "Ensuring expected directories/files exist"
for dir in "$DB_DATA_DIR" "$DB_TMP_DIR" "$DB_LOGS_DIR"; do
    ensure_dir_exists "$dir"
    am_i_root && chown "$DB_DAEMON_USER":"$DB_DAEMON_GROUP" "$dir"
done
```

相当于：

```bash
mkdir -p /bitnami/mysql/data /opt/bitnami/mysql/tmp /opt/bitnami/mysql/logs

chown mysql:mysql /bitnami/mysql/data
chown mysql:mysql /opt/bitnami/mysql/tmp
chown mysql:mysql /opt/bitnami/mysql/logs
```

***

```bash
if is_file_writable "$DB_CONF_FILE"; then
    info "Updating 'my.cnf' with custom configuration"
    mysql_update_custom_config
else
    warn "The ${DB_FLAVOR} configuration file '${DB_CONF_FILE}' is not writable. Configurations based on environment variables will not be applied for this file."
fi
```

检查 `/opt/bitnami/mysql/conf/my.cnf` 是否存在并可写，这里如果是用之前的 helm 部署 `my.cnf` 会随 [configmap](#configmap) 挂载至此路径，覆盖容器初始化 `mysql_create_default_config()` 函数根据环境变量创建的 `my.cnf`

```bash
mysql 04:48:45.58 WARN  ==> The mysql configuration file '/opt/bitnami/mysql/conf/my.cnf' is not writable. Configurations based on environment variables will not be applied for this file.
```

由于 ConfigMap 默认以只读形式挂载，[statefulset](#statefulset) 中并没有设置 `defaultMode` ，这里的 `my.cnf` 文件并不会被 `mysql_update_custom_config()` 函数修改成 `my_custom.cnf`。

***

`my_custom.cnf()` 部分在 kubernetes 中并不存在，故不做讨论。

***

```bash
if [[ -e "$DB_DATA_DIR/mysql" ]]; then
    info "Using persisted data"
    # mysql_upgrade requires the server to be running
    [[ -n "$(get_master_env_var_value ROOT_PASSWORD)" ]] && export ROOT_AUTH_ENABLED="yes"
    # https://dev.mysql.com/doc/refman/8.0/en/replication-upgrade.html
    mysql_upgrade
else
    debug "Cleaning data directory to ensure successfully initialization"
    rm -rf "${DB_DATA_DIR:?}"/*
    info "Installing database"
    mysql_install_db
    mysql_start_bg
    wait_for_mysql_access
    # we delete existing users and create new ones with stricter access
    # commands can still be executed until we restart or run 'flush privileges'
    info "Configuring authentication"
    mysql_execute "mysql" <<EOF
DELETE FROM mysql.user WHERE user not in ('mysql.sys','mysql.infoschema','mysql.session','mariadb.sys');
EOF
    # slaves do not need to configure users
    if [[ -z "$DB_REPLICATION_MODE" ]] || [[ "$DB_REPLICATION_MODE" = "master" ]]; then
        if [[ "$DB_REPLICATION_MODE" = "master" ]]; then
            debug "Starting replication"
            if [[ "$(mysql_get_version)" =~ ^8\.0\. ]]; then
                echo "RESET MASTER;" | debug_execute "$DB_BIN_DIR/mysql" --defaults-file="$DB_CONF_FILE" -N -u root
            else
                echo "RESET BINARY LOGS AND GTIDS;" | debug_execute "$DB_BIN_DIR/mysql" --defaults-file="$DB_CONF_FILE" -N -u root
            fi
        fi
        mysql_ensure_root_user_exists "$DB_ROOT_USER" "$DB_ROOT_PASSWORD" "$DB_AUTHENTICATION_PLUGIN"
        mysql_ensure_user_not_exists "" # ensure unknown user does not exist
        if [[ -n "$DB_USER" ]]; then
            local -a args=("$DB_USER")
            [[ -n "$DB_PASSWORD" ]] && args+=("-p" "$DB_PASSWORD")
            [[ -n "$DB_AUTHENTICATION_PLUGIN" ]] && args+=("--auth-plugin" "$DB_AUTHENTICATION_PLUGIN")
            mysql_ensure_optional_user_exists "${args[@]}"
        fi
        if [[ -n "$DB_DATABASE" ]]; then
            local -a createdb_args=("$DB_DATABASE")
            [[ -n "$DB_USER" ]] && createdb_args+=("-u" "$DB_USER")
            [[ -n "$DB_CHARACTER_SET" ]] && createdb_args+=("--character-set" "$DB_CHARACTER_SET")
            [[ -n "$DB_COLLATE" ]] && createdb_args+=("--collate" "$DB_COLLATE")
            mysql_ensure_optional_database_exists "${createdb_args[@]}"
        fi
        [[ -n "$DB_ROOT_PASSWORD" ]] && export ROOT_AUTH_ENABLED="yes"
    fi
    [[ -n "$DB_REPLICATION_MODE" ]] && mysql_configure_replication
    # we run mysql_upgrade in order to recreate necessary database users and flush privileges
    mysql_upgrade
fi
}
```

检查 `/bitnami/mysql/data` 中是否有文件，如果有则说明 mysql 在容器中已被初始化，执行 `mysql_upgrade()` 此函数本文暂时不讨论；如果没有，则删除改目录下所有文件，执行 `mysql_install_db()`，`mysql_start_bg()`，`wait_for_mysql_access()`。

这里只讨论 `else` 中的情况。



### mysql_install_db()

通过 `mysql_extra_flags()` 获取额外参数，首次初始化 mysql，不会启动服务。

```bash
mysql_install_db() {
    local command="${DB_BIN_DIR}/mysql_install_db"
    local -a args=("--defaults-file=${DB_CONF_FILE}" "--basedir=${DB_BASE_DIR}" "--datadir=${DB_DATA_DIR}")

    # Add flags specified via the 'DB_EXTRA_FLAGS' environment variable
    read -r -a db_extra_flags <<< "$(mysql_extra_flags)"
    [[ "${#db_extra_flags[@]}" -gt 0 ]] && args+=("${db_extra_flags[@]}")

    am_i_root && args=("${args[@]}" "--user=$DB_DAEMON_USER")
    command="${DB_BIN_DIR}/mysqld"
    args+=("--initialize-insecure")

    debug_execute "$command" "${args[@]}"
}
```

在命令行相当于：

master：

```bash
/opt/bitnami/mysql/sbin/mysqld \
    --defaults-file=/opt/bitnami/mysql/conf/my.cnf \
    --basedir=/opt/bitnami/mysql \
    --datadir=/bitnami/mysql/data \
    --server-id=123 \              		# 随机生成的3位数服务器ID
    --log-bin=mysql-bin \          		# 启用二进制日志
    --sync-binlog=1 \             		# 每次事务后同步二进制日志
    --innodb_flush_log_at_trx_commit=1  # 每次事务提交时刷新日志
```

slave：

```bash
/opt/bitnami/mysql/sbin/mysqld \
    --defaults-file=/opt/bitnami/mysql/conf/my.cnf \
    --basedir=/opt/bitnami/mysql \
    --datadir=/bitnami/mysql/data \
    --server-id=456 \              	# 随机生成的3位数服务器ID
    --log-bin=mysql-bin \          	# 启用二进制日志
    --sync-binlog=1 \             	# 每次事务后同步二进制日志
    --relay-log=mysql-relay-bin \  	# 中继日志文件名
    --log-replica-updates=1 \      	# 从库更新写入二进制日志
    --read-only=1                  	# 只读模式
```



### mysql_start_bg()

在后台启动 MySQL 服务，如果检测到 MySQL 正在运行，直接退出。通过 `wait_for_mysql()` 查询是否有 MySQL PID，等待 MySQL 启动。

> [!WARNING]
>
> 此时 MySQL 还在初始化阶段，不允许外部访问，使用 `--skip-replica-start` 避免在初始化阶段未配置好复制用户凭据时就开始复制，等待所有初始化完成（包括用户创建、权限设置等）后会在在 `run.sh` 中执行 `START REPLICA` 命令启动复制。

```bash
mysql_start_bg() {
    local -a flags=("--defaults-file=${DB_CONF_FILE}" "--basedir=${DB_BASE_DIR}" "--datadir=${DB_DATA_DIR}" "--socket=${DB_SOCKET_FILE}")

    # Only allow local connections until MySQL is fully initialized, to avoid apps trying to connect to MySQL before it is fully initialized
    flags+=("--bind-address=127.0.0.1")

    # Add flags specified via the 'DB_EXTRA_FLAGS' environment variable
    read -r -a db_extra_flags <<<"$(mysql_extra_flags)"
    [[ "${#db_extra_flags[@]}" -gt 0 ]] && flags+=("${db_extra_flags[@]}")

    # Do not start as root, to avoid permission issues
    am_i_root && flags+=("--user=${DB_DAEMON_USER}")

    # The replica should only start in 'run.sh', elseways user credentials would be needed for any connection
    flags+=("--skip-replica-start")
    flags+=("$@")

    is_mysql_running && return

    info "Starting $DB_FLAVOR in background"
    debug_execute "${DB_SBIN_DIR}/mysqld" "${flags[@]}" &

    # we cannot use wait_for_mysql_access here as mysql_upgrade for MySQL >=8 depends on this command
    # users are not configured on slave nodes during initialization due to --skip-slave-start
    wait_for_mysql

    # Special configuration flag for system with slow disks that could take more time
    # in initializing
    if [[ -n "${DB_INIT_SLEEP_TIME}" ]]; then
        debug "Sleeping ${DB_INIT_SLEEP_TIME} seconds before continuing with initialization"
        sleep "${DB_INIT_SLEEP_TIME}"
    fi
}
```

在命令行相当于：

Master：

```bash
/opt/bitnami/mysql/sbin/mysqld \
    --defaults-file=/opt/bitnami/mysql/conf/my.cnf \
    --basedir=/opt/bitnami/mysql \
    --datadir=/bitnami/mysql/data \
    --socket=/opt/bitnami/mysql/tmp/mysql.sock \
    --bind-address=127.0.0.1 \
    --server-id=123 \           # 随机生成的3位数
    --log-bin=mysql-bin \       # 开启二进制日志
    --sync-binlog=1 \          	# 同步写入二进制日志
    --innodb_flush_log_at_trx_commit=1 \  # Master节点特有配置
    --user=mysql \             	# 如果以root运行则切换用户
    --skip-replica-start \     	# 禁止复制自动启动
    &							# 将进程放入后台，不需要用 systemctl 启动
```

Slave：

```bash
/opt/bitnami/mysql/sbin/mysqld \
    --defaults-file=/opt/bitnami/mysql/conf/my.cnf \
    --basedir=/opt/bitnami/mysql \
    --datadir=/bitnami/mysql/data \
    --socket=/opt/bitnami/mysql/tmp/mysql.sock \
    --bind-address=127.0.0.1 \
    --server-id=456 \          # 随机生成的3位数
    --log-bin=mysql-bin \      # 开启二进制日志
    --sync-binlog=1 \          # 同步写入二进制日志
    --relay-log=mysql-relay-bin \  # Slave节点特有配置
    --log-replica-updates=1 \      # Slave节点特有配置
    --read-only=1 \               # Slave节点特有配置
    --user=mysql \              # 如果以root运行则切换用户
    --skip-replica-start \      # 禁止复制自动启动
    &							# 将进程放入后台
```



### wait_for_mysql_access()

根据 `ROOT_AUTH_ENABLED` 情况使用 `mysql -u root` 或 `mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}"` 连接来判断 MySQL 是否准备好接受数据。

```bash
wait_for_mysql_access() {
    # wait until the server is up and answering queries.
    local -r user="${1:-root}"
    local -a args=("mysql" "$user")
    is_boolean_yes "${ROOT_AUTH_ENABLED:-false}" && args+=("$(get_master_env_var_value ROOT_PASSWORD)")
    local -r retries=300
    local -r sleep_time=2
    is_mysql_accessible() {
        echo "select 1" | mysql_execute "${args[@]}"
    }
    if ! retry_while is_mysql_accessible "$retries" "$sleep_time"; then
        error "Timed out waiting for MySQL to be accessible"
        return 1
    fi
}
```

转换为：

```bash
# 循环尝试连接直到成功或超时
# ROOT_AUTH_ENABLED=false
for i in {1..300}; do
    echo "select 1" | mysql mysql -u root && break
    sleep 2
    [ $i -eq 300 ] && echo "Timed out waiting for MySQL" && exit 1
done

# ROOT_AUTH_ENABLED=true
for i in {1..300}; do
    echo "select 1" | mysql mysql -u root -p"${MYSQL_ROOT_PASSWORD}" && break
    sleep 2
    [ $i -eq 300 ] && echo "Timed out waiting for MySQL" && exit 1
done
```

> `wait_for_mysql()` 与 `wait_for_mysql_access()` 区别在于前者只检查 PID，后者通过 mysql 命令连接。



### mysql_configure_replication()

主从配置实现，master 创建复制用户并赋予复制权限，slave 等待主库根据 DB_REPLICATION_SLAVE_DUMP 环境变量选择复制方式，全量数据同步或者仅配置复制连接。

```bash
mysql_configure_replication() {
    if [[ "$DB_REPLICATION_MODE" = "slave" ]]; then
        info "Configuring replication in slave node"
        debug "Checking if replication master is ready to accept connection"
        while ! echo "select 1" | mysql_remote_execute "$DB_MASTER_HOST" "$DB_MASTER_PORT_NUMBER" "mysql" "$DB_MASTER_ROOT_USER" "$DB_MASTER_ROOT_PASSWORD"; do
            sleep 1
        done

        if [[ "$DB_REPLICATION_SLAVE_DUMP" = "true" ]]; then
            mysql_exec_initial_dump
        else
            debug "Replication master ready!"
            debug "Setting the master configuration"
            mysql_execute "mysql" <<EOF
CHANGE REPLICATION SOURCE TO SOURCE_HOST='$DB_MASTER_HOST',
SOURCE_PORT=$DB_MASTER_PORT_NUMBER,
SOURCE_USER='$DB_REPLICATION_USER',
SOURCE_PASSWORD='$DB_REPLICATION_PASSWORD',
SOURCE_DELAY=$DB_MASTER_DELAY,
SOURCE_CONNECT_RETRY=10,
GET_SOURCE_PUBLIC_KEY=1;
EOF

        fi
    elif [[ "$DB_REPLICATION_MODE" = "master" ]]; then
        info "Configuring replication in master node"
        if [[ -n "$DB_REPLICATION_USER" ]]; then
            mysql_ensure_replication_user_exists "$DB_REPLICATION_USER" "$DB_REPLICATION_PASSWORD"
        fi
    fi
}
```



### mysql_upgrade()

升级 MySQL 架构。调用 `mysql_stop()` 确保 MySQL 完全停止，等待数据文件解锁，再通过 DB_UPGRADE 作为启动参数启动 MySQL。

```bash
mysql_upgrade() {
    info "Running mysql_upgrade"
    mysql_stop
    mysql_start_bg "--upgrade=${DB_UPGRADE}"
}
```



## mysql_custom_scripts()

用于执行用户自定义的初始化脚本，支持 `.sh`，`.sql`，`.sql.gz` 三种类型的文件，检查文件目录为：

```bash
/docker-entrypoint-initdb.d/   # 首次初始化时执行的脚本
/docker-entrypoint-startdb.d/  # 每次启动时执行的脚本
```

本文暂不讨论。



## mysql_stop()

最后停止 MySQL，至此 MySQL 初始化完成。



## run.sh

[run.sh](https://github.com/bitnami/containers/blob/main/bitnami/mysql/8.4/debian-12/rootfs/opt/bitnami/scripts/mysql/run.sh)

此脚本是 MySQL 容器的主入口点，负责正确和安全地启动 MySQL 服务器。

使用 `mysqld` 启动 MySQL， 不用 `mysqld_safe`，因为 `mysqld` 允许日志输出到 stdout/stderr，便于容器环境中的日志收集。
