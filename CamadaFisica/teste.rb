require "readline"

class Cliente
	def initialize(interface)
		@interface=interface
	end

	#FALTA IMPLEMENTAR: botei só um default aqui
	def get_mac_address(ip)
			response = `sh mac.sh #{ip} #{@interface}`
			mac = response.split()[3]
	    #mac = "00:00:00:00:00:00"
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
		ip = d[0].split("\n")[0].delete("\n");

		#pega o dado do arquivo
		dado = ""
		for i in 0..d.size
			dado += d[i].to_s
		end

		puts "Ip do destinatario: #{ip}"
		puts "Dados: #{dado}"

		#FALTA PEGAR O MAC DO DESTINO
		macDestino = get_mac_address(ip)
		#PEGA O MAC do remetente de acordo com a interface usada
		macOrigem = getMyMacAddress

		puts "Mac do destinatario: #{macDestino}"
		puts "Mac do remetente: #{macOrigem}"

		macDestino = macDestino.gsub(":","")
		macOrigem = macOrigem.gsub(":","")

		#TRANSFORMA OS MAC ADDRESS PARA BINARIO
		macDestinoBinario=converteHexToBin(macDestino)
		macOrigemBinario=converteHexToBin(macOrigem)

		puts "Mac do destinatario em binario: #{macDestinoBinario}"
		puts "Mac do remetente em binario: #{macOrigemBinario}"

	end
end


c=Cliente.new ("wlan0")
puts c.converteHexToBin ("3C124542124242")
puts c.divideString("testandooo","2")
puts c.getMyMacAddress
c.executar("teste.txt")
