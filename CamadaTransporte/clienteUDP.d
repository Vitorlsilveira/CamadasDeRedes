class clienteUDP {
  int portaOrigem;
  int portaDestino;
  string mensagem;

  char[10000] buffer;

  auto listener;

  string segmento;

  void recebeAplicacao(string ip, int port){
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 2222));
    listener.listen(10);
    cliente = listener.accept();

    auto len = cliente.receive(buffer);


  }

  void enviaFisica(){
    auto socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    socket.connect(new InternetAddress("localhost", 1111));


  }

}
