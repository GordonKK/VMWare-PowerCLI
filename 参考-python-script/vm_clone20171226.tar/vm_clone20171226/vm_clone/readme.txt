#克隆     最常使用   
1.配置好conf/config.clone ,可参考 conf/config.clone.example中例子
2.执行 sh muti_clone.sh

#              模板名           虚拟机名 环境名 hostname    应用名  宿主机名 存储名 虚拟机IP  指定集群
app1:
    - ['Template-14.251-RHEL6.5_x64',TMCT,st2,TMCT,"'zabbix' 'tomcat'",null,null,null,['Stage2-1','Stage2-2-ESXI5.5']]
    - ['Template-14.251-RHEL6.5_x64',TMCT,st2,TMCT,"'zabbix' 'tomcat'",null,null,null,['Stage2-1','Stage2-2-ESXI5.5']]
=========================================================================================================================
#config.clone 说明 ,参考 conf/config.clone.example中例子
1、同一app分组下的机器，会分配到不同的宿主机上(因同一应用节点需分配至不同宿主机)
2、同一个key也就是app分组下面，要求 环境名相同，指定克隆到的 集群名称要相同
   如果不同的环境，或者不同的 指定集群，需要写到不同的app分组
3、环境名请使用 st1 st2 st3 sandbox  dev  nj , 用 sandbox 不要使用 sb
4、主机名  存储名  虚拟机IP  指定集群 ,这四项如果要自动分配的，就在该位置上填 null，不要使用其他字符串
   指定存储，存储名用单引号，例如  'datastore1 (10)'
   一般来说只有 st2 和 st3 需要指定集群
   st2 一般用 ['Stage2-1','Stage2-2-ESXI5.5']
   st3 一般用 ['ST3-new']      此集群用于10.200网段
   st2 公共服务如apache tibco ftp等用 ['Stage2-Basic-1','Stage2-Basic-2-ESXI5.5']
   其它sandbox,dev,st1,nj 指定集群 用null
5、指定存储和宿主机时，请同时指定存储和宿主机
   不要只指定其中一个存储，宿主机设置null,也不要只指定宿主机，存储设置null
6、config.clone.last 是最近一次配置文件的拷贝,方便查看上一次配置

=========================================================================================================================
#只执行初始化   
对于已经克隆好的机器，如果是esxi5.0以上的，只执行初始化
注：虚拟机名要保证正确，虚拟机的hostname，使用准确的名字
#		        虚拟机名                   环境        IP地址            hostname            应用名
#python get_init.py -b ST2-TMCT-14.154   -c st2   -i  192.168.14.154  -m TMCT-14.154  -a  'zabbix' 'tomcat'

=========================================================================================================================
#旧版本esxi 只执行初始化
如果是已经克隆在4.0和4.1上的虚拟机执行初始化，
需要把 init_99bill.tgz 拷到目标机器解压,切换到root用户执行
注意::登陆到目标机器执行，而不是在中控机执行，误操作会将中控机初始化
#             环境    IP地址         hostname      应用名     应用名
#sh init.sh   st2    192.168.14.154  TMCT-14.154  'zabbix'   'tomcat'

=========================================================================================================================
#对于conf目录下的配置文件
config.clone                克隆配置文件
config.clone.example        配置config.clone 的样例参考
config.clone.last           保存上一次 config.clone 中的内容,因为每次执行克隆脚本后config.clone会清空,方便查看
config.net                  配置每个环境自动分配IP地址，所使用的网段
config.name_cluster         每个环境的克隆虚拟机的集群名称，要保持跟vcenter中一致，
config.vcenter              每个vcenter的ip、用户、密码，以及数据库的连接信息
config.exclude.host_datastore       配置每个vcenter当中要屏蔽的宿主机和存储
