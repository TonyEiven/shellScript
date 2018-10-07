#!/usr/bin/env python
# -*- coding: utf-8 -*-

import paramiko
import datetime
from urllib import request
import base64
import json
from optparse import OptionParser

class SSHClient():
    def __init__(self,host,port,user,pkey_file):
        self.host = host
        self.port = port
        self.user = user
        self.pkey_file = paramiko.RSAKey.from_private_key_file(pkey_file)
        self.trans = paramiko.Transport((self.host,self.port))
        self.trans.connect(username=self.user,pkey=self.pkey_file)
        self.conn = paramiko.SSHClient()
        self.conn._transport = self.trans

    def CommandExec(self,command):
        try:
            stdin,stdout,stderr = self.conn.exec_command(command)
            result = stdout.read()
            if len(result) == 0:
                print(stderr.read().decode())
            else:
                print(str(result,'utf-8'))
        except paramiko.SSHException as e:
            print("Fails to execute the command %s" %e)

    def close(self):
        self.trans.close()

    def TransFiles(self,lfile,refile):
        # Instanciate a sftp object, specify connection channel
        return_code = True
        try:
            sftp = paramiko.SFTPClient.from_transport(self.trans)
            sftp.put(localpath=lfile,remotepath=refile)
        except Exception as e:
            print("Can't transfer file to remote host, eror %s" %e)
            return_code = False
            return return_code
        return return_code

    def GetFiles(self,refile,lfile):
        return_code = True
        try:
            sftp = paramiko.SFTPClient.from_transport(self.trans)
            sftp.get(remotepath=refile,localpath=lfile)
        except Exception as e:
            print("Can't get files from remote host, eror %s" %e)
            return_code = False
            return return_code
        return return_code


class Request():
    def __init__(self,user,pwd):
        self.user = user
        self.pwd = pwd
        self.method = ["GET","POST","PUT","DELETE"]
    
    def URIRequest(self,method,endpoint,postdata=None):
        json_ret = {"status":"succeed"}
        ret_code = 400
        authv = "%s:%s" %(self.user,self.pwd)
        decoded_authv = base64.b64encode(bytes(authv,encoding="utf-8")).decode()
        autheader = "Basic %s" %decoded_authv
        if str.upper(method) == self.method[0]:
            req = request.Request(endpoint)
            req.add_header('Content-Type','application/json')
            req.add_header('Accept','application/json')
            req.add_header('Authorization',autheader)
            with request.urlopen(req) as f:
                json_ret = f.read().decode("utf-8")
                ret_code = f.status
        if str.upper(method) == self.method[2]:
            req = request.Request(endpoint,method=self.method[2])
            req.add_header('Authorization',autheader)
            with request.urlopen(req) as f:
                json_ret = f.read().decode("utf-8")
                ret_code = f.status
        if str.upper(method) == self.method[3]:
            req = request.Request(endpoint,method=self.method[3])
            req.add_header('Authorization',autheader)
            with request.urlopen(req) as f:
                json_ret = f.read().decode("utf-8")
                ret_code = f.status
        return ret_code,json_ret

def SendDingding(token,msg,mobile):
    """
    send dingding alert info
    """
    baseAPI = "https://oapi.dingtalk.com/robot/send"
    webhook = baseAPI + "?" + "access_token=" + token
    raw = {"msgtype":"text","text":{"content":msg},"at":{"atMobiles":[mobile],"isAtAll":"True"}}
    dingmsgdata = json.dumps(raw).encode("utf-8")
    req = request.Request(url=webhook,data=dingmsgdata)
    req.add_header('Content-Type','application/json')
    with request.urlopen(req) as f:
        print(f.status)

def InstanceUnmarshel(content):
    instanceinfo = {}
    httpbody = json.loads(content)
    for (k,v) in httpbody.items():
        if isinstance(v,dict):
            for (keys,values) in v.items():
                instanceinfo[keys] = values
    return instanceinfo

def AppUnmarshel(content):
    appinfo = {}
    httpbody = json.loads(content)
    appinfo = httpbody['application']
    return appinfo

def AppsUnmarshel(content):
    appsinfo = {}
    httpbody = json.loads(content)
    appsinfo = httpbody['applications']
    return appsinfo        


def _request(u,p,eurekaddr,appname,instancetag,instanceport):
    port = "30000"
    ep = "http://" + eurekaddr + ":" + port + "/eureka/apps/" + appname + "/" + instancetag +":"  + str.lower(appname) + ":" + instanceport
    print(ep)
    #test.TransFiles(lfile="SalmanKhan_2011-480p-en.mp4",refile="/root/SalmanKhan_2011-480p-en.mp4")
    #print(datetime.datetime.now().strftime("%Y%m%d%H%M"))
    req = Request(user=u,pwd=p)
    retcode, jsonret = req.URIRequest(method="get",endpoint=ep)
    parsed = InstanceUnmarshel(jsonret)
    return retcode,parsed['statusPageUrl'],parsed['healthCheckUrl'],parsed['status']

def _exec(host,user,pkey):
    test = SSHClient(host=host,port=22,user=user,pkey_file=pkey)
    commandcoll = ["ip a show eth0"]
    for i in commandcoll:
        resinfo = test.CommandExec(i)
        print(resinfo)
    test.close()

if __name__ == '__main__':
    addr = "116.62.208.59"
    apn = "FOUNDATION-AUTH"
    instag = "10.206.119.193"
    insport = "8088"
    (code,statusPageUrl,healthCheckUrl,Status) = _request("focus","focus666uat",eurekaddr=addr,appname=apn,instancetag=instag,instanceport=insport)
    if code == 200:
        msg = ("Severity: Severe!!!" '\n'
        "EurekAddr: http://%s:30000/ " '\n'
        "ApplicationName: %s" '\n'
        "InstanceName: %s:%s:%s" '\n'
        "Status: %s" %(addr,apn,instag,str.lower(apn),insport,Status))
        SendDingding(token="1b49c603ebea4980551ad4a1c316de5e4be22c11c633d5856b60b7317d6c31ae",msg=msg,mobile="15068765534")
    _exec(host="10.200.164.8",user="root",pkey="D:\key\dev_vm_node1")
    
