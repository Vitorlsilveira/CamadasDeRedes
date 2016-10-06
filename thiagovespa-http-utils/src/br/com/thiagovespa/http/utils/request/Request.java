package br.com.thiagovespa.http.utils.request;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;

/**
 * Realiza o parse da requisição recebida
 * 
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 0.2
 */
public class Request {

	private String method;
	private String uri;
	private String protocol;

	public Request() {
	}

	/**
	 * Realiza o parse
	 * 
	 * @param input
	 * @return
	 * @throws IOException
	 */
	public void parse(String input) throws IOException {
		BufferedReader br = new BufferedReader(new StringReader(input));
		String line = null;
		int lineNumber = 0;
		while ((line = br.readLine()) != null) {
			System.out.println(lineNumber + " " + line);
			if (lineNumber == 0) {
				String[] values = line.split(" ");
				if (values.length == 3) { 
					this.method = values[0];
					this.uri = values[1];
					this.protocol = values[2];
				}// TODO Tratar erro
			} else {
				// TODO Recuperar os cabeçalhos e corpo
			}
			lineNumber++;

		}
	}

	/**
	 * Recupera o método
	 * 
	 * @return metodo TODO: Converter para Enum
	 */
	public String getMethod() {
		return method;
	}

	/**
	 * Recupera a URI
	 * 
	 * @return uri
	 */
	public String getUri() {
		return uri;
	}

	/**
	 * Recupera o protocolo
	 * 
	 * @return TODO: Fazer validação
	 */
	public String getProtocol() {
		return protocol;
	}

}