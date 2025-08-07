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

```bash
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

```bash
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

**Redis监控脚本**：

```python
#!/usr/bin/env python3
# redis_monitor.py - Redis监控脚本

import redis
import time
import json
import psutil
import logging
from datetime import datetime
from typing import Dict, Any

class RedisMonitor:
    def __init__(self, host='localhost', port=6379, password=None):
        self.redis_client = redis.Redis(
            host=host, port=port, password=password, decode_responses=True
        )
        self.setup_logging()
    
    def setup_logging(self):
        """设置日志"""
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('redis_monitor.log'),
                logging.StreamHandler()
            ]
        )
        self.logger = logging.getLogger(__name__)
    
    def get_redis_info(self) -> Dict[str, Any]:
        """获取Redis信息"""
        try:
            info = self.redis_client.info()
            return {
                'server': {
                    'version': info.get('redis_version'),
                    'uptime': info.get('uptime_in_seconds'),
                    'role': info.get('role')
                },
                'clients': {
                    'connected': info.get('connected_clients'),
                    'blocked': info.get('blocked_clients'),
                    'max_clients': info.get('maxclients')
                },
                'memory': {
                    'used': info.get('used_memory'),
                    'used_human': info.get('used_memory_human'),
                    'peak': info.get('used_memory_peak'),
                    'peak_human': info.get('used_memory_peak_human'),
                    'fragmentation_ratio': info.get('mem_fragmentation_ratio')
                },
                'stats': {
                    'total_commands': info.get('total_commands_processed'),
                    'ops_per_sec': info.get('instantaneous_ops_per_sec'),
                    'keyspace_hits': info.get('keyspace_hits'),
                    'keyspace_misses': info.get('keyspace_misses'),
                    'expired_keys': info.get('expired_keys'),
                    'evicted_keys': info.get('evicted_keys')
                },
                'persistence': {
                    'rdb_last_save': info.get('rdb_last_save_time'),
                    'rdb_changes_since_save': info.get('rdb_changes_since_last_save'),
                    'aof_enabled': info.get('aof_enabled'),
                    'aof_rewrite_in_progress': info.get('aof_rewrite_in_progress')
                },
                'replication': {
                    'role': info.get('role'),
                    'connected_slaves': info.get('connected_slaves'),
                    'master_repl_offset': info.get('master_repl_offset'),
                    'repl_backlog_size': info.get('repl_backlog_size')
                }
            }
        except Exception as e:
            self.logger.error(f"获取Redis信息失败: {e}")
            return {}
    
    def get_system_info(self) -> Dict[str, Any]:
        """获取系统信息"""
        try:
            # 查找Redis进程
            redis_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                if 'redis-server' in proc.info['name']:
                    redis_processes.append(proc)
            
            if not redis_processes:
                return {}
            
            redis_proc = redis_processes[0]
            
            return {
                'cpu': {
                    'percent': redis_proc.cpu_percent(),
                    'times': redis_proc.cpu_times()._asdict()
                },
                'memory': {
                    'rss': redis_proc.memory_info().rss,
                    'vms': redis_proc.memory_info().vms,
                    'percent': redis_proc.memory_percent()
                },
                'io': {
                    'read_count': redis_proc.io_counters().read_count,
                    'write_count': redis_proc.io_counters().write_count,
                    'read_bytes': redis_proc.io_counters().read_bytes,
                    'write_bytes': redis_proc.io_counters().write_bytes
                },
                'connections': len(redis_proc.connections()),
                'open_files': len(redis_proc.open_files()),
                'threads': redis_proc.num_threads()
            }
        except Exception as e:
            self.logger.error(f"获取系统信息失败: {e}")
            return {}
    
    def get_slow_queries(self, count=10) -> list:
        """获取慢查询"""
        try:
            slow_log = self.redis_client.slowlog_get(count)
            return [
                {
                    'id': entry['id'],
                    'start_time': entry['start_time'],
                    'duration': entry['duration'],
                    'command': ' '.join(entry['command'])
                }
                for entry in slow_log
            ]
        except Exception as e:
            self.logger.error(f"获取慢查询失败: {e}")
            return []
    
    def check_alerts(self, metrics: Dict[str, Any]) -> list:
        """检查告警条件"""
        alerts = []
        
        # 内存使用率告警
        if metrics.get('memory', {}).get('fragmentation_ratio', 0) > 1.5:
            alerts.append({
                'level': 'warning',
                'type': 'memory_fragmentation',
                'message': f"内存碎片率过高: {metrics['memory']['fragmentation_ratio']}"
            })
        
        # 连接数告警
        connected_clients = metrics.get('clients', {}).get('connected', 0)
        max_clients = metrics.get('clients', {}).get('max_clients', 10000)
        if connected_clients > max_clients * 0.8:
            alerts.append({
                'level': 'warning',
                'type': 'high_connections',
                'message': f"连接数过高: {connected_clients}/{max_clients}"
            })
        
        # 命中率告警
        hits = metrics.get('stats', {}).get('keyspace_hits', 0)
        misses = metrics.get('stats', {}).get('keyspace_misses', 0)
        if hits + misses > 0:
            hit_rate = hits / (hits + misses)
            if hit_rate < 0.8:
                alerts.append({
                    'level': 'warning',
                    'type': 'low_hit_rate',
                    'message': f"缓存命中率过低: {hit_rate:.2%}"
                })
        
        # 持久化告警
        rdb_changes = metrics.get('persistence', {}).get('rdb_changes_since_save', 0)
        if rdb_changes > 10000:
            alerts.append({
                'level': 'warning',
                'type': 'rdb_not_saved',
                'message': f"RDB未保存变更过多: {rdb_changes}"
            })
        
        return alerts
    
    def collect_metrics(self) -> Dict[str, Any]:
        """收集所有监控指标"""
        timestamp = datetime.now().isoformat()
        
        metrics = {
            'timestamp': timestamp,
            'redis': self.get_redis_info(),
            'system': self.get_system_info(),
            'slow_queries': self.get_slow_queries()
        }
        
        # 检查告警
        alerts = self.check_alerts(metrics['redis'])
        metrics['alerts'] = alerts
        
        return metrics
    
    def save_metrics(self, metrics: Dict[str, Any]):
        """保存监控数据"""
        try:
            filename = f"redis_metrics_{datetime.now().strftime('%Y%m%d')}.json"
            
            # 读取现有数据
            try:
                with open(filename, 'r') as f:
                    data = json.load(f)
            except FileNotFoundError:
                data = []
            
            # 添加新数据
            data.append(metrics)
            
            # 保持最近1000条记录
            if len(data) > 1000:
                data = data[-1000:]
            
            # 保存数据
            with open(filename, 'w') as f:
                json.dump(data, f, indent=2, default=str)
                
        except Exception as e:
            self.logger.error(f"保存监控数据失败: {e}")
    
    def send_alerts(self, alerts: list):
        """发送告警"""
        for alert in alerts:
            message = f"[{alert['level'].upper()}] {alert['type']}: {alert['message']}"
            self.logger.warning(message)
            
            # 这里可以集成邮件、短信、钉钉等告警方式
            # 示例：发送到日志文件
            with open('redis_alerts.log', 'a') as f:
                f.write(f"{datetime.now().isoformat()} - {message}\n")
    
    def run_monitor(self, interval=60):
        """运行监控"""
        self.logger.info("开始Redis监控")
        
        while True:
            try:
                # 收集指标
                metrics = self.collect_metrics()
                
                # 保存数据
                self.save_metrics(metrics)
                
                # 处理告警
                if metrics.get('alerts'):
                    self.send_alerts(metrics['alerts'])
                
                # 输出关键指标
                redis_info = metrics.get('redis', {})
                self.logger.info(
                    f"连接数: {redis_info.get('clients', {}).get('connected', 0)}, "
                    f"内存: {redis_info.get('memory', {}).get('used_human', 'N/A')}, "
                    f"QPS: {redis_info.get('stats', {}).get('ops_per_sec', 0)}"
                )
                
                time.sleep(interval)
                
            except KeyboardInterrupt:
                self.logger.info("监控已停止")
                break
            except Exception as e:
                self.logger.error(f"监控异常: {e}")
                time.sleep(interval)

if __name__ == '__main__':
    import sys
    
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 6379
    password = sys.argv[3] if len(sys.argv) > 3 else None
    interval = int(sys.argv[4]) if len(sys.argv) > 4 else 60
    
    monitor = RedisMonitor(host, port, password)
    monitor.run_monitor(interval)
```

### 告警配置

**告警规则配置**：

```yaml
# redis_alerts.yml - Redis告警配置
alerts:
  memory:
    fragmentation_ratio:
      threshold: 1.5
      level: warning
      message: "内存碎片率过高"
    
    used_memory_ratio:
      threshold: 0.8
      level: warning
      message: "内存使用率过高"
  
  performance:
    hit_rate:
      threshold: 0.8
      level: warning
      message: "缓存命中率过低"
    
    slow_queries:
      threshold: 10
      level: warning
      message: "慢查询过多"
  
  connections:
    connected_clients_ratio:
      threshold: 0.8
      level: warning
      message: "连接数过高"
  
  persistence:
    rdb_changes:
      threshold: 10000
      level: warning
      message: "RDB未保存变更过多"
    
    aof_rewrite:
      threshold: 3600  # 1小时
      level: warning
      message: "AOF重写时间过长"

notifications:
  email:
    enabled: true
    smtp_server: "smtp.example.com"
    smtp_port: 587
    username: "alert@example.com"
    password: "password"
    recipients:
      - "admin@example.com"
      - "ops@example.com"
  
  webhook:
    enabled: true
    url: "https://hooks.slack.com/services/xxx"
    
  sms:
    enabled: false
    api_key: "your_sms_api_key"
    recipients:
      - "+86138xxxxxxxx"
```

