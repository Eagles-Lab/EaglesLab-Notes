#!/bin/bash

CURRENT_DIR=$(dirname "$0")
ROOT_DIR=$(cd "$CURRENT_DIR/.." && pwd)

# 导入日志模块和检查工具模块
source $ROOT_DIR/logger.sh
source $ROOT_DIR/utils/utils.sh

# 导入基础安装脚本
source $ROOT_DIR/install/install_base.sh
run_base_install

# 集群状态检查
if [ -f /etc/kubernetes/admin.conf ]; then
    log_warn "检测到已存在的集群配置"
    exit 0
fi

log_info "开始初始化Kubernetes控制平面"
kubeadm init \
    --apiserver-advertise-address=${apiserver} \
    --image-repository registry.aliyuncs.com/google_containers \
    --kubernetes-version 1.29.2 \
    --service-cidr=10.10.0.0/12 \
    --pod-network-cidr=10.244.0.0/16 \
    --ignore-preflight-errors=all \
    --cri-socket unix:///var/run/cri-dockerd.sock

if [ $? -ne 0 ]; then
    log_error "控制平面初始化失败，请检查错误日志"
    exit 1
fi

# 生成join命令备份
log_info "保存节点加入命令到 ${ROOT_DIR}/join_command.sh"
kubeadm token create --print-join-command 2>/dev/null | sed 's/$/ --cri-socket unix:\/\/\/var\/run\/cri-dockerd.sock/' > ${ROOT_DIR}/join_command.sh
chmod 600 ${ROOT_DIR}/join_command.sh

# 配置kubectl访问权限
mkdir -p $HOME/.kube
cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

log_info "主节点初始化完成，节点加入命令已保存至 ${ROOT_DIR}/join_command.sh"

# 安装网络插件calico
log_info "安装网络插件calico"
download_file calico-typha.yaml
kubectl apply -f calico-typha.yaml

# 安装metrics-server

# 检查master01节点Ready
while true; do
    STATUS=$(kubectl get nodes -o jsonpath='{.items[?(@.metadata.name=="master01")].status.conditions[?(@.type=="Ready")].status}')
    if [ "$STATUS" == "True" ]; then
        log_info "master01节点状态正常"
        break
    else
        log_warn "master01节点状态异常，正在重试..."
        sleep 5
    fi
done