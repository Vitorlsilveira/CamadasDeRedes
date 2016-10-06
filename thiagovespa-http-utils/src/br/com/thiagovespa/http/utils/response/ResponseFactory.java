package br.com.thiagovespa.http.utils.response;

import br.com.thiagovespa.http.utils.request.Request;

/**
 * Fábrica de respostas
 * 
 * @author Thiago Galbiatti Vespa - <a
 *         href="mailto:thiago@thiagovespa.com.br">thiago@thiagovespa.com.br</a>
 * @version 0.1
 */
public class ResponseFactory {
	/**
	 * Retorna a resposta adequada ao request
	 * @param request request
	 * @return resposta de acordo com o request
	 */
	public static Response createResponse(Request request) {
		// TODO: Colocar outros tipos de response. Ex: FileResponse, DBResponse,
		// CacheResponse

		return new DummyResponse(request);
	}
}
