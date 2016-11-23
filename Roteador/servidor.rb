require "readline"
require 'socket'
require 'digest/crc32'

class Servidor
  def initialize(port)
    @port=port
		@server=TCPServer.open(port)
    @sock1=nil
		while @sock1==nil
      begin
			@sock1 = TCPSocket.open("localhost",1111)
			rescue
				@sock1=nil
        sleep 1
			end
		end
    @TMQ=1
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
		return saida
	end

  def conectaTransporte(dados)
    #tenta conectar ate conseguir
		#puts "To esperando servidor de transporte ficar disponivel!"

    @sock1.write dados+"\n";
    resposta = ""
    puts "Enviei para o servidor de transporte! Esperando resposta..."
    resposta=@sock1.recv(65536)
    puts resposta
    return resposta
	end

  def executar
    puts "Listening to port #{@port}"
    loop {
      Thread.start(@server.accept) do |client|
        puts "Conectado"
        while true
          mensagem = client.gets
          puts mensagem

          if mensagem[0..6] == "1110111"
            #Aqui definimos o TMQ
            @TMQ = gets
            client.puts @TMQ
            client.gets
            mensagem = client.gets
          end

          dados = mensagem

          puts "\n\n"

          preambulo = dados[0..63]
          macDestino = converteBinToHex(dados[64..111])
          macOrigem = converteBinToHex(dados[112..159])
          type = dados[160..175].to_i(2)
          data = dados[176..dados.size-34]
          crc = converteBinToHex(dados[dados.size-33..dados.size-1])

          puts "Preambulo : #{preambulo}"
      		puts "Mac Destino : #{macDestino}"
      		puts "Mac Origem : #{macOrigem}"
      		puts "Type : #{type}"
      		puts "Pacote : #{[data].pack("B*")}"
          puts "Pacote size = #{[data].pack("B*").size}"
      		puts "Crc : #{crc}"
          puts "\n\n"

          File.write("quadro_recebido.txt", data)
          resposta = conectaTransporte([data].pack("B*"))
          puts "\nRESPOSTA - tam #{resposta.length} =\n"
          puts resposta
          respostaBin = resposta.unpack("B*")[0].to_s
          puts respostaBin
          puts "Enviando para o cliente a resposta..."

          aux=macDestino
          macDestino=macOrigem
          macOrigem=aux
          puts "Mac do remetente: #{macOrigem}"
          puts "Mac do destinatario: #{macDestino}"

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
          puts "\nCRC HEX ==  #{Digest::CRC32.hexdigest("#{respostaBin}")}\n"
          crc = converteHexToBin(Digest::CRC32.hexdigest("#{respostaBin}"))

          puts "Frame ethernet:\n"
          puts "#{preambulo}#{macDestinoBinario}#{macOrigemBinario}#{type}#{respostaBin}#{crc}"
          puts "Tamanho do preambulo : #{preambulo.size.to_f/8}"
          puts "Tamanho do macDestinoBinario : #{macDestinoBinario.size.to_f/8}"
          puts "Tamanho do macOrigemBinario : #{macOrigemBinario.size.to_f/8}"
          puts "Tamanho do type : #{type.size.to_f/8}"
          puts "Tamanho do pacote : #{respostaBin.size.to_f/8}"
          puts "Tamanho do crc : #{crc.size.to_f/8}"

          puts "CRC = #{crc}"

          #pdu da camada fisica
          quadro = preambulo+macDestinoBinario+macOrigemBinario+type+respostaBin+crc
          puts "\nTamanho do quadro : #{quadro.size.to_f/8}"
          File.write("quadroResposta.txt", quadro)
          client.puts quadro
        end
        client.close
      end
    }
  end
end
servidor = Servidor.new(5553)
servidor.executar
