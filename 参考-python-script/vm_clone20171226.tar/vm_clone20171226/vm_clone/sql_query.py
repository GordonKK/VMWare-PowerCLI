#!/usr/sbin/env python
#coding=utf8
import sys,os,yaml,readline,re,pymssql,datetime
#for >a.txt
reload(sys)
sys.setdefaultencoding("utf-8")

def list_echo(list):
        for i in list:
                print str(i)
def select_sql(sql_str,ip_str,db_str,port_str,user_str,password_str):
    try:
        #conn = pymssql.connect(host='192.168.63.250',user='lab',password='12345678',database='SCM-vCenter',port='1045')
        #conn = pymssql.connect(host=ip_str,user='lab',password='admin4elm',database=db_str,port=port_str)
        conn = pymssql.connect(host=ip_str,user=user_str,password=password_str,database=db_str,port=port_str)
        cur = conn.cursor()
        AAAA = cur.execute(sql_str)
        rows = cur.fetchall()
        return rows
    except:
        raise Exception,'connect or query database error'
    finally:
        conn.close()

#(8194, u'ST1-RHEL6.5_x64-65.130', u'192.168.65.130', u'OK', u'8384')
def echo_sql(kkk):
    for i in kkk:
        print ""
        print ','.join(map(str,i)),
def write_sql(kkk,file_name):
    f = file(file_name,'w')
    for i in kkk:
        f.writelines(','.join(map(str,i))+'\n')
    f.close()
def vcenter_info_2(stage):
    if stage in ['st1','st2','sandbox','dev']:
        stage_vc='st2'
        return stage_vc
    elif stage in ['st3']:
        stage_vc='st3'
        return stage_vc
    elif stage in ['nj']:
        stage_vc='nj'
        return stage_vc
    elif stage in ['dev_basic']:
        return 'dev_basic'
    else:
        print "wrong stage str"
        sys.exit(1)

def which_stage(stage='st2'):
    stage_vcenter  =  vcenter_info_2(stage)
    database = 'database'
    #cf_name = '%s/config.vcenter.db'%(config_dir)
    cf_name = '%s/config.vcenter'%(config_dir)
    f = open(cf_name)
    cf=yaml.load(f)
    f.close()
    sql_ip = cf[database][stage_vcenter]['ip']
    sql_db = cf[database][stage_vcenter]['dbname']
    sql_port = cf[database][stage_vcenter]['port']
    sql_user =  cf[database][stage_vcenter]['user']
    sql_password = cf[database][stage_vcenter]['password']
    return sql_ip,sql_db,sql_port,sql_user,sql_password
def find_farm_id(stage,cluster_name=None):
    cf_name = '%s/config.name_cluster'%(config_dir)
    f = open(cf_name)
    cf=yaml.load(f)
    f.close()
    farm_id_list=[]
    if cluster_name == None:
        all_name = cf[stage]
    else:
        all_name = cluster_name
    for name in all_name:
        sql_str = "SELECT ID FROM dbo.VPXV_ENTITY where NAME = '%s'"%name
        farm_id = get_result(sql_str,stage)
        if len(farm_id) == 0:
            print "Error: %s is not exist"%name
            sys.exit(1)
        else:
            farm_id_list.append(farm_id[0][0])
    return farm_id_list
def get_result(sql_str,stage):
    sql_result=select_sql(sql_str,*which_stage(stage))
    #print sql_result
    #AA=echo_sql(sql_result)
    #return AA
    return sql_result
    
def create_list(sql_str,stage,file_name):
    #which_stage(stage)
    sql_result=select_sql(sql_str,*which_stage(stage))
    list_dir='list_creat'
    file_name_2='%s/%s'%(list_dir,file_name)
    write_sql(sql_result,file_name_2)
    print "%s vm number is %s:"%(file_name,len(sql_result))
config_dir = 'conf'
list_dir='list_creat'
if __name__ == '__main__':
    if len(sys.argv) == 1:
        the_argv = 'st2'
    else:
        the_argv = sys.argv[1]
    which_stage(the_argv)
    file_ff = file('sql_aa.sql','r')
    sql_str = file_ff.readline()
    file_ff.close()
    sql_result=select_sql(sql_str,*which_stage(the_argv))
    echo_sql(sql_result)
    print "\nall vm number is :",len(sql_result)

