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
                'net_connections': len(redis_proc.net_connections()),
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
                    'command': ' '.join(str(cmd) for cmd in entry['command'])
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