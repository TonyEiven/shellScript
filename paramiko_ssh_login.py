#!/usr/bin/python
#ssh
import paramiko
import sys,os

host='127.0.0.1'
user = 'whl'
password = '123456'

s = paramiko.SSHClient()                                 # ....
s.load_system_host_keys()                                # ....HOST....
s.set_missing_host_key_policy(paramiko.AutoAddPolicy())  # ......know_hosts......
s.connect(host,22,user,password,timeout=5)               # ......
while True:
        cmd=raw_input('cmd:')
        stdin,stdout,stderr = s.exec_command(cmd)        # ....
        cmd_result = stdout.read(),stderr.read()         # ......
        for line in cmd_result:
                print line,
s.close()

#paramiko..(..........)

#!/usr/bin/evn python
import os
import paramiko
host='127.0.0.1'
port=22
user = 'whl'
password = '123456'
ssh=paramiko.Transport((host,port))
privatekeyfile = os.path.expanduser('~/.ssh/id_rsa') 
mykey = paramiko.RSAKey.from_private_key_file( os.path.expanduser('~/.ssh/id_rsa'))   # ..key ...key...
ssh.connect(username=username,password=password)           # ......
# ..key. password=password .. pkey=mykey
sftp=paramiko.SFTPClient.from_transport(ssh)               # SFTP..Transport..
sftp.get('/etc/passwd','pwd1')                             # .. .........
sftp.put('pwd','/tmp/pwd')                                 # ..
sftp.close()
ssh.close()

#paramiko..(....)

#!/usr/bin/python
#ssh
import paramiko
import sys,os
host='127.0.0.1'
user = 'whl'
s = paramiko.SSHClient()
s.load_system_host_keys()
s.set_missing_host_key_policy(paramiko.AutoAddPolicy())
privatekeyfile = os.path.expanduser('~/.ssh/id_rsa')             # ..key..
mykey = paramiko.RSAKey.from_private_key_file(privatekeyfile)
# mykey=paramiko.DSSKey.from_private_key_file(privatekeyfile,password='061128')   # DSSKey.. password.key...
s.connect(host,22,user,pkey=mykey,timeout=5)
cmd=raw_input('cmd:')
stdin,stdout,stderr = s.exec_command(cmd)
cmd_result = stdout.read(),stderr.read()
for line in cmd_result:
        print line,
s.close()
