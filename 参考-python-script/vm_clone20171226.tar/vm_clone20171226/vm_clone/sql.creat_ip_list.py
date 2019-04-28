#!/usr/sbin/env python
#coding=utf8
from sql_query import *

def creat_stage_list(stage):
    sql_str_base="SELECT DISTINCT a.RESOURCE_GROUP_ID,'',a.IP_ADDRESS,'',a.GUEST_OS,a.NAME FROM dbo.VPXV_VMS a,dbo.VPX_VM b, dbo.VPX_NIC c where a.VMID=b.ID and b.ID=c.ENTITY_ID  and b.AGENT_ID !='0' and a.POWER_STATE='on' and c.IS_CONNECTED='1' and a.RESOURCE_GROUP_ID in"
    farm_id_list = find_farm_id(stage)
    cluster_id_list = map(lambda x:int(x)+1,farm_id_list)
    cluster_str = ','.join(map(str,cluster_id_list))
    sql_str="%s (%s)"%(sql_str_base,cluster_str)
    create_list(sql_str,stage,'%s.list'%stage)


if __name__ == '__main__':
    creat_stage_list('st1')
    creat_stage_list('st2')
    creat_stage_list('st3')
    creat_stage_list('sandbox')
    creat_stage_list('dev')
    creat_stage_list('nj')

############ 未连接
    print '='*30+'网卡未连接'+'='*30
    sql_str="SELECT DISTINCT a.RESOURCE_GROUP_ID,'',a.IP_ADDRESS,'',a.GUEST_OS,a.NAME FROM dbo.VPXV_VMS a,dbo.VPX_VM b, dbo.VPX_NIC c where a.VMID=b.ID and b.ID=c.ENTITY_ID  and b.AGENT_ID !='0' and a.POWER_STATE='on' and c.IS_CONNECTED='0'"
    create_list(sql_str,'st3','st3_disconn.list')
    create_list(sql_str,'st2','st1_st2_sb_dev_disconn.list')
    create_list(sql_str,'nj','nj_disconn.list')
########多网卡，多IP
########vmtool进程经常挂掉的机器，固定写入一个文件
########关机状态
    print '='*30+'关机状态（含模板）'+'='*30
    sql_str="SELECT DISTINCT a.RESOURCE_GROUP_ID,'',a.IP_ADDRESS,'',a.GUEST_OS,a.NAME FROM dbo.VPXV_VMS a,dbo.VPX_VM b, dbo.VPX_NIC c where a.VMID=b.ID and b.ID=c.ENTITY_ID  and b.AGENT_ID !='0' and a.POWER_STATE='off'"
    create_list(sql_str,'st3','st3_off.list')
    create_list(sql_str,'st2','st1_st2_sb_dev_off.list')
    create_list(sql_str,'nj','nj_off.list')
####################
    os.system('cd list_creat;cp -af st1.list st2.list st3.list sandbox.list dev.list st1_st2_sb_dev_disconn.list st3_disconn.list st3_off.list st1_st2_sb_dev_off.list backup_list/')
    os.system('cd list_creat/;sed -i "s/^1126\|^1129/stage-01/g" st1.list;sed -i "s/^51\|^53\|^61\|^69/stage-02/g" st2.list;sed -i "s/^[0-9]\{1,\},/stage-03,/g" st3.list;sed -i "s/^31\|^102/sandbox/g" sandbox.list;sed -i "s/^71\|^79/dev/g" dev.list;')
    os.system('cd list_creat/;sed -ie "s/^1126\|^1129/stage-01/g;s/^51\|^53\|^61\|^69/stage-02/g;s/^31\|^102/sandbox/g;s/^71\|^79/dev/g" st1_st2_sb_dev_disconn.list;sed -i "s/^[0-9]\{1,\},/stage-03,/g" st3_disconn.list;')
    os.system('cd list_creat/;sed -ie "s/^1126\|^1129/stage-01/g;s/^51\|^53\|^61\|^69/stage-02/g;s/^31\|^102/sandbox/g;s/^71\|^79/dev/g" st1_st2_sb_dev_off.list;sed -i "s/^[0-9]\{1,\},/stage-03,/g" st3_off.list;')
