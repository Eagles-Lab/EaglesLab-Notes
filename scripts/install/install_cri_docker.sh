#!/bin/bash

CURRENT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$CURRENT_DIR/.." && pwd)

# 导入日志模块和检查工具模块
source $ROOT_DIR/logger.sh
source $ROOT_DIR/utils/check_utils.sh
source $ROOT_DIR/utils/utils.sh

# 主要安装流程
log_info "开始安装CRI-Docker"

# 检查必要的命令
check_command "systemctl" || exit 1

# 检查并安装wget
if ! check_command "wget"; then
    log_info "安装wget工具"
    yum -y install wget || exit 1
fi

# 安装cri-docker
if [ ! -f "/usr/bin/cri-dockerd" ]; then
    log_info "安装cri-dockerd"
    if [ -f "cri-dockerd-0.3.9.amd64.tgz" ]; then
        log_info "使用本地cri-dockerd安装包"
    else
        log_info "本地安装包不存在，开始下载cri-dockerd安装包"
        # wget https://github.com/Mirantis/cri-dockerd/releases/download/v0.3.9/cri-dockerd-0.3.9.amd64.tgz
        download_file cri-dockerd-0.3.9.amd64.tgz
    fi
    tar -xf cri-dockerd-0.3.9.amd64.tgz
    cp cri-dockerd/cri-dockerd /usr/bin/
    chmod +x /usr/bin/cri-dockerd
    rm -f cri-dockerd-0.3.9.amd64.tgz
    rm -rf cri-dockerd
fi

# 配置cri-docker服务
log_info "配置cri-docker服务"
if [ ! -f "/usr/lib/systemd/system/cri-docker.service" ]; then
    cat > /usr/lib/systemd/system/cri-docker.service <<EOF
[Unit]
Description=CRI Interface for Docker Application Container Engine
Documentation=https://docs.mirantis.com
After=network-online.target firewalld.service docker.service
Wants=network-online.target
Requires=cri-docker.socket
[Service]
Type=notify
ExecStart=/usr/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.8
ExecReload=/bin/kill -s HUP $MAINPID
TimeoutSec=0
RestartSec=2
Restart=always
StartLimitBurst=3
StartLimitInterval=60s
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
TasksMax=infinity
Delegate=yes
KillMode=process
[Install]
WantedBy=multi-user.target
EOF
fi

# 添加cri-docker套接字
log_info "配置cri-docker套接字"
if [ ! -f "/usr/lib/systemd/system/cri-docker.socket" ]; then
    cat > /usr/lib/systemd/system/cri-docker.socket <<EOF
[Unit]
Description=CRI Docker Socket for the API
PartOf=cri-docker.service
[Socket]
ListenStream=%t/cri-dockerd.sock
SocketMode=0660
SocketUser=root
SocketGroup=docker
[Install]
WantedBy=sockets.target
EOF
fi

# 启动cri-docker服务
log_info "启动cri-docker服务"
systemctl daemon-reload
systemctl enable cri-docker
systemctl start cri-docker

# 检查服务状态
if systemctl is-active cri-docker &> /dev/null; then
    log_info "cri-docker服务已成功启动"
else
    log_error "cri-docker服务启动失败"
    exit 1
fi

log_info "CRI-Docker安装完成"