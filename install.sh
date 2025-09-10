#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[*]${NC} $1"
}

error() {
    echo -e "${RED}[!]${NC} $1"
}

success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

# Function to install dependencies
install_dependencies() {
    log "Updating package list..."
    apt update
    
    log "Installing required packages..."
    apt install curl wget -y
    
    success "Dependencies installed successfully"
}

# Function to download select.sh
download_select_sh() {
    log "Downloading select.sh..."
    
    if curl -o select.sh "https://github.com/magi17/dnstt-client/raw/refs/heads/main/select.sh"; then
        chmod +x select.sh
        success "select.sh downloaded successfully"
        return 0
    else
        error "Failed to download select.sh"
        return 1
    fi
}

# Function to download gtm.sh
download_gtm_sh() {
    log "Downloading gtm.sh..."
    
    if curl -o gtm.sh "https://github.com/magi17/dnstt-client/raw/heads/main/gtm.sh"; then
        chmod +x gtm.sh
        success "gtm.sh downloaded successfully"
        return 0
    else
        error "Failed to download gtm.sh"
        return 1
    fi
}

# Function to create bin directory and add to PATH
setup_bin_directory() {
    log "Setting up ~/bin directory..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$HOME/bin"
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/bin:$PATH"
        success "Added ~/bin to PATH"
    else
        log "~/bin is already in PATH"
    fi
}

# Function to create gtmmenu command
create_gtmmenu_command() {
    log "Creating gtmmenu command..."
    
    # Create a wrapper script in ~/bin
    cat > "$HOME/bin/gtmmenu" << 'EOF'
#!/bin/bash

# Find the select.sh script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# First check current directory
if [[ -f "./select.sh" ]]; then
    bash "./select.sh"
# Then check home directory
elif [[ -f "$HOME/select.sh" ]]; then
    bash "$HOME/select.sh"
# Then check in bin directory
elif [[ -f "$HOME/bin/select.sh" ]]; then
    bash "$HOME/bin/select.sh"
else
    echo "Error: select.sh not found!"
    echo "Please run the install script again or make sure select.sh is available."
    exit 1
fi
EOF

    chmod +x "$HOME/bin/gtmmenu"
    success "gtmmenu command created"
}

# Function to move scripts to bin (optional)
move_scripts_to_bin() {
    log "Moving scripts to ~/bin/ to hide them..."
    
    if [[ -f "select.sh" ]]; then
        mv select.sh "$HOME/bin/" && chmod +x "$HOME/bin/select.sh"
        success "Moved select.sh to ~/bin/"
    fi
    
    if [[ -f "gtm.sh" ]]; then
        mv gtm.sh "$HOME/bin/" && chmod +x "$HOME/bin/gtm.sh"
        success "Moved gtm.sh to ~/bin/"
    fi
}

# Function to create desktop shortcut (optional)
create_desktop_shortcut() {
    log "Creating desktop shortcut..."
    
    # This would create a Termux shortcut if supported
    echo "To run the menu, type: gtmmenu"
}

# Main installation function
main_install() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║        GTM Menu Installer            ║"
    echo "║                                      ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Starting installation..."
    
    # Install dependencies
    install_dependencies
    
    # Setup bin directory
    setup_bin_directory
    
    # Download scripts
    download_select_sh
    download_gtm_sh
    
    # Create gtmmenu command
    create_gtmmenu_command
    
    # Ask if user wants to hide scripts in bin
    read -p "Do you want to hide scripts in ~/bin/? (y/n): " answer
    case $answer in
        [Yy]*)
            move_scripts_to_bin
            ;;
        *)
            log "Keeping scripts in current directory"
            ;;
    esac
    
    # Final instructions
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║         INSTALLATION COMPLETE        ║"
    echo "║                                      ║"
    echo "║  To open the menu, type: gtmmenu     ║"
    echo "║                                      ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Reload bashrc
    source ~/.bashrc
    
    # Test the command
    log "Testing gtmmenu command..."
    if command -v gtmmenu &> /dev/null; then
        success "gtmmenu command is ready to use!"
        echo ""
        echo "Type 'gtmmenu' to start the menu"
    else
        warning "gtmmenu command might not be in PATH yet"
        echo "Please restart Termux or run: source ~/.bashrc"
    fi
}

# Run installation
main_install
