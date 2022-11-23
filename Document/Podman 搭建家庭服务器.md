# Podman 搭建家庭服务器（RockyLinux8）

Docker被红帽弃用了，改用Podman，命令几乎一样，但是有些坑，重新搭建一次NAS环境

## 准备

1. 先安装一下podman环境

```shell
yum install -y podman
#或者 yum install -y docker :)
```

2. podman需要安装dnsmasq和dnsname plugin才能提供容器间的相互解析,dnsname plugin 需要golang环境和git才能编译，反正在rockylinux8上是这样的，不知道算不算一个坑吧

   > 参考 https://github.com/containers/dnsname/blob/main/README_PODMAN.md

```shell
yum install -y make golang dnsmasq git wget
```

3. 下载dnsname源码，并编译安装

```shell
git clone https://github.com/containers/dnsname.git
cd dnsname
make
make install 
```

3. 创建一个自定义网络

```shell
podman network create --driver bridge --subnet 172.172.172.0/24 --gateway 172.172.172.1 OscarsNet
```

4. 查看网络属性看到 ***"dns_enabled": true*** 则正确

```shell
podman network inspect OscarsNet
#------Output-------
[
     {
          "name": "OscarsNet",
          "id": "f32c601868c0a9c5b82f27b9b24f229595792d5a4e25a2d091262f758cad8bcf",
          "driver": "bridge",
          "network_interface": "cni-podman1",
          "created": "2022-10-20T02:27:14.840995344+08:00",
          "subnets": [
               {
                    "subnet": "172.172.172.0/24",
                    "gateway": "172.172.172.1"
               }
          ],
          "ipv6_enabled": false,
          "internal": false,
          "dns_enabled": true, #此项为true则配置正确
          "ipam_options": {
               "driver": "host-local"
          }
     }
]
```

5. 建立文件夹

```shell
cd /home
mkdir /Docker
cd Docker
mkdir -p MariaDB/AppData
mkdir -p MariaDB/AppConfig
mkdir -p NextCloud/AppData
mkdir -p NextCloud/AppConfig
mkdir -p LetsEncrypt/AppData
mkdir -p LetsEncrypt/AppConfig
mkdir -p qBittorrent/AppData
mkdir -p qBittorrent/AppConfig
mkdir -p JellyFin/AppData
mkdir -p JellyFin/AppConfig
mkdir -p BaiduNetDisk/AppData
mkdir -p BaiduNetDisk/AppConfig
mkdir -p XunLei/AppData
mkdir -p XunLei/AppConfig
mkdir -p Calibre/AppData
mkdir -p Calibre/AppConfig
```



## MariaDB

先搭建MariaDB，很多开源项目都是基于mysql的，Mysql被收购之后分出了Maria，故事不长但是也不讲了

1. 直接运行，拉取需要时间，等待即可，数据库root密码，卷、端口映射自行安排

```shell
podman run -itd --name=MariaDB --network=OscarsNet -e MYSQL_ROOT_PASSWORD='< your password here >' -v /home/Docker/MariaDB/AppConfig:/etc/mysql -v /home/Docker/MariaDB/AppData:/var/lib/mysql -p 3306:3306 mariadb
```

2. 检查容器是否运行，并进入容器

```shell
podman ps
podman exec -it MariaDB bash
```

3. 以root身份进入sql命令行，新建数据库，用户，并分配权限

```shell
mysql -u root
#输入密码
```

```sql
CREATE DATABASE nextcloud_db;
CREATE USER 'nextcloud_user'@'%' identified by 'nextcloudpasswd';
GRANT ALL PRIVILEGES ON nextcloud_db.* TO 'nextcloud_user'@'%' IDENTIFIED BY 'nextcloudpasswd';  
FLUSH PRIVILEGES;
EXIT;
```

## NextCloud

退回宿主机，继续安装NextCloud 老规矩，卷、端口映射自行安排

```shell
podman run -itd --name=NextCloud --network=OscarsNet -v /home/Docker/NextCloud/AppConfig:/var/www/html -v /home/Data/NextCloud:/var/www/html/data -v /home/Data/SMB:/home/Data/SMB -p 81:80 nextcloud
```

然后进入对应地址 81端口进行配置即可

配置的时候选择数据库为MariaDB,按照上面的配置填写即可

用户名：nextcloud_user

密码    ：nextcloudpasswd

数据库：nextcloud_db

地址    ：MariaDB:3306  （这里应为开启了容器间域名解析所以直接填写数据库容器名即可解析获得ip）

### 补充

如果是NextCloud数据迁移的话也比较简单

1. 吧文件复制到 NextCloud根目录（有一个名字叫occ的文件）/用户名/files下面
2. 用www-data（NextCloud默认这个用户，uid为33）执行occ文件扫描，等待完成即可

