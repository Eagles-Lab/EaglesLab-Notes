#!/bin/bash

CURRENT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$CURRENT_DIR/.." && pwd)

# 导入日志模块和检查工具模块
source $ROOT_DIR/logger.sh
source $ROOT_DIR/utils/check_utils.sh
source $ROOT_DIR/utils/utils.sh

# 设置目标版本
TARGET_VERSION="1.29.2"

# 检查是否为root用户
if [ "$(id -u)" != "0" ]; then
    log_error "此脚本必须以root用户运行"
    exit 1
fi

# 检查是否已安装kubelet
if command -v kubelet >/dev/null 2>&1; then
    INSTALLED_VERSION=$(kubelet --version | cut -d ' ' -f 2)
    if [ "$INSTALLED_VERSION" = "v${TARGET_VERSION}" ]; then
        log_info "kubelet ${TARGET_VERSION} 已安装，跳过安装步骤"
        exit 0
    else
        log_warn "发现已安装的kubelet版本: $INSTALLED_VERSION，将进行更新"
    fi
fi

# 备份已存在的kubernetes.repo文件
KUBE_REPO_FILE="/etc/yum.repos.d/kubernetes.repo"
if [ -f "$KUBE_REPO_FILE" ]; then
    BACKUP_FILE="${KUBE_REPO_FILE}.bak.$(date +%Y%m%d%H%M%S)"
    log_info "备份现有的kubernetes.repo文件到 $BACKUP_FILE"
    if ! cp "$KUBE_REPO_FILE" "$BACKUP_FILE"; then
        log_error "无法备份kubernetes.repo文件"
        exit 1
    fi
fi

# 添加 kubeadm yum 源
log_info "配置kubernetes yum源"
cat <<EOF > "$KUBE_REPO_FILE"
[kubernetes]
name=Kubernetes
baseurl=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://mirrors.aliyun.com/kubernetes-new/core/stable/v1.29/rpm/repodata/repomd.xml.key
EOF

# 验证repo文件是否创建成功
if [ ! -f "$KUBE_REPO_FILE" ]; then
    log_error "kubernetes.repo文件创建失败"
    exit 1
fi

# 设置解压相关变量
base_name="${ROOT_DIR}/kubernetes-1.29.2-150500.1.1.tar.gz"
tmp_name=$(basename  ${base_name} .tar.gz)
hash_file="/tmp/.kubernetes-1.29.2-150500.1.1_archive_hash"
extract_base_dir="/tmp/$tmp_name-latest"
extract_dir="$extract_base_dir/$tmp_name"

# 检查压缩包是否需要解压
check_archive_unchanged "$base_name" "$hash_file" "$extract_base_dir"
case $? in
    0)  # 压缩包未变更，无需解压
        ;;
    1)  # 解压失败
        exit 1
        ;;
    2)  # 解压成功
        ;;
esac

# 安装本地RPM包
if ! yum localinstall -y ${extract_dir}/*.rpm; then
    log_error "本地RPM包安装失败"
    exit 1
fi
log_info "本地RPM包安装成功"

# 启用kubelet服务
log_info "启用kubelet服务"
if ! systemctl enable --now kubelet.service; then
    log_error "无法启用kubelet服务"
    exit 1
fi

log_info "安装完成！kubelet、kubectl 和 kubeadm ${TARGET_VERSION} 已成功安装"