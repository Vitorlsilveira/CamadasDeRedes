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
#ip de origem e resposta como variaveis globais
ipResposta = 0
ipOrig=0

#estabelece conexao com a camada de transporte na porta 6768
print("Aguardando camada de transporte ficar disponivel na porta 6768");
while True:
    try:
        socktransporte = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        socktransporte.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        socktransporte.connect(("localhost", 6768)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue
print("Conectado a camada de transporte");
#separa cada parte do pacote
def separaPacote(pacote):
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

#cria o pacote, anexa o cabeçalho da camada de rede ao segmento recebido
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

#recebe pacote da fisica , encaminha para camada superior ,aguarda resposta e responde a fisica
def recebe_fisica(port):
    #cria socket para que a fisica se conecte a camada de rede
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes

    print("Aguardando conexoes da camada fisica na porta "+str(port))

    #aceita conexao
    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print("Conexão da camada fisica aceita")

    while True:
        #recebe pacote da fisica
        pacote = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(pacote)) > 5:
            print("\nPacote recebido da camada fisica: " + pacote)
            segmento = separaPacote(pacote)
            #envia para a camada de transporte o pacote e recebe a resposta
            resposta = conecta_transporte(segmento)
            pacote = criaPacote(resposta, ipOrig, ipResposta)
            #define o proximo next hop de acordo com a tabela de roteamento
            define_nextHop()
            #envia resposta para a camada fisica pelo socket
            print("\nPacote enviado para a camada fisica: "+ pacote)
            con.send(pacote) # Envia mensagem através do socket.
    con.close()

# envia para a camada de transporte o segmento e recebe resposta do mesmo
def conecta_transporte(segmento):
    while True:
        try:
            print("\nSegmento enviado para a camada de transporte: " + segmento)
            socktransporte.send(segmento) # Envia uma mensagem através do socket.
            resposta = socktransporte.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            if len(str(segmento)) >= 0:
                print("\nSegmento recebido da camada de transporte: " + resposta)
                break
            else:
                print("Nenhum dado recebido do servidor...")
        except socket.error as serr:
            if serr.errno != errno.ECONNREFUSED:
                # Not the error we are looking for, re-raise
                raise serr
    #retorna a resposta recebida
    return resposta

#analisa a tabela de roteamento para definir o next hop no qual a fisica se conectara
def define_nextHop():
    tabela = open("CamadaRede/tabela2", 'r')
    for linha in tabela:
        linha=linha.strip().split(" ")
        ipDeRede=linha[0]
        mascara=linha[1]
        nextHop=linha[2]
        # se o ip de rede calculado bater com o ip de rede da tabela, é pq encontramos o next hop
        if ipDeRede == calculaIPRede(ipResposta,mascara):
            arquivo=open("CamadaRede/nexthop2","w")
            arquivo.write(nextHop)
            arquivo.close
            return
    print "Pacote descartado, arrume a tabela de roteamento da camada de rede"
    return

# a partir do ip e da mascara faz um and bit a bit retornando o ip de rede
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

#retorna o ip da maquina local a partir da interface passada como parametro
def get_myip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        pack('256s', ifname[:15])
    )[20:24])

recebe_fisica(4444)