```shell
podman exec -it -u 33 NextCloud bash
php occ files:scan --all
#php occ files:scan --<用户名> 单独扫描一个用户的文件

```

还有就是cifs挂载的时候需要注意，修改fstab之后需要吧目录权限和文件权限全部改为0770，uid、pid改为33不然nextcloud会因为权限问题报错，我的fstab是这样配置的

```shell
//192.168.3.2/DataSMB /home/Data cifs defaults,username=< your smb username here >,password=< your smb password here >,uid=33,gid=33,dir_mode=0770,file_mode=0770 0 0
```

如果是使用NFS的话挂载语句如下，添加到/etc/fstab即可

```shell
192.168.3.2:/mnt/MainPool/DataNFS/Docker /home/Docker nfs defaults 0 0
```

开机自动挂载后无法修改，修改fstab后记得 mount -all测试一下免得起不来

## LetsEncrypt

需要这个容器作反向代理，然后提供免费https的ca证书，而且会自动更新，参考一个up的方案https://www.bilibili.com/video/BV1eZ4y1g7vp/?spm_id_from=333.999.0.0&vd_source=d098c017639535259be4a5ba485becf7

1. 创建容器并运行，这里需要替换 EMAIL 和 URL等多个参数，不要全部复制

```shell
podman run -itd --cap-add=NET_ADMIN --name=LetsEncrypt --net=OscarsNet -v /home/Docker/LetsEncrypt/AppConfig/:/config:rw -e PGID=1000 -e PUID=1000 -e EMAIL=< your email here > -e URL=< your top domain name here > -e SUBDOMAINS=gitlab,cloud,jellyfin,blog -e ONLY_SUBDOMAINS=true -e DHLEVEL=2048 -e VALIDATION=dns -e DNSPLUGIN=aliyun -p '8088:80/tcp' -p '2443:443/tcp'  -e TZ=Asia/Shanghai linuxserver/letsencrypt
```

​	参数有点多，需要解释一下

```shell
podman run 
  -itd     									
  --cap-add=NET_ADMIN      
  --name=LetsEncrypt        
  --net=OscarsNet         #添加到自定义网络
  -v /home/Docker/LetsEncrypt/AppConfig/:/config:rw
  							#卷映射(自己安排)
  -e PGID=1000 
  -e PUID=1000 
  -e EMAIL=oscar@qq.com     #颁发ca是需要的email
  -e URL=baidu.cmo          #你的顶级域名
  -e SUBDOMAINS=chat,qq,baidu  #子域名
  -e ONLY_SUBDOMAINS=true   #只为子域名申请ssl证书
  -e DHLEVEL=2048           
  -e VALIDATION=dns 			#使用dns验证（保持不变即可）
  -e DNSPLUGIN=aliyun 		#dns验证插件（保持不变即可）
  -p '8088:80/tcp'         
  -p '2443:443/tcp'         #端口映射
  -e TZ=Asia/Shanghai       #时区选择
  linuxserver/letsencrypt
```

2. 进入配置文件夹，配置阿里云API（ISP封端口会导致证书验证失败，需要绕开80、443端口的验证）,之后重启容器，并查看日志

```shell
vim /home/Docker/LetsEncrypt/AppConfig/dns-conf/aliyun.ini
#填写你的Aliyun API key 和密钥,保存退出
podman restart LetsEncrypt
podman logs -f LetsEncrypt
#看到Server ready就说明服务已经启动了
```

3. https访问2443端口会显示一个Welcome to our server就OK了

之后配置nextcloud反代

1. 修改容器内/nginx/proxy-confs/下配置文件内容

```shell
cd /home/Docker/LetsEncrypt/AppConfig/nginx/proxy-confs #此路径为宿主机映射路径
cp nextcloud.subdomain.conf.sample nextcloud.subdomain.conf #备份文件
vim nextcloud.subdomain.conf
```

```shell
## Version 2020/12/09
# make sure that your dns has a cname set for nextcloud
# assuming this container is called "swag", edit your nextcloud container's config
# located at /config/www/nextcloud/config/config.php and add the following lines before the ");":
#  'trusted_proxies' => ['swag'],
#  'overwrite.cli.url' => 'https://nextcloud.your-domain.com/',
#  'overwritehost' => 'nextcloud.your-domain.com',
#  'overwriteprotocol' => 'https',
#
# Also don't forget to add your domain name to the trusted domains array. It should look somewhat like this:
#  array (
#    0 => '192.168.0.1:444', # This line may look different on your setup, don't modify it.
#    1 => 'nextcloud.your-domain.com',
#  ),

server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name cloud.*; #这里修改为你的子域名

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        resolver 172.172.172.1 valid=30s; #根据自己的情况 可以进入容器中使用nslookup查看dns服务器地址
        set $upstream_app NextCloud; #注意这里是内网容器名
        set $upstream_port 80;       #内网服务端口
        set $upstream_proto http;    #内网协议，注意是内网，别搞混了！！
        proxy_pass $upstream_proto://$upstream_app:$upstream_port; #内网内网上面变量拼起来就是你的nextcloud地址

        proxy_max_temp_file_size 2048m;
    }
}
```

