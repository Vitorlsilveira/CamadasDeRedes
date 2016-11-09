import std.socket;
import std.stdio;
import std.conv;
import core.stdc.string;
import std.random;
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
  long dadoslen;

  Socket listener, cliente;

  string segmento;

  this (int portaOrigem, int portaDestino){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
  }
/*
  void recebeAplicacao(){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 3333));
    listener.listen(10);

    cliente = listener.accept();
    dadoslen = cliente.receive(dados);
    writeln("QNT = " ~ to!string(dadoslen));
    writeln(dados[0 .. dadoslen]);
  }
  */
  void criaSegmento(int portaOrigem,int portaDestino,int janela,int comprimentoCabecalho,int numeroSequencia,int numeroReconhecimento,char bitsControle,char * checksum,char *dados){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pJanela = cast(char[2])nativeToLittleEndian(cast(ushort)janela);
    char[4] pNumeroSequencia = cast(char[4])nativeToLittleEndian(cast(uint)numeroSequencia);
    char[4] pNumeroReconhecimento = cast(char[4])nativeToLittleEndian(cast(uint)(0));
    char[2] pComprimentoCabecalho = cast(char[2])nativeToLittleEndian(cast(ushort)(18));
//    ushort check = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);
//    char[2] checksum = cast(char[2])nativeToLittleEndian(check);
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados);
    writeln(segmento);
    separaSegmento(cast(char*)segmento,18);
    writeln(segmento);
  }

  void separaSegmento(char *dados,int tam){
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    writeln("Porta origem:"~to!string(portaOrigem));
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta destino:"~to!string(portaDestino));
    numeroSequencia=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    writeln("sequencia:"~to!string(numeroSequencia));
    numeroReconhecimento=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    writeln("reconhecimento:"~to!string(numeroReconhecimento));
    bitsControle=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    writeln("bits controle:"~to!string(bitsControle));
    janela=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    writeln("janela:"~to!string(janela));
    comprimentoCabecalho=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    writeln("comprimento cabecalho:"~to!string(comprimentoCabecalho));
    writeln(strlen(dados));
    mensagem=to!string(dados[18..(tamanhoVetor-1)]);
  //  checksum=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
  }
  /*

  void enviaFisica(){
    auto socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
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
    //localhost:07777;localhost:06969;

    string abstracaoRede = "localhost;" ~ "localhost;";
    string cabecalho = to!string(portaOrigem) ~ ";" ~ to!string(portaDestino) ~ ";";

    numeroSequencia = to!int(uniform(0, 100));
    //estabelecimento de conexão , apresentação de três vias
    segmento=criaSegmento(portaOrigem,portaDestino,janela,comprimentoCabecalho,numeroSequencia,numeroReconhecimento,bitsControle,check,dados);
    writeln(segmento);
    socket.send(segmento);

    //aguarda resposta
    dadoslen = socket.receive(dados);

    //encaminha resposta cliente aplicacao
    cliente.send(dados[0 .. dadoslen]);
    cliente.close();
  }
*/
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

    auto cliente = new ClienteTCP(port, 5555);
    cliente.criaSegmento(5555,4444,4,4,1,0,'A',cast(char*)"teste",cast(char*)"verifica");
//    cliente.recebeAplicacao();
//    cliente.enviaFisica();
}
