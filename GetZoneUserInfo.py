# -*- coding: utf-8 -*-

import  xdrlib ,sys
import xlrd
#import pymssql
import pypyodbc
import os, shutil

#reload(sys)
#sys.setdefaultencoding('utf-8')

class readExcel:
    def __init__(self,file):
        self.file=file
        
    def open_excel(self):
        try:
            data = xlrd.open_workbook(self.file)
            return data
        except Exception,e:
            print str(e)
            raise(open_excelError,e)           
    
    #......Excel......   ..:file.Excel....     colnameindex...........  .by_name.Sheet1..
    def excel_table_byname(self,colnameindex=0,by_sheetName=u'Sheet1'):
        data = self.open_excel()
        table = data.sheet_by_name(by_sheetName)
        nrows = table.nrows #.. 
        colnames =  table.row_values(colnameindex) #..... 
        colIndexs=[]
        for i in range(len(colnames)):
            title = colnames[i].encode('gb18030','ignore')
            print title
            #.............Excel.........sql........
            if unicode(colnames[i])==u'....':
                colIndexs.append(i)
            elif unicode(colnames[i])==u'..':
                colIndexs.append(i)
            elif unicode(colnames[i])==u'......G.':
                colIndexs.append(i)
            elif unicode(colnames[i])==u'...IP..':
                colIndexs.append(i) 
        print colIndexs
        collist=[]
        for rownum in range(1,nrows):
            row=table.row_values(rownum)
            cols=[]
            cols.append(row[colIndexs[0]])
            cols.append(row[colIndexs[1]])
            val = row[colIndexs[2]] or '0'
            cols.append(val)
            cols.append(row[colIndexs[3]])                
            print cols
            if row[colIndexs[3]] and cols[3]:
                collist.append(cols)
        return collist

class Import2DB:
    def __init__(self,host,user,pwd,db):
        self.host = host
        self.user = user
        self.pwd = pwd
        self.db = db
        driver= '{SQL Server}'
        self.conn = pypyodbc.connect('DRIVER='+driver+';PORT=1433;SERVER='+self.host+';DATABASE='+self.db+';UID='+self.user+';PWD='+ self.pwd)

    def __GetConnect(self):
        if not self.db:
            raise(NameError,".........")
        #self.conn = pymssql.connect(host=self.host,user=self.user,password=self.pwd,database=self.db,charset="utf8")
        cur = self.conn.cursor()
        if not cur:
            raise(NameError,".......")
        else:
            return cur

    def ExecQuery(self,sql):
        try:
            cur = self.__GetConnect()
            cur.execute(sql)
            resList = cur.fetchall()
            #...........
            #self.conn.close()
            return resList
        except Exception as ex:
            self.conn.close()
            raise(ExecQueryError,ex)

    def ExecNonQuery(self,sql):
        try:
            cur = self.__GetConnect()
            cur.execute(sql)
            self.conn.commit()            
        except Exception as ex:
            self.conn.close()
            raise(ex)
        
    def Close(self):
        self.conn.close()
        

class mainUtils:
    def __init__(self,xlsFile,dbHost,dbUser,dbPwd,dbDb,sheetName=u'Sheet1'):
        self.xlsFile=xlsFile
        self.dbHost = dbHost
        self.dbUser=dbUser
        self.dbPwd=dbPwd
        self.dbDb=dbDb
        self.sheetName=sheetName
        
    def readXls(self):
        xlsObj = readExcel(self.xlsFile)
        dataDic = xlsObj.excel_table_byname(by_sheetName=self.sheetName)
        return dataDic
    
    def execQuery(self,sqlStr):
        try:
            i2dbObj = Import2DB(self.dbHost,self.dbUser,self.dbPwd,self.dbDb)
            result = i2dbObj.ExecQuery(sqlStr)
            return result
        except Exception as ex:
            pass
        
    def execNonQuery(self,sqlStr):
        try:
            i2dbObj = Import2DB(self.dbHost,self.dbUser,self.dbPwd,self.dbDb)
            i2dbObj.ExecNonQuery(sqlStr)
        except Exception as ex:
            pass
        
    def generateSqlStr(self):
        dataDic = self.readXls()
        try:
            i2dbObj = Import2DB(self.dbHost,self.dbUser,self.dbPwd,self.dbDb)
            for value in dataDic:
                if value and value[3]: #internalIP ......
                    #.............Excel.......sql........
                    selectStr = 'select usedFor,userDept from UserInfoInGovCloud where internalIP = \'%s\'' % unicode(value[3])
                    print selectStr
                    existlist = self.execQuery(selectStr)            
                    sqlStr=''
                    if existlist:
                        sqlStr='update UserInfoInGovCloud set userDept = \'%s\', usedFor =\'%s\',dataVol_G=%s,updateTime=getdate() where internalIP = \'%s\'' % (unicode(value[0]),unicode(value[1]),unicode(value[2]),unicode(value[3]))
                    else:
                        sqlStr='insert into UserInfoInGovCloud(userDept,usedFor,dataVol_G,internalIP) values(\'%s\',\'%s\',%s,\'%s\')'%(unicode(value[0]),unicode(value[1]),unicode(value[2]),unicode(value[3]))
                    print sqlStr
                    #self.execNonQuery(sqlStr)
                    i2dbObj.ExecNonQuery(sqlStr)
            i2dbObj.Close()
        except Exception as ex:
            raise(ex)

if __name__=='__main__':
    #qzsource = u'\\\h3cso01-nt\pub\.....\..-03-..............b.xls'
    #print qzsource
    if os.path.isfile(r'quzhouZoneUserInfo.xlsx'): #and False
       # print 'copy'
        #shutil.copy(qzsource,'quzhouZoneUserInfo.xls')
        m = mainUtils(u'quzhouZoneUserInfo.xlsx',"10.19.0.72","restapi","rest@api123","MoniterRestAPI_QuZhou",u'.....02')   
        m.generateSqlStr()
    #sxsource = u'\\\h3cso01-nt\pub\.....\..\\3.....\.....-.......1.xls'
    #print sxsource
    #if os.path.isfile(r'shaoxingZoneUserInfo.xlsx'):
        #print sxsource
        #shutil.copy(sxsource,'shaoxingZoneUserInfo.xls')
        #m = mainUtils(u'shaoxingZoneUserInfo.xlsx',"10.19.0.72","restapi","rest@api123","MoniterRestAPI_ShaoXing",u'...')   
        #m.generateSqlStr()    

