#client sends file to server
require 'socket'

host = '127.0.0.1'
port = 2000
sock = TCPSocket.open(host, port)

	file = open('/home/andre/Documentos/teste', "rb")
	fileContent = file.read
	sock.puts(fileContent)
	sock.close

#http://www.backtrack-linux.org/forums/showthread.php?t=22070
