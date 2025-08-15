# Redis 安全管理

## 访问控制

### 密码认证

Redis 提供了基本的密码认证机制来保护数据安全。

**配置密码认证**：

```shell
# 在配置文件中设置密码
# /etc/redis/redis.conf
requirepass your_strong_password

# 动态设置密码
redis-cli CONFIG SET requirepass "your_strong_password"

# 使用密码连接
redis-cli -a your_strong_password

# 或者连接后认证
redis-cli
127.0.0.1:6379> AUTH your_strong_password
OK
```

**密码安全最佳实践**：

```shell
# 生成强密码
openssl rand -base64 32

# 密码复杂度要求：
# - 长度至少16位
# - 包含大小写字母、数字、特殊字符
# - 避免使用字典词汇
# - 定期更换密码

# 示例强密码
requirepass "Rd!s@2024#Str0ng&P@ssw0rd"
```

### 用户管理 (ACL)

Redis 6.0+ 引入了 ACL（Access Control List）功能，提供更细粒度的权限控制。

**ACL 基本概念**：

```shell
# 查看当前用户
ACL WHOAMI

# 列出所有用户
ACL LIST

# 查看用户详细信息
ACL GETUSER username

# 查看当前用户权限
ACL GETUSER default
```

**创建和管理用户**：

```shell
# 创建只读用户
ACL SETUSER readonly on >readonly_password ~* &* -@all +@read

# 创建读写用户（限制特定键模式）
ACL SETUSER readwrite on >readwrite_password ~app:* &* -@all +@read +@write

# 创建管理员用户
ACL SETUSER admin on >admin_password ~* &* +@all

# 创建应用用户（限制命令）
ACL SETUSER appuser on >app_password ~app:* &* -@all +get +set +del +exists +expire

# 删除用户
ACL DELUSER username
```

**ACL 规则详解**：

```shell
# ACL 规则语法：
# on/off：启用/禁用用户
# >password：设置密码
# ~pattern：允许访问的键模式
# &pattern：允许访问的发布订阅频道模式
# +command：允许的命令
# -command：禁止的命令
# +@category：允许的命令分类
# -@category：禁止的命令分类

# 常用命令分类：
# @read：读命令
# @write：写命令
# @admin：管理命令
# @dangerous：危险命令
# @keyspace：键空间命令
# @string：字符串命令
# @list：列表命令
# @set：集合命令
# @hash：哈希命令
# @sortedset：有序集合命令
```

### 权限控制

**细粒度权限配置**：

```shell
# 数据库管理员
ACL SETUSER dba on >dba_password ~* &* +@all

# 应用开发者
ACL SETUSER developer on >dev_password ~dev:* &dev:* -@all +@read +@write -flushdb -flushall -shutdown

# 监控用户
ACL SETUSER monitor on >monitor_password ~* &* -@all +info +ping +client +config|get

# 备份用户
ACL SETUSER backup on >backup_password ~* &* -@all +@read +bgsave +lastsave

# 只读分析用户
ACL SETUSER analyst on >analyst_password ~analytics:* &* -@all +@read +scan +keys
```

**权限验证测试**：

```shell
# 测试用户权限
redis-cli --user readonly --pass readonly_password
127.0.0.1:6379> GET some_key  # 应该成功
127.0.0.1:6379> SET some_key value  # 应该失败

# 测试键模式限制
redis-cli --user developer --pass dev_password
127.0.0.1:6379> GET dev:config  # 应该成功
127.0.0.1:6379> GET prod:config  # 应该失败
```

### IP 白名单

**网络访问控制**：

```shell
# 绑定特定IP地址
# /etc/redis/redis.conf
bind 127.0.0.1 192.168.1.100 10.0.0.50

# 禁用保护模式（仅在安全网络环境中）
protected-mode no

# 使用防火墙限制访问
sudo firewall-cmd --permanent --add-rich-rule="rule family='ipv4' source address='192.168.1.0/24' port protocol='tcp' port='6379' accept"
sudo firewall-cmd --reload
```

## 网络安全

### 端口安全

**端口配置和保护**：

```shell
# 更改默认端口
# /etc/redis/redis.conf
port 16379  # 使用非标准端口

# 禁用端口（仅使用Unix套接字）
port 0
unixsocket /var/run/redis/redis.sock
unixsocketperm 700

# 连接Unix套接字
redis-cli -s /var/run/redis/redis.sock
```

