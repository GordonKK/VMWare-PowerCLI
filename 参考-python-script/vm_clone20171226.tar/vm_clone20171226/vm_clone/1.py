import os,sys
hxy='''template_name        is    Template-14.251-RHEL6.5_x64
base_name            is    DEV-TMCT-15.165
the_stage            is    dev
host_name            is    192.168.70.71
datastore_name       is    datastore1 (33)
app                  is    None
vm_ip                is    192.168.15.165
vm_hostname          is    TMCT-15.165
datastore free space is    522.18 GB
reserved space       is    300.00 GB
ESXI  version        is    5.5
Percent: [############################################################] 100%

VM DEV-TMCT-15.165 successfully clone
Now  clone  ......
template_name        is    Template-14.251-RHEL6.5_x64
base_name            is    DEV-TMCT-47.205
the_stage            is    dev
host_name            is    192.168.70.65
datastore_name       is    datastore1 (30)
app                  is    None
vm_ip                is    192.168.47.205
vm_hostname          is    TMCT-47.205
datastore free space is    456.37 GB
reserved space       is    300.00 GB
ESXI  version        is    5.5
Percent: [############################################################] 100%

VM DEV-TMCT-47.205 successfully clone
Now  clone  ......
192.168.15.158 already in use
192.168.15.158 already in use
192.168.47.179 already in use
'''
s=hxy.split('Now')
s2=""
for i in s[0:-1]:
   s2=s2+i
print "<pre>"+s2
