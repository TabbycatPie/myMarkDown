#!/bin/bash
network_name="OscarsNet"
read -p 'Install Mongo db?(y/n)' answer
if [ $answer = 'y' ];then
    read -p 'Installation folder:' installation_path
    if [ ! -d $installation_path ];then
        echo 'Using '$installation_path
    else 
        echo 'Using default setting installtion path = /home/docker/mongodb/'
        installation_path='/home/docker/mongodb/'
        mkdir -p /home/docker/mongodb/appdata
    fi
    # echo 'Creating config data ......'
    # touch $installation_path/mongod.config
    # echo -e '# mongod.conf\n\n# for documentation of all options, see:\n#   http://docs.mongodb.org/manual/reference/configuration-options/\n# Where and how to store data.storage:\n  dbPath: /data/db\n  journal:\nenabled: true\n#  engine:\n#  mmapv1:\n#  wiredTiger:\n\n# network interfaces\n  port: 27017\n  bindIp: 127.0.0.1\n\n# how the process runs\nprocessManagement:\n  timeZoneInfo: /usr/share/zoneinfo\n\n#security:\n#  authorization: "enabled"\n\n#operationProfiling:\n\nreplication:\n  replSetName: "rs01"\n\n#sharding:\n\n## Enterprise-Only Options:\n\n#auditLog:\n\n#snmp:' > $installation_path/mongod.config
    read -p 'Port number:' port_num
    if [ ! -n "$port" ];then
        port='27017'
    fi
    echo 'Installing container ......'
    docker run -itd --name='mongo' --net='OscarsNet' -e TZ="Asia/Shanghai" -p $port_num:27017 -v $installation_path:/data/db mongo
    if [ $? -ne 0 ];then
        echo "Installation Failed!"
        exit 1;
    fi

    echo 'Initializing database ......'
    
fi