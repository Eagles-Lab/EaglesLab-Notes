# Redis 应用实战

## 缓存应用

### 缓存策略

Redis 作为缓存系统，需要合理的缓存策略来保证数据一致性和性能。

**常见缓存模式**：

1. **Cache-Aside（旁路缓存）**：
```python
# Cache-Aside 模式实现
import redis
import json
import mysql.connector

class CacheAside:
    def __init__(self, redis_host='localhost', redis_port=6379, redis_password=None):
        self.redis_client = redis.Redis(host=redis_host, port=redis_port, password=redis_password)
        self.db_config = {
            'host': 'localhost',
            'user': 'root',
            'password': 'password',
            'database': 'testdb'
        }
    
    def get_user(self, user_id):
        """获取用户信息"""
        cache_key = f"user:{user_id}"
        
        # 1. 先从缓存获取
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # 2. 缓存未命中，从数据库获取
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor(dictionary=True)
        cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))
        user_data = cursor.fetchone()
        cursor.close()
        conn.close()
        
        if user_data:
            # 3. 写入缓存
            self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
            return user_data
        
        return None
    
    def update_user(self, user_id, user_data):
        """更新用户信息"""
        # 1. 更新数据库
        conn = mysql.connector.connect(**self.db_config)
        cursor = conn.cursor()
        cursor.execute(
            "UPDATE users SET name=%s, email=%s WHERE id=%s",
            (user_data['name'], user_data['email'], user_id)
        )
        conn.commit()
        cursor.close()
        conn.close()
        
        # 2. 删除缓存
        cache_key = f"user:{user_id}"
        self.redis_client.delete(cache_key)
```

2. **Write-Through（写穿透）**：
```python
class WriteThrough:
    def __init__(self, redis_client, db_connection):
        self.redis_client = redis_client
        self.db_connection = db_connection
    
    def set_user(self, user_id, user_data):
        """写穿透模式"""
        # 1. 同时写入数据库和缓存
        cursor = self.db_connection.cursor()
        cursor.execute(
            "INSERT INTO users (id, name, email) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE name=%s, email=%s",
            (user_id, user_data['name'], user_data['email'], user_data['name'], user_data['email'])
        )
        self.db_connection.commit()
        cursor.close()
        
        # 2. 写入缓存
        cache_key = f"user:{user_id}"
        self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
```

3. **Write-Behind（写回）**：
```python
import threading
import time
from queue import Queue

class WriteBehind:
    def __init__(self, redis_client, db_connection):
        self.redis_client = redis_client
        self.db_connection = db_connection
        self.write_queue = Queue()
        self.start_background_writer()
    
    def set_user(self, user_id, user_data):
        """写回模式"""
        # 1. 立即写入缓存
        cache_key = f"user:{user_id}"
        self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
        
        # 2. 异步写入数据库
        self.write_queue.put((user_id, user_data))
    
    def start_background_writer(self):
        """后台写入线程"""
        def writer():
            while True:
                try:
                    user_id, user_data = self.write_queue.get(timeout=1)
                    cursor = self.db_connection.cursor()
                    cursor.execute(
                        "INSERT INTO users (id, name, email) VALUES (%s, %s, %s) ON DUPLICATE KEY UPDATE name=%s, email=%s",
                        (user_id, user_data['name'], user_data['email'], user_data['name'], user_data['email'])
                    )
                    self.db_connection.commit()
                    cursor.close()
                    self.write_queue.task_done()
                except:
                    time.sleep(0.1)
        
        thread = threading.Thread(target=writer, daemon=True)
        thread.start()
```

### 缓存穿透、击穿、雪崩

**缓存穿透防护**：

```python
class CachePenetrationProtection:
    def __init__(self, redis_client):
        self.redis_client = redis_client
        self.bloom_filter_key = "bloom_filter:users"
    
    def init_bloom_filter(self, user_ids):
        """初始化布隆过滤器"""
        # 使用Redis的位图实现简单布隆过滤器
        for user_id in user_ids:
            for i in range(3):  # 3个哈希函数
                hash_value = hash(f"{user_id}_{i}") % 1000000
                self.redis_client.setbit(self.bloom_filter_key, hash_value, 1)
    
    def might_exist(self, user_id):
        """检查用户是否可能存在"""
        for i in range(3):
            hash_value = hash(f"{user_id}_{i}") % 1000000
            if not self.redis_client.getbit(self.bloom_filter_key, hash_value):
                return False
        return True
    
    def get_user_safe(self, user_id):
        """安全获取用户（防穿透）"""
        # 1. 布隆过滤器检查
        if not self.might_exist(user_id):
            return None
        
        # 2. 缓存检查
        cache_key = f"user:{user_id}"
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            if cached_data == b"NULL":  # 空值缓存
                return None
            return json.loads(cached_data)
        
        # 3. 数据库查询
        user_data = self.query_database(user_id)
        if user_data:
            self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
        else:
            # 缓存空值，防止穿透
            self.redis_client.setex(cache_key, 300, "NULL")
        
        return user_data
```

**缓存击穿防护**：

```python
import threading
import time

class CacheBreakdownProtection:
    def __init__(self, redis_client):
        self.redis_client = redis_client
        self.locks = {}
        self.lock_mutex = threading.Lock()
    
    def get_user_with_mutex(self, user_id):
        """使用互斥锁防止击穿"""
        cache_key = f"user:{user_id}"
        
        # 1. 尝试从缓存获取
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # 2. 获取锁
        with self.lock_mutex:
            if user_id not in self.locks:
                self.locks[user_id] = threading.Lock()
            user_lock = self.locks[user_id]
        
        # 3. 使用锁保护数据库查询
        with user_lock:
            # 再次检查缓存（双重检查）
            cached_data = self.redis_client.get(cache_key)
            if cached_data:
                return json.loads(cached_data)
            
            # 查询数据库
            user_data = self.query_database(user_id)
            if user_data:
                self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
            
            return user_data
    
    def get_user_with_redis_lock(self, user_id):
        """使用Redis分布式锁防止击穿"""
        cache_key = f"user:{user_id}"
        lock_key = f"lock:user:{user_id}"
        
        # 1. 尝试从缓存获取
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # 2. 尝试获取分布式锁
        lock_acquired = self.redis_client.set(lock_key, "locked", nx=True, ex=10)
        
        if lock_acquired:
            try:
                # 再次检查缓存
                cached_data = self.redis_client.get(cache_key)
                if cached_data:
                    return json.loads(cached_data)
                
                # 查询数据库
                user_data = self.query_database(user_id)
                if user_data:
                    self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
                
                return user_data
            finally:
                # 释放锁
                self.redis_client.delete(lock_key)
        else:
            # 等待锁释放后重试
            time.sleep(0.1)
            return self.get_user_with_redis_lock(user_id)
```

**缓存雪崩防护**：

```python
import random

class CacheAvalancheProtection:
    def __init__(self, redis_client):
        self.redis_client = redis_client
    
    def set_with_random_ttl(self, key, value, base_ttl=3600):
        """设置随机过期时间防止雪崩"""
        # 在基础TTL上增加随机时间（±20%）
        random_offset = random.randint(-int(base_ttl * 0.2), int(base_ttl * 0.2))
        actual_ttl = base_ttl + random_offset
        self.redis_client.setex(key, actual_ttl, value)
    
    def get_with_refresh(self, key, refresh_func, ttl=3600):
        """提前刷新缓存"""
        data = self.redis_client.get(key)
        if data:
            # 检查是否需要提前刷新（剩余时间少于20%）
            remaining_ttl = self.redis_client.ttl(key)
            if remaining_ttl < ttl * 0.2:
                # 异步刷新缓存
                threading.Thread(target=self._refresh_cache, args=(key, refresh_func, ttl)).start()
            return json.loads(data)
        else:
            # 缓存未命中，同步刷新
            new_data = refresh_func()
            if new_data:
                self.set_with_random_ttl(key, json.dumps(new_data, default=str), ttl)
            return new_data
    
    def _refresh_cache(self, key, refresh_func, ttl):
        """后台刷新缓存"""
        try:
            new_data = refresh_func()
            if new_data:
                self.set_with_random_ttl(key, json.dumps(new_data, default=str), ttl)
        except Exception as e:
            print(f"缓存刷新失败: {e}")
```

### 缓存更新策略

**缓存更新模式**：

```python
class CacheUpdateStrategy:
    def __init__(self, redis_client, db_connection):
        self.redis_client = redis_client
        self.db_connection = db_connection
    
    def lazy_loading(self, user_id):
        """懒加载模式"""
        cache_key = f"user:{user_id}"
        
        # 检查缓存
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # 从数据库加载
        user_data = self.query_database(user_id)
        if user_data:
            self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
        
        return user_data
    
    def write_around(self, user_id, user_data):
        """写绕过模式"""
        # 只写数据库，不写缓存
        cursor = self.db_connection.cursor()
        cursor.execute(
            "UPDATE users SET name=%s, email=%s WHERE id=%s",
            (user_data['name'], user_data['email'], user_id)
        )
        self.db_connection.commit()
        cursor.close()
        
        # 删除缓存，下次读取时重新加载
        cache_key = f"user:{user_id}"
        self.redis_client.delete(cache_key)
    
    def refresh_ahead(self, user_id):
        """提前刷新模式"""
        cache_key = f"user:{user_id}"
        
        # 检查缓存剩余时间
        ttl = self.redis_client.ttl(cache_key)
        if ttl > 0 and ttl < 600:  # 剩余时间少于10分钟
            # 异步刷新
            threading.Thread(target=self._async_refresh, args=(user_id,)).start()
        
        # 返回当前缓存数据
        cached_data = self.redis_client.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        return self.lazy_loading(user_id)
    
    def _async_refresh(self, user_id):
        """异步刷新缓存"""
        user_data = self.query_database(user_id)
        if user_data:
            cache_key = f"user:{user_id}"
            self.redis_client.setex(cache_key, 3600, json.dumps(user_data, default=str))
```

