# Ghost 搭建个人博客

> Ghost 是一款基于node.js的个人博客系统，貌似是wordpress创始人整的新活，wordpress架构确实比较老旧，很多地方还是使用的链接拼接的方式实现URL的书写，所以再反向代理的时候就会很麻烦，而且制作组也说过把wordpress放在反向代理后面不管他们的事。加之wordpress对markdown的支持实在鸡肋，所以我 ~~因为太菜~~放弃了wordpress，转向更轻量的ghost

![image-20210318235615006](Ghost.assets/image-20210318235615006.png)

ghost对markdown的支持以及对反向代理的支持很好的满足了我这种菜逼的需求，界面非常简介，而且可以一键导出自己的所有博客，也算是不错的解决了迁移这个让人头大的问题，而且页面可以自定义，可玩性也是完全不逊于wordpress只要你懂前端，基本上没什么花花是搞不了的。唯一的缺点可能就是对中文使用者不太友好了

## Ghost Installation

还是docker安装，应为涉及图片存储（尽量不要把图片存在ghost中，采用引用图床的方式会比较好，这样导出的时候你的post都全是文字信息，和链接，有效避免了图像的导入导出）所以还是推荐使用 -v 把内部文件挂载出来方便之后升级

```shell
docker run -itd
--name ghost 
--net=OscarsNet
-v /home/docker/ghost/appdata:/var/lib/ghost/content
-e url=http://some-ghost.example.com
-p 82:2368
ghost
```

```shell
#复制区
docker run -itd --name ghost --net=OscarsNet -v /home/docker/ghost/appdata:/var/lib/ghost/content -e url=http://192.168.1.92:82 -p 82:2368 ghost
```

