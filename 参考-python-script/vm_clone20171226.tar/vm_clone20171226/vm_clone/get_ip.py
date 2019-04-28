#!/usr/bin/env python
#coding=utf8
#st1,65    st2,14   st3   sandbox,12,13     dev,15,47
import sys,os,yaml,argparse,re
def list_echo(list):
        for i in list:
                print str(i)
def ip2int(s):
    list_AA = [int(i) for i in s.split('.')]
    return (list_AA[0] << 24) | (list_AA[1] << 16) | (list_AA[2] << 8) | list_AA[3]
def get_ip_all(file_name_list,file_new):
    ip_list_a=[]
    f_new=file('%s/%s'%(list_dir,file_new),'w')
    for file_name in file_name_list:
        f = file('%s/%s'%(list_dir,file_name),'r')
        for line in f.readlines():
            f_new.writelines(line.strip('\n')+','+file_name+'\n')
            line_num = len(line.split(','))
            
            if line_num<3:
                continue
            line_match_ip = re.search(r'\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}',line.split(',')[2].strip())
            if len(line.strip()) != 0 and line.split(',')[2].strip() != 'None' and line_match_ip != None:
                ip_list_a.append(line.split(',')[2].strip())
        f.close()
    f_new.close()
    ip_list_a.sort(lambda x, y: cmp(ip2int(x), ip2int(y)))
    return ip_list_a
def get_ip_free(ip_list,ip_net,ip_pre='192.168'):
    ip_free=[]
    for net in ip_net:
        #AAAA='ip_free_%s'%(net)
        AAAA_list=[]
        for j in range(1,254):
            ip_aa = "%s.%s.%s"%(ip_pre,net,j)
            if ip_aa in ip_list:
                pass
            else:
                AAAA_list.append(ip_aa)
                ip_free.append(ip_aa)
        #print "################# net: %s  free ip number: %s #################"%(net,len(AAAA_list))
        #list_echo(AAAA_list)
    #print "################# ip_net: %s  free ip number: %s #################"%(ip_net,len(ip_free))
    #list_echo(ip_free)
    return ip_free
def net_info(stage):
    the_env = stage
    cf_name = '%s/config.net'%config_dir
    f = open(cf_name)
    cf=yaml.load(f)
    f.close()
    net_A = cf[stage]
    return net_A
def ip_file():
    ip_on_file = ['st1.list','st2.list','st3.list','sandbox.list','dev.list','nj.list']
    ip_dis_file = ['st3_disconn.list','st1_st2_sb_dev_disconn.list','nj_disconn.list']
    ip_off_file = ['st3_off.list','st1_st2_sb_dev_off.list','nj_off.list']
    ip_no_vmtool_file = ['stat_no_vmtool.list']
    ip_physical_file = ['stat_physical.list']
    ip_register_file = ['stat_register.list']
    ip_nj_file = ['stat_exclude.list']
    ip_file_A = ip_on_file + ip_dis_file + ip_off_file + ip_no_vmtool_file + ip_physical_file + ip_register_file + ip_nj_file
    return ip_file_A

def get_ip_main_clone(stage,number=1,net_v=[]):
    BBBB = get_ip_main(stage,net_v)
    list_result=[]
    count = 0
    while(count<number):
        count +=1
        while True:
            ip =  BBBB.pop(0)
            ip_2 = ping_act(ip)
            if ip_2:
                list_result.append(ip)
                write_stat_ip(stage,ip)
                break
            else:
                print "%s already in use"%ip
    #print list_result
    return list_result
            
def get_ip_main(stage,net_v=[]):
    ip_all_file = ip_file()
    if net_v == []:
        ip_net = net_info(stage)
    else:
        ip_net = net_v
    #ip_net = ['15','47']
    ip_all_list = get_ip_all(ip_all_file,ip_all_file_new)
    if stage == 'st3':
        return get_ip_free(ip_all_list,ip_net,'10.10')
    else:
        return get_ip_free(ip_all_list,ip_net)
def ping_act(ip_addr):
    AA=os.system('ping -c 2 -W 1 %s &> /dev/null'%ip_addr)
    if AA:
        return ip_addr
    else:
        return None
    
def write_stat_ip(stage,ip,file_name='stat_register.list'):
    f = file('%s/%s'%(list_dir,file_name),'a')
    f.writelines(stage+',,'+ip+',\n')
    f.close()
def get_ip_info(ip):
    ip_all_file = ip_file()
    get_ip_all(ip_all_file,ip_all_file_new)
    for the_ip in ip:
        os.system('grep --color -w %s %s/%s'%(the_ip,list_dir,ip_all_file_new))
    
config_dir = 'conf'    
list_dir='list_creat'
ip_all_file_new='all_ip.list'
if __name__ == '__main__':
    os.system('python sql.creat_ip_list.py >> /dev/null')
    #get_ip_main_clone('dev',3)
    #get_ip_main_clone('st3',4,[50])
    #A = get_ip_main('dev',['6','12'])
    #list_echo(A)
    #A = get_ip_main('st3',['71','50'])
    #list_echo(A)
    description_str='''
for example:
------------------------------------------------------

example 1:
python %s   -c  dev
查询 dev的  所有可用IP地址
------------------------------------------------------

example 2:
python %s   -c  dev   --net 15
查询   dev的  15网段   的所有可用IP地址
------------------------------------------------------

example 3:
python %s   -c  st2   --net 14   --num 3
为st2的   14网段   分配   3个 IP地址
------------------------------------------------------

example 4:
python %s   -i    192.168.52.216
查询   192.168.52.216 的虚拟机信息
------------------------------------------------------
'''%(sys.argv[0],sys.argv[0],sys.argv[0],sys.argv[0])
    parser = argparse.ArgumentParser(formatter_class=argparse.RawDescriptionHelpFormatter,description=description_str)
    parser.add_argument('-i',nargs="+",required=False, help='Search ip info')
    parser.add_argument('-c',required=False,choices=['st1', 'st2', 'st3','sandbox','dev','nj'], help='which stage use only: st1 st2 st3 sandbox dev nj')
    parser.add_argument('--net',nargs="+",required=False, help='which net ,such as 15,47,12,65')
    parser.add_argument('--num',required=False, help='number of ip',type=int)
    args = parser.parse_args()
    
    search_ip = args.i
    the_stage = args.c
    the_net = args.net
    the_num = args.num
    if search_ip != None:
        get_ip_info(search_ip)
    if the_stage != None and the_net == None and the_num == None:
        AAAA = get_ip_main(the_stage)
        list_echo(AAAA)
        print "################# net: %s  free ip number: %s #################"%(the_stage,len(AAAA))
    if the_stage != None and the_net != None and the_num == None:
        AAAA = get_ip_main(the_stage,the_net)
        list_echo(AAAA)
        print "################# net: %s  free ip number: %s #################"%(the_net,len(AAAA))
    if the_stage != None and the_net != None and the_num != None:
        AAAA = get_ip_main_clone(the_stage,the_num,the_net)
        list_echo(AAAA)
