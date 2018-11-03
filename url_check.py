#!/usr/bin/env python
# _*_ coding:utf8 _*_
# author:JunfengWang
import os
import time
import datetime
import threading

import pycurl


srv_ip = ["192.168.60.50", "192.168.60.56"]
srv_code = ["trcactiveweb", "trccontentweb"]
port = "8080"


class CheckUrlThread(threading.Thread):
    def __init__(self, url):
        threading.Thread.__init__(self)
        self.f = open("/dev/null", "wb")
        self.url = url
        self.c = self.get_curl(url, self.f)
    #每个线程检测一个url，每个url最多检测9次，若一次失败，则5秒后再一次检测
    def run(self):
    	MAX_TRY = 9
    	count = 1
        while count < MAX_TRY:
            try:
                self.c.perform()
                HTTP_CODE = self.c.getinfo(self.c.HTTP_CODE)
                if HTTP_CODE == 200:
                    print "%s检查%s:服务可以正常访问,状态码为%s,线程结束\n" % (self.name, self.url, HTTP_CODE)
                    break
                else:
                    # print self.name + "第" + count + "次检查" + url + ":服务访问不通\n"
                    print "%s第%d次检查%s:服务访问不通,状态码为%s\n" % (self.name, count, self.url, HTTP_CODE)
                    time.sleep(5)
            except Exception, e:
                print "%s第%d次检查%s:服务访问不通,connection error:%s\n" % (self.name, count, self.url, str(e))
                time.sleep(5)
            count = count + 1
        self.f.close()
        self.c.close()

    @staticmethod		
    def get_curl(url, write_file):
        c = pycurl.Curl()
        c.setopt(pycurl.CONNECTTIMEOUT, 5)
        # 下载超时时间,5秒
        c.setopt(pycurl.TIMEOUT, 5)
        c.setopt(pycurl.FORBID_REUSE, 1)
        c.setopt(pycurl.MAXREDIRS, 1)
        c.setopt(pycurl.NOPROGRESS, 1)
        c.setopt(pycurl.DNS_CACHE_TIMEOUT, 30)
        c.setopt(pycurl.URL, url)
        c.setopt(pycurl.WRITEDATA, write_file)
        c.setopt(pycurl.WRITEHEADER, write_file)
        return c

        

if __name__ == '__main__':
    #time_start = datetime.datetime.now()
    # url = "http://192.168.60.56:8080/trcactiveweb/application.wadl"
    for ip in srv_ip:
        for code in srv_code:
            # url = ip+port+code
            url = "http://" + ip + ":" + port + "/" + code + "/application.wadl"
            # print url
            # 每生成一个url，就丢给一个新的线程去处理
            bc = CheckUrlThread(url)
            #bc.set_curl_opt()
            bc.start()
