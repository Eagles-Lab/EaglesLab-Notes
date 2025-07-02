# Docker compose单机编排

## Docker Compose 简介

当在宿主机上启动多个容器时，手动操作会比较繁琐，且容易出错。在这种情况下，推荐使用 Docker 单机编排工具 **Docker Compose**。Docker Compose 是 Docker 官方提供的一个开源工具，用于管理和编排多个容器。它可以解决容器之间的依赖关系，简化容器的创建、启动和停止操作。

例如，启动一个 Nginx 前端服务时，可能需要调用后端的 Tomcat 服务，而 Tomcat 容器又依赖于数据库。在这种嵌套依赖关系中，Docker Compose 可以按照正确的顺序启动这些容器，确保每个容器在启动时都能正确依赖所需的其他容器。因此，Docker Compose 完全可以替代 `docker run` 来创建和管理容器。

## Docker Compose 项目结构

Docker Compose 项目将所管理的容器分为三层，分别是：

- **工程（Project）**：工程是 Docker Compose 管理的最高层级，通常对应一个包含多个服务的应用场景。一个工程可以包含多个服务，这些服务通过 `docker-compose.yml` 文件进行定义。
- **服务（Service）**：服务是工程中的一个逻辑单元，通常对应一个容器模板。服务定义了容器的镜像、环境变量、端口映射等配置。一个服务可以启动多个容器实例。
- **容器（Container）**：容器是服务的具体运行实例。Docker Compose 会根据服务的定义创建并管理容器。

通过这种分层结构，Docker Compose 能够高效地管理和编排多个容器，简化复杂的容器依赖关系，提高开发和部署效率。

# 基础环境准备

## Docker compose部署

yum安装docker-compese

从 Docker 20.10 版本开始，Docker Compose 被集成到了 Docker 中，作为插件使用，而不是独立的命令行工具，所以说在20以后的版本中，我们直接使用docker compose(中间用空格隔开)即可

```bash
# 旧版本中安装docker-compose的方式
[root@localhost ~]# yum install -y epel-release
[root@localhost ~]# yum install docker-compose.noarch -y
[root@localhost ~]# docker-compose version
docker-compose version 1.18.0, build 8dd22a9
docker-py version: 2.6.1
CPython version: 3.6.8
OpenSSL version: OpenSSL 1.0.2k-fips  26 Jan 2017
```

## 相关参数

```bash
# docker-compose --help

Define and run multi-container applications with Docker.

## Usage
```bash
docker-compose [-f <arg>...] [options] [COMMAND] [ARGS...]
docker-compose -h|--help
```

### 选项说明

- `-f`, `--file FILE`：指定 Compose 模板文件，默认为 `docker-compose.yml`。
- `-p`, `--project-name NAME`：指定项目名称，默认将使用当前所在目录名称作为项目名。
- `--verbose`：显示更多输出信息。
- `--log-level LEVEL`：定义日志级别 (DEBUG, INFO, WARNING, ERROR, CRITICAL)。
- `--no-ansi`：不显示 ANSI 控制字符。
- `-v`, `--version`：显示版本。

### 命令选项

以下命令需要在 `docker-compose.yml` 或 `yaml` 文件所在目录里执行。

- `build`：构建或重新构建服务中定义的镜像。
- `bundle`：从当前 `docker-compose` 文件生成一个以 `<当前目录>` 为名称的 JSON 格式的 Docker Bundle 文件，用于离线部署。
- `config -q`：验证 Compose 文件格式是否正确，若无错误则不输出任何内容。
- `create`：创建服务所需的所有容器，但不启动它们。
- `down`：停止和删除所有容器、网络、卷，以及由 `docker-compose up` 创建的镜像（可选）。
- `events`：实时显示容器的日志事件，支持指定日志格式（如 JSON）。
- `exec`：在指定的容器中运行一个命令。
- `help`：显示指定命令的帮助信息。
- `images`：列出所有由 `docker-compose` 创建的镜像。
- `kill`：强制终止正在运行的容器。
- `logs`：查看容器的日志输出。
- `pause`：暂停服务中的所有容器。
- `port`：查看服务的端口映射情况。
- `ps`：列出所有由 `docker-compose` 管理的容器。
- `pull`：从镜像仓库拉取服务中定义的镜像。
- `push`：将服务中定义的镜像推送到镜像仓库。
- `restart`：重启服务中的所有容器。
- `rm`：删除所有已停止的容器。
- `run`：在指定服务中运行一个命令，创建一个临时容器。
- `scale`：设置指定服务运行的容器数量。
- `start`：启动已创建但未运行的服务。
- `stop`：停止正在运行的服务。
- `top`：显示正在运行的容器的进程信息。
- `unpause`：恢复之前暂停的服务。
- `up`：构建、创建并启动所有服务，如果服务已存在则重新启动。

### 示例 `docker-compose.yml` 文件

以下是一个详细的 `docker-compose.yml` 文件示例，包含注释和可能用到的所有指令。这个示例展示了如何定义一个包含多个服务（如 Nginx、Tomcat 和 MySQL）的 Docker Compose 项目。

```yaml
# docker-compose.yml

