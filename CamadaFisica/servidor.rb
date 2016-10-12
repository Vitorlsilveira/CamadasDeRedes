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
      #Aqui pegamos 4 bits e os convertemos para hex
      saida+=x[j..j+3].to_i(2).to_s(16)
      j+=4
    end
		return saida
	end

  def enviaPDU(ip,porta,dados)
    #tenta conectar ate conseguir
		puts "To esperando servidor da aplicacao ficar disponivel!"
		sock1 = 0
		while sock1==0
      begin
			sock1 = TCPSocket.open(ip,porta)
			rescue
				sock1=0
        sleep 1
			end
		end
    sock1.write dados;
    puts "Enviei para o servidor da aplicacao!"
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conectado"
        data = client.gets
        puts data

        #Aqui definimos o TMQ
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
    		puts "Pacote : #{[data].pack("B*")}"
    		puts "Crc : #{crc}"
        puts "\n\n"

        File.write("quadro_recebido.txt", data)
        enviaPDU("localhost",6768,data)
      end
    }
  end
end
servidor = Servidor.new(6969)
servidor.executar
