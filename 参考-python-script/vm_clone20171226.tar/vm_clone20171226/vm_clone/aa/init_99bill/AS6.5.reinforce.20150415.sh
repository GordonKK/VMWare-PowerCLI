#! /bin/bash
########################################################
# File:         AS6.5.reinforce2014031101.sh
# Description:  use for 99billidc center
# Version:	secupdate:2014031101
# Date:		2014-03-11
# Corp.:	99bill.com
# Author:	Vivyan.Wu
# WWW:		http://www.99bill.com
# Linux security strengthen script
# Use for Redhat 6.5 (Linux 2.6.18-238.el5)
### END INIT INFO
########################################################

THE_ENV=$1

#EXPORT PATH
export PATH=/usr/kerberos/sbin:/usr/kerberos/bin:/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#Version checking
SUBVERSION=IDC\(6.5\)_2014031101
VERSION=20140311
if [[ -e /etc/sec-version && `cat /etc/sec-version | grep "$VERSION"` != "" ]]; then 
  echo "Checking the sec-version!!"
  exit 0
fi

#Check
 
#echo """
#Please make sure all the preparatory work is ready:
#  1.Enabled iptables, opened ssh port
#  2.Added group \"IDC\"
#  3.Added users, and assigned to group \"IDC\" 
#  4.Use a nomal user to login test and login successful
#
#If you ensure all above is ok, input \"y|Y\" to continue: 
#"""
#read YES_OR_NO
#case "$YES_OR_NO" in
#  y|Y)
#    echo "Starting";;
#  *)
#    exit 0;;
#esac

#echo "Please input the Internet Data Center(hb|idx|m5 ):"
#read HB_OR_SX
#case "$HB_OR_SX" in
#  "idx") ip_logserver1=172.16.173.108; ip_logserver2=172.16.173.109; ip_nameserver1=172.16.173.111; ip_nameserver2=172.16.80.101; ip_nameserver3=172.16.80.102;;
#  "hb") ip_logserver1=172.16.50.136; ip_logserver2=172.16.50.181; ip_nameserver1=172.16.80.101; ip_nameserver2=172.16.80.102; ip_nameserver3=172.16.173.111;;
#  "m5") ip_logserver1=172.18.50.136; ip_logserver2=172.18.50.181; ip_nameserver1=172.16.173.111; ip_nameserver2=172.16.80.101; ip_nameserver3=172.16.80.102;;
#  *   ) echo "Input error!!";exit 0;;
#esac


#1.services limites
service netfs stop
chkconfig --level 12345 netfs off
service acpid stop
chkconfig --level 12345 acpid off
service haldaemon stop
chkconfig --level 12345 haldaemon off
service rhnsd stop
chkconfig --level 12345 rhnsd off
service blk-availability  stop
chkconfig --level 12345 blk-availability  off
service sendmail restart


