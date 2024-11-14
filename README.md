# Fresh Install

## Usage

Parâmetro 1: Caminho para o arquivo de chaves SSH

```sh 
./install.sh ./keys.zip
```
## Contents

- Hotfix para teclados com comandos/modo Apple (MAC)
- Visual Studio Code via repositório oficial Microsoft
- MongoDB Compass v1.44.5 via arquivo `.deb` (Remove o arquivo após instalar)
- Instala as seguintes aplicações básicas via **APT**
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
  - PHP CLIENT 
  - PHP-XML 
  - HTOP
- Instala as seguintes aplicações via **Flatpak**
  - Slack
  - DBeaver
  - PostMan
  - Docker GUI
  - Flat Seal
- Instala as seguintes aplicações via **Snapcraft**
  - MySQL Workbench Community
  - Brave Browser
- Configura permissões de grupo para:
  - Docker
- Extrai e adiciona as chaves `.ssh` caso informado o caminho para o arquivo.
- Altera o shell padrão para o **OhMyZSH**
  - Adiciona os plugins à configuração do OhMyZSH: git, docker, docker-compose, history
  - Altera o tema para `sonicradish`
- Cria o diretório `www` para utilização no Docker - PHP7
- Configuração de container Docker 
  - Cria a subrede `devnet` para utilização nos containers
  - Container PHP 7
  - Container MySQL 5.7
  - Container MongoDB