**告警处理脚本**：

```python
#!/usr/bin/env python3
# redis_alert_handler.py - Redis告警处理

import smtplib
import requests
import yaml
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

class AlertHandler:
    def __init__(self, config_file='redis_alerts.yml'):
        with open(config_file, 'r') as f:
            self.config = yaml.safe_load(f)
    
    def send_email(self, subject, message, recipients=None):
        """发送邮件告警"""
        email_config = self.config['notifications']['email']
        if not email_config.get('enabled'):
            return
        
        recipients = recipients or email_config['recipients']
        
        try:
            msg = MIMEMultipart()
            msg['From'] = email_config['username']
            msg['To'] = ', '.join(recipients)
            msg['Subject'] = subject
            
            msg.attach(MIMEText(message, 'plain'))
            
            server = smtplib.SMTP(email_config['smtp_server'], email_config['smtp_port'])
            server.starttls()
            server.login(email_config['username'], email_config['password'])
            
            text = msg.as_string()
            server.sendmail(email_config['username'], recipients, text)
            server.quit()
            
            print(f"邮件告警已发送: {subject}")
            
        except Exception as e:
            print(f"发送邮件失败: {e}")
    
    def send_webhook(self, message):
        """发送Webhook告警"""
        webhook_config = self.config['notifications']['webhook']
        if not webhook_config.get('enabled'):
            return
        
        try:
            payload = {
                'text': message,
                'timestamp': datetime.now().isoformat()
            }
            
            response = requests.post(webhook_config['url'], json=payload)
            response.raise_for_status()
            
            print(f"Webhook告警已发送: {message}")
            
        except Exception as e:
            print(f"发送Webhook失败: {e}")
    
    def process_alert(self, alert):
        """处理告警"""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        subject = f"Redis告警 - {alert['type']}"
        message = f"""
时间: {timestamp}
级别: {alert['level'].upper()}
类型: {alert['type']}
消息: {alert['message']}

请及时处理！
        """
        
        # 发送邮件
        self.send_email(subject, message)
        
        # 发送Webhook
        self.send_webhook(f"[{alert['level'].upper()}] {alert['message']}")
        
        # 记录到文件
        with open('processed_alerts.log', 'a') as f:
            f.write(f"{timestamp} - {alert['level']} - {alert['message']}\n")

if __name__ == '__main__':
    handler = AlertHandler()
    
    # 测试告警
    test_alert = {
        'level': 'warning',
        'type': 'memory_fragmentation',
        'message': '内存碎片率过高: 1.8'
    }
    
    handler.process_alert(test_alert)
```

## 实践操作

### 搭建Redis运维监控环境

**环境准备脚本**：

```bash
#!/bin/bash
# setup_redis_ops.sh - 搭建Redis运维环境

set -e

echo "=== 搭建Redis运维监控环境 ==="

# 创建工作目录
OPS_DIR="/opt/redis-ops"
sudo mkdir -p $OPS_DIR
cd $OPS_DIR

# 安装Python依赖
echo "安装Python依赖..."
sudo pip3 install redis psutil pyyaml requests

# 创建配置目录
sudo mkdir -p {config,scripts,logs,data}

# 创建Redis监控配置
cat > config/redis_monitor.conf << 'EOF'
[redis]
host = localhost
port = 6379
password = 
database = 0

[monitor]
interval = 60
log_level = INFO
log_file = logs/redis_monitor.log
metrics_file = data/redis_metrics.json

[alerts]
config_file = config/redis_alerts.yml
log_file = logs/redis_alerts.log

[thresholds]
memory_fragmentation_ratio = 1.5
hit_rate_min = 0.8
connection_ratio_max = 0.8
rdb_changes_max = 10000
EOF

# 创建告警配置
cat > config/redis_alerts.yml << 'EOF'
alerts:
  memory:
    fragmentation_ratio:
      threshold: 1.5
      level: warning
      message: "内存碎片率过高"
    
    used_memory_ratio:
      threshold: 0.8
      level: warning
      message: "内存使用率过高"
  
  performance:
    hit_rate:
      threshold: 0.8
      level: warning
      message: "缓存命中率过低"
    
    slow_queries:
      threshold: 10
      level: warning
      message: "慢查询过多"
  
  connections:
    connected_clients_ratio:
      threshold: 0.8
      level: warning
      message: "连接数过高"

notifications:
  email:
    enabled: false
    smtp_server: "smtp.example.com"
    smtp_port: 587
    username: "alert@example.com"
    password: "password"
    recipients:
      - "admin@example.com"
  
  webhook:
    enabled: false
    url: "https://hooks.slack.com/services/xxx"
EOF

# 创建systemd服务文件
cat > /etc/systemd/system/redis-monitor.service << 'EOF'
[Unit]
Description=Redis Monitor Service
After=network.target

[Service]
Type=simple
User=redis
Group=redis
WorkingDirectory=/opt/redis-ops
ExecStart=/usr/bin/python3 /opt/redis-ops/scripts/redis_monitor.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# 设置权限
sudo chown -R redis:redis $OPS_DIR
sudo chmod +x scripts/*.py

# 启用服务
sudo systemctl daemon-reload
sudo systemctl enable redis-monitor

echo "Redis运维监控环境搭建完成！"
echo "配置文件: $OPS_DIR/config/"
echo "脚本文件: $OPS_DIR/scripts/"
echo "日志文件: $OPS_DIR/logs/"
echo "数据文件: $OPS_DIR/data/"
echo ""
echo "启动监控: sudo systemctl start redis-monitor"
echo "查看状态: sudo systemctl status redis-monitor"
echo "查看日志: tail -f $OPS_DIR/logs/redis_monitor.log"
```

**运维脚本集合**：

```bash
#!/bin/bash
# redis_ops_tools.sh - Redis运维工具集

OPS_DIR="/opt/redis-ops"
LOG_DIR="$OPS_DIR/logs"
DATA_DIR="$OPS_DIR/data"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Redis健康检查
redis_health_check() {
    log_info "执行Redis健康检查..."
    
    # 检查Redis进程
    if ! pgrep redis-server > /dev/null; then
        log_error "Redis进程未运行"
        return 1
    fi
    
    # 检查Redis连接
    if ! redis-cli ping > /dev/null 2>&1; then
        log_error "无法连接到Redis"
        return 1
    fi
    
    # 检查内存使用
    memory_info=$(redis-cli info memory | grep used_memory_human)
    log_info "内存使用: $memory_info"
    
    # 检查连接数
    clients_info=$(redis-cli info clients | grep connected_clients)
    log_info "连接数: $clients_info"
    
    # 检查慢查询
    slow_count=$(redis-cli slowlog len)
    if [ "$slow_count" -gt 0 ]; then
        log_warn "发现 $slow_count 条慢查询"
    fi
    
    log_info "Redis健康检查完成"
}

# Redis性能报告
redis_performance_report() {
    log_info "生成Redis性能报告..."
    
    report_file="$DATA_DIR/performance_report_$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "=== Redis性能报告 ==="
        echo "生成时间: $(date)"
        echo ""
        
        echo "=== 基本信息 ==="
        redis-cli info server | grep -E "redis_version|uptime_in_seconds|role"
        echo ""
        
        echo "=== 内存使用 ==="
        redis-cli info memory | grep -E "used_memory_human|used_memory_peak_human|mem_fragmentation_ratio"
        echo ""
        
        echo "=== 客户端连接 ==="
        redis-cli info clients
        echo ""
        
        echo "=== 性能统计 ==="
        redis-cli info stats | grep -E "total_commands_processed|instantaneous_ops_per_sec|keyspace_hits|keyspace_misses"
        echo ""
        
        echo "=== 慢查询 ==="
        redis-cli slowlog get 10
        echo ""
        
        echo "=== 键空间信息 ==="
        redis-cli info keyspace
        echo ""
        
        echo "=== 复制信息 ==="
        redis-cli info replication
        
    } > "$report_file"
    
    log_info "性能报告已保存到: $report_file"
}

# Redis备份
redis_backup() {
    log_info "执行Redis备份..."
    
    backup_dir="$DATA_DIR/backups/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    # RDB备份
    log_info "执行RDB备份..."
    redis-cli bgsave
    
    # 等待备份完成
    while [ "$(redis-cli lastsave)" = "$(redis-cli lastsave)" ]; do
        sleep 1
    done
    
    # 复制RDB文件
    rdb_file=$(redis-cli config get dir | tail -1)/$(redis-cli config get dbfilename | tail -1)
    cp "$rdb_file" "$backup_dir/dump_$(date +%H%M%S).rdb"
    
    # AOF备份（如果启用）
    aof_enabled=$(redis-cli config get appendonly | tail -1)
    if [ "$aof_enabled" = "yes" ]; then
        log_info "执行AOF备份..."
        aof_file=$(redis-cli config get dir | tail -1)/$(redis-cli config get appendfilename | tail -1)
        if [ -f "$aof_file" ]; then
            cp "$aof_file" "$backup_dir/appendonly_$(date +%H%M%S).aof"
        fi
    fi
    
    # 压缩备份
    cd "$DATA_DIR/backups"
    tar -czf "redis_backup_$(date +%Y%m%d_%H%M%S).tar.gz" "$(date +%Y%m%d)"
    
    # 清理旧备份（保留7天）
    find "$DATA_DIR/backups" -name "redis_backup_*.tar.gz" -mtime +7 -delete
    
    log_info "Redis备份完成"
}

# Redis清理
redis_cleanup() {
    log_info "执行Redis清理..."
    
    # 清理过期键
    log_info "清理过期键..."
    redis-cli eval "return redis.call('scan', 0, 'count', 1000)" 0
    
    # 清理慢查询日志
    log_info "清理慢查询日志..."
    redis-cli slowlog reset
    
    # 内存整理（如果碎片率过高）
    fragmentation=$(redis-cli info memory | grep mem_fragmentation_ratio | cut -d: -f2)
    if (( $(echo "$fragmentation > 1.5" | bc -l) )); then
        log_warn "内存碎片率过高($fragmentation)，执行内存整理..."
        redis-cli memory purge
    fi
    
    log_info "Redis清理完成"
}

# 显示帮助
show_help() {
    echo "Redis运维工具集"
    echo ""
    echo "用法: $0 [命令]"
    echo ""
    echo "可用命令:"
    echo "  health      - 执行健康检查"
    echo "  report      - 生成性能报告"
    echo "  backup      - 执行备份"
    echo "  cleanup     - 执行清理"
    echo "  monitor     - 启动监控"
    echo "  stop        - 停止监控"
    echo "  status      - 查看监控状态"
    echo "  help        - 显示帮助"
}

# 主函数
main() {
    case "$1" in
        health)
            redis_health_check
            ;;
        report)
            redis_performance_report
            ;;
        backup)
            redis_backup
            ;;
        cleanup)
            redis_cleanup
            ;;
        monitor)
            sudo systemctl start redis-monitor
            log_info "Redis监控已启动"
            ;;
        stop)
            sudo systemctl stop redis-monitor
            log_info "Redis监控已停止"
            ;;
        status)
            sudo systemctl status redis-monitor
            ;;
        help|--help|-h)
            show_help
            ;;
        *)
            log_error "未知命令: $1"
            show_help
            exit 1
            ;;
    esac
}

# 检查参数
if [ $# -eq 0 ]; then
    show_help
    exit 1
fi

# 执行主函数
main "$@"
```

