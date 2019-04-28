#!/usr/bin/env python
#coding=utf8
#caodd 2015.04.27
#'host-862': '10.10.51.51'
#本机克隆 st3
#-t 'ST3-Template-RHEL6-test' -b test-temp3 -d '51.11' -H 10.10.51.11 -c st3 -i 10.10.70.250 -m test-tmct-6 -a 'zabbix' 'tomcat'
#-t 'ST3-Template-RHEL6.5_x64_4-70.200' -b test-70.200 -d '51.11' -H 10.10.51.11 -c st3 -i 10.10.70.251 -m test-tmct-200 -a 'zabbix' 'tomcat'
#-t 'ST3-Template-Tomcat-63.32(off)' -b test-6332 -d '51.11' -H 10.10.51.11 -c st3 -i 10.10.70.252 -m test-tmct-1 -a 'zabbix' 'tomcat'
#跨cluster
#-t 'ST3-Template-Tomcat-63.32(off)' -b test-6332-cluster -d '51.21' -H 10.10.51.21 -c st3 -i 10.10.70.253 -m test-tmct-cluster -a 'zabbix' 'tomcat'
#-t 'ST3-Template-RHEL6-test' -b test-6332-cluster -d '51.21' -H 10.10.51.21 -c st3 -i 10.10.70.253 -m test-tmct-cluster -a 'zabbix' 'tomcat'

from __future__ import division
import sys,os,yaml,readline,argparse,re,pymssql,datetime,getpass,time,tab
from pysphere import *
from pysphere.resources import VimService_services as VI
reload(sys)
sys.setdefaultencoding("utf-8")
from sql_query import *

def vcenter_info(stage):
    cf_name = '%s/config.vcenter'%(config_dir)
    f = open(cf_name)
    cf=yaml.load(f)
    f.close()
    vc_server = cf[stage]['ip']
    vc_username = cf[stage]['user']
    vc_password = cf[stage]['password']
    return vc_server,vc_username,vc_password
def find_vm(name):
    try:
        vm = conn.get_vm_by_name(name)
        return vm
    except VIException:
        return None

def find_host(host_ip):
    hosts = conn.get_hosts()
    hosts =  dict((v,k) for k, v in hosts.items())
    if hosts.has_key(host_ip):
        return hosts[host_ip]
    else:
        return None

def find_datastore(data_store):
    datastores = conn.get_datastores()
    datastores =  dict((v,k) for k, v in datastores.items())
    if datastores.has_key(data_store):
        return datastores[data_store]
    else:
        return None
def find_datastore_space(datastore_name,datastore_free):
    datastore_name_v = find_datastore(datastore_name)
    if datastore_name_v == None:
        print 'Error,datastore %s not found'%datastore_name
        return None
    else:
        props = VIProperty(conn,datastore_name_v)
        free = props.summary.freeSpace
        free_f = round(free/1024/1024/1024,2)
        print "datastore free space is    %.2f GB"%free_f
        print "reserved space       is    %.2f GB"%datastore_free
        if free_f >= datastore_free:
            #return free_f
            return datastore_name_v
        else:
            print 'Error,datastore %s  not enough disc space'%datastore_name
            return None
    
def find_cluster_version(stage,the_host):
    sql_str="SELECT FARMID,PRODUCT_API_VERSION FROM dbo.VPXV_HOSTS where NAME='%s'"%the_host
    AA = get_result(sql_str,stage)
    if len(AA) == 1:
        cluster = int(AA[0][0])
        version = float(AA[0][1])
        #print 'cluster is %s'%cluster
        print 'ESXI  version        is    %s'%version
        if version >= 5.0:
            return cluster,version
        else:
            return None
    elif len(AA) == 0:
        print "physical host %s not found in sql_db"%the_host
        return None
    else:
        print "physical host %s name more than one in sql_db"%the_host
        return None
def rate_view(percent, sum=100, bar_word="#",bar_length=60): 
    hashes = '#' * int(percent/float(sum) * bar_length)
    spaces = ' ' * (bar_length - len(hashes))
    if percent >= 100:
        sys.stdout.write("\rPercent: [%s] %d%%\n"%(hashes + spaces, percent))
    #else:
        #sys.stdout.write("\rPercent: [%s] %d%%"%(hashes + spaces, percent))
    sys.stdout.flush()
