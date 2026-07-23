# Fresh Install

An opinionated bootstrap script for a fresh Ubuntu or Linux Mint web development workstation.

## Requirements

- A recent Ubuntu or Linux Mint release (`amd64`)
- A regular user with `sudo` access
- An internet connection

Do not run the script directly as `root`.

## Usage

```sh
chmod +x install.sh
./install.sh
```

To reboot automatically after installation:

```sh
REBOOT_AFTER_INSTALL=1 ./install.sh
```

To also start PHP 7 and MySQL 5.7 for legacy projects:

```sh
INSTALL_LEGACY_STACK=1 ./install.sh
```

Both options can be combined in the same execution.

## Included Software

- Full system update
- Git, GitHub CLI, build tools, Composer, PHP CLI, and common PHP extensions
- MySQL/PostgreSQL clients and modern terminal utilities
- Node.js 24 LTS through NodeSource
- Docker Engine, Buildx, and Docker Compose from Docker's official repository
- Visual Studio Code, Brave, Syncthing, and MongoDB Compass
- Flatpak, Slack, DBeaver, Postman, Flatseal, and Obsidian
- Zsh and Oh My Zsh with Git, Docker, Compose, and history plugins
- An Ed25519 SSH key, while preserving an existing key
- A `~/www` project directory

## Local Services

The script starts MongoDB 7 through Docker Compose. PHP 7 and MySQL 5.7 belong to the optional `legacy` profile and start only with `INSTALL_LEGACY_STACK=1`. All ports are bound to `127.0.0.1`:

- PHP: `http://localhost:8080`
- MySQL: `localhost:3606`
- MongoDB: `localhost:27017`

Configuration and randomly generated credentials are stored under `~/.config/fresh-install/` with user-only permissions. To manage the services:

```sh
docker compose --env-file ~/.config/fresh-install/services.env \
  -f ~/.config/fresh-install/compose.yaml ps
```

Log out and back in after installation to apply Docker group membership and the default shell.

## Terminal Tools

The bootstrap installs the commands below. They do not replace traditional Unix tools; they provide convenient alternatives for recurring development tasks.

### `rg` — text search

Ripgrep searches recursively and respects `.gitignore`. It is a fast alternative to common `find` and `grep` combinations:

```sh
rg "MYSQL_ROOT_PASSWORD"
rg "TODO" src tests
rg --files
```

### `jq` — JSON processing

Use `jq` to read, filter, and format JSON from configuration files or API responses:

```sh
jq . package.json
curl -s https://api.example.com/items | jq '.[0]'
```

Keep filter expressions inside single quotes so the shell does not interpret their special characters.

### `shellcheck` — shell analysis

ShellCheck detects unquoted variables, portability problems, and fragile shell constructs:

```sh
bash -n install.sh
shellcheck install.sh
```

`bash -n` validates syntax, while ShellCheck adds static analysis.

### `gh` — GitHub CLI

Use GitHub CLI to authenticate, inspect issues, and work with pull requests without opening a browser:

```sh
gh auth login
gh repo view --web
gh pr create
gh pr checks
```

Run `gh auth login` once after installation. The package comes from the official GitHub CLI repository.

### Other utilities

- `tree`: displays directory structures, for example `tree -L 2`.
- `zip` and `unzip`: create and extract ZIP archives.
- `composer`: manages PHP dependencies; run `composer install` inside a project.
- PHP extensions: cURL, Intl, Mbstring, MySQL, SQLite, XML, and ZIP.

Do not run Composer or npm with `sudo`. Project dependencies should belong to the regular user and be declared by the project.