## 总结

本章详细介绍了Redis运维管理的核心内容：

### 监控告警
- **核心指标**: 性能、内存、连接、持久化等关键指标
- **监控脚本**: 自动化监控数据收集和告警处理
- **告警配置**: 灵活的告警规则和通知方式

### 备份恢复
- **自动备份**: RDB和AOF的自动备份策略
- **数据恢复**: 快速恢复数据的方法和脚本
- **备份管理**: 备份文件的管理和清理

### 故障处理
- **故障诊断**: 常见问题的诊断脚本和方法
- **处理手册**: 详细的故障处理步骤和解决方案
- **预防措施**: 故障预防和性能优化建议

### 容量规划
- **容量评估**: 内存使用和增长趋势分析
- **扩容策略**: 基于数据的扩容决策支持
- **性能预测**: 未来性能需求的预测模型

### 运维自动化
- **脚本工具**: 完整的运维脚本工具集
- **服务管理**: systemd服务的配置和管理
- **日志管理**: 运维日志的收集和分析

通过本章的学习，你将能够建立完善的Redis运维体系，确保Redis服务的稳定运行和高效管理。
            'system': self.get_system_info(),
            'slow_queries': self.get_slow_queries()
        }
        
        # 检查告警
        alerts = self.check_alerts(metrics['redis'])
        metrics['alerts'] = alerts
        
        # 记录告警
        for alert in alerts:
            self.logger.warning(f"告警: {alert['message']}")
        
        return metrics
    
    def save_metrics(self, metrics: Dict[str, Any], filename: str = None):
        """保存监控数据"""
        if filename is None:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            filename = f'redis_metrics_{timestamp}.json'
        
        try:
            with open(filename, 'w') as f:
                json.dump(metrics, f, indent=2, default=str)
            self.logger.info(f"监控数据已保存到: {filename}")
        except Exception as e:
            self.logger.error(f"保存监控数据失败: {e}")
    
    def run_monitor(self, interval=60, duration=3600):
        """运行监控"""
        self.logger.info(f"开始监控Redis，间隔: {interval}秒，持续: {duration}秒")
        
        start_time = time.time()
        while time.time() - start_time < duration:
            try:
                metrics = self.collect_metrics()
                
                # 输出关键指标
                redis_info = metrics.get('redis', {})
                print(f"\n=== Redis监控 {metrics['timestamp']} ===")
                print(f"连接数: {redis_info.get('clients', {}).get('connected', 'N/A')}")
                print(f"内存使用: {redis_info.get('memory', {}).get('used_human', 'N/A')}")
                print(f"QPS: {redis_info.get('stats', {}).get('ops_per_sec', 'N/A')}")
                print(f"告警数: {len(metrics.get('alerts', []))}")
                
                # 保存数据
                self.save_metrics(metrics)
                
                time.sleep(interval)
                
            except KeyboardInterrupt:
                self.logger.info("监控已停止")
                break
            except Exception as e:
                self.logger.error(f"监控异常: {e}")
                time.sleep(interval)

if __name__ == '__main__':
    monitor = RedisMonitor()
    monitor.run_monitor(interval=30, duration=1800)  # 30秒间隔，监控30分钟
```

### 告警配置

**告警规则配置**：

```yaml
# redis_alerts.yml - Redis告警规则配置
alert_rules:
  # 内存告警
  memory_usage:
    metric: used_memory_ratio
    threshold: 0.8
    level: warning
    message: "Redis内存使用率超过80%"
  
  memory_fragmentation:
    metric: mem_fragmentation_ratio
    threshold: 1.5
    level: warning
    message: "Redis内存碎片率过高"
  
  # 连接告警
  connection_usage:
    metric: connected_clients_ratio
    threshold: 0.8
    level: warning
    message: "Redis连接数使用率超过80%"
  
  # 性能告警
  hit_rate:
    metric: keyspace_hit_rate
    threshold: 0.8
    operator: "<"
    level: warning
    message: "Redis缓存命中率低于80%"
  
  slow_queries:
    metric: slow_query_count
    threshold: 10
    level: warning
    message: "Redis慢查询数量过多"
  
  # 持久化告警
  rdb_save_delay:
    metric: rdb_changes_since_last_save
    threshold: 10000
    level: warning
    message: "RDB持久化延迟过久"
  
  # 复制告警
  replication_lag:
    metric: master_repl_offset_lag
    threshold: 1000000
    level: critical
    message: "主从复制延迟过大"

# 通知配置
notifications:
  email:
    enabled: true
    smtp_server: "smtp.example.com"
    smtp_port: 587
    username: "alert@example.com"
    password: "password"
    recipients:
      - "admin@example.com"
      - "ops@example.com"
  
  webhook:
    enabled: true
    url: "https://hooks.slack.com/services/xxx/yyy/zzz"
    method: "POST"
  
  sms:
    enabled: false
    api_url: "https://api.sms.com/send"
    api_key: "your_api_key"
    phones:
      - "+86138xxxxxxxx"
```

**告警处理脚本**：

```python
#!/usr/bin/env python3
# alert_handler.py - Redis告警处理脚本

import yaml
import smtplib
import requests
import json
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from datetime import datetime

class AlertHandler:
    def __init__(self, config_file='redis_alerts.yml'):
        with open(config_file, 'r') as f:
            self.config = yaml.safe_load(f)
        self.alert_rules = self.config['alert_rules']
        self.notifications = self.config['notifications']
    
    def check_alert_rules(self, metrics):
        """检查告警规则"""
        alerts = []
        
        for rule_name, rule in self.alert_rules.items():
            metric_value = self.get_metric_value(metrics, rule['metric'])
            
            if metric_value is None:
                continue
            
            threshold = rule['threshold']
            operator = rule.get('operator', '>')
            
            triggered = False
            if operator == '>':
                triggered = metric_value > threshold
            elif operator == '<':
                triggered = metric_value < threshold
            elif operator == '>=':
                triggered = metric_value >= threshold
            elif operator == '<=':
                triggered = metric_value <= threshold
            elif operator == '==':
                triggered = metric_value == threshold
            
            if triggered:
                alerts.append({
                    'rule': rule_name,
                    'level': rule['level'],
                    'message': rule['message'],
                    'metric': rule['metric'],
                    'value': metric_value,
                    'threshold': threshold,
                    'timestamp': datetime.now().isoformat()
                })
        
        return alerts
    
    def get_metric_value(self, metrics, metric_path):
        """获取指标值"""
        try:
            # 计算派生指标
            if metric_path == 'used_memory_ratio':
                used = metrics['redis']['memory']['used']
                # 假设最大内存为8GB
                max_memory = 8 * 1024 * 1024 * 1024
                return used / max_memory
            
            elif metric_path == 'connected_clients_ratio':
                connected = metrics['redis']['clients']['connected']
                max_clients = metrics['redis']['clients']['max_clients']
                return connected / max_clients if max_clients > 0 else 0
            
            elif metric_path == 'keyspace_hit_rate':
                hits = metrics['redis']['stats']['keyspace_hits']
                misses = metrics['redis']['stats']['keyspace_misses']
                total = hits + misses
                return hits / total if total > 0 else 0
            
            elif metric_path == 'slow_query_count':
                return len(metrics.get('slow_queries', []))
            
            # 直接路径访问
            else:
                parts = metric_path.split('.')
                value = metrics
                for part in parts:
                    value = value.get(part, {})
                return value if isinstance(value, (int, float)) else None
        
        except Exception:
            return None
    
    def send_email_alert(self, alerts):
        """发送邮件告警"""
        if not self.notifications['email']['enabled']:
            return
        
        try:
            smtp_config = self.notifications['email']
            
            msg = MIMEMultipart()
            msg['From'] = smtp_config['username']
            msg['To'] = ', '.join(smtp_config['recipients'])
            msg['Subject'] = f"Redis告警 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}"
            
            # 构建邮件内容
            body = "Redis监控告警通知:\n\n"
            for alert in alerts:
                body += f"告警级别: {alert['level']}\n"
                body += f"告警规则: {alert['rule']}\n"
                body += f"告警信息: {alert['message']}\n"
                body += f"当前值: {alert['value']}\n"
                body += f"阈值: {alert['threshold']}\n"
                body += f"时间: {alert['timestamp']}\n"
                body += "-" * 50 + "\n"
            
            msg.attach(MIMEText(body, 'plain'))
            
            # 发送邮件
            server = smtplib.SMTP(smtp_config['smtp_server'], smtp_config['smtp_port'])
            server.starttls()
            server.login(smtp_config['username'], smtp_config['password'])
            server.send_message(msg)
            server.quit()
            
            print(f"邮件告警已发送给: {smtp_config['recipients']}")
        
        except Exception as e:
            print(f"发送邮件告警失败: {e}")
    
    def send_webhook_alert(self, alerts):
        """发送Webhook告警"""
        if not self.notifications['webhook']['enabled']:
            return
        
        try:
            webhook_config = self.notifications['webhook']
            
            payload = {
                'text': f"Redis告警 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
                'alerts': alerts
            }
            
            response = requests.post(
                webhook_config['url'],
                json=payload,
                timeout=10
            )
            
            if response.status_code == 200:
                print("Webhook告警发送成功")
            else:
                print(f"Webhook告警发送失败: {response.status_code}")
        
        except Exception as e:
            print(f"发送Webhook告警失败: {e}")
    
    def handle_alerts(self, metrics):
        """处理告警"""
        alerts = self.check_alert_rules(metrics)
        
        if not alerts:
            print("无告警")
            return
        
        print(f"检测到 {len(alerts)} 个告警:")
        for alert in alerts:
            print(f"- {alert['level']}: {alert['message']}")
        
        # 发送通知
        self.send_email_alert(alerts)
        self.send_webhook_alert(alerts)
        
        return alerts

