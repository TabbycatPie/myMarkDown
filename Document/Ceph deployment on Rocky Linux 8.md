# Ceph deployment on Rocky Linux 8

* Upgrade Kernel
* Install GUI [Optional]
* Beautify GUI [Optional]
* Disable firewall
* Install docker
* Install chrony for time sync
* Install Cephadm



## Upgrade Kernel

Install latest kernel makes the HBA card functional on Ceph OSDs

#### Step1: Update Repos

```shel
yum update -y
yum install -y vim wget python3 epel-release lsscsi podman net-tools
```



#### Step2: Enable ELRepo Repository

```shell
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install -y https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
```



#### Step3: Install Latest Linux Kernel & Reboot

```shell
yum --enablerepo=elrepo-kernel install kernel-ml
reboot
```

#### Tips

If your system boots up with another kernel, you may want to set the default kernel, here is how to do it.

##### Step1: Check The Default Kernel

```shell
grubby --default-kernel
```



##### Step2: Set 5.x Kernel As Default & Reboot

```shell
grubby --set-default /boot/vmlinuz-5.19.10-1.el8.elrepo.x86_64
reboot
```



## Install GUI

It's Optional to install the Graphic User Interface

#### Step 1: Install GNOME Desktop

```shell
yum groupinstall -y "Server with GUI"
```



#### Step2: Enable GUI & Reboot

```she
systemctl set-default graphical
reboot
```



### Disable Firewall

```shell
systemctl stop firewalld.service
systemctl disable firewalld.service
```



### Disable SELinux

```shell
vim /etc/selinux/config
#Change follow parameter to disabled
#SELINUX=enforce
SELINUX=disabled
```





### Beautify GUI

[Optional]

#### Step1: Install Essential Packages

```shell
yum install -y gnome-tweak-tool 
yum install -y gnome-shell-extension-* 
yum install -y papirus-icon-theme
```



### Install Docker

#### Step1: Install Docker on EVERY CLIENT

```shell
yum install -y docker
```



### Install Chrony

#### Step1: Install Chrony

```shell
yum install -y chrony
systemctl enable chronyd
```



#### Step2: Edit config file (Server)

```shell
vim /etc/chrony.conf
```

The file should be changed to this:

```shell
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# pool 2.rhel.pool.ntp.org iburst
server ntp2.nim.ac.cn iburst
server time2.aliyun.com iburst
server time4.cloud.tencent.com iburst
server time.apple.com iburst

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
allow 10.10.10.0/24 

# Serve time even if not synchronized to a time source.
#local stratum 10

# Specify file containing keys for NTP authentication.
keyfile /etc/chrony.keys

# Get TAI-UTC offset and leap seconds from the system tz database.
leapsectz right/UTC
```

Start chrony

```shell
systemctl restart chronyd
```

Config firewall

```shell
firewall-cmd --permanent --add-service=chronyd
firewall-cmd --reload
```

Usage (common commands)

```shell
date -s '20200101 00:00:00' 								 #Change date to a wrong date
timedatectl set-timezone "Asia/Shanghai" 		 #Change timezone to Shanghai
timedatectl set-ntp true/flase               #Turn NTP ON/OFF
chronyc sources                              #Maual Sync
```



#### Step3: Edit config file (Client)

```shell
vim /etc/chrony.conf
```

The file should be changed to this:

```shell
# Use public servers from the pool.ntp.org project.
# Please consider joining the pool (http://www.pool.ntp.org/join.html).
# pool 2.rhel.pool.ntp.org iburst
server ceph01 iburst

# Record the rate at which the system clock gains/losses time.
driftfile /var/lib/chrony/drift

# Allow the system clock to be stepped in the first three updates
# if its offset is larger than 1 second.
makestep 1.0 3

# Enable kernel synchronization of the real-time clock (RTC).
rtcsync

# Enable hardware timestamping on all interfaces that support it.
#hwtimestamp *

# Increase the minimum number of selectable sources required to adjust
# the system clock.
#minsources 2

# Allow NTP client access from local network.
allow ceph01

# Serve time even if not synchronized to a time source.
#local stratum 10

# Specify file containing keys for NTP authentication.
keyfile /etc/chrony.keys

# Get TAI-UTC offset and leap seconds from the system tz database.
leapsectz right/UTC
```

Start chrony

```shell
firewall-cmd --add-service=ntp --permanent
firewall-cmd --reload
systemctl restart chronyd
```



### Install Cephadm

#### Step1: Add Repos

Download install file and make it executable

```shell
curl --silent --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
chmod +x cephadm
```

Add repo by executing cephadm

```shell
./cephadm add-repo --release pacific #quincy
```



#### Step2: Install cephadm

```shell
yum -y install cephadm
```



### Step3: Running The Bootstrap Command

```shell
cephadm bootstrap --mon-ip 10.10.10.134
```



#### Step4: Copy Key File To Other Nodes

```shell
for i in ceph01 ceph02 ceph03 ceph04
do 
scp /etc/ceph/ceph.pub root@$i:/root/.ssh/authorized_keys
done
```



#### Step5: Install LVM2 On Storage Nodes

```shell
yum install -y lvm2
```



#### Step6: Edit hosts File

```shell
vim /etc/hosts
```

Add the following to the end

```shell
10.10.10.134 ceph01
10.10.10.128 ceph02
10.10.10.108 ceph03
10.10.10.232 ceph04
```



#### Step7:Expand The Cluster

wait until the information comes out

```shell 
Ceph Dashboard is now available at:

	     URL: https://ceph01:8443/
	    User: admin
	Password: 8ysw5y3la9

Enabling client.admin keyring and conf on hosts with "admin" label
Saving cluster configuration to /var/lib/ceph/6bc72926-494f-11ed-b333-d61ffd39ab2a/config directory
Enabling autotune for osd_memory_target
You can access the Ceph CLI as following in case of multi-cluster or non-default config:

	sudo /usr/sbin/cephadm shell --fsid 6bc72926-494f-11ed-b333-d61ffd39ab2a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

Or, if you are only running a single cluster on this host:

	sudo /usr/sbin/cephadm shell

Please consider enabling telemetry to help improve Ceph:

	ceph telemetry on

For more information see:

	https://docs.ceph.com/docs/master/mgr/telemetry/
```

