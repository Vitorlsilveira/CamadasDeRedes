require "readline"
require 'socket'

class Servidor
  def initialize(port)
    @port=port
		@server=TCPServer.open(port)
    @sock1=nil
		while @sock1==nil
      begin
			@sock1 = TCPSocket.open("localhost",4444)
			rescue
				@sock1=nil
        sleep 1
			end
		end
    @TMQ=1
	end

  def converteBinToHex(x)
		saida=""
    j = 0
    while j < x.size-1
      #Aqui pegamos 4 bits e os convertemos para hex
      saida+=x[j..j+3].to_i(2).to_s(16)
      j+=4
    end
		return saida
	end

  def conectaTransporte(dados)
    #tenta conectar ate conseguir
		#puts "To esperando servidor de transporte ficar disponivel!"
    @sock1.puts dados;
    resposta = ""
    puts "Enviei para o servidor de transporte! Esperando resposta..."
    while line = @sock1.gets
      if line == "\r\n"
				break
			end
      resposta += line
    end
    return resposta
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conectado"
        while true
          mensagem = client.gets
          puts mensagem

          if mensagem[0..6] == "1110111"
            #Aqui definimos o TMQ
            @TMQ = gets
            client.puts @TMQ
            client.gets
            mensagem = client.gets
          end

          dados = mensagem

          puts "\n\n"

          preambulo = dados[0..63]
          macDestino = converteBinToHex(dados[64..111])
          macOrigem = converteBinToHex(dados[112..159])
          type = dados[160..175].to_i(2)
          data = dados[176..dados.size-34]
          crc = converteBinToHex(dados[dados.size-33..dados.size-1])

          puts "Preambulo : #{preambulo}"
      		puts "Mac Destino : #{macDestino}"
      		puts "Mac Origem : #{macOrigem}"
      		puts "Type : #{type}"
      		puts "Pacote : #{[data].pack("B*")}"
      		puts "Crc : #{crc}"
          puts "\n\n"

          File.write("quadro_recebido.txt", data)
          resposta = conectaTransporte([data].pack("B*"))
          puts "\nRESPOSTA =\n"
          puts resposta
          respostaBin = resposta.unpack('B*')
          puts "\n\n"
          puts respostaBin
          puts "\n\n"
          puts "Enviando para o cliente a resposta..."
          client.puts respostaBin
        end
        client.close
      end
    }
  end
end
servidor = Servidor.new(5554)
servidor.executar
