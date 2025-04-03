// Fonction pour afficher les notifications
function showNotification(type, message) {
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.textContent = message;
    
    document.body.appendChild(notification);
    
    setTimeout(() => notification.classList.add('show'), 100);
    
    setTimeout(() => {
        notification.classList.remove('show');
        setTimeout(() => notification.remove(), 300);
    }, 5000);
}

// Fonction pour formater la taille des fichiers
function formatFileSize(bytes) {
    if (bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// Fonction pour démarrer l'archivage
async function startArchive() {
    const archiveBtn = document.getElementById('archive-button');
    const originalText = archiveBtn.textContent;
    archiveBtn.textContent = 'Archivage en cours...';
    archiveBtn.disabled = true;

    try {
        const controller = new AbortController();
        const timeout = setTimeout(() => controller.abort(), 30000);

        const response = await fetch('/api/archive', {
            method: 'POST',
            signal: controller.signal
        });

        clearTimeout(timeout);
        
        if (!response.ok) {
            if (response.status === 504 || response.status === 408) {
                throw new Error('L\'opération a pris trop de temps');
            }
            const data = await response.json();
            throw new Error(data.message || 'Erreur lors de l\'archivage');
        }
        
        const data = await response.json();
        
        if (data.message && data.message.includes('Aucun fichier')) {
            showNotification('info', 'Aucun fichier à archiver pour le moment');
        } else {
            showNotification('success', data.message || 'Archivage terminé avec succès');
        }
        
    } catch (error) {
        console.error('Erreur:', error);
        if (error.name === 'AbortError') {
            showNotification('error', 'L\'opération a pris trop de temps, veuillez réessayer');
        } else {
            showNotification('error', error.message || 'Erreur lors de l\'archivage');
        }
    } finally {
        updateStats();
        updateLogs();
        
        archiveBtn.textContent = originalText;
        archiveBtn.disabled = false;
    }
}

// Fonction pour restaurer un fichier
async function restoreFile(path) {
    try {
        const response = await fetch('/api/restore', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({ path })
        });
        const data = await response.json();
        
        if (data.success) {
            showNotification('success', 'Fichier restauré avec succès');
        } else {
            showNotification('error', data.error || 'Erreur lors de la restauration');
        }
    } catch (error) {
        showNotification('error', 'Erreur lors de la communication avec le serveur');
    }
}

// Fonction pour mettre à jour les statistiques
function updateStats() {
    fetch('/api/stats')
        .then(response => response.json())
        .then(data => {
            document.getElementById('files-count').textContent = data.files_archived;
            document.getElementById('space-saved').textContent = data.space_saved;
            document.getElementById('last-run').textContent = data.last_run;
        })
        .catch(error => console.error('Erreur lors de la mise à jour des stats:', error));
}

// Fonction pour mettre à jour les logs
function updateLogs() {
    fetch('/api/logs')
        .then(response => response.json())
        .then(data => {
            const logsContainer = document.getElementById('logs');
            logsContainer.innerHTML = '';
            
            data.logs.reverse().forEach(log => {
                const logEntry = document.createElement('div');
                logEntry.className = `log-entry ${log.level.toLowerCase()}`;
                
                let message = log.message;
                if (log.level === 'SUCCESS' && message.includes('Archivé:')) {
                    const parts = message.split('(');
                    const path = parts[0].replace('Archivé:', '').trim();
                    const size = parts[1].replace(')', '').trim();
                    message = `<strong>Archivé:</strong> ${path} <span class="file-size">(${size})</span>`;
                }
                
                logEntry.innerHTML = `
                    <span class="timestamp">[${log.timestamp}]</span>
                    <span class="level ${log.level.toLowerCase()}">${log.level}</span>
                    <span class="message">${message}</span>
                `;
                
                logsContainer.appendChild(logEntry);
            });
        })
        .catch(error => console.error('Erreur lors de la mise à jour des logs:', error));
}

// Fonction pour afficher/cacher la liste des fichiers
function toggleFiles() {
    const filesSection = document.getElementById('files-section');
    const filesButton = document.getElementById('show-files-button');
    const filesTable = document.getElementById('files-tbody');
    const searchInput = document.getElementById('search-input');
    
    if (!filesSection.classList.contains('hidden')) {
        filesSection.classList.add('hidden');
        filesButton.textContent = filesButton.dataset.showText;
        return;
    }
    
    filesSection.classList.remove('hidden');
    filesButton.textContent = filesButton.dataset.hideText;
    
    fetch('/api/files')
        .then(response => response.json())
        .then(data => {
            if (data.error) {
                showNotification('error', data.error);
                return;
            }
            
            filesTable.innerHTML = '';
            
            if (!data.files || data.files.length === 0) {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td colspan="4" class="px-6 py-4 text-center text-gray-500">
                        Aucun fichier archivé
                    </td>
                `;
                filesTable.appendChild(row);
                return;
            }
            
            data.files.forEach(file => {
                const row = document.createElement('tr');
                row.innerHTML = `
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-900">${file.name}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${formatFileSize(file.size)}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${file.date}</td>
                    <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                        <button onclick="restoreFile('${file.name}')" 
                                class="text-indigo-600 hover:text-indigo-900 bg-transparent border border-indigo-600 px-3 py-1 rounded">
                            Restaurer
                        </button>
                    </td>
                `;
                filesTable.appendChild(row);
            });
            
            if (searchInput) {
                searchInput.value = '';
                searchInput.addEventListener('input', (e) => {
                    const searchTerm = e.target.value.toLowerCase();
                    const rows = filesTable.getElementsByTagName('tr');
                    
                    Array.from(rows).forEach(row => {
                        const fileName = row.cells[0]?.textContent.toLowerCase() || '';
                        row.style.display = fileName.includes(searchTerm) ? '' : 'none';
                    });
                });
            }
        })
        .catch(error => {
            console.error('Erreur:', error);
            showNotification('error', 'Erreur lors du chargement des fichiers');
        });
}

// Initialisation des événements
document.addEventListener('DOMContentLoaded', () => {
    const archiveButton = document.getElementById('archive-button');
    if (archiveButton) {
        archiveButton.addEventListener('click', startArchive);
    }
    
    const showFilesButton = document.getElementById('show-files-button');
    if (showFilesButton) {
        showFilesButton.addEventListener('click', toggleFiles);
    }
    
    updateStats();
    updateLogs();
});