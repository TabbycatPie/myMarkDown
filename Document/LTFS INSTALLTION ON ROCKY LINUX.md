# LTFS INSTALLTION ON ROCKY LINUX

> LTFS is a Tape file system that can make a tape mount to system like a hard disk
>
> LTFS is open sourced by IBM on github

Git hub URL: https://github.com/LinearTapeFileSystem/ltfs.git



Preparation

```shell
yum install -y automake autoconf libtool make icu libicu-devel libxml2-devel libuuid-devel fuse-devel net-snmp-devel git python3 
```

```shell
alternatives --set python /usr/bin/python3
```

```shell
git clone https://github.com/LinearTapeFileSystem/ltfs.git
cd ltfs
```

```shell
./autogen.sh
./configure
make
make install
```

