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

# Vérification du processus
if ! check_process_running "archive_daily"; then
    log "ERROR" "Une autre instance du script est en cours d'exécution"
    exit 1
fi

# Fonction de nettoyage à la sortie
trap 'cleanup "archive_daily"' EXIT

# Création des répertoires nécessaires
mkdir -p "$LOG_DIR" "$ARCHIVE_DIR"

# Vérification de l'espace disque
if ! check_disk_space "$ARCHIVE_DIR"; then
    log "ERROR" "Espace disque insuffisant"
    exit 1
fi

# Fonction d'archivage d'un fichier
archive_file() {
    local file="$1"
    local relative_path="${file#$SOURCE_DIR/}"
    local archive_path="$ARCHIVE_DIR/$relative_path"
    local archive_dir="$(dirname "$archive_path")"
    
    # Validation du chemin
    if ! validate_path "$file"; then
        return 1
    fi
    
    # Vérification des extensions exclues
    for ext in $EXCLUDED_EXTENSIONS; do
        if [[ "$file" == *"$ext" ]]; then
            log "INFO" "Fichier ignoré (extension exclue): $file"
            return 0
        fi
    done
    
    # Création du répertoire d'archive si nécessaire
    mkdir -p "$archive_dir"
    
    # Déplacement du fichier
    if mv "$file" "$archive_path"; then
        # Création du lien symbolique
        ln -s "$archive_path" "$file"
        
        # Mise à jour des statistiques
        local file_size=$(stat -f%z "$archive_path")
        update_stats "$file_size" "archive"
        
        log "SUCCESS" "Fichier archivé: $file -> $archive_path"
        return 0
    else
        log "ERROR" "Échec de l'archivage: $file"
        return 1
    fi
}

# Fonction principale
main() {
    local error_count=0
    local processed_files=0
    local start_time=$(date +%s)
    
    log "INFO" "Début de l'archivage"
    
    # Recherche des fichiers à archiver
    while IFS= read -r -d '' file; do
        if (( error_count >= MAX_ERRORS )); then
            log "ERROR" "Nombre maximum d'erreurs atteint ($MAX_ERRORS)"
            return 1
        fi
        
        if ! archive_file "$file"; then
            ((error_count++))
        fi
        ((processed_files++))
        
    done < <(find "$SOURCE_DIR" -type f -not -path "*/archives/*" -atime "+$MIN_AGE_DAYS" -print0)
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Rapport final
    log "INFO" "Archivage terminé en $duration secondes"
    log "INFO" "Fichiers traités: $processed_files"
    log "INFO" "Erreurs rencontrées: $error_count"
    
    # Nettoyage des anciens logs
    find "$LOG_DIR" -name "*.gz" -mtime "+$LOG_RETENTION_DAYS" -delete
    
    return $((error_count > 0))
}

# Exécution
main
exit $?