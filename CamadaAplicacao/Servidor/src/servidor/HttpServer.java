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
        //cria socket para que a camada de transporte possa se conectar na porta 5555
        ServerSocket serverSocket = null;
        try {
            // Cria a conexão servidora
            serverSocket = new ServerSocket(port, 10,
                    InetAddress.getByName(host));
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Erro ao iniciar servidor!", e);
            return;
        }
        // Fica esperando pela conexão cliente
        while (true) {
            System.out.println("Aguardando conexões da camada de transporte na porta: " + this.port);
            Socket socket = null;
            InputStream input = null;
            OutputStream output = null;
            try {
                socket = serverSocket.accept();
                System.out.println("Conexão com a camada de transporte aceita");
                while (true) {
                    try {
                        //cria objeto para enviar e receber dados do socket
                        input = socket.getInputStream();
                        output = socket.getOutputStream();

                        // converte de stream para string os dados recebidos da camada de transporte
                        String requestString = convertStreamToString(input);
                        String saida = requestString;
                        System.out.println("Mensagem recebida da camada de transporte: \n\n" + saida + "\n\n");
                        escritor("pacote_recebido.txt", requestString);
                        
                        // Realiza o parse da requisição recebida pela camada de transporte                              
                        Request request = new Request();
                        request.parse(saida);
                        
                        // cria a resposta de acordo com a requisicao recebida
                        Response response = new Response(request);
                        String responseString = response.respond();
                        System.out.println("Mensagem enviada para a camada de trasnporte:\n" + responseString);

                        escritor("resposta.txt", responseString);
                        //envia resposta para a camada de transporte
                        output.write(responseString.getBytes());
                    } catch (IndexOutOfBoundsException e) {
                        break;
                    }
                }
            } catch (Exception e) {
                logger.log(Level.SEVERE, "Erro ao executar servidor!", e);
                continue;
            } finally {
                try {
                    //fecha conexao
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
    //funcao que converte de stream para string
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
        HttpServer server = new HttpServer("localhost", 5555);
        server.serve();
    }

}