#2.commands and scripts limites
chmod 700 /usr/bin/who
chmod 700 /usr/bin/w
chmod 700 /usr/bin/locate
chmod 700 /usr/bin/whereis
chmod a-s  /usr/bin/chage
chmod a-s  /usr/bin/gpasswd
chmod a-s  /usr/bin/wall
chmod a-s  /usr/bin/chfn
chmod a-s  /usr/bin/chsh
chmod a-s  /usr/bin/newgrp
chmod a-s  /usr/bin/write
chmod a-s  /usr/sbin/usernetctl
chmod a-s  /bin/traceroute
chmod a-s  /bin/mount
chmod a-s  /bin/umount
chmod a-s  /sbin/netreport
chmod 700 /etc/rc.d/init.d/*


#3.Unuseful users and groups deleted
userdel lp
userdel games
userdel adm
userdel shutdown
userdel halt
userdel uucp
userdel operator
userdel gopher
userdel ftp
groupdel lp
groupdel adm


#4.Banner
cat >> /etc/issue <<EOF
ALERT! You are entering a secured area(99bill.com)! Your IP and login information 
have been recorded. System administration has been notified.
This system is restricted to authorized access only. All activities on
this system are recorded and logged. Unauthorized access will be fully
investigated and reported to the appropriate law enforcement agencies.

EOF

cat > /etc/issue.net <<EOF
ALERT! You are entering a secured area(99bill.com)! Your IP and login information 
have been recorded. System administration has been notified.
This system is restricted to authorized access only. All activities on
this system are recorded and logged. Unauthorized access will be fully
investigated and reported to the appropriate law enforcement agencies.

EOF

#24.DNS configuration
#cat > /etc/resolv.conf <<EOF
#nameserver $ip_nameserver1
#nameserver $ip_nameserver2
#nameserver $ip_nameserver3
#search localdomain
#EOF


#5.sshd_config 
sed -i 's/#LoginGraceTime 2m/LoginGraceTime 30s/g' /etc/ssh/sshd_config
sed -i 's/#PermitRootLogin yes/PermitRootLogin yes/g' /etc/ssh/sshd_config
sed -i 's/#StrictModes yes/StrictModes yes/g' /etc/ssh/sshd_config
sed -i 's/#MaxAuthTries 6/MaxAuthTries 3/g' /etc/ssh/sshd_config
sed -i 's/#UseDNS yes/UseDNS no/g' /etc/ssh/sshd_config
sed -i 's/PasswordAuthentication yes/PasswordAuthentication yes/g' /etc/ssh/sshd_config
sed -i 's/GSSAPIAuthentication yes/GSSAPIAuthentication no/g' /etc/ssh/sshd_config
service sshd restart
chattr +i /etc/ssh/sshd_config
#sshconfigGT=`cat /etc/ssh/sshd_config | grep "^LoginGraceTime 30s"`
#sshconfigRL=`cat /etc/ssh/sshd_config | grep "^PermitRootLogin yes"`
#sshconfigSM=`cat /etc/ssh/sshd_config | grep "^StrictModes yes"`
#sshconfigMA=`cat /etc/ssh/sshd_config | grep "^MaxAuthTries 3"`
#sshconfigDNS=`cat /etc/ssh/sshd_config | grep "^UseDNS no"`
#sshconfigPA=`cat /etc/ssh/sshd_config | grep "^PasswordAuthentication yes"`
#sshconfigGSA=`cat /etc/ssh/sshd_config | grep "^GSSAPIAuthentication no"`
#if [[ sshconfigGT != "" && sshconfigSM != "" && sshconfigMA != "" && sshconfigRL != "" && sshconfigDNS != "" && sshconfigPA != "" && sshconfigGSA != "" ]];then
#  echo "Sshd_config secupdate Success!!"
#else echo "Sshd_config secupdate Fail!!"
#fi


#6.Accounts policies
#sed -i '/PASS_MAX_DAYS/s/99999/90/' /etc/login.defs
sed -i '/PASS_MIN_LEN/s/5/8/' /etc/login.defs
sed -i '/PASS_WARN_AGE/s/7/15/' /etc/login.defs

chattr +i /etc/login.defs


#7.Ctrl+Alt+Del
sed -i '/^ca::ctrlaltdel:\/sbin/s/^/#/' /etc/inittab
sed -i '/^id:5:initdefault:/s/5/3/' /etc/inittab


#8.History cmds and exec_time limited
sed -i 's/HISTSIZE=1000/HISTSIZE=1000\nTMOUT=1800/g' /etc/profile
echo "rm -f $HOME/.bash_history" >> ~/.bash_logout

## added by lunkun
cat > /etc/logrotate.d/omsa-tty << EOF
/var/log/TTY_00000000.log {
daily
notifempty
rotate 7
compress
sharedscripts
postrotate
/etc/init.d/dsm_om_shrsvc restart
endscript
}
EOF

cat > /etc/logrotate.d/mail << EOF
/var/spool/mail/root {
daily
missingok
rotate 7
notifempty
sharedscripts
}
EOF


#9.ports file
chattr +i /etc/services


#10.root ttys
sed -i '/^tty[3-9]/s/^/#/' /etc/securetty
sed -i '/^tty1[01]/s/^/#/' /etc/securetty


#11.IPTABLES initialization
iptables_whitelist=`/sbin/ifconfig |grep -v "127.0.0.1"|grep "inet addr"| cut -f 2 -d ":"|cut -f 1,2,3 -d "."`
#########################################################################
#
# File:        AS6.5.reinforce(IDC)2014031101.sh 
# Description:  use for 99billidc center
# Version:	1.0
# Date:		2011-5-3
# Corp.:	99bill.com
# Author:	vitas.liu
# WWW:		http://www.99bill.com 
### END INIT INFO
#########################################################################
case ${THE_ENV} in
	st1)
	echo "the_env is st1,cp iptables"
	cp -af iptables /etc/sysconfig/iptables
	service iptables start
	;;
	st2)
service iptables stop
IPTABLES=/sbin/iptables
# start by flushing the rules
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT
$IPTABLES -t mangle -P PREROUTING ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -F
$IPTABLES -X
$IPTABLES -Z
$IPTABLES -t nat -F
$IPTABLES -t mangle -F
$IPTABLES -t nat -X
$IPTABLES -t mangle -X
$IPTABLES -t nat -Z
## allow packets coming from the machine
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT
# allow outgoing traffic
$IPTABLES -A OUTPUT -o eth0 -j ACCEPT
# block spoofing
$IPTABLES -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT 
$IPTABLES -A INPUT -p icmp -j ACCEPT 
# stop bad packets
$IPTABLES -A INPUT -m state --state INVALID -j DROP
# stop ping flood attack
$IPTABLES -N PING
$IPTABLES -A PING -p icmp --icmp-type echo-request -m limit --limit 1/second -j RETURN
#$IPTABLES -A PING -p icmp -j REJECT
$IPTABLES -I INPUT -p icmp --icmp-type echo-request -m state --state NEW -j PING
#################################
## allow access  police
#################################

#middle used 70 60 21 30
$IPTABLES -A INPUT -s $iptables_whitelist".0/24" -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.63.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.64.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.55.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.52.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.50.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.6.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.14.0/24 -p tcp -j ACCEPT
#nfs mount
$IPTABLES -A INPUT -p udp -j ACCEPT
# tcp ports
# SSH
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 22 -j ACCEPT
# FTP
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 21 -j ACCEPT
# MYSQL
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 3306 -j ACCEPT
# ORACLE
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 1521 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 1530 -j ACCEPT
# HTTP
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 80:89 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7777 -j ACCEPT
# HTTPS
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 443 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 8443 -j ACCEPT
# pop3
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 110 -j ACCEPT
# imap
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 143 -j ACCEPT
# imaps
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 993 -j ACCEPT
# pop3s
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 995 -j ACCEPT
# smtp
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 25 -j ACCEPT
# snmp
$IPTABLES -A INPUT -s 192.168.0.0/16 -p udp -m udp --dport 161 -j ACCEPT
# samba
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 137:139 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p udp -m udp --dport 137:139 -j ACCEPT
# vnc
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 5901:5905 -j ACCEPT
# weblogic
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7001:8000 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 8001:9000 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 9001:10000 -j ACCEPT
# memcache
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 12000:12050 -j ACCEPT
# tibco
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7222 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7333 -j ACCEPT
# debug
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 9800:10000 -j ACCEPT
# fshare
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 5001 -j ACCEPT
# Iptables drop logging
$IPTABLES -A INPUT -j LOG --log-prefix "[IPTABLES DROP LOGS]: " --log-level 4
# finally - drop the rest
$IPTABLES -A INPUT -p all -j DROP

service iptables save
service iptables start
echo "Iptables rules update Complete!!"
;;
	st3)
	echo "the_env is st3,cp iptables"
	cp -af iptables /etc/sysconfig/iptables
	service iptables restart
	;;
	sandbox)
	echo "the_env is sandbox"
service iptables stop
IPTABLES=/sbin/iptables
# start by flushing the rules
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD ACCEPT
$IPTABLES -P OUTPUT ACCEPT
$IPTABLES -t nat -P PREROUTING ACCEPT
$IPTABLES -t nat -P POSTROUTING ACCEPT
$IPTABLES -t nat -P OUTPUT ACCEPT
$IPTABLES -t mangle -P PREROUTING ACCEPT
$IPTABLES -t mangle -P OUTPUT ACCEPT
$IPTABLES -F
$IPTABLES -X
$IPTABLES -Z
$IPTABLES -t nat -F
$IPTABLES -t mangle -F
$IPTABLES -t nat -X
$IPTABLES -t mangle -X
$IPTABLES -t nat -Z
## allow packets coming from the machine
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT
# allow outgoing traffic
$IPTABLES -A OUTPUT -o eth0 -j ACCEPT
# block spoofing
$IPTABLES -A INPUT -s 127.0.0.0/8 ! -i lo -j DROP
$IPTABLES -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
$IPTABLES -A INPUT -p icmp -j ACCEPT
# stop bad packets
$IPTABLES -A INPUT -m state --state INVALID -j DROP
# stop ping flood attack
$IPTABLES -N PING
$IPTABLES -A PING -p icmp --icmp-type echo-request -m limit --limit 1/second -j RETURN
#$IPTABLES -A PING -p icmp -j REJECT
$IPTABLES -I INPUT -p icmp --icmp-type echo-request -m state --state NEW -j PING
#################################
## allow access  police
#################################

#middle used 70 60 21 30
$IPTABLES -A INPUT -s $iptables_whitelist".0/24" -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.12.0/24 -p tcp -j ACCEPT
$IPTABLES -A INPUT -s 192.168.13.0/24 -p tcp -j ACCEPT
#nfs mount
$IPTABLES -A INPUT -p udp -j ACCEPT
# tcp ports
# SSH
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 22 -j ACCEPT
# FTP
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 21 -j ACCEPT
# MYSQL
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 3306 -j ACCEPT
# ORACLE
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 1521 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 1530 -j ACCEPT
# HTTP
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 80:89 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7777 -j ACCEPT
# HTTPS
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 443 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 8443 -j ACCEPT
# pop3
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 110 -j ACCEPT
# imap
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 143 -j ACCEPT
# imaps
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 993 -j ACCEPT
# pop3s
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 995 -j ACCEPT
# smtp
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 25 -j ACCEPT
# snmp
$IPTABLES -A INPUT -s 192.168.0.0/16 -p udp -m udp --dport 161 -j ACCEPT
# samba
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 137:139 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p udp -m udp --dport 137:139 -j ACCEPT
# vnc
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 5901:5905 -j ACCEPT
# weblogic
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7001:8000 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 8001:9000 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 9001:10000 -j ACCEPT
# memcache
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 12000:12050 -j ACCEPT
# tibco
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7222 -j ACCEPT
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 7333 -j ACCEPT
# debug
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 9800:10000 -j ACCEPT
# fshare
$IPTABLES -A INPUT -s 192.168.0.0/16 -p tcp -m tcp --dport 5001 -j ACCEPT
# Iptables drop logging
$IPTABLES -A INPUT -j LOG --log-prefix "[IPTABLES DROP LOGS]: " --log-level 4
# finally - drop the rest
$IPTABLES -A INPUT -p all -j DROP

service iptables save
service iptables start
echo "Iptables rules update Complete!!"

	;;
	dev)
	echo "the_env is dev,no iptables"
	;;
	*)
	echo "the_env not exist"
	;;
esac

#12.syslog server specify
#echo "*.*          @$ip_logserver1" >> /etc/rsyslog.conf
#echo "*.*          @$ip_logserver2" >> /etc/rsyslog.conf
echo "kern.warning          /var/log/iptables" >> /etc/rsyslog.conf
sed -i 1's/^\/var/\/var\/log\/iptables &/g' /etc/logrotate.d/syslog
service rsyslog restart


#13.no ip spoof
echo "nospoof on" >> /etc/host.conf


#14.su for group=IDC
#sed -i 7's/^/auth            required        pam_wheel.so group=IDC\n/g' /etc/pam.d/su


#15.add user mail notice
cat > /etc/cron.hourly/99bill_adduser_mailnoting.pl <<\EOF
#! /usr/bin/perl

########################################################
# File:         99bill_adduser_mailnoting.pl
# Description:  use for 99billidc center
# Version:      1.0
# Date:         2011-5-3
# Corp.:        99bill.com
# Author:       Vivyan.Wu
# WWW:          http://www.99bill.com
### END INIT INFO
########################################################

if ( -e "/etc/idcusers.conf" ){
  system("chattr -i /etc/idcusers.conf");
  my @users_n;my @users_o;my $i = 0;
  open( PASSWD, "/etc/passwd" );
  while( <PASSWD> ){
    ($users_n[$i]) = ($_=~m/^(\S+?):/);
    $i++;
  }
  close(PASSWD);
  my $i = 0;
  open( IDCUSER, "/etc/idcusers.conf" );
  while( <IDCUSER> ){
    ($users_o[$i]) = ($_=~m/^(\S+)$/);
    $i++;
  }
  close(IDCUSER);
  my $i = 0;

  foreach my $user(@users_n){
    if ( $user !~ m/\S+/ ){
        next;
      }
    if (!( grep /^$user$/,@users_o )){
      my $newuser_info = `cat /etc/shadow | grep $user`;
      (my $newuser_cdate) = ( $newuser_info =~ m/\S+:\S+:(\d+):.*?:.*?:.*?:.*?:.*?:.*/ );
      my $todaynum = `date +%s`;
      my $cdays = int($todaynum/24/3600) - $newuser_cdate;
      my $days = `date +%Y\.%m\.%d --date "$cdays days ago"`;
      chomp ($days);
      my $ipsource = `ifconfig`;
      my $ip_addr;
      if ($ipsource =~ m/((\d+\.){3}\d+)/ && !/127/){
        $ip_addr = $1;
      }
      chomp ($ip_addr);
      my $hostname = `hostname`;
      chomp ($hostname);
      my $hostinfo = $hostname.": ".$ip_addr;
      my $message = "User $user added on ${days}\, please check the user\'s legitimacy!!\( $hostinfo \)\n";
      print "$message\n";
      my $cmd = "echo \"$message\" | mail -v -s 'User Added Notice Message' POA_EA_LAB\@99bill\.com -c security\@99bill\.com";
      system( "$cmd" );
