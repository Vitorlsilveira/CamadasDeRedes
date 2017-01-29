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

#Conectando com o servidor fisico do roteador que irá transmitir para o next hop
print("Aguardando servidor da camada fisica ficar disponivel na porta 2222");
while True:
    try:
        sockfisico = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        sockfisico.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sockfisico.connect(("localhost", 2222)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue
print("Conectado ao servidor da camada fisica do roteador");
def recebe_fisica(port):
    # Cria o descritor do socket
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    # Associa o endereço e porta ao descritor do socket.
    sock.bind(("localhost", port))
    # Tamanho maximo da fila de conexões pendentes
    sock.listen(10)

    print("Aguardando conexoes da camada fisica do roteador: "+str(port))

    # aceita conexoes e recupera o endereco do cliente.
    (con, address) = sock.accept()
    print("Conexão da camada fisica aceita")

    while True:
        # Recebe uma mensagem do tamanho BUFFER_SIZE
        pacote = con.recv(BUFFER_SIZE)
        if len(str(pacote)) > 5:
            print(address[0]+" diz: " + pacote)
            separaPacote(pacote)
            #envia dados para a fisica e recebe resposta
            resposta = conectaFisica(pacote)
            # Envia resposta através do socket.
            con.send(resposta)
    con.close()

#separa pacote recebido, para extrair informações sobre o ip de destino e o ip de origem
def separaPacote(pacote):
    sourceAdd = str(unpack("B", pacote[12:13])[0])+"."+str(unpack("B", pacote[13:14])[0])+"."+str(unpack("B", pacote[14:15])[0])+"."+str(unpack("B", pacote[15:16])[0])
    destAdd = str(unpack("B", pacote[16:17])[0])+"."+str(unpack("B", pacote[17:18])[0])+"."+str(unpack("B", pacote[18:19])[0])+"."+str(unpack("B", pacote[19:20])[0])
    global ipOrigem
    ipOrigem=sourceAdd
    global ipResposta
    ipResposta=destAdd

#envia para servidor da camada fisica do roteador e recebe resposta da mesma
def conectaFisica(pacote):
    while True:
        try:
            define_nextHop()
            print("Mensagem enviada para fisica: "+ pacote)
            sockfisico.send(pacote) # Envia uma mensagem através do socket.
            resposta = sockfisico.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            if len(str(pacote)) >= 0:
                print("Mensagem recebida da camada fisica: " + resposta)
                break
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                raise serr
    return resposta

#funcao que define o next hop
def define_nextHop():
    #le a tabela de roteamento do arquivo tabela
    tabela = open("CamadaRede/tabela", 'r')
    #percorre todas as linhas da tabela, separando ip de rede, mascara e next hop
    for linha in tabela:
        linha=linha.strip().split(" ")
        ipDeRede=linha[0]
        mascara=linha[1]
        nextHop=linha[2]

        #verifica se o ip de rede da tabela bate o ip de rede do destino dada uma mascara, se isso acontecer, encontramos o next hop
        if ipDeRede == calculaIPRede(ipResposta,mascara):
            print "Encontramos a linha correspondente: "
            print("Ip de rede:"+ipDeRede)
            print("Next hop:"+nextHop)
            #escreve nextHop num arquivo para ser lido pela camada fisica
            arquivo=open("CamadaRede/nexthop","w")
            arquivo.write(nextHop)
            arquivo.close
            return
    print "Pacote descartado, arrume a tabela de roteamento"
    return

#funcao que calcula o ip de rede dado um ip e uma mascara
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
