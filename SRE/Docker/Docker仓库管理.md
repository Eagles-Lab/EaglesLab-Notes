# 公共仓库
## 官方Docker仓库
1. 准备账户: 登陆到[Docker Hub](https://hub.docker.com/)官网创建账号，登陆后点击settings完善信息。
2. 填写账户基本信息: 重置密码/生成`accesstoken`
3. `docker login docker.io` 输入用户密码即可
4. 国内可能因为网络问题，需要代理
   
## 阿里云镜像仓库
1. 准备账户: 登录到[Aliyun Hub](https://cr.console.aliyun.com/)官网创建账号
2. 容器镜像服务->实例列表->镜像仓库->创建镜像仓库
3. 执行操作指南

```shell
# 1.登录阿里云Docker Registry
$ docker login --username=15295733404 registry.cn-hangzhou.aliyuncs.com
# 2.从Registry中拉取镜像
$ docker pull registry.cn-hangzhou.aliyuncs.com/zhaohao/eagleslab:[镜像版本号]
# 3.将镜像推送到Registry
$ docker login --username=15295733404 registry.cn-hangzhou.aliyuncs.com
$ docker tag [ImageId] registry.cn-hangzhou.aliyuncs.com/zhaohao/eagleslab:[镜像版本号]
$ docker push registry.cn-hangzhou.aliyuncs.com/zhaohao/eagleslab:[镜像版本号]
# 4.选择合适的镜像仓库地址: 公网访问/VPC网络内访问
```

# 私有仓库
## docker registry
Docker Register作为Docker的核心组件之一负责镜像内容的存储与分发，客户端的docker pull以及push命令都将直接与register进行交互，最初版本的registry由python实现的，由于涉及初期在安全性、性能以及API的设计上有着诸多的缺陷，该版本在0.9之后停止了开发，由新的项目distribution（新的docker register被称为Distribution）来重新设计并开发了下一代的registry，新的项目由go语言开发，所有的api底层存储方式，系统架构都进行了全面的重新设计已解决上一代registry的问题。

官方文档地址：https://docs.docker.com/registry

官方github地址: https://github.com/docker/distribution

**部署**
```shell
# 执行安装脚本
[root@master01 scripts]# ./install/install_registry.sh
```

## 企业级方案Harbor
参考网址：https://goharbor.io/docs/2.3.0/install-config/

Harbor是一个用于存储和分发Docker镜像的企业级Registry服务器，由vmware开源，其通过添加一些企业必须的功能特性，例如安全、标识和管理等，扩展了开源的Docker Distribution。Harbor也提供了高级的安全特性，诸如用户管理，访问控制和活动审计等。

**部署**
```bash
# 1.准备安装包
[root@docker-server1 ~]# wget https://github.com/goharbor/harbor/releases/download/v2.3.1/harbor-offline-installer-v2.3.1.tgz
[root@docker-server1 ~]# tar xzvf harbor-offline-installer-v2.3.1.tgz 
[root@docker-server1 ~]# ln -sv /root/harbor /usr/local/
"/usr/local/harbor" -> "/root/harbor"
# 2.配置文件
[root@docker-server1 harbor]# cp harbor.yml.tmpl harbor.yml
[root@docker-server1 harbor]# grep -Ev '#|^$' harbor.yml.tmpl > harbor.yml
[root@docker-server1 harbor]# cat harbor.yml
# 3.执行安装
[root@docker-server1 harbor]# ./prepare 
[root@docker-server1 harbor]# ./install.sh 
# 之后的启动关闭可以通过docker-compose管理，自动生成docker-compose.yml文件
[root@docker-server1 harbor]# ls
common     docker-compose.yml    harbor.yml       install.sh  prepare
common.sh  harbor.v2.3.1.tar.gz  harbor.yml.tmpl  LICENSE
```
**web访问**
默认用户名和密码在harbor.yml中设置为：harbor_admin_password: Harbor12345

**推送镜像**
参考网站推送教学

```bash
# 登录
[root@docker-server2 ~]# grep 'insecure' /etc/docker/daemon.json
"insecure-registries":["192.168.175.10"]
[root@docker-server2 ~]# systemctl daemon-reload & systemctl restart docker
[root@docker-server2 ~]# docker login 192.168.204.135
Username: admin
Password: 
...
Login Succeeded
[root@admin harbor]# docker-compose restart

# 推送
[root@docker-server2 nginx]# docker tag nginx:v1 192.168.175.10/eagles/nginx:v1
[root@docker-server2 nginx]# docker push 192.168.175.10/eagles/nginx:v1
```
