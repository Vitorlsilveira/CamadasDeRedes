package classes.response;

import classes.request.Request;
import java.io.IOException;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 *
 * @author mattar
 */
//cria a resposta a ser enviada para a camada de transporte a partir da requisição recebida e formatada
public class Response{

	private Request request;
        private String content;

	protected static final DateFormat HTTP_DATE_FORMAT = new SimpleDateFormat(
			"EEE, dd MMM yyyy HH:mm:ss z");

	public Response(Request request) {
		this.request = request;
	}

        //cria a resposta da requisição
	public String respond() {
		StringBuilder sb = new StringBuilder();
		// Cria primeira linha do status code, no caso sempre 200 OK
		sb.append("HTTP/1.1 200 OK").append("\r\n");
		
		// Cria os cabeçalhos
		sb.append("Date: ").append(HTTP_DATE_FORMAT.format(new Date()))
				.append("\r\n");
		sb.append("Server: Servidor dos Maneis")
				.append("\r\n");
		sb.append("Connection: Close").append("\r\n");
		sb.append("Content-Type: text/html; charset=UTF-8").append("\r\n");
		sb.append("\r\n");
		
                
                // Agora vem o corpo em HTML
                // Devemos carregar o arquivo desejado pelo cliente na resposta
                try {
                    // Esse .substring(1) serve para remover o / que acompanha o URI
                    this.content = readFile(request.getUri().substring(1), StandardCharsets.UTF_8);
                } catch (IOException ex) {
                    Logger.getLogger(Response.class.getName()).log(Level.SEVERE, null, ex);
                }
                //anexa o corpo html na resposta da requisicao
                sb.append(this.content);
		sb.append("\r\n");
		//retorna resposta da requisição recebida
		return sb.toString();

	}
        
        //le do arquivo os bytes e retorna uma string
        static String readFile(String path, Charset encoding) throws IOException {
            byte[] encoded = Files.readAllBytes(Paths.get(path));
            return new String(encoded, encoding);
        }
}
