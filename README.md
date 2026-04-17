# Acorn helper scripts

> CI runs for this repository under development. Currently tested on Ubuntu 22+ only.

![Human made content](human-made-content.png "Human made content")
[![CI](https://github.com/anewholm/scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/anewholm/scripts/actions/workflows/ci.yml)

Shell scripts for setting up and managing WinterCMS installations, databases, Apache vhosts, and developer laptops on Ubuntu/KUbuntu. These are used commonly in CI/CD runs for the other repositories.

## Prominent scripts

| Script | Purpose |
|--------|---------|
| `acorn-setup-hostname` | Create Apache vhost, `/etc/hosts` entry, and SSL cert for a new local domain |
| `acorn-setup-database` | Create PostgreSQL database and user for a project |
| `acorn-setup-new-winter` | Install a fresh WinterCMS with Acorn + plugins into `/var/www/<name>` |
| `acorn-setup-laptop` | Full developer laptop setup (Apache, PHP, PostgreSQL, tools) |
| `acorn-setup-laptop-from-usb` | Automated laptop setup from Acorn USB drive |
| `acorn-setup-server` | Server variant of laptop setup |
| `acorn-setup-samba` | Configure Samba share for a project |
| `acorn-setup-apache-https` | Enable HTTPS on an existing vhost |
| `acorn-setup-security` | Harden a server installation |
| `acorn-backup` / `acorn-restore` | Backup and restore a WinterCMS project (files + DB) |
| `acorn-git-all` / `acorn-git-push-all` | Run git commands across all `/var/www/` projects |

## Quick start — new WinterCMS site

```bash
cd /var/www/
./scripts/acorn-setup-new-winter myproject
```

This creates a complete WinterCMS installation with PostgreSQL database and Apache vhost at `http://myproject.laptop`. It will automatically call `acorn-setup-hostname myproject` and `acorn-setup-database myproject` using `sudo` where necessary. Resultant website filesystem will be ch-owned by `www-data:www-data`.

## Installation

Clone into `/var/www/scripts` so the scripts are reachable as `../scripts/acorn-*` from any `/var/www` project directory:

```bash
git clone https://github.com/anewholm/scripts /var/www/scripts
```

## Compatibility

| OS (LTS) | [WinterCMS](https://wintercms.com/install) (target) | [Composer](https://getcomposer.org/download/) | [PHP](https://www.php.net/downloads.php)  | [PostgreSQL](https://www.postgresql.org/download/) |
|-----------|---------|---|------|------------|
| Ubuntu 22+ | v1.2+ | 2 | v8.1+ | v15+ |

## Related

- [anewholm/create-system](https://github.com/anewholm/create-system) — DDL-first code generator: introspects PostgreSQL schema and scaffolds WinterCMS plugins
- [anewholm/acorn](https://github.com/anewholm/acorn) — the WinterCMS base module these scripts install
- [anewholm/calendar](https://github.com/anewholm/calendar) — example plugin set up by these scripts
- [anewholm/dbauth](https://github.com/anewholm/dbauth) — DB authentication module

## License

MIT
