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
    pkg update -y
    
    log "Installing required packages..."
    pkg install wget -y
    
    success "Dependencies installed successfully"
}

# Function to download select.sh using wget
download_select_sh() {
    log "Downloading select.sh using wget..."
    
    # Check if select.sh exists, delete it
    if [[ -f "$HOME/bin/.select.sh" ]]; then
        rm "$HOME/bin/.select.sh"
        log "Removed existing select.sh"
    fi
    
    if wget -O "$HOME/bin/.select.sh" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/select.sh"; then
        chmod +x "$HOME/bin/.select.sh"
        success "select.sh downloaded successfully"
        return 0
    else
        error "Failed to download select.sh"
        return 1
    fi
}

# Function to download gtm.sh using wget
download_gtm_sh() {
    log "Downloading gtm.sh using wget..."
    
    # Check if gtm.sh exists, delete it
    if [[ -f "$HOME/bin/.gtm.sh" ]]; then
        rm "$HOME/bin/.gtm.sh"
        log "Removed existing gtm.sh"
    fi
    
    if wget -O "$HOME/bin/.gtm.sh" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/gtm.sh"; then
        chmod +x "$HOME/bin/.gtm.sh"
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
    
    # Check if gtmmenu exists, delete it
    if [[ -f "$HOME/bin/gtmmenu" ]]; then
        rm "$HOME/bin/gtmmenu"
        log "Removed existing gtmmenu command"
    fi
    
    # Create a wrapper script in ~/bin
    cat > "$HOME/bin/gtmmenu" << 'EOF'
#!/bin/bash

# Find the select.sh script
if [[ -f "$HOME/bin/.select.sh" ]]; then
    bash "$HOME/bin/.select.sh"
else
    echo "Error: select.sh not found!"
    echo "Please run the install script again."
    exit 1
fi
EOF

    chmod +x "$HOME/bin/gtmmenu"
    success "gtmmenu command created"
}

# Function to fix menu command issue
fix_menu_command() {
    log "Checking if menu command works..."
    
    # Test if menu command exists and works
    if command -v menu &> /dev/null; then
        success "menu command is available"
        return 0
    else
        warning "menu command not found. Installing main menu..."
        
        # Download and install the main menu
        if wget -O menu_install.sh "https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/refs/heads/Test/install.sh"; then
            chmod +x menu_install.sh
            ./menu_install.sh
            rm menu_install.sh
            success "Main menu installed"
            return 0
        else
            error "Failed to install main menu"
            return 1
        fi
    fi
}

# Main installation function
main_install() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║        GTM Menu Installer            ║"
    echo "║           (Using wget)               ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "Starting installation..."
    
    # Install dependencies
    install_dependencies
    
    # Setup bin directory
    setup_bin_directory
    
    # Download scripts using wget
    download_select_sh
    download_gtm_sh
    
    # Create gtmmenu command
    create_gtmmenu_command
    
    # Fix menu command issue
    fix_menu_command
    
    # Final instructions
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║         INSTALLATION COMPLETE        ║"
    echo "║                                      ║"
    echo "║  To open the menu, type: gtmmenu     ║"
    echo "║  Or use: menu (if available)         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Reload bashrc
    source ~/.bashrc
    
    # Test the commands
    log "Testing commands..."
    if command -v gtmmenu &> /dev/null; then
        success "gtmmenu command is ready!"
    else
        warning "Please run: source ~/.bashrc"
    fi
}

# Run installation
main_install
