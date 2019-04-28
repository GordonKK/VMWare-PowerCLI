#-*- coding: utf-8 -*-
#!/usr/bin/python
import os,sys
import threading
import os,re
import string
import sys
import datetime,time
import subprocess
import MySQLdb
import paramiko,commands
reload(sys)
sys.setdefaultencoding('utf-8')

id=sys.argv[1]
conn = MySQLdb.connect (host = '192.168.138.37',user = 'teops', passwd = '8611726',db = 'billinventory',charset='utf8')
cursor = conn.cursor()
cmd1="python teops_clone.py"
#cmd1="hostname;echo 'Now'"
(status, output) = commands.getstatusoutput(cmd1)
print status,output
s1=output.split('Now')
s2=""
for i in s1[0:-1]:
    s2=s2+i
sql0="select app_name,app_midware,app_email,app_num,date_times from ops_vmware where id=%s"
param0=(id)
cursor.execute(sql0,param0)
for row in cursor.fetchall():
  app_name=row[0].strip()
  app_midware=row[1].strip()
  app_email=row[2].strip()
  app_num=row[3].strip()
  date_times=row[4]

s="<pre>"+s2

sql1="update ops_vmware set vm_info=%s,check_os='1' where id=%s"
param1=(s,id)
cursor.execute(sql1,param1)
cmd="python mails.py '"+app_email+"' '''用户:"+app_name+"于"+str(date_times)+"申请的"+app_num+"台VMware虚拟机已经创建完成,请查看,详细信息如下:<pre>"+s+"'''"
os.system(cmd)
if status!=0:
  sql="update ops_vmware set isagree='1',check_os='3'  where id=%s"
  param=(id)
  cursor.execute(sql,param)
  s="<pre>申请的虚拟机创建失败，ID号为:"+id
  cmd="python mails.py 'POA_EA_LAB@99bill.com' '''"+s+"'''"
  os.system(cmd)
conn.commit()
cursor.close()
conn.close()
