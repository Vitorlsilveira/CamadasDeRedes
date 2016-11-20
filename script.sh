#kill ports
fuser -k 7777/tcp
fuser -k 6768/tcp
fuser -k 5555/tcp
fuser -k 5554/tcp
fuser -k 4444/tcp
fuser -k 9999/tcp
fuser -k 3333/tcp

cp config ~/.config/terminator/config
terminator -l redes
