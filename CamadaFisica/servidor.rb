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



      end
    }
  end
end
servidor = Servidor.new(20023)
servidor.executar