**网络接口绑定**：

```shell
# 仅绑定内网接口
bind 127.0.0.1 192.168.1.100

# 绑定多个接口
bind 127.0.0.1 10.0.0.100 172.16.0.100

# 监听所有接口（不推荐）
# bind 0.0.0.0
```

### SSL/TLS 加密

Redis 6.0+ 支持 SSL/TLS 加密传输。

**生成SSL证书**：

```shell
# 创建证书目录
mkdir -p /etc/redis/ssl
cd /etc/redis/ssl

# 生成私钥
openssl genrsa -out redis.key 2048

# 生成证书签名请求
openssl req -new -key redis.key -out redis.csr -subj "/C=CN/ST=Beijing/L=Beijing/O=Company/CN=redis.example.com"

# 生成自签名证书
openssl x509 -req -days 365 -in redis.csr -signkey redis.key -out redis.crt

# 生成DH参数文件
openssl dhparam -out redis.dh 2048

# 设置权限
chown redis:redis /etc/redis/ssl/*
chmod 600 /etc/redis/ssl/redis.key
chmod 644 /etc/redis/ssl/redis.crt
chmod 644 /etc/redis/ssl/redis.dh
```

**配置SSL/TLS**：

```shell
# Redis 配置文件
# /etc/redis/redis.conf

# 启用TLS端口
port 0
tls-port 6380

# 证书文件路径
tls-cert-file /etc/redis/ssl/redis.crt
tls-key-file /etc/redis/ssl/redis.key
tls-dh-params-file /etc/redis/ssl/redis.dh

# CA证书（如果使用）
# tls-ca-cert-file /etc/redis/ssl/ca.crt

# 客户端证书验证
tls-auth-clients yes

# TLS协议版本
tls-protocols "TLSv1.2 TLSv1.3"

# 密码套件
tls-ciphersuites TLS_AES_256_GCM_SHA384:TLS_CHACHA20_POLY1305_SHA256
tls-ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256

# 会话缓存
tls-session-caching no
tls-session-cache-size 5000
tls-session-cache-timeout 60
```

**SSL客户端连接**：

```shell
# 使用SSL连接
redis-cli --tls --cert /etc/redis/ssl/client.crt --key /etc/redis/ssl/client.key --cacert /etc/redis/ssl/ca.crt -p 6380

# 跳过证书验证（仅测试环境）
redis-cli --tls --insecure -p 6380
```

### 防火墙配置

**iptables 配置**：

```shell
# 允许特定IP访问Redis
iptables -A INPUT -p tcp -s 192.168.1.0/24 --dport 6379 -j ACCEPT
iptables -A INPUT -p tcp --dport 6379 -j DROP

# 限制连接频率
iptables -A INPUT -p tcp --dport 6379 -m connlimit --connlimit-above 10 -j DROP
iptables -A INPUT -p tcp --dport 6379 -m recent --set --name redis
iptables -A INPUT -p tcp --dport 6379 -m recent --update --seconds 60 --hitcount 20 --name redis -j DROP

# 保存规则
iptables-save > /etc/iptables/rules.v4
```

### VPN 访问

**OpenVPN 配置示例**：

```shell
# 安装OpenVPN
sudo apt update
sudo apt install openvpn easy-rsa

# 配置VPN服务器
sudo make-cadir /etc/openvpn/easy-rsa
cd /etc/openvpn/easy-rsa

# 初始化PKI
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh

# 生成客户端证书
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1
```

## 数据安全

### 数据加密

**应用层加密**：