### 分布式缓存

**一致性哈希实现**：

```python
import hashlib
import bisect

class ConsistentHash:
    def __init__(self, nodes=None, replicas=3):
        self.replicas = replicas
        self.ring = {}
        self.sorted_keys = []
        
        if nodes:
            for node in nodes:
                self.add_node(node)
    
    def add_node(self, node):
        """添加节点"""
        for i in range(self.replicas):
            key = self.hash(f"{node}:{i}")
            self.ring[key] = node
            bisect.insort(self.sorted_keys, key)
    
    def remove_node(self, node):
        """移除节点"""
        for i in range(self.replicas):
            key = self.hash(f"{node}:{i}")
            del self.ring[key]
            self.sorted_keys.remove(key)
    
    def get_node(self, key):
        """获取键对应的节点"""
        if not self.ring:
            return None
        
        hash_key = self.hash(key)
        idx = bisect.bisect_right(self.sorted_keys, hash_key)
        
        if idx == len(self.sorted_keys):
            idx = 0
        
        return self.ring[self.sorted_keys[idx]]
    
    def hash(self, key):
        """哈希函数"""
        return int(hashlib.md5(key.encode()).hexdigest(), 16)

class DistributedCache:
    def __init__(self, redis_nodes):
        self.redis_clients = {}
        for node in redis_nodes:
            host, port = node.split(':')
            self.redis_clients[node] = redis.Redis(host=host, port=int(port))
        
        self.consistent_hash = ConsistentHash(redis_nodes)
    
    def get(self, key):
        """分布式获取"""
        node = self.consistent_hash.get_node(key)
        if node:
            return self.redis_clients[node].get(key)
        return None
    
    def set(self, key, value, ex=None):
        """分布式设置"""
        node = self.consistent_hash.get_node(key)
        if node:
            return self.redis_clients[node].set(key, value, ex=ex)
        return False
    
    def delete(self, key):
        """分布式删除"""
        node = self.consistent_hash.get_node(key)
        if node:
            return self.redis_clients[node].delete(key)
        return False
```

## 会话管理

### 会话存储

**基于Redis的会话管理**：

```python
import uuid
import json
import time
from datetime import datetime, timedelta

class RedisSessionManager:
    def __init__(self, redis_client, session_timeout=1800):
        self.redis_client = redis_client
        self.session_timeout = session_timeout
        self.session_prefix = "session:"
    
    def create_session(self, user_id, user_data=None):
        """创建会话"""
        session_id = str(uuid.uuid4())
        session_key = f"{self.session_prefix}{session_id}"
        
        session_data = {
            'user_id': user_id,
            'created_at': datetime.now().isoformat(),
            'last_accessed': datetime.now().isoformat(),
            'user_data': user_data or {}
        }
        
        # 存储会话数据
        self.redis_client.setex(
            session_key,
            self.session_timeout,
            json.dumps(session_data, default=str)
        )
        
        # 维护用户会话索引
        user_sessions_key = f"user_sessions:{user_id}"
        self.redis_client.sadd(user_sessions_key, session_id)
        self.redis_client.expire(user_sessions_key, self.session_timeout)
        
        return session_id
    
    def get_session(self, session_id):
        """获取会话"""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis_client.get(session_key)
        
        if session_data:
            data = json.loads(session_data)
            # 更新最后访问时间
            data['last_accessed'] = datetime.now().isoformat()
            self.redis_client.setex(
                session_key,
                self.session_timeout,
                json.dumps(data, default=str)
            )
            return data
        
        return None
    
    def update_session(self, session_id, user_data):
        """更新会话数据"""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis_client.get(session_key)
        
        if session_data:
            data = json.loads(session_data)
            data['user_data'].update(user_data)
            data['last_accessed'] = datetime.now().isoformat()
            
            self.redis_client.setex(
                session_key,
                self.session_timeout,
                json.dumps(data, default=str)
            )
            return True
        
        return False
    
    def destroy_session(self, session_id):
        """销毁会话"""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis_client.get(session_key)
        
        if session_data:
            data = json.loads(session_data)
            user_id = data['user_id']
            
            # 删除会话
            self.redis_client.delete(session_key)
            
            # 从用户会话索引中移除
            user_sessions_key = f"user_sessions:{user_id}"
            self.redis_client.srem(user_sessions_key, session_id)
            
            return True
        
        return False
    
    def get_user_sessions(self, user_id):
        """获取用户所有会话"""
        user_sessions_key = f"user_sessions:{user_id}"
        session_ids = self.redis_client.smembers(user_sessions_key)
        
        sessions = []
        for session_id in session_ids:
            session_data = self.get_session(session_id.decode())
            if session_data:
                sessions.append({
                    'session_id': session_id.decode(),
                    'created_at': session_data['created_at'],
                    'last_accessed': session_data['last_accessed']
                })
        
        return sessions
    
    def destroy_user_sessions(self, user_id):
        """销毁用户所有会话"""
        user_sessions_key = f"user_sessions:{user_id}"
        session_ids = self.redis_client.smembers(user_sessions_key)
        
        for session_id in session_ids:
            session_key = f"{self.session_prefix}{session_id.decode()}"
            self.redis_client.delete(session_key)
        
        self.redis_client.delete(user_sessions_key)
```

### 分布式会话

**跨应用会话共享**：

```python
class DistributedSessionManager:
    def __init__(self, redis_client, app_name, session_timeout=1800):
        self.redis_client = redis_client
        self.app_name = app_name
        self.session_timeout = session_timeout
        self.session_prefix = f"session:{app_name}:"
        self.global_session_prefix = "global_session:"
    
    def create_global_session(self, user_id, user_data=None):
        """创建全局会话"""
        global_session_id = str(uuid.uuid4())
        global_session_key = f"{self.global_session_prefix}{global_session_id}"
        
        global_session_data = {
            'user_id': user_id,
            'created_at': datetime.now().isoformat(),
            'last_accessed': datetime.now().isoformat(),
            'user_data': user_data or {},
            'app_sessions': {}  # 各应用的会话ID
        }
        
        # 存储全局会话
        self.redis_client.setex(
            global_session_key,
            self.session_timeout,
            json.dumps(global_session_data, default=str)
        )
        
        return global_session_id
    
    def create_app_session(self, global_session_id, app_data=None):
        """为应用创建会话"""
        app_session_id = str(uuid.uuid4())
        app_session_key = f"{self.session_prefix}{app_session_id}"
        
        # 获取全局会话
        global_session_key = f"{self.global_session_prefix}{global_session_id}"
        global_session_data = self.redis_client.get(global_session_key)
        
        if not global_session_data:
            return None
        
        global_data = json.loads(global_session_data)
        
        app_session_data = {
            'global_session_id': global_session_id,
            'user_id': global_data['user_id'],
            'app_name': self.app_name,
            'created_at': datetime.now().isoformat(),
            'last_accessed': datetime.now().isoformat(),
            'app_data': app_data or {}
        }
        
        # 存储应用会话
        self.redis_client.setex(
            app_session_key,
            self.session_timeout,
            json.dumps(app_session_data, default=str)
        )
        
        # 更新全局会话中的应用会话映射
        global_data['app_sessions'][self.app_name] = app_session_id
        global_data['last_accessed'] = datetime.now().isoformat()
        
        self.redis_client.setex(
            global_session_key,
            self.session_timeout,
            json.dumps(global_data, default=str)
        )
        
        return app_session_id
    
    def get_session_with_sso(self, app_session_id):
        """获取会话（支持SSO）"""
        app_session_key = f"{self.session_prefix}{app_session_id}"
        app_session_data = self.redis_client.get(app_session_key)
        
        if not app_session_data:
            return None
        
        app_data = json.loads(app_session_data)
        global_session_id = app_data['global_session_id']
        
        # 获取全局会话数据
        global_session_key = f"{self.global_session_prefix}{global_session_id}"
        global_session_data = self.redis_client.get(global_session_key)
        
        if global_session_data:
            global_data = json.loads(global_session_data)
            
            # 合并会话数据
            combined_data = {
                'app_session_id': app_session_id,
                'global_session_id': global_session_id,
                'user_id': app_data['user_id'],
                'user_data': global_data['user_data'],
                'app_data': app_data['app_data'],
                'last_accessed': app_data['last_accessed']
            }
            
            # 更新访问时间
            app_data['last_accessed'] = datetime.now().isoformat()
            global_data['last_accessed'] = datetime.now().isoformat()
            
            self.redis_client.setex(
                app_session_key,
                self.session_timeout,
                json.dumps(app_data, default=str)
            )
            
            self.redis_client.setex(
                global_session_key,
                self.session_timeout,
                json.dumps(global_data, default=str)
            )
            
            return combined_data
        
        return None
```

### 会话过期处理

**会话清理和通知**：

