#!/bin/bash

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
ROOT_DIR="$SCRIPT_DIR"  

source "$ROOT_DIR/logger.sh"
source "$ROOT_DIR/utils/check_utils.sh"
source "$ROOT_DIR/utils/utils.sh"

# 主要安装流程

log_info "开始安装Containerd"

# 检查必要的命令

check_command "systemctl" || exit 1

# 检查并安装wget

if ! check_command "wget"; then
    log_info "安装wget工具"
    yum -y install wget || exit 1
fi

# 安装containerd

if [ ! -f "/usr/local/bin/containerd" ]; then
    log_info "安装containerd"

    if [ ! -f "/usr/bin/containerd" ]; then
        if [ -f "containerd-2.0.5-linux-amd64.tar.gz" ]; then
            log_info "使用本地containerd安装包"
        else
            log_info "本地安装不存在，开始下载containerd安装包"
            wget https://github.com/containerd/containerd/releases/download/v2.0.5/containerd-2.0.5-linux-amd64.tar.gz || exit 1
        fi
    
        tar -xzvf containerd-2.0.5-linux-amd64.tar.gz -C /usr/local
        chmod +x /usr/local/bin/containerd
        rm -f containerd-2.0.5-linux-amd64.tar.gz
    fi

fi

# 安装runc

if [ ! -f "/usr/local/sbin/runc" ]; then
    log_info "安装runc"

    if [ ! -f "/usr/local/bin/runc" ]; then
        if [ -f "runc.amd64" ]; then
            log_info "使用本地runc安装包"
        else
            log_info "本地安装不存在，开始下载runc安装包"
            wget https://github.com/opencontainers/runc/releases/download/v1.2.6/runc.amd64 || exit 1
        fi
    
        install -m 755 runc.amd64 /usr/local/sbin/runc || exit 1
    fi

fi

# 创建 containerd 的 systemd 服务文件

log_info "配置 containerd systemd 服务"
cat <<EOF > /etc/systemd/system/containerd.service
[Unit]
Description=containerd container runtime
Documentation=https://containerd.io
After=network.target

[Service]
ExecStartPre=/sbin/modprobe overlay
ExecStart=/usr/local/bin/containerd
Restart=always
RestartSec=5
Delegate=yes
KillMode=process
OOMScoreAdjust=-999
LimitNOFILE=1048576
LimitNPROC=infinity
LimitCORE=infinity

[Install]
WantedBy=multi-user.target
EOF

#安装CNI

if [ ! -f "/opt/cni/bin" ];then
    log_info "安装CNI插件"
    wget https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-amd64-v1.6.2.tgz|| exit 1
    mkdir -p /opt/cni/bin
    tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.6.2.tgz
    log_info "CNI插件安裝成功"
fi


# 重新加载 systemd 并启动 containerd

log_info "启动 containerd 服务"
systemctl daemon-reload
systemctl enable --now containerd

# 检查服务状态

if systemctl is-active --quiet containerd; then
    log_info "containerd 已成功启动！"
else
    log_error "containerd 启动失败，请检查日志！"
    journalctl -u containerd -xe
    exit 1
fi


# 启动服务

systemctl daemon-reload
systemctl enable --now containerd

log_info "Containerd安装完成"

