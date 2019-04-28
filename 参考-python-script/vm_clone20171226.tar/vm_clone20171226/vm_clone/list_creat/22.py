#!/usr/bin/env python
import re,time,datetime
file_src = file('st2.list','r')
file_old = file('public.st2.csv','r')
list_file_src = []
list_file_old = []
start = datetime.datetime.now()
for AAAA in file_src.readlines():
	if len(AAAA.strip()) != 0:
		list_file_src.append(AAAA)
file_src.close()
mid = datetime.datetime.now()
for BBBB in file_old.readlines():
	if len(BBBB.strip()) != 0:
		list_file_old.append(AAAA)
file_old.close()
end = datetime.datetime.now()
#print mid - start
#print end - mid

#print list_file_src
#print list_file_old
