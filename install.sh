#!/bin/sh

#Caminho para o arquivo de chaves SSH
KEYS=$1
#####################################

echo "Esse script requer permissão de root para modificar o sistema"
sudo echo ""

echo "Hotfix para desabilitar comandos no teclado para apple"
echo "options hid_apple fnmode=0" | sudo tee -a /etc/modprobe.d/hid_apple.conf

echo #blank line
echo #blank line

# Atualiza a base do sistema
echo "Atualizando o sistema"
sudo apt update -y
sudo apt upgrade -y

echo #blank line
echo #blank line

# Instala os pacotes apt
echo "Instalando aplicações via APT"
echo "CURL | WGET | GPG | BUILD ESSENTIALS | FLATPAK | GIT | DOCKER | DOCKER COMPOSER | zSH | POEDIT | MYSQL CLIENT | PHP CLIENT | PHP-XML | HTOP"
sudo apt install -y curl wget gpg build-essential flatpak git docker.io docker-compose zsh poedit mysql-client htop php-cli php-xml

echo #blank line
echo #blank line

#Repositório Microsoft
echo "Adicionando repositório Microsoft"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
echo "Instalando - Visual Studio Code"
sudo apt install apt-transport-https
sudo apt update
sudo apt install code

echo #blank line
echo #blank line

#Repositório flatpak
echo "Adicionando repositório Flatpak"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# Pacotes flatpak
echo "Instalandos os pacotes Flatpak"
#echo "Instalando - Google Chrome"
#flatpak install -y flathub com.google.Chrome # Google Chrome
echo "Instalando - Slack"
flatpak install -y flathub com.slack.Slack # Slack
echo "Instalando - DBeaver"
flatpak install -y flathub io.dbeaver.DBeaverCommunity # Dbeaver
echo "Instalando - PostMan"
flatpak install -y flathub com.getpostman.Postman # Postman
echo "Instalando - Docker GUI"
flatpak install -y flathub com.github.sdv43.whaler # Docker GUI
echo "Instalando - Flat Seal"
flatpak install -y flathub com.github.tchx84.Flatseal # Flat Seal - Gerenciador Permissões Flatpak
#flatpak install flathub org.gnome.DejaDup #Gerenciador de backup
echo "Buscando por atualizações nos pacotes"
sudo flatpak update

echo #blank line
echo #blank line

#MongoDB compass
echo "Baixando - MongoDB Compass"
wget https://downloads.mongodb.com/compass/mongodb-compass_1.44.5_amd64.deb
echo "Instalando - MongoDB Compass"
sudo apt install ./mongodb-compass_1.44.5_amd64.deb
echo "Removendo arquivo"
rm ./mongodb-compass_1.44.5_amd64.deb

echo #blank line
echo #blank line

# Pacotes snap
echo "Instalandos os pacotes Snapcraft"
echo "Instalando - MySQL Workbench Community"
sudo snap install mysql-workbench-community
echo "Instalando - Brave Browser"
sudo snap install brave
echo "Buscando por atualizações nos pacotes"
sudo snap refresh

echo #blank line
echo #blank line

# Grupos de permissões
echo "Configurando grupos de permissões"
sudo usermod -G docker -a $USER

if [ -e $KEYS ]; then
	echo "Recuperando chaves ssh"
	if [ ! -e $HOME/.ssh ]; then
		mkdir $HOME/.ssh
	fi
	unzip $KEYS -d $HOME/.ssh
else
	echo "O arquivo de chaves ssh não está presente."
fi

echo #blank line
echo #blank line

# Instala o OhMyZSH
echo "Alterando shell padrão para o OhMyZSH"
sudo usermod -s $(which zsh) $USER
#sudo chsh -s $(which zsh) $USER
echo "Instalando o OhMyZSH"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sudo omz theme set sonicradish
#Plugins adicionais para OhMyZSH
echo "Adicionando plugins a configuração do OhMyZSH"
#echo "nano ~/.zshrc"
echo "GIT | DOCKER | DOCKER COMPOSER | HISTORY"
echo "plugins=(git docker docker-compose history)" | sudo tee -a ~/.zshrc

echo #blank line
echo #blank line

#Diretório de projetos
echo "Criando diretório de projetos"
mkdir $HOME/www

echo #blank line
echo #blank line

#Cria uma subrede para o docker
echo "Criando subrede para o Docker"
sudo docker network create --subnet 172.18.0.0/16 devnet
#Containers
echo "Criando containers Docker"
echo "Container - PHP 7"
sudo docker run --network devnet --ip 172.18.0.10 -td --name php7 -p 80:80 -v $HOME/www:/www lhuggler/php7-xdebug
echo "Container - MySQL 5.7"
sudo docker run --network devnet --ip 172.18.0.20 -d --name mysql57 -p 3606:3606 -e MYSQL_ROOT_PASSWORD=segredo mysql:5.7 --sql-mode=""
echo "Container - MongoDB"
sudo docker run --network devnet --ip 172.18.0.30 -d --name mongo -p 27017:27017 mongo

echo #blank line
echo #blank line

echo "O sistema irá reiniciar em 10s, pressione CTRL+C para cancelar"
sleep 10
reboot 