```python
import threading
import time

class SessionCleanupManager:
    def __init__(self, redis_client, cleanup_interval=300):
        self.redis_client = redis_client
        self.cleanup_interval = cleanup_interval
        self.running = False
        self.cleanup_thread = None
        self.session_listeners = []
    
    def add_session_listener(self, listener):
        """添加会话事件监听器"""
        self.session_listeners.append(listener)
    
    def start_cleanup(self):
        """启动清理线程"""
        if not self.running:
            self.running = True
            self.cleanup_thread = threading.Thread(target=self._cleanup_loop, daemon=True)
            self.cleanup_thread.start()
    
    def stop_cleanup(self):
        """停止清理线程"""
        self.running = False
        if self.cleanup_thread:
            self.cleanup_thread.join()
    
    def _cleanup_loop(self):
        """清理循环"""
        while self.running:
            try:
                self._cleanup_expired_sessions()
                time.sleep(self.cleanup_interval)
            except Exception as e:
                print(f"会话清理错误: {e}")
                time.sleep(60)  # 出错时等待1分钟
    
    def _cleanup_expired_sessions(self):
        """清理过期会话"""
        # 扫描所有会话键
        session_keys = self.redis_client.keys("session:*")
        
        for key in session_keys:
            try:
                # 检查键是否仍然存在（可能已过期）
                if not self.redis_client.exists(key):
                    # 会话已过期，通知监听器
                    session_id = key.decode().split(':')[-1]
                    self._notify_session_expired(session_id)
            except Exception as e:
                print(f"检查会话 {key} 时出错: {e}")
    
    def _notify_session_expired(self, session_id):
        """通知会话过期"""
        for listener in self.session_listeners:
            try:
                listener.on_session_expired(session_id)
            except Exception as e:
                print(f"通知会话过期监听器时出错: {e}")

class SessionExpiredListener:
    def __init__(self, redis_client):
        self.redis_client = redis_client
    
    def on_session_expired(self, session_id):
        """会话过期处理"""
        print(f"会话 {session_id} 已过期")
        
        # 清理相关数据
        self._cleanup_session_data(session_id)
        
        # 记录日志
        self._log_session_expiry(session_id)
    
    def _cleanup_session_data(self, session_id):
        """清理会话相关数据"""
        # 清理用户会话索引
        user_sessions_pattern = "user_sessions:*"
        for key in self.redis_client.keys(user_sessions_pattern):
            self.redis_client.srem(key, session_id)
    
    def _log_session_expiry(self, session_id):
        """记录会话过期日志"""
        log_entry = {
            'event': 'session_expired',
            'session_id': session_id,
            'timestamp': datetime.now().isoformat()
        }
        
        # 存储到日志队列
        self.redis_client.lpush('session_logs', json.dumps(log_entry))
        self.redis_client.ltrim('session_logs', 0, 9999)  # 保留最近10000条日志
```

### 安全考虑

**会话安全增强**：

```python
import hashlib
import hmac
import secrets

class SecureSessionManager:
    def __init__(self, redis_client, secret_key, session_timeout=1800):
        self.redis_client = redis_client
        self.secret_key = secret_key
        self.session_timeout = session_timeout
        self.session_prefix = "secure_session:"
    
    def create_secure_session(self, user_id, client_ip, user_agent):
        """创建安全会话"""
        session_id = secrets.token_urlsafe(32)
        session_key = f"{self.session_prefix}{session_id}"
        
        # 生成会话指纹
        fingerprint = self._generate_fingerprint(client_ip, user_agent)
        
        session_data = {
            'user_id': user_id,
            'created_at': datetime.now().isoformat(),
            'last_accessed': datetime.now().isoformat(),
            'client_ip': client_ip,
            'user_agent': user_agent,
            'fingerprint': fingerprint,
            'csrf_token': secrets.token_urlsafe(32)
        }
        
        # 生成会话签名
        signature = self._sign_session_data(session_data)
        session_data['signature'] = signature
        
        # 存储会话
        self.redis_client.setex(
            session_key,
            self.session_timeout,
            json.dumps(session_data, default=str)
        )
        
        return session_id, session_data['csrf_token']
    
    def validate_session(self, session_id, client_ip, user_agent, csrf_token=None):
        """验证会话安全性"""
        session_key = f"{self.session_prefix}{session_id}"
        session_data = self.redis_client.get(session_key)
        
        if not session_data:
            return None, "会话不存在"
        
        data = json.loads(session_data)
        
        # 验证签名
        stored_signature = data.pop('signature')
        calculated_signature = self._sign_session_data(data)
        
        if not hmac.compare_digest(stored_signature, calculated_signature):
            return None, "会话签名无效"
        
        # 验证客户端指纹
        current_fingerprint = self._generate_fingerprint(client_ip, user_agent)
        if data['fingerprint'] != current_fingerprint:
            return None, "客户端指纹不匹配"
        
        # 验证CSRF令牌（如果提供）
        if csrf_token and data['csrf_token'] != csrf_token:
            return None, "CSRF令牌无效"
        
        # 检查IP变化（可选的安全策略）
        if data['client_ip'] != client_ip:
            # 记录可疑活动
            self._log_suspicious_activity(session_id, data['client_ip'], client_ip)
            # 可以选择是否允许继续
        
        # 更新最后访问时间
        data['last_accessed'] = datetime.now().isoformat()
        data['signature'] = self._sign_session_data(data)
        
        self.redis_client.setex(
            session_key,
            self.session_timeout,
            json.dumps(data, default=str)
        )
        
        return data, None
    
    def _generate_fingerprint(self, client_ip, user_agent):
        """生成客户端指纹"""
        fingerprint_data = f"{client_ip}:{user_agent}"
        return hashlib.sha256(fingerprint_data.encode()).hexdigest()
    
    def _sign_session_data(self, session_data):
        """签名会话数据"""
        # 创建数据的规范化字符串
        data_string = json.dumps(session_data, sort_keys=True, default=str)
        signature = hmac.new(
            self.secret_key.encode(),
            data_string.encode(),
            hashlib.sha256
        ).hexdigest()
        return signature
    
    def _log_suspicious_activity(self, session_id, old_ip, new_ip):
        """记录可疑活动"""
        log_entry = {
            'event': 'ip_change',
            'session_id': session_id,
            'old_ip': old_ip,
            'new_ip': new_ip,
            'timestamp': datetime.now().isoformat()
        }
        
        self.redis_client.lpush('security_logs', json.dumps(log_entry))
        self.redis_client.ltrim('security_logs', 0, 9999)
```

## 消息队列

### 发布订阅模式

**基本发布订阅实现**：

```python
import threading
import json
import time

class RedisPubSub:
    def __init__(self, redis_client):
        self.redis_client = redis_client
        self.subscribers = {}
        self.running = False
    
    def publish(self, channel, message):
        """发布消息"""
        if isinstance(message, dict):
            message = json.dumps(message)
        
        return self.redis_client.publish(channel, message)
    
    def subscribe(self, channel, callback):
        """订阅频道"""
        if channel not in self.subscribers:
            self.subscribers[channel] = []
        
        self.subscribers[channel].append(callback)
        
        # 启动订阅线程
        if not self.running:
            self.start_listening()
    
    def unsubscribe(self, channel, callback=None):
        """取消订阅"""
        if channel in self.subscribers:
            if callback:
                self.subscribers[channel].remove(callback)
            else:
                del self.subscribers[channel]
    
    def start_listening(self):
        """开始监听消息"""
        self.running = True
        
        def listen():
            pubsub = self.redis_client.pubsub()
            
            # 订阅所有频道
            for channel in self.subscribers.keys():
                pubsub.subscribe(channel)
            
            try:
                for message in pubsub.listen():
                    if message['type'] == 'message':
                        channel = message['channel'].decode()
                        data = message['data'].decode()
                        
                        # 尝试解析JSON
                        try:
                            data = json.loads(data)
                        except:
                            pass
                        
                        # 调用回调函数
                        if channel in self.subscribers:
                            for callback in self.subscribers[channel]:
                                try:
                                    callback(channel, data)
                                except Exception as e:
                                    print(f"回调函数执行错误: {e}")
            except Exception as e:
                print(f"监听错误: {e}")
            finally:
                pubsub.close()
        
        thread = threading.Thread(target=listen, daemon=True)
        thread.start()
    
    def stop_listening(self):
        """停止监听"""
        self.running = False

# 使用示例
def message_handler(channel, message):
    print(f"收到消息 - 频道: {channel}, 内容: {message}")

# 创建发布订阅实例
pubsub = RedisPubSub(redis_client)

# 订阅频道
pubsub.subscribe('notifications', message_handler)
pubsub.subscribe('alerts', message_handler)

# 发布消息
pubsub.publish('notifications', {'type': 'info', 'message': '系统维护通知'})
pubsub.publish('alerts', {'type': 'warning', 'message': 'CPU使用率过高'})
```

### 消息队列实现

**可靠消息队列**：

