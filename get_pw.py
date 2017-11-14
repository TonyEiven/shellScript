# -*- coding: utf-8 -*-
import base64
import os,sys,datetime,csv
import platform
import re
import Queue
import threading
 
#sectionLable = ("[","]")
#endlineLable = "\r\n" 
#endlineLable = "\n"   
equalLable = "=" 
#noteLable = '#'
Pass_file = 'Passwd'

class tool:
	def build_check(self,input):
		self.queue = Queue.Queue()
		self.result = Queue.Queue()
		with open(input) as csvfile:
			spamreader = csv.DictReader(csvfile)
				
			for row in spamreader:
				cvk = row['Name']
				IP = row['IP']
				root = row['root']
				pwd = row['pwd']
					
				self.queue.put([cvk, IP, root, pwd])
	
	def env_check(self):
		"""
		Function to return a statu value to determine 
		that script running on the right platform
	
		"""
		arch = platform.architecture()[1]
		status = 0
		if arch == 'WindowsPE':
			if os.path.exists(Pass_file) == True:
				return status
			elif os.path.exists(Pass_file) == False:
				print "Error, without password file (%s)!" % Pass_file
				status = 1
		elif arch == 'ELF':
			return "Current operation system is (%s), doesn't support"  % arch
		return status
	def getMainInfo(self,info):
		"""
		Function to return a dict includes keys and values
	
		"""
		parameter = []
		para = {}
		f = open(info,"rb")
                strFileContent = f.readlines()
                f.close()
		for content in strFileContent:
			section = re.findall('\[.*\]',content)        # through re module match string you want
			pair = re.findall('^[A-Z].*',content,re.M)      
			if len(pair) > 0:
				parameter.append(pair)
		for arg in parameter:
			for subarg in arg:
				key = subarg.split(equalLable)[0]
				value = subarg.split(equalLable)[1]
				para[key] = value.rstrip("\r")
		return para
	
	def encrypt(self,**kwargs):
		"""
		Function to encrypt hostname, ipaddress and password
		"""
		wrap = {}
		for k,v in kwargs.items():
			key = k
			value = base64.b64encode(v)
			wrap[key] = value
		return wrap
		
if __name__ == '__main__':
	instance = tool()
	b = instance.getMainInfo
	print b