```python
# Python 数据加密示例
import redis
import json
from cryptography.fernet import Fernet

class EncryptedRedis:
    def __init__(self, host='localhost', port=6379, password=None, key=None):
        self.redis = redis.Redis(host=host, port=port, password=password)
        self.cipher = Fernet(key or Fernet.generate_key())
    
    def set(self, name, value, ex=None):
        """加密存储数据"""
        if isinstance(value, dict):
            value = json.dumps(value)
        encrypted_value = self.cipher.encrypt(value.encode())
        return self.redis.set(name, encrypted_value, ex=ex)
    
    def get(self, name):
        """解密获取数据"""
        encrypted_value = self.redis.get(name)
        if encrypted_value:
            decrypted_value = self.cipher.decrypt(encrypted_value)
            return decrypted_value.decode()
        return None
    
    def hset(self, name, key, value):
        """加密存储哈希字段"""
        if isinstance(value, dict):
            value = json.dumps(value)
        encrypted_value = self.cipher.encrypt(value.encode())
        return self.redis.hset(name, key, encrypted_value)
    
    def hget(self, name, key):
        """解密获取哈希字段"""
        encrypted_value = self.redis.hget(name, key)
        if encrypted_value:
            decrypted_value = self.cipher.decrypt(encrypted_value)
            return decrypted_value.decode()
        return None

# 使用示例
key = Fernet.generate_key()
encrypted_redis = EncryptedRedis(password='your_password', key=key)

# 存储加密数据
user_data = {'name': 'John', 'email': 'john@example.com', 'phone': '123-456-7890'}
encrypted_redis.set('user:1', json.dumps(user_data))

# 获取解密数据
data = encrypted_redis.get('user:1')
user_info = json.loads(data)
print(user_info)
```

### 敏感数据处理

**敏感数据脱敏**：

```python
# 数据脱敏工具
import re
import hashlib

class DataMasking:
    @staticmethod
    def mask_phone(phone):
        """手机号脱敏"""
        if len(phone) == 11:
            return phone[:3] + '****' + phone[7:]
        return phone
    
    @staticmethod
    def mask_email(email):
        """邮箱脱敏"""
        if '@' in email:
            local, domain = email.split('@')
            if len(local) > 2:
                masked_local = local[0] + '*' * (len(local) - 2) + local[-1]
            else:
                masked_local = '*' * len(local)
            return f"{masked_local}@{domain}"
        return email
    
    @staticmethod
    def mask_id_card(id_card):
        """身份证脱敏"""
        if len(id_card) == 18:
            return id_card[:6] + '********' + id_card[14:]
        return id_card
    
    @staticmethod
    def hash_sensitive_data(data, salt=''):
        """敏感数据哈希"""
        return hashlib.sha256((str(data) + salt).encode()).hexdigest()

# 使用示例
masker = DataMasking()

# 存储脱敏数据
user_data = {
    'name': 'John Doe',
    'phone': masker.mask_phone('13812345678'),
    'email': masker.mask_email('john.doe@example.com'),
    'id_card': masker.mask_id_card('110101199001011234')
}

redis_client = redis.Redis(password='your_password')
redis_client.hset('user:masked:1', mapping=user_data)
```

### 备份安全

**安全备份策略**：

```shell
#!/bin/bash
# 安全备份脚本

BACKUP_DIR="/secure/backup/redis"
ENCRYPTION_KEY="/secure/keys/backup.key"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="redis_backup_$DATE.rdb"
ENCRYPTED_FILE="$BACKUP_FILE.enc"

# 创建备份目录
mkdir -p $BACKUP_DIR

# 生成备份
redis-cli --rdb $BACKUP_DIR/$BACKUP_FILE

# 加密备份文件
openssl enc -aes-256-cbc -salt -in $BACKUP_DIR/$BACKUP_FILE -out $BACKUP_DIR/$ENCRYPTED_FILE -pass file:$ENCRYPTION_KEY

# 删除未加密文件
rm $BACKUP_DIR/$BACKUP_FILE

# 计算校验和
sha256sum $BACKUP_DIR/$ENCRYPTED_FILE > $BACKUP_DIR/$ENCRYPTED_FILE.sha256

# 设置权限
chmod 600 $BACKUP_DIR/$ENCRYPTED_FILE
chown backup:backup $BACKUP_DIR/$ENCRYPTED_FILE

echo "备份完成：$BACKUP_DIR/$ENCRYPTED_FILE"

# 清理旧备份（保留30天）
find $BACKUP_DIR -name "*.enc" -mtime +30 -delete
find $BACKUP_DIR -name "*.sha256" -mtime +30 -delete
```

**备份恢复脚本**：