#      open( IDCUSER, ">>/etc/idcusers.conf" );
#      print IDCUSER  "$user\n";
#      close(IDCUSER);
    }
  }
  system ("awk -F \":\" '{print \$1}' /etc/passwd > /etc/idcusers.conf");
  system("chattr +i /etc/idcusers.conf");
}else{
  system ("awk -F \":\" '{print \$1}' /etc/passwd > /etc/idcusers.conf");
  system("chattr +i /etc/idcusers.conf");
}
EOF

chmod u+x /etc/cron.hourly/99bill_adduser_mailnoting.pl
/etc/cron.hourly/99bill_adduser_mailnoting.pl


#16.user expire noting
cat > /etc/cron.daily/99bill_accountexpire_mailnoting.pl <<\EOF
#! /usr/bin/perl

########################################################
# File:         99bill_accountexpire_mailnoting.pl
# Description:  use for 99billidc center
# Version:      1.0
# Date:         2011-5-3
# Corp.:        99bill.com
# Author:       Vivyan.Wu
# WWW:          http://www.99bill.com
### END INIT INFO
########################################################

open ( SHADOW,"/etc/shadow" );
while ( <SHADOW> ){
  next if ( $_ =~ m/(\S+):(.*?):(\d+):.*?:(99999)?:(.*?):.*?:.*?:.*/ );
  ( $user,$createday,$limitday,$noteday )=( $_ =~ m/(\S+):.*?:(\d+):.*?:(.*?):(.*?):.*?:.*?:.*/ );
  my $today = int((`date +%s`)/86400);
  my $testday = $limitday-($today-$createday);
  my $ipsource = `ifconfig`;
  my $ip_addr;
  if ($ipsource =~ m/((\d+\.){3}\d+)/ && !/127/){
    $ip_addr = $1;
  }
  chomp ($ip_addr);
  my $hostname = `hostname`;
  chomp ($hostname);
  my $hostinfo = $hostname.": ".$ip_addr;
  if ( $testday <= 0 ){
    my $text =  "User $user was expired!!\( $hostinfo \)\n";
    my $cmd= "echo \"$text\" | mail -v -s 'Password Expired Notice Message' POA_EA_LAB\@99bill\.com -c security\@99bill\.com";
    system ("$cmd");
  }elsif ( $testday <= $noteday ){
    my $text =  "User $user need to change password, it will be expired in $testday days!!\( $hostinfo \)\n";
    my $cmd= "echo \"$text\" | mail -v -s 'Password Expired Notice Message' POA_EA_LAB\@99bill\.com -c security\@99bill\.com";
    system ("$cmd");
  }
}
close (SHADOW);

