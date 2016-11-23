require "readline"
require 'digest/crc32'
require 'socket'


class Cliente
	def initialize()
		file = File.open("Roteador/config", 'r')
		@server=TCPServer.open(2222)
		@port=2222
		#pega o IP do arquivo
		@origemIP = "localhost"
		#pega o IP do arquivo
		@destinoIP=file.gets
		@interface=file.gets
		@msg = ""
		@client=@server.accept
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

	def converteBinToHex(x)
		saida=""
    j = 0
    while j < x.size-1
      #Aqui pegamos 4 bits e os convertemos para hex
      saida+=x[j..j+3].to_i(2).to_s(16)
      j+=4
    end
		return saida
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


	def executar()
		puts "Aguardando PDU da camada superior"

		#Lendo dados da camada de cima
		dados = ""
		puts "Ouvindo do cliente de rede na porta #{@port}"
		# espera pela conexão do cliente da camada de aplicação


		while true
			puts "Aguardando pacote"
			dados = ""
			dados=@client.recv(65536)
			puts dados;

			pacote =dados.unpack("B*")[0].to_s
			conectaServidor()
	#		if @msg.include?"1110111"
	#			tmq = pedirTMQ()
	#			@client.puts tmq
	#			dados = client.gets
	#			pacote = dados.unpack("B*")[0].to_s
	#		end

			puts "Ip de origem: #{@origemIP}"
			puts "Ip do destinatario: #{@destinoIP}"
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
			@sock.puts quadro
			puts "Recebendo resposta do servidor .. .. .. .. .. \n\n"
			resp = @sock.gets
			preambulo = resp[0..63]
			macDestino = converteBinToHex(resp[64..111])
			macOrigem = converteBinToHex(resp[112..159])
			type = resp[160..175].to_i(2)
			data = resp[176..resp.size-34]
			crc = converteBinToHex(resp[resp.size-33..resp.size-1])
			puts "Enviando para transporte"
			puts [data].pack('B*')
			@client.write [data].pack('B*')+"\n"
		end
		@client.close
	end
end

c=Cliente.new
c.executar()