# 使用示例
if __name__ == '__main__':
    # 模拟监控数据
    sample_metrics = {
        'redis': {
            'memory': {'used': 7 * 1024 * 1024 * 1024},  # 7GB
            'clients': {'connected': 900, 'max_clients': 1000},
            'stats': {'keyspace_hits': 800, 'keyspace_misses': 200}
        },
        'slow_queries': [{'id': 1}, {'id': 2}]  # 2个慢查询
    }
    
    handler = AlertHandler()
    handler.handle_alerts(sample_metrics)
```

## 备份恢复

### 备份策略

**自动备份脚本**：

```bash
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

```bash
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

**故障诊断脚本**：

```python
#!/usr/bin/env python3
# redis_diagnosis.py - Redis故障诊断脚本

import redis
import psutil
import time
import json
from datetime import datetime

class RedisDiagnosis:
    def __init__(self, host='localhost', port=6379, password=None):
        self.host = host
        self.port = port
        self.password = password
        self.redis_client = None
        self.diagnosis_results = []
    
    def connect_redis(self):
        """连接Redis"""
        try:
            self.redis_client = redis.Redis(
                host=self.host,
                port=self.port,
                password=self.password,
                decode_responses=True,
                socket_connect_timeout=5,
                socket_timeout=5
            )
            self.redis_client.ping()
            return True
        except Exception as e:
            self.add_result('connection', 'error', f'无法连接Redis: {e}')
            return False
    
    def add_result(self, category, level, message, details=None):
        """添加诊断结果"""
        result = {
            'timestamp': datetime.now().isoformat(),
            'category': category,
            'level': level,
            'message': message,
            'details': details or {}
        }
        self.diagnosis_results.append(result)
        
        # 输出到控制台
        level_symbol = {
            'info': '✓',
            'warning': '⚠',
            'error': '✗'
        }.get(level, '?')
        
        print(f"{level_symbol} [{category.upper()}] {message}")
    
    def check_connection(self):
        """检查连接状态"""
        if not self.connect_redis():
            return False
        
        try:
            # 检查响应时间
            start_time = time.time()
            self.redis_client.ping()
            response_time = (time.time() - start_time) * 1000
            
            if response_time > 100:
                self.add_result('connection', 'warning', 
                              f'响应时间较慢: {response_time:.2f}ms')
            else:
                self.add_result('connection', 'info', 
                              f'连接正常，响应时间: {response_time:.2f}ms')
            
            return True
        except Exception as e:
            self.add_result('connection', 'error', f'连接测试失败: {e}')
            return False
    
    def check_memory(self):
        """检查内存使用"""
        try:
            info = self.redis_client.info('memory')
            
            used_memory = info.get('used_memory', 0)
            used_memory_peak = info.get('used_memory_peak', 0)
            fragmentation_ratio = info.get('mem_fragmentation_ratio', 1.0)
            
            # 检查内存碎片
            if fragmentation_ratio > 1.5:
                self.add_result('memory', 'warning', 
                              f'内存碎片率过高: {fragmentation_ratio:.2f}',
                              {'fragmentation_ratio': fragmentation_ratio})
            
            # 检查内存使用趋势
            if used_memory > used_memory_peak * 0.9:
                self.add_result('memory', 'warning', 
                              '内存使用接近峰值',
                              {'used_memory': used_memory, 'peak_memory': used_memory_peak})
            
            self.add_result('memory', 'info', 
                          f'内存使用: {info.get("used_memory_human", "unknown")}',
                          info)
            
        except Exception as e:
            self.add_result('memory', 'error', f'内存检查失败: {e}')
    
    def check_performance(self):
        """检查性能指标"""
        try:
            info = self.redis_client.info('stats')
            
            # 检查命中率
            hits = info.get('keyspace_hits', 0)
            misses = info.get('keyspace_misses', 0)
            
            if hits + misses > 0:
                hit_rate = hits / (hits + misses)
                if hit_rate < 0.8:
                    self.add_result('performance', 'warning', 
                                  f'缓存命中率较低: {hit_rate:.2%}',
                                  {'hit_rate': hit_rate, 'hits': hits, 'misses': misses})
                else:
                    self.add_result('performance', 'info', 
                                  f'缓存命中率: {hit_rate:.2%}')
            
            # 检查慢查询
            slow_log = self.redis_client.slowlog_get(10)
            if slow_log:
                slow_count = len(slow_log)
                self.add_result('performance', 'warning', 
                              f'发现 {slow_count} 个慢查询',
                              {'slow_queries': slow_log[:3]})  # 只保存前3个
            
            # 检查QPS
            ops_per_sec = info.get('instantaneous_ops_per_sec', 0)
            self.add_result('performance', 'info', 
                          f'当前QPS: {ops_per_sec}',
                          {'ops_per_sec': ops_per_sec})
            
        except Exception as e:
            self.add_result('performance', 'error', f'性能检查失败: {e}')
    
    def check_persistence(self):
        """检查持久化状态"""
        try:
            info = self.redis_client.info('persistence')
            
            # 检查RDB
            rdb_last_save = info.get('rdb_last_save_time', 0)
            rdb_changes = info.get('rdb_changes_since_last_save', 0)
            
            if rdb_changes > 10000:
                self.add_result('persistence', 'warning', 
                              f'RDB未保存变更过多: {rdb_changes}',
                              {'rdb_changes': rdb_changes})
            
            # 检查AOF
            aof_enabled = info.get('aof_enabled', 0)
            if aof_enabled:
                aof_rewrite_in_progress = info.get('aof_rewrite_in_progress', 0)
                if aof_rewrite_in_progress:
                    self.add_result('persistence', 'info', 'AOF重写正在进行')
            
            self.add_result('persistence', 'info', 
                          f'持久化状态正常',
                          info)
            
        except Exception as e:
            self.add_result('persistence', 'error', f'持久化检查失败: {e}')
    
    def check_replication(self):
        """检查复制状态"""
        try:
            info = self.redis_client.info('replication')
            
            role = info.get('role', 'unknown')
            
            if role == 'master':
                connected_slaves = info.get('connected_slaves', 0)
                self.add_result('replication', 'info', 
                              f'主节点，连接的从节点数: {connected_slaves}',
                              {'role': role, 'slaves': connected_slaves})
            
            elif role == 'slave':
                master_link_status = info.get('master_link_status', 'unknown')
                if master_link_status != 'up':
                    self.add_result('replication', 'error', 
                                  f'主从连接异常: {master_link_status}',
                                  info)
                else:
                    lag = info.get('master_last_io_seconds_ago', 0)
                    if lag > 10:
                        self.add_result('replication', 'warning', 
                                      f'复制延迟: {lag}秒',
                                      {'replication_lag': lag})
                    else:
                        self.add_result('replication', 'info', 
                                      '从节点复制正常',
                                      info)
            
        except Exception as e:
            self.add_result('replication', 'error', f'复制检查失败: {e}')
    
    def check_system_resources(self):
        """检查系统资源"""
        try:
            # 查找Redis进程
            redis_processes = []
            for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
                if 'redis-server' in proc.info['name']:
                    redis_processes.append(proc)
            
            if not redis_processes:
                self.add_result('system', 'error', 'Redis进程未找到')
                return
            
            redis_proc = redis_processes[0]
            
            # CPU使用率
            cpu_percent = redis_proc.cpu_percent(interval=1)
            if cpu_percent > 80:
                self.add_result('system', 'warning', 
                              f'CPU使用率过高: {cpu_percent:.1f}%',
                              {'cpu_percent': cpu_percent})
            
            # 内存使用
            memory_info = redis_proc.memory_info()
            memory_percent = redis_proc.memory_percent()
            if memory_percent > 80:
                self.add_result('system', 'warning', 
                              f'系统内存使用率过高: {memory_percent:.1f}%',
                              {'memory_percent': memory_percent})
            
            # 文件描述符
            open_files = len(redis_proc.open_files())
            # 获取系统限制
            import resource
            max_files = resource.getrlimit(resource.RLIMIT_NOFILE)[0]
            if open_files > max_files * 0.8:
                self.add_result('system', 'warning', 
                              f'文件描述符使用过多: {open_files}/{max_files}',
                              {'open_files': open_files, 'max_files': max_files})
            
            self.add_result('system', 'info', 
                          f'系统资源正常 (CPU: {cpu_percent:.1f}%, 内存: {memory_percent:.1f}%)',
                          {
                              'cpu_percent': cpu_percent,
                              'memory_percent': memory_percent,
                              'open_files': open_files
                          })
            
        except Exception as e:
            self.add_result('system', 'error', f'系统资源检查失败: {e}')
    
    def check_configuration(self):
        """检查配置"""
        try:
            # 检查关键配置项
            configs_to_check = [
                'maxmemory',
                'maxmemory-policy',
                'timeout',
                'tcp-keepalive',
                'maxclients'
            ]
            
            config_issues = []
            
            for config_key in configs_to_check:
                try:
                    config_value = self.redis_client.config_get(config_key)
                    
                    # 检查特定配置
                    if config_key == 'maxmemory' and config_value.get(config_key) == '0':
                        config_issues.append(f'{config_key}: 未设置内存限制')
                    
                    elif config_key == 'timeout' and int(config_value.get(config_key, 0)) == 0:
                        config_issues.append(f'{config_key}: 客户端超时未设置')
                    
                except Exception:
                    config_issues.append(f'{config_key}: 无法获取配置')
            
            if config_issues:
                self.add_result('configuration', 'warning', 
                              '发现配置问题',
                              {'issues': config_issues})
            else:
                self.add_result('configuration', 'info', '配置检查正常')
            
        except Exception as e:
            self.add_result('configuration', 'error', f'配置检查失败: {e}')
    
    def run_diagnosis(self):
        """运行完整诊断"""
        print(f"\n=== Redis故障诊断开始 ({self.host}:{self.port}) ===")
        print(f"诊断时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        # 执行各项检查
        checks = [
            ('连接检查', self.check_connection),
            ('内存检查', self.check_memory),
            ('性能检查', self.check_performance),
            ('持久化检查', self.check_persistence),
            ('复制检查', self.check_replication),
            ('系统资源检查', self.check_system_resources),
            ('配置检查', self.check_configuration)
        ]
        
        for check_name, check_func in checks:
            print(f"\n--- {check_name} ---")
            try:
                check_func()
            except Exception as e:
                self.add_result('diagnosis', 'error', f'{check_name}失败: {e}')
        
        # 生成诊断报告
        self.generate_report()
    
    def generate_report(self):
        """生成诊断报告"""
        print("\n" + "=" * 60)
        print("诊断报告摘要")
        print("=" * 60)
        
        # 统计各级别问题数量
        error_count = len([r for r in self.diagnosis_results if r['level'] == 'error'])
        warning_count = len([r for r in self.diagnosis_results if r['level'] == 'warning'])
        info_count = len([r for r in self.diagnosis_results if r['level'] == 'info'])
        
        print(f"错误: {error_count} 个")
        print(f"警告: {warning_count} 个")
        print(f"信息: {info_count} 个")
        
        # 显示错误和警告
        if error_count > 0:
            print("\n严重问题:")
            for result in self.diagnosis_results:
                if result['level'] == 'error':
                    print(f"  ✗ {result['message']}")
        
        if warning_count > 0:
            print("\n警告问题:")
            for result in self.diagnosis_results:
                if result['level'] == 'warning':
                    print(f"  ⚠ {result['message']}")
        
        # 保存详细报告
        report_file = f"redis_diagnosis_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump({
                'diagnosis_time': datetime.now().isoformat(),
                'redis_host': self.host,
                'redis_port': self.port,
                'summary': {
                    'error_count': error_count,
                    'warning_count': warning_count,
                    'info_count': info_count
                },
                'results': self.diagnosis_results
            }, f, indent=2, default=str)
        
        print(f"\n详细报告已保存到: {report_file}")
        
        # 给出建议
        if error_count > 0:
            print("\n建议: 立即处理严重问题")
        elif warning_count > 0:
            print("\n建议: 关注警告问题，考虑优化")
        else:
            print("\n状态: Redis运行正常")

