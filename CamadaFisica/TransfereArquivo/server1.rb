#server receive a file from client
require 'socket'
server = TCPServer.open(2000)

loop {
  Thread.start(server.accept) do |client|
    #client.puts(Time.now.ctime)
	data = client.read
	destFile = File.open('/tmp/dowload1.rb', 'wb')
	destFile.print data
	destFile.close
end

}
#http://www.backtrack-linux.org/forums/showthread.php?t=22070
