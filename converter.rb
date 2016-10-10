require "readline"

s = File.open("pacote", "r")
sout = File.open("pacote.txt", "w");

pac = s.read
pacBin = pac.unpack('B*')
puts pacBin

sout.write(pacBin[0])