Jellyfin的文件需要注意dns解析那里填写对应的dns服务器

```shell
server {
    listen 443 ssl;
    listen [::]:443 ssl;

    server_name jellyfin.*;

    include /config/nginx/ssl.conf;

    client_max_body_size 0;

    location / {
        include /config/nginx/proxy.conf;
        resolver 172.172.172.1 valid=30s;#这里填写dns服务器名字，如果网络创建跟我的一样这里写172.172.172.1就可以了
        set $upstream_app JellyFin; #这里是容器的名字
        set $upstream_port 8096;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

        proxy_set_header Range $http_range;
        proxy_set_header If-Range $http_if_range;
    }

    location ~ (/jellyfin)?/socket {
        include /config/nginx/proxy.conf;
        resolver 172.172.172.1 valid=30s; #这里跟上面一样需要修改
        set $upstream_app JellyFin;  #这里是容器的名字
        set $upstream_port 8096;
        set $upstream_proto http;
        proxy_pass $upstream_proto://$upstream_app:$upstream_port;

    }
}
```



按照配置文件修改nextcloud配置文件

```shell
cd /home/Docker/NextCloud/AppConfig/config
```

修改config.php

```shell
  'htaccess.RewriteBase' => '/',
  'memcache.local' => '\\OC\\Memcache\\APCu',
  'apps_paths' =>
  array (
    0 =>
    array (
      'path' => '/var/www/html/apps',
      'url' => '/apps',
      'writable' => false,
    ),
    1 =>
    array (
      'path' => '/var/www/html/custom_apps',
      'url' => '/custom_apps',
      'writable' => true,
    ),
  ),
  'instanceid' => 'ocy7cq1gl4s5',
  'passwordsalt' => 'pnWgxLrzI52Q168Uv/aEy6R7yRCIax',
  'secret' => '6Oimx7+80UM2nrICdm+DT5OSaX0rxHmW7TNWhLy+4+acBRf6',
  'trusted_domains' =>
  array (
          0 => '192.168.3.9:81',
          1 => 'cloud.caliburn.work:8888', #这里添加
  ),
  'datadirectory' => '/var/www/html/data',
  'dbtype' => 'mysql',
  'version' => '24.0.6.1',
  'overwrite.cli.url' => 'http://192.168.3.9:81',
  'dbname' => 'nextcloud_db',
  'dbhost' => 'MariaDB:3306',
  'dbport' => '',
  'dbtableprefix' => 'oc_',
  'mysql.utf8mb4' => true,
  'dbuser' => 'nextcloud_user',
  'dbpassword' => 'nextcloudpasswd',
  'installed' => true,
  #后面的加在里面就可以了
  'trusted_proxies' => ['LetsEncrypt'],
  'overwrite.cli.url' => 'https://cloud.caliburn.work:8888/',
  'overwritehost' => 'cloud.caliburn.work:8888',
  'overwriteprotocol' => 'https',
);
```

重启容器

```shell
podman restart NextCloud
podman restart LetsEncrypt
```

## Jellyfin

影音管理软件，有ffmepg，可以利用CPU、显卡进行解码串流，唯一的缺点是对中文的支持不是很好，创建容器时需要用--device把本地的显卡交给容器，我这里是intel的集显，AMD或者绿厂的可以百度一下方案，具体原理类似，卷映射还是自行修改

因为有中文字体问题所以需要先把linux中的字体文件给到Jellyfin，最后是吧windows里面的字体考过来才解决的

```shell
cp -r /usr/share/fonts/* /home/Docker/JellyFin/AppData
```

```shell
podman run -itd --name=JellyFin --network=OscarsNet -p 8096:8096 -v /home/Docker/JellyFin/AppData:/usr/share/fonts/truetype -v /home/Data/SMB/Media:/home/Data -v /home/Docker/JellyFin/AppConfig:/config --device /dev/dri/card0:/dev/dri/card0 --device /dev/dri/renderD128:/dev/dri/renderD128 jellyfin/jellyfin		
```

还有一个单击演员转圈圈的问题，这个是因为大陆无法访问tmdb的演员信息服务，dns被污染传，可以修改/config/system.xml文件禁用自动信息获取 ，解决方案参考https://github.com/jellyfin/jellyfin/issues/4352

