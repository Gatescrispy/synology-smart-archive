#!/bin/bash

# Fonction pour convertir les tailles en octets
convert_to_bytes() {
    local size=$1
    local unit=${size: -1}
    local value=${size%?}
    
    case $unit in
        K) echo $((value * 1024));;
        M) echo $((value * 1024 * 1024));;
        G) echo $((value * 1024 * 1024 * 1024));;
        *) echo $size;;
    esac
}

# Fonction pour vérifier l'espace disque
check_disk_space() {
    local required_space=$1
    local path=$2
    
    # Convertir la taille requise en octets
    local required_bytes=$(convert_to_bytes "$required_space")
    
    # Récupérer l'espace disponible
    local available_space=$(df -B1 "$path" | awk 'NR==2 {print $4}')
    
    if [ $available_space -lt $required_bytes ]; then
        return 1
    fi
    return 0
}

# Fonction pour la gestion des verrous
acquire_lock() {
    local lock_file="/tmp/synology_archive.lock"
    
    # Vérifier si le verrou existe
    if [ -f "$lock_file" ]; then
        local pid=$(cat "$lock_file")
        if [ -d "/proc/$pid" ]; then
            log "ERROR" "Une autre instance du script est en cours d'exécution"
            return 1
        fi
    fi
    
    # Créer le verrou
    echo $$ > "$lock_file"
    
    # Nettoyer le verrou à la sortie
    trap "rm -f $lock_file" EXIT
    
    return 0
}

# Fonction de logging
log() {
    local level=$1
    local message=$2
    local timestamp=$(date +'%Y-%m-%d %H:%M:%S')
    local log_file="logs/archive.log"
    
    # Créer le dossier de logs si nécessaire
    mkdir -p "$(dirname "$log_file")"
    
    # Formater le message en JSON
    echo "{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}" >> "$log_file"
    
    # Afficher aussi dans la console
    echo "[$timestamp] $level $message"
}

# Fonction pour nettoyer les anciens logs
cleanup_logs() {
    local max_size=$1
    local retention_days=$2
    local log_dir=$3
    
    # Supprimer les logs plus vieux que retention_days jours
    find "$log_dir" -name "*.log" -type f -mtime +"$retention_days" -delete
    
    # Vérifier la taille des fichiers de log
    local log_size=$(du -sb "$log_dir" 2>/dev/null | cut -f1)
    local max_bytes=$(convert_to_bytes "$max_size")
    
    if [ -n "$log_size" ] && [ "$log_size" -gt "$max_bytes" ]; then
        # Garder seulement les derniers logs
        for log_file in $(find "$log_dir" -name "*.log" -type f -printf '%T@ %p\n' | sort -n | head -n -10 | cut -d' ' -f2-); do
            rm -f "$log_file"
        done
    fi
}