# 定义版本，指定 Compose 文件的格式版本
version: '3.8'

# 定义服务
services:
  # 定义 MySQL 服务
  mysql:
    # 使用的镜像名称
    image: mysql:5.7
    # 容器的名称
    container_name: mysql_container
    # 环境变量，用于设置 MySQL 的 root 密码
    environment:
      MYSQL_ROOT_PASSWORD: mypassword
      MYSQL_DATABASE: mydb
    # 持久化数据卷
    volumes:
      - mysql_data:/var/lib/mysql
    # 端口映射，将宿主机的 3306 端口映射到容器的 3306 端口
    ports:
      - "3306:3306"
    # 重启策略，始终重启
    restart: always
    # 网络配置，连接到默认网络
    networks:
      - my_network

  # 定义 Tomcat 服务
  tomcat:
    # 使用的镜像名称
    image: tomcat:9.0
    # 容器的名称
    container_name: tomcat_container
    # 环境变量，设置 Tomcat 的一些配置
    environment:
      - CATALINA_OPTS=-Xms512M -Xmx1024M
    # 持久化 Tomcat 的 webapps 目录
    volumes:
      - tomcat_webapps:/usr/local/tomcat/webapps
    # 端口映射，将宿主机的 8080 端口映射到容器的 8080 端口
    ports:
      - "8080:8080"
    # 依赖关系，确保 MySQL 服务先启动
    depends_on:
      - mysql
    # 重启策略，始终重启
    restart: always
    # 网络配置，连接到默认网络
    networks:
      - my_network

  # 定义 Nginx 服务
  nginx:
    # 使用的镜像名称
    image: nginx:1.19
    # 容器的名称
    container_name: nginx_container
    # 持久化 Nginx 的配置文件和静态资源
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./html:/usr/share/nginx/html
    # 端口映射，将宿主机的 80 端口映射到容器的 80 端口
    ports:
      - "80:80"
    # 依赖关系，确保 Tomcat 服务先启动
    depends_on:
      - tomcat
    # 重启策略，始终重启
    restart: always
    # 网络配置，连接到默认网络
    networks:
      - my_network

# 定义卷
volumes:
  # 定义 MySQL 数据卷
  mysql_data:
    driver: local
  # 定义 Tomcat webapps 卷
  tomcat_webapps:
    driver: local

# 定义网络
networks:
  # 定义默认网络
  my_network:
    driver: bridge
```

### 文件说明

1. **版本**：
   - `version: '3.8'`：指定 Compose 文件的格式版本。不同的版本支持不同的功能和语法。
2. **服务**：
   - `services`：定义项目中包含的所有服务。
   - 每个服务（如 `mysql`、`tomcat`、`nginx`）都有自己的配置，包括：
     - `image`：指定使用的 Docker 镜像。
     - `container_name`：指定容器的名称。
     - `environment`：设置环境变量。
     - `volumes`：定义数据卷，用于持久化数据或挂载本地文件。
     - `ports`：定义端口映射。
     - `depends_on`：定义服务之间的依赖关系。
     - `restart`：设置重启策略。
     - `networks`：定义服务所属的网络。
3. **卷**：
   - `volumes`：定义数据卷，用于持久化数据。这里定义了两个卷：`mysql_data` 和 `tomcat_webapps`。
4. **网络**：
   - `networks`：定义网络，用于服务之间的通信。这里定义了一个默认的桥接网络 `my_network`。

### 可能用到的 Docker Compose 命令

以下是在 `docker-compose.yml` 文件所在目录中可以执行的常用命令：

- **`docker-compose up`**：构建、创建并启动所有服务。如果服务已存在，则重新启动。
- **`docker-compose down`**：停止并删除所有容器、网络、卷以及由 `docker-compose up` 创建的镜像（可选）。
- **`docker-compose build`**：构建或重新构建服务中定义的镜像。
- **`docker-compose create`**：创建服务所需的所有容器，但不启动它们。
- **`docker-compose start`**：启动已创建但未运行的服务。
- **`docker-compose stop`**：停止正在运行的服务。
- **`docker-compose restart`**：重启服务中的所有容器。
- **`docker-compose kill`**：强制终止正在运行的容器。
- **`docker-compose rm`**：删除所有已停止的容器。
- **`docker-compose logs`**：查看容器的日志输出。
- **`docker-compose exec`**：在指定的容器中运行一个命令。
- **`docker-compose ps`**：列出所有由 `docker-compose` 管理的容器。
- **`docker-compose config`**：验证 Compose 文件格式是否正确，若无错误则不输出任何内容。
- **`docker-compose bundle`**：从当前 `docker-compose` 文件生成一个 JSON 格式的 Docker Bundle 文件，用于离线部署。
- **`docker-compose pull`**：从镜像仓库拉取服务中定义的镜像。
- **`docker-compose push`**：将服务中定义的镜像推送到镜像仓库。
- **`docker-compose scale`**：设置指定服务运行的容器数量。

# 实战案例

## 启动单个容器

一、编写docker-compose文件

```yaml
[root@localhost ~]# mkdir -pv docker-compose/nginx
[root@localhost ~]# cd docker-compose/nginx
[root@localhost nginx]# pwd
/root/docker-compose/nginx
[root@localhost nginx]# vim docker-compose.yml
# docker-compose.yml