if __name__ == '__main__':
    import sys
    
    host = sys.argv[1] if len(sys.argv) > 1 else 'localhost'
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 6379
    password = sys.argv[3] if len(sys.argv) > 3 else None
    
    diagnosis = RedisDiagnosis(host, port, password)
    diagnosis.run_diagnosis()
```

### 故障处理手册

**常见故障及解决方案**：

```markdown
# Redis故障处理手册

## 1. 连接问题

### 症状
- 客户端无法连接Redis
- 连接超时
- 连接被拒绝

### 可能原因
1. Redis服务未启动
2. 端口被占用或防火墙阻止
3. 配置文件错误
4. 内存不足

### 解决步骤
```bash
# 1. 检查Redis进程
ps aux | grep redis-server

# 2. 检查端口监听
netstat -tlnp | grep 6379

# 3. 检查防火墙
sudo ufw status
sudo iptables -L

# 4. 查看Redis日志
tail -f /var/log/redis/redis-server.log

# 5. 测试连接
redis-cli ping
```

## 2. 内存问题

### 症状
- 内存使用率过高
- OOM错误
- 性能下降

### 解决步骤
```bash
# 1. 检查内存使用
redis-cli info memory

# 2. 分析大键
redis-cli --bigkeys

# 3. 设置内存限制
redis-cli config set maxmemory 2gb
redis-cli config set maxmemory-policy allkeys-lru

# 4. 清理过期键
redis-cli --scan --pattern "expired:*" | xargs redis-cli del
```

## 3. 性能问题

### 症状
- 响应时间慢
- QPS下降
- 慢查询增多

### 解决步骤
```bash
# 1. 查看慢查询
redis-cli slowlog get 10

# 2. 监控实时命令
redis-cli monitor

# 3. 检查网络延迟
ping redis-server-ip

# 4. 优化配置
redis-cli config set tcp-keepalive 60
redis-cli config set timeout 300
```

## 4. 持久化问题

### 症状
- RDB保存失败
- AOF文件损坏
- 数据丢失

### 解决步骤
```bash
# 1. 检查磁盘空间
df -h

# 2. 检查文件权限
ls -la /var/lib/redis/

# 3. 修复AOF文件
redis-check-aof --fix /var/lib/redis/appendonly.aof

# 4. 手动触发保存
redis-cli bgsave
```

## 5. 主从复制问题

### 症状
- 主从同步失败
- 复制延迟过大
- 从节点数据不一致

### 解决步骤
```bash
# 1. 检查复制状态
redis-cli info replication

# 2. 重新同步
redis-cli slaveof no one
redis-cli slaveof master-ip 6379

# 3. 检查网络连接
telnet master-ip 6379

# 4. 调整复制参数
redis-cli config set repl-backlog-size 64mb
```

## 容量规划

### 容量评估脚本

**Redis容量分析工具**：

