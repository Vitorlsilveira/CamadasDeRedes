require "readline"
require 'digest/crc32'
require 'socket'
require "gibberish"

class Cliente
	def initialize()
		#le do arquivo config as configuraçoes necessarias para a camada fisica, como interface e ip de destino
		file = File.open("config", 'r')
		#abre a porta 9999 do servidor para que algum cliente se conecte nele
		@server=TCPServer.open(9999)
		@port=9999
		@origemIP = "localhost"
		#pega o IP de destino e a interface utiliza pelo arquivo config
		@destinoIP=file.gets
		@interface=file.gets
		#variaveis que serao usadas para armazenar quadro e o socket cliente(que aguarda conexao de um cliente)
		@msg = ""
		puts "Aguardando conexoes da camada de rede na porta 9999"
		@client=@server.accept
		puts "Conexao da camada de rede aceita"
		@origemPorta = ""
		@destinoPorta = ""
		@ipRoteador = ""
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
		caminho="/sys/class/net/#{@interface.chomp}/address"
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

	#funcao que estabelece conexao com o roteador
	def conectaServidor()
		#tenta conectar ate conseguir
		puts "Aguardando roteador ficar disponivel na porta 5553!"
		@sock = 0
		#loop para aguardar o roteador ficar disponivel
		while @sock==0
      begin
			#tenta abrir conexao com o roteador
			@sock = TCPSocket.open(@ipRoteador, 5553)
			rescue
				@sock=0
        sleep 1
			end
		end
		#ja está conectado ao servidor do roteador
		puts "Conectado a camada fisica do roteador"
	end

	def executar()
		#Lendo dados da camada de REDE
		dados = ""
		# espera pela conexao do cliente da camada de rede
		while true
			# "Aguardando pacote"
			dados = ""
			#recebe pacote
			dados=@client.recv(65536)
			#imprime o pacote
			puts "\nPacote recebido da camada de rede: #{dados}"

			#desconverte de binario
			pacote =dados.unpack("B*")[0].to_s
			#le o arquivo da camada de rede para que o quadro seja encaminhado ao roteador(cliente fisica,roteador,servidor fisico)certo
			@ipRoteador=File.open("CamadaRede/nexthopCliente", 'r').gets.chomp
			conectaServidor()

			#pega o mac do destino
			macDestino = get_mac_address(@ipRoteador)
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
			type=  converteHexToBin("0800")
	    #checksum utilizado para deteccao de erros
			crc = converteHexToBin(Digest::CRC32.hexdigest("#{pacote}"))

			#imprime o frame ethernet (Quadro)
			quadro = preambulo+macDestinoBinario+macOrigemBinario+type
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
			#imprime CRC
			puts "CRC = #{crc}"
			#imprime dados
			puts "Dados: #{pacote}"
			#imprime o tamanho de cada item do cabeçalho da camada fisica
			puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
			puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
			puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
			puts "Tamanho do type : #{type.size.to_f/8}"
			puts "Tamanho do crc : #{crc.size.to_f/8}"
			puts "Tamanho do pacote : #{pacote.size.to_f/8}"
			puts "Tamanho do quadro : #{quadro.size.to_f/8}"

			#criptografa os dados
			arquivo = File.open("CamadaFisica/chaveCliente.txt",'r')
			chave = arquivo.gets.chomp
			criptografia = Gibberish::AES.new(chave)
			pacoteC = criptografia.encrypt(pacote)
			quadro= quadro + pacoteC + crc

			#escreve em um arquivo o quadro ethernet
			File.write("CamadaFisica/quadro.txt", quadro)

			#Agora vamos enviar o quadro para o roteador
			@sock.puts quadro

			#roteador tras a resposta do servidor
			resp = @sock.gets
			puts "\nQuadro recebido da camada fisica do roteador: #{resp} "
			#separa o quadro recebido
			preambulo = resp[0..63]
			macDestino = converteBinToHex(resp[64..111])
			macOrigem = converteBinToHex(resp[112..159])
			type = resp[160..175].to_i(2)
			dadoCriptografado = resp[176..resp.size-34]
			crc = converteBinToHex(resp[resp.size-33..resp.size-1])

			#descriptografa a mensagem criptografada
			descriptografia = Gibberish::AES.new(chave)
			puts "Aguardando desencriptografia!"
			data = descriptografia.decrypt(dadoCriptografado)

			#imprime o quadro recebido
			puts "Preambulo : #{preambulo}"
			puts "Mac Destino : #{macDestino}"
			puts "Mac Origem : #{macOrigem}"
			puts "Type : #{type}"
			puts "Crc : #{crc}"
			puts "Pacote : #{[data].pack("B*")}"
			puts "Tamanho do pacote = #{[data].pack("B*").size}"

			#escreve num arquivo os dados recebidos
			File.write("CamadaFisica/quadro_resposta_recebido.txt", data)
			#envia para a camada de rede o pacote recebido
			puts "\nPacote enviado para a camada de rede: #{[data].pack('B*')}"
			@client.write [data].pack('B*')+"\n"
		end
		@client.close
	end
end

c=Cliente.new
c.executar()