services:
  nginx:
    image: nginx
    container_name: nginx_web1
    restart: always
    ports:
      - "80:80"
    volumes:
      - /data/web:/usr/share/nginx/html
```

二、启动容器

```bash
[root@localhost nginx]# docker compose up -d
[+] Running 2/2
 ✔ Network nginx_default  Created                                             0.0s
 ✔ Container nginx_web1   Started                                             0.2s
[root@localhost nginx]# docker ps
CONTAINER ID   IMAGE     COMMAND                  CREATED          STATUS          PORTS                                 NAMES
09d091a0c1a1   nginx     "/docker-entrypoint.…"   29 seconds ago   Up 28 seconds   0.0.0.0:80->80/tcp, [::]:80->80/tcp   nginx_web1

# 不指定网络的话，会默认创建一个类型为bridge的网络
[root@localhost nginx]# docker network ls
NETWORK ID     NAME            DRIVER    SCOPE
36f9c2f8e090   bridge          bridge    local
93ffe4510dd0   host            host      local
d0456365c64d   nginx_default   bridge    local
61f0d0d9b051   none            null      local
```

三、访问测试


## 启动多个容器

一、编辑docker-compose文件

```bash
[root@localhost docker]# cat docker-compose.yml 
service-nginx:
  image: nginx
  container_name: nginx_web1
  ports:
    - "80:80"

service-tomcat:
  image: tomcat
  container_name: tomcat_web1
  ports:
    - "8080:8080"
[root@localhost docker]# docker-compose up -d
nginx_web1    /docker-entrypoint.sh ngin ...   Up      0.0.0.0:80->80/tcp,:::80->80/tcp                              
tomcat_web1   catalina.sh run                  Up      0.0.0.0:8080->8080/tcp,:::8080-
                                                       >8080/tcp
```

## 定义数据卷挂载

- 创建数据卷目录和文件

```bash
[root@localhost docker]# mkdir -p /data/nginx
[root@localhost docker]# echo 'docker nginx' > /data/nginx/index.html
```

- 编辑配置文件

```bash
[root@localhost docker]# cat docker-compose.yml 
service-nginx:
  image: nginx
  container_name: nginx_web1
  volumes:
    - /data/nginx/:/usr/share/nginx/html
  ports:
    - "80:80"

service-tomcat:
  image: tomcat
  container_name: tomcat_web1
  ports:
    - "8080:8080"
```

- 访问测试

```bash
[root@localhost docker]# curl localhost
docker nginx
```

# Docker Compose部署LNMP实战

## 部署LNMP环境

- 使用docker-compose实现编排nginx+phpfpm+mysql容器
- 部署一个博客系统
- 首先编写一个如下的配置文件

```yaml
services:
  web:
    image: nginx:latest
    restart: always
    ports:
      - 80:80
    volumes:
      - /data/lnmp/nginx/conf.d:/etc/nginx/conf.d
      - /data/lnmp/nginx/html:/usr/share/nginx/html
      - /data/lnmp/nginx/log:/var/log/nginx
    depends_on:
      - php
      - mysql
    networks:
      - lnmp-network
  php:
    image: php:7.4-fpm
    restart: always
    volumes:
      - /data/lnmp/nginx/html:/usr/share/nginx/html
    networks:
      - lnmp-network
    depends_on:
      - mysql
  mysql:
    image: mysql:5.7
    restart: always
    volumes:
      - /data/lnmp/dbdata:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: "123456"
      MYSQL_DATABASE: login
    networks:
      - lnmp-network
