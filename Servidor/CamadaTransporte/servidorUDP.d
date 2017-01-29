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

  char[65536] dados;
  long dadoslen;

  Socket listener, servidor,socket;

  this(){
    //cria socket para que a camada de rede possa se conectar na porta 6768
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 6768));
    listener.listen(10);
    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
  }

  //aceita conexão da camada de rede
  void aceitaConexao(){
    writeln("Aguardando conexões da camada de rede na porta 6768");
    servidor = listener.accept();
    writeln("Conexao da camada de rede aceita");
  }

  // envia o segmento para a camada de aplicacao, recebe resposta da aplicacao e encaminha de volta para a camada de rede
  void enviaAplicacao(){
    writeln("\nMensagem enviada para a camada de aplicação: ");
    writeln(mensagem);
    // Envia a requisicao pra aplicação
    socket.send(mensagem);
    //recebe resposta da aplicação
    dadoslen = socket.receive(dados);
    writeln("\nMensagem recebida da camada de aplicação: " ~dados[0 .. dadoslen]);
    //encaminha resposta pra camada de rede
    enviaRede(dados[0..dadoslen],dadoslen);

  }

//anexa cabeçalho udp aos dados e envia para a camada de rede
  void enviaRede(char[] dadosA, long dadoslenA){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
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
    servidor.send(segmento);
  }

//recebe dados e separa o segmento udp
  void recebeRede(){
    //recebe dados da camada de rede
    dadoslen = servidor.receive(dados);
    portaOrigem = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    portaDestino = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    length = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[4..6]);
    checksum = cast(ushort)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[6..8]);
    //conecta-se a camada de aplicacao na porta de destino
    writeln("Aguardando camada de aplicação ficar disponivel na porta "~to!string(portaDestino));
    if(!conectado){
      while(true){
        try {
          socket.connect(new InternetAddress("localhost", cast(ushort)portaDestino));
          conectado=true;
          writeln("Conectado a camada de aplicação");
          break;
        } catch( Exception e ){
          continue;
        }
      }
    }
    writeln("\nSegmento recebido da camada de rede: \n" ~dados[0..dadoslen]);
    writeln("Porta origem: " ~ to!string(portaOrigem));
    writeln("Porta destino: " ~ to!string(portaDestino));
    writeln("Length: " ~ to!string(length));
    writeln("Checksum: " ~ to!string(checksum));
    mensagem = dados[8..dadoslen];
    writeln("Dados: " ~to!string(mensagem));
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
  //aceita conexao da camada de rede
  servidor.aceitaConexao();
  //loop para ficar sempre recebendo da rede, enviando para aplicacao,recebendo da aplicacao e encaminhando a resposta para a de rede
  while(true) {
    servidor.recebeRede();
    servidor.enviaAplicacao();
  }
}
