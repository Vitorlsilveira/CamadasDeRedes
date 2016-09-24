require "readline"
require 'socket'

class Servidor
  def initialize(port)
    @port=port
		@server=TCPServer.open(port)
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      puts "Waiting..."
      Thread.start(@server.accept) do |client|
        data = client.read
        puts data
        client.puts 10
      end
    }
  end
end
servidor = Servidor.new(20023)
servidor.executar
