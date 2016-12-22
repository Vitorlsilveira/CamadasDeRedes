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
#variavel global ip de destino
ipDestino=0

#estabelece conexao com a camada fisica na porta 9999
print("Aguardando camada fisica ficar disponivel na porta 9999");
while True:
    try:
        sockfisico = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
        sockfisico.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        sockfisico.connect(("localhost", 9999)) # Realiza a conexão no host e porta definidos
        break
    except:
        continue
print("Conectado a camada fisica");
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
    destAdd = str(unpack("B", pacote[16:17])[0])+"."+str(unpack("B", pacote[17:18])[0])+"."+str(unpack("B", pacote[18:19])[0])+"."+str(unpack("B", pacote[19:20])[0])
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

#recebe da camada de cima o segmento e envia para fisica ,aguardando resposta para encaminhar a resposta a de transporte
def recebe_transporte(port):
    #abre socket para que a camada de transporte se conecte a de rede na porta : port
    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM) # Cria o descritor do socket
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("localhost", port)) # Associa o endereço e porta ao descritor do socket.
    sock.listen(10) # Tamanho maximo da fila de conexões pendentes
    print("Aguardando conexões da camada de transporte na porta "+str(port))
    (con, address) = sock.accept() # aceita conexoes e recupera o endereco do cliente.
    print("Conexão da camada de transporte aceita")

    while True:
        # recebe segmento da camada de transporte
        segmento = con.recv(BUFFER_SIZE) # Recebe uma mensagem do tamanho BUFFER_SIZE
        if len(str(segmento)) >= 0:
            print("Segmento recebido da camada de transporte: " + segmento)
            #carrega o arquivo de configuração para pegar o ip de destino e a interface
            fil = open("config")
            fo = fil.readlines()
            #att a variavel global ip de destino
            global ipDestino
            ipDestino = fo[0].splitlines()[0]
            interface = fo[1].splitlines()[0]
            fil.close()
            #obtem o ip de origem
            ipOrigem = get_myip_address(interface)
            #cria pacote
            pacote = criaPacote(segmento, ipOrigem, ipDestino)
            #envia para a fisica o pacote e aguarda a resposta
            resposta = conecta_fisica(pacote)
            print("Segmento enviado para a camada de transporte: " + resposta)
            #envia resposta da fisica para a camada de transporte
            con.send(resposta) # Envia mensagem através do socket.
        else:
            print("Sem dados recebidos de camada de transporte: "+address[0])
    con.close()

def conecta_fisica(pacote):
    while True:
        try:
            #checa o proximo next hop
            define_nextHop()
            #envia pacote para a fisica
            print("Pacote enviado para a camada fisica: "+ pacote)
            sockfisico.send(pacote) # Envia uma mensagem através do socket.
            #recebe resposta da camada fisica
            resposta = sockfisico.recv(BUFFER_SIZE) # Recebe mensagem enviada pelo socket.
            #separa o pacote para obter o segmento
            segmento = separaPacote(resposta)
            if len(str(pacote)) >= 0:
                print("Pacote recebido da camada fisica: " + resposta)
                break
        except socket_error as serr:
            if serr.errno != errno.ECONNREFUSED:
                raise serr
    #retorna o segmento para que seja enviado para a camada de transporte a resposta
    return segmento

#le a tabela de roteamento
def define_nextHop():
    tabela = open("CamadaRede/tabela1", 'r')
    for linha in tabela:
        linha=linha.strip().split(" ")
        ipDeRede=linha[0]
        mascara=linha[1]
        nextHop=linha[2]
        # se o ip de rede calculado bater com o ip de rede da tabela, é pq encontramos o next hop
        if ipDeRede == calculaIPRede(ipDestino,mascara):
            arquivo=open("CamadaRede/nexthop1","w")
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


server1 = 'localhost'
recebe_transporte(7777)
