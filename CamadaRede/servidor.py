# -*- coding: utf-8 -*-
import fcntl
from struct import *
import os
import socket
import sys
import errno
from socket import error as socket_error
import crc16

BUFFER_SIZE = 65536
ipResposta = 0
ipOrig=0
while True:
    try:
        socktransporte = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        socktransporte.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        socktransporte.connect(("localhost", 6768)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue

def separaPacote(pacote):
    print "pacote len = " + str(len(pacote))
    versionIHL = unpack("B", pacote[0:1])[0]
    typeService = unpack("B", pacote[1:2])[0]
    totalLength = unpack("H", pacote[2:4])[0]
    identification = unpack("H", pacote[4:6])[0]
    flagsFragOffset = unpack("H", pacote[6:8])[0]
    ttl = unpack("B", pacote[8:9])[0]
    protocol = unpack("B", pacote[9:10])[0]
    headerChecksum = unpack("H", pacote[10:12])[0]
    sourceAdd = str(unpack("B", pacote[12:13])[0])+"."+str(unpack("B", pacote[13:14])[0])+"."+str(unpack("B", pacote[14:15])[0])+"."+str(unpack("B", pacote[15:16])[0])
    global ipResposta
    ipResposta=sourceAdd
    destAdd = str(unpack("B", pacote[16:17])[0])+"."+str(unpack("B", pacote[17:18])[0])+"."+str(unpack("B", pacote[18:19])[0])+"."+str(unpack("B", pacote[19:20])[0])
    global ipOrig
    ipOrig=destAdd
    segmento = pacote[20:len(pacote)-2]
    return segmento

def criaPacote(segmento, sourceIP, destIP):
    versionIHL = pack("B", 45)
    typeService = pack("B", 0)
    totalLength = pack("H", len(segmento)+20)
    identification = pack("H", 0)
    flagsFragOffset = pack("H", int('0100000000000000',2))
    ttl = pack("B", 10)
    protocol = pack("B", 6)
    headerChecksum = pack("H", 0)
    if destIP == "localhost":
        destIP = "127.0.0.1"
    sourceAdd = pack("B", int(sourceIP.split(".")[0])) + pack("B", int(sourceIP.split(".")[1])) + pack("B", int(sourceIP.split(".")[2])) + pack("B", int(sourceIP.split(".")[3]))
    destAdd = pack("B", int(destIP.split(".")[0])) + pack("B", int(destIP.split(".")[1])) + pack("B", int(destIP.split(".")[2])) + pack("B", int(destIP.split(".")[3]))
    header = versionIHL+typeService+totalLength+identification+flagsFragOffset+ttl+protocol+headerChecksum+sourceAdd+destAdd
    headerChecksum = pack("H", crc16.crc16xmodem(header))
    header = versionIHL+typeService+totalLength+identification+flagsFragOffset+ttl+protocol+headerChecksum+sourceAdd+destAdd
    pacote = header+segmento
    print "cria Pacote"
    print pacote
    return pacote

def recebe_fisica(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    print("Aguardando conexoes da camada fisica: "+str(port)+"\n")

    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print(address[0]+" Conectado...")

    while True:
        pacote = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(pacote)) > 5:
            print(address[0]+" diz: " + pacote)
            segmento = separaPacote(pacote)
            print "Teste1"
            print("SEGMENTO = " + segmento)
            print "teste2"
            resposta = conecta_transporte(segmento)
            print("Resposta da transporte: " + resposta)
            print("RESPOSTA LEN " + str(len(resposta)))
            pacote = criaPacote(resposta, ipOrig, ipResposta)
            print "\tPACOTE"
            print pacote
        #    print "\n\n"
            con.send(pacote) # Envia mensagem através do socket.
            print "Teste"
    con.close()


def conecta_transporte(segmento):
    while True:
        try:
            print("Mensagem enviada para transporte >>> "+ segmento)
            socktransporte.send(segmento) # Envia uma mensagem através do socket.
            resposta = socktransporte.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            if len(str(segmento)) >= 0:
                print("Mensagem recebida do servidor transporte: " + resposta)
                break
            else:
                print("Nenhum dado recebido do servidor...")
        except socket.error as serr:
            if serr.errno != errno.ECONNREFUSED:
                # Not the error we are looking for, re-raise
                raise serr
    return resposta



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

def get_myip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        pack('256s', ifname[:15])
    )[20:24])

recebe_fisica(4444)
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
