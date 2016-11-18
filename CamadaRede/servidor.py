# -*- coding: utf-8 -*-
import socket
import sys
import os

BUFFER_SIZE = 1024


def create_server(host,port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.bind((host, port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    MSG_DO_SERVIDOR = "servidor manelzinho"
    print("Aguardando conexoes na porta:"+str(port)+"\n")

    while True:
        try:
            (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
            print(address[0]+" Conectado...")
            data = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
            if len(str(data)) >= 0:
                print(address[0]+" diz: " + data.decode('UTF-8'))
                print("Resposta do servidor: " + MSG_DO_SERVIDOR)
                con.send(MSG_DO_SERVIDOR.encode('utf-8')) # Envia mensagem através do socket.
            else:
                print("Sem dados recebidos de: "+address[0])
        except ValueError:
            print("Erro")

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

create_server("localhost",8004)
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
