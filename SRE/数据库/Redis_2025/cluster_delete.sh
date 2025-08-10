#!/bin/bash

# Redis集群删除脚本
# 功能：删除指定Redis集群，包括停止服务、销毁集群、清理配置文件
# 作者：EaglesLab
# 日期：2025

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示使用说明
show_usage() {
    echo "使用方法: $0 <集群配置目录>"
    echo "示例: $0 /path/to/redis-cluster"
    echo ""
    echo "说明:"
    echo "  集群配置目录应包含Redis节点的配置文件和数据文件"
    echo "  脚本会自动检测目录中的Redis实例并进行删除操作"
}

# 检查参数
if [ $# -ne 1 ]; then
    print_error "参数错误！"
    show_usage
    exit 1
fi

CLUSTER_DIR="$1"

# 检查目录是否存在
if [ ! -d "$CLUSTER_DIR" ]; then
    print_error "目录不存在: $CLUSTER_DIR"
    exit 1
fi

# 转换为绝对路径
CLUSTER_DIR=$(cd "$CLUSTER_DIR" && pwd)

print_info "准备删除Redis集群: $CLUSTER_DIR"

# 检查目录中是否有Redis配置文件
redis_configs=$(find "$CLUSTER_DIR" -name "redis.conf" -o -name "redis_*.conf" 2>/dev/null || true)
if [ -z "$redis_configs" ]; then
    print_warning "在目录 $CLUSTER_DIR 中未找到Redis配置文件"
    print_info "继续执行将删除整个目录及其内容"
else
    print_info "发现以下Redis配置文件:"
    echo "$redis_configs" | while read -r config; do
        echo "  - $config"
    done
fi

# 获取运行中的Redis进程信息
get_redis_processes() {
    local cluster_dir="$1"
    # 查找与集群目录相关的Redis进程
    ps aux | grep redis-server | grep -v grep | grep "$cluster_dir" || true
}

# 显示将要删除的内容
print_warning "=== 删除操作概览 ==="
print_warning "将要删除的目录: $CLUSTER_DIR"
print_warning "目录大小: $(du -sh "$CLUSTER_DIR" 2>/dev/null | cut -f1 || echo '未知')"

# 检查运行中的Redis进程
running_processes=$(get_redis_processes "$CLUSTER_DIR")
if [ -n "$running_processes" ]; then
    print_warning "发现运行中的Redis进程:"
    echo "$running_processes" | while read -r process; do
        echo "  $process"
    done
else
    print_info "未发现运行中的Redis进程"
fi

echo ""
print_warning "警告: 此操作将永久删除集群数据，无法恢复！"
echo ""

# 第一次确认
read -p "$(echo -e "${YELLOW}确认要删除Redis集群吗？请输入 'yes' 继续: ${NC}")" first_confirm
if [ "$first_confirm" != "yes" ]; then
    print_info "操作已取消"
    exit 0
fi

echo ""
print_error "最后确认: 即将删除 $CLUSTER_DIR 及其所有内容！"
read -p "$(echo -e "${RED}请再次输入 'DELETE' 确认删除操作: ${NC}")" second_confirm
if [ "$second_confirm" != "DELETE" ]; then
    print_info "操作已取消"
    exit 0
fi

echo ""
print_info "开始删除Redis集群..."

# 停止Redis服务
stop_redis_services() {
    local cluster_dir="$1"
    
    print_info "正在停止Redis服务..."
    
    # 方法1: 通过配置文件查找并停止Redis进程
    find "$cluster_dir" -name "*.conf" | while read -r config_file; do
        if grep -q "^port" "$config_file" 2>/dev/null; then
            port=$(grep "^port" "$config_file" | awk '{print $2}')
            if [ -n "$port" ]; then
                print_info "尝试停止端口 $port 上的Redis服务..."
                redis-cli -p "$port" shutdown nosave 2>/dev/null || true
                sleep 1
            fi
        fi
    done
    
    # 方法2: 强制终止与集群目录相关的Redis进程
    local pids=$(ps aux | grep redis-server | grep "$cluster_dir" | grep -v grep | awk '{print $2}' || true)
    if [ -n "$pids" ]; then
        print_info "强制终止剩余的Redis进程..."
        echo "$pids" | while read -r pid; do
            if [ -n "$pid" ]; then
                print_info "终止进程 PID: $pid"
                kill -TERM "$pid" 2>/dev/null || true
                sleep 2
                # 如果进程仍然存在，使用KILL信号
                if kill -0 "$pid" 2>/dev/null; then
                    print_warning "强制杀死进程 PID: $pid"
                    kill -KILL "$pid" 2>/dev/null || true
                fi
            fi
        done
    fi
    
    # 等待进程完全停止
    sleep 3
    
    # 验证是否还有运行中的进程
    remaining_processes=$(get_redis_processes "$cluster_dir")
    if [ -n "$remaining_processes" ]; then
        print_warning "仍有Redis进程在运行:"
        echo "$remaining_processes"
        print_warning "请手动停止这些进程后重新运行脚本"
        return 1
    else
        print_success "所有Redis服务已停止"
        return 0
    fi
}

# 销毁集群配置
destroy_cluster() {
    local cluster_dir="$1"
    
    print_info "正在销毁集群配置..."
    
    # 尝试通过任意一个节点重置集群
    find "$cluster_dir" -name "*.conf" | head -1 | while read -r config_file; do
        if [ -n "$config_file" ] && grep -q "^port" "$config_file" 2>/dev/null; then
            port=$(grep "^port" "$config_file" | awk '{print $2}')
            if [ -n "$port" ]; then
                print_info "尝试通过端口 $port 重置集群..."
                timeout 10 redis-cli -p "$port" cluster reset hard 2>/dev/null || true
            fi
        fi
    done
    
    print_success "集群配置销毁完成"
}

# 清理配置文件和数据
cleanup_files() {
    local cluster_dir="$1"
    
    print_info "正在清理配置文件和数据..."
    
    # 删除集群相关文件
    find "$cluster_dir" -name "nodes-*.conf" -delete 2>/dev/null || true
    find "$cluster_dir" -name "dump.rdb" -delete 2>/dev/null || true
    find "$cluster_dir" -name "appendonly.aof" -delete 2>/dev/null || true
    find "$cluster_dir" -name "*.log" -delete 2>/dev/null || true
    find "$cluster_dir" -name "*.pid" -delete 2>/dev/null || true
    
    print_success "临时文件清理完成"
}

# 删除整个目录
delete_directory() {
    local cluster_dir="$1"
    
    print_info "正在删除集群目录: $cluster_dir"
    
    if rm -rf "$cluster_dir"; then
        print_success "集群目录删除成功"
    else
        print_error "删除集群目录失败"
        return 1
    fi
}

# 执行删除操作
main() {
    local cluster_dir="$1"
    local success=true
    
    # 停止Redis服务
    if ! stop_redis_services "$cluster_dir"; then
        print_error "停止Redis服务失败"
        success=false
    fi
    
    # 销毁集群（即使停止服务失败也尝试销毁）
    destroy_cluster "$cluster_dir"
    
    # 清理文件
    cleanup_files "$cluster_dir"
    
    # 删除目录
    if ! delete_directory "$cluster_dir"; then
        success=false
    fi
    
    if [ "$success" = true ]; then
        echo ""
        print_success "=== Redis集群删除完成 ==="
        print_success "集群目录 $cluster_dir 已被完全删除"
        print_info "所有Redis进程已停止，配置文件和数据已清理"
    else
        echo ""
        print_error "=== 删除过程中出现错误 ==="
        print_warning "请检查上述错误信息并手动处理剩余问题"
        exit 1
    fi
}

# 执行主函数
main "$CLUSTER_DIR"

echo ""
print_info "脚本执行完成"