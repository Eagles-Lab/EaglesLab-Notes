# 第十二章：Redis 运维管理

## 概述

Redis运维管理是确保Redis服务稳定运行的关键环节。本章将深入介绍Redis的日常运维管理，包括监控告警、备份恢复、故障处理、容量规划等核心内容，帮助运维人员建立完善的Redis运维体系。

### 学习目标

- 掌握Redis监控指标和告警策略
- 学会Redis备份恢复的最佳实践
- 了解Redis故障诊断和处理方法
- 掌握Redis容量规划和扩容策略
- 学会Redis运维自动化工具的使用

## 监控告警

### 核心监控指标

**性能指标**：

```shell
# Redis性能监控指标
# 1. 连接数
redis-cli info clients | grep connected_clients

# 2. 内存使用
redis-cli info memory | grep used_memory_human

# 3. 命令执行统计
redis-cli info commandstats

# 4. 键空间统计
redis-cli info keyspace

# 5. 复制延迟
redis-cli info replication | grep master_repl_offset

# 6. 慢查询
redis-cli slowlog get 10
```

**系统指标**：

```shell
# 系统资源监控
# CPU使用率
top -p $(pgrep redis-server)

# 内存使用
ps aux | grep redis-server

# 网络连接
netstat -an | grep :6379

# 磁盘I/O
iostat -x 1

# 文件描述符
lsof -p $(pgrep redis-server) | wc -l
```

### 监控脚本实现

**Redis监控脚本**：`参考 redis_monitor.py 工具`

### 告警配置

**告警规则配置**： `参考 redis_alerts.yml 工具`

**告警处理脚本**： `参考 redis_alert_handler.py 工具`

## 备份恢复

### 备份策略

**自动备份脚本**：

