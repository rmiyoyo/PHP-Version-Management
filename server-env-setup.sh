#!/bin/bash

# Server Environment Setup Script
# Automates PHP and Node.js version configuration for shared hosting

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}    Server Environment Setup Tool       ${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_current_versions() {
    print_status "Checking current environment..."
    
    if command -v php &> /dev/null; then
        current_php=$(php -v | head -n1 | cut -d' ' -f2 | cut -d'.' -f1,2)
        echo "Current PHP version: $current_php"
    else
        echo "PHP not found in PATH"
    fi
    
    if command -v node &> /dev/null; then
        current_node=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
        echo "Current Node.js version: v$(node -v | cut -c2-)"
    else
        echo "Node.js not found in PATH"
    fi
    echo ""
}

configure_php() {
    print_status "Starting PHP configuration..."
    
    echo "Available PHP versions: 5.6, 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3"
    echo -n "Enter desired PHP version (e.g., 8.0, 8.1): "
    read php_version
    
    # Convert version to format needed (remove dot)
    php_numeric=$(echo $php_version | tr -d '.')
    
    # Validate version
    if [[ ! $php_numeric =~ ^(56|70|71|72|73|74|80|81|82|83)$ ]]; then
        print_error "Invalid PHP version. Please use format like 8.0, 8.1, etc."
        return 1
    fi
    
    print_status "Configuring PHP $php_version..."
    
    # Method 1: Try symlink approach first
    if [ -f "/opt/cpanel/ea-php${php_numeric}/root/usr/bin/php" ]; then
        print_status "Creating PHP symlink..."
        
        # Create perl5/bin directory if it doesn't exist
        mkdir -p ~/perl5/bin
        
        # Remove existing PHP symlink if present
        [ -L ~/perl5/bin/php ] && rm ~/perl5/bin/php
        
        # Create new symlink
        ln -sf "/opt/cpanel/ea-php${php_numeric}/root/usr/bin/php" ~/perl5/bin/php
        
        # Update PATH in bashrc if needed
        if ! grep -q 'perl5/bin' ~/.bashrc; then
            echo 'export PATH="$HOME/perl5/bin:$PATH"' >> ~/.bashrc
        fi
        
        print_status "PHP symlink created successfully"
    else
        print_warning "Symlink method failed, trying alias method..."
        
        # Method 2: Alias approach
        # Clean existing aliases
        sed -i '/alias php=/d' ~/.bashrc 2>/dev/null || true
        sed -i '/alias composer=/d' ~/.bashrc 2>/dev/null || true
        
        # Add new aliases
        echo "alias php='/opt/cpanel/ea-php${php_numeric}/root/usr/bin/php'" >> ~/.bashrc
        echo "alias composer='php /opt/cpanel/composer/bin/composer'" >> ~/.bashrc
        
        print_status "PHP aliases configured"
    fi
    
    # Source bashrc
    source ~/.bashrc 2>/dev/null || true
    
    print_status "PHP configuration completed"
}

install_nodejs() {
    print_status "Starting Node.js installation..."
    
    echo -n "Enter desired Node.js version (18, 20, 22): "
    read node_version
    
    if [[ ! $node_version =~ ^(18|20|22)$ ]]; then
        print_error "Invalid Node.js version. Please choose 18, 20, or 22."
        return 1
    fi
    
    print_status "Installing Node.js v$node_version..."
    
    # Download and install Node Version Manager if not present
    if [ ! -d "$HOME/.nvm" ]; then
        print_status "Installing Node Version Manager..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
        
        # Load NVM
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        print_status "NVM already installed, loading..."
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Install and use the specified Node.js version
    print_status "Installing Node.js v$node_version..."
    nvm install $node_version
    nvm use $node_version
    nvm alias default $node_version
    
    # Update bashrc to load NVM automatically
    if ! grep -q 'NVM_DIR' ~/.bashrc; then
        echo '' >> ~/.bashrc
        echo '# Load NVM' >> ~/.bashrc
        echo 'export NVM_DIR="$HOME/.nvm"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"' >> ~/.bashrc
        echo '[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"' >> ~/.bashrc
    fi
    
    print_status "Node.js installation completed"
}

fix_permissions() {
    print_status "Fixing common permission issues..."
    
    # Fix node_modules permissions if directory exists
    if [ -d "node_modules" ]; then
        chmod -R u+x node_modules/.bin/ 2>/dev/null || true
        print_status "Fixed node_modules permissions"
    fi
    
    # Fix npm cache permissions
    if command -v npm &> /dev/null; then
        npm config set cache ~/.npm-cache --global 2>/dev/null || true
    fi
}

verify_installation() {
    print_status "Verifying installation..."
    echo ""
    
    # Source bashrc to get latest environment
    source ~/.bashrc 2>/dev/null || true
    
    # Load NVM if available
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" 2>/dev/null || true
    
    echo "=== Verification Results ==="
    
    if command -v php &> /dev/null; then
        echo -e "${GREEN}✓${NC} PHP: $(php -v | head -n1)"
    else
        echo -e "${RED}✗${NC} PHP not accessible"
    fi
    
    if command -v node &> /dev/null; then
        echo -e "${GREEN}✓${NC} Node.js: $(node -v)"
        echo -e "${GREEN}✓${NC} NPM: $(npm -v)"
    else
        echo -e "${RED}✗${NC} Node.js not accessible"
    fi
    
    if command -v composer &> /dev/null; then
        echo -e "${GREEN}✓${NC} Composer: Available"
    else
        echo -e "${YELLOW}!${NC} Composer: May need manual verification"
    fi
    
    echo ""
}

main_menu() {
    print_header
    check_current_versions
    
    echo "Select an option:"
    echo "1) Configure PHP version"
    echo "2) Install Node.js"
    echo "3) Fix permissions"
    echo "4) Full setup (PHP + Node.js + permissions)"
    echo "5) Exit"
    echo ""
    echo -n "Choose option [1-5]: "
    read choice
    
    case $choice in
        1)
            configure_php
            ;;
        2)
            install_nodejs
            ;;
        3)
            fix_permissions
            ;;
        4)
            configure_php
            echo ""
            install_nodejs
            echo ""
            fix_permissions
            ;;
        5)
            echo ""
            print_status "Thanks for using this Server Environment Setup!"
            echo -e "${BLUE}Script by Raphael Miyoyo${NC}"
            echo -e "${BLUE}GitHub: https://github.com/rmiyoyo${NC}"
            echo ""
            print_status "Happy coding! 🚀"
            exit 0
            ;;
        *)
            print_error "Invalid option. Please choose 1-5."
            sleep 2
            main_menu
            ;;
    esac
    
    echo ""
    verify_installation
    
    echo ""
    print_status "Setup completed! Please restart your SSH session or run 'source ~/.bashrc' to apply changes."
    print_warning "If using terminal, you may need to open a new terminal window."
}

# Check if running as root (not recommended)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended for this script."
    echo -n "Continue anyway? (y/N): "
    read continue_root
    if [[ ! $continue_root =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Start main menu
main_menu