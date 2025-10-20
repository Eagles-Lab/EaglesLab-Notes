db = {'wwc':'123456', 'xwz':'654321'}
li = []
for i in db:
    li.append(i)

n = 3
flag = False
while n:
    if not flag:
        name = input("用户名：")
    password = input("密码：")
    if name not in li and not flag:
        print('没有这个用户')
    elif password != db[name]:
        flag = True
        print('密码错误')
        n -= 1
        if n != 0:
            print('还有%s次机会' % (n,))
    else:
        print('登录成功')
        n = 0
input('输入回车退出')
