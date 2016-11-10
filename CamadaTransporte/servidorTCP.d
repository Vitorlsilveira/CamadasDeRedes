import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.string;
import std.random;
import std.bitmanip;


class ServidorTCP {
  int portaOrigem;
  int portaDestino;
  int MSS;
  int janela;
  int numeroSequencia;
  int numeroReconhecimento;
  int comprimentoCabecalho;
  string bufferDestinatario;
  char bitsControle;
  long dadoslen;
  long dadoslenR;
  ushort checksum;
  string segmento;
  char[10000] dados;
  char[10000] dadosR;
  char[] mensagem;

  int portaOrigemD;
  int portaDestinoD;
  int numeroSequenciaD;
  int numeroReconhecimentoD;
  char bitsControleD;
  int janelaD;
  int comprimentoCabecalhoD;
  ushort checksumD;
  char[] mensagemD;

  Socket listener, servidor;

  this(){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
    bufferDestinatario="";
  }

  void enviaAplicacao(){
    auto socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    while(true){
      try {
        socket.connect(new InternetAddress("localhost", cast(ushort)portaDestino));
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
    //encaminha resposta pra fisica
    servidor.send(dados[0 .. dadoslen]);
    servidor.close();
  }

  void criaSegmento(int portaOrigem,int portaDestino,int janela,int comprimentoCabecalho,int numeroSequencia,int numeroReconhecimento,char bitsControle,char *dados,long dadoslen){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pJanela = cast(char[2])nativeToLittleEndian(cast(ushort)janela);
    char[4] pNumeroSequencia = cast(char[4])nativeToLittleEndian(cast(uint)numeroSequencia);
    char[4] pNumeroReconhecimento = cast(char[4])nativeToLittleEndian(cast(uint)(0));
    char[2] pComprimentoCabecalho = cast(char[2])nativeToLittleEndian(cast(ushort)(18));
    ushort check = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);
    char[2] checksum = cast(char[2])nativeToLittleEndian(check);
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados[0..dadoslen]~"\n\n");
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


  void recebeFisica(){
    writeln("esperando conexao");
    servidor = listener.accept();
    writeln("aceitou");
    int count=0;
    janelaD=1;
    numeroSequencia=uniform(0,100);
    while(janelaD>0){
      writeln("entrei no loop");
      count++;
      dadoslenR = servidor.receive(dadosR);
      writeln("recebeu segmento");
      writeln(dadosR[0..dadoslenR]);
      separaSegmento(cast(char*)dadosR,dadoslenR);
      bufferDestinatario=bufferDestinatario~to!string(mensagemD);
      portaOrigem=portaDestinoD;
      portaDestino=portaOrigemD;
      numeroSequencia=numeroSequencia+1;
      numeroReconhecimento=numeroSequenciaD+1;
      criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,cast(char)'A',cast(char*)dadosR[0..0],0);
      servidor.send(segmento);
    }
    mensagem=cast(char[])bufferDestinatario;

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
    servidor.recebeFisica();
    servidor.enviaAplicacao();
  }
}
