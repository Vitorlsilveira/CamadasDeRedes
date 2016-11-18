# -*- coding: utf-8 -*-
import os
import socket
import sys
import errno
from socket import error as socket_error
buffer_size = 1024
def conecta(server,port):
    while True:
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
            sock.connect((server, port)) # Realiza a conexão no host e porta definidos
            print "Mensagem a ser enviada:",
            MSG = raw_input()
            if MSG=="EXIT":
                break
            print("Mensagem enviada >>>"+ MSG)
            sock.send(MSG.encode('utf-8')) # Envia uma mensagem através do socket.
            data = sock.recv(buffer_size) # Recebe mensagem enviada pelo socket.
            if len(str(data)) >= 0:
                print("Mensagem recebida do servidor: "+data.decode('utf-8'))

            else:
                print("Nenhum dado recebido do servidor...")
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                # Not the error we are looking for, re-raise
                raise serr

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

server1 = 'localhost'
port1 = 8004
conecta(server1,port1)
ipRede=calculaIPRede("192.168.10.20","255.255.141.0")
print ipRede
