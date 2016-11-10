import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.bitmanip;

class ClienteUDP {
  int portaOrigem;
  int portaDestino;
  string mensagem;

  char[10000] dados;
  long dadoslen;

  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
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
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] length = cast(char[2])nativeToLittleEndian(cast(ushort)(dadoslenA+8));
    ushort check = checksum16(cast(char*)dadosA[0 .. dadoslenA], cast(int)dadoslenA);
    char[2] checksum = cast(char[2])nativeToLittleEndian(check);

    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(length)~to!string(checksum)~to!string(dadosA[0 .. dadoslenA]~"\n");
    writeln(segmento);
    socket.send(segmento);

    //aguarda resposta
    dadoslen = socket.receive(dados);
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

    auto cliente = new ClienteUDP(port, 5555);

    cliente.executa();
}
