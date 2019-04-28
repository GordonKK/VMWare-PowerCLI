#!/bin/bash
#rsync -avz init.sh root@10.10.70.223:/root/init.sh
THE_ENV=$1
IP=$2
HOST_NAME=$3
#log_file='/root/init.log'
#sleep 15
#sleep 10

usage(){
        echo 'use such as: sh init.sh ENV(st1,st2,st3,sandbox,dev) IP HOSTNAME'
}
zabbix_info(){
	echo "zabbix setting"
	if [ "${THE_ENV}" == "st2" -o "${THE_ENV}" == "sandbox" ]
	then
		zabbix_env="st2"
	elif [ "${THE_ENV}" == "st3" ]
	then
		zabbix_env="st3"
	else
		zabbix_env="None"
	fi	
	echo "rsync -avz zabbix_agent/${zabbix_env}/zabbix/ /usr/local/zabbix/"
	rsync -avz zabbix_agent/${zabbix_env}/zabbix/ /usr/local/zabbix/
	echo "/usr/local/zabbix/sbin/zabbix_agentd -c /usr/local/zabbix/conf/zabbix_agentd.conf" >> /etc/rc.local
	#sed -i "s/^Hostname=.*/Hostname=${IP}/g" /usr/local/zabbix/conf/zabbix_agentd.conf
    killall -9 zabbix_agentd
    chkconfig zabbix_agentd off
    /usr/local/zabbix/sbin/zabbix_agentd -c /usr/local/zabbix/conf/zabbix_agentd.conf
}

tomcat_info(){
	echo "tomcat setting"
	echo -e "# nfs mount
${nfs_path}
# script mount
${script_path}
# start tomcat
su - oracle -c \". /opt/script/tomcat-manage/as.tomcat.env ;sh /opt/script/tomcat-manage/tomcat startall\"">>/etc/rc.local
}

if [ "$#" -lt 3 ];then usage;exit ;fi

shift 3
APP=$*

cd `dirname $0`
if [ "${THE_ENV}" != "st1" -a "${THE_ENV}" != "st2"  -a "${THE_ENV}" != "st3" -a "${THE_ENV}" != "sandbox" -a "${THE_ENV}" != "dev" -a "${THE_ENV}" != "nj" ]
then
    echo -e "\033[31mERROR！Environment not exist\033[0m"
    usage
    exit
fi
#### network
SEGMENT=$(echo ${IP}|awk -F. '{print $1"."$2"."$3}')
BROADCAST="${SEGMENT}.255"
if [ "${THE_ENV}" == "nj" ] 
    then GATEWAY="${SEGMENT}.1"
else
    GATEWAY="${SEGMENT}.254"
fi
NETWORK="${SEGMENT}.0"
NETWORKFILE='/etc/sysconfig/network-scripts/ifcfg-eth0'

cat >${NETWORKFILE} <<EOF
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
IPADDR=$IP
BROADCAST=$BROADCAST
NETMASK=255.255.255.0
NETWORK=$NETWORK
GATEWAY=$GATEWAY
EOF

#### hostname
cat >/etc/sysconfig/network <<EOF
NETWORKING=yes
NETWORKING_IPV6=no
HOSTNAME=${HOST_NAME}
EOF
hostname ${HOST_NAME}

cat >/etc/hosts <<EOF
# Do not remove the following line, or various programs
# that require network functionality will fail.
127.0.0.1               localhost.localdomain localhost
${IP}		${HOST_NAME}
EOF

#### ssh key pub
if [ "${THE_ENV}" == "nj" ] 
then THE_ENV="dev"
fi
if [ ! -d /root/.ssh ];then mkdir /root/.ssh;fi
if [ ! -d /home/oracle/.ssh ];then mkdir /home/oracle/.ssh;fi
cat SSH_KEY_FILES/${THE_ENV}/root/authorized_keys >/root/.ssh/authorized_keys
cat SSH_KEY_FILES/${THE_ENV}/oracle/authorized_keys >/home/oracle/.ssh/authorized_keys
chmod 700 /root/.ssh;chmod 600 /root/.ssh/authorized_keys
chmod 700 /home/oracle/.ssh;chmod 600 /home/oracle/.ssh/authorized_keys
chown -R oracle:oinstall /home/oracle/.ssh
./p_env.sh.x ${THE_ENV}

#### rc.local
echo -e "#!/bin/sh
#
# This script will be executed *after* all the other init scripts.
# You can put your own initialization stuff in here if you don't
# want to do the full Sys V style init stuff.
touch /var/lock/subsys/local
# ntpdate
sh /opt/idc_script/ntpdate.sh">/etc/rc.local

#### dns mount 
case ${THE_ENV} in
	st1)
	nfs_path="mount -o rw 192.168.65.1:/opt/export/bill99/stage1_nfs/stage1_vm/nfs /nfs/"
	script_path="mount -o rw 192.168.65.1:/opt/script /opt/script"
	echo -e "search 99bill.com
nameserver 192.168.65.77">/etc/resolv.conf
	;;
	st2)
	nfs_path="mount -o rw 192.168.63.150:/data1/nfs/ST2/nfs /nfs/"
	script_path="mount 192.168.63.219:/opt/script /opt/script"
	echo -e "search 99bill.com
nameserver 192.168.63.154
nameserver 192.168.63.155">/etc/resolv.conf
	;;
	st3)
	nfs_path="mount -o rw 10.10.1.164:/vol/vol_fc/as /nfs/"
	script_path="mount 10.10.50.169:/opt/script /opt/script"
	echo -e "search 99bill.com
nameserver 10.10.80.101
nameserver 10.10.80.102">/etc/resolv.conf
	;;
	sandbox)
	nfs_path="mount -o rw 192.168.63.150:/data1/nfs/sandbox/nfs /nfs/"
	script_path="mount 192.168.13.250:/opt/script /opt/script"
	echo -e "search 99bill.com
nameserver 192.168.13.237
nameserver 192.168.13.238">/etc/resolv.conf
	;;
	dev)
	nfs_path=""
	script_path=""
	echo -e "nameserver 192.168.191.240
nameserver 192.168.191.190">/etc/resolv.conf
	;;
	nj)
	nfs_path=""
	script_path=""
	echo -e "nameserver 192.168.191.240
nameserver 192.168.191.190">/etc/resolv.conf
	;;
esac

#### application 
echo $APP
for app in $APP
do
	case ${app} in
	#zabbix) zabbix_info;cp -af zabbix_agent/${$zabbix_env}/zabbix /usr/local/zabbix  ;;
	zabbix) echo "zabbix set";zabbix_info ;;
	tomcat) echo "tomcat set";tomcat_info ;;
	*)  echo "have not this app ${app}" ;;
	esac
done
####init salt
echo "${THE_ENV}-tomcat-${IP}">/etc/salt/minion_id;if [[ -d /etc/salt/pki/minion ]];then rm -rf /etc/salt/pki/minion;fi;sh /etc/init.d/salt-minion restart

sh AS6.5.reinforce.20150415.sh ${THE_ENV}
wait
rm -f /root/init_99bill.tgz
rm -rf /root/init_99bill
rm -f /etc/udev/rules.d/70-persistent-cd.rules
rm -f /etc/udev/rules.d/70-persistent-net.rules
sleep 3
reboot
