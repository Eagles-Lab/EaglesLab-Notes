# 背景介绍
Docker 镜像制作类似于虚拟机的模板制作，即按照公司的实际业务将需要安装的软件、相关配置等基础环境配置完成，然后将虚拟机再提交为模板，最后再批量从模板批量创建新的虚拟机，这样可以极大地简化业务中相同环境的虚拟机运行环境的部署工作，Docker的镜像制作分为手动制作可自动制作（基于 DockerFile ），企业通常都是基于 DockerFile 制作镜像。

# 手动制作nginx镜像
```shell
[root@docker-server ~]# docker run -it ubuntu bash
root@1d8e32ab39d6:/# apt-get update & apt-get install nginx curl vim-tiny -y
root@1d8e32ab39d6:/# echo 'eagleslab nginx' > /var/www/html/index.nginx-debian.html
root@1d8e32ab39d6:/# grep daemon /etc/nginx/nginx.conf
daemon off;

# 提交为镜像
Usage:  docker commit [OPTIONS] CONTAINER [REPOSITORY[:TAG]]
[root@docker-server ~]# docker commit -a "v100" -m "my nginx image v1" 0195bc1d0f7b ubuntu_nginx:v1

# 通过ubuntu_nginx:v1镜像启动容器
[root@docker-server ~]# docker run  -d -p 8081:80 ubuntu_nginx:v1
[root@docker-server ~]# curl 127.0.0.1:8081
```
**适用场景**：主要作用是将配置好的一些容器复用，再生成新的镜像。
commit是合并了save、load、export、import这几个特性的一个综合性的命令，它主要做了：
1. 将容器当前的读写层保存成一个新层。
2. 和镜像的历史层一起合并成一个新的镜像
3. 如果原本的镜像有3层，commit之后就会有4层，最新的一层为从镜像运行到commit之间对文件系统的修改。

# DockerFile制作镜像
DockerFile可以说是一种可以被Docker程序解释的脚本，DockerFile是由一条条的命令组成的，每条命令对应linux下面的一条命令，Docker程序将这些DockerFile指令再翻译成真正的linux命令，其有自己的书写方式和支持的命令，Docker程序读取DockerFile并根据指令生成Docker镜像，相比手动制作镜像的方式，DockerFile更能直观地展示镜像是怎么产生的，有了写好的各种各样的DockerFIle文件，当后期某个镜像有额外的需求时，只要在之前的DockerFile添加或者修改相应的操作即可重新生成新的Docker镜像，避免了重复手动制作镜像的麻烦。

## 最佳实践
```shell
# Dockerfile
## 使用官方 Ubuntu 22.04 LTS 作为基础镜像
FROM ubuntu:22.04

## 设置环境变量避免交互式提示
ENV DEBIAN_FRONTEND=noninteractive

## 安装 Nginx 并清理缓存（合并操作用于减少镜像层）
RUN apt-get update && \
    apt-get install -y \
    nginx \
    # 安装常用工具（可选）
    curl \
    vim-tiny && \
    # 清理APT缓存
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

## 删除默认配置文件（按需保留）
RUN rm /etc/nginx/sites-enabled/default

## 暴露 HTTP 和 HTTPS 端口
EXPOSE 80 443

## 创建日志目录（确保日志可持久化）
RUN mkdir -p /var/log/nginx && \
    chown -R www-data:www-data /var/log/nginx

## 添加自定义配置（示例文件需存在于构建上下文）
# COPY nginx.conf /etc/nginx/nginx.conf
# COPY sites-available/ /etc/nginx/sites-available/

## 设置健康检查
HEALTHCHECK --interval=30s --timeout=3s \
    CMD curl -f http://localhost/ || exit 1

## 以非root用户运行（Ubuntu官方nginx包已使用www-data用户）
USER www-data

## 启动Nginx并保持前台运行
CMD ["nginx", "-g", "daemon off;"]

# 通过Dockerfile构建镜像
[root@docker-server ~]# docker build -t nginx:v1 .
```
## 优化说明
- 层合并: 将多个`RUN`指令合并以减少镜像层数
- 缓存清理: 清理APT缓存减小镜像体积
- 安全实践: 非root用户运行；只读挂载配置文件
- 可维护性: 显式声明暴露端口；健康检查配置；日志目录持久化
- 稳定性: 指定精确的ubuntu版本；禁用Nginx后台模式
  

## 指令说明
操作指令

| 指令   | 说明                         |
| ------ | ---------------------------- |
| `RUN`  | 运行指定命令                 |
| `CMD`  | 启动容器时指定默认执行的命令 |
| `ADD`  | 添加内容到镜像               |
| `COPY` | 复制内容到镜像               |

配置指令

| 指令          | 说明                               |
| ------------- | ---------------------------------- |
| `ARG`         | 定义创建镜像过程中使用的变量       |
| `FROM`        | 指定所创建镜像的基础镜像           |
| `LABEL`       | 为生成的镜像添加元数据标签信息     |
| `EXPOSE`      | 声明镜像内服务监听的端口           |
| `ENV`         | 指定环境变量                       |
| `ENTRYPOINT`  | 指定镜像的默认入口命令             |
| `VOLUME`      | 创建一个数据卷挂载点               |
| `USER`        | 指定运行容器时的用户名或UID        |
| `WORKDIR`     | 配置工作目录                       |
| `ONBUILD`     | 创建子镜像时指定自动执行的操作指令 |
| `STOPSIGNAL`  | 指定退出的信号值                   |
| `HEALTHCHECK` | 配置所启动容器如何进行健康检查     |
| `SHELL`       | 指定默认shell类型                  |


**注意事项**
```shell
# RUN
- 运行指定命令
- 每条RUN指令将在当前镜像基础上执行指定命令，并提交为新的镜像层
- 当命令较长时可以使用\来换行

# CMD
- 每个Dockerfile只能有一条CMD命令。如果指定了多条命令，只有最后一条会被执行
- CMD指令用来指定启动容器时默认执行的命令,支持三种格式:
    CMD ["executable","param1","param2"] 
    CMD command param1 param2`
    CMD ["param1","param2"]

# ADD
- 该命令将复制指定的src路径下内容到容器中的dest路径下
- src可以是DockerFIle所在目录的一个相对路径，也可以是一个url，还可以是一个tar
- dest可以是镜像内绝对路径，或者相对于工作目录的相对路径

# COPY
- COPY与ADD指令功能类似，当使用本地目录为源目录时，推荐使用COPY

# ARG
- 定义创建过程中使用到的变量；比如:HTTP_PROXY 、HTTPS_PROXY 、FTP_PROXY 、NO_PROXY不区分大小写。

# FROM
- 指定所创建镜像的基础镜像：为了保证镜像精简，可以选用体积较小的Alpin或Debian作为基础镜像

# EXPOSE
- 声明镜像内服务监听的端口：该指令只是起到声明作用，并不会自动完成端口映射

# ENTRYPOINT
- 指定镜像的默认入口命令，该入口命令会在启动容器时作为根命令执行，所有传入值作为该命令的参数支持两种格式:
    ENTRYPOINT ["executable","param1","param2"]
    ENTRYPOINT command param1 param2
- 此时CMD指令指定值将作为根命令的参数
- 每个DockerFile中只能有一个ENTRYPOINT，当指定多个时只有最后一个起效

# VOLUME: 创建一个数据卷挂载点

# WORKDIR
- 为后续的RUN、CMD、ENTRYPOINT指令配置工作目录：建议使用绝对路径
```