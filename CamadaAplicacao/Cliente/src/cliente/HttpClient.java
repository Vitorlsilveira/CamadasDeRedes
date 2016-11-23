package cliente;

import java.awt.image.BufferedImage;
import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileDescriptor;
import java.io.FileOutputStream;
import java.io.FileWriter;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
import java.net.ConnectException;
import java.net.Socket;
import java.net.UnknownHostException;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;
import java.util.logging.Level;
import java.util.logging.Logger;
import javax.imageio.ImageIO;

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
            while (true) {
                try {
                    clientSocket = new Socket("localhost", 3333);
                    break;
                } catch (ConnectException ex) {
                }
            }

            PrintWriter outToServer = new PrintWriter(clientSocket.getOutputStream(), true);

            //DataOutputStream outToServer = new DataOutputStream(clientSocket.getOutputStream());
            BufferedReader inFromServer = new BufferedReader(new InputStreamReader(clientSocket.getInputStream()));

            String req = "";

            // Envia a requisição
            req += "GET " + path + " " + HTTP_VERSION + "\n";
            req += "Host: " + this.host + "\n";
            req += "Connection: Close;";

            escritor("requisicaoEmTextoCA.txt", req);
            System.out.println("Inicio REQ + " + req.length());
            System.out.println(req);
            System.out.println("Fim REQ");
            //System.out.println("Pacote: \n\n" + req + "\n\n" + reqBin + "\n\n");
            outToServer.println(req);

            StringBuilder sb = new StringBuilder();
            // recupera a resposta quando ela estiver disponível
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
            return sb.toString();
        } finally {
            if (clientSocket != null) {
                clientSocket.close();
            }
        }
    }

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

    private static void escritor(String path, String dados) throws IOException {
        BufferedWriter buffWrite = new BufferedWriter(new FileWriter(path));
        buffWrite.append(dados + "\n");
        buffWrite.close();
    }

    public static void main(String[] args) {
        File f = new File("config");
        BufferedReader br;
        Scanner s = new Scanner(System.in);
        System.out.println("Digite o IP de destino:");
        //String ipDest = s.nextLine();
        String ipDest = "192.168.0.34";
        System.out.println("Digite a interface utilizada:");
        //String interf = s.nextLine();
        String interf = "wlan0";
        try {
            escritor("config", ipDest + "\n" + interf);
        } catch (IOException ex) {
            Logger.getLogger(HttpClient.class.getName()).log(Level.SEVERE, null, ex);
        }
        HttpClient client = new HttpClient(ipDest, 6768, "localhost");
        try {
            System.out.println("Digite o arquivo requerido:");
            System.out.println(client.getURIRawContent("/" + s.nextLine()));
        } catch (UnknownHostException e) {
            logger.log(Level.SEVERE, "Host desconhecido!", e);
        } catch (IOException e) {
            logger.log(Level.SEVERE, "Erro de entrada e saída!", e);
        }

    }

}