EOF

chmod u+x /etc/cron.daily/99bill_accountexpire_mailnoting.pl

#17.iptables stop checking part
cat > /etc/cron.daily/ULC_sec_iptablesstopcheck.pl <<\EOF
#! /usr/bin/perl

my $iptableslist = `service iptables status | grep "state RELATED,ESTABLISHED"`;
#if ($iptableslist =~ m/Firewall is stopped/ or $iptableslist !~ m/\d+\.\d+\.\d+\.\d+ .* state RELATED,ESTABLISHED/ ){
if (!$iptableslist){
  my $hostinfo = &hostmark();
  my $message = "Service IPTABLES is STOPPED!!\( $hostinfo \)";
  print "$message\n";
#  my $cmd = "echo \"$message\" | /usr/bin/logger -t SEC -p local5\.warning";
  my $cmd = "echo \"$message\" |  mail -v -s 'Iptables Stop Notice Message' POA_EA_LAB\@99bill\.com -c security\@99bill\.com";
  system( "$cmd" );
}

#101.Host information function
sub hostmark(){
  my $ipsource = `ifconfig`;
  my $ip_addr;
  if ($ipsource =~ m/((\d+\.){3}\d+)/ && !/127/){
    $ip_addr = $1;
  }
  chomp ($ip_addr);
  my $hostname = `hostname`;
  chomp ($hostname);
  return($hostname.": ".$ip_addr);
}

