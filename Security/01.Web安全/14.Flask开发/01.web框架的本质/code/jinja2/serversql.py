import pymysql
from wsgiref.simple_server import make_server
from jinja2 import Template

def index(name,hobby):
    with open("index.html", "r", encoding='utf-8') as f:
        data = f.read()
    template = Template(data)
    ret = template.render({"name":name, "hobby_list":hobby})
    return [bytes(ret, encoding="utf-8"),]

URL_LIST = [
    ("/index/", index),
]

def run_server(environ, start_response):
    conn = pymysql.connect(
        host="127.0.0.1",
        port=3306,
        user="root",
        passwd="test123",
        db="pywebdb",
        charset="utf8"
    )
    cursor = conn.cursor()
    cursor.execute('select * from user')
    data = cursor.fetchone()
    name=data[1]
    hobby=data[2]
    conn.close()
    start_response('200 OK', [('Content-Type', 'text/html;charset=utf8'),])
    url = environ['PATH_INFO']
    func = None
    for i in URL_LIST:
        if i[0] == url:
            func = i[1]
            break
    if func:
        return func(name,hobby)
    else:
        return [bytes("404没有该页面", encoding="utf8"),]

if __name__ == '__main__':
    http = make_server('',8000,run_server)
    print("Serving HTTP on port 8000...")
    http.serve_forever()