networks:
  lnmp-network:
    driver: bridge
volumes:
  dbdata: null
```

运行docker-compose.yml

```bash
[root@localhost lnmp]# docker compose up -d
[root@localhost lnmp]# docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                                 NAMES
825b8630de47   nginx:latest   "/docker-entrypoint.…"   4 minutes ago   Up 4 minutes   0.0.0.0:80->80/tcp, [::]:80->80/tcp   lnmp-web-1
d1d6339ba0d7   lnmp-php       "docker-php-entrypoi…"   4 minutes ago   Up 4 minutes   9000/tcp                              lnmp-php-1
109672c0b1f0   mysql:5.7      "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes   3306/tcp, 33060/tcp                   lnmp-mysql-1
```

在`/data/lnmp/nginx/conf.d/default.conf`中写入nginx 的配置文件

```bash
server {
        listen 80;
        root /usr/share/nginx/html;
        location / {
                index index.php index.html;
         }

        location ~ \.php$ {
                fastcgi_pass php:9000;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
         }
}
```

准备探针测试

在`/data/lnmp/nginx/html/info.php`中准备php探针

```bash
<?php
	phpinfo();
?>
```

测试数据库连接

在`/data/lnmp/nginx/html/mysql.php`中准备php探针

```bash
<?php
    $dbhost = "mysql";
    $dbuser = "root";
    $dbpass = "123456";
    $db = "login";
    $conn = mysqli_connect($dbhost, $dbuser, $dbpass, $db) or exit("数据库连接失败！");
    echo "数据库连接成功";
?>
```

访问测试后发现，连接mysql报错，提示找不到mysqli_connect()，看来是官方构建的php没有mysqli模块

所以我们需要定制带有mysqli模块的php，编写如下dockerfile

```bash
FROM php:7.4-fpm
ENV TZ=Asia/Shanghai
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini" \
  && sed -i 's/deb.debian.org/mirrors.ustc.edu.cn/g' /etc/apt/sources.list \
  && sed -i -e 's|security.debian.org/\? |security.debian.org/debian-security |g' \
  -e 's|security.debian.org|mirrors.ustc.edu.cn|g' \
  -e 's|deb.debian.org/debian-security|mirrors.ustc.edu.cn/debian-security|g' \
  /etc/apt/sources.list \
  && apt-get update && apt-get install -y \
  libfreetype6-dev \
  libjpeg62-turbo-dev \
  libpng-dev \
  && docker-php-ext-configure gd -with-freetype -with-jpeg \
  && docker-php-ext-install -j$(nproc) gd mysqli && docker-php-ext-enable mysqli
```

然后修改docker-compose.yml文件如下

```yaml
# docker-compose build lnmp

services:
  web:
    image: nginx:latest
    restart: always
    ports:
      - 80:80
    volumes:
      - /data/lnmp/nginx/conf.d:/etc/nginx/conf.d
      - /data/lnmp/nginx/html:/usr/share/nginx/html
      - /data/lnmp/nginx/log:/var/log/nginx
    depends_on:
      - php
      - mysql
    networks:
      - lnmp-network
  php:
    # image: dockerfile:php:7.4-fpm
    # 这里来让compose自动构建，指定dockerfile的文件位置即可
    build:
      context: .
      dockerfile: dockerfile
    restart: always
    volumes:
      - /data/lnmp/nginx/html:/usr/share/nginx/html
    networks:
      - lnmp-network
    depends_on:
      - mysql
  mysql:
    image: mysql:5.7
    restart: always
    volumes:
      - /data/lnmp/dbdata:/var/lib/mysql
    environment:
      MYSQL_ROOT_PASSWORD: "123456"
      MYSQL_DATABASE: login
    networks:
      - lnmp-network
networks:
  lnmp-network:
    driver: bridge
volumes:
  dbdata: null
```

然后再次运行测试

```bash
[root@localhost lnmp]# docker compose up -d
[root@localhost lnmp]# docker ps
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                                 NAMES
825b8630de47   nginx:latest   "/docker-entrypoint.…"   4 minutes ago   Up 4 minutes   0.0.0.0:80->80/tcp, [::]:80->80/tcp   lnmp-web-1
d1d6339ba0d7   lnmp-php       "docker-php-entrypoi…"   4 minutes ago   Up 4 minutes   9000/tcp                              lnmp-php-1
109672c0b1f0   mysql:5.7      "docker-entrypoint.s…"   4 minutes ago   Up 4 minutes   3306/tcp, 33060/tcp                   lnmp-mysql-1
```
