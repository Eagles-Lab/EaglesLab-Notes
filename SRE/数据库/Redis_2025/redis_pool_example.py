import redis
import random
from redis.sentinel import Sentinel

class RedisCluster:
    def __init__(self, master_host, master_port, slave_hosts, password=None):
        # 主节点连接池（写操作）
        self.master_pool = redis.ConnectionPool(
            host=master_host,
            port=master_port,
            password=password,
            max_connections=20,
            retry_on_timeout=True
        )
        
        # 从节点连接池（读操作）
        self.slave_pools = []
        for host, port in slave_hosts:
            pool = redis.ConnectionPool(
                host=host,
                port=port,
                password=password,
                max_connections=10,
                retry_on_timeout=True
            )
            self.slave_pools.append(pool)
    
    def get_master_client(self):
        """获取主节点客户端（写操作）"""
        return redis.Redis(connection_pool=self.master_pool)
    
    def get_slave_client(self):
        """获取从节点客户端（读操作）"""
        if not self.slave_pools:
            return self.get_master_client()
        
        # 随机选择一个从节点
        pool = random.choice(self.slave_pools)
        return redis.Redis(connection_pool=pool)
    
    def set(self, key, value, **kwargs):
        """写操作"""
        client = self.get_master_client()
        return client.set(key, value, **kwargs)
    
    def get(self, key):
        """读操作"""
        client = self.get_slave_client()
        return client.get(key)
    
    def delete(self, *keys):
        """删除操作"""
        client = self.get_master_client()
        return client.delete(*keys)

# 使用示例
if __name__ == "__main__":
    cluster = RedisCluster(
        master_host="192.168.1.100",
        master_port=6379,
        slave_hosts=[("192.168.1.101", 6380), ("192.168.1.102", 6381)],
        password="your_password"
    )
    
    # 写操作（发送到主节点）
    cluster.set("test_key", "test_value")
    
    # 读操作（发送到从节点）
    value = cluster.get("test_key")
    print(f"读取到的值: {value}")