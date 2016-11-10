import std.socket;
import std.stdio;
import std.random;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.bitmanip;

class ClienteTCP {
  int portaOrigem;
  int portaDestino;
  int MSS;
  int janela;
  int numeroSequencia;
  int numeroReconhecimento;
  int comprimentoCabecalho;
  char[10000] bufferRemetente;
  char bitsControle;
  string mensagem;
  char[10000] dados;
  char[10000] dadosR;
  long dadoslenR;
  long dadoslen;

  int portaOrigemD;
  int portaDestinoD;
  int numeroSequenciaD;
  int numeroReconhecimentoD;
  char bitsControleD;
  int janelaD;
  int comprimentoCabecalhoD;
  ushort checksumD;
  char[] mensagemD;


  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino, int MSS){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
    this.MSS=MSS;
  }

  void recebeAplicacao(){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 3333));
    listener.listen(10);

    cliente = listener.accept();
    dadoslen = cliente.receive(dados);
    writeln("QNT = " ~ to!string(dadoslen));
    writeln(dados[0 .. dadoslen]);
  }

  void conectaFisica() {
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    writeln("Aguardando cliente da camada fisica");
    while(true){
      try {
        socket.connect(new InternetAddress("localhost", 7777));
        writeln("Conectado");
        break;
      } catch( Exception e ){
        continue;
      }
    }
  }

  void executa() {
    conectaFisica();
  //  enviaFisica(cast(char[])"1110111", 7);
    recebeAplicacao();
    enviaFisica(dados, dadoslen);

    //encaminha resposta cliente aplicacao
    cliente.send(dados[0 .. dadoslen]);
    cliente.close();
  }

  void enviaFisica(char[] dadosA, long dadoslenA){
    int numSegmentos=cast(int)(dadoslenA/MSS);
    long restoDivisao= cast(long)(dadoslenA % MSS);
    numeroSequencia=uniform(0,100);
    int fimParcial=MSS;
    int aux=0;
    int i=0;
    janela=numSegmentos;
    writeln(numSegmentos);
    if(numSegmentos>0){
        while(i<numSegmentos-1){
          janela=janela-1;
          criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosA[aux..fimParcial],MSS);
          socket.send(segmento);
          writeln("ENVIOUUUU");
          aux=fimParcial;
          fimParcial=fimParcial+MSS;
          i=i+1;
          dadoslenR=socket.receive(dadosR);
          separaSegmento(cast(char*)dadosR,dadoslenR);
          writeln("Recebi já");
          numeroReconhecimento=numeroSequenciaD+1;
          numeroSequencia=numeroSequencia+1;
        }
        if(restoDivisao==0){
          criaSegmento(portaOrigem,portaDestino,99,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosA[aux..fimParcial],MSS);
          socket.send(segmento);
          dadoslenR=socket.receive(dadosR);
          separaSegmento(cast(char*)dadosR,dadoslenR);
          numeroReconhecimento=numeroSequenciaD+1;
          numeroSequencia=numeroSequencia+1;
        }
        else{
          janela=janela-1;
          criaSegmento(portaOrigem,portaDestino,99,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosA[aux..restoDivisao],restoDivisao);
          socket.send(segmento);
          dadoslenR=socket.receive(dadosR);
          separaSegmento(cast(char*)dadosR,dadoslenR);
          numeroReconhecimento=numeroSequenciaD+1;
          numeroSequencia=numeroSequencia+1;
        }
        aux=0;
        fimParcial=MSS;
        i=0;
    }

    //aguarda resposta
    dadoslen = socket.receive(dados);
  }

  void criaSegmento(int portaOrigem,int portaDestino,int janela,int comprimentoCabecalho,int numeroSequencia,int numeroReconhecimento,char bitsControle,char *dados,long dadoslen){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pJanela = cast(char[2])nativeToLittleEndian(cast(ushort)janela);
    char[4] pNumeroSequencia = cast(char[4])nativeToLittleEndian(cast(uint)numeroSequencia);
    char[4] pNumeroReconhecimento = cast(char[4])nativeToLittleEndian(cast(uint)(numeroReconhecimento));
    char[2] pComprimentoCabecalho = cast(char[2])nativeToLittleEndian(cast(ushort)(comprimentoCabecalho));
    ushort check = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);
    char[2] checksum = cast(char[2])nativeToLittleEndian(check);
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados[0..dadoslen]~"\n\n");
    writeln(segmento);
  }

  void separaSegmento(char *dados,long tam){
    portaOrigemD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    writeln("Porta origem:"~to!string(portaOrigemD));
    portaDestinoD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta destino:"~to!string(portaDestinoD));
    numeroSequenciaD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    writeln("sequencia:"~to!string(numeroSequenciaD));
    numeroReconhecimentoD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    writeln("reconhecimento:"~to!string(numeroReconhecimentoD));
    bitsControleD=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    writeln("bits controle:"~to!string(bitsControleD));
    janelaD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    writeln("janela:"~to!string(janelaD));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    writeln("comprimento cabecalho:"~to!string(comprimentoCabecalhoD));
    checksumD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    if(tam>=19){
      mensagemD=dados[19..tam];
    }

  }

  ushort checksum16(char* addr, int count){
         /* Compute Internet Checksum for "count" bytes
          *         beginning at location "addr".
          */
    ushort sum = 0;
    while( count > 1 )  {
       /*  This is the inner loop */
           sum += * cast(ushort *) addr++;
           count -= 2;
     }
         /*  Add left-over byte, if any */
     if( count > 0 )
             sum += * cast(wchar *) addr;
        /*  Fold 32-bit sum to 16 bits */
     while (sum>>16)
         sum = (sum & 0xffff) + (sum >> 16);
     ushort checksum = ~sum;
     return checksum;
 }
}

void main() {
    const port = thisProcessID;

    auto cliente = new ClienteTCP(port, 5555,10);

    cliente.executa();
}