```python
import uuid
import time
from enum import Enum

class MessageStatus(Enum):
    PENDING = "pending"
    PROCESSING = "processing"
    COMPLETED = "completed"
    FAILED = "failed"
    RETRY = "retry"

class ReliableMessageQueue:
    def __init__(self, redis_client, queue_name, max_retries=3, visibility_timeout=30):
        self.redis_client = redis_client
        self.queue_name = queue_name
        self.max_retries = max_retries
        self.visibility_timeout = visibility_timeout
        
        # 队列键名
        self.pending_queue = f"queue:{queue_name}:pending"
        self.processing_queue = f"queue:{queue_name}:processing"
        self.failed_queue = f"queue:{queue_name}:failed"
        self.message_data = f"queue:{queue_name}:messages"
    
    def send_message(self, message, delay=0, priority=0):
        """发送消息"""
        message_id = str(uuid.uuid4())
        
        message_info = {
            'id': message_id,
            'body': message,
            'created_at': time.time(),
            'retry_count': 0,
            'max_retries': self.max_retries,
            'priority': priority,
            'status': MessageStatus.PENDING.value
        }
        
        # 存储消息数据
        self.redis_client.hset(
            self.message_data,
            message_id,
            json.dumps(message_info, default=str)
        )
        
        if delay > 0:
            # 延时消息
            deliver_time = time.time() + delay
            self.redis_client.zadd(
                f"queue:{self.queue_name}:delayed",
                {message_id: deliver_time}
            )
        else:
            # 立即投递
            self.redis_client.zadd(
                self.pending_queue,
                {message_id: priority}
            )
        
        return message_id
    
    def receive_message(self, timeout=10):
        """接收消息"""
        # 处理延时消息
        self._process_delayed_messages()
        
        # 从待处理队列获取消息
        result = self.redis_client.bzpopmax(self.pending_queue, timeout=timeout)
        
        if result:
            queue_name, message_id, priority = result
            message_id = message_id.decode()
            
            # 获取消息详情
            message_data = self.redis_client.hget(self.message_data, message_id)
            if message_data:
                message_info = json.loads(message_data)
                
                # 移动到处理队列
                processing_time = time.time() + self.visibility_timeout
                self.redis_client.zadd(
                    self.processing_queue,
                    {message_id: processing_time}
                )
                
                # 更新状态
                message_info['status'] = MessageStatus.PROCESSING.value
                message_info['processing_started'] = time.time()
                
                self.redis_client.hset(
                    self.message_data,
                    message_id,
                    json.dumps(message_info, default=str)
                )
                
                return {
                    'id': message_id,
                    'body': message_info['body'],
                    'retry_count': message_info['retry_count']
                }
        
        return None
    
    def complete_message(self, message_id):
        """完成消息处理"""
        # 从处理队列移除
        self.redis_client.zrem(self.processing_queue, message_id)
        
        # 更新消息状态
        message_data = self.redis_client.hget(self.message_data, message_id)
        if message_data:
            message_info = json.loads(message_data)
            message_info['status'] = MessageStatus.COMPLETED.value
            message_info['completed_at'] = time.time()
            
            self.redis_client.hset(
                self.message_data,
                message_id,
                json.dumps(message_info, default=str)
            )
        
        return True
    
    def fail_message(self, message_id, error_message=None):
        """消息处理失败"""
        # 从处理队列移除
        self.redis_client.zrem(self.processing_queue, message_id)
        
        # 获取消息信息
        message_data = self.redis_client.hget(self.message_data, message_id)
        if not message_data:
            return False
        
        message_info = json.loads(message_data)
        message_info['retry_count'] += 1
        
        if error_message:
            if 'errors' not in message_info:
                message_info['errors'] = []
            message_info['errors'].append({
                'error': error_message,
                'timestamp': time.time()
            })
        
        if message_info['retry_count'] <= message_info['max_retries']:
            # 重试
            message_info['status'] = MessageStatus.RETRY.value
            
            # 计算退避延时
            delay = min(300, 2 ** message_info['retry_count'])  # 指数退避，最大5分钟
            retry_time = time.time() + delay
            
            self.redis_client.zadd(
                f"queue:{self.queue_name}:delayed",
                {message_id: retry_time}
            )
        else:
            # 超过重试次数，移到失败队列
            message_info['status'] = MessageStatus.FAILED.value
            self.redis_client.zadd(
                self.failed_queue,
                {message_id: time.time()}
            )
        
        # 更新消息数据
        self.redis_client.hset(
            self.message_data,
            message_id,
            json.dumps(message_info, default=str)
        )
        
        return True
    
    def _process_delayed_messages(self):
        """处理延时消息"""
        current_time = time.time()
        delayed_queue = f"queue:{self.queue_name}:delayed"
        
        # 获取到期的延时消息
        messages = self.redis_client.zrangebyscore(
            delayed_queue, 0, current_time, withscores=True
        )
        
        for message_id, score in messages:
            message_id = message_id.decode()
            
            # 移动到待处理队列
            message_data = self.redis_client.hget(self.message_data, message_id)
            if message_data:
                message_info = json.loads(message_data)
                priority = message_info.get('priority', 0)
                
                self.redis_client.zadd(self.pending_queue, {message_id: priority})
                self.redis_client.zrem(delayed_queue, message_id)
                
                # 更新状态
                message_info['status'] = MessageStatus.PENDING.value
                self.redis_client.hset(
                    self.message_data,
                    message_id,
                    json.dumps(message_info, default=str)
                )
    
    def cleanup_expired_messages(self):
        """清理超时的处理中消息"""
        current_time = time.time()
        
        # 获取超时的处理中消息
        expired_messages = self.redis_client.zrangebyscore(
            self.processing_queue, 0, current_time
        )
        
        for message_id in expired_messages:
            message_id = message_id.decode()
            print(f"消息 {message_id} 处理超时，重新入队")
            self.fail_message(message_id, "处理超时")
    
    def get_queue_stats(self):
        """获取队列统计信息"""
        stats = {
            'pending': self.redis_client.zcard(self.pending_queue),
            'processing': self.redis_client.zcard(self.processing_queue),
            'failed': self.redis_client.zcard(self.failed_queue),
            'delayed': self.redis_client.zcard(f"queue:{self.queue_name}:delayed"),
            'total_messages': self.redis_client.hlen(self.message_data)
        }
        return stats
```

### 延时队列

**延时任务调度器**：

```python
import threading
import time
from datetime import datetime, timedelta

class DelayedTaskScheduler:
    def __init__(self, redis_client):
        self.redis_client = redis_client
        self.running = False
        self.scheduler_thread = None
        self.task_handlers = {}
    
    def register_handler(self, task_type, handler):
        """注册任务处理器"""
        self.task_handlers[task_type] = handler
    
    def schedule_task(self, task_type, task_data, delay_seconds=0, execute_at=None):
        """调度延时任务"""
        task_id = str(uuid.uuid4())
        
        if execute_at:
            execute_time = execute_at.timestamp()
        else:
            execute_time = time.time() + delay_seconds
        
        task_info = {
            'id': task_id,
            'type': task_type,
            'data': task_data,
            'created_at': time.time(),
            'execute_at': execute_time,
            'status': 'scheduled'
        }
        
        # 存储任务信息
        self.redis_client.hset(
            'delayed_tasks:data',
            task_id,
            json.dumps(task_info, default=str)
        )
        
        # 添加到调度队列
        self.redis_client.zadd(
            'delayed_tasks:schedule',
            {task_id: execute_time}
        )
        
        return task_id
    
    def cancel_task(self, task_id):
        """取消任务"""
        # 从调度队列移除
        self.redis_client.zrem('delayed_tasks:schedule', task_id)
        
        # 更新任务状态
        task_data = self.redis_client.hget('delayed_tasks:data', task_id)
        if task_data:
            task_info = json.loads(task_data)
            task_info['status'] = 'cancelled'
            task_info['cancelled_at'] = time.time()
            
            self.redis_client.hset(
                'delayed_tasks:data',
                task_id,
                json.dumps(task_info, default=str)
            )
            return True
        
        return False
    
    def start_scheduler(self):
        """启动调度器"""
        if not self.running:
            self.running = True
            self.scheduler_thread = threading.Thread(target=self._scheduler_loop, daemon=True)
            self.scheduler_thread.start()
    
    def stop_scheduler(self):
        """停止调度器"""
        self.running = False
        if self.scheduler_thread:
            self.scheduler_thread.join()
    
    def _scheduler_loop(self):
        """调度循环"""
        while self.running:
            try:
                current_time = time.time()
                
                # 获取到期的任务
                ready_tasks = self.redis_client.zrangebyscore(
                    'delayed_tasks:schedule',
                    0, current_time,
                    withscores=True
                )
                
                for task_id, execute_time in ready_tasks:
                    task_id = task_id.decode()
                    
                    # 获取任务详情
                    task_data = self.redis_client.hget('delayed_tasks:data', task_id)
                    if task_data:
                        task_info = json.loads(task_data)
                        
                        # 执行任务
                        self._execute_task(task_info)
                        
                        # 从调度队列移除
                        self.redis_client.zrem('delayed_tasks:schedule', task_id)
                
                time.sleep(1)  # 每秒检查一次
                
            except Exception as e:
                print(f"调度器错误: {e}")
                time.sleep(5)
    
    def _execute_task(self, task_info):
        """执行任务"""
        task_type = task_info['type']
        task_id = task_info['id']
        
        try:
            # 更新任务状态
            task_info['status'] = 'executing'
            task_info['started_at'] = time.time()
            
            self.redis_client.hset(
                'delayed_tasks:data',
                task_id,
                json.dumps(task_info, default=str)
            )
            
            # 执行任务处理器
            if task_type in self.task_handlers:
                handler = self.task_handlers[task_type]
                result = handler(task_info['data'])
                
                # 更新完成状态
                task_info['status'] = 'completed'
                task_info['completed_at'] = time.time()
                task_info['result'] = result
            else:
                raise Exception(f"未找到任务类型 {task_type} 的处理器")
                
        except Exception as e:
            # 更新失败状态
            task_info['status'] = 'failed'
            task_info['failed_at'] = time.time()
            task_info['error'] = str(e)
            
            print(f"任务 {task_id} 执行失败: {e}")
        
        finally:
            # 保存最终状态
            self.redis_client.hset(
                'delayed_tasks:data',
                task_id,
                json.dumps(task_info, default=str)
            )

# 使用示例
def send_email_handler(task_data):
    """发送邮件任务处理器"""
    print(f"发送邮件到: {task_data['email']}")
    print(f"主题: {task_data['subject']}")
    print(f"内容: {task_data['content']}")
    return "邮件发送成功"

def cleanup_temp_files_handler(task_data):
    """清理临时文件任务处理器"""
    print(f"清理目录: {task_data['directory']}")
    # 实际的清理逻辑
    return "清理完成"

# 创建调度器
scheduler = DelayedTaskScheduler(redis_client)

# 注册处理器
scheduler.register_handler('send_email', send_email_handler)
scheduler.register_handler('cleanup_temp_files', cleanup_temp_files_handler)

# 启动调度器
scheduler.start_scheduler()

# 调度任务
email_task_id = scheduler.schedule_task(
    'send_email',
    {
        'email': 'user@example.com',
        'subject': '欢迎注册',
        'content': '感谢您的注册！'
    },
    delay_seconds=300  # 5分钟后发送
)

cleanup_task_id = scheduler.schedule_task(
    'cleanup_temp_files',
    {'directory': '/tmp/uploads'},
    execute_at=datetime.now() + timedelta(hours=24)  # 24小时后清理
)
```

