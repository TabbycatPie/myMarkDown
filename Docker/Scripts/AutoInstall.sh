#!/bin/bash
network_name="OscarsNet"
read -p "Install MariaDB? (y/n):" answer
if [ $answer == 'y' ];then
    #开始安装数据库
    read -p 'ROOT password for MariaDB:' password
    read -p 'Local port for MariaDB:' port_num
    #networks name

    #create network
    echo "Creating network ......"
    docker network create --driver bridge --subnet 172.172.0.0/16 --gateway 172.172.0.1 $network_name

    #create dockers
    echo 'Creating mariadb container ......'
    docker run -itd --name=mariadb_main --network=$network_name -e MYSQL_ROOT_PASSWORD=$password -v /home/docker/mariadb_main/appconfig:/etc/mysql -v /home/docker/mariadb_main/appdata:/var/lib/mysql -p $port_num:3306 mariadb
    docker run -d --name=mariadb_test -e MYSQL_ROOT_PASSWORD=$password mariadb

    #copy data
    docker cp mariadb_test:/etc/mysql /home/docker/mariadb_main/appconfig

    #clean
    echo 'cleaning ......'
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

    echo "Creating database ...... "
    docker exec -it mariadb_main mysql -uroot -p$password -e "CREATE DATABASE nextcloud_db;"
    if [ $? -ne 0 ];then
        echo "Creating database Failed!"
        exit 1;
    fi
    echo "Creating database user ......"
    docker exec -it mariadb_main mysql -uroot -p$password -e "CREATE USER 'nextcloud_user'@'%' identified by 'nextcloudpasswd';"
    if [ $? -ne 0 ];then
        echo "Creating user Failed!"
        exit 1;
    fi
    echo "Setting privileges ......"
    docker exec -it mariadb_main mysql -uroot -p$password -e "GRANT ALL PRIVILEGES ON nextcloud_db.* TO 'nextcloud_user'@'%' IDENTIFIED BY 'nextcloudpasswd';FLUSH PRIVILEGES;"
    if [ $? -ne 0 ];then
        echo "Graning privileges Failed!"
        exit 1;
    fi
    echo "Created"
    echo "DataBase   : nextcloud_db"
    echo "User       : nextcloud_user"
    echo "Password   : nextcloudpasswd"
    echo "Entry localhost:"$port" to access"
fi
# 安装Nextcloud 
read -p "Install Nextcloud? (y/n):" answer
if [ $answer == 'y' ];then
    #install nextcloud
    read -p 'Directory of your data:' data_path
    if [ ! -e data_path ];then
        echo $data_path" does not exist,using the default '/home/NextCloud' instead."
        mkdir /home/NextCloud
        data_path='/home/NextCloud'
    fi
    read -p 'Local port for nextcloud:' port

    echo "Creating nextcloud container ......"
    docker run -itd --name=nextcloud_main --network=$network_name -v /home/docker/nextcloud/appconfig:/var/www/html -v $data_path:/var/www/html/data -v /home/Data:/home/Data -p $port:80 nextcloud
    if [ $? -ne 0 ];then
        echo "Installation Failed!"
        exit 1;
    fi
    
    echo "Nextcloud installed!"
    echo "Entry localhost:"$port" to access"
fi

#安装LetsEncrypt
read -p 'Install LetsEncrypt?(y/n):' answer
if [ $answer == 'y' ];then
    port=''
    read -p 'Please enter your email:' email_address
    read -p "Please enter your top domain (e.g:baidu.com):" top_domain_name
    read -p "Please enter your subdomains dviding by ',' (e.g:www,cloud,chat) :" sub_domain_name
    read -p "What port do you want to expose for port 80  inside contianer (default：8088):" port
    if [ ! -n "$port" ];then
        port='8088'
    fi
    read -p "What port do you want to expose for port 443 inside contianer (default：2443):" port2
    if [ ! -n "$port2" ];then
        port2='2443'
    fi
    read -p "What time zone do you belong to（default：Asia/Shanghai):" time_zone
    if [ ! -n "$time_zone" ];then
        time_zone='Asia/Shanghai'
    fi
    docker run -itd --cap-add=NET_ADMIN --name=letsencrypt --net=$network_name -v /home/docker/letsencrypt/appconfig:/config:rw -e PGID=1000 -e PUID=1000 -e EMAIL=$email_address -e URL=$top_domain_name -e SUBDOMAINS=$sub_domain_name -e ONLY_SUBDOMAINS=false -e DHLEVEL=2048 -e VALIDATION=dns -e DNSPLUGIN=aliyun -p $port:80  -p $port2:443  -e TZ=$time_zone linuxserver/letsencrypt
    echo "Installed LetsEncrypt!"
    echo "Entry URL https://localhost:$port2 to access"
fi