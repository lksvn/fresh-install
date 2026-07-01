#!/bin/sh

echo "This script requires root permission to modify the system"
sudo echo ""

echo "Hotfix to disable keyboard commands for Apple keyboards"
echo "options hid_apple fnmode=0" | sudo tee -a /etc/modprobe.d/hid_apple.conf

echo #blank line
echo #blank line

# Update the system
echo "Updating the system"
sudo apt update -y
sudo apt upgrade -y

echo #blank line
echo #blank line

# Install apt packages
echo "Installing applications via APT"
echo "CURL | WGET | GPG | BUILD ESSENTIALS | FLATPAK | GIT | DOCKER | DOCKER COMPOSER | zSH | POEDIT | MYSQL CLIENT | POSTGRESQL CLIENT | PHP CLIENT | PHP-XML | HTOP | NEOFETCH"
sudo apt install -y curl wget gpg build-essential flatpak git docker.io docker-compose zsh poedit mysql-client postgresql-client htop neofetch php-cli php-xml

echo #blank line
echo #blank line

# NodeSource repository
echo "Adding NodeSource repository"
curl -fsSL https://deb.nodesource.com/setup_23.x -o nodesource_setup.sh
sudo -E bash nodesource_setup.sh
# Install NodeJS
echo "Installing - NodeJS"
sudo apt-get install -y nodejs
# Install NPM
echo "Installing - NPM"
sudo npm install -g npm
# Install NPM Version Manager
echo "Installing - NPM Version Manager"
sudo npm install -g n

echo #blank line
echo #blank line

#Microsoft repository
echo "Adding Microsoft repository"
wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
sudo sh -c 'echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list'
rm -f packages.microsoft.gpg
echo "Installing - Visual Studio Code"
sudo apt install apt-transport-https
sudo apt update
sudo apt install code

echo #blank line
echo #blank line

#Flatpak repository
echo "Adding Flatpak repository"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
# Flatpak packages
echo "Installing Flatpak packages"
#echo "Installing - Google Chrome"
#flatpak install -y flathub com.google.Chrome # Google Chrome
echo "Installing - Slack"
flatpak install -y flathub com.slack.Slack # Slack
echo "Installing - DBeaver"
flatpak install -y flathub io.dbeaver.DBeaverCommunity # Dbeaver
echo "Installing - PostMan"
flatpak install -y flathub com.getpostman.Postman # Postman
echo "Installing - Docker GUI"
flatpak install -y flathub com.github.sdv43.whaler # Docker GUI
echo "Installing - Flat Seal"
flatpak install -y flathub com.github.tchx84.Flatseal # Flat Seal - Flatpak Permission Manager
echo "Installing - Obsidian"
flatpak install -y flathub md.obsidian.Obsidian # Obsidian - Notes
#flatpak install flathub org.gnome.DejaDup #Backup manager
echo "Checking for package updates"
sudo flatpak update

echo #blank line
echo #blank line

#MongoDB Compass
echo "Downloading - MongoDB Compass"
wget https://downloads.mongodb.com/compass/mongodb-compass_1.44.5_amd64.deb
echo "Installing - MongoDB Compass"
sudo apt install ./mongodb-compass_1.44.5_amd64.deb
echo "Removing file"
rm ./mongodb-compass_1.44.5_amd64.deb

echo #blank line
echo #blank line

# Brave Browser
echo "Adding Brave repository"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources https://brave-browser-apt-release.s3.brave.com/brave-browser.sources
sudo apt update
sudo apt install brave-browser

echo #blank line
echo #blank line

# Syncthing
echo "Adding Syncthing repository"
sudo mkdir -p /etc/apt/keyrings
sudo curl -L -o /etc/apt/keyrings/syncthing-archive-keyring.gpg https://syncthing.net/release-key.gpg
echo "deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2" | sudo tee /etc/apt/sources.list.d/syncthing.list
printf "Package: *\nPin: origin apt.syncthing.net\nPin-Priority: 990\n" | sudo tee /etc/apt/preferences.d/syncthing.pref
echo "Installing - Syncthing"
sudo apt-get update
sudo apt-get install -y syncthing

echo #blank line
echo #blank line

# Snap packages
echo "Installing Snapcraft packages"
echo "Installing - MySQL Workbench Community"
sudo snap install mysql-workbench-community
echo "Checking for package updates"
sudo snap refresh

echo #blank line
echo #blank line

# Permission groups
echo "Configuring permission groups"
sudo usermod -G docker -a $USER

# SSH key generation
echo "Setting up SSH key"
if [ ! -e "$HOME/.ssh/id_ed25519" ]; then
	mkdir -p "$HOME/.ssh"
	ssh-keygen -t ed25519 -C "$(whoami)@$(hostname)-fresh-install" -N "" -f "$HOME/.ssh/id_ed25519"
	eval "$(ssh-agent -s)"
	ssh-add "$HOME/.ssh/id_ed25519"
else
	echo "SSH key already exists, skipping generation."
fi

echo #blank line
echo #blank line

# Install OhMyZSH
echo "Changing default shell to OhMyZSH"
sudo usermod -s $(which zsh) $USER
#sudo chsh -s $(which zsh) $USER
echo "Installing OhMyZSH"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
sudo omz theme set sonicradish
#Additional plugins for OhMyZSH
echo "Adding plugins to OhMyZSH config"
#echo "nano ~/.zshrc"
echo "GIT | DOCKER | DOCKER COMPOSER | HISTORY"
echo "plugins=(git docker docker-compose history)" | sudo tee -a ~/.zshrc

echo #blank line
echo #blank line

#Project directory
echo "Creating project directory"
mkdir $HOME/www

echo #blank line
echo #blank line

#Creates a Docker subnet
echo "Creating Docker subnet"
sudo docker network create --subnet 172.18.0.0/16 devnet
#Containers
echo "Creating Docker containers"
echo "Container - PHP 7"
sudo docker run --network devnet --ip 172.18.0.10 -td --name php7 -p 80:80 -v $HOME/www:/www lhuggler/php7-xdebug
echo "Container - MySQL 5.7"
sudo docker run --network devnet --ip 172.18.0.20 -d --name mysql57 -p 3606:3606 -e MYSQL_ROOT_PASSWORD=segredo mysql:5.7 --sql-mode=""
echo "Container - MongoDB"
sudo docker run --network devnet --ip 172.18.0.30 -d --name mongo -p 27017:27017 mongo

echo #blank line
echo #blank line
echo "============================================"
echo "  FRESH INSTALL COMPLETE!"
echo "============================================"
echo #blank line
echo "Add this SSH public key to your GitHub:"
echo "  https://github.com/settings/ssh/new"
echo #blank line
cat "$HOME/.ssh/id_ed25519.pub"
echo #blank line
echo "============================================"
echo #blank line
echo #blank line

echo "System will reboot in 10s, press CTRL+C to cancel"
sleep 10
reboot 
