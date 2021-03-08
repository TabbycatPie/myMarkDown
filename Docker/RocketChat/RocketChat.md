# RocketChat安装与配置

![image-20210305231608784](RocketChat.assets/image-20210305231608784.png)

> RocketChat是一款开源免费的聊天服务软件，就是自己做的微信，有服务器就行，聊天数据都保存在自己的服务器上，不用成为xx公司的大数据的一部分了，然后某种程度上可以以脱离相关部门的监管，群里的车速也可以快一点了。话不多说，直接安装

rocketchat依赖于mongodb这个数据库，所以安装rocketchat之前，必须安装上mongodb

## MongoDB的安装

![image-20210305232039513](RocketChat.assets/image-20210305232039513.png)

> MongoDB 是由C++语言编写的，是一个基于分布式文件存储的开源数据库系统。
>
> MongoDB 将数据存储为一个文档，数据结构由键值(key=>value)对组成。MongoDB 文档类似于 JSON 对象。字段值可以包含其他文档，数组及文档数组。
>
> ![img](RocketChat.assets/crud-annotated-document.png)

### 安装并配置MongoDB

复制就可以了

```shell
docker run 
-itd 											#交互模式运行
--name='mongo'  								#容器名
--net='OscarsNet' 								#连接到网络
-e TZ="Asia/Shanghai" 							#时区
-p '27017:27017' 								#端口
-v '/home/docker/mongodb/appdata':'/data/db'    #数据地址
-f /data/db/mongod.conf							#配置文件
```

```shell
#复制区
docker run -itd --name='mongo' --net='OscarsNet' -e TZ="Asia/Shanghai" -p 27017:27017 -v '/home/docker/mongodb/appdata':'/data/db' -f /data/db/mongod.conf
```

之后进入容器内部

```shell
docker exec -it mongo bash
```

然后进入数据库操作

```shell
root@d648adc95578:/# mongo
MongoDB shell version v4.4.3
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("f2c31efc-1e28-4806-b6b9-a2350c026a96") }
MongoDB server version: 4.4.3
---
#以下部分省略
```

在数据据库里面执行下面指令

```shell
rs.initiate()   #初始化
use admin       #切换用户
```

![image-20210307222938414](RocketChat.assets/image-20210307222938414.png)

然后创建数据库root用户

```shell
db.createUser({user:"root",pwd:"oscar123456",roles:[{role:"root",db:"admin"}]})
```

![image-20210307223439436](RocketChat.assets/image-20210307223439436.png)

之后为Rocketchat创建用户并指派角色

```shell
db.createUser({user:"rocketchat",pwd:"rocketchat_pawd",roles:[{role:"readWrite",db:"local"},{role:"dbOwner",db:"rocketchat"}]})
```

安装完成之后可以试一试用navicat连接一下，如果可以连接上就没问题

## Rocketchat Intallation

**名👴名言**：

> ​        虽然不是同一时间，但是确实同一台电脑，我还是那句话，只有你们想不到的没有👴做不到的，你们可以嘲笑👴🐺背不堪，但是👴也可以嘲笑你们，离开你们的脚本，比👴我吃屎还难！

运行下面指令

```shell
docker run 
-itd 								
--name='rocketchat' 
--net='OscarsNet' 
-e TZ="Asia/Shanghai" 

-e 'MONGO_URL'='mongodb://rocketchat:rocketchat_pwd@mongo:27017/rocketchat' 
#这个参数比较重要，分为几个部分，按照URL的标准格式
#<协议>://<用户名>:<密码>@<主机>:<端口>/<路径>?<参数>
#1.<协议>://：mongodb://
#2.<用户名>:<密码>：rocketchat:rocketchat_pwd  数据库的用户密码
#3.@<主机>:<端口号>：@mongo:27017              填写刚刚的mogodb主机名和端口
#4./<路径>：rocketchat                        数据库名称

-e 'ROOT_URL'='https://rocketchat.xxxx.xxx:????' 
#这里填写你的网址 根据需求替换rocketchat.xxxx.xxx:????

-e 'MONGO_OPLOG_URL'='mongodb://rocketchat:rocketchat_pwd@mongo:27017/local?authSource=admin' 
#老规矩URL
#1.<协议>://：mongodb://
#2.<用户名>:<密码>：rocketchat:rocketchat_pwd 数据库的用户密码
#3.@<主机>:<端口号>：@mongo:27017             填写刚刚的mogodb主机名和端口
#4./<路径>： local                           数据库名称


-p 3000:3000 #端口和文件映射就不讲了，很多遍了
-v /home/docker/rocketchat/appconfig:/app/uploads
rocketchat/rocket.chat
```

```shell
#复制区
docker run -itd --name='rocketchat' --net='OscarsNet' -e TZ="Asia/Shanghai" -e 'MONGO_URL'='mongodb://rocketchat:rocketchat_pwd@mongo:27017/rocketchat' -e 'ROOT_URL'='https://rocketchat.xxxx.xxx:????' -e 'MONGO_OPLOG_URL'='mongodb://rocketchat:rocketchat_pwd@mongo:27017/local?authSource=admin' -p 3000:3000 -v /home/docker/rocketchat/appconfig:/app/uploads rocketchat/rocket.chat
```