```shell
#!/bin/bash
# 安全恢复脚本

BACKUP_FILE="$1"
ENCRYPTION_KEY="/secure/keys/backup.key"
TEMP_DIR="/tmp/redis_restore"

if [ -z "$BACKUP_FILE" ]; then
    echo "用法: $0 <encrypted_backup_file>"
    exit 1
fi

# 验证文件存在
if [ ! -f "$BACKUP_FILE" ]; then
    echo "备份文件不存在: $BACKUP_FILE"
    exit 1
fi

# 验证校验和
if [ -f "$BACKUP_FILE.sha256" ]; then
    echo "验证文件完整性..."
    sha256sum -c "$BACKUP_FILE.sha256"
    if [ $? -ne 0 ]; then
        echo "文件完整性验证失败"
        exit 1
    fi
fi

# 创建临时目录
mkdir -p $TEMP_DIR

# 解密备份文件
echo "解密备份文件..."
DECRYPTED_FILE="$TEMP_DIR/$(basename $BACKUP_FILE .enc)"
openssl enc -aes-256-cbc -d -in "$BACKUP_FILE" -out "$DECRYPTED_FILE" -pass file:$ENCRYPTION_KEY

if [ $? -eq 0 ]; then
    echo "备份文件已解密到: $DECRYPTED_FILE"
    echo "请手动将文件复制到Redis数据目录并重启服务"
else
    echo "解密失败"
    rm -rf $TEMP_DIR
    exit 1
fi
```

### 审计日志

**审计日志配置**：

```shell
# Redis 配置文件
# /etc/redis/redis.conf

# 启用命令日志
logfile /var/log/redis/redis-server.log
loglevel notice

# 启用慢查询日志
slowlog-log-slower-than 10000
slowlog-max-len 128

# 客户端连接日志
# 通过监控脚本实现
```

**审计日志脚本**：

```shell
#!/bin/bash
# Redis 审计日志脚本

LOG_FILE="/var/log/redis/audit.log"
REDIS_LOG="/var/log/redis/redis-server.log"

# 监控Redis连接
tail -f $REDIS_LOG | while read line; do
    if echo "$line" | grep -q "Accepted\|Client closed connection"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') $line" >> $LOG_FILE
    fi
done &

# 监控命令执行（需要启用monitor）
redis-cli monitor | while read line; do
    # 过滤敏感命令
    if echo "$line" | grep -qE "AUTH|CONFIG|EVAL|FLUSHDB|FLUSHALL|SHUTDOWN"; then
        echo "$(date '+%Y-%m-%d %H:%M:%S') SENSITIVE: $line" >> $LOG_FILE
    fi
done &

echo "审计日志监控已启动"
```

## 安全最佳实践

### 安全配置检查

**安全配置检查清单**：

```shell
#!/bin/bash
# Redis 安全配置检查脚本

echo "=== Redis 安全配置检查 ==="

# 检查密码配置
echo "1. 检查密码配置"
if redis-cli CONFIG GET requirepass | grep -q "requirepass"; then
    echo "✓ 已配置密码认证"
else
    echo "✗ 未配置密码认证"
fi

# 检查绑定地址
echo "2. 检查绑定地址"
BIND_ADDR=$(redis-cli CONFIG GET bind | tail -1)
if [ "$BIND_ADDR" != "" ] && [ "$BIND_ADDR" != "0.0.0.0" ]; then
    echo "✓ 绑定地址配置安全: $BIND_ADDR"
else
    echo "✗ 绑定地址不安全: $BIND_ADDR"
fi

# 检查保护模式
echo "3. 检查保护模式"
PROTECTED_MODE=$(redis-cli CONFIG GET protected-mode | tail -1)
if [ "$PROTECTED_MODE" = "yes" ]; then
    echo "✓ 保护模式已启用"
else
    echo "✗ 保护模式未启用"
fi

# 检查危险命令
echo "4. 检查危险命令"
DANGEROUS_COMMANDS=("FLUSHDB" "FLUSHALL" "CONFIG" "EVAL" "SHUTDOWN" "DEBUG")
for cmd in "${DANGEROUS_COMMANDS[@]}"; do
    if redis-cli CONFIG GET "rename-command" | grep -q "$cmd"; then
        echo "✓ 危险命令 $cmd 已重命名或禁用"
    else
        echo "✗ 危险命令 $cmd 未处理"
    fi
done

# 检查文件权限
echo "5. 检查文件权限"
REDIS_CONF="/etc/redis/redis.conf"
if [ -f "$REDIS_CONF" ]; then
    PERM=$(stat -c "%a" "$REDIS_CONF")
    if [ "$PERM" = "640" ] || [ "$PERM" = "600" ]; then
        echo "✓ 配置文件权限安全: $PERM"
    else
        echo "✗ 配置文件权限不安全: $PERM"
    fi
fi

# 检查日志配置
echo "6. 检查日志配置"
LOGFILE=$(redis-cli CONFIG GET logfile | tail -1)
if [ "$LOGFILE" != "" ]; then
    echo "✓ 已配置日志文件: $LOGFILE"
else
    echo "✗ 未配置日志文件"
fi

echo "=== 检查完成 ==="
```

