import socket
from threading import Thread
import time

sk = socket.socket()
sk.bind(('127.0.0.1',8080))
sk.listen()
def func1(conn):
    with open('test.html', 'r',encoding="utf-8") as f:
        f_data = f.read()
        now = str(time.time())
        f_data = f_data.replace("@@666@@",now).encode('utf-8')
    conn.send(f_data)
    conn.close()
def func2(conn):
    with open('logo.png', 'rb') as f:
        f_data = f.read()
    conn.send(f_data)
    conn.close()

while 1:
    conn,addr = sk.accept()
    b_msg = conn.recv(1024)
    str_msg = b_msg.decode('utf-8')
    path = str_msg.split('\r\n')[0].split(' ')[1]
    print('path>>>',path)
    conn.send(b'HTTP/1.1 200 ok \r\n\r\n')
    if path == '/':
        t = Thread(target=func1,args=(conn,))
        t.start()
    elif path == '/logo.png':
        t = Thread(target=func2,args=(conn,))
        t.start()
sk.close()