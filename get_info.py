mport paramiko
import json
import Queue
import threading

INFO = "/home/scripts/host_list"
ssh=paramiko.SSHClient()
ssh.set_missing_host_key_policy(paramiko.AutoAddPolicy())
class mutiple:
	_thread = 10
	
class tool:
	
	with open(INFO,'rb') as f:
		content = f.readlines()	
		hol = [ip.rstrip('\n') for ip in content]
		f.close()
	
	def build_queue(self):
		self.queue = Queue.Queue()
		self.result = Queue.Queue()
		
	def get_all(self):
		Group = {}
		for adr in hol:
			vm_info = {}
			ssh.connect(adr, 22, "root", "Aa147258")
			stdin, stdout, stderr = ssh.exec_command("virsh list")
			out = stdout.readlines()
			del out[0:2]
			out.pop()
			for phy_host in out:
				phy_host = phy_host.split()
				phy_host.pop()
				vm_info[phy_host[0]] = phy_host[1]
			Group[adr] = vm_info
			ssh.close()
		return Group
			
	def get_vmid(self):
		vmid = {}
		encom = get_all()
		for address in encom:
			vmid[address] = encom[address].keys()
		return vmid
		
	
	
	def get_vname():
		vname = {}
		encom = get_all()
		for address in encom:
			vname[address] = encom[address].values()
		return vname	
	
	def get_dminfo():
		belongto = {}
		vname = get_vname()
		for adr in vname:		
			pier = {}
			each_dom_info = {}
			ssh.connect(adr, 22, "root", "Aa147258")
			for each in vname[adr]:
				stdin, stdout, stderr = ssh.exec_command("virsh dominfo %s" % each)
				out = stdout.readlines()
				out.pop()
				for detail in out:
					detail = detail.split(':')
					detail[1] = detail[1].rstrip('\n')
					pier[detail[0]] = detail[1]
				each_dom_info[each] = pier
			belongto[adr] = each_dom_info
			ssh.close()
		return belongto
	
	print get_dminfo()


