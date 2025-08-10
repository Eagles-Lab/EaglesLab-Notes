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
