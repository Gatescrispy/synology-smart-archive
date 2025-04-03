#!/bin/bash

# Configuration
SOURCE_DIR="$HOME/SynologyDrive"
ARCHIVE_DIR="$SOURCE_DIR/archives"
LOCK_FILE="/tmp/synology_archive.lock"
LOG_FILE="$SOURCE_DIR/.archive_log.txt"
MIN_AGE_DAYS=180
ERROR_COUNT=0
MAX_ERRORS=5

# Fonction de logging
log() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$LOG_FILE"
}

# Vérification du verrou
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE")
    if ps -p "$pid" > /dev/null; then
        log "ERROR: Une autre instance est en cours d'exécution (PID: $pid)"
        exit 1
    else
        log "WARNING: Verrou obsolète détecté, suppression..."
        rm "$LOCK_FILE"
    fi
fi

# Création du verrou
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"' EXIT

# Vérification que Synology Drive Client est en cours d'exécution
if ! pgrep "Synology Drive Client" > /dev/null; then
    log "ERROR: Synology Drive Client n'est pas en cours d'exécution"
    exit 1
fi

# Vérification de l'espace disque
check_disk_space() {
    local min_space=5  # Go minimum requis
    local available=$(df -h "$SOURCE_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    if (( $(echo "$available < $min_space" | bc -l) )); then
        log "ERROR: Espace disque insuffisant ($available Go)"
        return 1
    fi
    return 0
}

# Fonction d'archivage
archive_file() {
    local file="$1"
    local relative_path="${file#$SOURCE_DIR/}"
    local archive_path="$ARCHIVE_DIR/$relative_path"
    local archive_dir=$(dirname "$archive_path")
    
    # Vérification si le fichier est en cours d'utilisation
    if lsof "$file" > /dev/null 2>&1; then
        log "WARNING: Fichier en cours d'utilisation, ignoré: $file"
        return 1
    }
    
    # Création du dossier d'archive si nécessaire
    if ! mkdir -p "$archive_dir"; then
        log "ERROR: Impossible de créer le dossier: $archive_dir"
        ((ERROR_COUNT++))
        return 1
    }
    
    # Déplacement du fichier
    if ! mv "$file" "$archive_path"; then
        log "ERROR: Impossible de déplacer le fichier: $file"
        ((ERROR_COUNT++))
        return 1
    }
    
    # Création du lien symbolique
    if ! ln -s "$archive_path" "$file"; then
        log "ERROR: Impossible de créer le lien symbolique pour: $file"
        # Tentative de restauration
        mv "$archive_path" "$file"
        ((ERROR_COUNT++))
        return 1
    }
    
    log "SUCCESS: Archivé: $file -> $archive_path"
    return 0
}

# Vérification de l'espace disque
check_disk_space || exit 1

# Création du dossier d'archive
mkdir -p "$ARCHIVE_DIR"

log "DÉBUT de l'archivage"

# Recherche et traitement des fichiers
find "$SOURCE_DIR" -type f -not -path "*/archives/*" -not -path "*/.*" -atime +$MIN_AGE_DAYS -print0 | while IFS= read -r -d '' file; do
    archive_file "$file"
    
    if [ $ERROR_COUNT -ge $MAX_ERRORS ]; then
        log "ERROR: Trop d'erreurs rencontrées ($ERROR_COUNT), arrêt..."
        exit 1
    fi
done

# Bilan
if [ $ERROR_COUNT -eq 0 ]; then
    log "FIN: Archivage terminé avec succès"
else
    log "FIN: Archivage terminé avec $ERROR_COUNT erreur(s)"
fi

exit $ERROR_COUNT