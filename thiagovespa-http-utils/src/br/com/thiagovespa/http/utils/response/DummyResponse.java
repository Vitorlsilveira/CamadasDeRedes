package br.com.thiagovespa.http.utils.response;

import java.text.DateFormat;
import java.text.SimpleDateFormat;
import java.util.Date;

import br.com.thiagovespa.http.utils.request.Request;

/**
 * Resposta utilizada para testes do servidor
 * 
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 1.0
 *
 */
public class DummyResponse implements Response {

	private Request request;

	protected static final DateFormat HTTP_DATE_FORMAT = new SimpleDateFormat(
			"EEE, dd MMM yyyy HH:mm:ss z");

	/**
	 * Construtor do Dummy Response
	 * @param request requisição para análise da resposta
	 */
	public DummyResponse(Request request) {
		this.request = request;
	}

	@Override
	public String respond() {
		StringBuilder sb = new StringBuilder();
		// Cria primeira linha do status code, no caso sempre 200 OK
		sb.append("HTTP/1.1 200 OK").append("\r\n");
		
		// Cria os cabeçalhos
		sb.append("Date: ").append(HTTP_DATE_FORMAT.format(new Date()))
				.append("\r\n");
		sb.append("Server: Test Server - http://www.thiagovespa.com.br")
				.append("\r\n");
		sb.append("Connection: Close").append("\r\n");
		sb.append("Content-Type: text/html; charset=UTF-8").append("\r\n");
		sb.append("\r\n");
		
		// Agora vem o corpo em HTML
		sb.append("<html><head><title>Dummy Response</title></head><body><h1>HttpServer Response</h1>");
		sb.append("Method: ").append(request.getMethod()).append("<br/>");
		sb.append("URI: ").append(request.getUri()).append("<br/>");
		sb.append("Protocol: ").append(request.getProtocol()).append("<br/>");
		sb.append("</body></html>");
		return sb.toString();

	}

}
