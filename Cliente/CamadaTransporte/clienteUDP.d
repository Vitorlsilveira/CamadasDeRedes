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
  bool controle = false;
  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
  }

//recebe dados da aplicaçao
  void recebeAplicacao(){
    //aceita conexao da aplicacao
    writeln("Aguardando conexoes da camada de aplicaçao na porta 3333");
    cliente = listener.accept();
    writeln("Conexao da camada de aplicacao aceita");
    //recebe da aplicacao
    dadoslen = cliente.receive(dados)-1;
    writeln("\nMensagem recebida da camada de aplicaçao: " ~dados[0 .. dadoslen]);
  }

// loop de execuçao
  void executa() {
    //estabelece conexao com a camada de rede
    conectaRede();
    //cria socket na porta 3333 para que a aplicacao se conecte ao socket
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 3333));
    listener.listen(10);

    while(1){
      recebeAplicacao();
      enviaRede(dados, dadoslen);
      recebeRede();
      //envia para a aplicacao
      writeln("\nMensagem enviada para a camada de aplicaçao: ");
      writeln(mensagem);
      cliente.send(mensagem);
    }
    cliente.close();
  }

//aguarda conexao com a camada de rede
  void conectaRede() {
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    writeln("Aguardando camada de rede ficar disponivel na porta 7777");
    //loop para aguardar conexao com cliente da camada de rede
    while(true){
      try {
        socket.connect(new InternetAddress("localhost", 7777));
        writeln("Conectado a camada de rede");
        break;
      } catch( Exception e ){
        continue;
      }
    }
  }

//recebe dados e separa o segmento udp
  void recebeRede(){
    //recebe dados da camada de rede
    dadoslen = socket.receive(dados);
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    length = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[4..6]);
    checksum = cast(ushort)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[6..8]);
    writeln("\nSegmento recebido da camada de rede: \n" ~dados[0..dadoslen]);
    writeln("Porta origem: " ~ to!string(portaOrigem));
    writeln("Porta destino: " ~ to!string(portaDestino));
    writeln("Length: " ~ to!string(length));
    writeln("Checksum: " ~ to!string(checksum));
    mensagem = dados[8..dadoslen];
    writeln("Dados: " ~to!string(mensagem));
  }

//anexa cabeçalho udp aos dados e envia para a camada de rede
  void enviaRede(char[] dadosA, long dadoslenA){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pLength = cast(char[2])nativeToLittleEndian(cast(ushort)(dadoslenA+8));
    ushort check = checksum16(cast(char*)dadosA[0 .. dadoslenA], cast(int)dadoslenA);
    char[2] pChecksum = cast(char[2])nativeToLittleEndian(check);
    writeln("\nSegmento enviado para a camada de rede: ");
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pLength)~to!string(pChecksum)~to!string(dadosA[0 .. dadoslenA]);
    writeln(segmento);
    writeln("Porta origem: " ~ to!string(portaOrigem));
    writeln("Porta destino: " ~ to!string(portaDestino));
    writeln("Length: " ~ to!string(dadoslenA+8));
    writeln("Checksum: " ~ to!string(pChecksum));
    writeln("Dados:"~to!string(dadosA[0..dadoslenA]));
    //envia para a camada de rede o segmento
    socket.send(segmento);

  }

 //calcula checksum
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
    //porta de origem é o pid do processo em execucao
    auto cliente = new ClienteUDP(port, 5555);

    cliente.executa();
}
