require "readline"
require 'socket'

class Servidor
  def initialize(port)
    @port=port
		@server=TCPServer.open(port)
    @TMQ=1
	end

  def converteBinToHex(x)
		saida=""
    j = 0
    while j < x.size-1
      saida+=x[j..j+3].to_i(2).to_s(16)
      j+=4
    end
		return saida
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conectado"
        data = client.gets
        puts data

        #Aqui eh definido a divisao q sera feita na hora de enviar os quadros
        @TMQ = gets
        client.puts @TMQ

        client.gets
        dados = client.gets

        puts "\n\n"

        preambulo = dados[0..63]
        macDestino = converteBinToHex(dados[64..111])
        macOrigem = converteBinToHex(dados[112..159])
        type = dados[160..175].to_i(2)
        data = dados[176..dados.size-33]
        crc = converteBinToHex(dados[dados.size-32..dados.size-1])

        puts "Preambulo : #{preambulo}"
    		puts "Mac Destino : #{macDestino}"
    		puts "Mac Origem : #{macOrigem}"
    		puts "Type : #{type}"
    		puts "Pacote : #{data}"
    		puts "Crc : #{crc}"
        puts "\n\n"

        File.write("../pacote_recebido.txt", data)

      end
    }
  end
end
servidor = Servidor.new(20023)
servidor.executar