```xml
<!-- 添加在MetadataOptions标签后面 -->
<MetadataOptions>
  <ItemType>Person</ItemType>
  <DisabledMetadataSavers />
  <LocalMetadataReaderOrder />
  <DisabledMetadataFetchers>
    <string>TheMovieDb</string>
  </DisabledMetadataFetchers>
  <MetadataFetcherOrder />
  <DisabledImageFetchers />
  <ImageFetcherOrder />
</MetadataOptions>
   
```



**字体问题需要访问Dashboard>Playback里面有个fall back font设置，选择/usr/share/fonts/truetype还有勾上下面的启用就可以了**

完成之后访问宿主机8096端口进行设置就可以了，还有就是去Dashboard中打开硬件解码

## PhotoPrism

个人照片管理软件，提供AI识别

```shell
podman run -d   --name PhotoPrism --security-opt seccomp=unconfined  --security-opt apparmor=unconfined  -p 2342:2342   -e PHOTOPRISM_UPLOAD_NSFW="true"   -e PHOTOPRISM_ADMIN_PASSWORD="insecure" photoprism/photoprism
```

## qBittorrent

Torrent下载器可下载磁力链接，但是BT经常没速度，还有就是注意这个PUID和PGID下载报错一般都是权限问题，我这里下载文件夹的权限是给33用户的，你的不是就改下

```shell
podman run -d --name=qBittorrent --network=OscarsNet -e PUID=33 -e PGID=33 -e TZ=Aisa/Shanghai -e WEBUI_PORT=8080 -p 8080:8080 -p 6881:6881 -p 6881:6881/udp -v /home/Docker/qBittorrent/AppConfig:/config -v /home/Data/SMB/Download:/downloads lscr.io/linuxserver/qbittorrent:latest
```

创建之后需要添加tracker服务器 提供一个网站 https://github.com/ngosang/trackerslist

添加位置 Tools>Options>BitTorrent>**Automatically add these trackers to new downloads**

添加之后需要开启 Tools>Options>Advanced>***Always announce to all trackers in a tier*** 和 ***Always announce to all tiers*** 两个选项

## BaiduNetDisk

Baidu云盘出了一个docker版，可以一直挂着下载，建议设置vnc密码，一个docker只允许一个人登录

```shell
podman run -itd --name=BaiduNetDisk --network=OscarsNet -e USER_ID=33 -e GROUP_ID=33 -e VNC_PASSWORD=< your vnc password here > -p 5800:5800 -p 5900:5900 -v /home/Docker/BaiduNetDisk/AppConfig:/config -v /home/Data/SMB/Download/BaiduNetDiskDownload:/config/baidunetdiskdownload docker.io/johngong/baidunetdisk
```

## AliyunNetDisk

可以通过webDav挂载阿里云盘到本地，需要一个docker，还有一个比较麻烦的是token，参考https://blog.csdn.net/bigbear00007/article/details/123468792

参数需要讲解下

1. REFRESH_TOKEN参照教程打开浏览器获取
2. WEBDAV_AUTH_USER/PASSWORD :webdav用户名密码挂载的时候有用

打开aliyun盘网页https://www.aliyundrive.com/drive/

F12 打开开发者模式,进入console输入下面代码获取token

~~~js
JSON.parse(window.localStorage["token"]).refresh_token;
~~~

```shell
podman run -itd --name=AliyunDriveWebDav -p 9090:8080 -v /home/Docker/AliyunDisk/AppData:/etc/aliyundrive-webdav/ -e REFRESH_TOKEN='< your aliyun token >' -e WEBDAV_AUTH_USER=< username for dav > -e WEBDAV_AUTH_PASSWORD=< password for dav > messense/aliyundrive-webdav
```

访问9090端口输入刚刚设置的用户名密码之后就可以访问云盘里面的东西了，之后再把webDAV挂载到本地就可以直接操作了

```shell
yum install davfs2
mount -t davfs localhost:9090 /home/webDAV/
```



## 迅雷

迅雷上了群晖，后面有大佬做成了容器https://hub.docker.com/r/cnk3x/xunlei, 默认端口2345

```shell
podman run -d --name=XunLei --hostname=XunleiHome --net=host -v /home/Docker/XunLei/AppData:/xunlei/data -v /home/Data/SMB/Download/XunLeiDownload:/xunlei/downloads --privileged cnk3x/xunlei:latest
```

内测码 ：迅雷牛通

## Calibre

Calibre是一款图书管理软件，出了web版，本人有电子、漫画书分类的需求，所以需要一款管理软件

```shell
podman run -d --name=Calibre -e PUID=33 -e PGID=33 -e TZ=Asia/Shanghai -p 8083:8083 -v /home/Docker/Calibre/AppConfig:/config -v /home/Data/SMB/Media/E-book:/books linuxserver/calibre-web
```

这个镜像的用户名是admin密码是admin123
