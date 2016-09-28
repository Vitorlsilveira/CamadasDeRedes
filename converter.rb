require "readline"

s = File.open("pacote", "r")
sout = File.open("pacote.txt", "w");

pac = s.read
pacBin = pac.unpack('b*')
puts pacBin

sout.write(pacBin[0])