```python
#!/usr/bin/env python3
# redis_capacity_planner.py - Redis容量规划工具

import redis
import json
import time
import statistics
from datetime import datetime, timedelta
from collections import defaultdict

class RedisCapacityPlanner:
    def __init__(self, host='localhost', port=6379, password=None):
        self.redis_client = redis.Redis(
            host=host, port=port, password=password, decode_responses=True
        )
        self.metrics_history = []
    
    def collect_metrics(self):
        """收集当前指标"""
        try:
            info = self.redis_client.info()
            
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'memory': {
                    'used_memory': info.get('used_memory', 0),
                    'used_memory_peak': info.get('used_memory_peak', 0),
                    'used_memory_rss': info.get('used_memory_rss', 0),
                    'mem_fragmentation_ratio': info.get('mem_fragmentation_ratio', 1.0)
                },
                'clients': {
                    'connected_clients': info.get('connected_clients', 0),
                    'blocked_clients': info.get('blocked_clients', 0)
                },
                'stats': {
                    'total_commands_processed': info.get('total_commands_processed', 0),
                    'instantaneous_ops_per_sec': info.get('instantaneous_ops_per_sec', 0),
                    'keyspace_hits': info.get('keyspace_hits', 0),
                    'keyspace_misses': info.get('keyspace_misses', 0)
                },
                'keyspace': self.get_keyspace_info(),
                'persistence': {
                    'rdb_changes_since_last_save': info.get('rdb_changes_since_last_save', 0),
                    'aof_current_size': info.get('aof_current_size', 0)
                }
            }
            
            return metrics
        except Exception as e:
            print(f"收集指标失败: {e}")
            return None
    
    def get_keyspace_info(self):
        """获取键空间信息"""
        try:
            keyspace_info = {}
            info = self.redis_client.info('keyspace')
            
            for db_key, db_info in info.items():
                if db_key.startswith('db'):
                    # 解析db信息: keys=xxx,expires=xxx,avg_ttl=xxx
                    db_stats = {}
                    for item in db_info.split(','):
                        key, value = item.split('=')
                        db_stats[key] = int(value)
                    keyspace_info[db_key] = db_stats
            
            return keyspace_info
        except Exception:
            return {}
    
    def analyze_key_patterns(self, sample_size=1000):
        """分析键模式"""
        try:
            print("分析键模式...")
            
            # 使用SCAN获取键样本
            keys_sample = []
            cursor = 0
            
            while len(keys_sample) < sample_size:
                cursor, keys = self.redis_client.scan(cursor, count=100)
                keys_sample.extend(keys)
                
                if cursor == 0:  # 扫描完成
                    break
            
            # 分析键模式
            pattern_stats = defaultdict(lambda: {'count': 0, 'total_size': 0, 'avg_ttl': 0})
            
            for key in keys_sample[:sample_size]:
                try:
                    # 提取键模式（前缀）
                    pattern = key.split(':')[0] if ':' in key else 'no_pattern'
                    
                    # 获取键信息
                    key_type = self.redis_client.type(key)
                    memory_usage = self.redis_client.memory_usage(key) or 0
                    ttl = self.redis_client.ttl(key)
                    
                    pattern_stats[pattern]['count'] += 1
                    pattern_stats[pattern]['total_size'] += memory_usage
                    
                    if ttl > 0:
                        pattern_stats[pattern]['avg_ttl'] = (
                            pattern_stats[pattern]['avg_ttl'] + ttl
                        ) / 2
                    
                except Exception:
                    continue
            
            # 计算平均大小
            for pattern, stats in pattern_stats.items():
                if stats['count'] > 0:
                    stats['avg_size'] = stats['total_size'] / stats['count']
            
            return dict(pattern_stats)
        
        except Exception as e:
            print(f"键模式分析失败: {e}")
            return {}
    
    def predict_growth(self, days=30):
        """预测增长趋势"""
        if len(self.metrics_history) < 2:
            return None
        
        # 计算内存增长率
        memory_values = [m['memory']['used_memory'] for m in self.metrics_history]
        time_points = [datetime.fromisoformat(m['timestamp']) for m in self.metrics_history]
        
        if len(memory_values) < 2:
            return None
        
        # 简单线性增长预测
        time_diffs = [(t - time_points[0]).total_seconds() / 3600 for t in time_points]  # 小时
        
        # 计算增长率（每小时）
        growth_rates = []
        for i in range(1, len(memory_values)):
            if time_diffs[i] > 0:
                rate = (memory_values[i] - memory_values[i-1]) / time_diffs[i]
                growth_rates.append(rate)
        
        if not growth_rates:
            return None
        
        avg_growth_rate = statistics.mean(growth_rates)  # 字节/小时
        current_memory = memory_values[-1]
        
        # 预测未来内存使用
        future_memory = current_memory + (avg_growth_rate * 24 * days)
        
        return {
            'current_memory': current_memory,
            'predicted_memory': future_memory,
            'growth_rate_per_hour': avg_growth_rate,
            'growth_rate_per_day': avg_growth_rate * 24,
            'prediction_days': days
        }
    
    def generate_capacity_report(self):
        """生成容量规划报告"""
        print("\n=== Redis容量规划报告 ===")
        print(f"生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
        
        # 当前状态
        current_metrics = self.collect_metrics()
        if not current_metrics:
            print("无法获取当前指标")
            return
        
        print("1. 当前状态")
        print("-" * 40)
        memory_mb = current_metrics['memory']['used_memory'] / 1024 / 1024
        print(f"内存使用: {memory_mb:.2f} MB")
        print(f"连接数: {current_metrics['clients']['connected_clients']}")
        print(f"QPS: {current_metrics['stats']['instantaneous_ops_per_sec']}")
        
        # 键空间分析
        total_keys = sum(
            db_info.get('keys', 0) 
            for db_info in current_metrics['keyspace'].values()
        )
        print(f"总键数: {total_keys}")
        
        # 键模式分析
        print("\n2. 键模式分析")
        print("-" * 40)
        key_patterns = self.analyze_key_patterns()
        
        if key_patterns:
            # 按内存使用排序
            sorted_patterns = sorted(
                key_patterns.items(),
                key=lambda x: x[1]['total_size'],
                reverse=True
            )
            
            print(f"{'模式':<20} {'数量':<10} {'总大小(KB)':<15} {'平均大小(B)':<15}")
            print("-" * 65)
            
            for pattern, stats in sorted_patterns[:10]:
                avg_size = stats.get('avg_size', 0)
                total_kb = stats['total_size'] / 1024
                print(f"{pattern:<20} {stats['count']:<10} {total_kb:<15.2f} {avg_size:<15.0f}")
        
        # 增长预测
        print("\n3. 增长预测")
        print("-" * 40)
        
        if len(self.metrics_history) >= 2:
            prediction = self.predict_growth(30)
            if prediction:
                current_gb = prediction['current_memory'] / 1024 / 1024 / 1024
                predicted_gb = prediction['predicted_memory'] / 1024 / 1024 / 1024
                growth_mb_day = prediction['growth_rate_per_day'] / 1024 / 1024
                
                print(f"当前内存: {current_gb:.2f} GB")
                print(f"30天后预测: {predicted_gb:.2f} GB")
                print(f"日增长率: {growth_mb_day:.2f} MB/天")
                
                # 容量建议
                print("\n4. 容量建议")
                print("-" * 40)
                
                if predicted_gb > 8:
                    print("⚠ 建议: 考虑增加内存或优化数据结构")
                elif predicted_gb > 4:
                    print("⚠ 建议: 监控内存使用，准备扩容计划")
                else:
                    print("✓ 当前容量充足")
                
                # 扩容时间点预测
                if growth_mb_day > 0:
                    # 假设8GB为容量上限
                    max_capacity = 8 * 1024 * 1024 * 1024
                    remaining_capacity = max_capacity - prediction['current_memory']
                    days_to_full = remaining_capacity / prediction['growth_rate_per_day']
                    
                    if days_to_full > 0:
                        full_date = datetime.now() + timedelta(days=days_to_full)
                        print(f"预计容量耗尽时间: {full_date.strftime('%Y-%m-%d')} ({days_to_full:.0f}天后)")
            else:
                print("数据不足，无法进行增长预测")
        else:
            print("需要更多历史数据进行预测")
        
        # 性能建议
        print("\n5. 性能优化建议")
        print("-" * 40)
        
        fragmentation = current_metrics['memory']['mem_fragmentation_ratio']
        if fragmentation > 1.5:
            print("⚠ 内存碎片率过高，建议重启Redis或使用MEMORY PURGE")
        
        hit_rate = 0
        hits = current_metrics['stats']['keyspace_hits']
        misses = current_metrics['stats']['keyspace_misses']
        if hits + misses > 0:
            hit_rate = hits / (hits + misses)
            if hit_rate < 0.8:
                print(f"⚠ 缓存命中率较低({hit_rate:.2%})，建议优化缓存策略")
        
        if current_metrics['clients']['connected_clients'] > 1000:
            print("⚠ 连接数较多，建议使用连接池")
        
        # 保存报告
        report_data = {
            'timestamp': datetime.now().isoformat(),
            'current_metrics': current_metrics,
            'key_patterns': key_patterns,
            'prediction': prediction if len(self.metrics_history) >= 2 else None,
            'recommendations': []
        }
        
        report_file = f"redis_capacity_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.json"
        with open(report_file, 'w') as f:
            json.dump(report_data, f, indent=2, default=str)
        
        print(f"\n详细报告已保存到: {report_file}")
    
    def monitor_and_collect(self, duration_hours=24, interval_minutes=10):
        """监控并收集数据"""
        print(f"开始收集数据，持续{duration_hours}小时，间隔{interval_minutes}分钟")
        
        end_time = datetime.now() + timedelta(hours=duration_hours)
        
        while datetime.now() < end_time:
            metrics = self.collect_metrics()
            if metrics:
                self.metrics_history.append(metrics)
                print(f"已收集数据点: {len(self.metrics_history)}")
            
            time.sleep(interval_minutes * 60)
        
        print(f"数据收集完成，共收集{len(self.metrics_history)}个数据点")

if __name__ == '__main__':
    planner = RedisCapacityPlanner()
    
    # 收集一些历史数据（演示用）
    for i in range(5):
        metrics = planner.collect_metrics()
        if metrics:
            planner.metrics_history.append(metrics)
        time.sleep(1)
    
    # 生成报告
    planner.generate_capacity_report()
```

## 实践操作

### 搭建Redis运维管理环境

**环境准备脚本**：

