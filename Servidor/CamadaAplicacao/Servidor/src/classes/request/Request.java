package classes.request;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.StringReader;

/**
 * Realiza o parse da requisiçao recebida
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

	//realiza o parse da requisiçao recebida
	public void parse(String input) throws IOException {
		BufferedReader br = new BufferedReader(new StringReader(input));
		String line = null;
                line = br.readLine();
                if(line != null){
                    //divide string com base no espaço em branco
                    String[] values = line.split(" ");
                    if (values.length == 3) { 
                        //captura o metodo,a url e o protocolo
			this.method = values[0];
			this.uri = values[1];
                        this.protocol = values[2];
                    }  
                }
	}

	//retorna o method
	public String getMethod() {
		return method;
	}

	//retorna a uri
	public String getUri() {
		return uri;
	}

	//retorna o protocolo
	public String getProtocol() {
		return protocol;
	}

}