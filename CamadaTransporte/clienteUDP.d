import std.socket;
import std.stdio;
import std.conv;
import std.process: thisProcessID;
import std.file;


class ClienteUDP {
  int portaOrigem;
  int portaDestino;
  string mensagem;

  char[10000] dados;
  long dadoslen;

  Socket listener, cliente;

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

    writeln(dados[0 .. dadoslen]);

  }

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

    cabecalho = cabecalho ~ to!string(cabecalho.length + cast(int)dadoslen) ~ ";";

    ushort checksum = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);

    cabecalho = cabecalho ~ to!string(checksum) ~ ";";

    segmento = abstracaoRede ~ cabecalho ~ to!string(dados[0 .. dadoslen]);

    writeln(segmento);
    socket.send(segmento);

    //aguarda resposta
    dadoslen = socket.receive(dados);
    //encaminha resposta cliente aplicacao
    cliente.send(dados[0 .. dadoslen]);
    cliente.close();
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

    cliente.recebeAplicacao();
    cliente.enviaFisica();
}