EOF

chmod u+x /etc/cron.daily/ULC_sec_iptablesstopcheck.pl

#18.iptables droplog mailing part
cat > /etc/SEC_IptablesDROPlog_monitor.pl <<\EOF
#! /usr/bin/perl

my $logtimemark = 0;
my @iptablesdroplogs = `cat /var/log/iptables | grep \"IPTABLES DROP LOGS\"`;
if ( -e "/etc/sec-iptables-logtimemark" ){
  $logtimemark = `cat /etc/sec-iptables-logtimemark  | egrep '[0-9]{10}'`;
  chomp( $logtimemark );
  $logtimemark = int($logtimemark);
}
if ($logtimemark !~ m/\d+/){
  $logtimemark = 0;
}
my $hostinfo = &hostmark();
system( "echo \"According to the FW drop logs, please IDC colleagues add iptables rules. Any questions contact Security Center, thanks!\n\nIptables Drop logs Detected\( $hostinfo \):\n\" > /var/log/iptables.tmp.sec" );
foreach my $iptableslog( @iptablesdroplogs ){
  next if ( $iptableslog =~ m/SRC=172\.16\.50\.138/ );
  next if ( $iptableslog =~ m/ RES=\w+ ACK / );
  next if ( $iptableslog =~ m/ PROTO=2/ );
  my $logtime;
  if ( $iptableslog =~ m/^(\w{3}\s{1,2}\d{1,2}\s{1,2}\d{1,2}:\d{1,2}:\d{1,2})/ ){
    $logtime = `date -d '$1'`;
    chomp( $logtime );
    my $logtimeint = `date -d '$logtime' +%s`;
    chomp( $logtimeint );
    $logtimeint = int($logtimeint);
    next if ( $logtimeint <= $logtimemark );
  }
  if ( $iptableslog =~ m/^(\w{3}\s{1,2}\d{1,2}\s{1,2}\d{1,2}:\d{1,2}:\d{1,2}) (\S+) .* (SRC=\d+\.\d+\.\d+\.\d+) (DST=\d+\.\d+\.\d+\.\d+) .* (PROTO=\S+) (SPT=\d+) (DPT=\d+) .*/ ){
    my $newlog = "$1 $2 : $3 $4 $6 $7 $5\n";
    my $cmd1 = "echo \"$newlog\" >> /var/log/iptables.tmp.sec";
    system( "$cmd1" );
  }else{
    my $cmd1 = "echo \"$iptableslog\" >> /var/log/iptables.tmp.sec";
#    print $iptableslog;
    system( "$cmd1" );
  }
}
my $lines = `cat /var/log/iptables.tmp.sec |wc -l`;
chomp($lines);
if ($lines > 4){
  my $cmd = "mail -v -s \'Iptables Drop Logs\' POA_EA_LAB\@99bill\.com -c security\@99bill\.com< /var/log/iptables\.tmp\.sec";
  system( "$cmd" );
}
system( "rm -rf /var/log/iptables.tmp.sec" );
my $lastlog = $iptablesdroplogs[-1];
( my $lastlogtimemark )= ( $lastlog =~ m/^(\w{3}\s{1,2}\d{1,2}\s{1,2}\d{1,2}:\d{1,2}:\d{1,2})/ );
my $lastlogTMint = `date -d '$lastlogtimemark' +%s`;
chomp( $lastlogTMint );
system( "echo $lastlogTMint > /etc/sec-iptables-logtimemark" );
system( "echo $lastlogtimemark >> /etc/sec-iptables-logtimemark" );

