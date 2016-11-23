package servidor;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.BufferedWriter;
import java.io.FileWriter;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Reader;
import java.io.StringWriter;
import java.io.Writer;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.util.logging.Level;
import java.util.logging.Logger;

import classes.request.Request;
import classes.response.Response;

/**
 * Servidor HTTP simples
 *
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 1.1
 */
public class HttpServer {

    private final static Logger logger = Logger.getLogger(HttpServer.class
            .toString());

    private String host;
    private int port;

    /**
     * Construtor do servidor de HTTP
     *
     * @param host host do servidor
     * @param port porta do servidor
     */
    public HttpServer(String host, int port) {
        //super();
        this.host = host;
        this.port = port;
    }

    /**
     * Inicia o servidor e fica escutando no endereço e porta especificada no
     * construtor
     */
    public void serve() {
        ServerSocket serverSocket = null;

        System.out.println("Iniciando servidor no endereço: " + this.host
                + ":" + this.port);

        try {
            // Cria a conexão servidora
            serverSocket = new ServerSocket(port, 10,
                    InetAddress.getByName(host));
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Erro ao iniciar servidor!", e);
            return;
        }
        System.out.println("Conexão com o servidor aberta no endereço: " + this.host
                + ":" + this.port);

        // Fica esperando pela conexão cliente
        while (true) {
            System.out.println("Aguardando conexões...");
            Socket socket = null;
            InputStream input = null;
            OutputStream output = null;
            try {
                socket = serverSocket.accept();
                System.out.println("Aceitou conexão com o servidor da camada fisica");
                while (true) {
                    try {
                        input = socket.getInputStream();
                        output = socket.getOutputStream();

                        // Realiza o parse da requisição recebida
                        String requestString = convertStreamToString(input);
                        String saida = requestString;
                        /*System.out.println("Conexão recebida. Conteúdo em binário:\n" + requestString);
                         System.out.println("Conexão recebida. Conteúdo em texto:\n\n" + saida + "\n\n");*/
                        System.out.println("Conteudo recebido: \n\n " + saida + "\n\n" + requestString + "\n\n");
                        escritor("pacote_recebido.txt", requestString);
                        //escritor("respostaDaFisicaEmTextoSA.txt",saida);                                
                        Request request = new Request();
                        request.parse(saida);

                        // recupera a resposta de acordo com a requisicao
                        Response response = new Response(request);
                        String responseString = response.respond();
                        System.out.println("Resposta enviada. Conteúdo:\n" + responseString);
                        escritor("resposta.txt", responseString);

                        output.write(responseString.getBytes());
                    } catch (IndexOutOfBoundsException e) {
                        break;
                    }
                    // Fecha a conexão
                }
                //socket.close();
            } catch (Exception e) {
                logger.log(Level.SEVERE, "Erro ao executar servidor!", e);
                continue;
            } finally {
                try {
                    if (socket != null) {
                        socket.close();
                    }
                } catch (IOException ex) {
                    Logger.getLogger(HttpServer.class.getName()).log(Level.SEVERE, null, ex);
                }
            }

        }
    }

    private static void escritor(String path, String dados) throws IOException {
        BufferedWriter buffWrite = new BufferedWriter(new FileWriter(path));
        buffWrite.append(dados + "\n");
        buffWrite.close();
    }

    private String convertStreamToString(InputStream is) {
        if (is != null) {
            Writer writer = new StringWriter();

            char[] buffer = new char[65536];
            try {
                Reader reader = new BufferedReader(new InputStreamReader(is));
                int i = reader.read(buffer);
                writer.write(buffer, 0, i);
            } catch (IOException e) {
                logger.log(Level.SEVERE, "Erro ao converter stream para string", e);
                return "";
            }
            return writer.toString();
        }
        return "";
    }

    public static void main(String[] args) {
        //Scanner reader = new Scanner(System.in);  
        //System.out.println("Qual o endereco?");
                /*String ip = reader.nextLine();*/
        HttpServer server = new HttpServer("localhost", 5555);
        server.serve();
    }

}
