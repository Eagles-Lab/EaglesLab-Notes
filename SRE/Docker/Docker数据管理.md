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

```shell
# 创建一个简单的数据卷
[root@docker-server ~]# docker volume create my_data

# 创建带标签的数据卷
[root@docker-server ~]# docker volume create --label env=prod --label app=web my_app_data

# 创建指定驱动的数据卷
[root@docker-server ~]# docker volume create --driver local --opt type=nfs --opt o=addr=192.168.1.1,rw --opt device=:/path/to/dir nfs_data

# 创建带容量限制的数据卷(需要支持的存储驱动)
# docker volume create --opt size=10G mysql_data
```

`Usage:  docker volume ls [OPTIONS]`

```shell
# 列出所有数据卷
[root@docker-server ~]# docker volume ls

# 按名称过滤数据卷
[root@docker-server ~]# docker volume ls --filter name=my_data

# 按标签过滤数据卷
[root@docker-server ~]# docker volume ls --filter label=env=prod

# 以自定义格式输出(仅显示名称)
[root@docker-server ~]# docker volume ls --format "{{.Name}}"

# 列出未被任何容器使用的数据卷
[root@docker-server ~]# docker volume ls --filter dangling=true

```

`Usage:  docker volume inspect [OPTIONS] VOLUME [VOLUME...]`

```shell
# 查看单个数据卷详情
[root@docker-server ~]# docker volume inspect my_data

# 查看多个数据卷详情
[root@docker-server ~]# docker volume inspect my_data my_app_data

# 以特定格式查看数据卷挂载点
[root@docker-server ~]# docker volume inspect --format '{{ .Mountpoint }}' my_data

# 以特定格式查看数据卷驱动
[root@docker-server ~]# docker volume inspect --format '{{ .Driver }}' my_data
```

`Usage:  docker volume rm [OPTIONS] VOLUME [VOLUME...]`

```shell
# 删除单个数据卷
[root@docker-server ~]# docker volume rm my_data

# 删除多个数据卷
[root@docker-server ~]# docker volume rm nfs_data my_app_data

# 强制删除数据卷(即使正在使用)
# [root@docker-server ~]# docker volume rm -f my_data
```

`Usage:  docker volume prune [OPTIONS]`

```shell
# 删除所有未使用的数据卷
[root@docker-server ~]# docker volume prune

# 删除未使用的数据卷并跳过确认提示
[root@docker-server ~]# docker volume prune --force

# 按标签过滤并删除未使用的数据卷
[root@docker-server ~]# docker volume prune --filter label=env=dev
```

## 使用卷启动容器

如果使用不存在的卷启动容器，Docker 会为创建该卷。

```shell
Usage:  
docker run --mount type=volume[,src=<volume-name>],dst=<mount-path>[,<key>=<value>...]
docker run -v [<volume-name>:]<mount-path>[:opts]
```

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
[root@docker-server ~]# docker run -d --name devtest01 --mount source=myvol01,target=/app busybox:latest
[root@docker-server ~]# docker run -d --name devtest02 -v myvol02:/app busybox:latest
```


## 实践案例

**需求**：运行MySQL容器并支持久化存储，进行一次数据备份，数据恢复测试验证。

```shell
# 步骤1: 创建MySQL数据卷
[root@docker-server ~]# docker volume create mysql_data

# 步骤2: 启动MySQL容器并挂载数据卷
[root@docker-server ~]# docker run -d \
    --name mysql_db \
    -e MYSQL_ROOT_PASSWORD=mysecret \
    -e MYSQL_DATABASE=testdb \
    -e MYSQL_USER=testuser \
    -e MYSQL_PASSWORD=testpass \
    -p 3306:3306 \
    --mount type=volume,src=mysql_data,dst=/var/lib/mysql \
    mysql:8.0

# 步骤3: 验证MySQL容器运行状态
[root@docker-server ~]# docker ps -a | grep mysql_db

# 步骤4: 连接到MySQL并创建测试数据
[root@docker-server ~]# docker exec -it mysql_db mysql -uroot -pmysecret -e "
    USE testdb;
    CREATE TABLE users (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), email VARCHAR(100));
    INSERT INTO users (name, email) VALUES ('张三', 'zhangsan@example.com'), ('李四', 'lisi@example.com');
    SELECT * FROM users;
"

# 步骤5: 使用docker命令备份数据库
# 创建备份目录
[root@docker-server ~]# mkdir -p ~/mysql_backups

# 使用mysqldump进行备份
[root@docker-server ~]# docker exec mysql_db mysqldump -uroot -pmysecret testdb > ~/mysql_backups/testdb_backup.sql

