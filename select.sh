#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Paths
GTM_LOCAL="gtm.sh"
GTM_BIN="$HOME/bin/gtm.sh"

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
    echo -e "${YELLOW}[!]${NC} $1
}

# Function to install menu using wget
install_menu() {
    log "Installing menu using wget..."
    
    # Install wget if not available
    if ! command -v wget &> /dev/null; then
        log "Installing wget..."
        pkg install wget -y
    fi
    
    # Download and install menu using wget
    if wget -O menu_install.sh "https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/refs/heads/Test/install.sh"; then
        chmod +x menu_install.sh
        ./menu_install.sh
        rm menu_install.sh
        
        # Verify menu installation
        if command -v menu &> /dev/null; then
            success "Menu installation completed!"
            return 0
        else
            error "Menu installed but command not found!"
            return 1
        fi
    else
        error "Failed to download menu installer!"
        return 1
    fi
}

# Function to download gtm.sh using wget
download_gtm() {
    log "Downloading gtm.sh using wget..."
    
    # Download to current directory
    if wget -O "$GTM_LOCAL" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/gtm.sh"; then
        chmod +x "$GTM_LOCAL"
        success "gtm.sh downloaded successfully!"
        return 0
    else
        error "Failed to download gtm.sh!"
        return 1
    fi
}

# Function to check if menu exists and works
check_menu() {
    if command -v menu &> /dev/null; then
        # Test if menu command actually works
        if timeout 2s menu --help > /dev/null 2>&1; then
            success "Menu command is working"
            return 0
        else
            warning "Menu command exists but may not be functioning properly"
            return 1
        fi
    else
        warning "Menu command not found."
        return 1
    fi
}

# Function to check if gtm.sh exists
check_gtm() {
    if [[ -f "$GTM_LOCAL" ]]; then
        success "gtm.sh found in current directory"
        return 0
    elif [[ -f "$GTM_BIN" ]]; then
        success "gtm.sh found in ~/bin/"
        return 0
    else
        warning "gtm.sh not found!"
        return 1
    fi
}

# Function to run gtm.sh
run_gtm() {
    if [[ -f "$GTM_LOCAL" ]]; then
        log "Running gtm.sh from current directory..."
        bash "$GTM_LOCAL"
    elif [[ -f "$GTM_BIN" ]]; then
        log "Running gtm.sh from ~/bin/"
        bash "$GTM_BIN"
    else
        error "gtm.sh not found in any location!"
        return 1
    fi
}

# Function to check and install requirements
check_requirements() {
    log "Checking requirements..."
    
    # Check if wget is available
    if ! command -v wget &> /dev/null; then
        warning "wget not found. Installing..."
        pkg install wget -y
    fi
    
    # Check if ~/bin is in PATH
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        log "Adding ~/bin to PATH..."
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/bin:$PATH"
        success "Added ~/bin to PATH"
    fi
    
    success "Requirements satisfied"
}

# Function to display header
display_header() {
    clear
    echo -e "${CYAN}"
    echo "╔══════════════════════════════════════╗"
    echo "║           SELECTION MENU             ║"
    echo "║      GTM Tunnel Manager v2.0         ║"
    echo "╚══════════════════════════════════════╝"
    echo -e "${NC}"
}

# Main menu loop
while true; do
    display_header
    
    echo -e "${CYAN}=== Main Menu ==="
    echo -e "1) GTM DNSTT (Menu)"
    echo -e "2) GTM OVPN+DNSTT (gtm.sh)"    
    echo -e "3) Install/Repair Menu"
    echo -e "4) Exit"
    echo -e "=================${NC}"
    
    read -p "Enter your choice (1-4): " choice

    case $choice in
        1)
            # Check requirements first
            check_requirements
            
            # Check and install menu if not found, then run it
            if check_menu; then
                log "Starting menu..."
                menu
            else
                warning "Menu not found or not working. Installing now..."
                if install_menu; then
                    log "Starting menu..."
                    menu
                else
                    error "Menu installation failed."
                    read -p "Press Enter to continue..."
                fi
            fi
            ;;

        2)
            # Check requirements first
            check_requirements
            
            # Check if gtm.sh exists before running
            if check_gtm; then
                run_gtm
            else
                read -p "Press Enter to continue..."
            fi
            ;;

        3)
            # Install/repair menu
            log "Installing/repairing menu..."
            if install_menu; then
                success "Menu installed/repaired successfully"
            else
                error "Menu installation failed"
            fi
            read -p "Press Enter to continue..."
            ;;

        4)
            clear
            echo -e "${GREEN}Goodbye!${NC}"
            exit 0
            ;;

        *)
            error "Invalid choice. Please enter 1-4."
            sleep 2
            ;;
    esac
done
