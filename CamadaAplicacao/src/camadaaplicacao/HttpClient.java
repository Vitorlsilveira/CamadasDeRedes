package camadaaplicacao;

import java.io.BufferedReader;
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

	/**
	 * Construtor do cliente HTTP
	 * @param host host para o cliente acessar
	 * @param port porta de acesso
	 */
	public HttpClient(String host, int port) {
		super();
		this.host = host;
		this.port = port;
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
			socket = new Socket(this.host, this.port);
			PrintWriter out = new PrintWriter(socket.getOutputStream(), true);
			BufferedReader in = new BufferedReader(new InputStreamReader(
					socket.getInputStream()));

			// Envia a requisição
			out.println("GET " + path + " " + HTTP_VERSION);
			out.println("Host: " + this.host);
			out.println("Connection: Close");
			out.println();

			boolean loop = true;
			StringBuffer sb = new StringBuffer();

			// recupera a resposta quando ela estiver disponível
			while (loop) {
				if (in.ready()) {
					int i = 0;
					while ((i = in.read()) != -1) {
						sb.append((char) i);
					}
					loop = false;
				}
			}
			return sb.toString();
		} finally {
			if (socket != null) {
				socket.close();
			}
		}
	}

	public static void main(String[] args) {
		HttpClient client = new HttpClient("www.thiagovespa.com.br", 80);
		try {
			System.out.println(client.getURIRawContent("/blog/"));
		} catch (UnknownHostException e) {
			logger.log(Level.SEVERE, "Host desconhecido!", e);
		} catch (IOException e) {
			logger.log(Level.SEVERE, "Erro de entrada e saída!", e);
		}

	}

}
