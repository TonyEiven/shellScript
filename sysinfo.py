#!/usr/bin/env python2.7 
# -*- coding:utf-8 -*- 
import os 
import subprocess 
import re 
import hashlib 
 
def sub_dict(form_dict, sub_keys, default=None): 
    return dict([(k, form_dict.get(k.strip(), default)) for k in sub_keys.split(',')]) 

# dmidecode -t 4 
def read_cpuinfo(): 
    cpu_stat = [] 
    with open('/proc/cpuinfo', 'r') as f: 
        data = f.read() 
        for line in data.split('\n\n'): 
            cpu_stat.append(line) 
    return cpu_stat[-2] 

def read_fdisk(): 
    p = subprocess.Popen('fdisk -l', stdout=subprocess.PIPE, shell=True) 
    out = p.communicate()[0] 
    info = [] 
    for i in out.split('\n\n'): 
        for x in i.splitlines(): 
            if x: 
                info.append(x) 
    return info 

def read_dmidecode(): 
    p = subprocess.Popen('dmidecode -t 1', stdout=subprocess.PIPE, shell=True) 
    return p.communicate()[0] 

def read_ifconfig(): 
    p = subprocess.Popen('ifconfig', stdout=subprocess.PIPE, shell=True) 
    return p.communicate()[0] 

def get_cpuinfo(data): 
    cpu_info = {} 
    for i in data.splitlines(): 
        k, v = [x.strip() for x in i.split(':')] 
        cpu_info[k] = v 
        
    cpu_info['physical id'] = str(int(cpu_info.get('physical id')) + 1) 
    return sub_dict(cpu_info, 'model name,physical id,cpu cores') 

def get_diskinfo(data): 
    disk_info = {} 
    m_disk = re.compile(r'^Disk\s/dev') 
                
    for i in data: 
        if m_disk.match(i): 
            i = i.split(',')[0] 
            k, v = [x for x in i.split(':')] 
            disk_info[k] = v 
    return disk_info 
 
def get_dmiinfo(data): 
    dmi_info = {} 
    line_in = False
    for line in data.splitlines(): 
        if line.startswith('System Information'): 
            line_in = True
            continue
        if line.startswith('\t') and line_in: 
            k, v = [i.strip() for i in line.split(':')] 
            dmi_info[k] = v 
        else: 
            line_in = False
    return sub_dict(dmi_info, 'Manufacturer,Product Name,Serial Number') 

def get_ipinfo(data): 
    data = (i for i in data.split('\n\n') if i and not i.startswith('lo')) 
    ip_info = [] 
    ifname = re.compile(r'(eth[\d:]*|wlan[\d:]*)') 
    ipaddr = re.compile(r'(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})(\.(25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[0-9]{1,2})){3}') 
    macaddr = re.compile(r'[A-F0-9a-f:]{17}') 
    for i in data: 
        x = {} 
        if ifname.match(i): 
            device = ifname.match(i).group() 
            x['Adapter'] = device 
        if macaddr.search(i): 
            mac = macaddr.search(i).group() 
            x['MAC'] = mac 
        if ipaddr.search(i): 
            ip = ipaddr.search(i).group() 
            x['IP'] = ip 
        else: 
            x['IP'] = None
        ip_info.append(x) 
    return ip_info 

def get_meminfo(): 
    mem_info = {} 
    with open('/proc/meminfo', 'r') as f: 
        data = f.readlines() 
        for i in data: 
            k, v = [x.strip() for x in i.split(':')] 
            mem_info[k] = int(v.split()[0]) 
    return sub_dict(mem_info, 'MemTotal,SwapTotal') 

def get_osinfo(): 
    os_info = {} 
    i = os.uname() 
    os_info['os_type'] = i[0] 
    os_info['node_name'] = i[1] 
    os_info['kernel'] = i[2] 
    return os_info 

def get_indentity(data): 
    match_serial = re.compile(r"Serial Number: .*", re.DOTALL) 
    match_uuid = re.compile(r"UUID: .*", re.DOTALL) 
    if match_serial.search(data): 
        serial = match_serial.search(data).group() 
    if match_uuid.search(data): 
        uuid = match_uuid.search(data).group() 
    if serial: 
        serial_md5 = hashlib.md5(serial).hexdigest() 
        return serial_md5 
    elif uuid: 
        uuid_md5 = hashlib.md5(uuid).hexdigest() 
        return uuid_md5 
if __name__ == "__main__": 
    ipinfo = get_ipinfo(read_ifconfig()) 
    dmiinfo = get_dmiinfo(read_dmidecode()) 
    cpuinfo = get_cpuinfo(read_cpuinfo()) 
    diskinfo = get_diskinfo(read_fdisk()) 
    meminfo = get_meminfo() 
    osinfo = get_osinfo() 
    identity = get_indentity(read_dmidecode())
