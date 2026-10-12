#!/usr/bin/env bash
#
# Server Environment Setup Script
# Configures the CLI PHP and Node.js versions for cPanel / CloudLinux shared hosting.
#
# Usage:
#   ./server-env-setup.sh                          # interactive menu
#   ./server-env-setup.sh --list                   # show installed PHP versions
#   ./server-env-setup.sh --php 8.2                # switch CLI PHP to 8.2
#   ./server-env-setup.sh --node 22                # install Node.js 22 via nvm
#   ./server-env-setup.sh --php 8.3 --node lts --fix-perms
#
# Note: this changes the PHP used on the command line (SSH, cron, composer).
# The PHP version used by your website is set in cPanel > MultiPHP Manager.

# No `set -e`/`set -u`: nvm is not compatible with them, and errors are handled explicitly.
set -o pipefail

readonly SCRIPT_VERSION="2.0.0"
readonly NVM_VERSION="v0.40.3"
readonly BIN_DIR="$HOME/.local/bin"
readonly BASHRC="$HOME/.bashrc"
readonly CPANEL_COMPOSER="/opt/cpanel/composer/bin/composer"
readonly MARK_BEGIN="# >>> server-env-setup >>>"
readonly MARK_END="# <<< server-env-setup <<<"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

ASSUME_YES=0
BASHRC_BACKED_UP=0

if (( BASH_VERSINFO[0] < 4 )); then
    echo "This script requires bash 4 or newer (found $BASH_VERSION)." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# Output helpers
# ---------------------------------------------------------------------------

if [[ -t 1 && -z "${NO_COLOR:-}" ]]; then
    RED=$'\033[0;31m' GREEN=$'\033[0;32m' YELLOW=$'\033[1;33m' BLUE=$'\033[0;34m' NC=$'\033[0m'
else
    RED='' GREEN='' YELLOW='' BLUE='' NC=''
fi

print_header() {
    echo "${BLUE}==========================================${NC}"
    echo "${BLUE}    Server Environment Setup Tool v${SCRIPT_VERSION}${NC}"
    echo "${BLUE}==========================================${NC}"
    echo
}

info()  { echo "${GREEN}[INFO]${NC} $*"; }
warn()  { echo "${YELLOW}[WARN]${NC} $*" >&2; }
error() { echo "${RED}[ERROR]${NC} $*" >&2; }

# prompt VAR "Question: " -- reads a line into VAR, fails if there is no terminal
prompt() {
    local __var=$1 __msg=$2 __reply
    if [[ ! -t 0 ]]; then
        error "Input required but stdin is not a terminal. Use command-line flags (see --help)."
        return 1
    fi
    read -r -p "$__msg" __reply || return 1
    printf -v "$__var" '%s' "$__reply"
}

confirm() {
    (( ASSUME_YES )) && return 0
    local answer
    prompt answer "$1 (y/N): " || return 1
    [[ $answer =~ ^[Yy]([Ee][Ss])?$ ]]
}

usage() {
    cat <<EOF
Server Environment Setup Tool v${SCRIPT_VERSION}

Usage: $(basename "$0") [options]

Run without options for the interactive menu.

Options:
  --php VERSION     Set the CLI PHP version (e.g. 8.2 or 82)
  --node VERSION    Install Node.js via nvm and make it the default
                    (major version such as 20 or 22, or "lts")
  --fix-perms [DIR] Fix common permission issues in a project (default: current dir)
  --list            List the PHP versions installed on this server
  --verify          Show the active PHP / Composer / Node.js versions
  -y, --yes         Answer yes to confirmation prompts
  -h, --help        Show this help
  --version         Show the script version
EOF
}

# ---------------------------------------------------------------------------
# ~/.bashrc management
# ---------------------------------------------------------------------------

backup_bashrc() {
    (( BASHRC_BACKED_UP )) && return 0
    [[ -s $BASHRC ]] || return 0
    local backup
    backup="$BASHRC.bak.$(date +%Y%m%d%H%M%S)"
    cp -p "$BASHRC" "$backup" || { error "Could not back up $BASHRC"; return 1; }
    info "Backed up $BASHRC to $backup"
    BASHRC_BACKED_UP=1
}

