#!/usr/bin/env python
# _*_ coding:utf8 _*_
# author:ShenJiaYi 
import pycurl
import os
import sys
import urllib2
import time
import datetime
import threading
from timeit import timeit  

def get_curl(url, write_file):
	c = pycurl.Curl()
	c.setopt(pycurl.CONNECTTIMEOUT, 5)
	c.setopt(pycurl.TIMEOUT, 5)
	c.setopt(pycurl.FORBID_REUSE, 1)
	c.setopt(pycurl.MAXREDIRS, 1)
	c.setopt(pycurl.NOPROGRESS, 1)
	c.setopt(pycurl.DNS_CACHE_TIMEOUT, 30)
	c.setopt(pycurl.NOSIGNAL, True)
	c.setopt(pycurl.URL, url)
	c.setopt(pycurl.WRITEDATA, write_file)
	c.setopt(pycurl.WRITEHEADER, write_file)
	return c

def health_check():
	f = open("/dev/null",'wb')
	url = sys.argv[1]
	c = get_curl(url,f)
	try:
		c.perform()
		global HTTP_CODE
		HTTP_CODE = c.getinfo(c.HTTP_CODE)
		print(HTTP_CODE)
		content = urllib2.urlopen(url).read()
		print content
	except Exception, e:
		time.sleep(1)
		health_check()

global HTTP_CODE
HTTP_CODE = "error"
if __name__ == '__main__':
	timeout = sys.argv[2]
	t = threading.Thread(target=health_check)
	t.setDaemon(True)
	t.start()
	t.join(int(timeout))
	if HTTP_CODE == "error":
		#print("service start faild!")
                print('\033[1;31m ERROR:')
                print("service start faild! \033[0m")
	elif HTTP_CODE == 200:
		#print("service start secceed!")
		print("\033[1;32m service start secceed! \033[0m")
