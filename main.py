#! /usr/bin/python

__version__ = "1.0"

import pdb
import hpilo
import csv, os, sys, datetime
from operator import itemgetter
from optparse import OptionParser
import Queue
import threading
#from test.test_threading_local import _thread
#from ctypes.test.test_errno import threading
#from novaclient.tests.unit.v2.contrib.test_instance_actions import InstanceActionExtensionTests

class config:    
    _thread = 2
    plat_name = 'qzzwy'    
    
    mail_group = {'qzzwy': {'mail_from': 'app.casadmin@h3c.com', 
                         'mailto_list': ['fw.niwei@h3c.com', 'fw.xubiao@h3c.com'], 
                         #'mailto_list': ['li.mei@h3c.com'], 
                         'mail_host': 'smtp.h3c.com', 
                         'mail_user': 'Appcasadmin', 
                         'mail_pwd': ''}
                  }

class tool:
    def build_checkqueue(self, input):
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
    
    def output_result(self, output, mode=0):
        if mode == 0:
            with open(output, 'w') as file:
                title = "Name,IP,SN,temperature,storage,fans,bios_hardware,memory,power_supplies,processor,network\n"
                file.write(title)
                
                while not self.result.empty():
                    item = self.result.get()
                    print item
                    file.write(item)
        elif mode == 1:
            with open(output, 'w') as file:
                title = "Name,IP,Product,SN,FW Version,CPU Type,Sockets,Cores,Mem Sockets,Capacity,PartNumber,MAC1,MAC2,MAC3,MAC4\n"
                file.write(title)
                
                while not self.result.empty():
                    item = self.result.get()
                    print item
                    file.write(item)
                
                #self.result.task_done()
            
            #self.result.join()
    
    def check_healthinqueue(self, i):
        while True:
            iLOInfo = self.queue.get()
            
            cvk = iLOInfo[0]
            IP = iLOInfo[1]
            root = iLOInfo[2]
            pwd = iLOInfo[3]
            
            try:
                ilo = hpilo.Ilo(IP,root,pwd)
                chassis = ilo.get_network_settings()
                #print chassis
                sn = chassis["dns_name"].lstrip("ILO")

                # cpu info
                chassis = ilo.get_embedded_health()
                #print(chassis['health_at_a_glance'])
                health = chassis['health_at_a_glance']
                status_temperature = health['temperature']['status']
                status_storage = health['storage']['status']
                status_fans = health['fans']['status']
                status_bios_hardware = health['bios_hardware']['status']
                status_memory = health['memory']['status']
                status_power_supplies = health['power_supplies']['status']
                status_processor = health['processor']['status']
                status_network = health['network']['status']
                #print(status_temperature)
            except hpilo.IloCommunicationError:
                sn = status_temperature = status_storage = status_fans = \
                status_bios_hardware = status_memory = status_power_supplies = \
                status_processor = status_network = 'UNKNOWN'
            except:
                sn = status_temperature = status_storage = status_fans = \
                status_bios_hardware = status_memory = status_power_supplies = \
                status_processor = status_network = 'ERR'
            
            result = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}\n".format(cvk, IP, sn, status_temperature
                        , status_storage, status_fans, status_bios_hardware
                        , status_memory, status_power_supplies, status_processor, status_network)
            #file.write(result)
            self.result.put(result)
            #print result
            print '{0} end'.format(IP)
            
            self.queue.task_done()
    
    def check_health(self, input, output):
        '''Check server embedded health
        
        input is a csv file, contains servername,iLO ip,iLO root and password
        
        output is a csv file, record server emebedded health status 
        '''
        table = []
        with open(input) as csvfile:
            spamreader = csv.DictReader(csvfile)
    
            with open(output, 'w') as file:
                title = "Name,IP,SN,temperature,storage,fans,bios_hardware,memory,power_supplies,processor,network\n"
                file.write(title)
		
                for row in spamreader:
                    cvk = row['Name']
                    IP = row['IP']
                    root = row['root']
                    pwd = row['pwd']
    
                    # sn
                    #pdb.set_trace()
                    try:
                        ilo = hpilo.Ilo(IP,root,pwd)
                        chassis = ilo.get_network_settings()
                        #print chassis
                        sn = chassis["dns_name"].lstrip("ILO")
        
                        # cpu info
                        chassis = ilo.get_embedded_health()
                        #print(chassis['health_at_a_glance'])
                        health = chassis['health_at_a_glance']
                        status_temperature = health['temperature']['status']
                        status_storage = health['storage']['status']
                        status_fans = health['fans']['status']
                        status_bios_hardware = health['bios_hardware']['status']
                        status_memory = health['memory']['status']
                        status_power_supplies = health['power_supplies']['status']
                        status_processor = health['processor']['status']
                        status_network = health['network']['status']
                        #print(status_temperature)
                    except hpilo.IloCommunicationError:
                        sn = status_temperature = status_storage = status_fans = \
                        status_bios_hardware = status_memory = status_power_supplies = \
                        status_processor = status_network = 'UNKNOWN'
                    except:
                        sn = status_temperature = status_storage = status_fans = \
                        status_bios_hardware = status_memory = status_power_supplies = \
                        status_processor = status_network = 'ERR'
                    
                    result = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10}\n".format(cvk, IP, sn, status_temperature
                                , status_storage, status_fans, status_bios_hardware
                                , status_memory, status_power_supplies, status_processor, status_network)
                    file.write(result)
                    print '{0} end'.format(IP)
    
    def check_confinqueue(self, i):
        '''Check server hardware configure
        
        input is a csv file, contains servername,iLO ip,iLO root and password
        
        output is a csv file, record server hardware configure 
        '''
        #table = []
        while True:
            iLOInfo = self.queue.get()
            
            cvk = iLOInfo[0]
            IP = iLOInfo[1]
            root = iLOInfo[2]
            pwd = iLOInfo[3]
            
            try:
                    # sn
                ilo = hpilo.Ilo(IP,root,pwd)
                #chassis = ilo.get_network_settings()
                #print chassis
                chassis = ilo.get_host_data()
                #sn = chassis["dns_name"].lstrip("ILO")
                sn = chassis[1]["Serial Number"]

                # product name
                product = ilo.get_product_name()

                fwinfo = ilo.get_fw_version()
                fwversion = "{0} {1}".format(fwinfo['firmware_version'], fwinfo['firmware_date'])

                # cpu info
                chassis = ilo.get_embedded_health()
                cpucore = chassis['processors'].itervalues().next()
                cpuname = cpucore['name']
                cpucount = len(chassis['processors'])
                cpucores = cpucore['execution_technology'][:cpucore['execution_technology'].index('/')]

                # mem info
                memOK = 0
                memErr = 0
                memNull = 0
                memCapacity = 0
                partnumber = {}
                for memboard in chassis['memory']['memory_details'].itervalues():
                    for socket in memboard.itervalues():
                        #print socket["part"]["number"];
                        partnumber = socket["part"]["number"];
                        if(socket['status']=='Good, In Use'):
                            memOK = memOK + 1
                            memCapacity = socket['size'] if memCapacity == 0 else memCapacity
                        elif(socket['status']=='Present, Unused'):
                            memErr = memErr + 1
                        elif(socket['status']=='Not Present'):
                            memNull = memNull + 1
                        elif(socket['status']=='Degraded'):
                            memErr = memErr +1
                
                # nic info
                nicinfo = chassis['nic_information']
                mac1 = nicinfo['NIC Port 1']['mac_address']
                mac2 = nicinfo['NIC Port 2']['mac_address']
                mac3 = nicinfo['NIC Port 3']['mac_address']
                mac4 = nicinfo['NIC Port 4']['mac_address']
                '''
                # temperature
                temps = chassis['temperature']
                table_temps = []
                for temp in temps.itervalues():
                    #print temp.keys()
                    temp_status = temp['status']
                    temp_current = temp['currentreading']
                    temp_label = temp['label']
                    temp_critical = temp['critical']
                    temp_caution = temp['caution']
                    temp_location = temp['location']
                    table_temps.append([temp_status, temp_current, temp_label, temp_critical, temp_caution, temp_location])
                import tabulate
                #sorted(table_temps, key=self.getKey)
                table_temps.sort(key=itemgetter(5))
                #print tabulate.tabulate(table_temps, ['status', 'currentreading', 'label', 'critical', 'caution', 'location'])
                
                fans = chassis['fans']
                print fans
                   '''
                #print chassis['temperature']['05-CPU 4']
            
            except hpilo.IloCommunicationError:
                sn = status_temperature = status_storage = status_fans = \
                status_bios_hardware = status_memory = status_power_supplies = \
                status_processor = status_network = 'UNKNOWN'
            except:
                sn = status_temperature = status_storage = status_fans = \
                status_bios_hardware = status_memory = status_power_supplies = \
                status_processor = status_network = 'ERR'

            result = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13},{14}\n".format(
                cvk, IP, product, sn, fwversion, cpuname, cpucount, cpucores, memOK + memErr, memCapacity, partnumber, mac1, mac2, mac3, mac4)
            
            self.result.put(result)
                
            print '{0} end'.format(IP)
            
            self.queue.task_done()
                    #file.write(result)
                    #print result
    
    def check_conf(self, input, output):
        '''Check server hardware configure
        
        input is a csv file, contains servername,iLO ip,iLO root and password
        
        output is a csv file, record server hardware configure 
        '''
        #table = []
        with open(input) as csvfile:
            spamreader = csv.DictReader(csvfile)
    
            with open(output, 'w') as file:
                title = "Name,IP,Product,SN,FW Version,CPU Type,Sockets,Cores,Mem Sockets,Capacity,PartNumber,MAC1,MAC2,MAC3,MAC4\n"
                file.write(title)
                
                for row in spamreader:
                    cvk = row['Name']
                    IP = row['IP']
                    root = row['root']
                    pwd = row['pwd']
    
                    # sn
                    ilo = hpilo.Ilo(IP,root,pwd)
                    chassis = ilo.get_network_settings()
                    #print chassis
                    sn = chassis["dns_name"].lstrip("ILO")
    
                    # product name
                    #product = ilo.get_product_name()
    
                    fwinfo = ilo.get_fw_version()
                    fwversion = "{0} {1}".format(fwinfo['firmware_version'], fwinfo['firmware_date'])
    
                    # cpu info
                    chassis = ilo.get_embedded_health()
                    cpucore = chassis['processors'].itervalues().next()
                    cpuname = cpucore['name']
                    cpucount = len(chassis['processors'])
                    cpucores = cpucore['execution_technology'][:cpucore['execution_technology'].index('/')]
    
                    # mem info
                    memOK = 0
                    memErr = 0
                    memNull = 0
                    memCapacity = 0
                    for memboard in chassis['memory']['memory_details'].itervalues():
                        for socket in memboard.itervalues():
                            if(socket['status']=='Good, In Use'):
                                memOK = memOK + 1
                                memCapacity = socket['size'] if memCapacity == 0 else memCapacity
                            elif(socket['status']=='Present, Unused'):
                                memErr = memErr + 1
                            elif(socket['status']=='Not Present'):
                                memNull = memNull + 1
                            elif(socket['status']=='Degraded'):
                                memErr = memErr +1
                    
                    # nic info
                    nicinfo = chassis['nic_information']
                    mac1 = nicinfo['NIC Port 1']['mac_address']
                    mac2 = nicinfo['NIC Port 2']['mac_address']
                    mac3 = nicinfo['NIC Port 3']['mac_address']
                    mac4 = nicinfo['NIC Port 4']['mac_address']
                    
                    # temperature
                    temps = chassis['temperature']
                    table_temps = []
                    for temp in temps.itervalues():
                        #print temp.keys()
                        temp_status = temp['status']
                        temp_current = temp['currentreading']
                        temp_label = temp['label']
                        temp_critical = temp['critical']
                        temp_caution = temp['caution']
                        temp_location = temp['location']
                        table_temps.append([temp_status, temp_current, temp_label, temp_critical, temp_caution, temp_location])
                    import tabulate
                    #sorted(table_temps, key=self.getKey)
                    table_temps.sort(key=itemgetter(5))
                    #print tabulate.tabulate(table_temps, ['status', 'currentreading', 'label', 'critical', 'caution', 'location'])
                    
                    fans = chassis['fans']
                    print fans
                       
                    #print chassis['temperature']['05-CPU 4']
                    

                    result = "{0},{1},{2},{3},{4},{5},{6},{7},{8},{9},{10},{11},{12},{13}\n".format(
          #              cvk, IP, product, sn, fwversion, cpuname, cpucount, cpucores, memOK + memErr, memCapacity, mac1, mac2, mac3, mac4)
                        cvk, IP, sn, fwversion, cpuname, cpucount, cpucores, memOK + memErr, memCapacity, mac1, mac2, mac3, mac4)
                    
                    file.write(result)
                    #print result
                
    def getKey(self, item):
        return item[0]
    
    def insert_path(self, path):
        '''Not in use.
        '''
        folder = os.path.abspath(path)
        if folder not in sys.path:
            sys.path.insert(0, folder)
            
    def format_csv(self, csvpath, tablefmt = 'simple'):
        '''format a csv file to a table
        
        csvpath is the input csv file
        tablefmt is the spported table formats, contains "plain","simple","grid",
        "fancy_grid","pipe","orgtbl","rst","mediawiki","html","latex","latex_booktabs"
        
        return formatted string
        '''
        import tabulate
        #header = ''
        table = []
        #pdb.set_trace()
        with open(csvpath, 'r') as file:
            for line in file.readlines():
                #pdb.set_trace()
                tabletmp = line.rstrip('\n').split(',')
                index = 3
                while(index < len(tabletmp)):
                    if tabletmp[index] != 'OK':
                        table.append(tabletmp)
                        break
                    index += 1
                #if not header:
                    #header = line.rstrip('\n').split(',')
                #else:
                #table.append(line.rstrip('\n').split(','))
        print table
        return tabulate.tabulate(table, headers = 'firstrow', tablefmt = tablefmt)
        
    def send_mail(self, to, subject, content, att=None):
        '''send mail
        '''
        import smtplib
        from email.mime.text import MIMEText
        from email.mime.multipart import MIMEMultipart 
        
        msg_body = MIMEText(content,_subtype='html',_charset='gb2312')
        msg = MIMEMultipart()
        msg['Subject'] = subject
        msg['From'] = "PythonChecker<{0}>".format(config.mail_group[config.plat_name]['mail_from'])  
        msg['To'] = ";".join(to)
        msg.attach(msg_body)
        
        if att:
            att1 = MIMEText(open(att, 'rb').read(), 'base64', 'gb2312')
            att1["Content-Type"] = 'application/octet-stream'
            att1["Content-Disposition"] = 'attachment; filename="result-{0}.csv"'.format(datetime.datetime.now().strftime("%Y%m%d%H%M%S"))
            msg.attach(att1)
        
        try:  
            server = smtplib.SMTP()  
            server.connect(config.mail_group[config.plat_name]['mail_host'])
            if config.plat_name in ['hz']:
                server.login(config.mail_group[config.plat_name]['mail_user'], config.mail_group[config.plat_name]['mail_pwd'])  
            server.sendmail(config.mail_group[config.plat_name]['mail_from'], to, msg.as_string())  
            server.close()  
            return True  
        except Exception, e:  
            print str(e)  
            return False
    
    
