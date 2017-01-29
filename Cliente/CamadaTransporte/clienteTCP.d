import std.socket;
import std.stdio;
import std.random;
import std.conv;
import std.process: thisProcessID;
import std.file;
import std.bitmanip;

class ClienteTCP {
  int portaOrigem;
  int portaDestino;
  int MSS;
  int janela;
  int numeroSequencia;
  int numeroReconhecimento,numeroReconhecimentoR;
  int comprimentoCabecalho;
  string bufferRemetente;
  char bitsControle;
  string retornoControle;
  char[] mensagem;
  char[65536] dados;
  char[65536] dadosR;
  long dadoslenR;
  long dadoslen;
  char[] vetorControle;
  int portaOrigemD;
  int portaDestinoD;
  int numeroSequenciaD,numeroSequenciaR;
  int numeroReconhecimentoD;
  char bitsControleD;
  int TMQ;
  int janelaD;
  int comprimentoCabecalhoD;
  ushort checksumD;
  char[] mensagemD;
  string mensagemE;
  int tamDados;

  Socket listener, cliente, socket;

  string segmento;

  this (int portaOrigem, int portaDestino){
    this.portaOrigem = portaOrigem;
    this.portaDestino = portaDestino;
    bufferRemetente="";
  }
//codifica bits de controle
  void codifica(string controle){
        if(controle=="00000010")
        {
          bitsControle='I';
          return;
        }
        if(controle=="00010010")
        {
          bitsControle='E';
          return;
        }
        if(controle=="00010000")
        {
          bitsControle='A';
          return;
        }
        if(controle=="00010001")
        {
          bitsControle='F';
          return;
        }
        if(controle=="01010000")
        {
          bitsControle='T';
          return;
        }
  }
//decodificador dos bits de controle
   void decodifica(char controle){
         if(controle=='I')
         {
           retornoControle="00000010";
           return ;
         }
         if(controle=='E')
         {
           retornoControle="00010010";
           return;
         }
         if(controle=='A')
         {
           retornoControle="00010000";
           return;
         }
         if (controle=='F')
         {
           retornoControle="00010001";
           return;
         }
         if(controle=='T')
         {
           retornoControle="01010000";
           return;
         }
    }
//recebe dados da camada de aplicacao
  void recebeAplicacao(){
    writeln("Aguardando conexões da camada de aplicaçao na porta 3333");
    cliente = listener.accept();
    writeln("Conexao da camada de aplicacao aceita");
    dadoslen = cliente.receive(dados);
    writeln("Mensagem recebida da camada de aplicação: " ~dados[0 .. dadoslen]);
  }

//conecta-se a camada de rede
  void conectaRede() {

    socket = new Socket(AddressFamily.INET,  SocketType.STREAM);
    writeln("Aguardando camada de rede ficar disponivel na porta 7777");
    //tenta se conectar a camada de rede na porta 7777
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

  void executa() {
    //estabelece conexao com a camada de rede
    conectaRede();
    //cria socket para que a camada de aplicacao possa se conectar na porta 3333
    listener = new Socket(AddressFamily.INET, SocketType.STREAM);
    listener.bind(new InternetAddress("localhost", 3333));
    listener.listen(10);
    //recebe da aplicacao, envia para a camada de rede,recebe a resposta da camada de rede e encaminha para a aplicacao
    while(1){
      recebeAplicacao();
      enviaRede(dados, dadoslen);
      recebeResposta();
      cliente.send(mensagem);
    }
    cliente.close();
  }

//envia o segmento para a camada de rede
  void enviaRede(char[] dadosA, long dadoslenA){

    writeln("Estabelecimento de conexao (Handshake)");
    /*Estabelecimento de conexão de 3 vias- handshake*/
    codifica("00000010");
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    socket.send(segmento);
    numeroSequencia=numeroSequencia+1;
    dadoslenR = socket.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroReconhecimento=numeroSequenciaD+1;

    //printa o TMQ, como decisão de implementação colocamos que o TMQ vem da camada de transporte pelo campo janela no primeiro segmento vindo do servidor
    write("TMQ é : ");
    writeln(TMQ);
    
    //calcula o numero de segmentos necessarios levando em consideração a MSS
    MSS=TMQ-20-26;
    tamDados=MSS;
    int numSegmentos=cast(int)(dadoslenA/tamDados);
    long restoDivisao= cast(long)(dadoslenA % tamDados);
    //cria um numero de sequencia inicial aleatorio
    numeroSequencia=uniform(0,100);
    int fimParcial=tamDados;
    int aux=0;
    int i=0;
    janela=numSegmentos;

    if(numSegmentos>=0){
        while(i<numSegmentos){
          codifica("00010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosA[aux..fimParcial],tamDados);
          socket.send(segmento);
          aux=fimParcial;
          fimParcial=fimParcial+tamDados;
          i=i+1;
          dadoslenR=socket.receive(dadosR);
          writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
          separaSegmento(cast(char*)dadosR,dadoslenR);
          portaOrigem=portaDestinoD;
          portaDestino=portaOrigemD;
          //writeln("Recebi confirmação do segmento acima: " ~ to!string(numeroReconhecimentoD));
          numeroReconhecimento=numeroSequenciaD+1;
          numeroSequencia=numeroSequencia+MSS;
        }
        //envia ultimo segmento com tamanho MSS
        if(restoDivisao==0){
          codifica("01010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosA[aux..fimParcial],tamDados);
          socket.send(segmento);
        }
        //ultimo segmento com tamanho menor
        else{
          codifica("01010000");
          writeln("\nSegmento enviado para a camada de rede: ");
          criaSegmento(portaOrigem,portaDestino,janela,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosA[aux..aux+restoDivisao],restoDivisao);
          socket.send(segmento);
        }
        aux=0;
        fimParcial=tamDados;
        i=0;
    }
  }

  void recebeResposta(){
    numeroSequenciaR=numeroSequencia;
    int count=0;
    janelaD=1;
    while(1){
      count++;
      dadoslenR = socket.receive(dadosR);
      writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
      separaSegmento(cast(char*)dadosR,dadoslenR);
      bufferRemetente=bufferRemetente~mensagemE;
      portaOrigem=portaDestinoD;
      portaDestino=portaOrigemD;

      if(vetorControle[1]=='1'){
        /*começa fechar conexão*/
        writeln("\nFechamento de conexão: ");
        numeroSequenciaR=numeroSequenciaR+1;
        numeroReconhecimentoR=numeroSequenciaD+1;
        mensagem=cast(char[])bufferRemetente;
        codifica("00010001");
        writeln("\nSegmento enviado para a camada de rede: ");
        criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosR[0..0],0);
        socket.send(segmento);
        break;
      }
      numeroSequenciaR=numeroSequenciaR+1;
      numeroReconhecimentoR=numeroSequenciaD+MSS;
      codifica("00010000");
      writeln("\nSegmento enviado para a camada de rede: ");
      criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequenciaR,numeroReconhecimentoR,bitsControle,cast(char*)dadosR[0..0],0);
      socket.send(segmento);
    }

    /*Continua fechamento de conexão*/
    dadoslenR = socket.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    numeroSequencia=numeroSequenciaR+1;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    socket.send(segmento);
    dadoslenR = socket.receive(dadosR);
    writeln("\nSegmento recebido da camada de rede: \n" ~dadosR[0..dadoslenR]);
    separaSegmento(cast(char*)dadosR,dadoslenR);
    portaOrigem=portaDestinoD;
    portaDestino=portaOrigemD;
    numeroSequencia=numeroSequencia+1;
    numeroReconhecimento=numeroSequenciaD+1;
    codifica("00010000");
    writeln("\nSegmento enviado para a camada de rede: ");
    criaSegmento(portaOrigem,portaDestino,janelaD,18,numeroSequencia,numeroReconhecimento,bitsControle,cast(char*)dadosR[0..0],0);
    socket.send(segmento);
    dadoslenR = socket.receive(dadosR);
    writeln("\nMensagem enviada para a camada de aplicação: ");
    writeln(mensagem);
  }
//cria segmento
  void criaSegmento(int portaOrigem,int portaDestino,int janela,int comprimentoCabecalho,int numeroSequencia,int numeroReconhecimento,char bitsControle,char *dados,long dadoslen){
    char[2] pOrigem = cast(char[2])nativeToLittleEndian(cast(ushort)portaOrigem);
    char[2] pDestino = cast(char[2])nativeToLittleEndian(cast(ushort)portaDestino);
    char[2] pJanela = cast(char[2])nativeToLittleEndian(cast(ushort)janela);
    char[4] pNumeroSequencia = cast(char[4])nativeToLittleEndian(cast(uint)numeroSequencia);
    char[4] pNumeroReconhecimento = cast(char[4])nativeToLittleEndian(cast(uint)(numeroReconhecimento));
    char[2] pComprimentoCabecalho = cast(char[2])nativeToLittleEndian(cast(ushort)(comprimentoCabecalho));
    ushort check = checksum16(cast(char*)dados[0 .. dadoslen], cast(int)dadoslen);
    char[2] checksum = cast(char[2])nativeToLittleEndian(check);
    segmento = to!string(pOrigem)~to!string(pDestino)~to!string(pNumeroSequencia)~to!string(pNumeroReconhecimento)~to!string(bitsControle)~to!string(pJanela)~to!string(pComprimentoCabecalho)~to!string(checksum)~to!string(dados[0..dadoslen]);
    writeln(segmento);
    writeln("Porta origem: "~to!string(portaOrigem));
    writeln("Porta destino: "~to!string(portaDestino));
    writeln("Numero de sequencia: "~to!string(numeroSequencia));
    writeln("Numero de reconhecimento: "~to!string(numeroReconhecimento));
    writeln("Bits de controle: "~to!string(bitsControle));
    writeln("Janela: "~to!string(janela));
    writeln("Comprimento do cabecalho: "~to!string(comprimentoCabecalho));
    writeln("Checksum: "~to!string(checksum));
    writeln("Dados: "~to!string(dados[0..dadoslen]));
  }

//separa segmento
  void separaSegmento(char *dados,long tam){
    portaOrigemD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[0..2]);
    writeln("Porta origem: "~to!string(portaOrigemD));
    portaDestinoD = cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[2..4]);
    writeln("Porta destino: "~to!string(portaDestinoD));
    numeroSequenciaD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[4..8]);
    writeln("Numero de sequencia: "~to!string(numeroSequenciaD));
    numeroReconhecimentoD=cast(int)littleEndianToNative!(uint,4)(cast(ubyte[4])dados[8..12]);
    writeln("Numero de reconhecimento: "~to!string(numeroReconhecimentoD));
    bitsControleD=cast(char)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[12..13]);
    decodifica(bitsControleD);
    vetorControle=cast(char[])retornoControle;
    writeln("Flag do ultimo segmento: ");
    writeln(vetorControle[1]);
    writeln("Bits controle: "~to!string(bitsControleD));
    janelaD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[13..15]);
    writeln("Janela: "~to!string(janelaD));
    comprimentoCabecalhoD=cast(int)littleEndianToNative!(byte,1)(cast(ubyte[1])dados[15..16]);
    writeln("Comprimento cabecalho: "~to!string(comprimentoCabecalhoD));
    checksumD=cast(int)littleEndianToNative!(ushort,2)(cast(ubyte[2])dados[16..18]);
    writeln("Checksum: "~to!string(checksumD));
    if(TMQ==0){
      TMQ=janelaD;
      return;
    }
    if(tam>=19){
      mensagemD=dados[19..tam];
      mensagemE=to!string(mensagemD);
      writeln("Dados: ");
      writeln(mensagemE);
    }
  }

//checksum
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
    //porta de origem é o pid do processo em execucao
    const port = thisProcessID;
    auto cliente = new ClienteTCP(port, 5555);

    cliente.executa();
}