### 可靠性保证

**消息确认和重试机制**：

```python
class ReliableMessageProcessor:
    def __init__(self, redis_client, queue_name):
        self.redis_client = redis_client
        self.queue = ReliableMessageQueue(redis_client, queue_name)
        self.running = False
        self.worker_threads = []
        self.message_handlers = {}
    
    def register_handler(self, message_type, handler):
        """注册消息处理器"""
        self.message_handlers[message_type] = handler
    
    def start_workers(self, num_workers=3):
        """启动工作线程"""
        if not self.running:
            self.running = True
            
            for i in range(num_workers):
                worker = threading.Thread(target=self._worker_loop, args=(i,), daemon=True)
                worker.start()
                self.worker_threads.append(worker)
    
    def stop_workers(self):
        """停止工作线程"""
        self.running = False
        for worker in self.worker_threads:
            worker.join()
        self.worker_threads = []
    
    def _worker_loop(self, worker_id):
        """工作线程循环"""
        print(f"工作线程 {worker_id} 启动")
        
        while self.running:
            try:
                # 接收消息
                message = self.queue.receive_message(timeout=5)
                
                if message:
                    self._process_message(message, worker_id)
                
            except Exception as e:
                print(f"工作线程 {worker_id} 错误: {e}")
                time.sleep(1)
        
        print(f"工作线程 {worker_id} 停止")
    
    def _process_message(self, message, worker_id):
        """处理消息"""
        message_id = message['id']
        message_body = message['body']
        
        try:
            # 解析消息类型
            if isinstance(message_body, dict) and 'type' in message_body:
                message_type = message_body['type']
                
                if message_type in self.message_handlers:
                    handler = self.message_handlers[message_type]
                    
                    print(f"工作线程 {worker_id} 处理消息 {message_id}")
                    
                    # 执行处理器
                    result = handler(message_body)
                    
                    # 标记完成
                    self.queue.complete_message(message_id)
                    
                    print(f"消息 {message_id} 处理完成: {result}")
                else:
                    raise Exception(f"未找到消息类型 {message_type} 的处理器")
            else:
                raise Exception("消息格式无效")
                
        except Exception as e:
            print(f"消息 {message_id} 处理失败: {e}")
            self.queue.fail_message(message_id, str(e))

# 使用示例
def order_handler(message_data):
    """订单处理器"""
    order_id = message_data['order_id']
    print(f"处理订单: {order_id}")
    
    # 模拟订单处理
    time.sleep(2)
    
    return f"订单 {order_id} 处理完成"

def notification_handler(message_data):
    """通知处理器"""
    user_id = message_data['user_id']
    content = message_data['content']
    
    print(f"发送通知给用户 {user_id}: {content}")
    
    return "通知发送成功"

# 创建消息处理器
processor = ReliableMessageProcessor(redis_client, 'main_queue')

# 注册处理器
processor.register_handler('order', order_handler)
processor.register_handler('notification', notification_handler)

# 启动工作线程
processor.start_workers(num_workers=5)

# 发送消息
queue = ReliableMessageQueue(redis_client, 'main_queue')

# 发送订单消息
queue.send_message({
    'type': 'order',
    'order_id': 'ORD-12345',
    'user_id': 'user123',
    'amount': 99.99
})

# 发送通知消息
queue.send_message({
    'type': 'notification',
    'user_id': 'user123',
    'content': '您的订单已确认'
})
```

## 分布式锁

### 基本分布式锁

**简单分布式锁实现**：

```python
import time
import threading
import uuid

class RedisDistributedLock:
    def __init__(self, redis_client, lock_name, timeout=10, retry_delay=0.1):
        self.redis_client = redis_client
        self.lock_name = f"lock:{lock_name}"
        self.timeout = timeout
        self.retry_delay = retry_delay
        self.lock_value = None
    
    def acquire(self, blocking=True, timeout=None):
        """获取锁"""
        self.lock_value = str(uuid.uuid4())
        
        if timeout is None:
            timeout = self.timeout
        
        end_time = time.time() + timeout
        
        while True:
            # 尝试获取锁
            if self.redis_client.set(self.lock_name, self.lock_value, nx=True, ex=self.timeout):
                return True
            
            if not blocking:
                return False
            
            if time.time() >= end_time:
                return False
            
            time.sleep(self.retry_delay)
    
    def release(self):
        """释放锁"""
        if self.lock_value is None:
            return False
        
        # 使用Lua脚本确保原子性
        lua_script = """
        if redis.call('get', KEYS[1]) == ARGV[1] then
            return redis.call('del', KEYS[1])
        else
            return 0
        end
        """
        
        result = self.redis_client.eval(lua_script, 1, self.lock_name, self.lock_value)
        self.lock_value = None
        return result == 1
    
    def extend(self, additional_time):
        """延长锁的过期时间"""
        if self.lock_value is None:
            return False
        
        lua_script = """
        if redis.call('get', KEYS[1]) == ARGV[1] then
            return redis.call('expire', KEYS[1], ARGV[2])
        else
            return 0
        end
        """
        
        result = self.redis_client.eval(
            lua_script, 1, 
            self.lock_name, self.lock_value, 
            self.timeout + additional_time
        )
        return result == 1
    
    def __enter__(self):
        """上下文管理器入口"""
        if self.acquire():
            return self
        else:
            raise Exception("无法获取锁")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        """上下文管理器出口"""
        self.release()

# 使用示例
def critical_section():
    """临界区代码"""
    with RedisDistributedLock(redis_client, "resource_1", timeout=30) as lock:
        print("进入临界区")
        time.sleep(5)  # 模拟工作
        print("离开临界区")

# 多线程测试
threads = []
for i in range(5):
    thread = threading.Thread(target=critical_section)
    threads.append(thread)
    thread.start()

for thread in threads:
    thread.join()
```

### 可重入锁

**支持重入的分布式锁**：

```python
class ReentrantRedisLock:
    def __init__(self, redis_client, lock_name, timeout=10):
        self.redis_client = redis_client
        self.lock_name = f"reentrant_lock:{lock_name}"
        self.timeout = timeout
        self.thread_id = threading.get_ident()
        self.lock_count = 0
    
    def acquire(self, blocking=True, timeout=None):
        """获取可重入锁"""
        if timeout is None:
            timeout = self.timeout
        
        end_time = time.time() + timeout
        
        while True:
            # 检查是否已经持有锁
            current_holder = self.redis_client.hget(self.lock_name, "holder")
            
            if current_holder:
                current_holder = current_holder.decode()
                if current_holder == str(self.thread_id):
                    # 重入
                    self.lock_count += 1
                    self.redis_client.hincrby(self.lock_name, "count", 1)
                    self.redis_client.expire(self.lock_name, self.timeout)
                    return True
            
            # 尝试获取新锁
            lua_script = """
            if redis.call('exists', KEYS[1]) == 0 then
                redis.call('hset', KEYS[1], 'holder', ARGV[1])
                redis.call('hset', KEYS[1], 'count', 1)
                redis.call('expire', KEYS[1], ARGV[2])
                return 1
            else
                return 0
            end
            """
            
            result = self.redis_client.eval(
                lua_script, 1,
                self.lock_name, str(self.thread_id), self.timeout
            )
            
            if result == 1:
                self.lock_count = 1
                return True
            
            if not blocking:
                return False
            
            if time.time() >= end_time:
                return False
            
            time.sleep(0.1)
    
    def release(self):
        """释放可重入锁"""
        if self.lock_count <= 0:
            return False
        
        lua_script = """
        if redis.call('hget', KEYS[1], 'holder') == ARGV[1] then
            local count = redis.call('hincrby', KEYS[1], 'count', -1)
            if count <= 0 then
                redis.call('del', KEYS[1])
            else
                redis.call('expire', KEYS[1], ARGV[2])
            end
            return 1
        else
            return 0
        end
        """
        
        result = self.redis_client.eval(
            lua_script, 1,
            self.lock_name, str(self.thread_id), self.timeout
        )
        
        if result == 1:
            self.lock_count -= 1
            return True
        
        return False
    
    def __enter__(self):
        if self.acquire():
            return self
        else:
            raise Exception("无法获取可重入锁")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()

# 使用示例
def recursive_function(depth, lock):
    """递归函数测试重入锁"""
    with lock:
        print(f"递归深度: {depth}")
        if depth > 0:
            recursive_function(depth - 1, lock)

lock = ReentrantRedisLock(redis_client, "recursive_resource")
recursive_function(3, lock)
```

### 红锁算法

**Redlock算法实现**：

