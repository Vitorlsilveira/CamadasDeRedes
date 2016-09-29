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
		macDestino = macDestino.gsub(":","").delete("\n")
		macOrigem = macOrigem.gsub(":","").delete("\n")

		#TRANSFORMA OS MAC ADDRESS PARA BINARIO
		macDestinoBinario=converteHexToBin(macDestino)
		macOrigemBinario=converteHexToBin(macOrigem)

		puts "Mac do destinatario em binario: #{macDestinoBinario}"
		puts "Mac do remetente em binario: #{macOrigemBinario}"

		#dados que compoem quadro ethernet
    #usado para sincronizar o emissor ao clock do remetente
		preambulo = "1010101010101010101010101010101010101010101010101010101010101011"
    #tipo indica o protocolo da camada superior, junto com o mac do destino e da origem formam o cabeçalho
		#esse tipo deve ser entao convertido para binario
		type=  2048.to_s(2)
    #utilizado para deteccao de erros
		crc = converteHexToBin(Digest::CRC32.hexdigest("#{arquivo}"))

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
		sock.flush
		tamanhoQuadroBytes = sock.gets


		#Agora vamos enviar o quadro
		sock.write quadro;

	end

end


c=Cliente.new ("eth0")
c.executar("../pacote.txt")
