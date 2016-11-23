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
ipOrigem = 0

#Conectando com o servidor fisico do roteador para transmitir para o next hop
while True:
    try:
        sockfisico = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        sockfisico.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sockfisico.connect(("localhost", 2222)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue

def recebe_fisica(port):
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    print("Aguardando conexoes da camada fisica do roteador: "+str(port)+"\n")

    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print(address[0]+" Conectado...")

    while True:
        pacote = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(pacote)) > 5:
            print(address[0]+" diz: " + pacote)
            segmento = separaPacote(pacote)
            print "\tPACOTE"
            print pacote
        #    print "\n\n"
            resposta = recebe_cliente_fisico(pacote)
            con.send(resposta) # Envia mensagem através do socket.
            print "Teste"
    con.close()



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
    global ipOrigem
    ipOrigem=sourceAdd
    global ipResposta
    ipResposta=destAdd
    segmento = pacote[20:len(pacote)-1]
    return segmento



def recebe_cliente_fisico(pacote):
    while True:
        try:
            define_nextHop()
            print("Mensagem enviada para fisica >>> "+ pacote)
            sockfisico.send(pacote) # Envia uma mensagem através do socket.
            resposta = sockfisico.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            if len(str(pacote)) >= 0:
                print("Mensagem recebida do servidor fisico: " + resposta)
                break
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                raise serr
    return resposta

def define_nextHop():
    tabela = open("Roteador/tabela", 'r')
    for linha in tabela:
        linha=linha.strip().split(" ")
        ipDeRede=linha[0]
        mascara=linha[1]
        nextHop=linha[2]

        if ipDeRede == calculaIPRede(ipResposta,mascara):
            print("ip de rede:"+ipDeRede)
            print ("calculo do ip de rede: "+calculaIPRede(ipResposta,mascara))
            print("next Hop:"+nextHop)
            arquivo=open("Roteador/nexthop","w")
            arquivo.write(nextHop)
            arquivo.close
            return
    print "Pacote descartado, arrume a tabela de roteamento"
    return

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


recebe_fisica(1111)