#101.Host information function
sub hostmark(){
  my $ipsource = `ifconfig`;
  my $ip_addr;
  if ($ipsource =~ m/((\d+\.){3}\d+)/ && !/127/){
    $ip_addr = $1;
  }
  chomp ($ip_addr);
  my $hostname = `hostname`;
  chomp ($hostname);
  return($hostname.": ".$ip_addr);
}

EOF

chmod u+x /etc/SEC_IptablesDROPlog_monitor.pl
echo "*/5 * * * * root /etc/SEC_IptablesDROPlog_monitor.pl" >> /etc/crontab

service crond restart


#19.history syslog
if ! egrep -q "local5\.\*\ *\/var\/log\/history.log" /etc/rsyslog.conf; then
  echo 'local5.*                                                /var/log/history.log' >> /etc/rsyslog.conf
else
  echo "command history logging within /etc/rsyslog.conf already done." 
fi

if ! egrep -q "function history_to_syslog" /etc/profile;then
cat >> /etc/profile <<\EOF
function history_to_syslog
{
        declare cmd
        cmd=$(echo `history|tail -n 1|cut -c 7-`|sed -lne 's/-/_/g')
        logger -p local5.notice [$$:$USER] - $cmd

}
trap history_to_syslog DEBUG
EOF

source /etc/profile
service rsyslog restart
else
echo "command history logging within /etc/profile already done."
fi


