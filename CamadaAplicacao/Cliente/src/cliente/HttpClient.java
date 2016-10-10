package cliente;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.PrintWriter;
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
	 * @param path caminho a ser feita a requisição
	 * @return resposta do protocolo HTTP
	 * @throws UnknownHostException quando não encontra o host
	 * @throws IOException quando há algum erro de comunicação
	 */
	public String getURIRawContent(String path) throws UnknownHostException,
			IOException {
		Socket socket = null;
		try {
			// Abre a conexão
                        Socket clientSocket = new Socket("localhost", 7777);
                        DataOutputStream outToServer = new DataOutputStream(clientSocket.getOutputStream());

                        String req = "";

			// Envia a requisição
                        req += this.myip + ":" + "7777" + ";" + this.host + ":" + "6969" + ";";
			req += "GET " + path + " " + HTTP_VERSION + "\n";
			req += "Host: " + this.host + "\n";
			req += "Connection: Close;";
                        
			req = toBinary(req, 8);
                        
                        System.out.println(req);
                        outToServer.writeBytes(req + "\n");
                        //out.println(req);
                        
                        System.out.println("GET " + path + " " + HTTP_VERSION);
			System.out.println("Host: " + this.host);
			System.out.println("Connection: Close");
			System.out.println();

			boolean loop = true;
			StringBuffer sb = new StringBuffer();

			// recupera a resposta quando ela estiver disponível
//			while (loop) {
//				if (in.ready()) {
//					int i = 0;
//					while ((i = in.read()) != -1) {
//						sb.append((char) i);
//					}
//					loop = false;
//				}
//			}
			return sb.toString();
		} finally {
			if (socket != null) {
				socket.close();
			}
		}
	}

        public static String toBinary(String str, int bits) {
            String result = "";
            String tmpStr;
            int tmpInt;
            char[] messChar = str.toCharArray();

            for (int i = 0; i < messChar.length; i++) {
                // Converte individualmente cada char para binario
                tmpStr = Integer.toBinaryString(messChar[i]);
                tmpInt = tmpStr.length();
                // Caso o tamanho for menor que 8 entao completamos o que falta com zeros a esquerda
                if(tmpInt != bits) {
                    tmpInt = bits - tmpInt;
                    if (tmpInt == bits) {
                        result += tmpStr;
                    } else if (tmpInt > 0) {
                        for (int j = 0; j < tmpInt; j++) {
                            result += "0";
                        }
                        result += tmpStr;
                    } else {
                        System.err.println("argument 'bits' is too small");
                    }
                } else {
                    result += tmpStr;
                }
            }

            return result;
        }

	public static void main(String[] args) {
		HttpClient client = new HttpClient("localhost", 6768, "192.168.0.34");
		try {
			System.out.println(client.getURIRawContent("/hello.html"));
		} catch (UnknownHostException e) {
			logger.log(Level.SEVERE, "Host desconhecido!", e);
		} catch (IOException e) {
			logger.log(Level.SEVERE, "Erro de entrada e saída!", e);
		}

	}

}
