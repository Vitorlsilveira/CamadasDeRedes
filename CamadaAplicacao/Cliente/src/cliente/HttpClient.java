package cliente;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.DataOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ConnectException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Cliente HTTP simples para somente requisições GET
 *
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 1.1
 *
 */
public class HttpClient {

    public final static Logger logger = Logger.getLogger(HttpClient.class.toString());

    /**
     * Versão do protocolo utilizada
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
     * Realiza uma requisição HTTP e devolve uma resposta
     *
     * @param path caminho a ser feita a requisição
     * @return resposta do protocolo HTTP
     * @throws UnknownHostException quando não encontra o host
     * @throws IOException quando há algum erro de comunicação
     */
    public String getURIRawContent(String path) throws UnknownHostException,
            IOException {
        Socket clientSocket = null;
        try {
            // Abre a conexão
            while(true) {
                try {
                    clientSocket = new Socket("localhost", 7777);
                    break;
                } catch(ConnectException ex) {
                }
            }
            DataOutputStream outToServer = new DataOutputStream(clientSocket.getOutputStream());
            BufferedReader inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

            String req = "";

            // Envia a requisição
            req += this.myip + ":" + "7777" + ";" + this.host + ":" + "6969" + ";";
            req += "GET " + path + " " + HTTP_VERSION + "\n";
            req += "Host: " + this.host + "\n";
            req += "Connection: Close;";
            
            escritor("requisicaoEmTextoCA.txt", req);
            //System.out.println("Pacote: \n\n" + req + "\n\n" + reqBin + "\n\n");
            outToServer.writeBytes(req + "\n");

            boolean loop = true;
            StringBuilder sb = new StringBuilder();
            // recupera a resposta quando ela estiver disponível
            while (loop) {
                if (inFromServer.ready()) {
                    int i = 0;
                    while ((i = inFromServer.read()) != -1) {
                        sb.append((char) i);
                    }
                    loop = false;
                }
            }
            return sb.toString();
        } finally {
            if (clientSocket != null) {
                clientSocket.close();
            }
        }
    }
    
    private static void escritor(String path, String dados) throws IOException {
        BufferedWriter buffWrite = new BufferedWriter(new FileWriter(path));
        buffWrite.append(dados + "\n");
        buffWrite.close();
    }

    public static void main(String[] args) {
        HttpClient client = new HttpClient("localhost", 6768, "localhost");
        try {
            System.out.println(client.getURIRawContent("/hello.html"));
        } catch (UnknownHostException e) {
            logger.log(Level.SEVERE, "Host desconhecido!", e);
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Erro de entrada e saída!", e);
        }

    }

}
