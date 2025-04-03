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