#20.ntpd-deploy
cat > ./ntpd-deploy.sh <<\EOG
#!/bin/bash

cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
yum install -y ntp
conf="/etc/ntp.conf"
#conf="/tmp/ntp.conf"

cat > $conf <<EOF
restrict default nomodify notrap noquery
restrict 127.0.0.1
server 192.168.54.254 iburst prefer
server 192.168.54.254 iburst
server  127.127.1.0     # local clock
fudge   127.127.1.0 stratum 10
driftfile /var/lib/ntp/drift
broadcastdelay  0.008
keys            /etc/ntp/keys
logconfig =all
EOF

cat /dev/null > /etc/ntp/step-tickers
echo -e "clock.redhat.com\nclock2.redhat.com" > /etc/ntp/ntpservers
chkconfig ntpd on
service ntpd restart
ntpq -pn

EOG

chmod +x ./ntpd-deploy.sh
./ntpd-deploy.sh
rm -f ./ntpd-deploy.sh


#21.idc users added
#cat > ./useradd.sh <<\EOF
#!/bin/bash
#list="userlist"

#function luseradd () {
#declare -a uinfo
#uinfo=($line)
#user=$(echo ${uinfo[0]} | sed 's/^#//')
#realname=${uinfo[1]}
#ktype=${uinfo[2]}
#key=${uinfo[3]}
#email=${uinfo[4]}
#group=${uinfo[5]}

