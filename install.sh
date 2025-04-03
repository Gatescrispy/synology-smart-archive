#!/bin/bash

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Installation de Synology Smart Archive${NC}"

# Vérification de l'OS
if [[ "$(uname)" != "Darwin" ]]; then
    echo -e "${RED}Ce script est uniquement compatible avec macOS${NC}"
    exit 1
fi