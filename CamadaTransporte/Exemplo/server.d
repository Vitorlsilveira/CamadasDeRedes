import std.socket;
import std.stdio;
import std.file;

void main() {
   auto listener = new Socket(AddressFamily.INET, SocketType.STREAM);
   listener.bind(new InternetAddress("localhost", 6665));
   listener.listen(10);

   char[1024] buffer;

   Socket client;

   while(true) {
      client = listener.accept();
      auto len = client.receive(buffer);
      writeln("Conteudo recebido: " ~ buffer[0 .. len] ~ "\n\n");

      auto confirmacao = "\n\nOk manel! \nConteudo recebido: " ~ buffer[0 .. len] ~ "\n\n";

      client.send(confirmacao);
  }
}
