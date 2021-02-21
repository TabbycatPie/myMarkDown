#!/bin/bash
#新建数据库
read -p 'ROOT password for MariaDB:' password
read -p 'Local port for MariaDB:' port_num
#networks name
network_name="OscarsNet"

#create network
echo "Creating network"
docker network create --driver bridge --subnet 172.172.0.0/16 --gateway 172.172.0.1 $network_name

#create dockers
echo 'Creating dockers'
docker run -itd --name=mariadb_main --network=$network_name -e MYSQL_ROOT_PASSWORD=$password -v /home/docker/mariadb_main/appconfig:/etc/mysql -v /home/docker/mariadb_main/appdata:/var/lib/mysql -p $port_num:3306 mariadb
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

#等待mariadb容器启动
#wait container start
sleep_time=5
echo "Please wait for "$sleep_time" for container starting ...... "
while [ $sleep_time -gt 0 ]
do
    echo -ne "\r"$sleep_time"s"
    sleep 1
    sleep_time=$(expr $sleep_time - 1)
done

#测试一下哪个变量能看到密码
# echo "password : " $MYSQL_ROOT_PASSWORD
# echo "password : " $password

echo "\rCreating database ...... "
docker exec -it mariadb_main mysql -uroot -p$password -e "CREATE DATABASE nextcloud_db;"
if [ $? -ne 0 ];then
    echo "Creating database Failed!"
    exit 1;
fi
echo "Creating database user ......"
docker exec -it mariadb_main mysql -uroot -p$password -e "CREATE USER nextcloud_user@localhost identified by 'nextcloudpasswd';"
if [ $? -ne 0 ];then
    echo "Creating user Failed!"
    exit 1;
fi
echo "Setting privileges ......"
docker exec -it mariadb_main mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON nextcloud_db.* TO nextcloud_user@localhost IDENTIFIED BY 'nextcloudpasswd';FLUSH PRIVILEGES;"
if [ $? -ne 0 ];then
    echo "Graning privileges Failed!"
    exit 1;
fi
echo "Seting user host ......"
docker exec -it mariadb_main mysql -uroot -p$password -e "USE mysql;UPDATE user SET Host='%' WHERE User='nextcloud_user';"
if [ $? -ne 0 ];then
    echo "seting host Failed!,please set it manully."
fi
echo "Created"
echo "DataBase   : nextcloud_db"
echo "User       : nextcloud_user"
echo "Password   : nextcloudpasswd"


