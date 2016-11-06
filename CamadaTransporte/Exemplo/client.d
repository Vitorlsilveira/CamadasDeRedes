import std.socket;
import std.stdio;
import std.file;

void main() {
    char[1024] buffer;

    // Para cada linha q vc tacar no terminal
    foreach(char [] linha; stdin.byLine) {
      auto socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
      socket.connect(new InternetAddress("localhost", 7777));

      socket.send(linha~"\n");

      // Esperando o servidor confirmar recebimento
      auto len = socket.receive(buffer);
      writeln(buffer[0 .. len]);

      socket.close();
  }

}
