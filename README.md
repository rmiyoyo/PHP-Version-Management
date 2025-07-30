# PHP-Version-Management
A bash script that automates PHP and Node.js version configuration for shared hosting environments.

## Common Errors This Script Fixes

**PHP/Composer Errors:**
```
Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.0.2". You are running 7.4.32.
```
```
Fatal error: Composer detected issues in your platform: Your Composer dependencies require a PHP version ">= 8.1.0"
```

**Node.js/NPM Errors:**
```
npm WARN EBADENGINE Unsupported engine { package: 'vite@6.2.5', required: { node: '^18.0.0 || ^20.0.0 || >=22.0.0' }, current: { node: 'v16.20.2' } }
```
```
sh: line 1: /home/user/project/node_modules/.bin/vite: Permission denied
```
```
npm ERR! engine Unsupported engine for laravel-vite-plugin@1.2.0: wanted: {"node":"^18.0.0 || ^20.0.0 || >=22.0.0"} (current: {"node":"16.20.2"})
```

## Quick Start

1. Upload `server-env-setup.sh` to your server's home directory
2. Make it executable: `chmod +x server-env-setup.sh`
3. Run the script: `./server-env-setup.sh`

## What It Does

**PHP Configuration:**
- Creates symlinks to specify PHP versions for CLI usage
- Configures aliases as fallback method
- Supports PHP versions 5.6 through 8.3
- Automatically sets up Composer to use the correct PHP version

**Node.js Installation:**
- Installs Node Version Manager (NVM) if not present
- Downloads and configures specified Node.js version (18, 20, or 22)
- Sets the chosen version as default
- Updates shell configuration automatically

**Permission Fixes:**
- Resolves common `node_modules/.bin` permission issues
- Configures npm cache permissions
- Fixes executable permissions for build tools

## Usage Options

The script provides an interactive menu with these options:
1. Configure PHP version only
2. Install Node.js only  
3. Fix permissions only
4. Complete setup (all three)
5. Exit

## Post-Installation

After running the script:
- Restart your SSH session, or
- Run `source ~/.bashrc` to apply changes
- For terminal users: open a new terminal window

The script automatically verifies the installation and displays version information.