def main():
    usage = "usage: %prog [options] arg"  
    parser = OptionParser(usage)  
    parser.add_option("-m", "--mode", type="int", 
                      help="mode list:0--chech emebedded health;1--check hw configuration;")  
      
    (options, args) = parser.parse_args()
    
    workdir = os.path.dirname(os.path.abspath(sys.argv[0]))
    os.chdir(workdir)
    
    print options.mode
    #if options.mode == 0:
    #    instance = tool()
    #    instance.check_health('input-{0}.csv'.format(config.plat_name), 'output-health.csv')
    #    print instance.format_csv('output-health.csv')
    #    if instance.send_mail(config.mail_group[config.plat_name]['mailto_list'], config.plat_name + '--Check server embedded health', instance.format_csv('output-health.csv', 'html'), 'output-health.csv'):  
    #        print "The execute result is send to {0}".format(';'.join(config.mail_group[config.plat_name]['mailto_list'])) 
    #    else:  
    #        print "Send mail failed"
    if options.mode == 0:
        instance = tool()
        
        instance.build_checkqueue('input-{0}.csv'.format(config.plat_name))
        
        for i in range(config._thread):
            run = threading.Thread(target=instance.check_healthinqueue, args=(str(i)))
            run.setDaemon(True)
            run.start()
        
        instance.queue.join()
        #pdb.set_trace()
        instance.output_result('output-health.csv', 0)
        
        print instance.format_csv('output-health.csv')
        if instance.send_mail(config.mail_group[config.plat_name]['mailto_list'], config.plat_name + '--Check server embedded health', instance.format_csv('output-health.csv', 'html'), 'output-health.csv'):  
            print "The execute result is send to {0}".format(';'.join(config.mail_group[config.plat_name]['mailto_list'])) 
        else:  
            print "Send mail failed"
        print 'END'
    
        
    elif options.mode == 1:
        instance = tool()
        
        instance.build_checkqueue('input-{0}.csv'.format(config.plat_name))
        
        for i in range(config._thread):
            run = threading.Thread(target=instance.check_confinqueue, args=(str(i)))
            run.setDaemon(True)
            run.start()
        
        instance.queue.join()
        instance.output_result('output-hw.csv', 1)
        print instance.format_csv('output-hw.csv')
        #instance.check_conf('input-{0}.csv'.format(config.plat_name), 'output-hw.csv')
        #if instance.send_mail(config.mail_group[config.plat_name]['mailto_list'], 'Check server hardware configure', instance.format_csv('output-hw.csv', 'html'), 'output-hw.csv'):  
            #print "The execute result is send to {0}".format(';'.join(config.mail_group[config.plat_name]['mailto_list']))
        #else:  
            #print "Send mail failed"
            
    print "END"
    
if __name__ == '__main__':
    '''#pdb.set_trace()
    instance = tool()
    #instance.check_health('input-{0}.csv'.format(config.plat_name), 'output-health.csv')
    print instance.format_csv('output-health.csv')
    #if instance.send_mail(config.mail_group[config.plat_name]['mailto_list'], config.plat_name + '--Check server embedded health', instance.format_csv('output-health.csv', 'html'), 'output-health.csv'):  
    #    print "The execute result is send to {0}".format(';'.join(config.mail_group[config.plat_name]['mailto_list'])) 
    #else:  
    #    print "Send mail failed"
    quit()'''
    main()
    
    
    




