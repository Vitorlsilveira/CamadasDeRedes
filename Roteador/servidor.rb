require "readline"
require 'socket'
require 'digest/crc32'

class Servidor
  def initialize(port)
    @port=port
    #servidor aguarda conexao na porta port
		@server=TCPServer.open(port)
    @sock1=nil
    #loop para aguardar a camada de fisica ficar disponivel
    puts "Aguardando camada de rede do roteador ficar disponivel na porta 1111"
		while @sock1==nil
      begin
			@sock1 = TCPSocket.open("localhost",1111)
      puts "Conectado a camada de rede do roteador"
			rescue
				@sock1=nil
        sleep 1
			end
		end
    @TMQ=1
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
		return saida
	end

  def conectaFisica(dados)
    #envia pacote para a camada de rede roteador
    @sock1.write dados+"\n";
    puts "\nQuadro enviado para a camada de rede do roteador: #{dados}"
    resposta = ""
    #recebe resposta da camada de rede do roteador
    resposta=@sock1.recv(65536)
    return resposta
	end

  def executar
    puts "Aguardando conexoes da camada fisica na porta #{@port}"
    #loop para aguardar conexoes com clientes
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conexao da camada fisica aceita"
        while true
          #recebe do roteador
          mensagem = client.gets
          if mensagem[0..6] == "1110111"
            #Aqui definimos o TMQ
            @TMQ = gets
            client.puts @TMQ
            client.gets
            mensagem = client.gets
          end

          dados = mensagem
          puts "\nQuadro recebido da camada fisica: #{dados} "
          #separa o quadro recebido
          preambulo = dados[0..63]
          macDestino = converteBinToHex(dados[64..111])
          macOrigem = converteBinToHex(dados[112..159])
          type = dados[160..175].to_i(2)
          data = dados[176..dados.size-34]
          crc = converteBinToHex(dados[dados.size-33..dados.size-1])

          #imprime o quadro recebido
          puts "Preambulo : #{preambulo}"
      		puts "Mac Destino : #{macDestino}"
      		puts "Mac Origem : #{macOrigem}"
      		puts "Type : #{type}"
      		puts "Pacote : #{[data].pack("B*")}"
          puts "Pacote size = #{[data].pack("B*").size}"
      		puts "Crc : #{crc}"

          #escreve num arquivo os dados recebidos
          File.write("quadro_roteador_recebido", data)
          #envia para camada de fisica os dados e aguarda resposta
          resposta = conectaFisica([data].pack("B*"))
          #imprime a resposta da camada fisica
          puts "\nQuadro recebido da camada de rede do roteador: #{resposta}"
          #converte a resposta para binario
          respostaBin = resposta.unpack("B*")[0].to_s
          #imprime a resposta em binario
          puts "Resposta em binario:#{respostaBin}"

          #enviando resposta para o cliente fisico
          #troca o mac de origem com o mac de destino
          aux=macDestino
          macDestino=macOrigem
          macOrigem=aux

          #transforma os mac para binario
          macDestinoBinario=converteHexToBin(macDestino)
          macOrigemBinario=converteHexToBin(macOrigem)

          #usado para sincronizar o emissor ao clock do remetente
          preambulo = "1010101010101010101010101010101010101010101010101010101010101011"
          #tipo indica o protocolo da camada superior e deve ser formatado para binario
          #FALTA ARRUMAR
          type=  converteHexToBin("0800")
          #Checksum utilizado para deteccao de erros
          crc = converteHexToBin(Digest::CRC32.hexdigest("#{respostaBin}"))
          quadro = preambulo+macDestinoBinario+macOrigemBinario+type+respostaBin+crc
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
          puts "Dados: #{respostaBin}"
          #imprime CRC
          puts "CRC = #{crc}"
          #imprime o tamanho de cada item do cabeçalho da camada fisica
          puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
          puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
          puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
          puts "Tamanho do type : #{type.size.to_f/8}"
          puts "Tamanho do pacote : #{respostaBin.size.to_f/8}"
          puts "Tamanho do crc : #{crc.size.to_f/8}"
          puts "Tamanho do quadro : #{quadro.size.to_f/8}"
          #escreve a resposta num arquivo de resposta
          File.write("quadro_roteador_resposta.txt", quadro)
          #envia para a camada fisica
          client.puts quadro
        end
        client.close
      end
    }
  end
end
servidor = Servidor.new(5553)
servidor.executar
