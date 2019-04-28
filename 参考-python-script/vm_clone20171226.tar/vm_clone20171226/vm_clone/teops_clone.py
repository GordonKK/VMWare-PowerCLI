#!/usr/bin/env python
#coding=utf8
#caodd 2015.05.28
from __future__ import division
import sys,os,yaml,random,time
from sql_query import *
from get_ip import *

def find_host_ds(stage,num,cluster_name=None,vm_num_max=12):
    farm_id_list = find_farm_id(stage,cluster_name)
    farm_str = ','.join(map(str,farm_id_list))
    sql_str = '''
SELECT DISTINCT a.NAME,c.NAME,a.HOSTID,a.FARMID 
FROM dbo.VPXV_HOSTS a,dbo.VPXV_HOST_DATASTORE b,dbo.VPXV_DATASTORE c
where a.FARMID in (%s) 
and a.PRODUCT_API_VERSION >= 5.0 
and  a.HOSTID=b.HOST_ID 
and b.DS_ID=c.ID 
and b.ACCESSIBLE=1 
and convert(float,c.FREE_SPACE)>322122547200
and a.HOSTID in 
(
select d.HOSTID from
dbo.VPXV_VMS d where d.POWER_STATE='On'
GROUP BY d.HOSTID 
HAVING count(d.HOSTID)<=%s
)
'''%(farm_str,vm_num_max)
    stage_vcenter = vcenter_info_2(stage)
    AA = get_result(sql_str,stage_vcenter)
    #print "------------------------------------------------"
    cf_name_exclude = '%s/config.exclude.host_datastore'%(config_dir)
    f_ex = open(cf_name_exclude)
    cf_ex=yaml.load(f_ex)
    f_ex.close()
    exclude_host=cf_ex['%s.host'%stage_vcenter]
    exclude_datastore=cf_ex['%s.datastore'%stage_vcenter]
    temp_AA = []
    for row in AA:
        row_flag=0
        for ex_host in exclude_host:
            if row[0].strip() == ex_host.strip():
                row_flag=1
        for ex_ds in exclude_datastore:
            if row[1].strip() == ex_ds.strip():
                row_flag=1
        if row_flag == 1:
            temp_AA.append(row)
    result_AA = list(set(AA) - set(temp_AA))
    #print AA,temp_AA
    #print result_AA,num
    BB = random.sample(result_AA,num)
    use_list=[]
    for HH in BB:
        use_list.append([HH[0],HH[1]])
    return use_list

def creat_cf_list():
    cf_name = '%s/config.clone'%(config_dir)
    f = open(cf_name,'r')
    cf=yaml.load(f)
    for k in cf.keys():
        stage_flag=0
        stage_list = []
        clone_cluster_list = []
        for j in cf[k]:
            stage_1 = j[2].strip()
            stage_list.append(stage_1)
            clone_cluster = j[8]
            clone_cluster_list.append(clone_cluster)
        AA = len(set(stage_list))
        for x in clone_cluster_list:
            while clone_cluster_list.count(x)>1:
                del clone_cluster_list[clone_cluster_list.index(x)]
        #BB = len(set(clone_cluster_list))
        BB = len(clone_cluster_list)

        if AA == 1 and BB == 1:
            stage_flag = 1
        else:
            stage_flag = 0
        if stage_flag == 0:
            print "config.clone stage wrong or cluster name for clone wrong"
            sys.exit(1)
    cf_full_name = '%s/full.config.clone'%(config_dir)
    f_full = open(cf_full_name,'w')
    for key in cf.keys():
        num = len(cf[key])
        stage_2 = cf[key][0][2]
        clone_cluster_2 = cf[key][0][8]
        H_D=find_host_ds(stage_2,num,clone_cluster_2)
        for num_AA in range(0,num):
            template_name = cf[key][num_AA][0]
            base_name = cf[key][num_AA][1]
            the_stage = cf[key][num_AA][2]
            vm_hostname = cf[key][num_AA][3]
            app = cf[key][num_AA][4]

            stat_the_host = cf[key][num_AA][5]
            if stat_the_host != None:
                the_host = stat_the_host
            else:
                the_host = H_D[num_AA][0]

            stat_datastore_name = cf[key][num_AA][6]
            if stat_datastore_name != None:
                datastore_name = stat_datastore_name
            else:
                datastore_name = H_D[num_AA][1]

            stat_ip_addr = cf[key][num_AA][7]
            if stat_ip_addr != None:
                ip_addr = stat_ip_addr
            else:
                ip_addr = get_ip_main_clone(the_stage)[0]

            #print 'stat_the_host is %s,  stat_datastore_name is %s, stat_ip_addr is %s'%(stat_the_host,stat_datastore_name,stat_ip_addr)
            #print 'the_host is %s,  datastore_name is %s,  ip_addr is %s'%(the_host,datastore_name,ip_addr)
            
            ip_suffix = '-'+ip_addr.split('.')[2]+'.'+ip_addr.split('.')[3]
            base_name_new = the_stage.upper() + '-' + base_name + ip_suffix
            vm_hostname_new = vm_hostname + ip_suffix
            #print base_name_new,vm_hostname_new,the_host,datastore_name
            
            stat_app = cf[key][num_AA][4]
            if stat_app != None:
                app = stat_app
                clone_str = "python teops_get_clone.py -t %s -b %s -d '%s' -H %s -c %s -i %s -m %s -a %s"%(template_name,base_name_new,datastore_name,the_host,the_stage,ip_addr,vm_hostname_new,app)
            else:
                clone_str = "python teops_get_clone.py -t %s -b %s -d '%s' -H %s -c %s -i %s -m %s"%(template_name,base_name_new,datastore_name,the_host,the_stage,ip_addr,vm_hostname_new)
            #print clone_str
            f_full.writelines(clone_str + '\n')
    f_full.close()
def clone_muti():
    #print "="*100
    cf_full_name = '%s/full.config.clone'%(config_dir)
    f_full = open(cf_full_name,'r')
    for line in f_full.readlines():
        #print line
        os.system(line)
    f_full.close()
    
config_dir = 'conf'
if __name__ == '__main__':
    if os.path.exists('log/list') == False:
        os.makedirs('log/list')
    os.system('python sql.creat_ip_list.py >> /dev/null')
    CUR_TIME = time.strftime('%Y-%m-%d_%H-%M-%S',time.localtime(time.time()))
    os.system('cp -f conf/config.clone.last log/list/config.clone.%s'%CUR_TIME)
    os.system('cp -f conf/full.config.clone log/list/full.config.clone.%s'%CUR_TIME)
    creat_cf_list()
    clone_muti()
    os.system('cp -f conf/config.clone conf/config.clone.last')
    os.system('>conf/config.clone')
