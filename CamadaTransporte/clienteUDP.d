import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.bitmanip;

class ClienteUDP {
  int portaOrigem;
  int portaDestino;
  char[] mensagem;
  int length;
  ushort checksum;

  char[65536] dados;
  long dadoslen;

  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
  }

  void recebeAplicacao(){
    cliente = listener.accept();
    dadoslen = cliente.receive(dados)-1;
    writeln("QNT = " ~ to!string(dadoslen));
    writeln(dados[0 .. dadoslen]);
  }

  void conectaRede() {
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    writeln("Aguardando cliente da camada Rede");
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
    conectaRede();
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 3333));
    listener.listen(10);

    while(1){
      recebeAplicacao();
      enviaRede(dados, dadoslen);
      recebeRede();
      writeln(mensagem);
      cliente.send(mensagem);
    }
    cliente.close();
  }

  void recebeRede(){

    dadoslen = socket.receive(dados);
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    length = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[4..6]);
    checksum = cast(ushort)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[6..8]);
    writeln("Segmento recebido: ");
    writeln("Porta origem = " ~ to!string(portaOrigem));
    writeln("Porta destino = " ~ to!string(portaDestino));
    writeln("Length= " ~ to!string(length));
    writeln("Checksum = " ~ to!string(checksum));
    mensagem = dados[8..dadoslen];
    writeln("Dados = " ~to!string(mensagem));
  }

  void enviaRede(char[] dadosA, long dadoslenA){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pLength = cast(char[2])nativeToLittleEndian(cast(ushort)(dadoslenA+8));
    ushort check = checksum16(cast(char*)dadosA[0 .. dadoslenA], cast(int)dadoslenA);
    char[2] pChecksum = cast(char[2])nativeToLittleEndian(check);
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pLength)~to!string(pChecksum)~to!string(dadosA[0 .. dadoslenA]);
    writeln("Segmento enviado: ");
    writeln(segmento);
    writeln("Porta origem = " ~ to!string(portaOrigem));
    writeln("Porta destino = " ~ to!string(portaDestino));
    writeln("Length= " ~ to!string(dadoslenA+8));
    writeln("Checksum = " ~ to!string(pChecksum));
    socket.send(segmento);

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
