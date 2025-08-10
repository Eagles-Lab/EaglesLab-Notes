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