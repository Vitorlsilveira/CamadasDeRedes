package cliente;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ConnectException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Cliente HTTP simples para somente requisiçoes GET
 *
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 1.1
 *
 */
public class HttpClient {

    public final static Logger logger = Logger.getLogger(HttpClient.class.toString());

    /**
     * Versao do protocolo utilizada
     */
    public final static String HTTP_VERSION = "HTTP/1.1";

    private String host;
    private int port;
    private String myip;

    /**
     * Construtor do cliente HTTP
     *
     * @param host host para o cliente acessar
     * @param port porta de acesso
     */
    public HttpClient(String host, int port, String myip) {
        super();
        this.host = host;
        this.port = port;
        this.myip = myip;
    }

    /**
     * Realiza uma requisiçao HTTP e devolve uma resposta
     *
     * @param path caminho a ser feita a requisiçao
     * @return resposta do protocolo HTTP
     * @throws UnknownHostException quando nao encontra o host
     * @throws IOException quando há algum erro de comunicaçao
     */
    public String getURIRawContent(String path) throws UnknownHostException,
            IOException {
        Socket clientSocket = null;
        try {
            // Abre a conexao com a camada de transporte
            System.out.println("Aguardando camada de transporte ficar disponível na porta 3333");
            while (true) {
                try {
                    clientSocket = new Socket("localhost", 3333);
                    break;
                } catch (ConnectException ex) {
                }
            }
            System.out.println("Conectado a camada de transporte");
            
            //envio
            PrintWriter outToServer = new PrintWriter(clientSocket.getOutputStream(), true);
            //recebimento
            BufferedReader inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

            String req = "";

            // Envia a requisiçao
            req += "GET " + path + " " + HTTP_VERSION + "\n";
            req += "Host: " + this.host + "\n";
            req += "Connection: Close;";

            escritor("CamadaAplicacao/requisicao.txt", req);
            System.out.println("Mensagem enviada para a camada de transporte: \n\n" + req + "\n\n");
            outToServer.println(req);

            StringBuilder sb = new StringBuilder();
            // recupera a resposta da camada de transporte quando ela estiver disponivel
            while (true) {
                int a = 0;
                if (inFromServer.ready()) {
                    int i = 0;
                    while (inFromServer.ready() && (i = inFromServer.read()) != -1) {
                        sb.append((char) i);
                    }
                    break;
                }
            }
            String response = sb.toString();
            String[] split = response.split("\r\n\r\n", 2);
            salvarImagem(path, split[1]);
            System.out.println("Mensagem recebida da camada de transporte: " + sb.toString() );
            escritor("CamadaAplicacao/resposta.txt", sb.toString());
            return sb.toString();
        } finally {
            if (clientSocket != null) {
                clientSocket.close();
            }
        }
    }

    //funcao criada para salvar a resposta da requisicao como uma imagem FALTA ARRUMAR
    private void salvarImagem(String path, String imagem) throws IOException {
        byte[] buffer = imagem.getBytes(StandardCharsets.UTF_8);
        if (path.contains(".jpg")) {
            System.out.println(buffer.length);
            /*ByteArrayInputStream in = new ByteArrayInputStream(buffer);
            BufferedImage bImageFromConvert = ImageIO.read(in);
            System.out.println(bImageFromConvert);
            ImageIO.write(bImageFromConvert, "jpg", new File("saida"));*/
            ByteToImage(buffer);
        }
    }

    //converter bytes para imagem FALTA ARRUMAR
    public void ByteToImage(byte[] bytes) {
        byte[] imgBytes = bytes;
        try {
            FileOutputStream fos = new FileOutputStream("saida.jpg");
            fos.write(imgBytes);
            FileDescriptor fd = fos.getFD();
            fos.flush();
            fd.sync();
            fos.close();
        } catch (Exception e) {
            System.out.println(e);
        }
    }

    //funcao criada para escrever dados num arquivo
    private static void escritor(String path, String dados) throws IOException {
        BufferedWriter buffWrite = new BufferedWriter(new FileWriter(path));
        buffWrite.append(dados + "\n");
        buffWrite.close();
    }

    public static void main(String[] args) {
        //le do arquivo config , o ip de destino, a interface e a requisiçao
        FileReader arq;
        BufferedReader lerArq;
        String ipDest="";
        String interf="";
        String arquivoRequerido="";
        try {
          arq = new FileReader("config"); 
          lerArq = new BufferedReader(arq); 
          ipDest = lerArq.readLine(); // lê a primeira linha
          interf = lerArq.readLine(); // lê a primeira linha
          arquivoRequerido = lerArq.readLine(); // lê a primeira linha        
          arq.close();
        } catch (IOException e) {
             System.err.printf("Erro na abertura do arquivo: %s.\n",
             e.getMessage());
        }
        
        //instancia novo objeto http client com os parametros adequados
        HttpClient client = new HttpClient(ipDest, 5555, "localhost");
        try {
            client.getURIRawContent("/" + arquivoRequerido);
        } catch (UnknownHostException e) {
            logger.log(Level.SEVERE, "Host desconhecido!", e);
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Erro de entrada e saída!", e);
        }

    }

}
