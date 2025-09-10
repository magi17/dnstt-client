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
SELECT_BIN="$HOME/bin/select.sh"

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

# Function to install menu
install_menu() {
    log "Installing menu..."
    
    # Install curl if not available
    if ! command -v curl &> /dev/null; then
        log "Installing curl..."
        apt update && apt install curl -y
    fi
    
    # Download and install menu
    if curl -o install.sh "https://raw.githubusercontent.com/Jhon-mark23/Termux-beta/refs/heads/Test/install.sh"; then
        chmod +x install.sh
        ./install.sh
        rm install.sh
        success "Menu installation completed!"
        return 0
    else
        error "Failed to download menu installer!"
        return 1
    fi
}

# Function to download gtm.sh if not found
download_gtm() {
    log "Downloading gtm.sh..."
    
    # Download to current directory
    if curl -o "$GTM_LOCAL" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/gtm.sh"; then
        chmod +x "$GTM_LOCAL"
        success "gtm.sh downloaded successfully!"
        return 0
    else
        error "Failed to download gtm.sh!"
        return 1
    fi
}

# Function to move gtm.sh to bin
hide_gtm() {
    log "Moving gtm.sh to ~/bin/ to hide it..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$HOME/bin"
    
    # Move and make executable
    if mv "$GTM_LOCAL" "$GTM_BIN" && chmod +x "$GTM_BIN"; then
        success "gtm.sh hidden in ~/bin/"
        return 0
    else
        error "Failed to move gtm.sh to ~/bin/"
        return 1
    fi
}

# Function to check if menu exists
check_menu() {
    if [[ ! -f "/data/data/com.termux/files/usr/bin/menu" ]]; then
        warning "Menu not found."
        return 1
    else
        success "Menu file exists"
        return 0
    fi
}

# Function to check if gtm.sh exists (in either location)
check_gtm() {
    # Check local directory first
    if [[ -f "$GTM_LOCAL" ]]; then
        success "gtm.sh found in current directory"
        
        # Ask if user wants to hide it
        read -p "Do you want to hide gtm.sh in ~/bin/? (y/n): " answer
        case $answer in
            [Yy]*)
                if hide_gtm; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                return 0
                ;;
        esac
    
    # Check if hidden in bin
    elif [[ -f "$GTM_BIN" ]]; then
        success "gtm.sh found in ~/bin/"
        return 0
    
    # Not found anywhere
    else
        warning "gtm.sh not found!"
        
        # Ask user if they want to download it
        read -p "Do you want to download gtm.sh? (y/n): " answer
        case $answer in
            [Yy]*)
                if download_gtm; then
                    return 0
                else
                    return 1
                fi
                ;;
            *)
                error "Please make sure gtm.sh is available."
                return 1
                ;;
        esac
    fi
}

# Function to run gtm.sh (from wherever it is)
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
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        warning "curl not found. Installing..."
        apt update && apt install curl -y
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
    echo -e "1) GTM DNSTT"
    echo -e "2) GTM OVPN+DNSTT"    
    echo -e "3) Install Requirements"
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
                warning "Menu not found. Installing now..."
                if install_menu; then
                    log "Starting menu..."
                    menu
                else
                    error "Menu installation failed. Please try manual installation."
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
            # Install requirements
            check_requirements
            read -p "Requirements installed. Press Enter to continue..."
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
