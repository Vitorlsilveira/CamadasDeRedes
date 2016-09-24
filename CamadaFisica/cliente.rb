require "readline"
require 'socket'

class Cliente
	def initialize(interface)
		@interface=interface
	end

	def get_mac_address(ip)
	begin
			response = `sh mac.sh #{ip} #{@interface}`
			mac = response.split()[3]
		rescue
				mac = "00:00:00:00:00:00"
		end
	return mac
	end

	def getMyMacAddress
	begin
		caminho="/sys/class/net/#{@interface}/address"
		mac = File.open(caminho,'r').gets
		rescue
			mac = "00:00:00:00:00:00"
		end
	return mac
	end

	def converteHexToBin(x)
		saida=""
		for i in 0..x.size
			if x[i].to_s.upcase == "0"
				saida+="0000"
			elsif x[i].to_s.upcase == "1"
				saida+="0001"
			elsif x[i].to_s.upcase == "2"
				saida+="0010"
			elsif x[i].to_s.upcase == "3"
				saida+="0011"
			elsif x[i].to_s.upcase == "4"
				saida+="0100"
			elsif x[i].to_s.upcase == "5"
				saida+="0101"
			elsif x[i].to_s.upcase == "6"
				saida+="0110"
			elsif x[i].to_s.upcase == "7"
				saida+="0111"
			elsif x[i].to_s.upcase == "8"
				saida+="1000"
			elsif x[i].to_s.upcase == "9"
				saida+="1001"
			elsif x[i].to_s.upcase == "A"
				saida+="1010"
			elsif x[i].to_s.upcase == "B"
				saida+="1011"
			elsif x[i].to_s.upcase == "C"
				saida+="1100"
			elsif x[i].to_s.upcase == "D"
				saida+="1101"
			elsif x[i].to_s.upcase == "E"
				saida+="1110"
			elsif x[i].to_s.upcase == "F"
				saida+="1111"
			end
		end
		return saida
	end

	def divideString(string, length)
	    return string.scan(/.{1,#{length}}/)
	end

	def executar(arquivo)
		puts "Esperando pacote da camada de Rede"
		aux=0
		while aux!=1
			aux=1
			caminho="#{arquivo}"
			begin
			d = File.readlines(caminho)
			rescue
				aux=0
			end
		end

		while d.size == 0 do
			caminho="#{arquivo}"
			d = File.readlines(caminho)
		end

		#pega o IP do arquivo
		ip = d[0].split("\n")[0];
		#pega a porta do arquivo
		porta = d[1].split("\n")[0].to_i;

		#pega o dado do arquivo
		dado = ""
		for i in 0..d.size
			dado += d[i].to_s
		end

		puts "Ip do destinatario: #{ip}"
		puts "Dados: \n\n#{dado}\n\n"

		#PEGA O MAC do destino
		macDestino = get_mac_address(ip)
		#PEGA O MAC do remetente de acordo com a interface usada
		macOrigem = getMyMacAddress

		puts "Mac do destinatario: #{macDestino}"
		puts "Mac do remetente: #{macOrigem}"

    #Formata os MAC address retirando o dois pontos
		macDestino = macDestino.gsub(":","")
		macOrigem = macOrigem.gsub(":","")

		#TRANSFORMA OS MAC ADDRESS PARA BINARIO
		macDestinoBinario=converteHexToBin(macDestino)
		macOrigemBinario=converteHexToBin(macOrigem)

		puts "Mac do destinatario em binario: #{macDestinoBinario}"
		puts "Mac do remetente em binario: #{macOrigemBinario}"

    #Transforma dado/tipo em binario
		dadoBinario = dado.unpack('B*')

		#dados que compoem quadro ethernet
    #usado para sincronizar o emissor ao clock do remetente
		preambulo = "1010101010101010101010101010101010101010101010101010101010101011"
    #tipo indica o protocolo da camada superior , junto com o mac do destino e da origem formam o cabeçalho
		type=  34667.to_s(2)
		puts "Type = #{type}"
    #utilizado para deteccao de erros
		checksum = "00000000000000000000000000000000"

		puts "Ta aqui o frame ethernet"
		puts "#{preambulo}#{macDestinoBinario}#{macOrigemBinario}#{type}#{checksum}"

		#tenta conectar ate conseguir
		puts "Esperando servidor ficar disponivel"
		puts "#{ip}"
		puts "#{porta}"
    aux=0
		while aux!=1
      begin
			aux=1
			sock = TCPSocket.open(ip, porta)
			rescue
				aux=0
        sleep 1
			end
		end

		puts "Conectado ao servidor: #{ip}"

		#pergunta ao servidor qual sera o tamanho do quadro
		sock.puts("E ai manel, qual e' o tamanho do quadro?")
    #
		tamanhoQuadroBytes = sock.gets
		tmq = tamanhoQuadroBytes * 8

		puts "Manelzinho o tamanho do quadro em bytes e':#{tamanhoQuadroBytes}"


	end
end


c=Cliente.new ("wlan0")
puts c.converteHexToBin ("3C124542124242")
puts c.divideString("testandooo","2")
puts c.getMyMacAddress
c.executar("teste.txt")
