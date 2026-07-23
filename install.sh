#!/usr/bin/env bash

set -Eeuo pipefail

NODE_MAJOR="${NODE_MAJOR:-24}"
COMPASS_VERSION="${COMPASS_VERSION:-1.49.11}"
REBOOT_AFTER_INSTALL="${REBOOT_AFTER_INSTALL:-0}"
INSTALL_LEGACY_STACK="${INSTALL_LEGACY_STACK:-0}"

log() { printf '\n==> %s\n' "$*"; }
die() { printf 'Error: %s\n' "$*" >&2; exit 1; }

[[ ${EUID} -ne 0 ]] || die "run this script as a regular user; it will request sudo when required"
command -v sudo >/dev/null || die "sudo is not installed"

source /etc/os-release
case ${ID:-} in
  ubuntu)
    BASE_CODENAME=${VERSION_CODENAME:-}
    ;;
  linuxmint)
    BASE_CODENAME=${UBUNTU_CODENAME:-}
    ;;
  *)
    die "unsupported distribution: ${PRETTY_NAME:-${ID:-unknown}} (use Ubuntu or Linux Mint)"
    ;;
esac
[[ -n $BASE_CODENAME ]] || die "could not identify the underlying Ubuntu release"

TARGET_USER=$USER
TARGET_HOME=$HOME
ARCH=$(dpkg --print-architecture)
[[ $ARCH == "amd64" ]] || die "this legacy stack (MySQL 5.7 and Compass) requires amd64"

sudo -v

log "Updating the system"
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  apt-transport-https build-essential ca-certificates composer curl flatpak git \
  gnupg htop jq mysql-client openssh-client openssl php-cli \
  php-curl php-intl php-mbstring php-mysql php-sqlite3 php-xml php-zip poedit \
  postgresql-client ripgrep shellcheck tree unzip wget zip zsh

log "Configuring the Apple keyboard fix when applicable"
if [[ -d /sys/module/hid_apple ]]; then
  printf '%s\n' 'options hid_apple fnmode=0' | sudo tee /etc/modprobe.d/hid_apple.conf >/dev/null
fi

log "Installing Node.js ${NODE_MAJOR} LTS"
curl -fsSL "https://deb.nodesource.com/setup_${NODE_MAJOR}.x" -o /tmp/nodesource_setup.sh
sudo -E bash /tmp/nodesource_setup.sh
rm -f /tmp/nodesource_setup.sh
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs

log "Installing Docker Engine and Docker Compose"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $BASE_CODENAME
Components: stable
Architectures: $ARCH
Signed-By: /etc/apt/keyrings/docker.asc
EOF
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$TARGET_USER"
sudo systemctl enable --now docker

log "Installing Visual Studio Code"
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | \
  sudo tee /etc/apt/keyrings/packages.microsoft.gpg >/dev/null
sudo chmod a+r /etc/apt/keyrings/packages.microsoft.gpg
sudo tee /etc/apt/sources.list.d/vscode.sources >/dev/null <<EOF
Types: deb
URIs: https://packages.microsoft.com/repos/code
Suites: stable
Components: main
Architectures: $ARCH
Signed-By: /etc/apt/keyrings/packages.microsoft.gpg
EOF

log "Installing Brave Browser"
sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
  https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
sudo curl -fsSLo /etc/apt/sources.list.d/brave-browser-release.sources \
  https://brave-browser-apt-release.s3.brave.com/brave-browser.sources

log "Installing Syncthing"
sudo curl -fsSL -o /etc/apt/keyrings/syncthing-archive-keyring.gpg \
  https://syncthing.net/release-key.gpg
sudo tee /etc/apt/sources.list.d/syncthing.list >/dev/null <<'EOF'
deb [signed-by=/etc/apt/keyrings/syncthing-archive-keyring.gpg] https://apt.syncthing.net/ syncthing stable-v2
EOF
sudo tee /etc/apt/preferences.d/syncthing.pref >/dev/null <<'EOF'
Package: *
Pin: origin apt.syncthing.net
Pin-Priority: 990
EOF

log "Configuring the GitHub CLI repository"
sudo curl -fsSL -o /etc/apt/keyrings/githubcli-archive-keyring.gpg \
  https://cli.github.com/packages/githubcli-archive-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
printf 'deb [arch=%s signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main\n' "$ARCH" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null

sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y brave-browser code gh syncthing

log "Installing Flatpak applications"
sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
sudo flatpak install --system -y flathub \
  com.slack.Slack io.dbeaver.DBeaverCommunity com.getpostman.Postman \
  com.github.tchx84.Flatseal md.obsidian.Obsidian
sudo flatpak update --system -y

