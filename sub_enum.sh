#!/bin/bash
# Passive Subdomain Enumeration Script
# Author: Sithum + BB 😎
# Usage: ./subenum.sh target.com

if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

DOMAIN=$1
OUTPUT_DIR="recon_$DOMAIN"
mkdir -p $OUTPUT_DIR

echo "[+] Starting passive subdomain enumeration for: $DOMAIN"

# --- Amass ---
if command -v amass &> /dev/null; then
    echo "[+] Running Amass (passive)"
    amass enum -passive -d $DOMAIN -o $OUTPUT_DIR/amass.txt
fi

# --- Subfinder ---
if command -v subfinder &> /dev/null; then
    echo "[+] Running Subfinder"
    subfinder -d $DOMAIN -all -silent -o $OUTPUT_DIR/subfinder.txt
fi

# --- Assetfinder ---
if command -v assetfinder &> /dev/null; then
    echo "[+] Running Assetfinder"
    assetfinder --subs-only $DOMAIN > $OUTPUT_DIR/assetfinder.txt
fi

# --- Findomain ---
if command -v findomain &> /dev/null; then
    echo "[+] Running Findomain"
    findomain -t $DOMAIN -u $OUTPUT_DIR/findomain.txt
fi

# --- crt.sh ---
echo "[+] Pulling from crt.sh"
curl -s "https://crt.sh/?q=%25.$DOMAIN&output=json" \
| jq -r '.[].name_value' 2>/dev/null \
| sed 's/\*\.//g' | sed 's/^\.//' | sort -u > $OUTPUT_DIR/crtsh.txt

# --- SecurityTrails (requires API key) ---
if [ ! -z "$SECURITYTRAILS_API_KEY" ]; then
    echo "[+] Pulling from SecurityTrails"
    curl -s "https://api.securitytrails.com/v1/domain/$DOMAIN/subdomains" \
    -H "APIKEY: $SECURITYTRAILS_API_KEY" \
    | jq -r '.subdomains[]' | sed "s/$/.$DOMAIN/" > $OUTPUT_DIR/securitytrails.txt
fi

# --- Chaos (ProjectDiscovery) ---
if command -v chaos &> /dev/null; then
    echo "[+] Running Chaos (ProjectDiscovery)"
    chaos -d $DOMAIN -silent -o $OUTPUT_DIR/chaos.txt
fi

# --- Combine Results ---
echo "[+] Combining and cleaning results..."
cat $OUTPUT_DIR/*.txt 2>/dev/null | sort -u > $OUTPUT_DIR/all_subdomains.txt

echo "[+] Finished! All subdomains saved in: $OUTPUT_DIR/all_subdomains.txt"
wc -l $OUTPUT_DIR/all_subdomains.txt