# Rewrites the managed block in ~/.bashrc. Also strips the php/composer aliases
# written by v1 of this script, since aliases would shadow the PATH entry.
update_bashrc() {
    touch "$BASHRC" || { error "Cannot write to $BASHRC"; return 1; }
    backup_bashrc || return 1

    local tmp
    tmp=$(mktemp) || { error "mktemp failed"; return 1; }

    awk -v begin="$MARK_BEGIN" -v end="$MARK_END" '
        $0 == begin { skip = 1; next }
        $0 == end   { skip = 0; next }
        skip        { next }
        /^alias (php|composer)=.*\/opt\/cpanel\// { next }
        { print }
    ' "$BASHRC" > "$tmp" || { rm -f "$tmp"; error "Failed to process $BASHRC"; return 1; }

    cat >> "$tmp" <<'EOF'
# >>> server-env-setup >>>
# Managed by server-env-setup.sh - changes inside this block will be overwritten.
case ":$PATH:" in
    *":$HOME/.local/bin:"*) ;;
    *) export PATH="$HOME/.local/bin:$PATH" ;;
esac
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && . "$NVM_DIR/bash_completion"
# <<< server-env-setup <<<
EOF

    # Write in place (rather than mv) to keep the file's permissions and any symlink.
    cat "$tmp" > "$BASHRC"
    local status=$?
    rm -f "$tmp"
    (( status == 0 )) || { error "Failed to update $BASHRC"; return 1; }
}

# ---------------------------------------------------------------------------
# PHP
# ---------------------------------------------------------------------------

declare -A PHP_BINARIES=()

# Finds installed PHP CLI binaries: cPanel EasyApache (ea-php) first, then CloudLinux alt-php.
discover_php() {
    PHP_BINARIES=()
    local bin ver
    shopt -s nullglob
    for bin in /opt/cpanel/ea-php[0-9]*/root/usr/bin/php /opt/alt/php[0-9]*/usr/bin/php; do
        [[ -x $bin && $bin =~ php([0-9])([0-9]+)/ ]] || continue
        ver="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
        [[ -n ${PHP_BINARIES[$ver]:-} ]] || PHP_BINARIES[$ver]=$bin
    done
    shopt -u nullglob
}

