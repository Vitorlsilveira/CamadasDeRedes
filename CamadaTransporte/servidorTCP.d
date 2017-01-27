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
  char[65536] dados;
  char[65536] dadosA;
  char[65536] dadosR;
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
  int tamDados;
  bool conectado = false;
  Socket listener, servidor, socket;

  this(){
    //cria socket para que a camada de rde se conecte a camada de transporte na porta 6768
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
    bufferDestinatario="";
  }

//codifica bits de controle
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

//decodificador dos bits de controle
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


  //cria segmento
    void criaSegmento(int portaOrigem,int portaDestino,int janela,int comprimentoCabecalho,int numeroSequencia,int numeroReconhecimento,char bitsControle,char *dados,long dadoslen){
      char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
      char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
      char[2] pJanela = cast(char[2])nativeToLittleEndian(cast(ushort)janela);
      char[4] pNumeroSequencia = cast(char[4])nativeToLittleEndian(cast(uint)numeroSequencia);
      char[4] pNumeroReconhecimento = cast(char[4])nativeToLittleEndian(cast(uint)(numeroReconhecimento));
      char[2] pComprimentoCabecalho = cast(char[2])nativeToLittleEndian(cast(ushort)(comprimentoCabecalho));
      ushort check = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);
      char[2] checksum = cast(char[2])nativeToLittleEndian(check);
      segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados[0..dadoslen]);
      writeln(segmento);
      writeln("Porta origem: "~to!string(portaOrigem));
      writeln("Porta destino: "~to!string(portaDestino));
      writeln("Numero de sequencia: "~to!string(numeroSequencia));
      writeln("Numero de reconhecimento: "~to!string(numeroReconhecimento));
      writeln("Bits de controle: "~to!string(bitsControle));
      writeln("Janela: "~to!string(janela));
      writeln("Comprimento do cabecalho: "~to!string(comprimentoCabecalho));
      writeln("Checksum: "~to!string(checksum));
      writeln("Dados: "~to!string(dados[0..dadoslen]));
    }
//separa segmento
  void separaSegmento(char *dados,long tam){
    portaOrigemD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    writeln("Porta origem: "~to!string(portaOrigemD));
    portaDestinoD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta destino: "~to!string(portaDestinoD));
    numeroSequenciaD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    writeln("Numero de sequencia: "~to!string(numeroSequenciaD));
    numeroReconhecimentoD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    writeln("Numero de reconhecimento: "~to!string(numeroReconhecimentoD));
    bitsControleD=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    decodifica(bitsControleD);
    vetorControle=cast(char[])retornoControle;
    writeln("Flag do ultimo segmento: ");
    writeln(vetorControle[1]);
    writeln("Bits controle: "~to!string(bitsControleD));
    janelaD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    writeln("Janela: "~to!string(janelaD));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    writeln("comprimento cabecalho: "~to!string(comprimentoCabecalhoD));
    checksumD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    writeln("Checksum: "~to!string(checksumD));
    if(tam>=19){
      mensagemD=dados[19..tam];
      mensagemE=to!string(mensagemD);
      writeln("Dados recebidos: ");
      writeln(mensagemE);
      tamanhoBufferDestinatario=tamanhoBufferDestinatario+cast(int)tam-19;
    }
  }