#case $group in
#self)
#  group=$user
#  groupopt=''
#  ;;
#*)
#  (cat /etc/group | cut -d: -f1 | grep -q $group) || groupadd $group
#  groupopt="-g $group"
#  ;;
#esac

#if cut -d: -f1 /etc/passwd | grep -Fq $user;then
#  echo "user $user(realname $realname) exists, nothing will be done."
#else
#  useradd -m $groupopt -c "99bill $user" $user && echo "user $user(realname $realname) added." || echo "user $user can't be added."
#  (mkdir -p /home/$user/.ssh && echo "ssh-$ktype $key $email" >> /home/$user/.ssh/authorized_keys && chown -R $user:$group /home/$user) && echo "user $user(realname $realname) home directory permission and ssh public key set." || echo "homedir permition or ssh public key can't be set."
#fi
#}

#if [ $1 ];then
#  for user in $*;do
#    if ! egrep -q "^#?$user " $list;then
#      echo "$user does not exists as a user in user list file $list."
#    else
#      line=$(egrep "^#?$user " $list)
#      luseradd
#    fi
#  done
#else
#  cat $list | egrep -v "^#" |\
#  while read line;do
#    luseradd
#  done
#fi

#EOF

#chmod +x ./useradd.sh
#./useradd.sh
#rm -f ./useradd.sh


#22.Userslist Audit log
cat > /etc/cron.hourly/ULC_sec_userslist_logging.pl <<\EOF
#! /usr/bin/perl

########################################################
# File:         99bill_userslist_mailnoting.pl
# Description:  users list will be logged every hours
# Version:      1.0
# Date:         2011-8-10
# Corp.:        99bill.com
# Author:       Vivyan.Wu
# WWW:          http://www.99bill.com
### END INIT INFO
########################################################

my @users_now;
my $i=0;
open( PASSWD, "/etc/passwd" );
while( <PASSWD> ){
#  my $user=$_;
  ($users_now[$i]) = ($_=~m/^(\S+?):x:/);
  $i++;
}
close(PASSWD);

#my $hostinfo = &hostmark();
$"=",";
my $message = "@users_now";
my $cmd = "echo \"$message\" | /usr/bin/logger -t SEC_USERLIST -p authpriv\.info";
#print $message;
system("$cmd");


EOF

chmod u+x /etc/cron.hourly/ULC_sec_userslist_logging.pl
/etc/cron.hourly/ULC_sec_userslist_logging.pl

#23.ntp/snmp restart when ifup
echo -e "/sbin/service ntpd restart\n/sbin/service snmpd restart" > /sbin/ifup-local
chmod 700 /sbin/ifup-local


#99.root umask
#umask 027
#echo "umask 027" >> /root/.bashrc
#chmod a+r /etc/profile

#100.end version
echo "secupdate:$SUBVERSION" > /etc/sec-version
chmod a+r /etc/sec-version

#echo  -e "\n\nNOTICE!!!!!!!!!!!!!!\n\nPlease update the following services:\nopenssl, openssh, ossec, nfs-util, Rsync, ntpd\n"
