require "readline"
require 'socket'

class Servidor
  def initialize(port)
    @port=port
		@server=TCPServer.open(port)
    @division=1
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conectado"
        data = client.gets
        puts data

        #Aqui eh definido a divisao q sera feita na hora de enviar os quadros
        @division = gets
        client.puts @division

        dados = ""
        client.gets #Esse gets eh uma correcao de bug... nao sei pq mas a primeira parte sempre vem um 0
        while line = client.gets
          dados += line
        end
        puts "\n\n"
        puts dados
        puts "\n\n"

        File.write("teste_recebido.txt", dados)

      end
    }
  end
end
servidor = Servidor.new(20023)
servidor.executar