### 漏洞防护

**常见漏洞防护措施**：

```shell
# 1. 禁用或重命名危险命令
# /etc/redis/redis.conf
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command CONFIG "CONFIG_b840fc02d524045429941cc15f59e41cb7be6c52"
rename-command EVAL ""
rename-command DEBUG ""
rename-command SHUTDOWN "SHUTDOWN_b840fc02d524045429941cc15f59e41cb7be6c52"

# 2. 限制客户端连接
maxclients 1000
timeout 300
tcp-keepalive 300

# 3. 禁用Lua脚本调试
lua-replicate-commands yes

# 4. 设置内存限制
maxmemory 2gb
maxmemory-policy allkeys-lru
```

### 安全更新

**安全更新策略**：

```shell
#!/bin/bash
# Redis 安全更新脚本

echo "检查Redis版本和安全更新"

# 获取当前版本
CURRENT_VERSION=$(redis-server --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
echo "当前Redis版本: $CURRENT_VERSION"

# 检查是否有安全更新
echo "检查安全公告..."
echo "请访问以下链接查看最新安全公告:"
echo "- https://redis.io/topics/security"
echo "- https://github.com/redis/redis/security/advisories"

# 备份当前配置
echo "备份当前配置..."
cp /etc/redis/redis.conf /etc/redis/redis.conf.backup.$(date +%Y%m%d)

# 更新前检查
echo "更新前安全检查:"
redis-cli CONFIG GET '*' > /tmp/redis_config_before_update.txt

echo "请手动执行以下步骤:"
echo "1. 下载最新稳定版本"
echo "2. 测试环境验证"
echo "3. 制定回滚计划"
echo "4. 执行更新"
echo "5. 验证功能和安全配置"
```

### 应急响应

**安全事件应急响应**：

```shell
#!/bin/bash
# Redis 安全事件应急响应脚本

INCIDENT_LOG="/var/log/redis/security_incident.log"
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "=== Redis 安全事件应急响应 ==="
echo "事件时间: $DATE" | tee -a $INCIDENT_LOG

# 1. 立即隔离
echo "1. 立即隔离Redis服务"
echo "停止Redis服务? (y/n)"
read -r response
if [ "$response" = "y" ]; then
    sudo systemctl stop redis
    echo "$DATE: Redis服务已停止" | tee -a $INCIDENT_LOG
fi

# 2. 收集证据
echo "2. 收集安全证据"
EVIDENCE_DIR="/tmp/redis_incident_$(date +%Y%m%d_%H%M%S)"
mkdir -p $EVIDENCE_DIR

# 收集日志
cp /var/log/redis/* $EVIDENCE_DIR/ 2>/dev/null

# 收集配置
cp /etc/redis/redis.conf $EVIDENCE_DIR/

# 收集进程信息
ps aux | grep redis > $EVIDENCE_DIR/processes.txt

# 收集网络连接
netstat -tulpn | grep :6379 > $EVIDENCE_DIR/connections.txt

# 收集系统信息
uname -a > $EVIDENCE_DIR/system_info.txt
whoami > $EVIDENCE_DIR/current_user.txt

echo "证据已收集到: $EVIDENCE_DIR"
echo "$DATE: 证据收集完成 - $EVIDENCE_DIR" | tee -a $INCIDENT_LOG

# 3. 分析威胁
echo "3. 分析潜在威胁"
echo "检查可疑连接..."
redis-cli CLIENT LIST > $EVIDENCE_DIR/client_list.txt 2>/dev/null

echo "检查慢查询日志..."
redis-cli SLOWLOG GET 100 > $EVIDENCE_DIR/slowlog.txt 2>/dev/null

# 4. 修复建议
echo "4. 安全修复建议:"
echo "- 更改Redis密码"
echo "- 检查ACL配置"
echo "- 更新防火墙规则"
echo "- 检查系统用户账户"
echo "- 扫描恶意软件"
echo "- 更新Redis到最新版本"

echo "应急响应完成，详细日志: $INCIDENT_LOG"
```