log "Installing MongoDB Compass ${COMPASS_VERSION}"
COMPASS_DEB="/tmp/mongodb-compass_${COMPASS_VERSION}_amd64.deb"
wget -q "https://downloads.mongodb.com/compass/mongodb-compass_${COMPASS_VERSION}_amd64.deb" -O "$COMPASS_DEB"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$COMPASS_DEB"
rm -f "$COMPASS_DEB"

log "Configuring SSH and Zsh"
mkdir -p "$TARGET_HOME/.ssh"
chmod 700 "$TARGET_HOME/.ssh"
if [[ ! -f "$TARGET_HOME/.ssh/id_ed25519" ]]; then
  ssh-keygen -t ed25519 -C "${TARGET_USER}@$(hostname)-fresh-install" -N '' \
    -f "$TARGET_HOME/.ssh/id_ed25519"
fi

if [[ ! -d "$TARGET_HOME/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
fi
touch "$TARGET_HOME/.zshrc"
if grep -q '^ZSH_THEME=' "$TARGET_HOME/.zshrc"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="sonicradish"/' "$TARGET_HOME/.zshrc"
else
  printf '%s\n' 'ZSH_THEME="sonicradish"' >> "$TARGET_HOME/.zshrc"
fi
if grep -q '^plugins=' "$TARGET_HOME/.zshrc"; then
  sed -i 's/^plugins=.*/plugins=(git docker docker-compose history)/' "$TARGET_HOME/.zshrc"
else
  printf '%s\n' 'plugins=(git docker docker-compose history)' >> "$TARGET_HOME/.zshrc"
fi
sudo usermod -s "$(command -v zsh)" "$TARGET_USER"

log "Preparing project directories and legacy services"
mkdir -p "$TARGET_HOME/www" "$TARGET_HOME/.config/fresh-install"
chmod 700 "$TARGET_HOME/.config/fresh-install"
ENV_FILE="$TARGET_HOME/.config/fresh-install/services.env"
if [[ ! -f $ENV_FILE ]]; then
  umask 077
  {
    printf 'MYSQL_ROOT_PASSWORD=%s\n' "$(openssl rand -hex 24)"
    printf 'MONGO_ROOT_PASSWORD=%s\n' "$(openssl rand -hex 24)"
  } > "$ENV_FILE"
fi

cat > "$TARGET_HOME/.config/fresh-install/compose.yaml" <<EOF
services:
  php7:
    image: lhuggler/php7-xdebug
    profiles: ["legacy"]
    ports:
      - "127.0.0.1:8080:80"
    volumes:
      - "$TARGET_HOME/www:/www"
    restart: unless-stopped

  mysql57:
    image: mysql:5.7
    profiles: ["legacy"]
    environment:
      MYSQL_ROOT_PASSWORD: \${MYSQL_ROOT_PASSWORD}
    ports:
      - "127.0.0.1:3606:3306"
    volumes:
      - mysql57_data:/var/lib/mysql
    command: ["--sql-mode="]
    restart: unless-stopped

  mongo:
    image: mongo:7.0
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: \${MONGO_ROOT_PASSWORD}
    ports:
      - "127.0.0.1:27017:27017"
    volumes:
      - mongo_data:/data/db
    restart: unless-stopped

volumes:
  mysql57_data:
  mongo_data:
EOF

if [[ $INSTALL_LEGACY_STACK == "1" ]]; then
  sudo docker compose --profile legacy --env-file "$ENV_FILE" \
    -f "$TARGET_HOME/.config/fresh-install/compose.yaml" up -d
else
  sudo docker compose --env-file "$ENV_FILE" \
    -f "$TARGET_HOME/.config/fresh-install/compose.yaml" up -d
fi

printf '\n============================================\n'
printf '  INSTALLATION COMPLETE\n'
printf '============================================\n'
printf 'Public SSH key (add it to GitHub):\n\n'
cat "$TARGET_HOME/.ssh/id_ed25519.pub"
printf '\n\nLocal credentials: %s\n' "$ENV_FILE"
printf 'Compose: %s\n' "$TARGET_HOME/.config/fresh-install/compose.yaml"
if [[ $INSTALL_LEGACY_STACK != "1" ]]; then
  printf 'PHP 7/MySQL 5.7 were not started. Use INSTALL_LEGACY_STACK=1 to enable them.\n'
fi
printf 'Log out and back in to use Docker without sudo and activate Zsh as the default shell.\n'

if [[ $REBOOT_AFTER_INSTALL == "1" ]]; then
  log "Rebooting in 10 seconds; press Ctrl+C to cancel"
  sleep 10
  sudo reboot
else
  printf 'Automatic reboot is disabled. Use REBOOT_AFTER_INSTALL=1 to enable it.\n'
fi
