require "readline"
require 'digest/crc32'
require 'socket'


class Cliente
	def initialize(interface)
		@interface=interface
		@server=TCPServer.open(7777)
		@port=7777
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

	def recebePDU()
		puts "Listening to port #{@port}"
		client = @server.accept    # Wait for a client to connect
	  data = client.gets
		puts data
	  client.close
		return data
	end

	def executar(arquivo)
		puts "Aguardando PDU da camada superior"

		#Lendo dados da camada de cima
		dados = []
		pacote = recebePDU()
		dados << pacote
		dados = dados.pack("B*")
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

		#pega o mac do destino
		macDestino = get_mac_address(destinoIP)
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
		crc = converteHexToBin(Digest::CRC32.hexdigest("#{arquivo}"))

		puts "Frame ethernet:\n"
		puts "#{preambulo}#{macDestinoBinario}#{macOrigemBinario}#{type}#{pacote}#{crc}"
		puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
		puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
		puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
		puts "Tamanho do type : #{type.size.to_f/8}"
		puts "Tamanho do pacote : #{pacote.size.to_f/8}"
		puts "Tamanho do crc : #{crc.size.to_f/8}"

		#pdu da camada fisica
		quadro = preambulo+macDestinoBinario+macOrigemBinario+type+pacote+crc
		puts "\nTamanho do quadro : #{quadro.size.to_f/8}"

		#tenta conectar ate conseguir
		puts "Aguardando servidor ficar disponivel!"

		sock = 0
		while sock==0
      begin
			sock = TCPSocket.open(destinoIP, destinoPorta)
			rescue
				sock=0
        sleep 1
			end
		end

		puts "Conectado ao servidor: #{destinoIP}"

		#Pergunta ao servidor qual sera o tamanho maximo do quadro
		sock.puts("Qual o tamanho maximo do quadro(TMQ) ?\000", 0)
		tamanhoQuadroBytes = sock.gets

		#Agora vamos enviar o quadro
		sock.write quadro;
	end

end


c=Cliente.new ("wlan0")
c.executar("../pacote.txt")
