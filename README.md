# Acorn helper scripts

![Human made content](human-made-content.png "Human made content")

Shell scripts for setting up and managing WinterCMS installations, databases, Apache vhosts, and developer laptops on Ubuntu/KUbuntu.

## What's here

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
./scripts/acorn-setup-hostname myproject
./scripts/acorn-setup-database myproject
./scripts/acorn-setup-new-winter myproject
```

This creates a complete WinterCMS installation with PostgreSQL database and Apache vhost at `http://myproject.laptop`.

## Installation

Clone into `/var/www/scripts` so the scripts are reachable as `scripts/acorn-*` from any project directory:

```bash
git clone https://github.com/anewholm/scripts /var/www/scripts
```

## Prerequisites

- Ubuntu 22.04+ or KUbuntu
- Apache 2, PHP 8.1+, PostgreSQL 12+, Composer

## Related

- [anewholm/create-system](https://github.com/anewholm/create-system) — DDL-first code generator: introspects PostgreSQL schema and scaffolds WinterCMS plugins
- [anewholm/acorn](https://github.com/anewholm/acorn) — the WinterCMS base module these scripts install
- [anewholm/calendar](https://github.com/anewholm/calendar) — example plugin set up by these scripts
- [anewholm/dbauth](https://github.com/anewholm/dbauth) — DB authentication module

## License

MIT
