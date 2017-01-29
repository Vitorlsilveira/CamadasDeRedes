#kill ports
fuser -k 1111/tcp
fuser -k 2222/tcp
cp roteadorConfig ~/.config/terminator/config
terminator -l redes