```shell
#!/bin/bash
# redis_backup.sh - Redis自动备份脚本

# 配置参数
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""
BACKUP_DIR="/data/redis_backup"
RETENTION_DAYS=7
LOG_FILE="/var/log/redis_backup.log"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# 创建备份目录
mkdir -p $BACKUP_DIR

# 备份函数
backup_redis() {
    local backup_type=$1
    local timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_name="redis_${backup_type}_${timestamp}"
    local backup_path="$BACKUP_DIR/$backup_name"
    
    log "开始 $backup_type 备份: $backup_name"
    
    case $backup_type in
        "rdb")
            # RDB备份
            if [ -n "$REDIS_PASSWORD" ]; then
                redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD BGSAVE
            else
                redis-cli -h $REDIS_HOST -p $REDIS_PORT BGSAVE
            fi
            
            # 等待备份完成
            while true; do
                if [ -n "$REDIS_PASSWORD" ]; then
                    result=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD LASTSAVE)
                else
                    result=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT LASTSAVE)
                fi
                
                if [ "$result" != "$last_save" ]; then
                    break
                fi
                sleep 1
            done
            
            # 复制RDB文件
            redis_data_dir=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir | tail -1)
            rdb_filename=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dbfilename | tail -1)
            
            if [ -f "$redis_data_dir/$rdb_filename" ]; then
                cp "$redis_data_dir/$rdb_filename" "$backup_path.rdb"
                log "RDB备份完成: $backup_path.rdb"
            else
                log "错误: RDB文件不存在"
                return 1
            fi
            ;;
        
        "aof")
            # AOF备份
            redis_data_dir=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir | tail -1)
            aof_filename=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendfilename | tail -1)
            
            if [ -f "$redis_data_dir/$aof_filename" ]; then
                cp "$redis_data_dir/$aof_filename" "$backup_path.aof"
                log "AOF备份完成: $backup_path.aof"
            else
                log "警告: AOF文件不存在"
            fi
            ;;
        
        "full")
            # 全量备份（包含配置文件）
            mkdir -p "$backup_path"
            
            # 备份RDB
            backup_redis "rdb"
            if [ $? -eq 0 ]; then
                mv "$BACKUP_DIR/redis_rdb_"*.rdb "$backup_path/"
            fi
            
            # 备份AOF
            backup_redis "aof"
            if [ $? -eq 0 ]; then
                mv "$BACKUP_DIR/redis_aof_"*.aof "$backup_path/"
            fi
            
            # 备份配置文件
            redis_config=$(ps aux | grep redis-server | grep -v grep | awk '{for(i=1;i<=NF;i++) if($i ~ /\.conf$/) print $i}')
            if [ -n "$redis_config" ] && [ -f "$redis_config" ]; then
                cp "$redis_config" "$backup_path/redis.conf"
                log "配置文件备份完成: $backup_path/redis.conf"
            fi
            
            # 创建备份信息文件
            cat > "$backup_path/backup_info.txt" << EOF
备份时间: $(date)
备份类型: 全量备份
Redis版本: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO server | grep redis_version | cut -d: -f2 | tr -d '\r')
数据库大小: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE)
内存使用: $(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
EOF
            
            # 压缩备份
            cd $BACKUP_DIR
            tar -czf "${backup_name}.tar.gz" "$backup_name"
            rm -rf "$backup_name"
            
            log "全量备份完成: ${backup_path}.tar.gz"
            ;;
    esac
}

# 清理过期备份
cleanup_old_backups() {
    log "清理 $RETENTION_DAYS 天前的备份文件"
    find $BACKUP_DIR -name "redis_*" -type f -mtime +$RETENTION_DAYS -delete
    log "清理完成"
}

# 验证备份
verify_backup() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        log "错误: 备份文件不存在: $backup_file"
        return 1
    fi
    
    local file_size=$(stat -c%s "$backup_file")
    if [ $file_size -eq 0 ]; then
        log "错误: 备份文件为空: $backup_file"
        return 1
    fi
    
    log "备份验证通过: $backup_file (大小: $file_size 字节)"
    return 0
}

# 主函数
main() {
    local backup_type=${1:-"full"}
    
    log "=== Redis备份开始 ==="
    log "备份类型: $backup_type"
    
    # 检查Redis连接
    if ! redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1; then
        log "错误: 无法连接到Redis服务器"
        exit 1
    fi
    
    # 执行备份
    backup_redis $backup_type
    
    # 验证备份
    latest_backup=$(ls -t $BACKUP_DIR/redis_${backup_type}_* 2>/dev/null | head -1)
    if [ -n "$latest_backup" ]; then
        verify_backup "$latest_backup"
    fi
    
    # 清理过期备份
    cleanup_old_backups
    
    log "=== Redis备份完成 ==="
}

# 执行主函数
main $@
```

### 恢复策略

**数据恢复脚本**：