# 步骤6: 模拟数据丢失
[root@docker-server ~]# docker exec -it mysql_db mysql -uroot -pmysecret -e "
    USE testdb;
    DROP TABLE users;
    SHOW TABLES;
"

# 步骤7: 从备份恢复数据
[root@docker-server ~]# docker exec -i mysql_db mysql -uroot -pmysecret testdb < ~/mysql_backups/testdb_backup.sql

# 步骤8: 验证数据恢复
[root@docker-server ~]# docker exec -it mysql_db mysql -uroot -pmysecret -e "
    USE testdb;
    SELECT * FROM users;
"

# 步骤9: 测试容器删除后数据持久性
[root@docker-server ~]# docker stop mysql_db
[root@docker-server ~]# docker rm mysql_db

# 使用相同的数据卷重新创建容器
[root@docker-server ~]# docker run -d \
    --name mysql_db_new \
    -e MYSQL_ROOT_PASSWORD=mysecret \
    -e MYSQL_DATABASE=testdb \
    -e MYSQL_USER=testuser \
    -e MYSQL_PASSWORD=testpass \
    -p 3306:3306 \
    --mount type=volume,src=mysql_data,dst=/var/lib/mysql \
    mysql:8.0

# 等待MySQL启动完成
[root@docker-server ~]# sleep 20

# 验证数据是否仍然存在
[root@docker-server ~]# docker exec -it mysql_db_new mysql -uroot -pmysecret -e "
    USE testdb;
    SELECT * FROM users;
"
# 步骤10: 清理资源（可选）
[root@docker-server ~]# docker stop mysql_db_new
[root@docker-server ~]# docker rm mysql_db_new
[root@docker-server ~]# docker volume rm mysql_data
[root@docker-server ~]# rm -rf ~/mysql_backups
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

**需求**：启动 Nginx 容器并挂载宿主机上的配置文件和主页目录，容器内无权限修改相关内容，测试验证。

```shell
# 步骤1: 创建本地工作目录
[root@docker-server ~]# mkdir -p ~/nginx_demo/{conf,html,logs}

# 步骤2: 创建自定义Nginx配置文件
[root@docker-server ~]# cat > ~/nginx_demo/conf/nginx.conf << 'EOF'
user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;

    sendfile        on;
    keepalive_timeout  65;

    server {
        listen       80;
        server_name  localhost;

        location / {
            root   /usr/share/nginx/html;
            index  index.html index.htm;
        }

        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   /usr/share/nginx/html;
        }
    }
}
EOF

# 步骤3: 创建自定义HTML页面
[root@docker-server ~]# cat > ~/nginx_demo/html/index.html << 'EOF'
Bind Mount 测试页面
EOF

# 步骤4: 启动Nginx容器并使用bind mount挂载配置和HTML目录(只读模式)
[root@docker-server ~]# docker run -d --name nginx_bind_mount \
    -p 8080:80 \
    --mount type=bind,src=/root/nginx_demo/conf/nginx.conf,dst=/etc/nginx/nginx.conf,readonly \
    --mount type=bind,src=/root/nginx_demo/html,dst=/usr/share/nginx/html,readonly \
    --mount type=bind,src=/root/nginx_demo/logs,dst=/var/log/nginx \
    nginx:latest

# 步骤5: 验证Nginx容器是否正常运行
[root@docker-server ~]# docker ps | grep nginx_bind_mount

# 步骤6: 测试网站访问
[root@docker-server ~]# curl http://localhost:8080

# 步骤7: 验证只读挂载(这将失败，因为挂载是只读的)
[root@docker-server ~]# docker exec -it nginx_bind_mount bash -c "echo 'test' > /usr/share/nginx/html/test.txt"
bash: /usr/share/nginx/html/test.txt: Read-only file system

# 步骤8: 在宿主机上修改HTML文件
[root@docker-server ~]# cat > ~/nginx_demo/html/index.html << 'EOF'
已更新的页面
EOF

# 步骤9: 再次测试网站访问，查看更新后的页面
[root@docker-server ~]# curl http://localhost:8080

# 步骤10: 查看Nginx日志(它们被挂载到宿主机)
[root@docker-server ~]# ls -la ~/nginx_demo/logs/
[root@docker-server ~]# cat ~/nginx_demo/logs/access.log

# 步骤11: 清理资源(可选)
[root@docker-server ~]# docker stop nginx_bind_mount
[root@docker-server ~]# docker rm nginx_bind_mount
[root@docker-server ~]# rm -rf ~/nginx_demo
```

# 扩展阅读

tmpfs mounts: 
https://docs.docker.com/engine/storage/tmpfs/

volumes plugins: 
https://docs.docker.com/engine/extend/legacy_plugins/