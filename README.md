# Fresh Install

## Usage

```sh 
./install.sh
```

## Contents

- Hotfix for Apple keyboard command mode (MAC)
- Full system update (apt update + upgrade)
- Visual Studio Code via official Microsoft repository
- MongoDB Compass v1.44.5 via `.deb` file (Removes the file after installation)
- **Node.js 23.x**, NPM and NPM Version Manager (`n`) via NodeSource
- Installs the following basic applications via **APT**
  - CURL
  - WGET
  - GPG
  - BUILD ESSENTIALS
  - FLATPAK
  - GIT
  - DOCKER
  - DOCKER COMPOSER
  - zSH
  - POEDIT
  - MYSQL CLIENT
  - POSTGRESQL CLIENT
  - PHP CLIENT
  - PHP-XML
  - HTOP
  - NEOFETCH
  - **Syncthing** (via official APT repository)
  - **Brave Browser** (via official Brave repository)
- Installs the following applications via **Flatpak**
  - Slack
  - DBeaver
  - PostMan
  - Docker GUI (Whaler)
  - Flat Seal
  - Obsidian
- Installs the following applications via **Snapcraft**
  - MySQL Workbench Community
- Configures group permissions for:
  - Docker
- Generates a new **Ed25519 SSH key** and displays the public key at the end with instructions to add it to GitHub.
- Changes the default shell to **OhMyZSH**
  - Adds plugins to OhMyZSH config: git, docker, docker-compose, history
  - Changes theme to `sonicradish`
- Creates the `www` directory for Docker PHP7 usage
- Docker container setup
  - Creates the `devnet` subnet for container networking
  - PHP 7 container
  - MySQL 5.7 container
  - MongoDB container