```shell
#!/bin/bash
# redis_restore.sh - Redis数据恢复脚本

# 配置参数
REDIS_HOST="localhost"
REDIS_PORT="6379"
REDIS_PASSWORD=""
BACKUP_DIR="/data/redis_backup"
LOG_FILE="/var/log/redis_restore.log"

# 日志函数
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a $LOG_FILE
}

# 停止Redis服务
stop_redis() {
    log "停止Redis服务"
    
    # 尝试优雅关闭
    if [ -n "$REDIS_PASSWORD" ]; then
        redis-cli -h $REDIS_HOST -p $REDIS_PORT -a $REDIS_PASSWORD SHUTDOWN SAVE
    else
        redis-cli -h $REDIS_HOST -p $REDIS_PORT SHUTDOWN SAVE
    fi
    
    # 等待进程结束
    sleep 5
    
    # 强制杀死进程（如果仍在运行）
    pkill -f redis-server
    
    log "Redis服务已停止"
}

# 启动Redis服务
start_redis() {
    log "启动Redis服务"
    
    # 查找Redis配置文件
    local config_file="/etc/redis/redis.conf"
    if [ ! -f "$config_file" ]; then
        config_file="/usr/local/etc/redis.conf"
    fi
    
    if [ -f "$config_file" ]; then
        redis-server "$config_file" &
    else
        redis-server &
    fi
    
    # 等待服务启动
    local retry_count=0
    while [ $retry_count -lt 30 ]; do
        if redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1; then
            log "Redis服务启动成功"
            return 0
        fi
        sleep 1
        retry_count=$((retry_count + 1))
    done
    
    log "错误: Redis服务启动失败"
    return 1
}

# 恢复RDB文件
restore_rdb() {
    local rdb_file=$1
    
    if [ ! -f "$rdb_file" ]; then
        log "错误: RDB文件不存在: $rdb_file"
        return 1
    fi
    
    log "恢复RDB文件: $rdb_file"
    
    # 获取Redis数据目录
    local redis_data_dir=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir 2>/dev/null | tail -1)
    if [ -z "$redis_data_dir" ]; then
        redis_data_dir="/var/lib/redis"
    fi
    
    local rdb_filename=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dbfilename 2>/dev/null | tail -1)
    if [ -z "$rdb_filename" ]; then
        rdb_filename="dump.rdb"
    fi
    
    # 停止Redis
    stop_redis
    
    # 备份现有RDB文件
    if [ -f "$redis_data_dir/$rdb_filename" ]; then
        mv "$redis_data_dir/$rdb_filename" "$redis_data_dir/${rdb_filename}.backup.$(date +%s)"
        log "现有RDB文件已备份"
    fi
    
    # 复制新的RDB文件
    cp "$rdb_file" "$redis_data_dir/$rdb_filename"
    chown redis:redis "$redis_data_dir/$rdb_filename" 2>/dev/null
    
    # 启动Redis
    start_redis
    
    if [ $? -eq 0 ]; then
        log "RDB恢复完成"
        return 0
    else
        log "错误: RDB恢复失败"
        return 1
    fi
}

# 恢复AOF文件
restore_aof() {
    local aof_file=$1
    
    if [ ! -f "$aof_file" ]; then
        log "错误: AOF文件不存在: $aof_file"
        return 1
    fi
    
    log "恢复AOF文件: $aof_file"
    
    # 验证AOF文件
    redis-check-aof --fix "$aof_file"
    if [ $? -ne 0 ]; then
        log "警告: AOF文件可能有问题，已尝试修复"
    fi
    
    # 获取Redis数据目录
    local redis_data_dir=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET dir 2>/dev/null | tail -1)
    if [ -z "$redis_data_dir" ]; then
        redis_data_dir="/var/lib/redis"
    fi
    
    local aof_filename=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT CONFIG GET appendfilename 2>/dev/null | tail -1)
    if [ -z "$aof_filename" ]; then
        aof_filename="appendonly.aof"
    fi
    
    # 停止Redis
    stop_redis
    
    # 备份现有AOF文件
    if [ -f "$redis_data_dir/$aof_filename" ]; then
        mv "$redis_data_dir/$aof_filename" "$redis_data_dir/${aof_filename}.backup.$(date +%s)"
        log "现有AOF文件已备份"
    fi
    
    # 复制新的AOF文件
    cp "$aof_file" "$redis_data_dir/$aof_filename"
    chown redis:redis "$redis_data_dir/$aof_filename" 2>/dev/null
    
    # 启动Redis
    start_redis
    
    if [ $? -eq 0 ]; then
        log "AOF恢复完成"
        return 0
    else
        log "错误: AOF恢复失败"
        return 1
    fi
}

# 恢复全量备份
restore_full() {
    local backup_file=$1
    
    if [ ! -f "$backup_file" ]; then
        log "错误: 备份文件不存在: $backup_file"
        return 1
    fi
    
    log "恢复全量备份: $backup_file"
    
    # 创建临时目录
    local temp_dir="/tmp/redis_restore_$(date +%s)"
    mkdir -p "$temp_dir"
    
    # 解压备份文件
    if [[ "$backup_file" == *.tar.gz ]]; then
        tar -xzf "$backup_file" -C "$temp_dir"
    elif [[ "$backup_file" == *.zip ]]; then
        unzip "$backup_file" -d "$temp_dir"
    else
        log "错误: 不支持的备份文件格式"
        return 1
    fi
    
    # 查找解压后的目录
    local extract_dir=$(find "$temp_dir" -maxdepth 1 -type d | grep -v "^$temp_dir$" | head -1)
    if [ -z "$extract_dir" ]; then
        extract_dir="$temp_dir"
    fi
    
    # 恢复配置文件
    if [ -f "$extract_dir/redis.conf" ]; then
        log "发现配置文件，请手动检查是否需要恢复"
        log "配置文件位置: $extract_dir/redis.conf"
    fi
    
    # 恢复数据文件
    local rdb_file=$(find "$extract_dir" -name "*.rdb" | head -1)
    local aof_file=$(find "$extract_dir" -name "*.aof" | head -1)
    
    if [ -n "$rdb_file" ]; then
        restore_rdb "$rdb_file"
    elif [ -n "$aof_file" ]; then
        restore_aof "$aof_file"
    else
        log "错误: 未找到数据文件"
        rm -rf "$temp_dir"
        return 1
    fi
    
    # 清理临时文件
    rm -rf "$temp_dir"
    
    log "全量恢复完成"
}

# 列出可用备份
list_backups() {
    log "可用的备份文件:"
    
    if [ ! -d "$BACKUP_DIR" ]; then
        log "备份目录不存在: $BACKUP_DIR"
        return 1
    fi
    
    local backup_files=$(find "$BACKUP_DIR" -name "redis_*" -type f | sort -r)
    
    if [ -z "$backup_files" ]; then
        log "未找到备份文件"
        return 1
    fi
    
    local index=1
    echo "$backup_files" | while read file; do
        local size=$(stat -c%s "$file" 2>/dev/null || echo "unknown")
        local date=$(stat -c%y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
        printf "%2d. %s (大小: %s, 日期: %s)\n" $index "$(basename "$file")" "$size" "$date"
        index=$((index + 1))
    done
}

# 验证恢复结果
verify_restore() {
    log "验证恢复结果"
    
    # 检查Redis连接
    if ! redis-cli -h $REDIS_HOST -p $REDIS_PORT ping > /dev/null 2>&1; then
        log "错误: Redis服务未正常运行"
        return 1
    fi
    
    # 获取基本信息
    local db_size=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT DBSIZE)
    local memory_usage=$(redis-cli -h $REDIS_HOST -p $REDIS_PORT INFO memory | grep used_memory_human | cut -d: -f2 | tr -d '\r')
    
    log "恢复验证结果:"
    log "- 数据库大小: $db_size 个键"
    log "- 内存使用: $memory_usage"
    log "- Redis状态: 正常"
    
    return 0
}

# 主函数
main() {
    local action=$1
    local backup_file=$2
    
    log "=== Redis恢复开始 ==="
    
    case $action in
        "list")
            list_backups
            ;;
        "rdb")
            if [ -z "$backup_file" ]; then
                log "错误: 请指定RDB备份文件"
                exit 1
            fi
            restore_rdb "$backup_file"
            verify_restore
            ;;
        "aof")
            if [ -z "$backup_file" ]; then
                log "错误: 请指定AOF备份文件"
                exit 1
            fi
            restore_aof "$backup_file"
            verify_restore
            ;;
        "full")
            if [ -z "$backup_file" ]; then
                log "错误: 请指定全量备份文件"
                exit 1
            fi
            restore_full "$backup_file"
            verify_restore
            ;;
        *)
            echo "用法: $0 {list|rdb|aof|full} [backup_file]"
            echo "  list - 列出可用备份"
            echo "  rdb  - 恢复RDB备份"
            echo "  aof  - 恢复AOF备份"
            echo "  full - 恢复全量备份"
            exit 1
            ;;
    esac
    
    log "=== Redis恢复完成 ==="
}

# 执行主函数
main $@
```

## 故障处理

### 常见故障诊断

**故障诊断脚本**： `待补充`

### 故障处理手册

**常见故障及解决方案**：

```shell
# 网络问题：
- 客户端无法连接Redis
- 连接超时
- 连接被拒绝

# 内存问题：
- 内存使用率过高
- OOM错误
- 性能下降

# 性能问题
- 响应时间慢
- QPS下降
- 慢查询增多

# 持久化问题
- RDB保存失败
- AOF文件损坏
- 数据丢失

# 主从复制问题
- 主从同步失败
- 复制延迟过大
- 从节点数据不一致

```

## 容量规划

### 容量评估脚本

**Redis容量分析工具**：`参考 redis_capacity_planner.py 工具`
