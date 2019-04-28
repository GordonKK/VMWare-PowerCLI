#!/bin/bash
CUR_TIME=$(date +"%Y-%m-%d_%H-%M-%S")
log="clone.log.${CUR_TIME}"
if [ ! -d ./log/list ]
then
mkdir -p ./log/list
fi
>log/${log}

echo "========================================================="
date +"%Y-%m-%d_%H-%M-%S"|tee -a log/${log}
echo "log  :  log/${log}"
echo "python clone_vm.py"|sh |tee -a log/${log} 2>&1
#python clone_vm.py >> log/${log} 2>&1
