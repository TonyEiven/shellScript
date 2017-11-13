#!/usr/bin/env python

# -*- coding: utf-8 -*-
from scapy.all import srp,Ether,ARP,conf
import sys,os
ipscan="10.166.6.0/24"
try:
        ans,unans = srp(Ether(dst="FF:FF:FF:FF:FF:FF")/ARP(pdst=ipscan),timeout=2,verbose=False)
except Exception,e:
        print str(e)
else:
        for snd,rcv in ans:
                list_mac = rcv.sprintf("%Ether.src% - %ARP.psrc%")
                print list_mac
print "This script could be used to scan survival host in lan zone"
