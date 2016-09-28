require "readline"
require 'digest/crc32'
require 'socket'

class Cliente
	def initialize(interface)
		@interface=interface
	end

	def get_mac_address(ip)
		begin
			response = `sh mac.sh #{ip} #{@interface}`
			mac = response.split()[3]
			if mac == "entries" then
				raise "Mac nao encontrado"
			end
		rescue
				mac = getMyMacAddress
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
		dados = []
		pacote = File.open("#{arquivo}", "r").read
		dados << pacote
		dados = dados.pack("b*")
		puts dados

		origem = dados.split(";")[0]
		destino = dados.split(";")[1]
		msg = dados.split(";")[2]

		#origem
		#pega o IP do arquivo
		origemIP = origem.split(":")[0]
		#pega a porta do arquivo
		origemPorta = origem.split(":")[1].to_i

		#destino
		#pega o IP do arquivo
		destinoIP = destino.split(":")[0]
		#pega a porta do arquivo
		destinoPorta = destino.split(":")[1].to_i

		#porta = dados.split(";")[1].to_i;

		puts "Ip do destinatario: #{destinoIP}"
		puts "Porta: #{destinoPorta}"
		puts "Dados: \n\n#{msg}\n\n"

		#PEGA O MAC do destino
		macDestino = get_mac_address(destinoIP)
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
		#puts "Type = #{type}"
    #utilizado para deteccao de erros
		crc = converteHexToBin(Digest::CRC32.hexdigest("#{arquivo}"))
		#puts "CRC = #{crc}"
		#checksum = "00000000000000000000000000000000"

		puts "Ta aqui o frame ethernet"
		puts "#{preambulo}#{macDestinoBinario}#{macOrigemBinario}#{type}#{pacote}#{crc}"
		puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
		puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
		puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
		puts "Tamanho do type : #{type.size.to_f/8}"
		puts "Tamanho do pacote : #{pacote.size.to_f/8}"
		puts "Tamanho do crc : #{crc.size.to_f/8}"

		quadro = preambulo+macDestinoBinario+macOrigemBinario+type+pacote+crc
		puts "\nTamanho do quadro : #{quadro.size.to_f/8}"

		#tenta conectar ate conseguir
		puts "Esperando servidor ficar disponivel"
    aux=0
		while aux!=1
      begin
			aux=1
			sock = TCPSocket.open(destinoIP, destinoPorta)
			rescue
				aux=0
        sleep 1
			end
		end

		puts "Conectado ao servidor: #{destinoIP}"

		#Pergunta ao servidor qual sera o tamanho do quadro
		sock.puts("E ai manel, qual eh o tamanho do quadro?\000", 0)
		tamanhoQuadroBytes = sock.gets



		#Agora que ja sabemos o tamanho basta enviar as partes
		enviarPorPartes(sock, quadro, tamanhoQuadroBytes.to_i)

	end

	def enviarPorPartes(sock, dados, tamanho)
		#Nesse bloco eh enviado o arquivo em pedacos para o servidor
		if tamanho > dados.size #Caso o tamanho exceder o tamanho do arquivo ai definimos um envio inteiro do mesmo
			tamanho = dados.size
		end
		quantos = (dados.size.to_f / tamanho).ceil
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
		puts "O tamanho do arquivo eh: #{dados.size.to_f/8} bytes \nForam enviados: #{quantos} quadros\n\n"

	end
end


c=Cliente.new ("wlan0")
#puts c.converteHexToBin ("3C124542124242")
#puts c.getMyMacAddress
c.executar("../pacote.txt")
