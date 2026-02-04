#!/bin/bash

# 检查必要依赖：jq（用于解析 JSON 配置）
if ! command -v jq >/dev/null 2>&1; then
    echo "Error: 'jq' not installed"
    exit 1
fi

# Read deployment configuration
CONFIG=$(cat deploy-config.json)

# Get list of enabled courses
COURSES=($(echo "$CONFIG" | jq -r 'to_entries | .[] | select(.value.enabled == true) | .key'))

if [ ${#COURSES[@]} -eq 0 ]; then
    echo "No enabled courses found in configuration."
    exit 0
fi

# 函数：setup_ssh_key
# 说明：将目标主机的 SSH 公钥预先加入 known_hosts，避免首次连接交互阻塞。
# 参数：
#   $1 - 目标主机名或 IP
#   $2 - 目标 SSH 端口（默认 22）
# 返回：0 表示成功，非 0 表示失败
setup_ssh_key() {
    local host=$1
    local port=${2:-22}
    local known_hosts="$HOME/.ssh/known_hosts"

    # 创建 .ssh 目录（若不存在）
    mkdir -p "$HOME/.ssh"

    # 移除可能存在的旧主机密钥（同时处理默认端口与显式端口格式）
    ssh-keygen -R "$host" 2>/dev/null
    ssh-keygen -R "[${host}]:${port}" 2>/dev/null

    # 抓取并添加新的主机密钥
    if ! ssh-keyscan -p "$port" -H "$host" >> "$known_hosts" 2>/dev/null; then
        echo "Error: Failed to get host key for $host:$port"
        return 1
    fi
}

# 函数：transfer_files
# 说明：将本地目录内容同步到远端目录；优先使用 rsync，若失败或远端缺失 rsync，则回退到打包 + scp 上传 + 远端解压方案。
#       在回退模式下，为模拟 rsync 的 --delete 行为，先清空远端目标目录下的现有内容（使用 find 删除包含隐藏文件在内的所有内容）。
# 参数：
#   $1 - 本地源目录（必须以斜杠结尾，如 dist/course/）
#   $2 - 远端用户名
#   $3 - 远端主机名或 IP
#   $4 - 远端 SSH 端口
#   $5 - 远端目标路径
# 返回：0 表示成功，非 0 表示失败
transfer_files() {
    local src_dir=$1
    local user=$2
    local host=$3
    local port=${4:-22}
    local dest_path=$5

    # 优先尝试 rsync（本地存在 rsync 时）。
    # 注意：远端也需要安装 rsync，否则会失败；此时自动回退到 scp。
    if command -v rsync >/dev/null 2>&1; then
        rsync -avz --size-only --stats --delete \
            -e "ssh -p ${port}" \
            "${src_dir}" "${user}@${host}:${dest_path}"
        local rc=$?
        if [ $rc -eq 0 ]; then
            return 0
        fi
        echo "Warning: rsync 传输失败（可能远端缺少 rsync 或连接异常），回退到 scp。"
    fi

    # 回退到：本地压缩打包 + scp 上传 + 远端解压
    echo "Warning: 使用压缩包回退方案（tar.gz + scp 上传 + 远端解压）。"

    # 本地检查 tar/scp 是否可用
    if ! command -v tar >/dev/null 2>&1; then
        echo "Error: 本地缺少 tar，无法进行回退打包。"
        return 1
    fi
    if ! command -v scp >/dev/null 2>&1; then
        echo "Error: 本地缺少 scp，无法进行回退上传。"
        return 1
    fi

    # 创建本地临时目录与压缩包路径，打包 src_dir 的内容（不包含父目录）
    local tmp_dir
    tmp_dir="$(mktemp -d -t deploy_tar_XXXXXX)"
    local tmp_tar
    tmp_tar="${tmp_dir}/payload.tar.gz"

    if ! tar -C "${src_dir}" -czf "${tmp_tar}" .; then
        echo "Error: 打包本地目录失败：${src_dir}"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 生成远端临时文件路径
    local ts rand remote_tmp
    ts="$(date +%s)"; rand="${RANDOM}"
    remote_tmp="/tmp/deploy_${ts}_${rand}.tar.gz"

    # 准备远端目录并清空现有内容（find 删除所有文件/目录，包含隐藏文件）
    if ! ssh -p "${port}" "${user}@${host}" "mkdir -p \"${dest_path}\" && find \"${dest_path}\" -mindepth 1 -maxdepth 1 -exec rm -rf {} +"; then
        echo "Error: 无法准备远端目录 ${dest_path}"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 传输压缩包到远端临时路径
    if ! scp -P "${port}" "${tmp_tar}" "${user}@${host}:${remote_tmp}"; then
        echo "Error: 上传压缩包失败：${remote_tmp}"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 远端解压至目标目录并清理临时包
    if ! ssh -p "${port}" "${user}@${host}" "tar -xzf \"${remote_tmp}\" -C \"${dest_path}\" && rm -f \"${remote_tmp}\""; then
        echo "Error: 远端解压失败或清理临时文件失败"
        rm -rf "${tmp_dir}"
        return 1
    fi

    # 清理本地临时文件
    rm -rf "${tmp_dir}"
    return 0
}

for course in "${COURSES[@]}"; do
    # Parse configuration
    host=$(echo "$CONFIG" | jq -r ".${course}.host")
    user=$(echo "$CONFIG" | jq -r ".${course}.user")
    path=$(echo "$CONFIG" | jq -r ".${course}.path")
    port=$(echo "$CONFIG" | jq -r ".${course}.port // 22")

    # Check if the directory exists
    if [ ! -d "dist/$course/" ]; then
        echo "Warning: Directory dist/$course/ does not exist. Skipping deployment for $course."
        continue
    fi

    # Setup SSH key for the host
    echo "Setting up SSH key for $host:$port..."
    if ! setup_ssh_key "$host" "$port"; then
        echo "Error: Failed to setup SSH connection for $host. Skipping deployment."
        continue
    fi

    # Synchronize files
    echo "Deploying $course to $host:$port..."
    if ! transfer_files "dist/${course}/" "$user" "$host" "$port" "$path"; then
        echo "Error: Failed to deploy $course to $host:$port"
        continue
    fi

    echo "Successfully deployed $course to $host"
done