def task_status(task):
    while True:
        status = task.wait_for_state([task.STATE_SUCCESS, task.STATE_ERROR, task.STATE_RUNNING])
        if status == task.STATE_SUCCESS:
            rate_view(100)
            print "\nVM %s successfully clone" %base_name
            break
        elif status == task.STATE_ERROR:
            print "\nError failed  clone : %s" %base_name, task.get_error_message()
            return None
            break
        elif status == task.STATE_RUNNING:
            CC = task.get_progress()
            if CC == None:
                CC = 100
            rate_view(CC)
            time.sleep(2)
def network_config(base_name,vlan_name,connect=True):
    vm=conn.get_vm_by_name(base_name)
    net_device = []
    for dev in vm.properties.config.hardware.device:
        if dev._type in ["VirtualE1000", "VirtualE1000e",
                "VirtualPCNet32", "VirtualVmxnet",
                "VirtualNmxnet2", "VirtualVmxnet3"]:
            net_device.append(dev._obj)
    if len(net_device) == 0:
        raise Exception("The vm seems to lack a Virtual Nic")

    for dev_eth in net_device:
        dev_eth.Backing.set_element_deviceName(vlan_name)
        dev_eth.Connectable.Connected = connect

        request = VI.ReconfigVM_TaskRequestMsg()
        _this = request.new__this(vm._mor)
        _this.set_attribute_type(vm._mor.get_attribute_type())
        request.set_element__this(_this)
        spec = request.new_spec()
        dev_change = spec.new_deviceChange()
        dev_change.set_element_device(dev_eth)
        dev_change.set_element_operation('edit')
        spec.set_element_deviceChange([dev_change])
        request.set_element_spec(spec)
        ret = conn._proxy.ReconfigVM_Task(request)._returnval
        task = VITask(ret, conn)
        #task_status(task)
        #print 'set vlan  %s'%dev_eth.Backing.DeviceName
        #print 'set eth connected'
def vm_clone(template_name,base_name,datastore_name,the_host,the_stage):

    template_name_v = find_vm(template_name)
    if template_name_v == None:
        print 'Error,vm not found %s'%template_name
        print "template_name_v is %s"%template_name_v
        return None
    datastore_name_v = find_datastore_space(datastore_name,datastore_free=disk_free)
    if datastore_name_v == None:
        return None

    the_host_v = find_host(the_host)
    if the_host_v == None:
        print 'Error,physical host not found %s'%the_host
        return None
    #print "the_host_v is %s"%the_host_v

    resourcepool_v = find_cluster_version(stage,the_host)
    if resourcepool_v == None:
        print 'Error,%s find_cluster_version wrong '%the_host
        return None
    else:
        resourcepool_id = 'resgroup-%s'%(resourcepool_v[0]+1)

    base_name_v = find_vm(base_name)
    if base_name_v:
        print 'Error: the vm %s already exists ' %base_name
        return None
    else:
        #print template_name_v.get_property('name')
        #print "template_name_v.clone('%s',datastore='%s',host='%s',power_on=False,resourcepool='%s')"%(base_name,datastore_name_v,the_host_v,resourcepool_id)
        #print "Now  clone  ......"
        task = template_name_v.clone(base_name,datastore=datastore_name_v,host=the_host_v,power_on=True,resourcepool=resourcepool_id,sync_run=False)
        task_status(task)
        print "Now  clone  ......"
        return base_name
def find_vlan_name(vm_ip):
    n = vm_ip.split('.')[2]
    vlan_name = 'vlan %s'%n
    return vlan_name
def vm_login(base_name,passwd):
    vm = conn.get_vm_by_name(base_name)
    the_time=0
    while True:
        vm_t_sta =  vm.get_tools_status()
        if vm_t_sta in ['RUNNING']:
            #print 'OS start up'
            try:
                #print 'wait OS start up time is %d seconds'%the_time
                vm.login_in_guest('root',passwd)
                return vm
            except VIException:
                #print 'can not login %s'%base_name
                return None
            break
        elif vm_t_sta in ['RUNNING OLD']:
            #print 'vm_tools_status is RUNNING OLD'
            vm.upgrade_tools(sync_run=True)
        else:
            time.sleep(4)
            the_time = the_time + 4
            continue
