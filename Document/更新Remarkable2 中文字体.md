# 更新Remarkable2 中文字体

每次系统更新都会把系统里面的字体重制，所以每次更新系统之后打开中文书籍都是乱码所以这边留一下记录，其实更新很简单的，就是年纪大了会忘记 🥹

1. 用usb线连接上设备，打开wifi
2. 转到 Setting > Help > Copyright and license > 下面可以查看ip地址和root密码
3. 用xshell等软件访问设备的ip，然后连进去shell
4. cd 到 /usr/share/fonts/ttf
5. 把准备好的字体拷贝到这个目录下面
6. 重启，然后把乱码的书籍重新拷贝一次或者调整一下字体大小让设备重新生成一遍就好