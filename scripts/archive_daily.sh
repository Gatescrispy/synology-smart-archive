#!/bin/bash

# Charger les fonctions communes et la configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
source "${SCRIPT_DIR}/../config/default.conf"

# Vérifier que le dossier source existe
if [ ! -d "$SYNOLOGY_DRIVE_PATH" ]; then
    log "ERROR" "Le dossier source n'existe pas: $SYNOLOGY_DRIVE_PATH"
    exit 1
 fi

# Acquérir le verrou
if ! acquire_lock; then
    exit 1
fi

# Vérifier l'espace disque
if ! check_disk_space "${MIN_DISK_SPACE}G" "$SYNOLOGY_DRIVE_PATH"; then
    log "ERROR" "Espace disque insuffisant (minimum ${MIN_DISK_SPACE}G requis)"
    exit 1
fi

# Créer le dossier d'archives si nécessaire
mkdir -p "$ARCHIVE_PATH"

# Construire les options d'exclusion pour find
build_find_options() {
    local options=""
    
    # Exclure les dossiers
    IFS=',' read -ra DIRS <<< "$EXCLUDED_DIRS"
    for dir in "${DIRS[@]}"; do
        options="$options -not -path '*/$dir/*'"
    done
    
    # Exclure les extensions
    IFS=',' read -ra EXTS <<< "$EXCLUDED_EXTENSIONS"
    for ext in "${EXTS[@]}"; do
        options="$options -not -name '*$ext'"
    done
    
    echo "$options"
}

# Rechercher les fichiers à archiver
log "INFO" "Recherche des fichiers plus vieux que $MIN_AGE_DAYS jours dans $SYNOLOGY_DRIVE_PATH"

# Construire la commande find avec les exclusions
find_cmd="find \"$SYNOLOGY_DRIVE_PATH\" -type f -mtime +\"$MIN_AGE_DAYS\" $(build_find_options) -print0"

# Compteurs
files_processed=0
errors=0
total_size=0

# Traiter les fichiers
while IFS= read -r -d '' file; do
    # Vérifier si le fichier existe toujours
    if [ ! -f "$file" ]; then
        continue
    fi
    
    # Calculer le chemin relatif
    relative_path=${file#$SYNOLOGY_DRIVE_PATH/}
    destination="$ARCHIVE_PATH/$relative_path"
    
    # Créer le dossier de destination
    mkdir -p "$(dirname "$destination")"
    
    # Déplacer le fichier
    if mv "$file" "$destination"; then
        size=$(stat -f %z "$destination")
        total_size=$((total_size + size))
        files_processed=$((files_processed + 1))
        log "SUCCESS" "Archivé: $relative_path ($(numfmt --to=iec-i --suffix=B --format="%.1f" $size))"
    else
        errors=$((errors + 1))
        log "ERROR" "Erreur lors de l'archivage de: $relative_path"
        if [ $errors -ge $MAX_ERRORS ]; then
            log "ERROR" "Trop d'erreurs rencontrées ($errors), arrêt de l'archivage"
            exit 1
        fi
    fi
done < <(eval "$find_cmd")

# Résultat final
if [ $files_processed -eq 0 ]; then
    log "INFO" "Aucun fichier trouvé à archiver"
else
    log "SUCCESS" "Archivage terminé avec succès"
    log "INFO" "Archivage terminé - Fichiers: $files_processed, Erreurs: $errors, Taille totale: $(numfmt --to=iec-i --suffix=B --format="%.1f" $total_size)"
fi

# Nettoyer les logs
cleanup_logs "$MAX_LOG_SIZE" "$LOG_RETENTION_DAYS" "$LOG_DIR"

exit 0