```bash
#!/bin/bash
# setup_redis_ops.sh - Redis运维环境搭建脚本

set -e

echo "=== Redis运维管理环境搭建 ==="

# 创建工作目录
OPS_DIR="redis_ops_$(date +%Y%m%d_%H%M%S)"
mkdir -p $OPS_DIR
cd $OPS_DIR

echo "工作目录: $(pwd)"

# 创建目录结构
mkdir -p {\
    scripts/{monitoring,backup,diagnosis,capacity},\
    configs,\
    logs,\
    reports,\
    data/backup\
}

echo "目录结构创建完成"

# 安装Python依赖
echo "安装Python依赖..."
pip3 install redis psutil matplotlib pandas

# 创建配置文件
cat > configs/redis_ops.conf << 'EOF'
# Redis运维配置
[redis]
host = localhost
port = 6379
password = 
database = 0

[monitoring]
interval = 60
thresholds_memory_usage = 80
thresholds_cpu_usage = 70
thresholds_connections = 1000
thresholds_hit_rate = 0.8

[backup]
backup_dir = ./data/backup
retention_days = 7
compress = true

[alerts]
email_enabled = false
email_smtp_server = smtp.example.com
email_smtp_port = 587
email_username = 
email_password = 
email_to = admin@example.com

slack_enabled = false
slack_webhook_url = 

[capacity]
max_memory_gb = 8
growth_prediction_days = 30
EOF

echo "配置文件创建完成"

# 创建监控脚本
cat > scripts/monitoring/redis_monitor.py << 'EOF'
#!/usr/bin/env python3
# redis_monitor.py - Redis监控脚本

import redis
import time
import json
import configparser
import smtplib
import requests
from datetime import datetime
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

class RedisMonitor:
    def __init__(self, config_file='../../configs/redis_ops.conf'):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        # Redis连接
        self.redis_client = redis.Redis(
            host=self.config.get('redis', 'host'),
            port=self.config.getint('redis', 'port'),
            password=self.config.get('redis', 'password') or None,
            decode_responses=True
        )
        
        # 阈值配置
        self.thresholds = {
            'memory_usage': self.config.getfloat('monitoring', 'thresholds_memory_usage'),
            'cpu_usage': self.config.getfloat('monitoring', 'thresholds_cpu_usage'),
            'connections': self.config.getint('monitoring', 'thresholds_connections'),
            'hit_rate': self.config.getfloat('monitoring', 'thresholds_hit_rate')
        }
        
        self.alerts = []
    
    def collect_metrics(self):
        """收集Redis指标"""
        try:
            info = self.redis_client.info()
            
            # 计算内存使用率
            used_memory = info.get('used_memory', 0)
            max_memory = info.get('maxmemory', 0)
            memory_usage_pct = (used_memory / max_memory * 100) if max_memory > 0 else 0
            
            # 计算缓存命中率
            hits = info.get('keyspace_hits', 0)
            misses = info.get('keyspace_misses', 0)
            hit_rate = hits / (hits + misses) if (hits + misses) > 0 else 0
            
            metrics = {
                'timestamp': datetime.now().isoformat(),
                'memory': {
                    'used_memory': used_memory,
                    'used_memory_human': info.get('used_memory_human', ''),
                    'used_memory_peak': info.get('used_memory_peak', 0),
                    'memory_usage_pct': memory_usage_pct,
                    'mem_fragmentation_ratio': info.get('mem_fragmentation_ratio', 1.0)
                },
                'performance': {
                    'instantaneous_ops_per_sec': info.get('instantaneous_ops_per_sec', 0),
                    'hit_rate': hit_rate,
                    'keyspace_hits': hits,
                    'keyspace_misses': misses
                },
                'connections': {
                    'connected_clients': info.get('connected_clients', 0),
                    'blocked_clients': info.get('blocked_clients', 0),
                    'rejected_connections': info.get('rejected_connections', 0)
                },
                'persistence': {
                    'rdb_last_save_time': info.get('rdb_last_save_time', 0),
                    'rdb_changes_since_last_save': info.get('rdb_changes_since_last_save', 0),
                    'aof_enabled': info.get('aof_enabled', 0)
                },
                'replication': {
                    'role': info.get('role', 'unknown'),
                    'connected_slaves': info.get('connected_slaves', 0),
                    'master_repl_offset': info.get('master_repl_offset', 0)
                }
            }
            
            return metrics
        except Exception as e:
            print(f"收集指标失败: {e}")
            return None
    
    def check_thresholds(self, metrics):
        """检查阈值并生成告警"""
        self.alerts = []
        
        # 内存使用率检查
        memory_usage = metrics['memory']['memory_usage_pct']
        if memory_usage > self.thresholds['memory_usage']:
            self.alerts.append({
                'level': 'warning',
                'type': 'memory',
                'message': f"内存使用率过高: {memory_usage:.1f}%",
                'value': memory_usage,
                'threshold': self.thresholds['memory_usage']
            })
        
        # 连接数检查
        connections = metrics['connections']['connected_clients']
        if connections > self.thresholds['connections']:
            self.alerts.append({
                'level': 'warning',
                'type': 'connections',
                'message': f"连接数过多: {connections}",
                'value': connections,
                'threshold': self.thresholds['connections']
            })
        
        # 缓存命中率检查
        hit_rate = metrics['performance']['hit_rate']
        if hit_rate < self.thresholds['hit_rate']:
            self.alerts.append({
                'level': 'warning',
                'type': 'hit_rate',
                'message': f"缓存命中率过低: {hit_rate:.2%}",
                'value': hit_rate,
                'threshold': self.thresholds['hit_rate']
            })
        
        # 内存碎片检查
        fragmentation = metrics['memory']['mem_fragmentation_ratio']
        if fragmentation > 1.5:
            self.alerts.append({
                'level': 'warning',
                'type': 'fragmentation',
                'message': f"内存碎片率过高: {fragmentation:.2f}",
                'value': fragmentation,
                'threshold': 1.5
            })
    
    def send_alerts(self):
        """发送告警"""
        if not self.alerts:
            return
        
        alert_message = self.format_alert_message()
        
        # 邮件告警
        if self.config.getboolean('alerts', 'email_enabled', fallback=False):
            self.send_email_alert(alert_message)
        
        # Slack告警
        if self.config.getboolean('alerts', 'slack_enabled', fallback=False):
            self.send_slack_alert(alert_message)
        
        # 控制台输出
        print("\n=== Redis告警 ===")
        print(alert_message)
    
    def format_alert_message(self):
        """格式化告警消息"""
        message = f"Redis告警 - {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        
        for alert in self.alerts:
            message += f"[{alert['level'].upper()}] {alert['message']}\n"
        
        return message
    
    def send_email_alert(self, message):
        """发送邮件告警"""
        try:
            smtp_server = self.config.get('alerts', 'email_smtp_server')
            smtp_port = self.config.getint('alerts', 'email_smtp_port')
            username = self.config.get('alerts', 'email_username')
            password = self.config.get('alerts', 'email_password')
            to_email = self.config.get('alerts', 'email_to')
            
            msg = MIMEMultipart()
            msg['From'] = username
            msg['To'] = to_email
            msg['Subject'] = "Redis监控告警"
            
            msg.attach(MIMEText(message, 'plain'))
            
            server = smtplib.SMTP(smtp_server, smtp_port)
            server.starttls()
            server.login(username, password)
            server.send_message(msg)
            server.quit()
            
            print("邮件告警发送成功")
        except Exception as e:
            print(f"邮件告警发送失败: {e}")
    
    def send_slack_alert(self, message):
        """发送Slack告警"""
        try:
            webhook_url = self.config.get('alerts', 'slack_webhook_url')
            
            payload = {
                'text': message,
                'username': 'Redis Monitor',
                'icon_emoji': ':warning:'
            }
            
            response = requests.post(webhook_url, json=payload)
            response.raise_for_status()
            
            print("Slack告警发送成功")
        except Exception as e:
            print(f"Slack告警发送失败: {e}")
    
    def save_metrics(self, metrics):
        """保存指标到文件"""
        log_file = f"../../logs/redis_metrics_{datetime.now().strftime('%Y%m%d')}.jsonl"
        
        with open(log_file, 'a') as f:
            f.write(json.dumps(metrics) + '\n')
    
    def run_monitoring(self):
        """运行监控"""
        print(f"开始Redis监控 - {datetime.now()}")
        
        metrics = self.collect_metrics()
        if not metrics:
            print("无法收集指标")
            return
        
        # 检查阈值
        self.check_thresholds(metrics)
        
        # 发送告警
        self.send_alerts()
        
        # 保存指标
        self.save_metrics(metrics)
        
        # 输出当前状态
        print(f"\n当前状态:")
        print(f"  内存使用: {metrics['memory']['used_memory_human']}")
        print(f"  连接数: {metrics['connections']['connected_clients']}")
        print(f"  QPS: {metrics['performance']['instantaneous_ops_per_sec']}")
        print(f"  命中率: {metrics['performance']['hit_rate']:.2%}")
        
        if self.alerts:
            print(f"  告警数: {len(self.alerts)}")
        else:
            print("  状态: 正常")

if __name__ == '__main__':
    monitor = RedisMonitor()
    monitor.run_monitoring()
EOF

# 创建备份脚本
cat > scripts/backup/redis_backup.py << 'EOF'
#!/usr/bin/env python3
# redis_backup.py - Redis备份脚本

import redis
import os
import gzip
import shutil
import configparser
from datetime import datetime, timedelta

class RedisBackup:
    def __init__(self, config_file='../../configs/redis_ops.conf'):
        self.config = configparser.ConfigParser()
        self.config.read(config_file)
        
        self.redis_client = redis.Redis(
            host=self.config.get('redis', 'host'),
            port=self.config.getint('redis', 'port'),
            password=self.config.get('redis', 'password') or None
        )
        
        self.backup_dir = self.config.get('backup', 'backup_dir')
        self.retention_days = self.config.getint('backup', 'retention_days')
        self.compress = self.config.getboolean('backup', 'compress')
        
        os.makedirs(self.backup_dir, exist_ok=True)
    
    def create_backup(self):
        """创建备份"""
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        backup_name = f"redis_backup_{timestamp}"
        
        try:
            # 触发RDB保存
            print("开始创建RDB快照...")
            self.redis_client.bgsave()
            
            # 等待保存完成
            while True:
                info = self.redis_client.info('persistence')
                if info.get('rdb_bgsave_in_progress', 0) == 0:
                    break
                time.sleep(1)
            
            # 获取RDB文件路径
            config_info = self.redis_client.config_get('dir')
            redis_dir = config_info.get('dir', '/var/lib/redis')
            
            dbfilename_info = self.redis_client.config_get('dbfilename')
            dbfilename = dbfilename_info.get('dbfilename', 'dump.rdb')
            
            rdb_path = os.path.join(redis_dir, dbfilename)
            
            if not os.path.exists(rdb_path):
                print(f"RDB文件不存在: {rdb_path}")
                return False
            
            # 复制RDB文件
            backup_file = os.path.join(self.backup_dir, f"{backup_name}.rdb")
            shutil.copy2(rdb_path, backup_file)
            
            # 压缩备份文件
            if self.compress:
                print("压缩备份文件...")
                with open(backup_file, 'rb') as f_in:
                    with gzip.open(f"{backup_file}.gz", 'wb') as f_out:
                        shutil.copyfileobj(f_in, f_out)
                
                os.remove(backup_file)
                backup_file = f"{backup_file}.gz"
            
            # 获取文件大小
            file_size = os.path.getsize(backup_file)
            
            print(f"备份创建成功: {backup_file}")
            print(f"备份大小: {file_size / 1024 / 1024:.2f} MB")
            
            return True
            
        except Exception as e:
            print(f"备份创建失败: {e}")
            return False
    
    def cleanup_old_backups(self):
        """清理过期备份"""
        try:
            cutoff_date = datetime.now() - timedelta(days=self.retention_days)
            
            for filename in os.listdir(self.backup_dir):
                if not filename.startswith('redis_backup_'):
                    continue
                
                file_path = os.path.join(self.backup_dir, filename)
                file_mtime = datetime.fromtimestamp(os.path.getmtime(file_path))
                
                if file_mtime < cutoff_date:
                    os.remove(file_path)
                    print(f"删除过期备份: {filename}")
            
        except Exception as e:
            print(f"清理备份失败: {e}")
    
    def list_backups(self):
        """列出所有备份"""
        try:
            backups = []
            
            for filename in os.listdir(self.backup_dir):
                if not filename.startswith('redis_backup_'):
                    continue
                
                file_path = os.path.join(self.backup_dir, filename)
                file_stat = os.stat(file_path)
                
                backups.append({
                    'filename': filename,
                    'size': file_stat.st_size,
                    'mtime': datetime.fromtimestamp(file_stat.st_mtime)
                })
            
            # 按时间排序
            backups.sort(key=lambda x: x['mtime'], reverse=True)
            
            print("\n=== 备份列表 ===")
            print(f"{'文件名':<30} {'大小(MB)':<10} {'创建时间':<20}")
            print("-" * 65)
            
            for backup in backups:
                size_mb = backup['size'] / 1024 / 1024
                mtime_str = backup['mtime'].strftime('%Y-%m-%d %H:%M:%S')
                print(f"{backup['filename']:<30} {size_mb:<10.2f} {mtime_str:<20}")
            
            return backups
            
        except Exception as e:
            print(f"列出备份失败: {e}")
            return []

if __name__ == '__main__':
    import sys
    
    backup = RedisBackup()
    
    if len(sys.argv) > 1 and sys.argv[1] == 'list':
        backup.list_backups()
    else:
        backup.create_backup()
        backup.cleanup_old_backups()
EOF

# 创建运维管理脚本
cat > scripts/redis_ops_manager.py << 'EOF'
#!/usr/bin/env python3
# redis_ops_manager.py - Redis运维管理主脚本

import sys
import os
import time
import threading
from datetime import datetime

# 添加脚本路径
sys.path.append(os.path.join(os.path.dirname(__file__), 'monitoring'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'backup'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'diagnosis'))
sys.path.append(os.path.join(os.path.dirname(__file__), 'capacity'))

from redis_monitor import RedisMonitor
from redis_backup import RedisBackup

class RedisOpsManager:
    def __init__(self):
        self.monitor = RedisMonitor()
        self.backup = RedisBackup()
        self.running = False
    
    def start_monitoring(self, interval=60):
        """启动监控"""
        print(f"启动Redis监控，间隔{interval}秒")
        self.running = True
        
        def monitor_loop():
            while self.running:
                try:
                    self.monitor.run_monitoring()
                    time.sleep(interval)
                except KeyboardInterrupt:
                    break
                except Exception as e:
                    print(f"监控异常: {e}")
                    time.sleep(interval)
        
        monitor_thread = threading.Thread(target=monitor_loop)
        monitor_thread.daemon = True
        monitor_thread.start()
        
        return monitor_thread
    
    def stop_monitoring(self):
        """停止监控"""
        self.running = False
        print("停止Redis监控")
    
    def create_backup(self):
        """创建备份"""
        print("创建Redis备份...")
        success = self.backup.create_backup()
        if success:
            self.backup.cleanup_old_backups()
        return success
    
    def list_backups(self):
        """列出备份"""
        return self.backup.list_backups()
    
    def run_diagnosis(self):
        """运行诊断"""
        try:
            from redis_diagnosis import RedisDiagnosis
            diagnosis = RedisDiagnosis()
            diagnosis.run_diagnosis()
        except ImportError:
            print("诊断模块未找到")
    
    def generate_capacity_report(self):
        """生成容量报告"""
        try:
            from redis_capacity_planner import RedisCapacityPlanner
            planner = RedisCapacityPlanner()
            planner.generate_capacity_report()
        except ImportError:
            print("容量规划模块未找到")
    
    def show_status(self):
        """显示状态"""
        print("\n=== Redis运维状态 ===")
        print(f"时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"监控状态: {'运行中' if self.running else '已停止'}")
        
        # 获取Redis基本信息
        try:
            metrics = self.monitor.collect_metrics()
            if metrics:
                print(f"Redis状态: 正常")
                print(f"内存使用: {metrics['memory']['used_memory_human']}")
                print(f"连接数: {metrics['connections']['connected_clients']}")
                print(f"QPS: {metrics['performance']['instantaneous_ops_per_sec']}")
            else:
                print(f"Redis状态: 连接失败")
        except Exception as e:
            print(f"Redis状态: 异常 - {e}")
    
    def interactive_menu(self):
        """交互式菜单"""
        while True:
            print("\n=== Redis运维管理 ===")
            print("1. 显示状态")
            print("2. 启动监控")
            print("3. 停止监控")
            print("4. 创建备份")
            print("5. 列出备份")
            print("6. 运行诊断")
            print("7. 容量报告")
            print("0. 退出")
            
            choice = input("\n请选择操作: ").strip()
            
            if choice == '1':
                self.show_status()
            elif choice == '2':
                interval = input("监控间隔(秒，默认60): ").strip()
                interval = int(interval) if interval.isdigit() else 60
                self.start_monitoring(interval)
            elif choice == '3':
                self.stop_monitoring()
            elif choice == '4':
                self.create_backup()
            elif choice == '5':
                self.list_backups()
            elif choice == '6':
                self.run_diagnosis()
            elif choice == '7':
                self.generate_capacity_report()
            elif choice == '0':
                self.stop_monitoring()
                print("退出运维管理")
                break
            else:
                print("无效选择")

if __name__ == '__main__':
    manager = RedisOpsManager()
    
    if len(sys.argv) > 1:
        command = sys.argv[1]
        
        if command == 'monitor':
            interval = int(sys.argv[2]) if len(sys.argv) > 2 else 60
            thread = manager.start_monitoring(interval)
            try:
                thread.join()
            except KeyboardInterrupt:
                manager.stop_monitoring()
        elif command == 'backup':
            manager.create_backup()
        elif command == 'status':
            manager.show_status()
        elif command == 'diagnosis':
            manager.run_diagnosis()
        elif command == 'capacity':
            manager.generate_capacity_report()
        else:
            print(f"未知命令: {command}")
    else:
        manager.interactive_menu()
EOF

# 设置执行权限
chmod +x scripts/monitoring/redis_monitor.py
chmod +x scripts/backup/redis_backup.py
chmod +x scripts/redis_ops_manager.py

echo "\n=== 环境搭建完成 ==="
echo "工作目录: $(pwd)"
echo "\n使用方法:"
echo "1. 修改配置文件: configs/redis_ops.conf"
echo "2. 运行监控: python3 scripts/redis_ops_manager.py monitor"
echo "3. 创建备份: python3 scripts/redis_ops_manager.py backup"
echo "4. 交互模式: python3 scripts/redis_ops_manager.py"
echo "\n日志目录: logs/"
echo "报告目录: reports/"
echo "备份目录: data/backup/"
```

