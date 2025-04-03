#!/bin/bash

# Configuration des couleurs pour les logs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration des logs
LOG_DIR="logs"
MAIN_LOG="${LOG_DIR}/archive.log"
ERROR_LOG="${LOG_DIR}/error.log"
MAX_LOG_SIZE=10485760 # 10MB

# Fonction de rotation des logs
rotate_logs() {
    local log_file="$1"
    if [[ -f "$log_file" ]] && [[ $(stat -f%z "$log_file") -gt $MAX_LOG_SIZE ]]; then
        mv "$log_file" "${log_file}.$(date +%Y%m%d_%H%M%S)"
        gzip "${log_file}.$(date +%Y%m%d_%H%M%S)"
    fi
}

# Fonction de logging améliorée
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local json_message="{\"timestamp\":\"$timestamp\",\"level\":\"$level\",\"message\":\"$message\"}"
    
    # Rotation des logs si nécessaire
    rotate_logs "$MAIN_LOG"
    rotate_logs "$ERROR_LOG"
    
    # Log dans le fichier principal
    echo "$json_message" >> "$MAIN_LOG"
    
    # Log les erreurs séparément
    if [[ "$level" == "ERROR" ]]; then
        echo "$json_message" >> "$ERROR_LOG"
    fi
    
    # Affichage console avec couleurs
    case "$level" in
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message" >&2
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        *)
            echo "[INFO] $message"
            ;;
    esac
}

# Fonction de validation des chemins
validate_path() {
    local path="$1"
    
    # Vérification des caractères dangereux
    if [[ "$path" =~ [[:cntrl:]] || "$path" =~ [\'\"\\\ ] ]]; then
        log "ERROR" "Chemin invalide détecté: $path"
        return 1
    fi
    
    # Vérification des permissions
    if [[ ! -r "$path" ]]; then
        log "ERROR" "Permissions insuffisantes pour lire: $path"
        return 1
    fi
    
    return 0
}

# Fonction de vérification d'espace disque
check_disk_space() {
    local dir="$1"
    local min_space=5242880 # 5GB en KB
    
    local available_space=$(df -k "$dir" | awk 'NR==2 {print $4}')
    
    if [[ $available_space -lt $min_space ]]; then
        log "ERROR" "Espace disque insuffisant dans $dir: $available_space KB disponible"
        return 1
    fi
    
    return 0
}

# Fonction de statistiques
update_stats() {
    local file_size="$1"
    local action="$2"
    local stats_file="logs/stats.json"
    
    # Création du fichier de stats s'il n'existe pas
    if [[ ! -f "$stats_file" ]]; then
        echo '{"total_files":0,"total_size":0,"last_run":""}' > "$stats_file"
    fi
    
    # Mise à jour des statistiques
    local total_files=$(jq '.total_files + 1' "$stats_file")
    local total_size=$(jq ".total_size + $file_size" "$stats_file")
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    jq --arg ts "$timestamp" \
       --argjson tf "$total_files" \
       --argjson ts "$total_size" \
       '.total_files = $tf | .total_size = $ts | .last_run = $ts' \
       "$stats_file" > "${stats_file}.tmp" && mv "${stats_file}.tmp" "$stats_file"
}

# Fonction de vérification de processus
check_process_running() {
    local script_name="$1"
    local pid_file="/tmp/${script_name}.pid"
    
    # Vérification si le fichier PID existe
    if [[ -f "$pid_file" ]]; then
        local pid=$(cat "$pid_file")
        if ps -p "$pid" > /dev/null; then
            log "WARNING" "Une instance est déjà en cours d'exécution (PID: $pid)"
            return 1
        fi
    fi
    
    # Création du fichier PID
    echo $$ > "$pid_file"
    return 0
}

# Fonction de nettoyage
cleanup() {
    local script_name="$1"
    rm -f "/tmp/${script_name}.pid"
    log "INFO" "Nettoyage effectué"
}