```python
import random

class Redlock:
    def __init__(self, redis_clients, lock_name, timeout=10, retry_delay=0.2, retry_count=3):
        self.redis_clients = redis_clients
        self.lock_name = f"redlock:{lock_name}"
        self.timeout = timeout
        self.retry_delay = retry_delay
        self.retry_count = retry_count
        self.lock_value = None
        self.acquired_locks = []
    
    def acquire(self):
        """获取红锁"""
        for attempt in range(self.retry_count):
            self.lock_value = str(uuid.uuid4())
            self.acquired_locks = []
            
            start_time = time.time()
            
            # 尝试在所有Redis实例上获取锁
            for i, redis_client in enumerate(self.redis_clients):
                try:
                    if redis_client.set(self.lock_name, self.lock_value, nx=True, px=self.timeout * 1000):
                        self.acquired_locks.append(i)
                except Exception as e:
                    print(f"Redis实例 {i} 获取锁失败: {e}")
            
            # 计算获取锁的时间
            elapsed_time = (time.time() - start_time) * 1000
            
            # 检查是否获取了大多数锁且在有效时间内
            if (len(self.acquired_locks) >= (len(self.redis_clients) // 2 + 1) and
                elapsed_time < self.timeout * 1000):
                return True
            
            # 获取失败，释放已获取的锁
            self._release_acquired_locks()
            
            # 随机等待后重试
            time.sleep(random.uniform(0, self.retry_delay))
        
        return False
    
    def release(self):
        """释放红锁"""
        if self.lock_value is None:
            return False
        
        lua_script = """
        if redis.call('get', KEYS[1]) == ARGV[1] then
            return redis.call('del', KEYS[1])
        else
            return 0
        end
        """
        
        released_count = 0
        
        for i in self.acquired_locks:
            try:
                result = self.redis_clients[i].eval(lua_script, 1, self.lock_name, self.lock_value)
                if result == 1:
                    released_count += 1
            except Exception as e:
                print(f"Redis实例 {i} 释放锁失败: {e}")
        
        self.lock_value = None
        self.acquired_locks = []
        
        return released_count > 0
    
    def _release_acquired_locks(self):
        """释放已获取的锁"""
        lua_script = """
        if redis.call('get', KEYS[1]) == ARGV[1] then
            return redis.call('del', KEYS[1])
        else
            return 0
        end
        """
        
        for i in self.acquired_locks:
            try:
                self.redis_clients[i].eval(lua_script, 1, self.lock_name, self.lock_value)
            except Exception as e:
                print(f"释放Redis实例 {i} 的锁失败: {e}")
        
        self.acquired_locks = []
    
    def __enter__(self):
        if self.acquire():
            return self
        else:
            raise Exception("无法获取红锁")
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        self.release()

# 使用示例
# 创建多个Redis客户端（模拟不同的Redis实例）
redis_clients = [
    redis.Redis(host='redis1.example.com', port=6379),
    redis.Redis(host='redis2.example.com', port=6379),
    redis.Redis(host='redis3.example.com', port=6379),
    redis.Redis(host='redis4.example.com', port=6379),
    redis.Redis(host='redis5.example.com', port=6379)
]

def critical_section_with_redlock():
    """使用红锁的临界区"""
    with Redlock(redis_clients, "critical_resource", timeout=30) as lock:
        print("获取红锁成功，执行临界区代码")
        time.sleep(10)
        print("临界区代码执行完成")

critical_section_with_redlock()
```

## 实时数据处理

### 实时统计

**实时计数器**：

```python
from datetime import datetime, timedelta
import calendar

class RealTimeCounter:
    def __init__(self, redis_client):
        self.redis_client = redis_client
    
    def increment(self, counter_name, value=1, timestamp=None):
        """增加计数器"""
        if timestamp is None:
            timestamp = datetime.now()
        
        # 不同时间粒度的计数
        self._increment_by_minute(counter_name, value, timestamp)
        self._increment_by_hour(counter_name, value, timestamp)
        self._increment_by_day(counter_name, value, timestamp)
        self._increment_by_month(counter_name, value, timestamp)
    
    def _increment_by_minute(self, counter_name, value, timestamp):
        """按分钟计数"""
        minute_key = f"counter:{counter_name}:minute:{timestamp.strftime('%Y%m%d%H%M')}"
        self.redis_client.incrby(minute_key, value)
        self.redis_client.expire(minute_key, 3600)  # 1小时过期
    
    def _increment_by_hour(self, counter_name, value, timestamp):
        """按小时计数"""
        hour_key = f"counter:{counter_name}:hour:{timestamp.strftime('%Y%m%d%H')}"
        self.redis_client.incrby(hour_key, value)
        self.redis_client.expire(hour_key, 86400 * 7)  # 7天过期
    
    def _increment_by_day(self, counter_name, value, timestamp):
        """按天计数"""
        day_key = f"counter:{counter_name}:day:{timestamp.strftime('%Y%m%d')}"
        self.redis_client.incrby(day_key, value)
        self.redis_client.expire(day_key, 86400 * 30)  # 30天过期
    
    def _increment_by_month(self, counter_name, value, timestamp):
        """按月计数"""
        month_key = f"counter:{counter_name}:month:{timestamp.strftime('%Y%m')}"
        self.redis_client.incrby(month_key, value)
        self.redis_client.expire(month_key, 86400 * 365)  # 1年过期
    
    def get_count(self, counter_name, granularity='day', start_time=None, end_time=None):
        """获取计数"""
        if start_time is None:
            start_time = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
        if end_time is None:
            end_time = datetime.now()
        
        if granularity == 'minute':
            return self._get_minute_counts(counter_name, start_time, end_time)
        elif granularity == 'hour':
            return self._get_hour_counts(counter_name, start_time, end_time)
        elif granularity == 'day':
            return self._get_day_counts(counter_name, start_time, end_time)
        elif granularity == 'month':
            return self._get_month_counts(counter_name, start_time, end_time)
    
    def _get_minute_counts(self, counter_name, start_time, end_time):
        """获取分钟级计数"""
        counts = []
        current = start_time
        
        while current <= end_time:
            minute_key = f"counter:{counter_name}:minute:{current.strftime('%Y%m%d%H%M')}"
            count = self.redis_client.get(minute_key)
            counts.append({
                'timestamp': current.isoformat(),
                'count': int(count) if count else 0
            })
            current += timedelta(minutes=1)
        
        return counts
    
    def _get_hour_counts(self, counter_name, start_time, end_time):
        """获取小时级计数"""
        counts = []
        current = start_time.replace(minute=0, second=0, microsecond=0)
        
        while current <= end_time:
            hour_key = f"counter:{counter_name}:hour:{current.strftime('%Y%m%d%H')}"
            count = self.redis_client.get(hour_key)
            counts.append({
                'timestamp': current.isoformat(),
                'count': int(count) if count else 0
            })
            current += timedelta(hours=1)
        
        return counts
    
    def get_top_counters(self, pattern, limit=10):
        """获取热门计数器"""
        keys = self.redis_client.keys(f"counter:{pattern}:*")
        counter_values = []
        
        for key in keys:
            value = self.redis_client.get(key)
            if value:
                counter_values.append({
                    'key': key.decode(),
                    'value': int(value)
                })
        
        # 按值排序
        counter_values.sort(key=lambda x: x['value'], reverse=True)
        return counter_values[:limit]

# 使用示例
counter = RealTimeCounter(redis_client)

# 记录页面访问
counter.increment('page_views')
counter.increment('page_views', value=5)

# 记录用户行为
counter.increment('user_login')
counter.increment('user_register')

# 获取统计数据
today_views = counter.get_count('page_views', 'hour')
print(f"今日每小时页面访问量: {today_views}")

# 获取热门页面
top_pages = counter.get_top_counters('page_views', limit=5)
print(f"热门页面: {top_pages}")
```

### 滑动窗口统计

**滑动窗口计数器**：

```python
class SlidingWindowCounter:
    def __init__(self, redis_client, window_size=60, bucket_size=1):
        self.redis_client = redis_client
        self.window_size = window_size  # 窗口大小（秒）
        self.bucket_size = bucket_size  # 桶大小（秒）
        self.bucket_count = window_size // bucket_size
    
    def increment(self, counter_name, value=1, timestamp=None):
        """增加计数"""
        if timestamp is None:
            timestamp = time.time()
        
        # 计算桶索引
        bucket_index = int(timestamp // self.bucket_size) % self.bucket_count
        bucket_key = f"sliding:{counter_name}:{bucket_index}"
        
        # 使用Lua脚本原子性操作
        lua_script = """
        local bucket_key = KEYS[1]
        local timestamp_key = KEYS[2]
        local current_time = tonumber(ARGV[1])
        local bucket_size = tonumber(ARGV[2])
        local value = tonumber(ARGV[3])
        
        -- 检查桶是否过期
        local last_update = redis.call('get', timestamp_key)
        if last_update then
            local time_diff = current_time - tonumber(last_update)
            if time_diff >= bucket_size then
                -- 桶已过期，重置
                redis.call('set', bucket_key, value)
            else
                -- 桶未过期，增加计数
                redis.call('incrby', bucket_key, value)
            end
        else
            -- 新桶
            redis.call('set', bucket_key, value)
        end
        
        -- 更新时间戳
        redis.call('set', timestamp_key, current_time)
        redis.call('expire', bucket_key, ARGV[4])
        redis.call('expire', timestamp_key, ARGV[4])
        
        return redis.call('get', bucket_key)
        """
        
        timestamp_key = f"sliding:{counter_name}:{bucket_index}:ts"
        
        result = self.redis_client.eval(
            lua_script, 2,
            bucket_key, timestamp_key,
            timestamp, self.bucket_size, value, self.window_size * 2
        )
        
        return int(result) if result else 0
    
    def get_count(self, counter_name, timestamp=None):
        """获取滑动窗口内的总计数"""
        if timestamp is None:
            timestamp = time.time()
        
        total_count = 0
        current_bucket = int(timestamp // self.bucket_size) % self.bucket_count
        
        for i in range(self.bucket_count):
            bucket_index = (current_bucket - i) % self.bucket_count
            bucket_key = f"sliding:{counter_name}:{bucket_index}"
            timestamp_key = f"sliding:{counter_name}:{bucket_index}:ts"
            
            # 检查桶是否在窗口内
            last_update = self.redis_client.get(timestamp_key)
            if last_update:
                time_diff = timestamp - float(last_update)
                if time_diff < self.window_size:
                    count = self.redis_client.get(bucket_key)
                    if count:
                        total_count += int(count)
        
        return total_count
    
    def get_rate(self, counter_name, timestamp=None):
        """获取速率（每秒）"""
        count = self.get_count(counter_name, timestamp)
        return count / self.window_size

# 使用示例
sliding_counter = SlidingWindowCounter(redis_client, window_size=60, bucket_size=1)

# 模拟请求
for i in range(100):
    sliding_counter.increment('api_requests')
    time.sleep(0.1)

# 获取最近1分钟的请求数
recent_requests = sliding_counter.get_count('api_requests')
print(f"最近1分钟请求数: {recent_requests}")

# 获取请求速率
request_rate = sliding_counter.get_rate('api_requests')
print(f"请求速率: {request_rate:.2f} 请求/秒")
```

