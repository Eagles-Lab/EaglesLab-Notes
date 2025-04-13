#!/bin/bash

# 导入日志模块和检查工具模块
source $(dirname "$0")/logger.sh
source $(dirname "$0")/check_utils.sh
source $(dirname "$0")/utils.sh

# 主要安装流程
log_info "开始安装Docker CE"

# 检查必要的命令
check_command "dnf" || exit 1
check_command "systemctl" || exit 1

# 检查并安装wget
if ! check_command "wget"; then
    log_info "安装wget工具"
    yum -y install wget || exit 1
fi

# 检查Docker是否已安装
if ! check_docker; then
    # 添加docker-ce yum源
    log_info "添加docker-ce yum源(中科大)"
    sudo dnf config-manager --add-repo https://mirrors.ustc.edu.cn/docker-ce/linux/centos/docker-ce.repo
    
    # 切换中科大源
    if [ -f "/etc/yum.repos.d/docker-ce.repo" ]; then
        log_info "切换到中科大源"
        sed -i 's#download.docker.com#mirrors.ustc.edu.cn/docker-ce#g' /etc/yum.repos.d/docker-ce.repo
    fi

    # 安装docker-ce
    log_info "安装docker-ce"
    yum -y install docker-ce
fi

# 配置daemon
log_info "配置Docker daemon"
check_directory "/etc/docker"
check_directory "/etc/systemd/system/docker.service.d"
check_directory "/data/docker"

if [ ! -f "/etc/docker/daemon.json" ] || ! grep -q "data-root" "/etc/docker/daemon.json"; then
    cat > /etc/docker/daemon.json <<EOF
{
  "data-root": "/data/docker",
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m",
    "max-file": "100"
  },
  "insecure-registries": ["iproute.cn:6443"],
  "registry-mirrors": ["https://iproute.cn:6443"]
}
EOF
    log_info "已创建Docker daemon配置文件"
fi

# 重启docker服务
log_info "重启Docker服务"
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

log_info "Docker CE安装完成"