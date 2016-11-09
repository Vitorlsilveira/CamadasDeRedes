import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.string;
import std.bitmanip;


class ServidorTCP {
  int portaOrigem;
  int portaDestino;
  int MSS;
  int janela;
  int numeroSequencia;
  int numeroReconhecimento;
  int comprimentoCabecalho;
  char[10000] bufferRemetente;
  char bitsControle;
  long dadoslen;
  ushort checksum;
  char[10000] dados;
  char[] mensagem;

  Socket listener, servidor;

  this(){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
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
    servidor.send(dados[0 .. dadoslen-1]);
    servidor.close();
  }

  void separaSegmento(char *dados,long tam){
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
//    writeln("Porta origem:"~to!string(portaOrigem));
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
  //  writeln("Porta destino:"~to!string(portaDestino));
    numeroSequencia=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    //writeln("sequencia:"~to!string(numeroSequencia));
    numeroReconhecimento=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    //writeln("reconhecimento:"~to!string(numeroReconhecimento));
    bitsControle=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    //writeln("bits controle:"~to!string(bitsControle));
    janela=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    //writeln("janela:"~to!string(janela));
    comprimentoCabecalho=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    //writeln("comprimento cabecalho:"~to!string(comprimentoCabecalho));
    checksum=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    mensagem=dados[19..tam];
  }

  void recebeFisica(){
    servidor = listener.accept();
    dadoslen = servidor.receive(dados);
    separaSegmento(cast(char*)dados,dadoslen);
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
