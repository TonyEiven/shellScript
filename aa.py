from paramiko.client import SSHClient, AutoAddPolicy

def install_glance(hostname, port, password):
    ssh_client = SSHClient()
    ssh_client.set_missing_host_key_policy(AutoAddPolicy)
    ssh_client.connect(
        hostname,
        port=port,
        username='root',
        password=password
    )
    try:
        _, stdout, stderr = ssh_client.exec_command('yum -y install git  && \
        pip install glances && pip install bottle && glances -w')
        if stdout.channel.recv_exit_status() != 0:
            raise Exception('Installation failed: ' + ''.join(x for x in stderr))
    finally:
        ssh_client.close()

if __name__ == '__main__':
	install_glance(hostname='10.200.147.23',port=22,password='86F33d#efe')