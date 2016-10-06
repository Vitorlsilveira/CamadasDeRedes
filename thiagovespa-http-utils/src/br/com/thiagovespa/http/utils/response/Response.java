package br.com.thiagovespa.http.utils.response;


/**
 * Interface para criação de respostas
 * 
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 1.0
  */
public interface Response {
	/**
	 * Método que contém devolve a resposta
	 * @return resposta
	 */
	public abstract String respond();

}