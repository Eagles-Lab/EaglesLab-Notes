

```shell
# install mysql 8.0.43
yum install mysql84-community-release-el9-2.noarch.rpm
dnf config-manager --disable mysql-8.4-lts-community
dnf config-manager --disable mysql-tools-8.4-lts-community
dnf config-manager --enable mysql80-community
dnf config-manager --enable mysql-tools-community
yum repolist enabled | grep mysql
yum install mysql-community-server
mysqld -V
grep 'temporary password' /var/log/mysqld.log
mysql -uroot -p
ALTER USER 'root'@'localhost' IDENTIFIED BY 'MyNewPass4!';
show databases;
```