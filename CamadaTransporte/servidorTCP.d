import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.string;
import std.random;
import std.bitmanip;


class ServidorTCP {
  int portaOrigem, portaOrigemR;
  int portaDestino, portaDestinoR;
  int MSS;
  int janela, janelaR;
  int numeroSequencia, numeroSequenciaR;
  int numeroReconhecimento, numeroReconhecimentoR;
  int comprimentoCabecalho;
  string bufferDestinatario,bufferDestinatarioR;
  char bitsControle;
  string retornoControle;
  long dadoslen;
  long dadoslenR;
  ushort checksum;
  string segmento;
  char[10000] dados;
  char[10000] dadosA;
  char[10000] dadosR;
  char[] mensagem;
  char[] vetorControle;
  int portaOrigemD,portaOrigemDR;
  int portaDestinoD,portaDestinoDR;
  int numeroSequenciaD, numeroSequenciaDR;
  int numeroReconhecimentoD,numeroReconhecimentoDR;
  char bitsControleD,bitsControleDR;
  int janelaD,janelaDR;
  int tamanhoBufferDestinatario=0;
  int tamanhoBufferDestinatarioR=0;
  int comprimentoCabecalhoD,comprimentoCabecalhoDR;
  ushort checksumD,checksumDR;
  char[] mensagemD,mensagemDR;
  string mensagemE,mensagemER;
  bool conectado = false;
  Socket listener, servidor, socket;

  this(int MSS){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
    bufferDestinatario="";
    this.MSS=MSS;
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
    writeln("Segmento: ");
    writeln(segmento);
    writeln("Porta origem:"~to!string(portaOrigem));
    writeln("Porta destino:"~to!string(portaDestino));
    writeln("sequencia:"~to!string(numeroSequencia));
    writeln("reconhecimento:"~to!string(numeroReconhecimento));
    writeln("bits controle:"~to!string(bitsControle));
    writeln("janela:"~to!string(janela));
    writeln("comprimento cabecalho:"~to!string(comprimentoCabecalho));
    writeln("checksum:"~to!string(checksum));
    writeln("dados:"~to!string(dados[0..dadoslen]));
  }

  void separaSegmento(char *dados,long tam){
    portaOrigemD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
//  writeln("Porta origem:"~to!string(portaOrigemD));
    portaDestinoD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
  //  writeln("Porta destino:"~to!string(portaDestinoD));
    numeroSequenciaD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    //writeln("sequencia:"~to!string(numeroSequenciaD));
    numeroReconhecimentoD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    //writeln("reconhecimento:"~to!string(numeroReconhecimentoD));
    bitsControleD=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    decodifica(bitsControleD);
    vetorControle=cast(char[])retornoControle;
    //writeln("flag de ultimo segmento:");
    //writeln(vetorControle[1]);
    //writeln("bits controle:"~retornoControle);
    janelaD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    //writeln("janela:"~to!string(janelaD));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    //writeln("comprimento cabecalho:"~to!string(comprimentoCabecalhoD));
    checksumD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    if(tam>=19){
      mensagemD=dados[19..tam-1];
      mensagemE=to!string(mensagemD);
      tamanhoBufferDestinatario=tamanhoBufferDestinatario+cast(int)tam-20;
      //writeln("mensagem: ");
      //writeln(mensagemE);
    }
  }

  void separaSegmento2(char *dados,long tam){
    portaOrigemDR = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    //writeln("Porta origem:"~to!string(portaOrigemD));
    portaDestinoDR = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    //writeln("Porta destino:"~to!string(portaDestinoD));
    numeroSequenciaDR=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    //writeln("sequencia:"~to!string(numeroSequenciaD));
    numeroReconhecimentoDR=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    //writeln("reconhecimento:"~to!string(numeroReconhecimentoD));
    bitsControleDR=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    decodifica(bitsControleDR);
    vetorControle=cast(char[])retornoControle;
    //writeln("flag de ultimo segmento:");
    //writeln(vetorControle[1]);
    //writeln("bits controle:"~to!string(bitsControleD));
    janelaDR=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    //writeln("janela:"~to!string(janelaD));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    //writeln("comprimento cabecalho:"~to!string(comprimentoCabecalhoD));
    checksumDR=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    if(tam>=19){
      mensagemDR=dados[19..tam-1];
      mensagemER=to!string(mensagemD);
      tamanhoBufferDestinatarioR=tamanhoBufferDestinatarioR+cast(int)tam-20;
      //writeln("mensagem: ");
      //writeln(mensagemER);
    }
  }

