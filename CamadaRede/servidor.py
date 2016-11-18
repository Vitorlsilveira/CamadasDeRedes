import os

def calculaIPRede(ip,mask):
    ipRede=""
    numIP=""
    numMask=""
    aux=0
    ultimoPontoIp=-1
    ultimoPontoMask=-1
    for i in range(0,4):
        numIP=""
        numMask=""
        count=0
        for d in ip:
            if count>ultimoPontoIp:
                if d ==".":
                    ultimoPontoIp=count
                    break
                numIP=numIP+d
            count=count+1
        count=0
        for m in mask:
            if count>ultimoPontoMask:
                if m ==".":
                    ultimoPontoMask=count
                    break
                numMask=numMask+m
            count=count+1
        if i!=3:
            ipRede=ipRede+str(int(numIP)&int(numMask))+"."
        else:
            ipRede=ipRede+str(int(numIP)&int(numMask))
    return ipRede


ipRede=calculaIPRede("192.168.10.20","255.255.141.0")
print ipRede
    #    192.168.10.20
    #    AND BIT A BIT
    #    255.255.255.128

    #        11000000.10101000.00001010.00010100
    #AND
    #        11111111.11111111.10001101.10000000
    #        ============================
    #IPRede  11000000.10101000.00001010.00000000
    #Assim, o ip da rede e 192.168.10.0
