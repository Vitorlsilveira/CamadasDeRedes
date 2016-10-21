#!/bin/bash
gnome-terminal -e "java -jar CamadaAplicacao/Servidor/dist/Servidor.jar" &
gnome-terminal -e "ruby CamadaFisica/servidor.rb" &
gnome-terminal -e "ruby CamadaFisica/cliente.rb" &
gnome-terminal -e "java -jar CamadaAplicacao/Cliente/dist/Cliente.jar" &
