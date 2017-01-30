echo "Checando requisitos";
cd CamadaFisica;
if ! gem list digest-crc -i &>/dev/null; then echo "Installing digest-crc" && sudo gem install digest-crc; fi
if ! gem list gibberish -i &>/dev/null; then echo "Installing gibberish" && sudo gem install gibberish; fi

cd ..
cd CamadaRede;
if [ $(dpkg-query -W -f='${Status}' python-pip 2>/dev/null | grep -c "ok installed") -eq 0 ];
then
  sudo apt-get install python-pip;
fi
if [ $(pip search crc16 2>/dev/null | grep -c "INSTALLED") -eq 0 ];
then
  sudo pip install crc16;
fi

cd ..
cd CamadaAplicacao/Cliente;
if [ ! -d "dist" ]; then
	mkdir build &>/dev/null
	mkdir dist &>/dev/null
	javac src/**/*.java -d build/ &>/dev/null
	cd build
	jar -cfe ../dist/Cliente.jar cliente.HttpClient  **/*.class
	cd ..
fi
