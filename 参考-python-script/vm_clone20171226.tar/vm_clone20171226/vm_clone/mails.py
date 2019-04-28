#!/usr/bin/env python
# -*- coding: utf-8 -*-
#导入smtplib和MIMEText
import smtplib
from email.mime.text import MIMEText
import sys,os
import smtplib
import socket,time,datetime
from getpass import getpass
from email.MIMEText import MIMEText
from email.Utils import formatdate
from email.Header import Header
from email.mime.multipart import MIMEMultipart
reload(sys)
sys.setdefaultencoding('utf-8')
times2=datetime.datetime.now()
now=times2.strftime('%Y-%m-%d')
mail_to= sys.argv[1]
s=sys.argv[2]

mail_cc="POA_EA_LAB@99bill.com"
body='''<pre>快钱'''+now+'''号--TEOPS申请情况: </pre>'''
subject="快钱"+now+"号--TEOPS申请情况"
#s='''您申请的虚拟机被驳回'''
msg = MIMEMultipart('alternative')
msg['Subject'] = Header(subject,'utf-8')
html ='''
    <html>
      <head></head>
      <body>
           '''+s+'''
        </p>
      </body>
    </html>
    '''
hxy=body+html

htm = MIMEText(hxy,'html','utf-8')
msg.attach(htm)



msg['From'] = "notification@99bill.net"
msg['Date'] = formatdate()
msg['To'] = mail_to
msg['Cc'] = mail_cc
message=msg.as_string()

#s = smtplib.SMTP("192.168.63.153")
#s.starttls()
s = smtplib.SMTP()
s.connect("192.168.63.153")
#s.login("notification@99bill.net","Hxy8611726@")
s.sendmail("notification@99bill.net", [mail_to,mail_cc],message)
s.close()

