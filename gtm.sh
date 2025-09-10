#!/bin/bash

# === CONFIG FILE ===
CONFIG_FILE="slowdns_config.conf"

# === DEFAULT VALUES ===
DNS_SERVER="124.6.181.25"
NS="arjienx.kagerou.site"
PUBKEY="93cbf61c1fc56446dae86d509f438742de751d0bb305c37603f2690730f94554"
PORT="8888"

# === DNSTT-CLIENT PATH ===
DNSTT_CLIENT="$HOME/bin/dnstt-client"

# === COLORS FOR OUTPUT ===
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# === LOGGING FUNCTION ===
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

# === LOAD CONFIG IF EXISTS ===
load_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        source "$CONFIG_FILE"
        log "Loaded configuration from $CONFIG_FILE"
    else
        log "Using default configuration"
    fi
}

# === SAVE CONFIG ===
save_config() {
    cat > "$CONFIG_FILE" << EOF
#!/bin/bash

# === SLOWDNS CONFIGURATION ===
DNS_SERVER="$DNS_SERVER"
NS="$NS"
PUBKEY="$PUBKEY"
PORT="$PORT"
EOF
    log "Configuration saved to $CONFIG_FILE"
}

# === CHECK AND INSTALL DNSTT-CLIENT IF NEEDED ===
check_dnstt_client() {
    if [[ -f "$DNSTT_CLIENT" && -x "$DNSTT_CLIENT" ]]; then
        log "dnstt-client found in ~/bin/"
        return 0
    fi
    
    warning "dnstt-client not found or not executable in ~/bin/"
    log "Attempting to download dnstt-client..."
    
    # Create bin directory if it doesn't exist
    mkdir -p "$HOME/bin"
    
    # Check if wget or curl is available
    if command -v wget &> /dev/null; then
        log "Using wget to download dnstt-client..."
        if wget -O "$DNSTT_CLIENT" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/dnstt-client"; then
            chmod +x "$DNSTT_CLIENT"
            success "dnstt-client installed successfully using wget"
        else
            error "Failed to download dnstt-client using wget"
            return 1
        fi
    elif command -v curl &> /dev/null; then
        log "Using curl to download dnstt-client..."
        if curl -o "$DNSTT_CLIENT" "https://github.com/magi17/dnstt-client/raw/refs/heads/main/dnstt-client"; then
            chmod +x "$DNSTT_CLIENT"
            success "dnstt-client installed successfully using curl"
        else
            error "Failed to download dnstt-client using curl"
            return 1
        fi
    else
        error "Neither wget nor curl is available. Please install one of them:"
        echo "  pkg install wget -y"
        echo "  pkg install curl -y"
        return 1
    fi
    
    # Add to PATH if not already there
    if [[ ":$PATH:" != *":$HOME/bin:"* ]]; then
        echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/bin:$PATH"
        log "Added ~/bin to PATH"
    fi
    
    # Verify the download
    if [[ -x "$DNSTT_CLIENT" ]]; then
        log "Testing dnstt-client..."
        timeout 3s "$DNSTT_CLIENT" --help > /dev/null 2>&1
        if [[ $? -eq 0 || $? -eq 124 ]]; then
            success "dnstt-client is working correctly"
            return 0
        else
            error "dnstt-client test failed"
            return 1
        fi
    else
        error "Downloaded file is not executable"
        return 1
    fi
}

# === DISPLAY CURRENT CONFIG ===
show_config() {
    echo ""
    echo "=== CURRENT CONFIGURATION ==="
    echo "1) DNS Server: $DNS_SERVER"
    echo "2) Nameserver: $NS"
    echo "3) Public Key: $PUBKEY"
    echo "4) Port: $PORT"
    echo "=============================="
    echo ""
}