### 实时排行榜

**动态排行榜实现**：

```python
class RealTimeLeaderboard:
    def __init__(self, redis_client, leaderboard_name, max_size=100):
        self.redis_client = redis_client
        self.leaderboard_name = f"leaderboard:{leaderboard_name}"
        self.max_size = max_size
    
    def add_score(self, member, score):
        """添加或更新分数"""
        # 添加到有序集合
        self.redis_client.zadd(self.leaderboard_name, {member: score})
        
        # 保持排行榜大小
        self.redis_client.zremrangebyrank(self.leaderboard_name, 0, -(self.max_size + 1))
    
    def increment_score(self, member, increment=1):
        """增加分数"""
        new_score = self.redis_client.zincrby(self.leaderboard_name, increment, member)
        
        # 保持排行榜大小
        self.redis_client.zremrangebyrank(self.leaderboard_name, 0, -(self.max_size + 1))
        
        return new_score
    
    def get_top(self, count=10, with_scores=True):
        """获取前N名"""
        if with_scores:
            return self.redis_client.zrevrange(
                self.leaderboard_name, 0, count - 1, withscores=True
            )
        else:
            return self.redis_client.zrevrange(
                self.leaderboard_name, 0, count - 1
            )
    
    def get_rank(self, member):
        """获取成员排名（从1开始）"""
        rank = self.redis_client.zrevrank(self.leaderboard_name, member)
        return rank + 1 if rank is not None else None
    
    def get_score(self, member):
        """获取成员分数"""
        return self.redis_client.zscore(self.leaderboard_name, member)
    
    def get_around(self, member, count=5):
        """获取成员周围的排名"""
        rank = self.redis_client.zrevrank(self.leaderboard_name, member)
        if rank is None:
            return []
        
        start = max(0, rank - count)
        end = rank + count
        
        return self.redis_client.zrevrange(
            self.leaderboard_name, start, end, withscores=True
        )
    
    def remove_member(self, member):
        """移除成员"""
        return self.redis_client.zrem(self.leaderboard_name, member)
    
    def get_total_members(self):
        """获取总成员数"""
        return self.redis_client.zcard(self.leaderboard_name)

# 使用示例
leaderboard = RealTimeLeaderboard(redis_client, 'game_scores')

# 添加玩家分数
leaderboard.add_score('player1', 1000)
leaderboard.add_score('player2', 1500)
leaderboard.add_score('player3', 800)

# 增加分数
leaderboard.increment_score('player1', 200)

# 获取前10名
top_players = leaderboard.get_top(10)
print(f"前10名: {top_players}")

# 获取玩家排名
rank = leaderboard.get_rank('player1')
print(f"player1排名: {rank}")

# 获取周围排名
around = leaderboard.get_around('player1', 3)
print(f"player1周围排名: {around}")
```

## 实践操作

### 搭建Redis应用实战环境

**环境准备脚本**：

```shell
#!/bin/bash
# setup_redis_app_env.sh - Redis应用实战环境搭建

echo "=== Redis应用实战环境搭建 ==="

# 创建项目目录
APP_DIR="redis_app_demo"
mkdir -p $APP_DIR
cd $APP_DIR

# 创建Python虚拟环境
echo "创建Python虚拟环境..."
python3 -m venv venv
source venv/bin/activate

# 安装依赖
echo "安装Python依赖..."
cat > requirements.txt << 'EOF'
redis==4.5.4
flask==2.3.2
requests==2.31.0
mysql-connector-python==8.0.33
celery==5.2.7
EOF

pip install -r requirements.txt

# 创建配置文件
echo "创建配置文件..."
cat > config.py << 'EOF'
import os

class Config:
    # Redis配置
    REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
    REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
    REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', None)
    REDIS_DB = int(os.getenv('REDIS_DB', 0))
    
    # 数据库配置
    DB_HOST = os.getenv('DB_HOST', 'localhost')
    DB_USER = os.getenv('DB_USER', 'root')
    DB_PASSWORD = os.getenv('DB_PASSWORD', 'password')
    DB_NAME = os.getenv('DB_NAME', 'redis_demo')
    
    # 应用配置
    SECRET_KEY = os.getenv('SECRET_KEY', 'your-secret-key')
    DEBUG = os.getenv('DEBUG', 'False').lower() == 'true'
EOF

echo "环境搭建完成！"
echo "激活虚拟环境: source venv/bin/activate"
echo "项目目录: $(pwd)"
```

### 缓存应用示例

**Web应用缓存实现**：

```python
# app.py - Flask应用示例
from flask import Flask, request, jsonify
import redis
import json
import time
from config import Config

app = Flask(__name__)
app.config.from_object(Config)

# Redis连接
redis_client = redis.Redis(
    host=app.config['REDIS_HOST'],
    port=app.config['REDIS_PORT'],
    password=app.config['REDIS_PASSWORD'],
    db=app.config['REDIS_DB'],
    decode_responses=True
)

# 缓存装饰器
def cache_result(expiration=300):
    def decorator(func):
        def wrapper(*args, **kwargs):
            # 生成缓存键
            cache_key = f"cache:{func.__name__}:{hash(str(args) + str(kwargs))}"
            
            # 尝试从缓存获取
            cached_result = redis_client.get(cache_key)
            if cached_result:
                return json.loads(cached_result)
            
            # 执行函数
            result = func(*args, **kwargs)
            
            # 存储到缓存
            redis_client.setex(cache_key, expiration, json.dumps(result, default=str))
            
            return result
        return wrapper
    return decorator

@app.route('/api/users/<int:user_id>')
@cache_result(expiration=600)
def get_user(user_id):
    """获取用户信息（带缓存）"""
    # 模拟数据库查询
    time.sleep(0.5)  # 模拟查询延时
    
    user_data = {
        'id': user_id,
        'name': f'User {user_id}',
        'email': f'user{user_id}@example.com',
        'created_at': time.time()
    }
    
    return user_data

@app.route('/api/stats/page_views')
def get_page_views():
    """获取页面访问统计"""
    # 增加访问计数
    redis_client.incr('page_views:total')
    redis_client.incr(f'page_views:daily:{time.strftime("%Y%m%d")}')
    
    # 获取统计数据
    total_views = redis_client.get('page_views:total') or 0
    daily_views = redis_client.get(f'page_views:daily:{time.strftime("%Y%m%d")}') or 0
    
    return jsonify({
        'total_views': int(total_views),
        'daily_views': int(daily_views)
    })

@app.route('/api/leaderboard')
def get_leaderboard():
    """获取排行榜"""
    # 获取前10名
    top_players = redis_client.zrevrange('game_leaderboard', 0, 9, withscores=True)
    
    leaderboard = []
    for i, (player, score) in enumerate(top_players):
        leaderboard.append({
            'rank': i + 1,
            'player': player,
            'score': int(score)
        })
    
    return jsonify(leaderboard)

@app.route('/api/leaderboard/update', methods=['POST'])
def update_score():
    """更新玩家分数"""
    data = request.get_json()
    player = data.get('player')
    score = data.get('score', 0)
    
    if not player:
        return jsonify({'error': '玩家名称不能为空'}), 400
    
    # 更新分数
    new_score = redis_client.zincrby('game_leaderboard', score, player)
    
    # 获取新排名
    rank = redis_client.zrevrank('game_leaderboard', player)
    
    return jsonify({
        'player': player,
        'new_score': int(new_score),
        'rank': rank + 1 if rank is not None else None
    })

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
```

### 消息队列示例

**任务队列实现**：