### 运维操作示例

**日常运维脚本**：

```bash
#!/bin/bash
# daily_ops.sh - 日常运维脚本

set -e

echo "=== Redis日常运维 $(date) ==="

# 1. 健康检查
echo "\n1. 健康检查"
echo "-------------------"
python3 scripts/redis_ops_manager.py status

# 2. 创建备份
echo "\n2. 创建备份"
echo "-------------------"
python3 scripts/redis_ops_manager.py backup

# 3. 运行诊断
echo "\n3. 系统诊断"
echo "-------------------"
python3 scripts/redis_ops_manager.py diagnosis

# 4. 生成容量报告
echo "\n4. 容量分析"
echo "-------------------"
python3 scripts/redis_ops_manager.py capacity

# 5. 清理日志
echo "\n5. 清理日志"
echo "-------------------"
find logs/ -name "*.jsonl" -mtime +7 -delete
find reports/ -name "*.json" -mtime +30 -delete

echo "\n=== 日常运维完成 ==="
```

## 总结

本章详细介绍了Redis运维管理的核心内容：

### 监控告警
- **核心指标监控**：内存使用、性能指标、连接状态、持久化状态
- **实时监控脚本**：自动收集指标、阈值检查、告警通知
- **告警机制**：邮件告警、Slack集成、多级告警策略
- **监控数据存储**：指标历史记录、趋势分析

### 备份恢复
- **自动备份策略**：定时RDB备份、增量AOF备份
- **备份压缩存储**：节省存储空间、提高传输效率
- **备份保留策略**：自动清理过期备份、存储空间管理
- **恢复验证**：备份完整性检查、恢复测试

### 故障处理
- **故障诊断工具**：自动化诊断脚本、问题检测
- **常见故障手册**：连接问题、内存问题、性能问题、持久化问题
- **故障处理流程**：问题定位、解决方案、预防措施
- **应急响应**：快速恢复、数据保护

### 容量规划
- **容量监控分析**：内存使用趋势、键空间分析、性能指标
- **增长预测模型**：基于历史数据的容量预测
- **扩容建议**：容量阈值告警、扩容时间点预测
- **优化建议**：性能优化、资源利用率提升

### 运维自动化
- **统一管理平台**：集成监控、备份、诊断、容量分析
- **配置管理**：统一配置文件、参数调优
- **脚本化运维**：自动化日常操作、减少人工干预
- **报告生成**：定期运维报告、状态总结

### 最佳实践
1. **建立完善的监控体系**：覆盖所有关键指标
2. **制定备份策略**：定期备份、异地存储
3. **准备故障预案**：快速响应、最小化影响
4. **持续容量规划**：提前预警、合理扩容
5. **自动化运维**：减少人工错误、提高效率

通过本章的学习和实践，你将掌握Redis运维管理的核心技能，能够建立完善的Redis运维体系，确保Redis服务的稳定运行。