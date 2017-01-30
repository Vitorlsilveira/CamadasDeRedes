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
//cria a resposta a ser enviada para a camada de transporte a partir da requisiçao recebida e formatada
public class Response{

	private Request request;
        private String content;

	protected static final DateFormat HTTP_DATE_FORMAT = new SimpleDateFormat(
			"EEE, dd MMM yyyy HH:mm:ss z");

	public Response(Request request) {
		this.request = request;
	}

        //cria a resposta da requisiçao
	public String respond() {
                // Agora vem o corpo em HTML
                // Devemos carregar o arquivo desejado pelo cliente na resposta
                try {
                    // Esse .substring(1) serve para remover o / que acompanha o URI
                    this.content = readFile(request.getUri().substring(1), StandardCharsets.UTF_8);
                } catch (IOException ex) {
                    Logger.getLogger(Response.class.getName()).log(Level.SEVERE, null, ex);
                }
                
                StringBuilder sb = new StringBuilder();
                // Cria primeira linha do status code
                if(this.content == null) {
                    sb.append("HTTP/1.1 404 Not Found").append("\r\n");
                } else {
                    sb.append("HTTP/1.1 200 OK").append("\r\n");
                }
		// Cria os cabeçalhos
		sb.append("Date: ").append(HTTP_DATE_FORMAT.format(new Date()))
				.append("\r\n");
		sb.append("Server: Servidor dos Maneis")
				.append("\r\n");
		sb.append("Connection: Close").append("\r\n");
		sb.append("Content-Type: text/html; charset=UTF-8").append("\r\n");
		sb.append("\r\n");
                //anexa o corpo html na resposta da requisicao
                if(this.content == null) {
                    sb.append("< !DOCTYPE HTML>\n" +
                            "<html>\n" +
                            "  <head>\n" +
                            "    <meta charset=\"utf-8\"/>\n" +
                            "    <title>404 - this page does not exist</title>\n" +
                            "  </head>\n" +
                            "  <body>\n" +
                            "    <p>The page "+ request.getUri().substring(1) +" was not found</p>\n"+
                            "  </body>\n" +
                            "</html>");
                } else {
                    sb.append(this.content);
                }
		sb.append("\r\n");
		//retorna resposta da requisiçao recebida
		return sb.toString();

	}
        
        //le do arquivo os bytes e retorna uma string
        static String readFile(String path, Charset encoding) throws IOException {
            byte[] encoded = Files.readAllBytes(Paths.get(path));
            return new String(encoded, encoding);
        }
}
