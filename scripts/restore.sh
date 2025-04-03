#!/bin/bash

# Charger les fonctions communes et la configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/../config/default.conf"

# Fonction pour restaurer un fichier
restore_file() {
    local archive_path=$1
    local original_path=$2
    
    # Vérifier que le fichier existe dans les archives
    if [ ! -f "$archive_path" ]; then
        log "ERROR" "Fichier non trouvé dans les archives: $archive_path"
        return 1
    fi
    
    # Créer le dossier de destination si nécessaire
    mkdir -p "$(dirname "$original_path")"
    
    # Déplacer le fichier
    if mv "$archive_path" "$original_path"; then
        log "SUCCESS" "Restauré: $original_path"
        return 0
    else
        log "ERROR" "Erreur lors de la restauration de: $original_path"
        return 1
    fi
}

# Fonction principale
main() {
    local file_path=$1
    
    if [ -z "$file_path" ]; then
        log "ERROR" "Chemin du fichier à restaurer non spécifié"
        exit 1
    fi
    
    # Construire les chemins
    local archive_path="$ARCHIVE_PATH/$file_path"
    local original_path="$SYNOLOGY_DRIVE_PATH/$file_path"
    
    # Restaurer le fichier
    if restore_file "$archive_path" "$original_path"; then
        exit 0
    else
        exit 1
    fi
}

# Exécuter la restauration
main "$1"