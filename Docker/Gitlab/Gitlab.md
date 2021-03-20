# Gitlab 服务部署

> gitlab就是私人github,github国内比较慢

![image-20210320180229292](Gitlab.assets/image-20210320180229292.png)

## Installation

还是docker

```shell
docker run -itd 
--name gitlab 
--net=OscarsNet
-p 4444:443 
-p 83:80 
-p 2222:22 
-v /home/docker/gitlab/appconfig:/etc/gitlab 
-v /home/docker/gitlab/applogs:/var/log/gitlab 
-v /home/docker/gitlab/appdata:/var/opt/gitlab 
gitlab/gitlab-ce
```

```shell
#复制区
docker run -itd --name gitlab --net=OscarsNet -p 4444:443 -p 83:80 -p 2222:22 -v /home/docker/gitlab/appconfig:/etc/gitlab -v /home/docker/gitlab/applogs:/var/log/gitlab -v /home/docker/gitlab/appdata:/var/opt/gitlab gitlab/gitlab-ce
```