# === EDIT CONFIG MENU ===
edit_config() {
    while true; do
        show_config
        echo "=== EDIT MENU ==="
        echo "1) Change DNS Server"
        echo "2) Change Nameserver"
        echo "3) Change Public Key"
        echo "4) Change Port"
        echo "5) Save and Back to Main Menu"
        echo "6) Back to Main Menu (Discard Changes)"
        echo "================="
        
        read -p "Select option (1-6): " choice
        
        case $choice in
            1)
                read -p "Enter new DNS Server: " new_dns
                DNS_SERVER="$new_dns"
                log "DNS Server updated to: $DNS_SERVER"
                ;;
            2)
                read -p "Enter new Nameserver: " new_ns
                NS="$new_ns"
                log "Nameserver updated to: $NS"
                ;;
            3)
                read -p "Enter new Public Key: " new_pubkey
                PUBKEY="$new_pubkey"
                log "Public Key updated"
                ;;
            4)
                read -p "Enter new Port: " new_port
                if [[ $new_port =~ ^[0-9]+$ ]] && [ $new_port -ge 1 ] && [ $new_port -le 65535 ]; then
                    PORT="$new_port"
                    log "Port updated to: $PORT"
                else
                    error "Invalid port number! Must be between 1-65535"
                fi
                ;;
            5)
                save_config
                success "Changes saved successfully!"
                sleep 2
                return
                ;;
            6)
                log "Changes discarded"
                load_config  # Reload original config
                sleep 2
                return
                ;;
            *)
                error "Invalid option! Please choose 1-6"
                sleep 2
                ;;
        esac
    done
}

# === START TUNNEL ===
start_tunnel() {
    clear 
    echo ""
    log "Starting SlowDNS using configuration:"
    echo "    DNS Server: $DNS_SERVER"
    echo "    Nameserver: $NS"
    echo "    Port: $PORT"
    echo ""
    
    # Check if dnstt-client exists, install if needed
    if ! check_dnstt_client; then
        error "dnstt-client not available!"
        error "Please check your internet connection and try again"
        return 1
    fi
    
    # Start the tunnel using the hidden dnstt-client
    log "Starting tunnel with hidden dnstt-client..."
    "$DNSTT_CLIENT" -udp "$DNS_SERVER:53" -pubkey "$PUBKEY" "$NS" "127.0.0.1:$PORT"
}

# === AUTO START FUNCTION ===
auto_start() {
    log "Auto-starting SlowDNS tunnel..."
    sleep 2
    start_tunnel
}

# === INSTALL REQUIRED PACKAGES ===
install_requirements() {
    log "Checking for required packages..."
    
    if ! command -v wget &> /dev/null && ! command -v curl &> /dev/null; then
        warning "Neither wget nor curl found. Installing wget..."
        pkg install wget -y
    fi
    
    success "All requirements are satisfied"
}

# === MAIN MENU ===
main_menu() {
    load_config
    
    # Check if auto-start argument is provided
    if [[ "$1" == "start" ]] || [[ "$1" == "1" ]]; then
        auto_start
        exit 0
    fi
    
    while true; do
        clear
        echo "=== SLOWDNS MANAGER ==="
        echo "1) Start SlowDNS Tunnel"
        echo "2) Show Current Configuration"
        echo "3) Edit Configuration"
        echo "4) Save Configuration"
        echo "5) Install Requirements"
        echo "6) Exit"
        echo "======================="
        
        read -p "Select option (1-6): " choice
        
        case $choice in
            1|start)
                start_tunnel
                read -p "Press Enter to continue..."
                ;;
            2|config)
                show_config
                read -p "Press Enter to continue..."
                ;;
            3|edit)
                edit_config
                ;;
            4|save)
                save_config
                read -p "Press Enter to continue..."
                ;;
            5|install)
                install_requirements
                read -p "Press Enter to continue..."
                ;;
            6|exit|quit)
                log "Goodbye!"
                exit 0
                ;;
            *)
                start_tunnel
                ;;
        esac
    done
}

# === CHECK FOR AUTO-START PARAMETERS ===
if [[ $# -gt 0 ]]; then
    case $1 in
        start|1)
            load_config
            auto_start
            exit 0
            ;;
        edit|config|2|3)
            # Just continue to main menu
            ;;
        install|5)
            install_requirements
            exit 0
            ;;
        *)
            echo "Usage: $0 [start|1|install|5]"
            echo "  start or 1 - Auto-start the tunnel"
            echo "  install or 5 - Install required packages"
            echo "  no args - Show menu"
            exit 1
            ;;
    esac
fi

# === START PROGRAM ===
install_requirements
main_menu "$@"
