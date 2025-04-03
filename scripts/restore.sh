#!/bin/bash

# Import des fonctions communes
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"

# Chargement de la configuration
CONFIG_FILE="${SCRIPT_DIR}/../config/default.conf"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
else
    log "ERROR" "Fichier de configuration non trouvé: $CONFIG_FILE"
    exit 1
fi

# Fonction d'aide
show_help() {
    cat << EOF
Usage: $(basename "$0") [options] <chemin_fichier>

Options:
    -l, --list          Liste les fichiers archivés
    -r, --restore       Restaure un fichier spécifique
    -a, --restore-all   Restaure tous les fichiers archivés
    -h, --help          Affiche cette aide
    
Exemples:
    $(basename "$0") -l                          # Liste tous les fichiers archivés
    $(basename "$0") -r "Documents/rapport.pdf"  # Restaure un fichier spécifique
    $(basename "$0") -a                          # Restaure tous les fichiers
EOF
}

# Fonction de listage des fichiers archivés
list_archived_files() {
    log "INFO" "Liste des fichiers archivés:"
    find "$ARCHIVE_DIR" -type f -print0 | while IFS= read -r -d '' file; do
        local relative_path="${file#$ARCHIVE_DIR/}"
        local size=$(stat -f%z "$file")
        local modified=$(stat -f%Sm "$file")
        printf "%-50s %10d bytes  %s\n" "$relative_path" "$size" "$modified"
    done | sort
}

# Fonction de restauration d'un fichier
restore_file() {
    local relative_path="$1"
    local archive_path="$ARCHIVE_DIR/$relative_path"
    local original_path="$SOURCE_DIR/$relative_path"
    
    # Validation des chemins
    if ! validate_path "$archive_path"; then
        return 1
    fi
    
    if [[ ! -f "$archive_path" ]]; then
        log "ERROR" "Fichier non trouvé dans les archives: $relative_path"
        return 1
    fi
    
    # Suppression du lien symbolique s'il existe
    if [[ -L "$original_path" ]]; then
        rm "$original_path"
    fi
    
    # Création du répertoire parent si nécessaire
    mkdir -p "$(dirname "$original_path")"
    
    # Déplacement du fichier
    if mv "$archive_path" "$original_path"; then
        log "SUCCESS" "Fichier restauré: $relative_path"
        
        # Mise à jour des statistiques
        local file_size=$(stat -f%z "$original_path")
        update_stats "$file_size" "restore"
        
        return 0
    else
        log "ERROR" "Échec de la restauration: $relative_path"
        return 1
    fi
}

# Fonction de restauration de tous les fichiers
restore_all_files() {
    local error_count=0
    local restored_count=0
    
    log "INFO" "Début de la restauration complète"
    
    find "$ARCHIVE_DIR" -type f -print0 | while IFS= read -r -d '' file; do
        local relative_path="${file#$ARCHIVE_DIR/}"
        
        if restore_file "$relative_path"; then
            ((restored_count++))
        else
            ((error_count++))
            if (( error_count >= MAX_ERRORS )); then
                log "ERROR" "Nombre maximum d'erreurs atteint ($MAX_ERRORS)"
                return 1
            fi
        fi
    done
    
    log "INFO" "Restauration terminée"
    log "INFO" "Fichiers restaurés: $restored_count"
    log "INFO" "Erreurs rencontrées: $error_count"
    
    return $((error_count > 0))
}

# Traitement des arguments
case "$1" in
    -l|--list)
        list_archived_files
        ;;
    -r|--restore)
        if [[ -z "$2" ]]; then
            log "ERROR" "Chemin du fichier à restaurer non spécifié"
            show_help
            exit 1
        fi
        restore_file "$2"
        ;;
    -a|--restore-all)
        restore_all_files
        ;;
    -h|--help|*)
        show_help
        ;;
esac

exit $?