def vm_init(base_name,the_stage,vm_ip,vm_hostname,app,passwd='111111'):
    vm = vm_login(base_name,passwd=passwd)
    if vm:
        if app==None:
            vm.send_file('init_99bill.tgz','/root/init_99bill.tgz',overwrite=True)
            vm.start_process('/bin/tar',args=['-zxvf','init_99bill.tgz'])
            #vm.start_process('/bin/sh',args=['/root/init_99bill/init.sh',the_stage,vm_ip,vm_hostname])
            vm.start_process('/bin/sh',args=['/root/init_99bill/init.sh',the_stage,vm_ip,vm_hostname,'>/root/init.log','2>&1'])
            #print 'Now running init'
            return vm
        else:
            app_sh = ' '.join(app)
            vm.send_file('init_99bill.tgz','/root/init_99bill.tgz',overwrite=True)
            vm.start_process('/bin/tar',args=['-zxvf','init_99bill.tgz'])
            #vm.start_process('/bin/sh',args=['/root/init_99bill/init.sh',the_stage,vm_ip,vm_hostname,app_sh])
            vm.start_process('/bin/sh',args=['/root/init_99bill/init.sh',the_stage,vm_ip,vm_hostname,app_sh,'>/root/init.log','2>&1'])
            #print 'Now running init'
            return vm
            
    else:
        print "Error: login %s failed with password %s"%(base_name,passwd)
        return None

config_dir = 'conf'

if __name__ == '__main__':
    starttime = datetime.datetime.now()
    description_str='''
clone VM from template
for example:
python %s -t ST3-Template-Apache-63.30 -b ST3-Apache-64.239 -d 'datastore1 (6)' -H 10.10.51.60 -c st3 -i 192.168.64.239 -m tmct-64.239 -a 'zabbix' 'tomcat'
从模板         ST3-Template-Apache-63.30    克隆
新虚拟机名     ST3-Apache-64.239
存储名         datastore1 (6)
宿主机名       10.10.51.60
执行环境       st3
IP地址         192.168.64.239
hostname       tmct-64.239
应用类型       'zabbix' 'tomcat'
---------------------------------
'''%sys.argv[0]
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,description=description_str)
    parser.add_argument('-t',nargs=1,required=True, help='Template VM')
    parser.add_argument('-b',nargs=1,required=True, help='new VM name')
    parser.add_argument('-d',nargs=1,required=True, help='datastore name')
    parser.add_argument('-H',nargs=1,required=True, help='name of host ')
    parser.add_argument('-c',nargs=1,required=True,choices=['st1', 'st2', 'st3','sandbox','dev','nj'], help='which stage use only: st1 st2 st3 sandbox dev nj')
    parser.add_argument('-i',nargs=1,required=True, help='new VM IP addr')
    parser.add_argument('-m',nargs=1,required=True, help='new VM hostname')
    parser.add_argument('-f',required=False, help='threshold of disk free',default=300.00,type=float)
    parser.add_argument('-a',nargs='+',required=False, help='which application to install')
    args = parser.parse_args()
    
    template_name = args.t[0]
    base_name = args.b[0]
    datastore_name = args.d[0]
    the_host =  args.H[0]
    the_stage = args.c[0]
    vm_ip = args.i[0]
    vm_hostname = args.m[0]
    disk_free = args.f
    app = args.a

    conn = VIServer()        
    stage=vcenter_info_2(the_stage)
    conn.connect(*vcenter_info(stage))

    #print '-'*120
    print "template_name        is    %s"%template_name
    print 'base_name            is    %s' %base_name
    print "the_stage            is    %s"%the_stage
    print "host_name            is    %s"%the_host
    print "datastore_name       is    %s"%datastore_name
    print "app                  is    %s"%app
    print "vm_ip                is    %s"%vm_ip
    print "vm_hostname          is    %s"%vm_hostname
    vm_clone_v = vm_clone(template_name,base_name,datastore_name,the_host,stage)
    if vm_clone_v == None:
        print 'Error:  clone  failed '
        sys.exit(1)
    else:
        #base_name='caodd-test4'
        #print 'new vm name is %s'%vm_clone_v
        #print '%s clone success'%vm_clone_v
        time.sleep(1)
        #print 'app is %s'%app
        if the_stage == 'nj':
            vlan_name = 'VM Network'
        else:
            vlan_name = find_vlan_name(vm_ip)
        #vlan_name = "vlan 50"
        network_config(base_name,vlan_name)
        #print "waiting for vm start up  ......"
        vm_init_v = vm_init(base_name,the_stage,vm_ip,vm_hostname,app)
        if vm_init_v:
            #print '%s init sucess'%base_name
            endtime = datetime.datetime.now()
            #print '%s clone and init  take  %s seconds'%(base_name,(endtime - starttime).seconds)
            #print '%s reboot now'%base_name
        else:
            sys.exit(1)
