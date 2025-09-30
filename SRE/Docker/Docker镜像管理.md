# 镜像

容器是一个独立的进程，它从哪里获取文件和配置？如何共享这些环境？

镜像是一个标准化包，其中包含运行容器所需的所有文件、二进制文件、库和配置。
- MySQL 镜像会打包数据库二进制文件、配置文件和其他依赖项。
- Python Web 应用镜像会打包 Python 运行时、应用代码及其所有依赖项。

镜像两个重要原则：
1. 镜像是不可变的。一旦创建，就无法修改。只能创建新镜像或在其上进行更改。
2. 镜像由层组成。每一层代表一组文件系统变更，包括添加、删除或修改文件。


# 镜像管理

## 搜索镜像

`Usage:  docker search [OPTIONS] TERM`
```shell
# 搜索包含关键字的镜像
[root@docker-server ~]# docker search centos
```
可以看到返回了很多包含关键字的镜像，其中包括镜像名字、描述、点赞数（表示该镜像的受欢迎程度）、是否官方创建、是否自动创建。默认输出结果按照星级评价进行排序。

![img](docker镜像管理/docker_hub搜索.png)


## 下载镜像

`Usage:  docker pull [OPTIONS] NAME[:TAG|@DIGEST]`
```shell
# 下载nginx、centos、hello-world镜像
[root@docker-server ~]# docker pull nginx
[root@docker-server ~]# docker pull centos
[root@docker-server ~]# docker pull hello-world
```
其中，NAME是镜像名称，TAG是镜像的标签（往往用来是表示版本信息），通常情况下，描述一个镜像需要包括名称+标签，如果不指定标签，标签的值默认为latest。


## 镜像列表

`Usage:  docker image COMMAND`
```shell
# 列出本地所有镜像
[root@docker-server ~]# docker image ls
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    d1a364dc548d   2 weeks ago    133MB
...

# 字段说明
- REPOSITORY：镜像仓库名称
- TAG：镜像的标签信息
- 镜像ID：唯一用来标识镜像，如果两个镜像的ID相同，说明他们实际上指向了同一个镜像，只是具有不同标签名称而已
- CREATED：创建时间，说明镜像的最后更新时间
- SIZE：镜像大小，优秀的镜像往往体积都较小
```


## 镜像标签

`Usage:  docker image tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]`
```shell
[root@docker-server ~]# docker tag centos:latest mycentos:latest
[root@docker-server ~]# docker images
REPOSITORY    TAG       IMAGE ID       CREATED        SIZE
nginx         latest    d1a364dc548d   2 weeks ago    133MB
...
```


## 镜像信息

`Usage:  docker image inspect [OPTIONS] IMAGE [IMAGE...]`
```shell
[root@docker-server ~]# docker inspect centos:latest 
[
    {
        "Id": "sha256:300e315adb2f96afe5f0b2780b87f28ae95231fe3bdd1e16b9ba606307728f55",
        "RepoTags": [
            "centos:latest",
            "mycentos:latest"
        ]
        ...
    }
]
```

## 镜像创建信息

`Usage:  docker image history [OPTIONS] IMAGE`
```shell
[root@docker-server ~]# docker history centos:latest 
IMAGE          CREATED        CREATED BY                                      SIZE      COMMENT
300e315adb2f   6 months ago   /bin/sh -c #(nop)  CMD ["/bin/bash"]            0B        
...
```

## 镜像导出

`Usage:  docker image save [OPTIONS] IMAGE [IMAGE...]`
```shell
[root@docker-server ~]# docker image save centos:latest -o /opt/centos.tar.gz
[root@docker-server ~]# ll /opt/centos.tar.gz 
-rw------- 1 root root 216535040 6月   9 10:33 /opt/centos.tar.gz
[root@docker-server ~]# docker image save centos:latest > /opt/centos-1.tar.gz
[root@docker-server ~]# ll /opt/centos-1.tar.gz 
-rw-r--r-- 1 root root 216535040 6月   9 10:35 /opt/centos-1.tar.gz
```

## 镜像导入

`Usage:  docker image load [OPTIONS]`
```shell
[root@docker-server ~]# docker image load -i /opt/centos.tar.gz 
Loaded image: centos:latest
[root@docker-server ~]# docker image load < /opt/centos.tar.gz 
Loaded image: centos:latest
```

## 删除镜像

`Usage:  docker image rm [OPTIONS] IMAGE [IMAGE...]`
```shell
[root@docker-server ~]# docker image rm nginx:latest 
Untagged: nginx:latest
Untagged: nginx@sha256:6d75c99af15565a301e48297fa2d121e15d80ad526f8369c526324f0f7ccb750
[root@docker-server ~]# docker image rm 300e315adb2f
...
```
