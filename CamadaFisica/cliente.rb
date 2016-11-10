require "readline"
require 'digest/crc32'
require 'socket'


class Cliente
	def initialize(interface)
		@interface=interface
		@server=TCPServer.open(7777)
		@port=7777
		#pega o IP do arquivo
		@origemIP = "localhost"
		#pega o IP do arquivo
		@destinoIP = "localhost"
		@msg = ""
		@origemPorta = ""
		@destinoPorta = ""
	end

	def get_mac_address(ip)
		begin
			response = `sh mac.sh #{ip} #{@interface}`
			mac = response.split()[3]
			if mac.size < 17
				raise "MAC nao encontrado"
			end
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
		for i in 0..(x.size-1)
			saida+=x[i].hex.to_s(2).rjust(x[i].size*4, '0')
		end
		puts saida
		return saida
	end

	def conectaServidor()
		#tenta conectar ate conseguir
		puts "Aguardando servidor ficar disponivel na porta 5554!"
		@sock = 0
		while @sock==0
      begin
			@sock = TCPSocket.open(@destinoIP, 5554)
			rescue
				@sock=0
        sleep 1
			end
		end
		puts "Conectado ao servidor: #{@destinoIP}"
	end

	def pedirTMQ()
		#pergunta ao servidor qual sera o tamanho maximo do quadro
		#@sock.puts("Qual o tamanho maximo do quadro(TMQ) ?\000", 0)
		@sock.puts "1110111"
		tamanhoQuadroBytes = @sock.gets
		puts "TMQ = #{tamanhoQuadroBytes}"
		return tamanhoQuadroBytes
	end

	def lerPacote(dados)
		pacote = dados.unpack("B*")[0]
		pacote = pacote.to_s
		puts pacote
		puts "DADOSSSSS\n"
		puts dados

		#pega a porta do arquivo
		#origemPorta = dados.split(";")[2].to_i
		@origemPorta = dados[0..1].unpack("S")[0]
		#pega a porta do arquivo
		#destinoPorta = dados.split(";")[3].to_i
		@destinoPorta = dados[2..3].unpack("S")[0]

		#conteudo
		@msg = dados[4..dados.size-1]
		puts "MENSAGEM\n"
		puts @msg
		return pacote
	end

	def executar()
		puts "Aguardando PDU da camada superior"

		#Lendo dados da camada de cima
		dados = ""
		puts "Ouvindo do cliente de transporte na porta #{@port}"
		# espera pela conexão do cliente da camada de aplicação
		client = @server.accept
		while true
			puts "Aguardando pacote"
			dados = ""
			while line = client.gets
				if line == "\n"
					break
				end
				dados += line
				puts dados
			end
			puts dados;

			pacote = lerPacote(dados)
			conectaServidor()
			if @msg.include?"1110111"
				tmq = pedirTMQ()
				client.puts tmq
				dados = client.gets
				pacote = lerPacote(dados)
			end

			puts "Ip de origem: #{@origemIP}"
			puts "Ip do destinatario: #{@destinoIP}"
			puts "Porta origem: #{@origemPorta}"
			puts "Porta destino: #{@destinoPorta}"
			puts "Dados: \n#{@msg}\n"

			#pega o mac do destino
			macDestino = get_mac_address(@destinoIP)
			#pega o mac do remetente de acordo com a interface usada
			macOrigem = getMyMacAddress

			puts "Mac do destinatario: #{macDestino}"
			puts "Mac do remetente: #{macOrigem}"

	   	#Formata os MAC address retirando o dois pontos
			macDestino = macDestino.gsub(":","").delete("\n")
			macOrigem = macOrigem.gsub(":","").delete("\n")

			#transforma os mac para binario
			macDestinoBinario=converteHexToBin(macDestino)
			macOrigemBinario=converteHexToBin(macOrigem)

			puts "Mac do destinatario em binario: #{macDestinoBinario}"
			puts "Mac do remetente em binario: #{macOrigemBinario}"

	   	#usado para sincronizar o emissor ao clock do remetente
			preambulo = "1010101010101010101010101010101010101010101010101010101010101011"
	   	#tipo indica o protocolo da camada superior e deve ser formatado para binario
			type=  converteHexToBin("0800")
	    #utilizado para deteccao de erros
			puts "\nCRC HEX ==  #{Digest::CRC32.hexdigest("#{pacote}")}\n"
			crc = converteHexToBin(Digest::CRC32.hexdigest("#{pacote}"))

			puts "Frame ethernet:\n"
			puts "#{preambulo}#{macDestinoBinario}#{macOrigemBinario}#{type}#{pacote}#{crc}"
			puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
			puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
			puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
			puts "Tamanho do type : #{type.size.to_f/8}"
			puts "Tamanho do pacote : #{pacote.size.to_f/8}"
			puts "Tamanho do crc : #{crc.size.to_f/8}"

			puts "CRC = #{crc}"

			#pdu da camada fisica
			quadro = preambulo+macDestinoBinario+macOrigemBinario+type+pacote+crc
			puts "\nTamanho do quadro : #{quadro.size.to_f/8}"

			File.write("quadro.txt", quadro)

			#Agora vamos enviar o quadro
			@sock.puts quadro;

			puts "Recebendo resposta do servidor .. .. .. .. .. \n\n"
			resp = @sock.gets
			puts "Enviando para transporte"

			puts [resp].pack('B*')
			client.puts [resp].pack('B*')
		end
		client.close
	end

end


c=Cliente.new ("wlan0")
c.executar()
