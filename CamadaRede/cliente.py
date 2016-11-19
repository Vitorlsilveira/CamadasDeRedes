# -*- coding: utf-8 -*-
import fcntl
import struct
import os
import socket
import sys
import errno
from socket import error as socket_error
BUFFER_SIZE = 10000

while True:
    try:
        sockfisico = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        sockfisico.connect(("localhost", 9999)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue


def recebe_transporte(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    print("Aguardando conexoes da camada de transporte: "+str(port)+"\n")

    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print(address[0]+" Conectado...")

    while True:
        #try:
        segmento = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(segmento)) >= 0:
            print(address[0]+" diz: " + segmento)

            pacote = get_myip_address() + segmento
            
            resposta = conecta_fisica(segmento)
            print("Resposta do servidor: " + resposta)
            con.send(resposta) # Envia mensagem através do socket.
        else:
            print("Sem dados recebidos de camada de transporte: "+address[0])
        #except ValueError:
        #    print("Erro")

def conecta_fisica(segmento):
    while True:
        try:
            print("Mensagem enviada para fisica >>> "+ segmento)
            sockfisico.send(segmento) # Envia uma mensagem através do socket.
            resposta = sockfisico.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            if len(str(segmento)) >= 0:
                print("Mensagem recebida do servidor fisico: " + resposta)
                break
            else:
                print("Nenhum dado recebido do servidor...")
        except socket_error as serr:
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
        struct.pack('256s', ifname[:15])
    )[20:24])


server1 = 'localhost'
recebe_transporte(7777)
ipRede=calculaIPRede("192.168.10.20","255.255.141.0")
print ipRede