```python
# task_queue.py - 任务队列示例
import redis
import json
import time
import threading
from datetime import datetime

class TaskQueue:
    def __init__(self, redis_client, queue_name='default'):
        self.redis_client = redis_client
        self.queue_name = f"task_queue:{queue_name}"
        self.processing_queue = f"{self.queue_name}:processing"
        self.failed_queue = f"{self.queue_name}:failed"
        self.task_handlers = {}
    
    def register_task(self, task_name):
        """任务注册装饰器"""
        def decorator(func):
            self.task_handlers[task_name] = func
            return func
        return decorator
    
    def enqueue(self, task_name, task_data, delay=0):
        """入队任务"""
        task = {
            'id': f"{task_name}_{int(time.time() * 1000)}",
            'name': task_name,
            'data': task_data,
            'created_at': datetime.now().isoformat(),
            'retry_count': 0
        }
        
        if delay > 0:
            # 延时任务
            execute_time = time.time() + delay
            self.redis_client.zadd(f"{self.queue_name}:delayed", {json.dumps(task): execute_time})
        else:
            # 立即执行
            self.redis_client.lpush(self.queue_name, json.dumps(task))
        
        return task['id']
    
    def process_tasks(self, worker_id=1):
        """处理任务"""
        print(f"Worker {worker_id} 开始处理任务...")
        
        while True:
            try:
                # 处理延时任务
                self._process_delayed_tasks()
                
                # 获取任务
                task_data = self.redis_client.brpop(self.queue_name, timeout=5)
                
                if task_data:
                    queue_name, task_json = task_data
                    task = json.loads(task_json)
                    
                    # 移动到处理队列
                    self.redis_client.lpush(self.processing_queue, task_json)
                    
                    # 执行任务
                    self._execute_task(task, worker_id)
                    
                    # 从处理队列移除
                    self.redis_client.lrem(self.processing_queue, 1, task_json)
                    
            except Exception as e:
                print(f"Worker {worker_id} 错误: {e}")
                time.sleep(1)
    
    def _process_delayed_tasks(self):
        """处理延时任务"""
        current_time = time.time()
        delayed_queue = f"{self.queue_name}:delayed"
        
        # 获取到期的任务
        ready_tasks = self.redis_client.zrangebyscore(
            delayed_queue, 0, current_time
        )
        
        for task_json in ready_tasks:
            # 移动到主队列
            self.redis_client.lpush(self.queue_name, task_json)
            self.redis_client.zrem(delayed_queue, task_json)
    
    def _execute_task(self, task, worker_id):
        """执行任务"""
        task_name = task['name']
        task_id = task['id']
        
        try:
            print(f"Worker {worker_id} 执行任务: {task_id}")
            
            if task_name in self.task_handlers:
                handler = self.task_handlers[task_name]
                result = handler(task['data'])
                print(f"任务 {task_id} 完成: {result}")
            else:
                raise Exception(f"未找到任务处理器: {task_name}")
                
        except Exception as e:
            print(f"任务 {task_id} 失败: {e}")
            
            # 重试逻辑
            task['retry_count'] += 1
            if task['retry_count'] < 3:
                # 重新入队
                delay = 2 ** task['retry_count']  # 指数退避
                self.enqueue(task_name, task['data'], delay=delay)
            else:
                # 移到失败队列
                task['failed_at'] = datetime.now().isoformat()
                task['error'] = str(e)
                self.redis_client.lpush(self.failed_queue, json.dumps(task))

# 使用示例
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
task_queue = TaskQueue(redis_client)

@task_queue.register_task('send_email')
def send_email_task(data):
    """发送邮件任务"""
    email = data['email']
    subject = data['subject']
    content = data['content']
    
    print(f"发送邮件到 {email}")
    print(f"主题: {subject}")
    print(f"内容: {content}")
    
    # 模拟发送邮件
    time.sleep(2)
    
    return f"邮件已发送到 {email}"

@task_queue.register_task('process_image')
def process_image_task(data):
    """图片处理任务"""
    image_path = data['image_path']
    operations = data['operations']
    
    print(f"处理图片: {image_path}")
    print(f"操作: {operations}")
    
    # 模拟图片处理
    time.sleep(5)
    
    return f"图片 {image_path} 处理完成"

# 启动工作进程
def start_worker(worker_id):
    task_queue.process_tasks(worker_id)

# 启动多个工作线程
for i in range(3):
    worker_thread = threading.Thread(target=start_worker, args=(i+1,), daemon=True)
    worker_thread.start()

# 添加任务
task_queue.enqueue('send_email', {
    'email': 'user@example.com',
    'subject': '欢迎注册',
    'content': '感谢您注册我们的服务！'
})

task_queue.enqueue('process_image', {
    'image_path': '/uploads/photo.jpg',
    'operations': ['resize', 'watermark']
}, delay=10)  # 10秒后执行

print("任务已添加到队列")
print("按Ctrl+C退出")

try:
    while True:
        time.sleep(1)
except KeyboardInterrupt:
    print("\n程序退出")
```

### 分布式锁示例

**库存管理系统**：

```python
# inventory_system.py - 分布式锁库存管理示例
import redis
import time
import threading
import uuid
from contextlib import contextmanager

class InventoryManager:
    def __init__(self, redis_client):
        self.redis_client = redis_client
    
    @contextmanager
    def distributed_lock(self, lock_name, timeout=10):
        """分布式锁上下文管理器"""
        lock_key = f"lock:{lock_name}"
        lock_value = str(uuid.uuid4())
        
        # 获取锁
        acquired = self.redis_client.set(lock_key, lock_value, nx=True, ex=timeout)
        
        if not acquired:
            raise Exception(f"无法获取锁: {lock_name}")
        
        try:
            yield
        finally:
            # 释放锁（使用Lua脚本确保原子性）
            lua_script = """
            if redis.call('get', KEYS[1]) == ARGV[1] then
                return redis.call('del', KEYS[1])
            else
                return 0
            end
            """
            self.redis_client.eval(lua_script, 1, lock_key, lock_value)
    
    def get_stock(self, product_id):
        """获取库存"""
        stock = self.redis_client.get(f"stock:{product_id}")
        return int(stock) if stock else 0
    
    def set_stock(self, product_id, quantity):
        """设置库存"""
        self.redis_client.set(f"stock:{product_id}", quantity)
    
    def reserve_stock(self, product_id, quantity, user_id):
        """预留库存"""
        with self.distributed_lock(f"stock:{product_id}", timeout=30):
            current_stock = self.get_stock(product_id)
            
            if current_stock < quantity:
                return False, f"库存不足，当前库存: {current_stock}"
            
            # 减少库存
            new_stock = current_stock - quantity
            self.set_stock(product_id, new_stock)
            
            # 记录预留
            reservation_id = str(uuid.uuid4())
            reservation_data = {
                'id': reservation_id,
                'product_id': product_id,
                'quantity': quantity,
                'user_id': user_id,
                'created_at': time.time()
            }
            
            self.redis_client.hset(
                f"reservation:{reservation_id}",
                mapping=reservation_data
            )
            self.redis_client.expire(f"reservation:{reservation_id}", 1800)  # 30分钟过期
            
            return True, reservation_id
    
    def confirm_reservation(self, reservation_id):
        """确认预留（完成购买）"""
        reservation_data = self.redis_client.hgetall(f"reservation:{reservation_id}")
        
        if not reservation_data:
            return False, "预留不存在或已过期"
        
        # 删除预留记录
        self.redis_client.delete(f"reservation:{reservation_id}")
        
        return True, "购买确认成功"
    
    def cancel_reservation(self, reservation_id):
        """取消预留（恢复库存）"""
        reservation_data = self.redis_client.hgetall(f"reservation:{reservation_id}")
        
        if not reservation_data:
            return False, "预留不存在或已过期"
        
        product_id = reservation_data['product_id']
        quantity = int(reservation_data['quantity'])
        
        with self.distributed_lock(f"stock:{product_id}", timeout=30):
            # 恢复库存
            current_stock = self.get_stock(product_id)
            new_stock = current_stock + quantity
            self.set_stock(product_id, new_stock)
            
            # 删除预留记录
            self.redis_client.delete(f"reservation:{reservation_id}")
        
        return True, "预留已取消，库存已恢复"

# 使用示例和测试
redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
inventory = InventoryManager(redis_client)

# 初始化商品库存
inventory.set_stock('product_001', 100)
inventory.set_stock('product_002', 50)

def simulate_purchase(user_id, product_id, quantity):
    """模拟购买过程"""
    print(f"用户 {user_id} 尝试购买商品 {product_id} 数量 {quantity}")
    
    # 预留库存
    success, result = inventory.reserve_stock(product_id, quantity, user_id)
    
    if success:
        reservation_id = result
        print(f"用户 {user_id} 预留成功，预留ID: {reservation_id}")
        
        # 模拟支付过程
        time.sleep(2)
        
        # 随机决定是否确认购买
        import random
        if random.random() > 0.3:  # 70%概率确认购买
            inventory.confirm_reservation(reservation_id)
            print(f"用户 {user_id} 购买确认成功")
        else:
            inventory.cancel_reservation(reservation_id)
            print(f"用户 {user_id} 取消购买，库存已恢复")
    else:
        print(f"用户 {user_id} 预留失败: {result}")
    
    print(f"当前库存: {inventory.get_stock(product_id)}")
    print("-" * 50)

# 并发测试
threads = []
for i in range(10):
    thread = threading.Thread(
        target=simulate_purchase,
        args=(f"user_{i}", 'product_001', 5)
    )
    threads.append(thread)
    thread.start()

for thread in threads:
    thread.join()

print(f"最终库存: {inventory.get_stock('product_001')}")
```

### 发布订阅示例

**实时消息系统**：

```python
# realtime_chat.py - 实时聊天系统示例
import redis
import time
import threading
import uuid
from contextlib import contextmanager

class ChatSystem:
    def __init__(self, redis_client):
        self.redis_client = redis_client
        self.pubsub = self.redis_client.pubsub()
    
    def subscribe(self, channel):
        """订阅频道"""
        self.pubsub.subscribe(channel)
    
    def publish(self, channel, message):