  void recebeFisica(){
    writeln("Esperando conexao com camada fisica");
    if(!conectado){
      servidor = listener.accept();
      conectado = true;
    }
    int count=0;
    janelaD=1;
    numeroSequencia=uniform(0,100);

    /*Estabelecimento de conexão de 3 vias - handshake*/
    dadoslenR = servidor.receive(dadosR);
    writeln("Estabelecimento de conexao (Handshake)");
    separaSegmento(cast(char*)dadosR,dadoslenR);
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010010");
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
//    numeroSequencia=numeroSequencia+1;
    servidor.send(segmento);
    while(1){
      count++;
      dadoslenR = servidor.receive(dadosR);
      writeln(dadosR[0..dadoslenR]);
      separaSegmento(cast(char*)dadosR,dadoslenR);
      writeln("Recebi segmento: " ~ to!string(numeroSequenciaD));
      bufferDestinatario = bufferDestinatario ~ mensagemE;
      portaOrigem=portaDestinoD;
      portaDestino=portaOrigemD;
      janela=janelaD;
      numeroSequencia=numeroSequencia+1;
      numeroReconhecimento=numeroSequenciaD+MSS;
      if(vetorControle[1]=='0'){
        codifica("00010000");
        writeln("Enviei confirmacao: " ~ to!string(numeroReconhecimentoD));
        criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
        servidor.send(segmento);
        continue;
      }
      else{
        break;
      }
    }
    mensagem=cast(char[])bufferDestinatario;
    writeln("Buffer destinatario final: ");
    writeln(mensagem);

    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    while(true){
      try {
        socket.connect(new InternetAddress("localhost", cast(ushort)portaDestinoD));
        break;
      } catch( Exception e ){
        continue;
      }
    }
    writeln("\nEnviando para Aplicacao \n" ~ mensagem);
    // Envia a requisicao pra aplicacao
    socket.send(mensagem);
    //recebe resposta
    dadoslen = socket.receive(dados);
    socket.close();
    writeln("\nDados recebidos da aplicacao: ");
    writeln(dados[0..dadoslen]);
    //encaminha resposta pra fisica
    long dadoslenA=dadoslen;
    dadosA=dados;
    int numSegmentos=cast(int)(dadoslenA/MSS);
    long restoDivisao= cast(long)(dadoslenA % MSS);
    numeroSequenciaR=numeroSequencia;
    numeroReconhecimentoR=numeroReconhecimento;
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    int fimParcial=MSS;
    int aux=0;
    int i=0;
    janelaR=numSegmentos;
    writeln(numSegmentos);
    if(numSegmentos>0){
        while(i<numSegmentos){
          codifica("00010000");
          writeln("Enviei segmento: " ~ to!string(numeroSequenciaR));
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..fimParcial],MSS);
          servidor.send(segmento);
          aux=fimParcial;
          fimParcial=fimParcial+MSS;
          i=i+1;
          dadoslenR=servidor.receive(dadosR);
          separaSegmento2(cast(char*)dadosR,dadoslenR);
          writeln("Recebi confimacao: "~to!string(numeroReconhecimentoDR));
          portaOrigem=portaDestinoD;
          portaDestino=portaOrigemD;
          numeroReconhecimentoR=numeroSequenciaDR+1;
          numeroSequenciaR=numeroSequenciaR+MSS;
        }
        if(restoDivisao==0){
          codifica("01010000");
          writeln("Enviei segmento: " ~ to!string(numeroSequenciaR));
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..fimParcial],MSS);
          servidor.send(segmento);
        } else {
          int aux2=aux+cast(int)restoDivisao;
          codifica("01010000");
          writeln("Enviei segmento: " ~ to!string(numeroSequenciaR));
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..aux2],restoDivisao);
          servidor.send(segmento);
        }
        aux=0;
        fimParcial=MSS;
        i=0;
    }
    writeln("FECHAMENTO DE CONEXAAAAAAAAAAAAAAAAAAAAAAAAAAO ");
    dadoslenR = servidor.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    numeroSequencia=numeroSequenciaR+1;
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    servidor.send(segmento);
    dadoslenR = servidor.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    codifica("00010001");
    numeroSequencia=numeroSequencia+1;
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    numeroSequencia=numeroSequencia+1;
    servidor.send(segmento);
    dadoslenR = servidor.receive(dadosR);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    numeroSequencia=numeroSequencia;
    servidor.send(segmento);
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
  auto servidor = new ServidorTCP(10);
  while(true) {
    servidor.recebeFisica();
  }
}