sorted_php_versions() {
    (( ${#PHP_BINARIES[@]} )) || return 0
    printf '%s\n' "${!PHP_BINARIES[@]}" | sort -V
}

list_php() {
    discover_php
    if (( ${#PHP_BINARIES[@]} == 0 )); then
        warn "No ea-php or alt-php installations found under /opt."
        return 1
    fi
    echo "Installed PHP versions:"
    local v
    while read -r v; do
        printf '  %-5s %s\n' "$v" "${PHP_BINARIES[$v]}"
    done < <(sorted_php_versions)
}

configure_php() {
    local php_version=$1

    info "Starting PHP configuration..."
    discover_php
    if (( ${#PHP_BINARIES[@]} == 0 )); then
        error "No ea-php or alt-php installations found under /opt. Is this a cPanel/CloudLinux server?"
        return 1
    fi

    if [[ -z $php_version ]]; then
        echo "Available PHP versions: $(sorted_php_versions | paste -sd' ' -)"
        prompt php_version "Enter desired PHP version (e.g. 8.2): " || return 1
    fi

    # Accept "82" as well as "8.2"
    if [[ $php_version =~ ^([0-9])([0-9]+)$ ]]; then
        php_version="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi

    local php_bin=${PHP_BINARIES[$php_version]:-}
    if [[ -z $php_bin ]]; then
        error "PHP '$php_version' is not installed. Available: $(sorted_php_versions | paste -sd' ' -)"
        return 1
    fi

    info "Configuring PHP $php_version ($php_bin)..."
    mkdir -p "$BIN_DIR" || { error "Cannot create $BIN_DIR"; return 1; }
    ln -sfn "$php_bin" "$BIN_DIR/php" || { error "Failed to create PHP symlink"; return 1; }

    # Wrap cPanel's composer so it always runs with the selected PHP.
    if [[ -f $CPANEL_COMPOSER ]]; then
        cat > "$BIN_DIR/composer" <<EOF
#!/bin/sh
exec "$BIN_DIR/php" "$CPANEL_COMPOSER" "\$@"
EOF
        chmod 755 "$BIN_DIR/composer"
    fi

    # Clean up the symlink left by v1 of this script so it can't shadow the new one.
    if [[ -L $HOME/perl5/bin/php && $(readlink "$HOME/perl5/bin/php") == /opt/* ]]; then
        rm -f "$HOME/perl5/bin/php"
        info "Removed old ~/perl5/bin/php symlink"
    fi

    update_bashrc || return 1
    info "PHP $php_version configured for the command line"
    info "Website PHP is set separately in cPanel > MultiPHP Manager."
}

# ---------------------------------------------------------------------------
# Node.js
# ---------------------------------------------------------------------------

load_nvm() {
    [[ -s $NVM_DIR/nvm.sh ]] || return 1
    # shellcheck source=/dev/null
    . "$NVM_DIR/nvm.sh"
}

install_nvm() {
    info "Installing nvm $NVM_VERSION..."
    local url="https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh"
    # PROFILE=/dev/null stops the installer editing ~/.bashrc; we manage that ourselves.
    if command -v curl >/dev/null 2>&1; then
        curl -fsSL "$url" | PROFILE=/dev/null bash
    elif command -v wget >/dev/null 2>&1; then
        wget -qO- "$url" | PROFILE=/dev/null bash
    else
        error "curl or wget is required to install nvm"
        return 1
    fi
}

install_nodejs() {
    local node_version=$1

    info "Starting Node.js installation..."

    if [[ -z $node_version ]]; then
        prompt node_version "Enter desired Node.js version (e.g. 20, 22, 24 or 'lts'): " || return 1
    fi
    node_version=${node_version#v}

    if [[ $node_version == lts ]]; then
        node_version="lts/*"
    elif [[ ! $node_version =~ ^[0-9]+$ ]]; then
        error "Invalid Node.js version '$node_version'. Use a major version (e.g. 22) or 'lts'."
        return 1
    fi

    if ! load_nvm; then
        install_nvm || { error "nvm installation failed"; return 1; }
        load_nvm || { error "nvm installed but $NVM_DIR/nvm.sh could not be loaded"; return 1; }
    else
        info "nvm already installed ($(nvm --version))"
    fi

    info "Installing Node.js $node_version..."
    nvm install "$node_version" || { error "nvm install $node_version failed"; return 1; }
    nvm alias default "$node_version" >/dev/null || warn "Could not set default Node.js version"

    update_bashrc || return 1
    info "Node.js $(node -v) installed and set as default"
}

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------

fix_permissions() {
    local dir=${1:-$PWD}
    [[ -d $dir ]] || { error "Directory '$dir' does not exist"; return 1; }

    info "Fixing common permission issues in $dir..."
    local fixed=0

    # Executables linked from node_modules/.bin (including nested packages)
    if [[ -d $dir/node_modules ]]; then
        local bin_dir
        while IFS= read -r -d '' bin_dir; do
            find -L "$bin_dir" -maxdepth 1 -type f -exec chmod u+x {} + 2>/dev/null
        done < <(find "$dir/node_modules" -type d -name .bin -print0 2>/dev/null)
        info "Made node_modules/.bin executables runnable"
        fixed=1
    fi

    # Laravel writable directories
    if [[ -f $dir/artisan ]]; then
        local d
        for d in storage bootstrap/cache; do
            [[ -d $dir/$d ]] && chmod -R u+rwX "$dir/$d"
        done
        info "Made Laravel storage/ and bootstrap/cache/ writable"
        fixed=1
    fi

    # npm cache location that isn't writable (common after copying a home dir)
    if command -v npm >/dev/null 2>&1; then
        local cache
        cache=$(npm config get cache 2>/dev/null)
        if [[ -n $cache && -e $cache && ! -w $cache ]]; then
            npm config set cache "$HOME/.npm-cache" &&
                info "npm cache $cache was not writable; moved it to ~/.npm-cache"
            fixed=1
        fi
    fi

    (( fixed )) || info "Nothing to fix"
}

# ---------------------------------------------------------------------------
# Status
# ---------------------------------------------------------------------------

php_short_version() {
    "$1" -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION.".".PHP_RELEASE_VERSION;' 2>/dev/null
}

check_current_versions() {
    info "Current environment:"
    if command -v php >/dev/null 2>&1; then
        echo "  PHP:     $(php_short_version php) ($(command -v php))"
    else
        echo "  PHP:     not found in PATH"
    fi
    if command -v node >/dev/null 2>&1; then
        echo "  Node.js: $(node -v) ($(command -v node))"
    else
        echo "  Node.js: not found in PATH"
    fi
    echo
}

# Checks what a fresh login shell will see, without sourcing ~/.bashrc
# (which often exits early in non-interactive shells).
verify_installation() {
    case ":$PATH:" in
        *":$BIN_DIR:"*) ;;
        *) PATH="$BIN_DIR:$PATH" ;;
    esac
    load_nvm >/dev/null 2>&1 && nvm use default >/dev/null 2>&1
    hash -r

    echo "=== Verification Results ==="
    if command -v php >/dev/null 2>&1; then
        echo "${GREEN}✓${NC} PHP:      $(php_short_version php) ($(readlink -f "$(command -v php)"))"
    else
        echo "${RED}✗${NC} PHP:      not accessible"
    fi

    if command -v composer >/dev/null 2>&1; then
        echo "${GREEN}✓${NC} Composer: $(composer --version --no-ansi 2>/dev/null | head -n1)"
    else
        echo "${YELLOW}!${NC} Composer: not found"
    fi

    if command -v node >/dev/null 2>&1; then
        echo "${GREEN}✓${NC} Node.js:  $(node -v)"
        echo "${GREEN}✓${NC} npm:      $(npm -v 2>/dev/null)"
    else
        echo "${RED}✗${NC} Node.js:  not accessible"
    fi
    echo
}

finish_message() {
    info "Done. Run 'source ~/.bashrc' or open a new SSH session to apply the changes."
}

# ---------------------------------------------------------------------------
# Interactive menu
# ---------------------------------------------------------------------------

main_menu() {
    print_header
    check_current_versions

    local choice ran
    while true; do
        echo "Select an option:"
        echo "  1) Configure PHP version"
        echo "  2) Install Node.js"
        echo "  3) Fix permissions (current directory)"
        echo "  4) Full setup (PHP + Node.js + permissions)"
        echo "  5) List installed PHP versions"
        echo "  6) Exit"
        echo
        prompt choice "Choose option [1-6]: " || exit 1
        echo

        ran=1
        case $choice in
            1) configure_php "" ;;
            2) install_nodejs "" ;;
            3) fix_permissions "$PWD" ;;
            4) configure_php "" && echo && install_nodejs "" && echo && fix_permissions "$PWD" ;;
            5) list_php; ran=0 ;;
            6)
                info "Thanks for using Server Environment Setup!"
                echo "${BLUE}Script by Raphael Miyoyo - https://github.com/rmiyoyo${NC}"
                exit 0
                ;;
            *) error "Invalid option '$choice'. Please choose 1-6."; ran=0 ;;
        esac

        if (( ran )); then
            echo
            verify_installation
            finish_message
        fi
        echo
    done
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
    local php_version="" node_version="" fix_dir="" do_fix=0 do_list=0 do_verify=0

    while (( $# )); do
        case $1 in
            --php)       [[ -n ${2:-} ]] || { error "--php requires a version"; exit 2; }
                         php_version=$2; shift ;;
            --node)      [[ -n ${2:-} ]] || { error "--node requires a version"; exit 2; }
                         node_version=$2; shift ;;
            --fix-perms) do_fix=1
                         if [[ -n ${2:-} && $2 != -* ]]; then fix_dir=$2; shift; fi ;;
            --list)      do_list=1 ;;
            --verify)    do_verify=1 ;;
            -y|--yes)    ASSUME_YES=1 ;;
            -h|--help)   usage; exit 0 ;;
            --version)   echo "$SCRIPT_VERSION"; exit 0 ;;
            *)           error "Unknown option: $1"; usage >&2; exit 2 ;;
        esac
        shift
    done

    if (( EUID == 0 )); then
        warn "Running as root is not recommended: this configures the current user's environment."
        confirm "Continue anyway?" || exit 1
    fi

    if (( do_list )); then
        list_php
        exit $?
    fi

    # No actions requested: interactive mode
    if [[ -z $php_version && -z $node_version ]] && (( !do_fix && !do_verify )); then
        main_menu
    fi

    local failed=0
    if [[ -n $php_version ]]; then configure_php "$php_version" || failed=1; fi
    if [[ -n $node_version ]]; then install_nodejs "$node_version" || failed=1; fi
    if (( do_fix )); then fix_permissions "${fix_dir:-$PWD}" || failed=1; fi

    echo
    verify_installation
    [[ -n $php_version || -n $node_version ]] && finish_message
    exit "$failed"
}

main "$@"
