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
  string bufferRemetente;
  int tamanhoBufferRemetente;
  char bitsControle;
  string retornoControle;
  char[] mensagem;
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
  string mensagemE;

  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino, int MSS){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
    this.MSS=MSS;
    bufferRemetente="";
  }

  void codifica(string controle){
        if(controle=="00000010")
        {
          bitsControle='I';
          return;
        }
        if(controle=="00010010")
        {
          bitsControle='E';
          return;
        }
        if(controle=="00010000")
        {
          bitsControle='A';
          return;
        }
        if(controle=="00010001")
        {
          bitsControle='F';
          return;
        }
        if(controle=="01010000")
        {
          bitsControle='T';
          return;
        }
  }

   void decodifica(char controle){
         if(controle=='I')
         {
           retornoControle="00000010";
           return ;
         }
         if(controle=='E')
         {
           retornoControle="00010010";
           return;
         }
         if(controle=='A')
         {
           retornoControle="00010000";
           return;
         }
         if (controle=='F')
         {
           retornoControle="00010001";
           return;
         }
         if(controle=='T')
         {
           retornoControle="01010000";
           return;
         }
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
    recebeResposta();
    socket.close();
    //encaminha resposta cliente aplicacao
    //cliente.send(dados[0 .. dadoslen]);
    cliente.send(mensagem);
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
    /*Estabelecimento de conexão de 3 vias- handshake*/

    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosR[0..0],0);
    socket.send(segmento);
    numeroSequencia=numeroSequencia+1;
    dadoslenR = socket.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;

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
          janela=janela-1;
          criaSegmento(portaOrigem,portaDestino,99,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosA[aux..fimParcial],MSS);
          socket.send(segmento);
        }
        else{
          janela=janela-1;
          criaSegmento(portaOrigem,portaDestino,99,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosA[aux..restoDivisao],restoDivisao);
          socket.send(segmento);
        }
        aux=0;
        fimParcial=MSS;
        i=0;
    }

    //aguarda resposta
    //dadoslen = socket.receive(dados);

  }

  void recebeResposta(){
    writeln("aceitou");
    int count=0;
    janelaD=1;
    while(janelaD!=100){
      writeln("entrei no loop");
      count++;
      dadoslenR = socket.receive(dadosR);
      writeln("recebeu segmento");
      writeln(dadosR[0..dadoslenR]);
      separaSegmento(cast(char*)dadosR,dadoslenR);
      bufferRemetente=bufferRemetente~mensagemE;
      writeln("buffer do remetente atual:");
      writeln(bufferRemetente);
      portaOrigem=portaDestinoD;
      portaDestino=portaOrigemD;
      numeroSequencia=numeroSequencia+1;
      numeroReconhecimento=numeroSequenciaD+1;
      criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosR[0..0],0);
      socket.send(segmento);
      if(janelaD==100){
        /*começa fechar conexão*/
        mensagem=cast(char[])bufferRemetente;
        criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'F',cast(char*)dadosR[0..0],0);
        socket.send(segmento);
        writeln("mensagem");
        writeln(mensagem);

        break;
      }
    }
    /*Continua fechamento de conexão*/

    dadoslenR = socket.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroSequencia=numeroSequencia+1;
    numeroReconhecimento=numeroSequenciaD+1;
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'N',cast(char*)dadosR[0..0],0);
    socket.send(segmento);
    dadoslenR = socket.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroSequencia=numeroSequencia+1;
    numeroReconhecimento=numeroSequenciaD+1;
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosR[0..0],0);
    socket.send(segmento);


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
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados[0..dadoslen]~"\n\r\n");
    writeln(segmento);
  }

  void separaSegmento(char *dados,long tam){
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
      mensagemD=dados[19..tam-2];
      mensagemE=to!string(mensagemD);
      tamanhoBufferRemetente=tamanhoBufferRemetente+cast(int)tam-20;
      writeln("mensagem: ");
      writeln(mensagemE);
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
/*
T= to mandando ultimo segmento
A= ACK
S= SYN
F= FIN
0T0A00SF
00000010
0001
*/
void main() {
    const port = thisProcessID;
    auto cliente = new ClienteTCP(port, 5555,10);

    cliente.executa();
}