//separa segmento
  void separaSegmento2(char *dados,long tam){
    portaOrigemDR = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    writeln("Porta origem: "~to!string(portaOrigemDR));
    portaDestinoDR = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta destino: "~to!string(portaDestinoDR));
    numeroSequenciaDR=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    writeln("Numero de sequencia: "~to!string(numeroSequenciaDR));
    numeroReconhecimentoDR=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    writeln("Numero de reconhecimento: "~to!string(numeroReconhecimentoDR));
    bitsControleDR=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    decodifica(bitsControleDR);
    vetorControle=cast(char[])retornoControle;
    writeln("Flag de ultimo segmento: ");
    writeln(vetorControle[1]);
    writeln("Bits de controle: "~to!string(bitsControleDR));
    janelaDR=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    writeln("Janela: "~to!string(janelaDR));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    writeln("Comprimento do cabecalho: "~to!string(comprimentoCabecalhoDR));
    checksumDR=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    writeln("Checksum: "~to!string(checksumDR));
    if(tam>=19){
      mensagemDR=dados[19..tam];
      mensagemER=to!string(mensagemD);
      tamanhoBufferDestinatarioR=tamanhoBufferDestinatarioR+cast(int)tam-19;
      writeln("Dados: ");
      writeln(mensagemER);
    }
  }

  void recebeRede(){
    if(!conectado){
      //aceita conexao da camada de rede
      writeln("Aguardando conexões da camada de rede na porta 6768");
      servidor = listener.accept();
      writeln("Conexao da camada de rede aceita");
      conectado = true;
    }
    int count=0;
    janelaD=1;
    //cria numero de sequencia aleatorio
    numeroSequencia=uniform(0,100);
    mensagem=[];
    bufferDestinatario="";
    bufferDestinatarioR="";
    mensagemE="";
    mensagemER="";

    /*Estabelecimento de conexão de 3 vias - handshake*/
    auto f = File("TMQ.txt");
    string buffer;
    foreach (line ; f.byLine) {
        buffer ~= line;
    }
    f.close();
    int TMQ=to!int(buffer);
    if(TMQ<66){
      writeln("TMQ muito baixo, não cobre nem os cabeçalhos da camada de transporte,rede e fisica");
      getchar();
    }
    MSS=TMQ-20-26;
    tamDados=MSS-18;

    dadoslenR = servidor.receive(dadosR);
    writeln("Estabelecimento de conexao (Handshake)");
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010010");
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,TMQ,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    servidor.send(segmento);
    while(1){
      count++;
      //recebe \nSegmento da camada de rede
      dadoslenR = servidor.receive(dadosR);
      writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
      separaSegmento(cast(char*)dadosR,dadoslenR);
      bufferDestinatario = bufferDestinatario ~ mensagemE;
      //envia a resposta
      portaOrigem=portaDestinoD;
      portaDestino=portaOrigemD;
      janela=janelaD;
      numeroSequencia=numeroSequencia+1;
      numeroReconhecimento=numeroSequenciaD+MSS;
      if(vetorControle[1]=='0'){
        codifica("00010000");
        writeln("\nSegmento enviado para a camada de rede: ");
        criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
        servidor.send(segmento);
        continue;
      }
      else{
        break;
      }
    }
    mensagem=cast(char[])bufferDestinatario;
    writeln("Requisicao completa: ");
    writeln(mensagem);
    //abre conexao com camada de aplicacao na porta de destino
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    writeln("Aguardando camada de aplicação ficar disponivel na porta "~to!string(portaDestinoD));
    while(true){
      try {
        //tenta conectar com a camada de aplicacao
        socket.connect(new InternetAddress("localhost", cast(ushort)portaDestinoD));
        writeln("Conectado a camada de aplicação");
        break;
      } catch( Exception e ){
        continue;
      }
    }
    writeln("\nMensagem enviada para a camada de aplicação: ");
    writeln(mensagem);
    // Envia a requisicao pra aplicacao
    socket.send(mensagem);
    //recebe resposta
    dadoslen = socket.receive(dados);
    socket.close();
    writeln("\nMensagem recebida da camada de aplicação: " ~dados[0 .. dadoslen]);
    //encaminha resposta pra Rede
    //calcula o numero de segmentos necessarios levando em consideração a MSS e o tamanho dos dados a serem enviados
    long dadoslenA=dadoslen;
    dadosA=dados;
    int numSegmentos=cast(int)(dadoslenA/tamDados);
    long restoDivisao= cast(long)(dadoslenA % tamDados);
    numeroSequenciaR=numeroSequencia;
    numeroReconhecimentoR=numeroReconhecimento;
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    int fimParcial=tamDados;
    int aux=0;
    int i=0;
    janelaR=numSegmentos;
    if(numSegmentos>0){
        while(i<numSegmentos){
          codifica("00010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..fimParcial],tamDados);
          servidor.send(segmento);
          aux=fimParcial;
          fimParcial=fimParcial+tamDados;
          i=i+1;
          dadoslenR=servidor.receive(dadosR);
          writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
          separaSegmento2(cast(char*)dadosR,dadoslenR);
          portaOrigem=portaDestinoD;
          portaDestino=portaOrigemD;
          numeroReconhecimentoR=numeroSequenciaDR+1;
          numeroSequenciaR=numeroSequenciaR+MSS;
        }
        //envia o ultimo segmento
        if(restoDivisao==0){
          codifica("01010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..fimParcial],tamDados);
          servidor.send(segmento);
        } else {
          int aux2=aux+cast(int)restoDivisao;
          codifica("01010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janelaR,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosA[aux..aux+restoDivisao],restoDivisao);
          servidor.send(segmento);
        }
        aux=0;
        fimParcial=tamDados;
        i=0;
    }
    writeln("\nFechamento de conexao: ");
    dadoslenR = servidor.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    numeroSequencia=numeroSequenciaR+1;
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    servidor.send(segmento);
    dadoslenR = servidor.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    codifica("00010001");
    numeroSequencia=numeroSequencia+1;
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    numeroSequencia=numeroSequencia+1;
    servidor.send(segmento);
    dadoslenR = servidor.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    writeln("\nSegmento enviado para a camada de rede: ");
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
  auto servidor = new ServidorTCP();
  while(true) {
    servidor.recebeRede();
  }
}
