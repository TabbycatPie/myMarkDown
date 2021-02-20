#!/bin/bash
#新建数据库
read -p 'ROOT password for MariaDB:'password
read -p 'Local port for MariaDB:'port_num

#create dockers
echo 'Creating test dockers'

docker run -itd --name=mariadb_main --network=OscarsNet -e MYSQL_ROOT_PASSWORD=$password -v /home/docker/mariadb_main/appconfig:/etc/mysql -v /home/docker/mariadb_main/appdata:/var/lib/mysql -p $port_num:3306 mariadb

docker run -d --name=mariadb_test -e MYSQL_ROOT_PASSWORD=$password mariadb

#copy data
docker cp mariadb_test:/etc/mysql /home/docker/mariadb_main/appconfig

#clean
echo 'cleaning'
docker rm -f mariadb_test
cd /home/docker/mariadb_main/appconfig/mysql
mv ./* ../ 
rm -rf /home/docker/mariadb_main/appconfig/mysql

#为Nextcloud 创建用户、数据库，并分配权限

MYSQL_USER_NAME='root'       

docker exec -it mariadb_main mysql -u$MYSQL_UER_NAME -p$password -e "CREATE DATABASE nextcloud_db;CREAT USER nextcloud_user@localhost identified by \'nextcloudpasswd\';GRANT ALL PRIVILEGES ON nextcloud_db.* TO nextcloud_user@localhost IDENTIFIED BY \'nextcloudpasswd\';EXIT;"

if [$? -ne 0];then
    echo "Failed!"
    exit 1;
else
    echo "Created"
    echo "DataBase   : nextcloud_db"
    echo "User       : nextcloud_user"
    echo "Password   : nextcloudpasswd"
fi