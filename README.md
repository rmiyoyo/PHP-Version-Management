# PHP Version Management

A bash script that automates PHP and Node.js version configuration for shared hosting environments.

---

## Common Errors This Script Fixes

### PHP/Composer Errors:
```
Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.0.2". You are running 7.4.32.
```

```
Fatal error: Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.1.0"
```

### Node.js/NPM Errors:
```
npm WARN EBADENGINE Unsupported engine { package: 'vite@6.2.5', required: { node: '^18.0.0 || ^20.0.0 || >=22.0.0' }, current: { node: 'v16.20.2' } }
```

```
sh: line 1: /home/user/project/node_modules/.bin/vite: Permission denied
```

```
npm ERR! engine Unsupported engine for laravel-vite-plugin@1.2.0: wanted: {"node":"^18.0.0 || ^20.0.0 || >=22.0.0"} (current: {"node":"16.20.2"})
```

---

## Quick Start

1. Upload `server-env-setup.sh` to your server's home directory
2. Make it executable: `chmod +x server-env-setup.sh`
3. Run the script: `./server-env-setup.sh`

---

## What It Does

### PHP Configuration:
- Detects the PHP versions actually installed on the server (cPanel `ea-php` and CloudLinux `alt-php`)
- Symlinks the chosen version to `~/.local/bin/php` for CLI usage
- Wraps cPanel's Composer so it always runs with the selected PHP version
- Cleans up the `php`/`composer` aliases and `~/perl5/bin/php` symlink created by older versions of this script

> **Note:** This sets the PHP version for the command line (SSH, cron, Composer). The version your website runs on is set in cPanel > MultiPHP Manager.

### Node.js Installation:
- Installs Node Version Manager (NVM) if not present
- Installs any Node.js major version (e.g. 20, 22, 24) or the latest LTS
- Sets the chosen version as default

### Shell Configuration:
- Keeps all changes in a single marked block in `~/.bashrc`, so re-running the script never adds duplicate lines
- Backs up `~/.bashrc` before changing it

### Permission Fixes:
- Resolves `node_modules/.bin` permission issues (including nested packages)
- Makes Laravel's `storage/` and `bootstrap/cache/` writable
- Moves the npm cache to `~/.npm-cache` if the current one isn't writable

---

## Usage Options

Run without arguments for an interactive menu:

1. Configure PHP version
2. Install Node.js
3. Fix permissions (current directory)
4. Full setup (PHP + Node.js + permissions)
5. List installed PHP versions
6. Exit

Or pass options to run without prompts:

```bash
./server-env-setup.sh --list                    # show installed PHP versions
./server-env-setup.sh --php 8.2                 # switch CLI PHP to 8.2
./server-env-setup.sh --node 22                 # install Node.js 22
./server-env-setup.sh --php 8.3 --node lts --fix-perms
./server-env-setup.sh --verify                  # show active versions
./server-env-setup.sh --help
```

---

## Post-Installation

After running the script:

- Restart your SSH session, or
- Run `source ~/.bashrc` to apply changes
- For terminal users: open a new terminal window

> **Note:** The script automatically verifies the installation and displays version information.

---

## System Requirements

- Bash 4 or newer (standard on cPanel/CloudLinux servers)
- Internet connection for downloading Node.js
- Write permissions to home directory
- Access to PHP binaries on the server

---

## Troubleshooting

### Script Won't Execute
```bash
# Make sure the script has execute permissions
chmod +x server-env-setup.sh

# Check if bash is available
which bash
```

### PHP Version Not Switching
```bash
# Manually source the configuration
source ~/.bashrc

# Check where the php symlink points
ls -la ~/.local/bin/php

# See which PHP versions are installed
./server-env-setup.sh --list
```

### Node.js Installation Issues
```bash
# Check if NVM was installed correctly
command -v nvm

# Manually load NVM
source ~/.nvm/nvm.sh
```

---

## Manual Configuration

If you prefer to configure manually, here are the key steps the script performs:

### For PHP:
```bash
# Create bin directory
mkdir -p ~/.local/bin

# Create PHP symlink (example for cPanel PHP 8.1)
ln -sfn /opt/cpanel/ea-php81/root/usr/bin/php ~/.local/bin/php

# Add to PATH in ~/.bashrc
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
```

### For Node.js:
```bash
# Install NVM
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash

# Install and use Node.js
nvm install 22
nvm use 22
nvm alias default 22
```

---

## Support

If you encounter any issues:

1. Check the error messages displayed by the script
2. Ensure you have the necessary permissions
3. Verify your hosting provider supports the PHP/Node.js versions you're trying to use
4. Contact your hosting provider for server-specific PHP binary locations

---