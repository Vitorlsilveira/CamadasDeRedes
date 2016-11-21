# -*- coding: utf-8 -*-
import fcntl
from struct import *
import os
import socket
import sys
import errno
from socket import error as socket_error
import crc16
BUFFER_SIZE = 65535

#pip install crc16

while True:
    try:
        sockfisico = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        sockfisico.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sockfisico.connect(("localhost", 9999)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue

def separaPacote(pacote):
    print "pacote"
    print pacote
    print "teste"
    print len(pacote)
    versionIHL = unpack("B", pacote[0:1])[0]
    typeService = unpack("B", pacote[1:2])[0]
    totalLength = unpack("H", pacote[2:4])[0]
    identification = unpack("H", pacote[4:6])[0]
    flagsFragOffset = unpack("H", pacote[6:8])[0]
    ttl = unpack("B", pacote[8:9])[0]
    protocol = unpack("B", pacote[9:10])[0]
    headerChecksum = unpack("H", pacote[10:12])[0]
    sourceAdd = str(unpack("B", pacote[12:13])[0])+"."+str(unpack("B", pacote[13:14])[0])+"."+str(unpack("B", pacote[14:15])[0])+"."+str(unpack("B", pacote[15:16])[0])
    destAdd = str(unpack("B", pacote[16:17])[0])+"."+str(unpack("B", pacote[17:18])[0])+"."+str(unpack("B", pacote[18:19])[0])+"."+str(unpack("B", pacote[19:20])[0])
    segmento = pacote[20:len(pacote)]
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
    return pacote

def recebe_transporte(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    print("Aguardando conexoes da camada de transporte: "+str(port)+"\n")

    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print(address[0]+" Conectado...")

    while True:
        fo = open("config")
        ipDestino = fo.readline().splitlines()[0]
        fo.close()
        segmento = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(segmento)) >= 0:
            print(address[0]+" diz: " + segmento)
            ipOrigem = get_myip_address("wlan0")
            pacote = criaPacote(segmento, ipOrigem, ipDestino)

            resposta = conecta_fisica(pacote)
            print("Resposta do servidor: " + resposta)
            con.send(resposta) # Envia mensagem através do socket.
        else:
            print("Sem dados recebidos de camada de transporte: "+address[0])
    con.close()

def conecta_fisica(pacote):
    while True:
        try:
            print("Mensagem enviada para fisica >>> "+ pacote)
            sockfisico.send(pacote) # Envia uma mensagem através do socket.
            resposta = sockfisico.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            segmento = separaPacote(resposta)
            print("SEGMENTO = " + segmento)
            if len(str(pacote)) >= 0:
                print("Mensagem recebida do servidor fisico: " + resposta)
                break
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                raise serr
    return segmento

def calculaIPRede(ip,mask):
    if ip == "localhost":
        ip = "127.0.0.1"
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


server1 = 'localhost'
recebe_transporte(7777)
ipRede=calculaIPRede("192.168.10.20","255.255.141.0")
print ipRede
