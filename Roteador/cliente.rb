require "readline"
require 'digest/crc32'
require 'socket'


class Cliente
	def initialize()
		#le do arquivo config as configuraçoes necessarias para a camada fisica, como interface e ip de destino
		file = File.open("Roteador/config", 'r')
		#abre a porta 2222 do servidor para que algum cliente se conecte nele
		@server=TCPServer.open(2222)
		@port=2222
		@origemIP = "localhost"
		#pega o IP de destino e a interface utiliza pelo arquivo config
		@destinoIP=file.gets
		@interface=file.gets
		#variaveis que serao usadas para armazenar quadro e o socket cliente(que aguarda conexao de um cliente)
		@msg = ""
		puts "Aguardando conexoes da camada de rede do roteador na porta 2222"
		@client=@server.accept
		puts "Conexao da camada de rede do roteador aceita"
		@origemPorta = ""
		@destinoPorta = ""
	end

	#funcao que retorna o mac address do destino, usa shell (arp)
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

	#funcao que retorna o mac address da maquina de origem
	def getMyMacAddress
	begin
		#no arquivo localizado em /sys/class/net/interface/address temos uma linha com o mac de acordo com a interface utilizada
		caminho="/sys/class/net/#{@interface}/address"
		mac = File.open(caminho,'r').gets
		rescue
			mac = "00:00:00:00:00:00"
		end
	return mac
	end

	#funcao que converte de binario para hexadecimal
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

	#funcao que converte de hexadecimal para binario
	def converteHexToBin(x)
		saida=""
		for i in 0..(x.size-1)
			saida+=x[i].hex.to_s(2).rjust(x[i].size*4, '0')
		end
		puts saida
		return saida
	end

	#funcao que estabelece conexao com a camada fisica
	def conectaServidor()
		#tenta conectar ate conseguir
		puts "Aguardando camada fisica ficar disponivel na porta 5554"
		@sock = 0
		#loop para aguardar a camada fisica ficar disponivel
		while @sock==0
      begin
			#tenta abrir conexao com a camada fisica
			@sock = TCPSocket.open(@destinoIP, 5554)
			rescue
				@sock=0
        sleep 1
			end
		end
	  #ja está conectado a camada fisica
		puts "Conectado a camada fisica"
	end

	#funcao que pede o TMQ ao servidor da camada fisica
	#FALTA ARRUMAR
	def pedirTMQ()
		#pergunta ao servidor qual sera o tamanho maximo do quadro
		#@sock.puts("Qual o tamanho maximo do quadro(TMQ) ?\000", 0)
		@sock.puts "1110111"
		tamanhoQuadroBytes = @sock.gets
		puts "TMQ = #{tamanhoQuadroBytes}"
		return tamanhoQuadroBytes
	end


	def executar()
		dados = ""

		# espera pela conexao da camada de rede do roteador
		while true
			dados = ""
			#recebe quadro
			dados=@client.recv(65536)
			#imprime o quadro
			puts "\nQuadro recebido da camada de rede do roteador: #{dados}"

			#desconverte de binario
			pacote =dados.unpack("B*")[0].to_s
			#le do arquivo nexthop o ip do roteador
			@destinoIP=	File.open("Roteador/nexthop", 'r').gets.chomp
			conectaServidor()

			#pega o mac do destino
			macDestino = get_mac_address(@destinoIP)
			#pega o mac do remetente de acordo com a interface usada
			macOrigem = getMyMacAddress

	   	#Formata os MAC address retirando o dois pontos
			macDestino = macDestino.gsub(":","").delete("\n")
			macOrigem = macOrigem.gsub(":","").delete("\n")

			#transforma os mac para binario
			macDestinoBinario=converteHexToBin(macDestino)
			macOrigemBinario=converteHexToBin(macOrigem)

	   	#usado para sincronizar o emissor ao clock do remetente
			preambulo = "1010101010101010101010101010101010101010101010101010101010101011"
	   	#tipo indica o protocolo da camada superior e deve ser formatado para binario
			#FALTA ARRUMAR AQUI, O TIPO TEM QUE SER O PROTOCOLO DA CAMADA SUPERIOR
			type=  converteHexToBin("0800")
	    #checksum utilizado para deteccao de erros
			crc = converteHexToBin(Digest::CRC32.hexdigest("#{pacote}"))

			#imprime o frame ethernet (Quadro)
			quadro = preambulo+macDestinoBinario+macOrigemBinario+type+pacote+crc
			puts "\nQuadro enviado para a camada fisica: #{quadro}"
			#imprime preambulo
			puts "Pre ambulo: #{preambulo}"
			#imprime o MAC de origem e o MAC de destino em hexadecimal
			puts "Mac do remetente: #{macOrigem}"
			puts "Mac do destinatario: #{macDestino}"
			#imprime os MAC em binario
			puts "Mac do destinatario em binario: #{macDestinoBinario}"
			puts "Mac do remetente em binario: #{macOrigemBinario}"
			#imprime type
			puts "Type: #{type}"
			#imprime dados
			puts "Dados: #{pacote}"
			#imprime CRC
			puts "CRC = #{crc}"
			#imprime o tamanho de cada item do cabeçalho da camada fisica
			puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
			puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
			puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
			puts "Tamanho do type : #{type.size.to_f/8}"
			puts "Tamanho do pacote : #{pacote.size.to_f/8}"
			puts "Tamanho do crc : #{crc.size.to_f/8}"
			puts "Tamanho do quadro : #{quadro.size.to_f/8}"

			#escreve em um arquivo o quadro ethernet
			File.write("quadro_roteador.txt", quadro)
			#Agora vamos enviar o quadro para a camada fisica
			@sock.puts quadro
			#recebe resposta da camada fisica
			resp = @sock.gets
			puts "\nQuadro recebido da camada fisica: #{resp} "
			#separa o quadro recebido
			preambulo = resp[0..63]
			macDestino = converteBinToHex(resp[64..111])
			macOrigem = converteBinToHex(resp[112..159])
			type = resp[160..175].to_i(2)
			data = resp[176..resp.size-34]
			crc = converteBinToHex(resp[resp.size-33..resp.size-1])
			#imprime o quadro recebido
			puts "Preambulo : #{preambulo}"
			puts "Mac Destino : #{macDestino}"
			puts "Mac Origem : #{macOrigem}"
			puts "Type : #{type}"
			puts "Pacote : #{[data].pack("B*")}"
			puts "Tamanho do pacote = #{[data].pack("B*").size}"
			puts "Crc : #{crc}"
			#escreve num arquivo os dados recebidos
			File.write("quadro_roteador_resposta_recebido.txt", data)
			#envia para a camada de rede do roteador os dados recebidos
			puts "\nQuadro enviado para a camada de rede do roteador: #{[data].pack('B*')}"
			@client.write [data].pack('B*')+"\n"
		end
		@client.close
	end
end

c=Cliente.new
c.executar()
