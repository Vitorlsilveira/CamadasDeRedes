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

		#Lendo dados do arquivo
		dados = ""
		File.open("#{arquivo}", "r") do |f|
		  f.each_line do |line|
		    dados = dados + line
		  end
		end

		#pega o IP do arquivo
		ip = dados.split("\n")[0];
		#pega a porta do arquivo
		porta = dados.split("\n")[1].to_i;

		puts "Ip do destinatario: #{ip}"
		puts "Porta: #{porta}"
		puts "Dados: \n\n#{dados}\n\n"

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

		#Pergunta ao servidor qual sera o tamanho do quadro
		sock.puts("E ai manel, qual eh o tamanho do quadro?\000", 0)
		tamanhoQuadroBytes = sock.gets

		#Agora que ja sabemos o tamanho basta enviar as partes
		enviarPorPartes(sock, dados, tamanhoQuadroBytes.to_i)

	end

	def enviarPorPartes(sock, dados, tamanho)
		#Nesse bloco eh enviado o arquivo em pedacos para o servidor
		if tamanho > dados.size #Caso o tamanho exceder o tamanho do arquivo ai definimos um envio inteiro do mesmo
			tamanho = dados.size
		end
		quantos = (dados.size / tamanho).ceil
		inicio = 0
		fim = tamanho
		i = 0
		while i < quantos
			sock.write dados[inicio..fim]
			inicio = fim+1
			fim += tamanho
			i += 1
		end

		puts "\n\nManelzinho o tamanho do quadro em bytes eh: #{tamanho}"
		puts "O tamanho do arquivo eh: #{dados.size} bytes \nForam enviados: #{quantos} quadros\n\n"

	end
end


c=Cliente.new ("wlan0")
puts c.converteHexToBin ("3C124542124242")
puts c.getMyMacAddress
c.executar("teste.txt")
