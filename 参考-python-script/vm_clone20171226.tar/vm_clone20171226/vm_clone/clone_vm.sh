#!/bin/bash
#python get_clone.py -t 'ST3-Template-RHEL6-test' -b test-temp3 -d '51.11' -H 10.10.51.11 -c st3 -i 10.10.70.250 -m test-tmct-6 -a 'zabbix' 'tomcat'
CUR_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
log="clone.log.${CUR_TIME}"
if [ ! -d ./log ]
then
mkdir -p ./log
fi
>log/${log}
cp -f conf/config.clone log/config.clone.${CUR_TIME}
while read line
do
	template_name=$(echo "$line"|awk -F, '{print $1}')
	base_name=$(echo "$line"|awk -F, '{print $2}')
        datastore_name=$(echo "$line"|awk -F, '{print $3}')
        the_host=$(echo "$line"|awk -F, '{print $4}')
        the_stage=$(echo "$line"|awk -F, '{print $5}')
        vm_ip=$(echo "$line"|awk -F, '{print $6}')
        vm_hostname=$(echo "$line"|awk -F, '{print $7}')
        app=$(echo "$line"|awk -F, '{print $8}')
	echo "====================================================================================="|tee -a log/${log}
	date +"%Y-%m-%d_%H-%M-%S"|tee -a log/${log}
	echo "python get_clone.py -t ${template_name} -b ${base_name} -d ${datastore_name} -H ${the_host} -c ${the_stage} -i ${vm_ip} -m ${vm_hostname} -a ${app} "|tee -a log/${log}
	echo "python get_clone.py -t ${template_name} -b ${base_name} -d ${datastore_name} -H ${the_host} -c ${the_stage} -i ${vm_ip} -m ${vm_hostname} -a ${app} "|sh |tee -a log/${log} 2>&1
	#python get_clone.py -t ${template_name} -b ${base_name} -d ${datastore_name} -H ${the_host} -c ${the_stage} -i ${vm_ip} -m ${vm_hostname} -a ${app} >>log/${log} 2>&1
done<conf/config.clone
