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
  int length;
  ushort checksum;
  string segmento;
  char[] mensagem;
  bool conectado = false;
  bool conectado1=false;

  char[10000] dados;
  long dadoslen;

  Socket listener, servidor,socket;

  this(){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
  }

  void enviaAplicacao(){
    writeln("entrou no envia aplicacao");
    writeln("\nEnviando para Aplicacao \n" ~ mensagem);
    // Envia a requisicao pra aplicacao
    socket.send(mensagem);
    //recebe resposta
    dadoslen = socket.receive(dados);
    writeln("recebi da aplicação:");
    writeln(dados[0..dadoslen]);
    //encaminha resposta pra Rede
    enviaRede(dados[0..dadoslen],dadoslen);
  }

  void enviaRede(char[] dadosA, long dadoslenA){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
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
    servidor.send(segmento);
  }


  void recebeRede(){
    if(!conectado){
      servidor = listener.accept();
      conectado = true;
    }
    dadoslen = servidor.receive(dados);
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    length = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[4..6]);
    checksum = cast(ushort)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[6..8]);

    if(!conectado1){
      while(true){
        try {
          socket.connect(new InternetAddress("localhost", cast(ushort)portaDestino));
          conectado1=true;
          break;
        } catch( Exception e ){
          writeln(e);
          readln();
          continue;
        }
      }
    }

    writeln("Segmento recebido: ");
    writeln("Porta origem = " ~ to!string(portaOrigem));
    writeln("Porta destino = " ~ to!string(portaDestino));
    writeln("Length= " ~ to!string(length));
    writeln("Checksum = " ~ to!string(checksum));
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
    servidor.recebeRede();
    servidor.enviaAplicacao();
  }
}
