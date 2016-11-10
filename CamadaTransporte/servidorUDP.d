import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.string;
import std.bitmanip;


class ServidorUDP {
  int portaOrigem;
  int portaDestino;
  char[] mensagem;

  char[10000] dados;
  long dadoslen;

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
    servidor.send(dados[0 .. dadoslen]);
    servidor.close();
  }

  void recebeFisica(){
    servidor = listener.accept();
    dadoslen = servidor.receive(dados);

    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta origem = " ~ to!string(portaOrigem));
    writeln("Porta destino = " ~ to!string(portaDestino));
    mensagem = dados[8..dadoslen];
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
  auto servidor = new ServidorUDP();
  while(true) {
    servidor.recebeFisica();
    servidor.enviaAplicacao();
  }
}
